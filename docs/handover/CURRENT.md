# Current handover — device build, native auth and offline training

2026-11-12 (Asia/Bangkok). **Owner reassigned Claude as the active implementation engineer** (Codex near its usage limit). The handover is a continuity mechanism; owner tests UI/functionality personally and does not require a Claude/Codex review cycle per milestone. Branch `codex/m0-foundation-handover`, [draft PR#1](https://github.com/ijennyRSM/project-100m-dashboard/pull/1) (base `feat/ios-native-foundation`). No merge to main, no production database operation, no self-acceptance.

Previous Codex handover (UI-001 redesign, M0 review packet, SEC-001 preparation) is preserved at commit `ff8f01f` and in `docs/handover/REVIEW.md` / `evidence/`. Its statuses are unchanged.

## What is new (Claude)

| Task | Status | Summary |
|---|---|---|
| P100-DEV-001 | READY_FOR_REVIEW | Unsigned arm64 iPhoneOS IPA workflow + verifier + Windows/Sideloadly guide. Build evidence only; awaiting owner install. |
| P100-AUTH-001 | READY_FOR_REVIEW | Native passwordless sign-in to the existing Supabase accounts, Keychain session restore, sign-out, per-account local partitions. Not yet exercised against the live auth service. |
| P100-TRAIN-001 | READY_FOR_REVIEW | Offline-first training engine (web rules), Live Workout, history, per-account JSON persistence, Today/Train/Me on real state. |

### Device build (P0)

- Workflow `.github/workflows/ios-device-ipa.yml` (**iPhone Device Build (Unsigned IPA)**): macOS 15, Xcode 16.4, XcodeGen, `xcodebuild -sdk iphoneos -destination generic/platform=iOS -configuration Release ARCHS=arm64 CODE_SIGNING_ALLOWED=NO`, packages `Payload/PROJECT100M.app` → `PROJECT100M-unsigned.ipa`. An ad-hoc (identity `-`) pseudo-signature embeds the declared `com.apple.developer.healthkit` entitlement so re-signing tools see it; no certificate/profile/Apple ID in GitHub.
- Verification: `native-ios/scripts/verify_ipa.py` (stdlib; ZIP/Payload layout, Info.plist keys, bundle `com.project100m.ios`, MinimumOSVersion 17.0, `iPhoneOS`/`iphoneos` platform, arm64 Mach-O with LC_BUILD_VERSION platform iOS (not simulator), not encrypted, no Apple certificate signature, entitlement present) + `lipo`/`vtool`/`codesign` cross-checks; unit tests `scripts/tests/test_verify_ipa.py`.
- Artifact **`PROJECT100M-iPhone-Unsigned`** (IPA, SHA256SUMS, provenance.json, verification.json/.txt, declared-entitlements.plist; 30-day retention).
- Guide: [docs/IOS_INSTALLATION_WINDOWS.md](../IOS_INSTALLATION_WINDOWS.md) (download/extract, Sideloadly, Trust, Developer Mode, error collection, 7-day re-sign, HealthKit limits, sign-in).
- **HealthKit finding:** free personal-team provisioning of HealthKit is not guaranteed (developer reports of "doesn't support the HealthKit capability"; no Apple guarantee). The main app keeps HealthKit; if the entitlement is not provisioned the Health tab shows the HealthKit error and the rest of the app works. Full HealthKit testing route: paid Apple Developer Program signing (Xcode/TestFlight/paid account in Sideloadly). No separate UI-only build published.

### Native authentication (P1)

- `Core/Auth/SupabaseAuth.swift`: minimal GoTrue REST client against the existing project (`rbryddekjwytcoqqgcgu`, publishable key already public in `cloud-config.js`; no secret keys). `/otp` with `create_user:false` (existing accounts only), `/verify` by 6–8 digit code or pasted email link (`token_hash`), fragment-token callback via `project100m://auth-callback`, `/token?grant_type=refresh_token`, `/logout?scope=local` (website session untouched).
- `AuthSessionController`: restore without network if unexpired; refresh when near expiry; keep signed in offline on network failure; discard on rejected refresh; sign-out always clears local session.
- `Services/AuthPlatform.swift`: Keychain (`AfterFirstUnlockThisDeviceOnly`), cleared on first launch after reinstall; ephemeral URLSession. UI testing uses an in-memory store and an offline transport (never contacts Supabase).
- UI: `Features/Me/SignInScreen.swift`; Me shows real account state, sign-out confirmation with optional local data removal, explicit Guest→account copy.
- Owner options (dashboard config, not DB): add `{{ .Token }}` to the Magic Link template; allow-list `project100m://auth-callback`.
- **No `training_states` read/write** (SEC-001 open, no reviewed sync design).

### Offline-first training (P1)

- `Core/Training`: catalog ported exactly from `v2-data.js` (100M 60 sessions, 5K 24, Strength 24, Wellness 18; 10K listed but unavailable — no reviewed prescription). Models: PlanTemplate, TrainingSession, SessionComponents, TrainingPlan, SessionAttempt (workout log), ComponentProgress, PlanOverview (progress), HistoryEntry, LiveWorkoutDraft.
- Rules: Completed advances; Partial keeps the session and its components (restored next Live Workout); Skipped requires an explicit confirmation timestamp; latest record wins (web semantics); dates never progress.
- Live Workout: warm-up checklist (items only from session text), sprint reps, strength sets, rest timer (150/240/90 s like web), wall-clock elapsed timer, pause/resume, RPE, notes, Completed/Partial finish, cancel, draft survives termination.
- `Core/Persistence/TrainingRepository.swift`: `Application Support/PROJECT100M/accounts/{guest|user-<uuid>}/training.json`, atomic writes + complete-until-first-auth protection, corrupt/newer-schema files quarantined (never overwritten), migration hook.
- UI: Today (greeting, real next session, resume draft, progress, latest history), Train (active plan, all sessions, history, library with start/switch), Program, Session detail (Live/quick log/confirmed skip), Live Workout, History. Feed/Groups/Maps/Me-Gallery remain labeled samples; Health unchanged.

## Verification (see ledger for exact SHAs/runs)

Implementation commit **`ef09ba0342b22c42ba7df141def13e7c1ddcd688`** (native tree `138872f694e9b1866740d28ecec210a9e72fdcf4`, .github tree `4e79dfe6bef0e26520d22ed33234fe0554f4daa7`). All runs on GitHub Actions, macOS 15 / Xcode 16.4 unless noted.

| Evidence | Result |
|---|---|
| [iPhone device build 43152462029](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43152462029) | PASS. Release arm64 iphoneos 18.5 SDK; verifier 16/16 checks + lipo/vtool/codesign; artifact `PROJECT100M-iPhone-Unsigned`; IPA SHA256 `5510dfc393deed90265938d51f3e6757def2b834b5a3c97c2ef8db15057c07f3` |
| [Simulator build + UI 43152462066](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43152462066) | PASS. Both unsigned simulator builds; UI tests 5/5 zero failures on iPhone 16 and on iPhone SE (3rd gen), iOS 18.5 (incl. new `testTrainingFlowPersistsDraftAndPartial`: enrol, Live Workout, terminate, draft restored, Partial, same session still next) |
| [Core unit tests 43152467633](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43152467633) | PASS on Linux (swift:6.0) and macOS: 19 XCTest cases (catalog parity, progression, skip confirmation, live timers, Partial restore, repository isolation/quarantine, auth link parsing, OTP/verify/refresh/offline/sign-out) |
| Handover validation (Windows/Linux) + PG16/17 security tests | PASS (runs 43152462075 / 43152467662) |
| Local Windows | `python -m unittest discover -s scripts/tests` 20 tests PASS; handover validate PASS |
| First IPA (workflow only) | [43146948447](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43146948447) at `cf47dc6`, SHA256 `5ff33217...b257`, independently re-verified locally after download |
| Earlier failure (kept) | [43149842661](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43149842661) at `5831376`: new flow test failed at its final assertion (container identifier masked `next-session-title`); fixed in `ef09ba0`. SE also showed one transient "Failed to terminate" that passed on retry. |

**Not run / not evidence:** physical iPhone install or launch, Sideloadly signing, HealthKit on device, sign-in against the live Supabase auth service (UI tests run offline by design), iOS 17 runtime, VoiceOver.

## Owner device feedback and visual pass (P100-UI-002)

- Owner installed an IPA on their iPhone with Sideloadly (Apple-side anisette error -80046 first; owner resolved it on their side). Owner reported install success; launch/function results not yet reported.
- Owner asked for a closer reference-app look with the same green tone. Commit `61da35470465fd64efb97f11ec64931a00ae16e6`: flat full-width Feed posts with real weekly summary, Train start card + program carousel, Me profile header with underline icon tabs, real 12-week chart and streak, Groups/Maps restyle (see DESIGN_SYSTEM v2.1).
- Evidence: [simulator UI 43165820018](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43165820018) 5/5 on iPhone 16 and SE; [core 43165820031](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43165820031) PASS; [device IPA 43165820141](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43165820141) PASS, SHA256 `5e337fe73f602049b4e2b5d473012af2cb8e5d1cbe6b6d87d62ec7d9979ac563` (install this one for the new look).
- Mobbin connector was connected by the owner but returned "requires a paid plan"; no Mobbin references were used.

## Real map basemap (ADR-018)

- Owner asked for a real map like Google Maps. Commit `c05ea20ed8c964b23f3bee68a0489b20a3314365` uses Apple MapKit (no API key, no location permission): full-bleed maps in Feed run/walk sample posts; full-screen interactive Maps with route chips, route card, recenter and visible Apple legal label. Routes are labeled fictional samples around Lumphini Park.
- Evidence: [simulator UI 43253641663](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43253641663) 5/5 on iPhone 16 and SE; [device IPA 43253631746](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43253631746) PASS, SHA256 `702ada0794125da5609b4f409e44660b139743c00a7b324260601a601bc28d6b` (latest installable build).
- Visual review caught overlays under the floating tab bar twice; the non-scrolling Maps layout does not receive the capsule inset, so it pads explicitly. Local preview gallery: `.local-evidence/preview-c05ea20.html` (ignored, not committed).
- CI infrastructure: one macOS job was never acquired (capacity) and re-ran green; security pgTAP jobs currently fail while installing packages from apt.postgresql.org. No database files changed; re-run later.

## App icon

- Owner-supplied "100M" logo is the app icon (commit `c29c6253bc47ee5e8a88e1971caeb6090ff9b7bd`): `native-ios/App/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`, 1024px opaque, corners filled black (iOS applies its own mask). Latest installable IPA: [run 43259974147](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43259974147), SHA256 `dd130811bbfbaf4431034d8083251ad8fc11484502044e317829ce1281645fbd`; simulator UI [43259982703](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43259982703) PASS on both devices.

## Security gate

**P100-SEC-001 unchanged and unresolved in production** (authenticated TRUNCATE etc. on `public.training_states`). Migration A/proposal B remain READY_FOR_REVIEW; requires owner approval, backup confirmation and disposable/staging proof before any production SQL. Native code does not touch that table.

## Known issues / limits

- No physical-device evidence yet (install, launch, Keychain, HealthKit, sign-in against live service).
- Sign-in by code requires the email template to include `{{ .Token }}`; otherwise use pasted link (link is single-use; tapping it first consumes it on the website).
- Offline-restored session is not re-refreshed when connectivity returns until next launch (no API calls depend on it yet).
- Native training is device-local; no cloud sync/import of web history yet (needs SEC-001 + reviewed adapter).
- Build number = workflow run number of `ios-device-ipa.yml`.

## Exact next tasks

1. Owner: install the IPA via the guide; report launch/UI, sign-in, Live Workout relaunch and Health results separately (M7 evidence).
3. Read-only, explicit "import my web plan" adapter (training_states SELECT under RLS, owner-approved) mapping v2 profiles/plans/records into a local copy — only after SEC-001 decision.
4. Retry refresh on foreground when restored offline; expose session state in Me.
5. Owner decision on SEC-001 production remediation (separate approval).

## Copy-ready takeover summary (for Codex or a new Claude session)

> Continue PROJECT 100M on `codex/m0-foundation-handover` (draft PR#1) from `ef09ba0342b22c42ba7df141def13e7c1ddcd688` plus the handover commit after it. Read AGENTS.md, native-ios/AGENTS.md, this CURRENT.md, tasks.json (P100-DEV-001, P100-AUTH-001, P100-TRAIN-001) and ADR-014..017. Core logic lives in `native-ios/Core` (Foundation-only, `swift test` in `native-ios`); app services in `native-ios/Services`; screens in `native-ios/Features`. CI: `ios-device-ipa.yml` (unsigned IPA artifact `PROJECT100M-iPhone-Unsigned`), `ios-native-compile.yml` (simulator build + 5 UI tests on iPhone 16/SE), `native-core-tests.yml` (Linux/macOS unit tests). Do not touch production Supabase or `training_states` (SEC-001 open). Next: owner device results, app icon, foreground refresh after offline restore, then an owner-approved read-only web-plan import. Never claim device/HealthKit success without the owner's evidence.
