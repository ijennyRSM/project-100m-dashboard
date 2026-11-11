-- READ ONLY. Safe after owner-approved rollout: no TRUNCATE, DELETE or payload reads.
select role_name, p.privilege_type,
       has_table_privilege(role_name,'public.training_states',p.privilege_type) as allowed,
       (role_name='authenticated' and p.privilege_type=any(array['SELECT','INSERT','UPDATE'])) as expected
from unnest(array['anon','authenticated']) role_name, pg_class c,
lateral aclexplode(acldefault('r',c.relowner)) p
where c.oid='public.training_states'::regclass order by role_name,p.privilege_type;
select role_name, has_function_privilege(role_name,'public.save_training_state(bigint,jsonb)','EXECUTE') as rpc_execute
from unnest(array['anon','authenticated']) role_name;
select relrowsecurity from pg_class where oid='public.training_states'::regclass;
select p.oid::regprocedure,p.prosecdef,p.proacl from pg_proc p
where p.oid='public.save_training_state(bigint,jsonb)'::regprocedure;
select a.* from pg_class c,lateral aclexplode(c.relacl) a
where c.oid='public.training_states'::regclass and a.grantee=0; -- expected zero rows
