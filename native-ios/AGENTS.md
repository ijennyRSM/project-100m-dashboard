# Native iOS agent instructions — PROJECT 100M

This directory is the SwiftUI native iPhone companion of the existing public web app.

## Safety / product invariants
- Preserve the root GitHub Pages site. Do not edit root index.html, v2-data.js, supabase schema, or live web release without a separate explicit task.
- The user's existing 100M plan advances ONLY when a session is completed. Partial/Skipped behavior must match the web app before native plan migrations.
- This branch is an early iPhone scaffold and has not yet passed real-device acceptance. Do not claim otherwise.
- HealthKit requests ONLY user-authorized sample types. No hidden tracking, mass historical upload, or auto-share.
- The initial HealthKit service is READ-ONLY and ON-DEVICE. NEVER upload medical/health data until the user signs in and approves a documented sync policy. Always display unknown or denied data as missing.
- The web Supabase project is shared with personal workout data. Enforce user identity, RLS, and explicit consent before adding any cloud sync.
- No secret/provider/service_role keys in Swift source, YAML, docs, workflows or GitHub commits.
- Apple Watch is accessed through HealthKit and watchOS APIs, NOT by reverse engineering Apple Watch Bluetooth.
- NOOP Forge source is under PolyForm Noncommercial 1.0.0. Do not copy files, code, bundled assets or design from NOOP into PROJECT 100M. Use Apple APIs and original implementation.
- The app should remain friendly, low-friction and accessible on small iPhone screens. Prefer Thai UI text with clear English metric terms.

## Claude — architecture and review role
1. Review HealthKit sample source attribution, authorization, deduplication, sleep-night grouping and unit normalization.
2. Propose SwiftUI screens, app navigation, normalized cloud event schema, consent and retention controls.
3. Review Apple Store policy/privacy and threat model before any cloud health upload.
4. Write acceptance criteria/tests and review Codex commits. Flag unknowns explicitly.

## Codex — implementation and testing role
1. Compile the app on an actual macOS Xcode environment or GitHub Actions macOS runner; resolve compiler/project errors.
2. Add mockable HealthKit repository protocol, deterministic tests for sleep interval union and missing samples.
3. Run the app on physical iPhone. Validate permission prompts, actual HRV/RHR/Sleep/Workouts, and no incorrect duplication.
4. Implement only features whose scope and acceptance are documented. Keep changes as small reviewable commits.
5. Preserve web behavior and project history. Add build/test evidence, not unsupported success claims.

## Required next milestone
- XcodeGen project generates; iOS Simulator build passes (HealthKit entitlement ignored for simulator test).
- Physical iPhone launches and shows accurate / missing metric values.
- HealthKit "no permission" states are calm and do not fabricate readings.
- No network transmission of health data.
- One architecture review from Claude and implementation review from Codex.

## Future sequence
iPhone login via existing Supabase -> explicit opt-in cloud metrics -> watchOS Live Workout -> sleep/recovery models -> AI Coach secured server-side -> social activities and clubs.

Read README.md and ROADMAP.md before implementing new features.
