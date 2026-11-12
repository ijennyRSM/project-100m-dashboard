# Web expansion proposal — awaiting Claude review

2026-11-12. Planning only; no production UI or backend rewrite.

## Feature matrix

| Module | Production baseline inspected | Proposed original PROJECT 100M increment | Acceptance / dependency |
|---|---|---|---|
| Dashboard / feed | Next session, progress, quick actions; no social feed | Keep training first; separate optional published activity feed | Empty/offline/error states; private workouts never enter feed |
| Training history | Profile/plan records, Completed/Partial/Skipped | Filters, accessible history list, stable activity IDs | Existing records retained; Partial keeps current session |
| Activity detail | Prescribed session, quick logging, Live Workout | Read-only detail with provenance and missing-value display | Open/back retains filters; reload preserves selected record |
| Maps / pace / splits / HR | Imported workout summaries; no verified route recorder | Optional local GPX route viewer and derived splits | Explicit file selection; no upload; redact start/end before any publication |
| Calendar | Ordered sessions; dates do not advance plans | Calendar as an optional scheduling view | Missed date never skips; timezone/DST tests |
| Athlete profile | Local named profiles; existing cloud account | Separate private account and opt-in public projection | Never treat local profile ID as authenticated user UUID |
| Running statistics / PRs | Existing summaries and self-reported timings | Derived records by distance, source and timing method | Missing/incomparable inputs excluded; recompute after corrections |
| Health / recovery | Local Apple Health XML/ZIP import, recovery and insights | Provenance, coverage and explainable trends | No invented score; explicit consent before cloud transfer |
| Community | Not implemented on production Web | Publish preview, comments, likes, block/report | Reviewed schema/RLS, moderation and negative access tests first |
| 100m sprint analysis | Sprint prescriptions, repetitions, distance/time logs | Rep distribution, rest adherence, trend and timing-source labels | Hand timing / GPS / electronic timing kept distinct; no competition accuracy claim |

## Architecture and migration decision

Retain static HTML/CSS/JavaScript and GitHub Pages. A framework migration is not justified by the current setup task: existing modules already separate training state (`v2-data.js`), imports (`v2-health.js`), Live Workout, insights and rendering (`v2-ui.js`). New modules should expose narrow interfaces and be introduced one reviewed feature at a time. Consider a framework only if measured navigation/state/test complexity warrants its build pipeline and migration cost.

Proposed flow: original presentation components → feature controllers → training/activity repositories → versioned local storage adapters. A separate authenticated adapter may later reuse Supabase identity and reviewed normalized tables. Preserve legacy JSON, revision conflict handling, backups and all history. Do not repurpose the legacy table for public feeds. Public activity projections and private health/routes are separate, with owner-scoped policies and explicit publish/consent records.

The native app stays Swift/SwiftUI with its existing Core, Keychain and HealthKit services. Share domain contracts and backend identity, not UI wrappers or an assumption of implemented health sync. Native login/offline training exists on the latest handover branch but remains under review; HealthKit cloud sync is not established.

The repository's unresolved P100-SEC-001 grant finding blocks new cloud surface. No production SQL, health upload, automatic sharing, AI transfer or new backend is part of this proposal.

## References and limits

Public documentation was read; no signed-in Strava account or proprietary assets/code were accessed. Strava documents an activity detail page with statistics, biometrics, charts, maps and achievements, plus separate activity visibility settings: [Activity privacy controls](https://support.strava.com/en-us/articles/15401987-how-do-my-activity-privacy-controls-work-on-strava). Its [privacy controls index](https://support.strava.com/en-us/articles/15401951-privacy-controls) identifies profile, training log and map visibility as separate controls. These inform the separation above; PROJECT 100M defaults to private and requires explicit publishing. The public [features page](https://www.strava.com/features) yielded only a sparse navigation shell, so no full interaction walkthrough is claimed.

## Recommended next milestone

Claude reviews this proposal, infrastructure diff and test evidence first. Then implement one read-only activity-detail/history improvement using synthetic fixtures and local data, with preserved progression/history and no cloud/schema changes. Calendar, GPS, social and scoring are separate future reviewed milestones, not implied authorization from this proposal.
