-- READ ONLY. Catalog/privilege inventory; never selects private training payloads.
select version();
select c.relname, pg_get_userbyid(c.relowner) as owner, c.relrowsecurity, c.relacl
from pg_class c where c.oid='public.training_states'::regclass;
select case when a.grantee=0 then 'PUBLIC' else pg_get_userbyid(a.grantee) end as grantee,
       a.privilege_type, a.is_grantable, pg_get_userbyid(a.grantor) as grantor
from pg_class c, lateral aclexplode(coalesce(c.relacl,acldefault('r',c.relowner))) a
where c.oid='public.training_states'::regclass order by 1,2;
select pg_get_userbyid(defaclrole) as creator,
       case when defaclnamespace=0 then '(global)' else defaclnamespace::regnamespace::text end as scope,
       defaclobjtype, defaclacl from pg_default_acl order by 1,2,3;
select p.oid::regprocedure, p.prosecdef, p.proacl
from pg_proc p where p.pronamespace='public'::regnamespace;
select polname, polcmd, polroles::regrole[], pg_get_expr(polqual,polrelid), pg_get_expr(polwithcheck,polrelid)
from pg_policy where polrelid='public.training_states'::regclass;
select member.rolname as member, parent.rolname as parent from pg_auth_members m
join pg_roles member on member.oid=m.member join pg_roles parent on parent.oid=m.roleid
where member.rolname in ('anon','authenticated');
