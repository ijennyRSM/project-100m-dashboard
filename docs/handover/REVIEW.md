# Claude review

## Review record — M0 (P100-M0-001, P100-M0-002, P100-SEC-001)

| Field | Value |
|---|---|
| Reviewer | Claude (Opus 5.5), architecture / UX / security / code review role |
| Date | 2026-11-12 (Asia/Bangkok); CI observed 2026-11-11 20:44 UTC |
| Implementation SHA reviewed | `52cc51ab5ba0799425a0788d8b9766e0e440ef71` |
| Handover SHA reviewed | `7519937b728287b48992598a4770af0bbd8d00b3` (docs/evidence only; `native-ios` tree `932a53e1` and `.github` identical to 52cc51a) |
| PR | Draft [#1](https://github.com/ijennyRSM/project-100m-dashboard/pull/1), base `feat/ios-native-foundation`. Not merged. |
| **M0 disposition** | **CHANGES_REQUESTED. M0 is NOT ACCEPTED and NOT VERIFIED.** |
| P100-SEC-001 disposition | **CHANGES_REQUESTED → READY.** Critical. Must ship (staging-verified) before any M1 cloud work, new table, or new RPC. |

Scope: actual SwiftUI source, navigation, HealthKit boundary, adaptive layout, UI tests, CI workflow and live run state, committed screenshots, web/Supabase preservation, handover tooling and ledger, live-grant finding. No physical-device validation exists or is claimed. No production database access or change was made by this review; no destructive test was run. M1 not started.

### What I verified directly (evidence, not claims)

- **Five tabs, order, stacks, persistence — source PASS.** `native-ios/Features/RootView.swift:3-4` enum order feed/today/train/health/me; `:28-38` one `TabView` with five `NavigationStack(path:)`, each with its own `@State` path (`:19-23`); selection persisted through `@AppStorage("project100m.selectedTab")` (`:18`, `:24-26`), default Today. Titles render "Feed/Today/Train/Health/Me" (`:5`). Committed screenshot `M0-Today-light.png` shows the 5-item bar in order.
- **Rings only on Health, at the top — source PASS.** `Features/Health/HealthScreen.swift:14-20` ring row is the first content of the Health scroll view. `Features/Me/MeScreen.swift` has no `HealthRing`; no other file references `HealthRing` except its own preview. UI test `FoundationUITests.swift:66-69` asserts absence on Me.
- **Rings interactive — source PASS.** `HealthScreen.swift:7-11` each ring is a `NavigationLink` to `WellnessDetailScreen` (`:87-103`). UI test `:53-65` taps all three and checks detail navigation (last observed passing at 9399655 only).
- **No fabricated scores — source PASS.** State is hard-coded `.missing` (`HealthScreen.swift:9`); ring renders "—", caption "ยังไม่มีคะแนน", accessibility value "ยังไม่คำนวณ" (`DesignSystem/HealthRing.swift:33,55,64`). Detail screen says no score, not medically validated, no auto-adjust (`HealthScreen.swift:91,100`). Numeric states appear only in the `#Preview` with a fiction label (`HealthRing.swift:70-79`).
- **Sample labelling — PASS.** `SampleBanner` on Feed/Today/Train/Me and sub-screens; per-card "ตัวอย่าง" labels (`Components.swift:91,96`); fixtures documented as never persisted (`Features/PreviewContent.swift:3`). No inert action styled as working: web hand-offs are explicit `Link`s with "↗".
- **Web app and Supabase preservation — PASS.** `git diff origin/main 52cc51a` is empty for `index.html, app.js, v1.html, v2-*.js, live-workout.js, wellness-insights.js, *.css, cloud-config.js, supabase-schema.sql, payload/, icon.svg, CLOUD_SETUP.md, NOOP_INTEGRATION_ROADMAP.md`. Only root `.gitignore`, `AGENTS.md`, `README.md` changed. `native-ios/Health/*`, `native-ios/AGENTS.md`, `native-ios/CLAUDE.md` unchanged vs `15e10f0`. No native network code: the only URL is the public dashboard link (`Components.swift:13`); no keys in Swift/YAML.
- **HealthKit boundary — unchanged and still read-only.** `requestAuthorization(toShare: [], read:)` (`HealthKitService.swift:61`); no prompt on launch unless previously requested (`:41-42`); UI-test launches skip HealthKit (`App/PROJECT100MApp.swift:14,19`).
- **Handover tooling — PASS locally.** `python scripts/handover.py validate` → PASS 10 records; `python -m unittest discover -s scripts/tests` → 9 tests OK (Windows, Python 3.14). Validator enforces reviewer ≠ owner, exact commit and all-criteria-pass for VERIFIED/ACCEPTED (`scripts/handover.py:102-110`).
- **Live CI state (gh API, 20:44 UTC).** All seven runs for 52cc51a and 7519937 are `queued` — including the Ubuntu/Windows *Handover validation* runs — so the stall is not caused by the macOS-15/Xcode-16.4 pin. Run 43075144693 (6437d8d) failed after 8 min with an empty step list; job/log endpoints return HTTP 502; its artifact `ios-simulator-evidence-dcec212d…` (id 13883405985, 26.8 KB) exists but download returned HTTP 500/502. **No SHA in this PR has ever produced a complete 4/4 UI-test pass.**

## Findings

### Critical

**C1 — Production `public.training_states` grants TRUNCATE (plus DELETE, REFERENCES, TRIGGER) to `authenticated`; the repository SQL cannot fix or prevent it.** Task P100-SEC-001 · DATA-01, PRIV-01 · `supabase-schema.sql:12-13`
- Root cause, verified in source: line 12 revokes everything from `anon`, line 13 *adds* `select, insert, update` for `authenticated`, but nothing revokes the Supabase platform default (`ALTER DEFAULT PRIVILEGES … GRANT ALL ON TABLES TO anon, authenticated, service_role` in `public`). Running this file on a stock Supabase project yields exactly the live ACL observed. So this is not drift from the repo; **the repo file itself is not least-privilege**, and re-applying it is not a remediation.
- Impact: TRUNCATE is not subject to RLS and empties the whole table — every user's production training history — in one statement, irrecoverably without a backup. DELETE is currently neutralised by RLS (no DELETE policy), REFERENCES/TRIGGER have no current use. Backup/PITR status of the project is unknown.
- Likelihood today: PostgREST, GraphQL and the web client (`v2-data.js:107-108`, SELECT + `save_training_state` RPC only) expose no TRUNCATE path; exploitation needs any SQL-execution path running as `authenticated` (a future SECURITY INVOKER function with dynamic SQL, an extension, a misconfigured endpoint). Rated Critical because impact is total and irreversible, the default-ACL root cause will silently re-grant ALL on **every new M1 table**, and the project's top invariant is preserving production history.
- The audit only reported `authenticated`. It must also record `anon`, `PUBLIC`, and `pg_default_acl` for schema `public` (tables, sequences, functions).
- Required change: see **Security remediation plan** below. P100-SEC-001 moves to READY and blocks P100-M1-001.

### High

**H1 — No exact-source simulator build/UI evidence for 52cc51a; M0 acceptance criterion cannot pass.** P100-M0-002 · QA-01, UX-01 · `.github/workflows/ios-native-compile.yml`
- Evidence: see "Live CI state". Last compile PASS was 9399655 (superseded mid-suite); 6437d8d (which contains the ring geometry change) is an unexplained FAILURE; 52cc51a has never run. The committed gallery (`docs/handover/evidence/M0-9399655/`) predates the large-text ring changes and was captured on iPhone 17 Pro / iOS 26.4, whereas the pinned workflow now runs iOS 18.5 — the next screenshots will be a different OS/tab-bar style, so the old gallery cannot stand in for them.
- Required: (a) retrieve artifact 13883405985 and the 6437d8d log once the API recovers, and record the actual failure cause; (b) obtain one completed run with build PASS and **all four** UI tests PASS for native tree `932a53e147aa8543ad340e4d3249176fd7d7824f` (a run on 7519937 or a later docs-only head is acceptable evidence for 52cc51a **only if** `git rev-parse <sha>:native-ios` and `:.github` match — record both hashes in provenance); (c) commit the new light + dark-AX5 + detail screenshots with provenance (run id, artifact id, head SHA, merge SHA, device, runtime, sha256). Do not re-push code only to "kick" CI while Ubuntu jobs are also queued — check githubstatus.com / account Actions limits first.

**H2 — Small-screen, Dynamic Type and dark-mode claims are not asserted by any test.** P100-M0-001 · UX-01, QA-01 · `native-ios/UITests/FoundationUITests.swift:92-105`, workflow `:57-63`
- `testDarkModeAndAccessibilityText` only checks that navigation bars exist and that Sleep can be tapped; it does not check that rings/tiles are hittable, inside the screen bounds, or that dark mode actually applied. The simulator is `candidates[0]` of any iOS 18.5 iPhone (non-deterministic, never the smallest). DESIGN_SYSTEM.md:23 requires 320/375/393 pt, light/dark, default/AX5 — none of the widths is pinned or asserted.
- Required: pin the device by name (e.g. `iPhone 16` and `iPhone SE (3rd generation)`, 375 pt) and record it; in the AX5 test assert for each ring `isHittable` and `frame.minX >= 0 && frame.maxX <= app.windows.firstMatch.frame.maxX`; add an `xLarge` (non-accessibility) launch on the SE device; capture Health light/dark at default and AX5 on both devices. For the 320 pt Display-Zoom case (no simulator exists) add a hosted-view layout test or document it as M6 with Claude sign-off.

### Medium

**M1 — Ring row overflows narrow widths at `xLarge` text.** P100-M0-001 · HEALTH-01, UX-01 · `DesignSystem/HealthRing.swift:44,57`, `Features/Health/HealthScreen.swift:16-20`
- `@ScaledMetric` 88 pt relative to `.title2` gives ≈96 pt at `xLarge` (title2 22→24 pt). Three fixed-frame rings + 2×8 spacing = 304 pt; available width at 320 pt (iPhone SE/mini with Display Zoom, supported on iOS 17) is 320−32 = 288 pt. The fixed `.frame(width:height:)` cannot compress, so the HStack spills 8 pt into each margin and the Thai caption wraps into 2-3 lines. Vertical stacking starts only at `xxLarge`.
- Required: choose layout from available width rather than type size alone — e.g. `ViewThatFits(in: .horizontal) { HStack{rings}; VStack{rings} }`, or compute diameter from `GeometryReader`/`containerRelativeFrame` with min 72/max 160. Same treatment for the two `MetricTile`s (`HealthScreen.swift:33-37`). Test per H2.

**M2 — "Latest" HR/HRV values can be up to 21 days old with no sample date — misleading currency.** P100-M0-001 (copy) / P100-M2-001 (model) · HEALTH-01, HK-01 · `HealthScreen.swift:29-31,57-58`, `Health/HealthModels.swift:7-8`, `Health/HealthKitService.swift:103-106`
- The screen shows "อ่านล่าสุด <query time>" next to "bpm · ล่าสุดที่อ่านได้". The query time is *now*, but the value is the newest sample in a 21-day window and its `endDate` is discarded. A user will read a three-week-old RHR as today's. Not fabricated, but a misleading live-data impression, which the brief explicitly forbids.
- Required for M0: change tile caption to state the window (e.g. "ค่าล่าสุดภายใน 21 วัน") and distinguish "อ่านล่าสุด" as the read time. Preferred (small, additive, read-only): add `restingHeartRateDate`/`heartRateVariabilityDate` to `HealthSnapshot` and show "วัดเมื่อ …". Full source attribution stays in M2.

**M3 — Health screen does not distinguish not-connected, unavailable and error states.** P100-M0-001 · HEALTH-01, UX-01 · `HealthScreen.swift:21-28`, `HealthKitService.swift:12,52-70`
- Every `health.message` (authorization failure, "HealthKit ไม่พร้อมใช้งาน") is titled "อ่านข้อมูลไม่สำเร็จ". When access was never requested the app knows it (`hasRequestedAccess`), yet the sleep card says it cannot tell missing from denied (`:78`) and there is no primary connect call-to-action; `connection` (`.notRequested/.unavailable/.failed`) is published but never rendered. DESIGN_SYSTEM.md:23 lists unavailable / no-sample / request-error / loading as M0 review scenarios.
- Required: render from `connection`: not requested → calm CTA card to `HealthConnectionScreen`; unavailable → explanation without retry; failed → error title; requested + empty → current "may be missing or not allowed" copy. Add a `--ui-health-state=<state>` test hook using a stub (no HealthKit) and a UI test per state.

**M4 — CI concurrency makes push and PR runs cancel each other; docs-only commits cancel implementation runs.** P100-M0-002 · QA-01, HAND-01 · `.github/workflows/ios-native-compile.yml:20-22`
- `group: ios-${{ github.head_ref || github.ref_name }}` resolves to the same value for the `push` and `pull_request` runs of one SHA, so every SHA shows a cancelled twin (e.g. 43075135619, 43075055222). Because `pull_request` path filters evaluate the whole PR diff, a docs-only handover commit (7519937) also starts a native run that will cancel the 52cc51a run — the evidence-loss pattern seen at 9399655.
- Required: `group: ios-${{ github.workflow }}-${{ github.event_name }}-${{ github.head_ref || github.ref_name }}`, or drop the `push` trigger for `codex/**` (PR covers it). Record which run is the evidence of record per SHA.

**M5 — Ledger lifecycle under-states the P0 and lacks a review trail.** HAND-01 · `docs/handover/tasks.json` (P100-SEC-001), `docs/handover/CURRENT.md:52,58`
- P100-SEC-001 was BACKLOG (not actionable) while CURRENT calls it P0; `next` therefore never surfaces it. Its `commit` is the docs commit `ffada65`, which is fine for an audit but must be replaced by the migration commit when implemented.
- Done in this review: P100-SEC-001 → READY with reviewer findings; P100-M0-001 → CHANGES_REQUESTED with exact review record; P100-M0-002 remains BLOCKED with updated observation. Codex: move M0-001 to IN_PROGRESS when you start, back to READY_FOR_REVIEW with a new implementation SHA.

### Low

- **L1 — UI tests share persisted state.** `RootView.swift:18` `@AppStorage` survives between tests and reruns; `testIndependentStacksAndRestoredTab` leaves Me selected. Reset defaults when launched with a dedicated `--ui-reset` argument (do not override the key via the argument domain, which would mask restoration). UX-01/QA-01.
- **L2 — Score presentation type is too thin for M2.** `HealthRing.swift:23-38`: `.provisional(Double)/.available(Double)` carry no model version, confidence, coverage or provenance (SCORE-03), and `available` reads "มีข้อมูลพร้อม". Acceptable for M0 since unused; M2 must replace with a scoring-result type before any numeric state reaches a screen. P100-M2-001.
- **L3 — No iOS 17 runtime coverage.** Deployment target 17.0 (`project.yml:5`) but CI tests only iOS 18.5 (earlier 26.4). Add an iOS 17.x runtime job when runners allow, or record as M6 risk. QA-01.
- **L4 — Validator limits (by design, document them).** `scripts/handover.py:102-110` reviewer≠owner is string comparison and no transition history is stored; `next` ignores BLOCKED/BACKLOG P0 items. Consider a `priority` field and an append-only `history` list per record. HAND-01.
- **L5 — Direct table INSERT/UPDATE bypasses RPC validation for the caller's own row.** `supabase-schema.sql:13,46-55`: a user can PATCH their own `revision`/`payload` around the version-2 check. Self-scoped only; revisit with column grants or a SECURITY DEFINER RPC (fixed `search_path`) in M1. DATA-01.
- **L6 — Pre-existing HealthKit gaps (unchanged, tracked for M2):** observer refreshes dropped while `isLoading` (`HealthKitService.swift:79`), longest-union single-source selection and per-stage overlap (`:203-221`), noon/DST grouping (`:193-197`), HR/steps requested but unused (`:33-35`), no anchors/deletions. P100-M2-001.

## Security remediation plan — P100-SEC-001 (proposal; not applied anywhere)

**Constraints:** no production change without owner approval; no TRUNCATE/DELETE test on production; all destructive tests only on disposable local/staging data with synthetic users.

### 0. Read-only inventory (production, owner runs or approves)
```sql
select grantee, privilege_type from information_schema.role_table_grants
 where table_schema='public' and table_name='training_states' order by 1,2;
select relacl from pg_class where oid='public.training_states'::regclass;           -- save verbatim for rollback
select pg_get_userbyid(defaclrole), defaclnamespace::regnamespace, defaclobjtype, defaclacl from pg_default_acl;
select p.oid::regprocedure, p.proacl, p.prosecdef from pg_proc p
 where p.pronamespace='public'::regnamespace;
select polname, polcmd, polroles::regrole[], pg_get_expr(polqual,polrelid), pg_get_expr(polwithcheck,polrelid)
  from pg_policy where polrelid='public.training_states'::regclass;
select version();   -- PG17 adds MAINTAIN; the migration below is version-agnostic
```
Also confirm backup/PITR availability and take an owner-controlled backup (not committed).

### 1. Migration A — table/function least privilege (proposed path `supabase/migrations/20261112090000_p100_sec_001_training_states_least_privilege.sql`)
```sql
begin;
set local lock_timeout = '5s';

do $$ begin
  if to_regclass('public.training_states') is null then
    raise exception 'P100-SEC-001: public.training_states missing';
  end if;
  if to_regprocedure('public.save_training_state(bigint,jsonb)') is null then
    raise exception 'P100-SEC-001: save_training_state(bigint,jsonb) missing';
  end if;
end $$;

-- Reset to nothing, then grant exactly what the web client + SECURITY INVOKER RPC need.
revoke all on table public.training_states from public, anon, authenticated;
grant select, insert, update on table public.training_states to authenticated;

revoke all on function public.save_training_state(bigint, jsonb) from public, anon;
grant execute on function public.save_training_state(bigint, jsonb) to authenticated;

-- Post-conditions: fail the transaction (and roll back) if anything unexpected remains.
do $$
declare p text;
begin
  foreach p in array array['DELETE','TRUNCATE','REFERENCES','TRIGGER'] loop
    if has_table_privilege('authenticated','public.training_states',p) then
      raise exception 'P100-SEC-001: authenticated still has %', p; end if;
  end loop;
  foreach p in array array['SELECT','INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER'] loop
    if has_table_privilege('anon','public.training_states',p) then
      raise exception 'P100-SEC-001: anon still has %', p; end if;
  end loop;
  foreach p in array array['SELECT','INSERT','UPDATE'] loop
    if not has_table_privilege('authenticated','public.training_states',p) then
      raise exception 'P100-SEC-001: authenticated lost required %', p; end if;
  end loop;
  if has_function_privilege('anon','public.save_training_state(bigint,jsonb)','EXECUTE')
     or not has_function_privilege('authenticated','public.save_training_state(bigint,jsonb)','EXECUTE') then
    raise exception 'P100-SEC-001: RPC execute grants wrong';
  end if;
  if not (select relrowsecurity from pg_class where oid='public.training_states'::regclass) then
    raise exception 'P100-SEC-001: RLS disabled';
  end if;
end $$;
commit;
```
`service_role` and the table owner are intentionally untouched. Idempotent (safe to re-run). No data or policy change. Also update `supabase-schema.sql:12-13` to the same `revoke all … from public, anon, authenticated` + explicit grant so a fresh project is correct (a separate reviewed commit; this changes a preserved file, so call it out in the PR).

### 2. Migration B — default privileges (separate, reviewed before M1 creates any table)
```sql
alter default privileges for role postgres in schema public revoke all on tables    from anon, authenticated;
alter default privileges for role postgres in schema public revoke all on sequences from anon, authenticated;
alter default privileges for role postgres in schema public revoke all on functions from public, anon, authenticated;
```
Run for every role that creates objects (check `pg_default_acl` output from step 0). Consequence: every M1 table/function must carry explicit grants in its own migration — add that to the M1 migration checklist and a CI lint that fails on a `create table`/`create function` without a matching `grant`.

### 3. Staging verification (disposable; local `supabase start` or a throwaway project — no production data)
1. Apply current `supabase-schema.sql`, then reproduce the live ACL from step 0 exactly (`grant all … to authenticated`), and snapshot `relacl`.
2. Create synthetic users A and B; seed one row each.
3. **Prove the test detects the hole**: as `authenticated` (`set local role authenticated; set local request.jwt.claims = '{"sub":"<A>","role":"authenticated"}'`) `truncate public.training_states` succeeds in staging only; reseed.
4. Apply Migration A twice (idempotency). Then, as A: `truncate` → SQLSTATE 42501; `delete` → 42501; select returns only A; update/insert targeting B → 0 rows / RLS violation; `save_training_state` with correct revision → revision+1, stale revision → NULL; as `anon`: select/insert/RPC → 42501.
5. Point a local copy of the web app at staging: sign in, pull, record a session, sync, force a conflict — all unchanged.
6. Encode 3–4 as pgTAP (`supabase/tests/p100_sec_001.sql`) and run in CI against `supabase start`; attach output to the task.
7. Apply Migration B in staging; create a scratch table and confirm anon/authenticated get no privileges; drop it.

### 4. Production rollout (owner-approved window)
Backup confirmed → read-only step-0 snapshot → apply Migration A in one transaction (post-condition block aborts on surprise) → read-only re-run of step 0 and the `has_table_privilege` matrix (no destructive probe) → owner web smoke test (sign in, load, save one session) → watch PostgREST/API logs for 42501 for 24 h → record evidence in P100-SEC-001.

### 5. Rollback
Primary: forward-fix — re-grant only the specific privilege a verified client error proves is needed (none expected: the web client uses SELECT + RPC, and the RPC needs only INSERT/UPDATE). Emergency exact restore (owner approval only; re-opens the hole):
```sql
grant delete, truncate, references, trigger on table public.training_states to authenticated;
```
Migration B rollback: re-run the `alter default privileges … grant all …` statements captured from step 0. Neither migration touches rows, so no data rollback exists or is needed.

## M0 acceptance disposition

| P100-M0-001 criterion | Result | Evidence / reason |
|---|---|---|
| Five tabs in order; independent stacks; restored selection | **Source PASS, runtime NOT VERIFIED** | RootView.swift:18-38; last runtime at 9399655 stopped before the relaunch assertion |
| Reusable adaptive components; labelled fixtures | **Partial** | Labels/components pass; M1 (narrow width), M2 (currency copy), M3 (states) open; no latest dark/AX5 screenshots |
| Three interactive Health-only rings; no invented scores | **Source PASS, runtime NOT VERIFIED for 52cc51a** | HealthScreen.swift:7-20, HealthRing.swift; test passed only at 9399655 |
| Windows handover + exact-source macOS build/UI pass | **FAIL** | Handover PASS locally; native exact-source run never executed (H1) |
| Claude review of criteria and UX evidence | **Done — CHANGES_REQUESTED** | This document |

**M0: CHANGES_REQUESTED. Not ACCEPTED, not VERIFIED.** PR #1 must stay Draft and unmerged. No physical-device, signing, HealthKit-data, Watch, GPS or background claim is made or implied.

## Claude → Codex handover

```yaml
review_of: P100-M0-001 @ 52cc51ab5ba0799425a0788d8b9766e0e440ef71 (handover 7519937)
decision: CHANGES_REQUESTED
do_not: [merge PR #1, start M1, touch production DB, mark anything ACCEPTED/VERIFIED, claim device results]
required_for_M0_resubmission:   # owner Codex, branch codex/m0-foundation-handover
  - id: H1   # P100-M0-002
    do: retrieve 6437d8d logs/artifact 13883405985, record cause; get one completed run with build PASS + 4/4 UI PASS on native tree 932a53e1 (or the new tree after fixes)
    evidence: run id, artifact id, head+merge SHA, native/.github tree hashes, device+runtime, screenshots + sha256
  - id: M4
    do: split concurrency group by event (or drop push trigger for codex/**) — ios-native-compile.yml:20-22
  - id: H2
    do: pin named simulators (iPhone 16 + iPhone SE 3rd gen); add bounds/hittable assertions at xLarge and AX5; dark+light captures
  - id: M1
    do: width-driven ring/tile layout (ViewThatFits or container-relative diameter) — HealthRing.swift:44,57; HealthScreen.swift:16-20,33-37
  - id: M2
    do: honest freshness copy for RHR/HRV (minimum) or additive sample dates — HealthScreen.swift:29-31,57-58; HealthModels.swift:7-8
  - id: M3
    do: render connection states (notRequested CTA / unavailable / failed / empty / loading) with stubbed UI-test hook
  - id: L1
    do: reset persisted tab under --ui-reset for test isolation
then: set P100-M0-001 READY_FOR_REVIEW with the new implementation SHA (separate handover commit), update CURRENT.md, run `python scripts/handover.py validate`
parallel_priority_task:          # independent of M0 UI work; blocks M1
  - id: P100-SEC-001 (status READY)
    do: implement Migration A (+ schema file fix) and pgTAP tests per REVIEW.md plan; staging evidence; propose Migration B
    never: run TRUNCATE/DELETE against production; apply to production without owner approval
deferred_to_M2: [L2 score-result type, L6 HealthKit gaps]
recommended_tests:
  - UI: tabs order/count; Health first element is ring row; rings hittable+in-bounds at default/xLarge/AX5 on SE and 16; Me/Today/Feed/Train have no ring-* ids; detail back navigation; stack retention; relaunch restore after --ui-reset
  - UI states: HealthKit notRequested/unavailable/failed/empty/loading via stub
  - DB (staging pgTAP): authenticated TRUNCATE/DELETE → 42501; anon all → 42501; A cannot read/write B; RPC stale → NULL; RLS enabled
```

---
*Previous status line (superseded by this review): "pending; no Claude review has been received."* Codex resolves findings and resubmits; a handover file cannot execute Claude.
