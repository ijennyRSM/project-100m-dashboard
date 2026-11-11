# P100-SEC-001 disposable database evidence

Captured 2026-11-12 (Asia/Bangkok). Each server passed **42 pgTAP assertions** plus migration idempotency, synthetic-row/policy/RPC preservation and failure-atomicity checks. PostgreSQL 17.11 matches the inspected live major/minor version. Image IDs, source-file SHA256 values, migration/proposal digests and the reviewed base commit are in result JSON. These snapshots precede the implementation commit; the final handover maps the unchanged file hashes to that commit.

- `pg16-pgtap.log` / `pg16-result.json`: local pgvector/pgvector:pg16 image; no vector extension used.
- `pg17-pgtap.log` / `pg17-result.json`: official postgres:17 image, PostgreSQL 17.11.

Every destructive statement ran only inside generated, label-verified Docker fixtures with synthetic users/rows and no exposed port or remote database URL. No production payloads were read or exported. This evidence does not cover Supabase JWT signature verification, Magic Link or a hosted PostgREST/browser smoke test. Production apply/backup status and review remain outstanding. See supabase/security/README.md.

Independent implementation commit: `ed7b525e8ec1fe6f2d8a1babf764dfc976a2b402`. `source-map.json` maps tested bytes/universal-newline content to canonical committed files. [CI run43105037594](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43105037594) passed42 assertions on each official PG16/17 image; result/log snapshots and artifact digests/head+merge SHAs are in `ci/`. [Latest run43107212947](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43107212947) also succeeded at713ead4 with unchanged security SQL/test source. Preparation is READY_FOR_REVIEW; live SEC-001 is not resolved.
