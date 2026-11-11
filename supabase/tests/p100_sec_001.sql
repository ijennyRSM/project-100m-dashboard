-- Destructive probes are confined to a rollback transaction in a disposable database.
begin;
do $$ begin
  if current_database()<>'project100m_sec001' then raise exception 'Disposable DB required'; end if;
end $$;
select no_plan();
select ok((select relrowsecurity from pg_class where oid='public.training_states'::regclass),'RLS stays enabled');
select ok(not (select prosecdef from pg_proc where oid='public.save_training_state(bigint,jsonb)'::regprocedure),'RPC remains SECURITY INVOKER');
select ok(not has_table_privilege('authenticated','public.training_states','DELETE,TRUNCATE,REFERENCES,TRIGGER'),'all dangerous table privileges removed');
select ok(has_table_privilege('service_role','public.training_states','TRUNCATE'),'service_role ACL untouched');
select ok(has_function_privilege('service_role','public.save_training_state(bigint,jsonb)','EXECUTE'),'service_role RPC ACL untouched');
select ok(not exists(select 1 from pg_class c,lateral aclexplode(c.relacl) a where c.oid='public.training_states'::regclass and a.grantee=0),'no PUBLIC table grants');
select ok(not exists(select 1 from pg_class c,lateral aclexplode(acldefault('r',c.relowner)) a
  where c.oid='public.training_states'::regclass and a.privilege_type<>all(array['SELECT','INSERT','UPDATE'])
    and has_table_privilege('authenticated',c.oid,a.privilege_type)),'server-specific extras including PG17 MAINTAIN removed');
insert into public.training_states(user_id,revision,payload) values
('00000000-0000-0000-0000-000000000001',1,'{"version":2,"profiles":[],"synthetic":"A"}'),
('00000000-0000-0000-0000-000000000002',1,'{"version":2,"profiles":[],"synthetic":"B"}');
set local role authenticated;
set local request.jwt.claims='{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}';
select throws_ok('truncate public.training_states','42501',null,'authenticated TRUNCATE denied before touching rows');
select throws_ok('delete from public.training_states','42501',null,'authenticated DELETE denied');
select is((select count(*)::int from public.training_states),1,'A only sees A');
with changed as (update public.training_states set revision=99 where user_id='00000000-0000-0000-0000-000000000002' returning *)
select is(count(*)::int,0,'A cannot update B') from changed;
select throws_ok($q$insert into public.training_states values ('00000000-0000-0000-0000-000000000002',1,'{"version":2}',now())$q$,'42501',null,'A cannot insert B');
select throws_ok($q$update public.training_states set user_id='00000000-0000-0000-0000-000000000002'$q$,'42501',null,'A cannot reassign ownership');
select is(public.save_training_state(1,'{"version":2,"profiles":[],"synthetic":"A updated"}'),2::bigint,'existing web RPC advances expected revision');
select is(public.save_training_state(1,'{"version":2,"profiles":[]}'),null::bigint,'stale web RPC revision returns NULL');
reset role;
select is((select revision from public.training_states where user_id='00000000-0000-0000-0000-000000000002'),1::bigint,'B unchanged by A attempts');
-- Remove only synthetic B locally to exercise a first account save.
delete from public.training_states where user_id='00000000-0000-0000-0000-000000000002';
set local role authenticated;
set local request.jwt.claims='{"sub":"00000000-0000-0000-0000-000000000002","role":"authenticated"}';
select is(public.save_training_state(0,'{"version":2,"profiles":[],"synthetic":"B new"}'),1::bigint,'new B account can insert via SECURITY INVOKER RPC');
select is((select count(*)::int from public.training_states),1,'B only sees B');
reset role;
set local role anon;
select throws_ok('select * from public.training_states','42501',null,'anon SELECT denied');
select throws_ok($q$insert into public.training_states values ('00000000-0000-0000-0000-000000000001',1,'{}',now())$q$,'42501',null,'anon INSERT denied');
select throws_ok($q$select public.save_training_state(0,'{"version":2}')$q$,'42501',null,'anon RPC denied');
reset role;
select * from finish();
rollback;
