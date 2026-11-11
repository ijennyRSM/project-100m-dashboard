# P100-SEC-001 disposable database evidence

Captured 2026-11-12 (Asia/Bangkok). Each server passed **42 pgTAP assertions** plus migration idempotency, synthetic-row/policy/RPC preservation and failure-atomicity checks. PostgreSQL 17.11 matches the inspected live major/minor version. Image IDs, source-file SHA256 values, migration/proposal digests and the reviewed base commit are in result JSON. These snapshots precede the implementation commit; the final handover maps the unchanged file hashes to that commit.

- `pg16-pgtap.log` / `pg16-result.json`: local pgvector/pgvector:pg16 image; no vector extension used.
- `pg17-pgtap.log` / `pg17-result.json`: official postgres:17 image, PostgreSQL 17.11.

Every destructive statement ran only inside generated, label-verified Docker fixtures with synthetic users/rows and no exposed port or remote database URL. No production payloads were read or exported. This evidence does not cover Supabase JWT signature verification, Magic Link or a hosted PostgREST/browser smoke test. Production apply/backup status and review remain outstanding. See supabase/security/README.md.
