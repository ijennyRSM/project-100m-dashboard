# System architecture

## Current boundary

Web remains static GitHub Pages with profile-scoped localStorage and Supabase Auth / `training_states` revision RPC. Native iOS 17 SwiftUI has a main-actor read-only HealthKit service; no native network sync. M0 changes presentation and handover, not the production database.

## Target modules

`App` owns lifecycle and five independent `NavigationStack`s. `DesignSystem` owns adaptive tokens/cards/rings/state banners. Feature modules: Feed, Today, Train, Health, Me; shared domain models remain framework-light. Services are injected through repositories: HealthRepository, TrainingRepository, ProfileRepository, SocialRepository. Introduce protocols when adding tested domain functionality (Health service injection/interval tests first in M2, not falsely claimed in M0).

M0 redesign keeps native TabView/stack ownership and stored selection; a custom Material capsule presents the five destinations while the stock bar is hidden. Maps belongs to Train and Groups to Feed, preserving dedicated Health. Sample filters/section selections are transient view State, with no network, user-data migration or domain mutation. Original Canvas route illustrations have no coordinates. See DESIGN_ALIGNMENT for navigation/accessibility tradeoffs and Material versus native SDK26 Liquid Glass scope.

Local persistence is the source for immediate UI; repositories enqueue durable idempotent outbox operations. Partition database/files/cache and outbox by authenticated user UUID; guest is separate. Logout cancels queries, clears visible state, scopes cache, and invalidates pending work for that session before another user signs in. Keychain for session secrets; OS file protection for sensitive local persistence. Restoration must never merge a guest profile into an account without approval.

HealthKit → authorized samples → normalized on-device records → versioned aggregation/baseline/scoring → private Health/Coach. Persist query anchors atomically with changed samples/deletions per type/account/device; reset/rebuild safely on invalid anchor. Query cancellation, concurrent refresh serialization, stale snapshots, source identity and day/timezone policies need M2 tests. Background observer acknowledgement follows durable processing and Apple's delivery limits. No network HealthKit transfer until category-specific sync consent is approved.

Training templates → enrolled plan → ordered sessions → component attempts → workout/event history → next session. Imported HealthKit workout is not evidence that a prescription was completed. Never derive plan progression from dates. An append-only attempt/event model must reconcile conflicts; preserve Partial work and explicit skip approval. Legacy JSON revision conflicts require backup and user resolution; never silently replace newer local history.

Supabase JWT identifies private ownership. Additive normalized tables coexist with untouched legacy `training_states`. Public posts contain an explicit safe activity projection, never joins that expose private health/route data. Storage policies verify owner on upload and post visibility/block status on reads; private originals and sanitized published media separate. Strip EXIF; trim routes around sensitive areas before publish preview. Report queue restricted to moderators; block enforcement in server reads/writes, not UI filters alone. Pagination cursor `(published_at,id)`; likes unique by post/user; comments length/rate limits and report controls.

## Future AI (AI-01)

Optional authenticated Edge Function verifies JWT and consent receipt, fetches minimal owner-scoped context, enforces rate/budget limits and redacted logging, calls provider using server secret, returns cited evidence/uncertainty. Treat notes/posts as untrusted data. Advice is read-only; a separate explicit user-approved command changes a plan. Revocation stops future transfers; retention/export/deletion documented before launch. No AI provider or billable service configured in M0.

## Verification and gates

Portable handover tests on Windows/Linux; macOS XcodeGen builds and native unit/UI tests. Simulator screenshots validate actual views when available. Physical signed iPhone/Watch required for permissions, real data, GPS/background and synchronization acceptance. No simulator artifact is an iPhone release. Claude reviews each milestone before expansion. See [audit](REPOSITORY_AUDIT.md), [decisions](DECISIONS.md) and [handover](../handover/CURRENT.md).
