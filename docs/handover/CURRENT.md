# Current handover

Date: 2026-11-12 (Asia/Bangkok). Branch: `codex/m0-foundation-handover` from native `15e10f0`. Owner: Codex. Reviewer: Claude (manual handoff, no integration configured). [Draft PR #1](https://github.com/ijennyRSM/project-100m-dashboard/pull/1), base `feat/ios-native-foundation`; no merge to main.

## Scope and commit evidence

- `ffada65b2674f6b9765d7bf21c493254c62179c4`: approved blueprint, architecture and audit, committed before substantial feature work.
- `aad45de05e9d37cfb125c4c56ee6a399dbc6e7e1`: portable handover tooling and initial tests.
- `adfa55c2e383c90a913d3936145549ac930d8598`: five-tab M0 views, components and simulator UI suite.
- `db321c319ebb5a06fd928511d999ca7f05bec4cd`: stronger validation, milestone ledger and consistent sample progression.
- `939965577a38032dedca2ae75955a23a83402529`: launch-screen declaration and safe-area-aware simulator interaction fixes.
- `565e663cfea6c715199f4398875731956550125d`: explicit simulator boot, bounded tests and runtime diagnostics.
- `437b760` and `6437d8dea86877b99341f61932d40b98b18617aa`: adaptive ring geometry and earlier vertical layout at large text sizes.
- `52cc51ab5ba0799425a0788d8b9766e0e440ef71`: supported macOS 15 / Xcode 16.4 / iOS 18.5 CI environment, after latest-run queue/startup problems. Toolchain availability checked against [official runner documentation](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md).
- Implementation under review: `52cc51ab5ba0799425a0788d8b9766e0e440ef71` (includes earlier implementation/history). Handover-only documentation commits follow this SHA and do not imply another native build.
- Modified areas: root agent/README links; docs/product, docs/architecture, docs/handover; scripts/handover.py and tests; GitHub handover/iOS workflows; native App lifecycle, DesignSystem, feature views, UITests, project.yml, README/ROADMAP. See PR file diff and tasks.json for exact paths.
- Web application source, legacy Supabase schema/data, HealthKit query service and native agent instructions preserved. No production writes or permissions changes performed.

## Implemented M0 foundation (not complete product features)

Five tabs in approved order, independent navigation stacks, persisted selected tab. Shared adaptive colors/surfaces/cards/banners/metric tiles/activity cards/rings, Thai-first content, Dynamic Type and labeled fictional Feed/Today/Train/Me previews. Health begins with three tappable missing-score rings and detailed explanations; Me has none. Existing real on-device HealthKit controls/read displays retained; raw readings remain separate from scores. No native accounts, workout logging, GPS, social interactions, scoring or coach engine implemented here.

`status`, `next`, `prepare`, `validate`, `archive` commands work through portable Python standard library. Validator checks required fields, IDs, lifecycle, tracked files, approved requirement IDs, existing branch/commit ancestry, blockers and exact reviewed SHA/criteria for acceptance. Archive refuses unaccepted records and preserves immutable history. No automatic Claude invocation or acceptance.

## Verification

Local Windows: nine handover unit tests PASS, ten task records validate, status/next/prepare commands verified; archive correctly refuses P100-M0-001 because it is not accepted. `git diff --check` and Node syntax checks for unchanged v2-data/live-workout/wellness-insights/v2-health passed. These are not web behavior, RLS isolation or device tests.

Initial [simulator run](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43071252125) at `adfa55c` compiled and ran four UI tests: three passed, navigation test failed. Examined actual screenshot attachments and app hierarchy: missing launch-screen declaration produced legacy 320×480 compatibility bounds; the test also scrolled its target under navigation chrome. `9399655` adds UILaunchScreen, safe-area-aware test scrolling and explicit test dark-mode override. Duplicate/newer-run cancellation is enabled for future CI runs. Do not count the initial failed/superseded runs as PASS.

[Corrected screenshots](evidence/M0-9399655/README.md) at head `9399655` verify full 1206×2622 layout and dark appearance. That run passed the first three tests and exercised independent detail stacks, then was superseded during relaunch after slow simulator startup; it is not a complete PASS. Large-text ring geometry found during visual inspection is corrected in the later implementation SHA. PR workflows test a synthetic merge ref; each screenshot provenance file records head and tested merge SHA separately.

### Final observed CI disposition

| Evidence | Observed result | Scope |
|---|---|---|
| [Initial native run](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43071252125) | Simulator compile PASS; UI 3/4 PASS, navigation test FAIL | Head adfa55c; failure corrected later |
| [Corrected native run / screenshots](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43072638314) | Compile PASS; first three UI tests PASS; detail stacks retained; superseded during last relaunch check | Head 9399655; not a full-suite PASS |
| [Windows/Linux handover CI](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43072638436) | PASS on both OS jobs | Nine portable tests and ledger validation; handover script unchanged since this run |
| [Later native run](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43075144693) | Overall FAILURE; job/log APIs returned Server Error / ReadTimeout during investigation | Head 6437d8d; exact failure cause unverified, do not infer a compiler failure or PASS |
| [Pinned native PR run](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43095669281) / [push run](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43095662201) | QUEUED, no jobs created at last observation | Head 52cc51a; final simulator compile/UI verification BLOCKED |
| [Pinned handover PR run](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43095669277) | QUEUED, no jobs created at last observation | Local validation remains available; do not claim latest remote run passed |

The latest native source (including large-text ring changes) has **not** received a verified simulator PASS. M0 exit criteria are not all satisfied. P100-M0-002 tracks CI recovery and verification separately. Earlier unsigned simulator compilation is useful evidence but not verification of later source. No current run is assumed successful. Source screenshot gallery and provenance are preserved even though external Actions logs became unavailable. No real-device/signing evidence exists.

## Known issues and blockers

- P100-SEC-001: live authenticated extra grants include TRUNCATE; RLS does not protect truncation. No destructive test performed; no remote attack/data loss claimed. Review staged minimal-grant hardening before M1 cloud expansion.
- Existing HealthKit service still lacks persistent anchors/deletions, source attribution in display models, active-energy queries, HR/steps results, mockable repository and deterministic sleep/source/DST tests. Stage sums may overlap and source selection favors longest union. Track in M2; do not interpret displayed raw samples as reviewed wellness scores.
- Existing web skip is an explicit selection without dedicated confirmation; native training must implement the stronger approved confirmation rule. Native 10K is catalog preview only, with no reviewed prescription.
- Mobbin screens inaccessible; no Mobbin/Flownato MCP configured. Flownato public flow inventory only; no invented transition/screen findings. Detailed design reference review remains open.
- No Claude review received. No signing identity or physical-device execution access in this Windows session. Simulator evidence proves no HealthKit/Watch/GPS/background/real sync acceptance and produces no installable iPhone release. No paid service/membership purchased.
- Latest GitHub Actions runs are queued without jobs on both macOS and handover paths. Prior failure diagnostics are inaccessible through job API and connector; exact cause remains unknown. Pinned supported fallback was attempted; additional blind reruns were stopped. Unblock when Actions starts jobs and logs are accessible; inspect actual diagnostics and obtain a passing build/UI run for the exact implementation before M0 acceptance.

## Next actions and review gate

1. P100-M0-002: recover final CI evidence when Actions jobs/logs become available, diagnose the 6437d8d failure, verify exact latest source build/UI suite, and inspect updated large-text screenshots. No M0 acceptance until this passes.
2. Claude reviews exact implementation SHA using REVIEW.md; return requirement-linked findings. M0 stays READY_FOR_REVIEW, never self-accepted. Codex resolves findings and resubmits. Resolve P100-SEC-001 in a separate reviewed safe hardening task; test grants and anon/two-user access in disposable staging before production rollout.
3. After M0/security gates, P100-M1-001 adds existing-identity auth/restoration/logout isolation, owner-partitioned persistence and a non-destructive legacy adapter with conflict/isolation tests.
4. M2 then introduces mockable HealthKit boundaries, interval/source/timezone tests, anchors/deletions, missing-data-aware original scoring. M3–M7 remain separately scoped ledger records.
