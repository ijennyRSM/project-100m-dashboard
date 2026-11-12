# Approved feature requirements

Stable IDs connect implementation, tasks, tests and review. All are approved requirements; status is in the audit/task ledger, not implied by this document.

| ID | Requirement and acceptance contract |
|---|---|
| NAV-01 | Exactly Feed, Today, Train, Health, Me in that order; native SwiftUI navigation; preserve tab selection and independent stacks. Feed leftmost, Me rightmost. |
| UX-01 | Original Thai-first, accessible iOS 17+ design; Dynamic Type, VoiceOver, clear touch targets, light/dark and reduced motion; future watchOS, web companion preserved. |
| UI-01 | Owner screenshot-led latest-Strava-inspired visual structure, original assets/identity; user images override conflicting older web references. Mandatory light/dark themes; floating translucent capsule navigation with clear active state and accessible opaque fallback. Keep NAV-01 and first-class Health; Maps under Train, Groups under Feed. Samples labeled and never imply backend/GPS/recording functionality. See DESIGN_ALIGNMENT for observed references, mapping tradeoffs and iOS17 Material vs native Liquid Glass distinction. |
| FEED-01 | Functioning public feed of explicitly published activities from all users; Running, Walking, Strength and other supported types. Cards show name/avatar/time/description/summary; optional photos/maps. Compose, like, comment, profile navigation, report/block, pagination, loading/empty/error states. |
| PRIV-01 | New workouts private by default; explicit publish action; never automatically publish private health metrics, home locations or detailed routes. Separate private health and public projections; user-controlled media and consent. |
| TODAY-01 | Personalized greeting, next workout, current plan/progress, recent activity, concise recovery, quick actions. Next step obvious; missed dates never expire/skip sessions. |
| TRAIN-01 | Independent multi-user plans: 100M — The Comeback, 5K Foundation, 10K Progression, Strength Foundation, Active Wellness. Low-friction prescribed workouts. |
| TRAIN-02 | Completed advances; Partial retains current session and records components; Skipped advances only after explicit confirmation. No calendar-driven skipping. |
| LIVE-01 | Warm-up checklist, sprint reps, strength sets/reps, rest/elapsed timers, RPE/notes, pause/resume, offline persistence, Completed/Partial logs. |
| RUN-01 | Progressively add native GPS recording, pace/distance/splits/PRs, appropriate location permission and route privacy controls. |
| HEALTH-01 | Three large interactive rings at Health's very top: Sleep, Recovery, Strain. Each opens detail analysis. Never at top of Me. Explicit missing, insufficient baseline, provisional and available states. |
| HK-01 | Direct native authorized reading without XML/ZIP: sleep duration/stages, HRV SDNN, RHR, HR, steps, workouts, relevant distance/active energy. Appropriate queries/units/source attribution, durable anchors, UUID deduplication/deletions. Foreground refresh required; background delivery implemented/tested when feasible, never guaranteed real-time. Prompt completion is not proof of read permission. |
| SCORE-01 | Sleep hypothesis: 60% duration sufficiency, 20% timing consistency, 20% efficiency only with reliable in-bed data. Actual duration/stages separate. Document missing-component policy and calibrate; not medically validated. |
| SCORE-02 | Recovery hypothesis: 40% personal HRV baseline comparison, 30% personal RHR baseline comparison, 20% sleep, 10% self-reported fatigue/soreness. Require sufficient baseline; never fabricate inputs. |
| SCORE-03 | Original documented strain using HR zones, duration/intensity, recent load, RPE and fitness baseline. Every score has version/confidence/provenance and an explanation; never claim WHOOP algorithm or use for automatic medical decisions. |
| ME-01 | Avatar, display name/username, bio, public posts, workout history, PRs, achievements, account/device/privacy/sharing settings. No health-ring trio. |
| COACH-01 | Working explainable V1 rules analyze history and available sleep/HRV/RHR trends; conservative unusual-change/recovery observations and suggested adjustments; show evidence/uncertainty; never mutate plan without approval. Generative chat not required. |
| AI-01 | Separate future secure backend/Edge Function architecture; no AI secrets in app; explicit authorization before transmitting selected health records. |
| DATA-01 | Reuse Supabase user identity, secure auth/session restoration, owner-partitioned offline data, safe migration adapters, strict RLS, additive versioned migrations with rollback/verification. Preserve legacy web and all production history. |
| HAND-01 | Persistent task IDs, milestone, owner, lifecycle, branch/actual commit, requirements, changes/files/tests/issues/findings/actions/criteria; Windows status/prepare/validate/archive/next commands, CI, immutable history, no automatic Claude execution or self-acceptance. |
| QA-01 | macOS CI unsigned simulator build and meaningful automated checks; accessibility/responsive/error/offline/performance/integration/security evidence. Separate signing, physical HealthKit/Watch/GPS/background/sync acceptance in M7. |

## Score research protocol (M2 design, not implemented)

Keep missing components missing; do not silently reweight to a confident full score. Candidate baseline: at least 14 valid prior days in a 28-day window, exclude today's sample, display coverage/age/source. Claude must approve baseline sufficiency, normalization, stale limits and calibration before implementation. Sleep with no reliable in-bed coverage can show duration and provisional component analysis, not a fabricated efficiency value. Recovery cannot be available without personal HRV/RHR baseline. Strain needs zone coverage/duration and documented handling for strength/RPE or missing HR; no precision claim from sparse samples. Validate boundary, overlap, source, timezone/DST, stale and missing-data cases independently of real-device checks.
