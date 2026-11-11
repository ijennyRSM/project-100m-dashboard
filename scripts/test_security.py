"""P100-SEC-001: Docker-only disposable PostgreSQL/pgTAP tests. No remote DB URL accepted."""
import argparse
import hashlib
import json
import re
import secrets
import subprocess
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB = 'project100m_sec001'
LABEL = 'com.project100m.disposable-security-test'


def command(args, data=None):
    result = subprocess.run(args, input=data, text=True, encoding='utf-8', capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr.strip()[-3000:])
    return result.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pg-version', choices=['16', '17'], default='17')
    parser.add_argument('--image', choices=['postgres:16','postgres:17','pgvector/pgvector:pg16'])
    args = parser.parse_args()
    image = args.image or 'postgres:' + args.pg_version
    if image.endswith('16') != (args.pg_version == '16'):
        parser.error('Image must match requested PostgreSQL major version')
    name = 'project100m-sec001-' + secrets.token_hex(5)
    evidence = ROOT / '.local-evidence' / ('security-pg' + args.pg_version)
    evidence.mkdir(parents=True, exist_ok=True)
    (evidence / 'result.json').write_text(json.dumps({'result':'RUNNING','pg_major':args.pg_version})+'\n',encoding='utf-8')
    log = []

    def sql(text, database=DB):
        result = command(['docker', 'exec', '-i', name, 'psql', '-XAtq', '-U', 'postgres', '-d', database,
                          '-v', 'ON_ERROR_STOP=1'], text)
        log.append(result)
        if re.search(r'^not ok\b', result, re.MULTILINE):
            raise RuntimeError('pgTAP failure:\n' + result)
        return result

    def run_file(path, database=DB):
        return sql((ROOT / path).read_text(encoding='utf-8'), database)

    created = False
    try:
        if subprocess.run(['docker','image','inspect',image],capture_output=True).returncode:
            # Public image only; avoid requiring a stored registry credential helper on Windows.
            with tempfile.TemporaryDirectory(prefix='p100-public-pull-') as folder:
                (Path(folder)/'config.json').write_text('{"auths":{}}',encoding='utf-8')
                command(['docker','--config',folder,'pull',image])
        command(['docker', 'run', '--name', name, '--label', LABEL + '=true', '-e', 'POSTGRES_PASSWORD=' + secrets.token_hex(16),
                 '-e', 'POSTGRES_DB=' + DB, '-d', image])
        created = True
        for _ in range(60):
            # pg_isready alone can see the temporary initdb server immediately before it stops.
            ready = subprocess.run(['docker', 'exec', name, 'sh', '-c',
                                    'test "$(cat /proc/1/comm)" = postgres && pg_isready -U postgres -d ' + DB], capture_output=True)
            if ready.returncode == 0:
                break
            time.sleep(0.5)
        else:
            raise RuntimeError('Disposable PostgreSQL did not become ready')
        if sql("select split_part(current_setting('server_version'),'.',1);").strip() != args.pg_version:
            raise RuntimeError('Image PostgreSQL version does not match requested version')
        command(['docker', 'exec', name, 'sh', '-c', 'apt-get update -qq && apt-get install -y -qq postgresql-' + args.pg_version + '-pgtap'])
        run_file('supabase/tests/bootstrap.sql')
        # The actual reviewed legacy setup reproduces the original default-ACL bug.
        legacy = command(['git', '-C', str(ROOT), 'show', 'f2b370f:supabase-schema.sql'])
        sql(legacy)
        sql('''begin;
select no_plan();
insert into public.training_states(user_id,payload) values
('00000000-0000-0000-0000-000000000001','{"version":2,"synthetic":"A"}'),
('00000000-0000-0000-0000-000000000002','{"version":2,"synthetic":"B"}');
select ok(has_table_privilege('authenticated','public.training_states','TRUNCATE'),'test detects vulnerable legacy grant');
set local role authenticated;
set local request.jwt.claims='{"sub":"00000000-0000-0000-0000-000000000001"}';
truncate public.training_states;
reset role;
select is((select count(*)::int from public.training_states),0,'legacy TRUNCATE bypasses RLS and removes BOTH synthetic rows');
select * from finish(); rollback;''')
        contract = "select jsonb_build_object('rpc',pg_get_functiondef('public.save_training_state(bigint,jsonb)'::regprocedure),'policies',(select jsonb_agg(row_to_json(p)) from (select polname,polcmd,polqual::text,polwithcheck::text from pg_policy where polrelid='public.training_states'::regclass order by polname) p));"
        before = sql(contract)
        sql('''insert into public.training_states(user_id,payload) values
('00000000-0000-0000-0000-000000000001','{"version":2,"synthetic":"preserve me"}');''')
        rows_before = sql('select row_to_json(t) from public.training_states t;')
        migration = next((ROOT / 'supabase/migrations').glob('*p100_sec_001_training_states_least_privilege.sql'))
        sql(migration.read_text(encoding='utf-8'))
        sql(migration.read_text(encoding='utf-8'))
        if sql(contract) != before or sql('select row_to_json(t) from public.training_states t;') != rows_before:
            raise RuntimeError('Migration changed policy/function contract or synthetic data')
        log.append('PASS: Migration A twice preserves RPC/policies and synthetic payload\n')
        sql('delete from public.training_states;')  # Only this disposable, label-guarded DB.
        sql('create role sec001_danger nologin; grant truncate on public.training_states to sec001_danger; grant sec001_danger to authenticated; grant delete on public.training_states to authenticated;')
        prior_acl = sql("select relacl::text from pg_class where oid='public.training_states'::regclass;")
        try:
            sql(migration.read_text(encoding='utf-8'))
        except RuntimeError as error:
            if 'P100-SEC-001: unexpected authenticated privilege' not in str(error):
                raise
        else:
            raise RuntimeError('Migration failed to detect unexpected inherited privileges')
        if sql("select relacl::text from pg_class where oid='public.training_states'::regclass;") != prior_acl:
            raise RuntimeError('Failed migration did not roll back ACL changes')
        log.append('PASS: inherited dangerous privileges abort and roll back the entire ACL transaction\n')
        sql('revoke delete on public.training_states from authenticated; revoke sec001_danger from authenticated; revoke all on public.training_states from sec001_danger; drop role sec001_danger;')
        run_file('supabase/tests/p100_sec_001.sql')
        proposal = next((ROOT / 'supabase/proposals').glob('*p100_sec_001_default_privileges_proposal.sql'))
        sql(proposal.read_text(encoding='utf-8'))
        sql(proposal.read_text(encoding='utf-8'))
        run_file('supabase/tests/p100_sec_001_defaults.sql')
        command(['docker', 'exec', name, 'createdb', '-U', 'postgres', DB + '_fresh'])
        run_file('supabase/tests/bootstrap.sql', DB + '_fresh')
        run_file('supabase-schema.sql', DB + '_fresh')
        sql('''select no_plan();
select ok(not has_table_privilege('authenticated','public.training_states','TRUNCATE,DELETE,REFERENCES,TRIGGER'),'corrected setup narrows stock default grants on a fresh database');
select ok(not has_table_privilege('anon','public.training_states','SELECT'),'fresh setup denies anon');
select ok(has_table_privilege('authenticated','public.training_states','SELECT,INSERT,UPDATE'),'fresh setup preserves required writes');
select * from finish();''', DB + '_fresh')
        version = sql('select version();').strip()
        combined = '\n'.join(log)
        (evidence / 'pgtap.log').write_text(combined, encoding='utf-8')
        metadata = dict(result='PASS', pg_version=version, image=image,
                        image_id=command(['docker', 'inspect', '--format', '{{.Image}}', name]).strip(),
                        tests=len(re.findall(r'^ok \d+', combined, re.MULTILINE)),
                        migration_sha256=hashlib.sha256(migration.read_bytes()).hexdigest(),
                        proposal_sha256=hashlib.sha256(proposal.read_bytes()).hexdigest(),
                        scope='Disposable local SQL/pgTAP only; no production data, JWT verification or Magic Link smoke test',
                        base_commit=command(['git', '-C', str(ROOT), 'rev-parse', 'HEAD']).strip(),
                        source_files={str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                                      for p in [ROOT / 'scripts/test_security.py', ROOT / 'supabase-schema.sql',
                                                ROOT / 'supabase/tests/bootstrap.sql', ROOT / 'supabase/tests/p100_sec_001.sql',
                                                ROOT / 'supabase/tests/p100_sec_001_defaults.sql']})
        (evidence / 'result.json').write_text(json.dumps(metadata, indent=2) + '\n', encoding='utf-8')
        print(f"PASS: {metadata['tests']} pgTAP assertions + idempotency/contract/data checks on PostgreSQL {args.pg_version}")
        print(evidence)
    except (RuntimeError, OSError) as error:
        (evidence / 'pgtap.log').write_text('\n'.join(log), encoding='utf-8')
        (evidence / 'result.json').write_text(json.dumps({'result':'FAIL','pg_major':args.pg_version,'error':str(error)},indent=2)+'\n',encoding='utf-8')
        print('FAIL:', error)
        return 1
    finally:
        if created:
            label = command(['docker', 'inspect', '--format', '{{index .Config.Labels "' + LABEL + '"}}', name]).strip()
            if label == 'true':
                command(['docker', 'rm', '-fv', name])
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
