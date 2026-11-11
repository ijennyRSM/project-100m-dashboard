# Current handover — M0 second review

2026-11-12 (Asia/Bangkok). Codex owns the fixes on `codex/m0-foundation-handover`. [Draft PR #1](https://github.com/ijennyRSM/project-100m-dashboard/pull/1) remains unmerged, base `feat/ios-native-foundation`. **M0 remains CHANGES_REQUESTED** per the owner's instruction; no self-acceptance/verification and no M1 development.

## Synchronization and committed implementation

Clean working tree at start; `git fetch` and `git merge --ff-only` confirmed local/remote already at Claude review `f2b370f79581b9009836f7e5a47da08fe566e1ea`. No uncommitted work was discarded. Read root/native instructions and review/ledger before edits.

- Independent security implementation: `ed7b525e8ec1fe6f2d8a1babf764dfc976a2b402`. Migration A, authorized original-setup correction, separately scoped B proposal, disposable SQL tests/lint/CI and original local evidence.
- Native/CI fixes: `3e864514b2687e44a603532040ebd448b17bd8b8`; measured test-budget correction: `713ead4126850b6a488943cfe5c511ee3983b3fa` (current implementation).
- Exact native tree: `54462fa2bbd9b1a56ae46b02b8acd836f8f62ea3`; `.github` tree: `65567a9f07fe2630b099ed4c7e16443188510e95`.
- Later handover-only changes must match these two trees before reusing native CI evidence. Tests captured before commit have source SHA256 maps; `P100-SEC-001/source-map.json` proves canonical committed SQL/test content matches tested input (universal-newline normalization for the original schema file).

## Findings addressed in source

| Review | Change / remaining evidence |
|---|---|
| H1 | Recovered historical job/artifact: 6437d8d compiled successfully; simulator boot timed out after 5 minutes, before UI tests. Exact matching head/merge trees and excerpt are saved in evidence/M0-review-fix. New-source full suite is tracked below. |
| H2 / layout M1 | Width-driven ViewThatFits for scaled rings and tiles; named iPhone 16 (393pt) / SE3 (375pt), iOS18.5. Tests assert actual theme/type, ring/tile bounds/hittability at light/dark large/xLarge/AX5. A real hosted 320pt Health container at xLarge tests narrow content; no Display Zoom claim. |
| Freshness M2 | Preserve RHR/HRV sample end dates. Show measurement date and latest-within-21-days window; query timestamp explicitly says it is not measurement time. |
| Connection M3 | Explicit notRequested CTA, unavailable without retry, failure reason, loading and requested-empty ambiguity. DEBUG-only dated/stale/state fixtures construct no HKHealthStore. Release ignores test overrides. |
| Concurrency M4 | Event/branch/workflow-specific groups; cancel-in-progress false. Push and PR runs execute without cancelling each other or docs-only evidence. |
| Lifecycle M5 / L1 | Claude's review record preserved; M0 remains CHANGES_REQUESTED. --ui-reset removes only saved tab key; restore test removes reset on relaunch, with no argument-domain override. |
| C1 | Prepared/tested ACL remediation; original setup no longer merely adds grants over platform ALL defaults. Live PostgreSQL17 inventory also finds MAINTAIN and both postgres/supabase_admin default ACLs. No production change. |

Exactly five tabs/order and read-only HealthKit remain. No accounts, native training/social/scoring/AI features were added. Web JS/CSS/HTML and private training data unchanged. `supabase-schema.sql` is intentionally corrected under the owner's explicit security task, separately from native code.

## Observed verification

- Local Windows: all 15 handover/grant-lint unit tests PASS (9 original handover + 6 SQL lint); explicit-grant lint PASS; git diff/source checks PASS. Handover status/validation PASS for all10 staged records; prepared review instructions generated without status mutation.
- Disposable local PG16 and PG17: **42 pgTAP assertions each PASS**, plus A/B idempotency, unchanged synthetic data/RPC/policies, and deliberately inherited dangerous privileges causing full transaction rollback. Fresh corrected setup tested separately. No remote DB URL or published container port; fixtures removed by label-checked cleanup.
- [Remote security CI](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43105037594): completed SUCCESS on official PostgreSQL16/17 images, 42 assertions each. Logs/result/provenance committed under evidence/P100-SEC-001/ci. SQL-side web SELECT/RPC/new-save/stale-conflict contract passed; real Supabase Auth/JWT signature/PostgREST/browser Magic Link smoke NOT RUN.
- [Remote handover CI](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43107212967): completed SUCCESS on Windows/Linux at 713ead4. [Latest security CI](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43107212947) also completed SUCCESS; security source unchanged from the archived 42+42 run above.
- First native fix run [43105037599](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43105037599), head 3e86451: both builds PASS; iPhone16 all four tests PASS; SE3 layout method exceeded default four-minute execution limit (273 seconds), other three tests PASS. Overall run FAILURE. At 713ead4, only that expanded seven-launch matrix method receives six minutes (CLI maximum seven); scenarios/assertions retained. No application code was changed for the timeout.
- Native evidence of record: [PR run 43107213059](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43107213059), head 713ead4. Both named simulator app builds PASS. Completed SUCCESS: iPhone16 and SE3 each build PASS and all four UI tests PASS with zero failures (288.828s / 331.438s). Tested merge `e6b0b764e2967118c6622800ec2b0c67e4ed846d` matches both trees above. Artifacts13894209678 / 13894484095 downloaded and SHA256-verified; 38 original selected PNGs, attachment maps, test excerpts and full provenance are committed under [review evidence](evidence/M0-review-fix/README.md). Representative current light/dark/xLarge/AX5, hosted320, dated metrics and connection-state images were inspected. No real-device or full VoiceOver acceptance implied.

## Infrastructure diagnosis

Historical [43075144693](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43075144693), merge dcec212d44a3ddd73d2f3d7ba4b2d8cacb129600, exactly matches native/.github trees at head6437d8d. Recovered log says BUILD SUCCEEDED and Boot selected simulator timed out; no UI result bundle. This earlier boot failure is separate from the later GitHub incident.

[GitHub incident dvy0t3mvh1lg](https://www.githubstatus.com/incidents/dvy0t3mvh1lg) reported Actions major outage, started 2026-11-11 20:48 UTC and resolved 21:21 UTC. Public incident history and observed status snapshots are saved. Repository Actions enabled, allowed_actions=all, default workflow token read permissions sufficient; no permission/settings changed. Account billing-usage endpoint returned404, so account-wide quotas were not independently established. Current successful Windows/Linux/security jobs and named macOS builds show execution resumed. No empty trigger commits were pushed.

## Security status and production gate

Read-only live catalog inspection only: PostgreSQL17.11, owner `postgres`, RLS on; authenticated ALL includes MAINTAIN; anon/PUBLIC absent from table ACL; public-schema defaults are broad for postgres and supabase_admin. No user payload read/export, hosted DDL or destructive probe.

Migration A narrows only existing table/RPC ACLs, including effective/inherited privilege assertions. B is outside migrations, with its **global future-object scope** explicitly proposed for both creators; per-schema revocation cannot undo built-in global PUBLIC EXECUTE. Full plan, catalog-only verification, backup and rollback: supabase/security/README.md. Production backup/PITR status is unknown. Owner approval and separate scope review are required; Critical live exposure is NOT closed. M1 remains BLOCKED.

## Required Claude re-review / next actions

1. Review source commit `713ead4` and independently review security commit `ed7b525`. Check UI tree/provenance equivalence and all four tests on both devices, new screenshots, hosted320 bounds and actual environment probes.
2. Re-review Migration A, PG17 MAINTAIN/inheritance failure-atomicity, corrected setup and 42+42 evidence; review B's two creator roles/global scope before any production approval.
3. Arrange hosted disposable staging Auth/PostgREST/web smoke, owner backup confirmation and an explicitly approved production window. No production SQL has been applied.
4. Return findings/acceptance disposition; M0 remains CHANGES_REQUESTED until Claude reviews fixes and required evidence is available. Resolve findings and resubmit; do not start M1.
5. Deferred review risks: iOS17 runtime, real Display Zoom/full VoiceOver (M6); score result provenance types, HealthKit anchors/source/night grouping (M2); self-scoped direct DML bypass of RPC validation (M1). No signing, real-device, Watch/GPS/background evidence claimed.
