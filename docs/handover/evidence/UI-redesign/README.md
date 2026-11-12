# Screenshot-led M0 redesign — runtime evidence

[Native PR run43141777432](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43141777432) completed **SUCCESS**. Each named simulator built the unsigned app and passed **all four UI methods, zero failures**. Xcode16.4 (16F6), iOS18.5. These are simulator/presentation checks, not signing or physical HealthKit acceptance.

| Device | Job | Artifact | UI suite |
|---|---|---|---|
| iPhone 16 | [job130930220281](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43141777432/job/130930220281) | 13909953454 |4/4 PASS, 368.545s |
| iPhone SE (3rd generation) | [job130930220564](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43141777432/job/130930220564) | 13910042452 |4/4 PASS, 402.776s |

Head `5ecb4f212932418d4257dd8c2b6cda390f196d9d`; tested merge `79c26b3b2401f20855fc7053d2183f116a9bf128`. Head/merge native tree `32941871117b0fd1a74c66db854780d08ad526ac` and .github tree `3a8c647eb5c6842617ea45141b175610840bde3f` match, independently checked with git after fetching the merge. A later handover-only commit reuses this evidence only if both trees remain equal.

`provenance.json` maps all **52 unmodified selected PNGs** to original attachment names/files/timestamps and SHA256. Both full artifact ZIP digests were independently verified after download. Each device directory includes original provenance, complete attachment manifest and exact test-log excerpt. Full logs/builds/xcresult bundles remain in CI artifacts (14-day retention); selected images survive in git. Original personal reference images remain local/ignored; no copied photographs, vendor artwork, real coordinates or health records appear in these synthetic fixtures.

## Main screens

| Screen |16 light |16 dark |SE3 light |SE3 dark |
|---|---|---|---|---|
| Feed | [light](iphone16/UI-Feed-light.png) | [dark](iphone16/UI-Feed-dark.png) | [light](se3/UI-Feed-light.png) | [dark](se3/UI-Feed-dark.png) |
| Today | [light](iphone16/UI-Today-light.png) | [dark](iphone16/UI-Today-dark.png) | [light](se3/UI-Today-light.png) | [dark](se3/UI-Today-dark.png) |
| Train | [light](iphone16/UI-Train-light.png) | [dark](iphone16/UI-Train-dark.png) | [light](se3/UI-Train-light.png) | [dark](se3/UI-Train-dark.png) |
| Health | [light](iphone16/UI-Health-light.png) | [dark](iphone16/UI-Health-dark.png) | [light](se3/UI-Health-light.png) | [dark](se3/UI-Health-dark.png) |
| Me | [light](iphone16/UI-Me-light.png) | [dark](iphone16/UI-Me-dark.png) | [light](se3/UI-Me-light.png) | [dark](se3/UI-Me-dark.png) |
| Maps | [light](iphone16/UI-Maps-light.png) | [dark](iphone16/UI-Maps-dark.png) | [light](se3/UI-Maps-light.png) | [dark](se3/UI-Maps-dark.png) |
| Workout | [light](iphone16/UI-Workout-light.png) | [dark](iphone16/UI-Workout-dark.png) | [light](se3/UI-Workout-light.png) | [dark](se3/UI-Workout-dark.png) |
| Groups-Events | [light](iphone16/UI-Groups-Events-light.png) | [dark](iphone16/UI-Groups-Events-dark.png) | [light](se3/UI-Groups-Events-light.png) | [dark](se3/UI-Groups-Events-dark.png) |

## Accessibility and profile sections

| View |16 |SE3 |
|---|---|---|
| AX5 Feed heading | [view](iphone16/UI-Feed-header-dark-AX5.png) | [view](se3/UI-Feed-header-dark-AX5.png) |
| AX5 Feed action | [view](iphone16/UI-Feed-dark-AX5.png) | [view](se3/UI-Feed-dark-AX5.png) |
| AX5 Today | [view](iphone16/UI-Today-dark-AX5.png) | [view](se3/UI-Today-dark-AX5.png) |
| AX5 Train | [view](iphone16/UI-Train-dark-AX5.png) | [view](se3/UI-Train-dark-AX5.png) |
| AX5 Me | [view](iphone16/UI-Me-dark-AX5.png) | [view](se3/UI-Me-dark-AX5.png) |
| Activities sample | [view](iphone16/UI-Profile-Activities-dark.png) | [view](se3/UI-Profile-Activities-dark.png) |
| Gallery illustration | [view](iphone16/UI-Profile-Gallery-dark.png) | [view](se3/UI-Profile-Gallery-dark.png) |
| More settings | [view](iphone16/UI-Profile-More-dark.png) | [view](se3/UI-Profile-More-dark.png) |
| Hosted320/xLarge dated metrics | [view](iphone16/M0-Health-hosted-320-xLarge-rhr.png) | [view](se3/M0-Health-hosted-320-xLarge-rhr.png) |

Tests assert capsule count/order/selection, ≥44pt targets and bounds, no duplicate stock bar, five roots, no Me rings, local filters/sections, Maps sample selection, details/back, independent stacks/restored selection, actual light/dark/type probes and Health ring/metric bounds/stale dates/connection states. AX5 Feed explicitly stacks Groups below its complete heading and bounds the action height. Hosted320 is a content container, not Display Zoom. At AX5, vertical content can exceed a viewport and must scroll; no claim that whole cards fit one frame.

Captures use a preflight frame plus0.6s compositor settling for UI-prefixed screenshots, in the separate test process; no image editing or app-thread delay. Automated PASS is not final visual acceptance. Codex inspects representative frames and records limits in CURRENT; Claude still reviews the complete gallery/reference alignment and acceptance. System VoiceOver/Reduce Transparency/enlarged-content-viewer interaction, iOS17 runtime and real Display Zoom remain manual/M6 items. No SDK26 native glassEffect or signed iPhone/Watch/GPS/background proof is implied.

## Preserved iteration history

-30bebd2 / run43129292963: both app builds PASS, UI0/4 on each; parent navigation identifier overwrote all five child IDs. Runtime excerpt/provenance retained.
-6158ec9 / run43130713599: both build/UI4/4 PASS; manual inspection found AX5 Feed squeeze. Before image/visual-finding JSON retained; corrected by f379701 with stronger assertions.
-f379701 / run43133236478: SE3 all4 PASS;16 layout case PASS then15min step deadline during case2 after nearly9min preparation. Overall FAILURE; timeout log/provenance retained.370adde raised UI-step25min/job40min, leaving420s test bounds unchanged.
-370adde / run43138252275: both builds/UI4/4 PASS; adjacent partial captures/default stat clipping prompted intrinsic-height and capture-settling refinement. Before image/finding JSON retained; not used as current visual proof.
-5ecb4f2 is the current implementation/evidence above. Parent M0 remains CHANGES_REQUESTED; no self-verification, M1 work, production changes or merge.
