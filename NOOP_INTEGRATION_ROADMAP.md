# PROJECT 100M V4 — Live Workout, Apple Health, Sleep Insights & Coach

## Current implementation (live on GitHub Pages)
- **Live Workout Mode** is independent code in live-workout.js. Start from Next Workout or Workout Details. Tracks warm-up, sprint repeats, leg-strength sets and cooldown separately; includes a rest timer and manual completion checklist.
- An unfinished Live Workout is saved on the athlete's profile (JSON state, localStorage and optionally the existing Supabase cloud profile). You can leave and resume it.
- **Correct plan progression:** finishing a Live Workout where all units are checked records Completed. Otherwise it records Partial, keeps the same next Session, and tells the athlete. There is an explicit cancel with confirmation. Opening the screen is not evidence of training completion.
- Rest timer uses the phone's system clock while the page is open. It does not provide a hardware sprint timer, reliable background alarms, or GPS timing.
- **Apple Health file import** reads recent resting HR, HRV, supported Workout records, sleep duration and Apple sleep stages (Core, Deep, REM, Unspecified, Awake, In Bed) from XML/ZIP. Aggregation unions overlapping sleep intervals instead of adding duplicate entries. Raw file is not uploaded; extracted data can sync if Supabase cloud is already enabled.
- **Sleep Insights (beta)** shows time asleep, a configurable personal sleep target, the last-seven-night average, Apple sleep stages if present, and incomplete-data notices. Percentage shown is **percent of personal sleep target, not a WHOOP or clinical score**.
- **Coach Insights (beta)** explains observations using transparent local rules, the user's training logs, sleep trend, RHR, and HRV where available. It is NOT a generative AI model. The app does not send health data to an AI provider by itself.

## NOOP research, reuse and license
Reference: https://github.com/DX23876/noop (NOOP Forge, upstream as inspected November 2026).
- Upstream license: **PolyForm Noncommercial 1.0.0** — https://github.com/DX23876/noop/blob/main/LICENSE. Personal/non-commercial forks are permitted within its terms; commercial use is not granted. Copyright 2026 NoopApp and applicable notices must be preserved when redistributing NOOP source/derivatives.
- NOOP is a native iOS/macOS app with WHOOP BLE reading, local calculation, Apple Health import, sleep and recovery analytics and an optional AI coach. Our website is JavaScript on GitHub Pages, so its native hardware drivers and HealthKit code cannot run in Safari.
- Relevant upstream reference files:
  - https://github.com/DX23876/noop/blob/main/Packages/NoopCoreJNI/Sources/NoopCore/Shared/AppleHealthImport.swift
  - https://github.com/DX23876/noop/blob/main/Packages/StrandAnalytics/Sources/StrandAnalytics/RecoveryScorer.swift
  - https://github.com/DX23876/noop/blob/main/Packages/StrandAnalytics/Sources/StrandAnalytics/SleepDebt.swift
  - https://github.com/DX23876/noop/blob/main/Packages/NoopCoreJNI/Sources/NoopCore/Shared/AICoach.swift
- No NOOP source code, bundled dependencies, logos or artwork have been copied into the current PROJECT 100M JavaScript application. We wrote original code using documented Apple Health categories and personal-baseline design principles as references. A future source-code fork would need its own license review and attribution.
- WHOOP hardware interoperability is an **optional separate native integration**, not required for Apple Watch and not implemented here. Read NOOP's own DISCLAIMER before experimenting with BLE on devices you own.

## Next: actual Apple Watch automatic integration
A website cannot directly access iPhone HealthKit through arbitrary Safari JavaScript. A native iOS app/extension or another authorized bridge is required. This is a separate development deliverable.

Proposed **PROJECT 100M iOS Companion**:
1. A small SwiftUI app built with Xcode on macOS, with HealthKit entitlement.
2. Ask user permission **per HealthKit type** (sleepAnalysis, restingHeartRate, heartRateVariabilitySDNN, workouts, heartRate where permitted). Do not request unnecessary sensitive data.
3. Use HKAnchoredObjectQuery (delta changes) with appropriate background delivery behavior where supported to fetch samples; track HKObject UUID, source and updates/deletions to avoid double counting. Handle limited authorization and missing samples gracefully.
4. Transform authorized samples into a documented, versioned JSON event format. Use local, encrypted storage while offline.
5. Send only selected metrics through a user-authenticated, RLS-protected backend endpoint. The endpoint must verify Supabase JWT identity, deduplicate by source+sample ID, validate timestamps/units, and store authorized data under the user's own user ID. Never ship service_role keys to the iPhone or web client.
6. Expose an iOS setting to disable sync, export/delete synced data, and revoke permissions. Show the last successful sync and sources in the web UI.

**No claim is made that this native component is compiled, installed, or running.** The user would need a Mac/Xcode or compatible build service and any required Apple signing.

## Next: true generative AI Coach
1. Add a *separate Supabase Edge Function* protected by the signed-in user's JWT.
2. On explicit question only, query that user's relevant training/recovery data server side, with a limited lookback and explainable data receipt.
3. Call an AI provider using a server-side secret; configure a suitable API key, per-user limits, budget/usage caps, and logging without sensitive raw payloads.
4. Show sources, confidence, unknowns and coach reasoning summaries. Keep AI advice read-only; changing the plan must require user confirmation.
5. Apply minimum-data and privacy-by-default rules. Do not silently send full Apple Health exports or cloud databases. Avoid medical diagnoses and disclose that coach output is not medical care.
6. Test wrong-user access, duplicate samples, prompt injection in workout notes and data leakage before launching.

**No AI API key or LLM service is configured or secretly called by the current web version.**

## Testing / safety requirements
- Live Workout must not mark Sprint + Strength as fully completed until their separate steps have been checked.
- Partial logs must leave the plan on the same Session; Completed advances.
- Apple Health sleep exports may contain overlapping sources and in-bed intervals; do not sum overlapping sleep stages into a fake extra night.
- Missing/low-quality sleep data is shown as unknown, not guessed.
- Personal baseline requires a meaningful sample count; don't treat one-night HRV variation as a diagnosis.
- Sleep-score percent of target is not WHOOP Charge/Rest or readiness.
- Always respect user account isolation and Supabase RLS.
