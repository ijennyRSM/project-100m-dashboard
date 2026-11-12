begin;
do $$ begin
  if current_database()<>'project100m_sec001' then raise exception 'Disposable DB required'; end if;
end $$;
select no_plan();
create table public.sec001_future_postgres(id bigint);
create sequence public.sec001_sequence_postgres;
create function public.sec001_function_postgres() returns int language sql as $$select 1$$;
set local role supabase_admin;
create table public.sec001_future_admin(id bigint);
create sequence public.sec001_sequence_admin;
create function public.sec001_function_admin() returns int language sql as $$select 1$$;
reset role;
select ok(not has_table_privilege(role_name,table_name,'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'),role_name||' has no future table access: '||table_name)
from unnest(array['anon','authenticated']) role_name,unnest(array['public.sec001_future_postgres','public.sec001_future_admin']) table_name;
select ok(not has_sequence_privilege(role_name,sequence_name,'USAGE,SELECT,UPDATE'),role_name||' has no future sequence access: '||sequence_name)
from unnest(array['anon','authenticated']) role_name,unnest(array['public.sec001_sequence_postgres','public.sec001_sequence_admin']) sequence_name;
select ok(not has_function_privilege(role_name,function_name,'EXECUTE'),role_name||' has no future function access: '||function_name)
from unnest(array['anon','authenticated']) role_name,unnest(array['public.sec001_function_postgres()','public.sec001_function_admin()']) function_name;
select ok(not exists(select 1 from pg_proc p,lateral aclexplode(p.proacl) a where p.oid in
 ('public.sec001_function_postgres()'::regprocedure,'public.sec001_function_admin()'::regprocedure) and a.grantee=0),'built-in global PUBLIC EXECUTE actually revoked');
select ok(has_table_privilege('service_role','public.sec001_future_postgres','TRUNCATE'),'service_role table defaults preserved');
select ok(has_function_privilege('service_role','public.sec001_function_admin()','EXECUTE'),'service_role function defaults preserved');
grant select on public.sec001_future_postgres to authenticated;
select ok(has_table_privilege('authenticated','public.sec001_future_postgres','SELECT'),'future explicit grants remain possible');
select * from finish();
rollback;
