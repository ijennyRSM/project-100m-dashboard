import importlib.util
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location('grants', Path(__file__).parents[1] / 'check_sql_grants.py')
grants = importlib.util.module_from_spec(spec)
spec.loader.exec_module(grants)


class GrantLintTests(unittest.TestCase):
    def test_unguarded_table_rejected(self):
        self.assertTrue(grants.check('create table public.workouts(id uuid);'))

    def test_explicit_grant_accepted(self):
        self.assertEqual(grants.check('create table public.workouts(id uuid); grant select on table public.workouts to authenticated;'), [])

    def test_comment_cannot_supply_missing_grant(self):
        self.assertTrue(grants.check('create table public.workouts(id uuid); -- grant select on public.workouts to authenticated;'))

    def test_function_body_cannot_supply_grant(self):
        self.assertTrue(grants.check("create function public.f() returns text language sql as $$select 'grant execute on function public.f() to authenticated;'$$;"))

    def test_client_all_rejected(self):
        self.assertTrue(grants.check('grant all on public.workouts to authenticated;'))

    def test_service_role_grant_unchanged(self):
        self.assertEqual(grants.check('grant all on public.workouts to service_role;'), [])
