-- P100-SEC-001 / Migration A. REVIEW ONLY until explicit owner production approval.
-- ACL-only: no rows, policies, RPC implementation or service_role grants change.
begin;
set local lock_timeout = '5s';
do $$ begin
  if to_regclass('public.training_states') is null
     or to_regprocedure('public.save_training_state(bigint,jsonb)') is null then
    raise exception 'P100-SEC-001: expected table/RPC missing';
  end if;
  if not (select relrowsecurity from pg_class where oid='public.training_states'::regclass)
     or (select prosecdef from pg_proc where oid='public.save_training_state(bigint,jsonb)'::regprocedure) then
    raise exception 'P100-SEC-001: expected RLS / SECURITY INVOKER boundary changed';
  end if;
end $$;

revoke all on table public.training_states from public, anon, authenticated;
grant select, insert, update on table public.training_states to authenticated;
revoke all on function public.save_training_state(bigint,jsonb) from public, anon, authenticated;
grant execute on function public.save_training_state(bigint,jsonb) to authenticated;

do $$
declare p text;
begin
  -- Derive privilege names from this server; includes PG17 MAINTAIN without breaking PG16.
  for p in select privilege_type from pg_class c,
      lateral aclexplode(acldefault('r',c.relowner)) a
      where c.oid='public.training_states'::regclass loop
    if has_table_privilege('anon','public.training_states',p) then
      raise exception 'P100-SEC-001: anon retains % (including inherited privileges)',p;
    end if;
    if has_table_privilege('authenticated','public.training_states',p) <> (p=any(array['SELECT','INSERT','UPDATE'])) then
      raise exception 'P100-SEC-001: unexpected authenticated privilege %',p;
    end if;
  end loop;
  if exists(select 1 from pg_class c,lateral aclexplode(c.relacl) a
      where c.oid='public.training_states'::regclass and
        (a.grantee=0 or (a.grantee in ('anon'::regrole,'authenticated'::regrole) and a.is_grantable))) then
    raise exception 'P100-SEC-001: PUBLIC access or client grant option remains';
  end if;
  if has_function_privilege('anon','public.save_training_state(bigint,jsonb)','EXECUTE')
     or not has_function_privilege('authenticated','public.save_training_state(bigint,jsonb)','EXECUTE')
     or exists(select 1 from pg_proc p,lateral aclexplode(p.proacl) a
       where p.oid='public.save_training_state(bigint,jsonb)'::regprocedure and
         (a.grantee=0 or (a.grantee='authenticated'::regrole and a.is_grantable))) then
    raise exception 'P100-SEC-001: unexpected RPC ACL';
  end if;
end $$;
commit;
