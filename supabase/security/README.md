# P100-SEC-001 — prepared remediation, NOT applied to production

Owner approval is required before **any** hosted privilege change. M1 remains blocked. Do not run the fixture/test SQL on a hosted project. No private training payload was read/exported during this work.

## Inventory and cause

Read-only catalog inspection on 2026-11-12 (Asia/Bangkok) found PostgreSQL 17.11, table owner `postgres`, RLS enabled, and table ACL `{postgres=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}`. `anon` and `PUBLIC` have no direct table ACL. `authenticated` has no inherited role membership in the inspected catalog. `m` is PG17 MAINTAIN and is also unnecessary. RPC is SECURITY INVOKER, with owner/authenticated/service_role EXECUTE; no anon/PUBLIC entry.

Both `postgres` and `supabase_admin` have schema-public default ACLs granting ALL table/sequence/function privileges to anon/authenticated/service_role (admin defaults also grant postgres). No global default ACL rows were returned; PostgreSQL's built-in global PUBLIC function EXECUTE still matters. The legacy setup adds SELECT/INSERT/UPDATE but never revokes inherited platform default grants. This reproduces the hole in a fresh disposable database; reapplying the legacy setup is not a fix.

## Independently reviewable changes

- **Migration A:** `../migrations/20261111211924_p100_sec_001_training_states_least_privilege.sql`. Resets only training_states and save_training_state client/PUBLIC ACLs, restoring authenticated SELECT/INSERT/UPDATE and RPC EXECUTE. Owner/service_role untouched. No rows, policies or RPC implementation change. Post-conditions inspect effective privileges (including inheritance and PG17 MAINTAIN), PUBLIC access and grant options; surprises abort/roll back the transaction. Apply is idempotent and uses a 5-second lock timeout.
- **Setup correction:** root `supabase-schema.sql` now resets PUBLIC/anon/authenticated ACLs and applies its existing setup atomically. This file change is explicitly authorized by the review-fix task. Use Migration A for an existing hosted deployment; do not replace its entire policy/function setup merely to narrow grants.
- **Migration B proposal:** `../proposals/20261111211927_p100_sec_001_default_privileges_proposal.sql`, outside automatic migration discovery. Covers the two inventoried creators. **Global revocations affect future objects in all schemas for these creators**, then clear public-schema grants too. This is required because per-schema REVOKE cannot override global/built-in grants. Existing objects and service_role grants stay intact. Requires separate Claude scope review and owner approval; may require an authorized platform operator to alter supabase_admin defaults. Review extension upgrades/other schema consumers before approving. Unexpected extra creator roles require a new inventory and explicit scope amendment, not automatic iteration.
- `inventory.sql` and `verify.sql` are catalog-only/read-only and can be saved by the owner. No training payload SELECT or destructive probe appears in verification.
- `scripts/check_sql_grants.py` rejects conventional static CREATE TABLE/FUNCTION without explicit object grants and client GRANT ALL. It is a lint, not a complete SQL parser or proof of least privilege: quoted/dynamic DDL and overloaded signatures require manual review. Every M1 migration still needs runtime RLS/ACL tests and explicit grants.

Sources: [PostgreSQL default-privilege scope](https://www.postgresql.org/docs/17/sql-alterdefaultprivileges.html), [Supabase roles](https://supabase.com/docs/guides/database/postgres/roles). Migration filenames were created with Supabase CLI 3.1.0 (UTC timestamps), then B was moved to proposals for review.

## Local/staging verification

From the repository root with Docker running:

```
python scripts/test_security.py --pg-version 17
python scripts/test_security.py --pg-version 16
python scripts/check_sql_grants.py
python -m unittest discover -s scripts/tests -v
```

The runner accepts **no database URL**. It creates a random, labeled Docker container, publishes no port, uses synthetic A/B users, verifies the database name and server version, installs pgTAP only in that container, and removes only its label-verified container/anonymous volume afterward. `--image pgvector/pgvector:pg16 --pg-version 16` can use the existing local PG16 image; the image digest/version is recorded. CI repeats against official postgres:16/17 images.

Tests reproduce the legacy cross-user TRUNCATE hole inside a rollback transaction; apply A twice; prove payload/policy/RPC preservation; deliberately introduce inherited dangerous privileges to verify transaction abort/ACL rollback; assert 42501 for authenticated TRUNCATE/DELETE and anon access, A/B isolation/ownership checks, initial RPC insert/update and stale-revision NULL; apply B twice and check future tables/sequences/functions for both creators; prove corrected setup on a separate fresh database. Results/digests are under `.local-evidence/security-pg*/`; reviewed snapshots are copied to docs/handover/evidence. These are real PostgreSQL/pgTAP checks, **not hosted Supabase Auth/JWT signature, HTTP/PostgREST or Magic Link browser smoke tests**. Those integration checks remain a staging/owner acceptance item.

## Backup and approved rollout

1. Owner confirms a usable backup/PITR recovery point, retention and a restore procedure, or makes an approved owner-controlled backup. Backup status is currently **unknown**. The agent has not exported private data; do not commit backups.
2. Owner captures `inventory.sql` output verbatim, including relacl/proacl/default ACLs, role memberships, policies and server version. Confirm the deployed schema still matches review, client operations still use SELECT + invoker RPC, and identify every actual DDL creator.
3. Review local evidence and perform a hosted **disposable staging** web smoke test: sign in, pull, record/sync a synthetic session, force stale-revision conflict. Never point destructive tests at production.
4. Obtain explicit approval for the exact Migration A hash and maintenance window. Apply A once as an authorized operator. A post-condition failure rolls back all ACL changes; investigate rather than bypassing it.
5. Owner runs only read-only `verify.sql`/inventory, checks every allowed column matches expected, verifies service_role/owner and policies unchanged, and performs an approved production web smoke test. Observe 42501 errors for 24 hours; record evidence before closing SEC-001.
6. Review/approve B independently, including its global future-object impact. Confirm M1 explicit-grant policies/lint before any new table or RPC. Neither file is authorization to deploy it.

## Rollback

Prefer a forward fix granting only the specific required privilege proven missing. No loss of web-required permissions is expected: authenticated retains SELECT/INSERT/UPDATE and invoker RPC EXECUTE. Neither migration changes rows, so there is no data rollback to run.

If exact ACL restoration is unavoidable, the owner must approve it explicitly: it reopens the Critical vulnerability. Use the **captured pre-change** table/function ACLs, creator/global/schema default ACLs and grant options; do not assume GRANT ALL or a fixed four-privilege list is an exact restore (PG17 adds MAINTAIN). Reset only the affected client/PUBLIC ACLs, then reconstruct the captured grants under their authorized grantors. For B, a previously absent global function ACL corresponds to PostgreSQL's built-in PUBLIC EXECUTE and must be considered when restoring; preserve unrelated existing default ACLs. Review the reconstructed SQL before execution. Never infer rollback from current post-change catalogs or run TRUNCATE/DELETE as a production probe.
