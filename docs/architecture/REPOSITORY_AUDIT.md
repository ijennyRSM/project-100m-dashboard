# Repository audit — 2026-11-12

## Evidence and scope

Clean local checkout `E:\Project100M`, origin `ijennyRSM/project-100m-dashboard`; fetched both refs before changes. main = `53ba1b5aad9605309407ba186d816ed6aa77fd3e`; native = `15e10f0ae2f17ff4b65288c4012174dc0631afb3`. Native descends from main, adding 10 files / 922 lines only, no divergent web changes. Main history includes V4 live workout/sleep/coach and V4.1 streaming ZIP import. Native history adds HealthKit, SwiftUI, XcodeGen/CI, then optional type/distance compiler fixes. Existing foundation was not assumed to pass current build or device tests.

Verified all owner-listed paths exist. Read root README/CLOUD_SETUP/NOOP roadmap/schema, web data/live/insights/import/UI and HTML/style structure, all native README/ROADMAP/AGENTS/CLAUDE/project/source/workflow files. No root AGENTS, package manifest, native test target or test suite existed. Initial git identity unset; implementation commits use explicit Codex agent attribution, not owner impersonation.

Live website opened through browser: Today hero, next Sprint A + Strength A prescription, current plan/progress, quick actions, details form with Completed/Partial/Skipped and recovery missing-data/check-in UI. No workouts/auth/import writes performed. Public dashboard styling is warm forest/mint with Thai text and large cards. Source inspection supplies behavior findings below, not claims of end-to-end cloud/device tests.

## Feature inventory

| Area | Existing web | Existing native / gaps |
|---|---|---|
| Plans/progression | 100M 60 sessions; 5K, strength, wellness; multiple profiles/plans; latest record per session; completed/skipped advances, partial stays, no date expiry | Links to web only. 10K missing on both. Native ordered domain engine missing. Web skip selection is explicit but lacks dedicated confirmation; new native requirement is stronger. |
| Live workout/history | Prescribed warm-up/sprint/strength/cooldown, per-unit counters, elapsed/rest, pause/resume, local profile draft, Completed vs Partial, history/backup/report | Native live workout, durable offline store, GPS/splits/PR missing. Web component partial state is rendered into notes/sets; migration needs structured preservation. |
| Recovery/coach | Manual recovery, RHR/sleep trends, sleep target/stages, original rules, no AI call | Native latest RHR/HRV/sleep/workouts only; no baseline/scoring/coach. Web target percent is not sleep/recovery score. |
| Apple Health | Streaming XML/ZIP; bounded recent selected metrics, interval union, imported workout dedup; raw export stays local; extracted metrics may sync after consent | Native read-only HK authorization, recent 21-day samples, foreground/in-process observers, source-per-night sleep union. No persistent anchors/deletions/background delivery. HR/steps requested but not queried/displayed. Active energy not requested. Distance read from workout. |
| Health correctness | Union avoids total sleep double-count; per-stage unions can overlap across labels/sources | Native picks source with greatest union, loses source attribution in output, per-stage overlaps may exceed total, noon grouping/DST and bounds need tests. No fake metrics on missing reads; prompt success correctly not permission proof. Refresh error retains old snapshot without explicit staleness UI. |
| Accounts/sync | Magic Link, persisted session, UUID namespace, revision RPC, conflict status, guest-copy confirmation, local backup before pull | Native auth/profile/account isolation/sync absent. Real email redirects/two-device sync still unverified. Web async account switching/sync requires race tests before reuse. |
| Social | No public feed/post/like/comment/moderation | Entire functional social stack missing. Private health schema must stay separate. |
| UI/quality | Thai web tabs, responsive cards | Four native tabs; hardcoded white cards/fixed type sizes; no test target, no UI screenshots/device evidence. |

## Database inspection (metadata only)

Connected Supabase project from CLOUD_SETUP. Verified public table columns, FK, policies, RPC definition and grants through read-only queries. RLS owner checks and security-invoker revision function match source. **P0:** authenticated has extra DELETE/TRUNCATE/REFERENCES/TRIGGER privileges; TRUNCATE is not constrained by RLS. Source SQL does not grant those. No production grant/schema/data modifications. See DATA_MODEL and task P100-SEC-001; do not claim deployed isolation validated by policy inspection alone.

Review correction (f2b370f, followed by remediation work): absence of explicit broad GRANT in the setup is insufficient. Supabase default ACLs grant ALL when objects are created; the legacy setup never revoked authenticated's existing grants. Local PG16/17 tests reproduce the hole using the original file. PG17 live inventory also identifies MAINTAIN and broad defaults for postgres/supabase_admin. The approved review-fix task authorizes a safe setup-file correction and prepared ACL migration, separately from native UI work; production remains unchanged. See `supabase/security/README.md` and the new handover evidence.

## Reuse and migration

Reuse program definitions, ordered session identities, latest-status semantics, effort/rest prescriptions, independent profiles/plans, revision conflict detection and transparent coaching principles. Port domain logic into tested Swift, not a web wrapper. Preserve attempt timestamps/status and legacy identity mappings; HealthKit imports never auto-complete prescribed sessions. Add 10K after training design review. Keep health data local until explicit per-category cloud consent; publish only safe explicit activity projections. M1 requires staging security tests and grant hardening before cloud expansion.

## Environment and external references

Windows: Python 3.14 and Node available; no local Xcode/Swift/gh. Git and connector access available; push authentication tested later. CI originally macos-latest + XcodeGen generic unsigned simulator build, only native foundation branch pushes, no PR trigger/tests/artifact capture. M0 will add selected branch/PR coverage. No signing identity, physical iPhone/Watch access or Claude integration in this execution. M7 remains open.

Mobbin/Flownato access limitations and NOOP license findings are recorded in PRODUCT_BLUEPRINT; no proprietary source/artwork imported. Existing roadmap's M0 physical-device requirements are moved to M7 by approved specification; safety acceptance remains mandatory.
