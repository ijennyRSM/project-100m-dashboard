# PROJECT 100M — iPhone Native MVP

This is the **new SwiftUI iPhone app** started alongside the existing PROJECT 100M GitHub Pages website. The web app and its Supabase data are unchanged.

**Status:** M0 five-tab design foundation; see [current handover](../docs/handover/CURRENT.md) for exact commit/build evidence. Not signed or installed on a physical iPhone. Feed/training/profile content is explicitly labeled fictional preview data; accounts, social interactions, native workout logging and scores are not implemented.

## M0 — Foundation and design

The approved [Product Blueprint](../docs/product/PRODUCT_BLUEPRINT.md) and [requirements](../docs/product/FEATURE_REQUIREMENTS.md) supersede the old milestone numbering. M7 separately tracks physical-device acceptance.

- Exactly Feed / Today / Train / Health / Me using native TabView, independent stacks and restored selected tab. The M0 redesign presents a custom floating Material capsule over the hidden stock bar, with selected accessibility traits and ≥44pt targets; iOS17 minimum retained.
- Adaptive shared design tokens/cards/banners/activity previews; Thai-first copy and Dynamic Type. Health begins with interactive Sleep/Recovery/Strain rings showing no invented scores; Me has none.
- User explicitly taps **อนุญาตการอ่านข้อมูล** to request read-only HealthKit access.
- Read the last 21 days of permitted resting heart rate, HRV (SDNN), sleep stages and workouts from Apple Health, including samples already synced from the paired Apple Watch.
- Refresh when the app comes to the foreground, and use HealthKit change observers while the app is alive.
- Missing or denied data is shown as "no data", not fabricated. A successful permission request does NOT prove every read type was granted.
- Avoid double-counting sleep by selecting one source per night and merging overlapping time intervals from that source.
- No sign-in, cloud health upload, AI provider, or public social sharing enabled in this milestone.
- The existing 100M training plan remains available by linking to the current website; native migration follows.

## Building

The screenshot-led redesign is a visual foundation: Feed filters, Groups sections, Maps sample selection and Me sections switch local fictional content. It does not add social mutations, enrollment, workout recording, GPS, photo upload or account editing. Raw owner reference images stay local/ignored. `DESIGN_ALIGNMENT.md` documents why Maps is under Train, Groups under Feed and Health remains dedicated. Light/dark use shared semantic tokens; the capsule uses iOS17 Material, not a verified SDK26 Liquid Glass API.

Requirements:
1. A Mac with Xcode or a supported hosted macOS build runner. **Xcode cannot build or sign an iOS/watchOS app natively on Windows**.
2. XcodeGen from https://github.com/yonaskolb/XcodeGen (on macOS: brew install xcodegen).
3. A real iPhone to test HealthKit; a paired Apple Watch with recent readings is strongly recommended.
4. An Apple signing team/provisioning profile with the HealthKit capability.

Commands on macOS:

    cd native-ios
    xcodegen generate
    open PROJECT100M.xcodeproj

In Xcode choose the PROJECT100M target, select Signing & Capabilities, set a unique Bundle Identifier and Development Team, verify HealthKit capability, choose the physical iPhone, then Build and Run.

The default bundle identifier com.project100m.ios is a placeholder; change it to a value supported by your signing team.

**Do not test background delivery solely in Simulator.** Apple Watch/HealthKit authorization and background updates must be checked on physical hardware. This initial implementation includes foreground and in-process observer refresh only; it does NOT guarantee unattended sync.

## Source tree

- project.yml — XcodeGen project definition, iOS 17+
- App/PROJECT100MApp.swift — SwiftUI app lifecycle
- Health/HealthModels.swift — read-only native display data
- Health/HealthKitService.swift — HealthKit authorization and queries
- Features/ — five-tab shell and feature-specific views, explicitly labeled fixtures
- DesignSystem/ — adaptive tokens, shared components and ring presentation states
- UITests/ — simulator navigation, privacy placement, fixture labeling and screenshot checks
- AGENTS.md — Codex + Claude guardrails
- ROADMAP.md — phases and acceptance checks

CI builds an unsigned simulator app and runs four UI tests on pinned iPhone 16 and iPhone SE (3rd generation), iOS 18.5. Light/dark/default/xLarge/AX5 captures assert actual presentation, ring/tile bounds and hittability; a 320pt hosted container covers narrow content without claiming Display Zoom. Provenance includes head/tested SHA, native/.github trees, device/runtime and run/event IDs. Push/PR concurrency groups are separate and running evidence is never auto-cancelled by later commits.

DEBUG-only `--ui-testing` uses a Health stub that never constructs HealthKit. `--ui-health-state=notRequested|unavailable|failed|missing|loading|stale`, `--ui-theme=light|dark`, `--ui-text-size=large|xLarge|AX5` and optional `--ui-content-width=320` support deterministic checks. `--ui-reset` removes only saved tab selection; tests remove it for restoration relaunch. These overrides are inactive in Release builds. Fixtures are labeled and never uploaded/persisted. Production still reads only authorized HealthKit types, with sample measurement dates separate from query time and explicit connection states. UI tests prove no real HealthKit permissions/device behavior. See CURRENT for actual observed test results, not just test definitions.

## Apple Watch without ZIP exports

Apple Watch synchronizes samples to Apple Health on the paired iPhone. Our native iPhone app requests permission to read those samples, so users do not have to export an archive. The MVP reads a bounded window on open; future work will use persisted HealthKit anchors, observer/background-delivery, deletions and sample IDs to avoid duplicate import. iOS decides background delivery timing: never promise real-time updates.

For recording workouts while the phone is pocketed, add a separate watchOS target using HKWorkoutSession / HKLiveWorkoutBuilder, plus WatchConnectivity. That is a separate milestone.

## Existing backend

The current website uses Supabase Auth and RLS-protected training_states JSON by user. Native login should reuse this identity and preserve plan progression. Later add dedicated tables for workouts, metric summaries and social features. **No secret keys or personal health exports may be committed to this public GitHub repo.**

## NOOP reference

NOOP Forge is a useful reference for the architectural separation of Apple Health, watchOS and local analytics, but its original source uses the PolyForm Noncommercial 1.0.0 license. This scaffold is original code; no NOOP source files have been copied. The root repository has NOOP_INTEGRATION_ROADMAP.md explaining licensing and future integrations.

## Immediate acceptance checkpoint

Compile on a Mac; install on a real iPhone; confirm HealthKit permission sheet and permitted Apple Watch metrics; verify no upload; test the app with Health access refused; record build errors for Codex. Do not claim the Native app is complete until those tests succeed.
