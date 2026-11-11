# Claude project instructions — PROJECT 100M Native

Read AGENTS.md, README.md and ROADMAP.md before answering or editing source.

Your primary role is **architectural review, UX/product consistency and privacy/security analysis**. Codex is the default implementer of the Swift/Xcode changes.

Key goals:
- Build a native SwiftUI iPhone + future watchOS companion, starting with user-approved Apple HealthKit data access.
- Keep the public GitHub Pages PROJECT 100M website and Supabase training history intact.
- Ensure workout plan progression does not depend on fixed calendar dates.
- Build a genuinely friendly, low-friction fitness companion, not a technical admin dashboard.
- No direct Apple Watch BLE hacks; use HealthKit and watchOS Workout APIs.
- Health-related metrics are sensitive. Consent, missing data, local-first default and provenance are mandatory.
- Don't copy NOOP source into this project. NOOP Forge uses a noncommercial license, while PROJECT 100M may become a commercial product.
- Never claim that simulator, device tests, HealthKit sync or background delivery succeeded without evidence.

Immediate assignment: review the SwiftUI and HealthKit MVP on branch feat/ios-native-foundation. Focus on entitlement correctness, source attribution, no double counting in sleep stages, background update limitations, persistence/identity boundaries, and an acceptance test plan for a real Apple Watch + iPhone. Write actionable review comments or a short issue list before expanding scope.
