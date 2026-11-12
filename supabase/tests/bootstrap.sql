-- ONLY the Docker-created disposable database in scripts/test_security.py.
do $$ begin
  if current_database() not in ('project100m_sec001','project100m_sec001_fresh') then
    raise exception 'Refusing fixture setup outside disposable security database';
  end if;
end $$;
do $$ declare r text; begin
  foreach r in array array['anon','authenticated','service_role','supabase_admin'] loop
    if not exists(select 1 from pg_roles where rolname=r) then execute format('create role %I nologin',r); end if;
  end loop;
end $$;
create schema auth;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$
  select (nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'sub')::uuid;
$$;
grant usage on schema auth to anon,authenticated;
grant execute on function auth.uid() to anon,authenticated;
grant usage,create on schema public to supabase_admin;
grant usage on schema public to anon,authenticated,service_role;
-- Reproduce the deployed Supabase defaults; no production records are copied.
alter default privileges for role postgres in schema public grant all on tables to anon,authenticated,service_role;
alter default privileges for role postgres in schema public grant all on sequences to anon,authenticated,service_role;
alter default privileges for role postgres in schema public grant all on functions to anon,authenticated,service_role;
alter default privileges for role supabase_admin in schema public grant all on tables to postgres,anon,authenticated,service_role;
alter default privileges for role supabase_admin in schema public grant all on sequences to postgres,anon,authenticated,service_role;
alter default privileges for role supabase_admin in schema public grant all on functions to postgres,anon,authenticated,service_role;
insert into auth.users values ('00000000-0000-0000-0000-000000000001'),('00000000-0000-0000-0000-000000000002');
create extension pgtap;
