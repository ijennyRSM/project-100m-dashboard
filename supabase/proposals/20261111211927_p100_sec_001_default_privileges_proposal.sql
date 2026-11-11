-- Migration B PROPOSAL: deliberately outside migrations/, never auto-deployed.
-- Requires Claude scope review and explicit owner approval for BOTH creators below.
-- Global revocations affect FUTURE objects in all schemas for these creators.
-- Per-schema REVOKE alone cannot undo global or built-in PUBLIC EXECUTE grants.
-- Existing objects/data are untouched; service_role grants are retained.
begin;
set local lock_timeout = '5s';
do $$
declare creator text; kind text;
begin
  foreach creator in array array['postgres','supabase_admin'] loop
    if not exists(select 1 from pg_roles where rolname=creator) then
      raise exception 'P100-SEC-001 B: inventoried creator % missing; review deployment scope',creator;
    end if;
    foreach kind in array array['TABLES','SEQUENCES','FUNCTIONS'] loop
      execute format('alter default privileges for role %I revoke all on %s from public, anon, authenticated',creator,kind);
      execute format('alter default privileges for role %I in schema public revoke all on %s from public, anon, authenticated',creator,kind);
    end loop;
  end loop;
end $$;

do $$
declare creator text; object_type "char"; defaults aclitem[];
begin
  foreach creator in array array['postgres','supabase_admin'] loop
    foreach object_type in array array['r'::"char",'S'::"char",'f'::"char"] loop
      select coalesce((select defaclacl from pg_default_acl
        where defaclrole=creator::regrole and defaclnamespace=0 and defaclobjtype=object_type),
        acldefault(object_type,creator::regrole)) into defaults;
      if exists(select 1 from aclexplode(defaults) a
        where a.grantee in (0,'anon'::regrole,'authenticated'::regrole))
        or exists(select 1 from pg_default_acl d,lateral aclexplode(d.defaclacl) a
          where d.defaclrole=creator::regrole and d.defaclnamespace='public'::regnamespace
            and d.defaclobjtype=object_type and a.grantee in (0,'anon'::regrole,'authenticated'::regrole)) then
        raise exception 'P100-SEC-001 B: client default privileges remain for % / %',creator,object_type;
      end if;
    end loop;
  end loop;
end $$;
commit;
