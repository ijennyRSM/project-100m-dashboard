# PROJECT 100M Native App — product and engineering roadmap

> Historical roadmap below. The approved 2026-11-12 [Product Blueprint](../docs/product/PRODUCT_BLUEPRINT.md) now defines M0–M7; [tasks](../docs/handover/tasks.json) and [CURRENT](../docs/handover/CURRENT.md) track actual progress. Old M0 physical-iPhone acceptance is now M7 and remains required. Do not infer completion or sequence from the legacy headings below.

## North Star
A friendly, privacy-aware fitness companion combining:
- Runna-like session-based adaptive training, not fixed calendar guilt
- WHOOP-like explainable sleep/recovery insights, without impersonating their proprietary scores
- Strava-like real running, GPS routes, pace, splits and personal records
- Social feed, friends and clubs (private by default, explicit sharing)
- User-controlled AI Coach using training/recovery context on demand

### Platform
SwiftUI iOS 17+; HealthKit; future watchOS SwiftUI/HKWorkoutSession; offline-first local cache; Supabase Auth/RLS; backend Edge Functions for AI. Reuse existing PROJECT 100M web plan and Supabase account; do not launch another incompatible set of identities.

## M0 — HealthKit MVP (this branch, scaffold in progress)
App installs on physical iPhone and:
- Requests read-only Apple Health permission by explicit tap
- Reads recent sleep, resting heart rate, HRV SDNN and completed workouts
- Refreshes on foreground and HealthKit changes while app runs
- Shows a reassuring empty state when records aren't present
- Doesn't upload data anywhere or assume all read permissions were granted
- Shows the original web training plan via Link, without modifying it

**Exit criteria**: Xcode/macOS build passes; real iPhone signed build; a real permitted sample appears; denial/absence handled; reviewed test screenshots or logs. A source commit is not acceptance.

## M1 — iPhone accounts + secure optional health sync
- Supabase login using original account identity (separate users for each phone)
- Session recovery, logout and local data partition per account
- Normalized workout and health summary tables with RLS and real-device cross-user tests
- Consent screen chooses which metric categories may sync, with independent revoke/delete/export
- Durable deduplication by source UUID and versioned timestamp+unit; deletions supported
- HealthKit anchored queries and background observers with persistent anchor; demonstrate actual constraints
- Existing session plan progression must retain Completed/Partial/Skipped semantics
- Migration must not overwrite old training_states data

## M2 — watchOS workout companion
- Apple Watch SwiftUI app, HKWorkoutSession/HKLiveWorkoutBuilder, permission prompts
- Live running screens: elapsed, HR, pace, laps, intervals, rest haptics
- Sprint sets, strength sets, rest timer and handoff to iPhone
- WatchConnectivity for sync; offline workout persistence
- Avoid claiming wrist GPS/Watch estimates can time 100m sprint to competition accuracy

## M3 — Recovery intelligence
- 14–30-night personal sleep/HRV/RHR baseline; input sources and confidence visible
- Estimated sleep debt, trends and fatigue check-in; insufficient data yields unknown
- Readiness suggestions never act as medical diagnosis
- Workout adaptation proposed, user approves before plan changes

## M4 — AI Coach
- Supabase Edge Function with user JWT verification, server-side provider secret, budget/abuse limits
- Data minimization, opt-in sending of selected metrics, no public health feed
- RAG over user's own session rules and plan; citations to dated metrics
- Read-only plan advice initially; explicit confirmation required before editing anything

## M5 — Social + GPS
- User-controlled profile and privacy levels; default new activities private
- Running routes, GPX/FIT exports, splits, badges, photos, comments and clubs
- Separate social data schema and moderation/abuse/reporting controls
- Community UI must not leak HealthKit HRV/sleep details without explicit selection

## NOOP licensing
NOOP Forge https://github.com/DX23876/noop is a reference for public technology choices and system architecture only. Its original source is PolyForm Noncommercial 1.0.0, so don't copy it if the intent is a potentially commercial app. Our own native implementation uses platform APIs.

## Cloud-first versus local-first
- HealthKit is the local system data source on iPhone; the app chooses what to summarize and upload.
- Supabase holds account, plan, workout and opt-in metric summaries; not full raw HealthKit exports.
- No background execution or live sync guarantee beyond Apple's documented delivery limits.
- Personal training data and social content have separate access policies and auditing.

## Next Codex checkpoint
1. Open native-ios/project.yml on macOS with XcodeGen and build the PROJECT100M target.
2. Fix compile errors and add tests for the grouping and overlapping-sleep logic.
3. Validate HealthKit entitlement on a signed real-iPhone build.
4. Return a clear report: compile PASS/FAIL, device PASS/FAIL, current limitations.
