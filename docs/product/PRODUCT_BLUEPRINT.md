# PROJECT 100M Product Blueprint

Approved specification: owner's master development prompt, 2026-11-12 (Asia/Bangkok). Version 1. Codex implements; Claude is architecture, UX/UI and code reviewer. GitHub is the source of truth.

## Mission

Build an original native iPhone fitness and social platform combining activity tracking, flexible structured training, sleep/recovery/load insight and explainable coaching. Preserve the existing web companion and Supabase identity/history. SwiftUI, iOS 17+ (existing minimum); future Apple Watch companion. Thai first, familiar English fitness terms, friendly accessible premium UI. No generative chat required for V1.

## Product contract

The normative, traceable requirements are in [FEATURE_REQUIREMENTS](FEATURE_REQUIREMENTS.md). Exactly five primary tabs: **Feed, Today, Train, Health, Me**. Independent native navigation state. Health starts with Sleep, Recovery, Strain rings; Me never duplicates them. Plans follow session order, never fixed weekdays. Completed advances; Partial retains the session/components; Skipped requires confirmation. Private workouts by default; publishing is explicit and separate from health records.

V1 must eventually deliver working accounts, offline training and live workout, direct authorized HealthKit reading, missing-data-aware original wellness models, a public feed with moderation, and evidence-based coach suggestions requiring approval before changing a plan. M0 sample screens do not satisfy those functional requirements.

## Design references and access

- [Strava / Flownato](https://www.flownato.com/apps/strava)
- [Strava / Mobbin](https://mobbin.com/apps/strava-ios-1ac190cf-46ee-4c65-845d-38bb8354219d/0581b139-5dc9-492d-89ad-da56951a027b/screens)
- [WHOOP / Mobbin](https://mobbin.com/apps/whoop-ios-f2d3db04-8fb3-4e1d-ada4-f5dc133be818/ff42691a-a36c-4a33-80c5-a349c719dfcb/screens)

2026-11-12: no Mobbin/Flownato MCP tools configured. Flownato public page exposes an Android flow inventory (onboarding, maps, recording, profile/settings); full flows require sign-in. Mobbin pages were inaccessible through browsing. No claims of inspecting their transitions or full card layouts. Existing web dashboard visually inspected: warm canvas, forest actions, next-session hero, progress and quick actions. Native interaction choices are original using system navigation. Detailed external reference review remains open; no proprietary screenshots, branding or artwork copied.

## Engineering and privacy constraints

SwiftUI feature modules, HealthKit, Core Location, offline-first persistence, Supabase Auth/PostgreSQL with strict RLS, user-controlled Storage media; future AI through authenticated backend/Edge Function only. Inspect deployed schema before additive versioned migrations; include rollback and verification, preserve `training_states`. Never commit provider/service credentials or real health exports. No production destructive changes without explicit approval. No automatic health/route sharing, home location exposure, or AI uploads. No paid dependency without approval.

Study NOOP only as architectural research: [upstream](https://github.com/DX23876/noop), [PolyForm Noncommercial 1.0.0 license](https://github.com/DX23876/noop/blob/main/LICENSE) verified 2026-11-12. Independently implement documented Apple APIs; copy no NOOP source/assets/restricted algorithms. Experimental scores are original hypotheses, never WHOOP scores, medical validation, diagnosis or automatic high-stakes decisions.

## Milestones and gates

| Milestone | Deliverable | Exit evidence |
|---|---|---|
| M0 Foundation/design | Audit, persistent requirements, handover tooling, architecture/data model, original tokens/components, five tabs and labeled preview states | Windows tooling checks, macOS simulator compile, Claude review; runtime visual evidence tracked separately |
| M1 Accounts/data | Existing Supabase identity, secure profiles, restoration, account-separated local persistence, safe legacy adapters | Auth/restore/offline/conflict tests and negative cross-user/RLS tests |
| M2 Health/wellness | Authorized native reads, anchors/deletions, foreground refresh, three interactive rings, trends, original scoring and provenance | Deterministic scoring/missing-data tests; distinguish simulator and device evidence; background only when feasible/tested |
| M3 Training | Five-program library, ordered progression, live running/strength, timers, partial logs, offline resume and conflict handling | Progression, offline relaunch and sync integration tests |
| M4 Social | Public feed, compose, likes/comments, profiles, report/block, pagination and location privacy | Public/private and blocked-user access tests; no private metrics/routes leakage |
| M5 Explainable Coach | History/baseline analysis, conservative suggestions with evidence/uncertainty, approved adjustments; future chat architecture | Rule/baseline tests; no unapproved plan mutation or AI transfer |
| M6 Integration/quality | Accessibility, layouts, loading/error/empty/offline, performance, integration/security checks and CI | Reviewer-approved release evidence and known-risk disposition |
| M7 Physical iPhone | Signed install; real HealthKit/Watch data, GPS/background, accounts/sync and end-to-end UX | Actual physical-device evidence only |

Continue incrementally after mandatory review. Lifecycle: BACKLOG → READY → IN_PROGRESS → READY_FOR_REVIEW → (CHANGES_REQUESTED → IN_PROGRESS) → VERIFIED → ACCEPTED. BLOCKED requires explanation and unblock condition. Never mark accepted solely from source or mock screens. No Claude integration is configured; copy-ready review instructions are required. Windows can author/check portable code; GitHub Actions macOS can compile unsigned simulator builds. Those builds are not installable iPhone releases. Signing and M7 remain separately tracked without assuming paid membership or buying anything.
