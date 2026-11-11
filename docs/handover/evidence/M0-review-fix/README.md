# M0 review-fix runtime evidence

[PR run 43107213059](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43107213059) completed **SUCCESS**. On each named simulator, the unsigned app build and all **four UI test methods passed, zero failures**. Xcode16.4 (16F6), iOS18.5. No signing or physical-device acceptance is implied.

| Device | Content width | Job | Artifact | Four-method runtime |
|---|---|---|---|---|
| iPhone16 | 393pt | [130813544329](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43107213059/job/130813544329) | 13894209678 | 288.828s |
| iPhone SE3 | 375pt | [130813543828](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43107213059/job/130813543828) | 13894484095 | 331.438s |

Head `713ead4126850b6a488943cfe5c511ee3983b3fa`; tested PR merge `e6b0b764e2967118c6622800ec2b0c67e4ed846d`. Both have native tree `54462fa2bbd9b1a56ae46b02b8acd836f8f62ea3` and .github tree `65567a9f07fe2630b099ed4c7e16443188510e95`. The merge was fetched and both trees independently matched with git. Later handover-only commits can reuse this evidence only while these trees remain equal.

`provenance.json` records both artifact ZIP digests (verified after download), original attachment mapping/timestamp and SHA256 for each of the **38 unmodified selected PNGs**. Each device directory retains original workflow provenance, full attachment manifest and an exact test-log excerpt. Complete build logs, test logs and xcresult bundles remain in the linked CI artifacts (14-day retention); selected screenshots survive in git. All Health values are explicitly labeled DEBUG synthetic fixtures. No HealthKit store is constructed in this test path.

## Review gallery

| Scenario | SE3 | iPhone16 |
|---|---|---|
| Light/default | [Rings](se3/M0-Health-se3-light-large-sleep.png) | [Rings](iphone16/M0-Health-iphone16-light-large-sleep.png) |
| Light/xLarge | [Width adaptation](se3/M0-Health-se3-light-xLarge-sleep.png) | [Width adaptation](iphone16/M0-Health-iphone16-light-xLarge-sleep.png) |
| Dark/default | [Rings](se3/M0-Health-se3-dark-large-sleep.png) | [Rings](iphone16/M0-Health-iphone16-dark-large-sleep.png) |
| Dark/AX5 | [Sleep](se3/M0-Health-se3-dark-AX5-sleep.png), [Recovery](se3/M0-Health-se3-dark-AX5-recovery.png), [Strain](se3/M0-Health-se3-dark-AX5-strain.png) | [Sleep](iphone16/M0-Health-iphone16-dark-AX5-sleep.png), [Recovery](iphone16/M0-Health-iphone16-dark-AX5-recovery.png), [Strain](iphone16/M0-Health-iphone16-dark-AX5-strain.png) |
| Dark/AX5 metrics | [RHR](se3/M0-Health-se3-dark-AX5-rhr.png), [HRV](se3/M0-Health-se3-dark-AX5-hrv.png) | [RHR](iphone16/M0-Health-iphone16-dark-AX5-rhr.png), [HRV](iphone16/M0-Health-iphone16-dark-AX5-hrv.png) |
| Hosted320/xLarge | [Rings](se3/M0-Health-hosted-320-xLarge-sleep.png), [dated metrics](se3/M0-Health-hosted-320-xLarge-rhr.png) | [Rings](iphone16/M0-Health-hosted-320-xLarge-sleep.png), [dated metrics](iphone16/M0-Health-hosted-320-xLarge-rhr.png) |
| Not requested | [CTA](se3/M0-Health-state-notRequested.png) | [CTA](iphone16/M0-Health-state-notRequested.png) |
| Unavailable | [No retry](se3/M0-Health-state-unavailable.png) | [No retry](iphone16/M0-Health-state-unavailable.png) |
| Failed | [Failure](se3/M0-Health-state-failed.png) | [Failure](iphone16/M0-Health-state-failed.png) |
| Requested/empty | [Missing](se3/M0-Health-state-missing.png) | [Missing](iphone16/M0-Health-state-missing.png) |
| Loading | [Loading](se3/M0-Health-state-loading.png) | [Loading](iphone16/M0-Health-state-loading.png) |
| Me / detail | [No rings](se3/M0-Me-light.png), [Sleep detail](se3/M0-Sleep-detail-missing.png) | [No rings](iphone16/M0-Me-light.png), [Sleep detail](iphone16/M0-Sleep-detail-missing.png) |

Tests assert the actual SwiftUI color scheme/type environment, named device width, horizontal ring/tile bounds and hittability after scrolling, stale-date copy, all five tabs, state banners, ring detail navigation, independent stacks and persisted selection after removing reset. At AX5 a card may exceed viewport height and remains vertically scrollable; the bounds test is horizontal, not an assertion that the whole card fits one screenshot. Hosted320 is a real 320pt Health content container on these simulators, not Display Zoom or a separate320pt hardware claim.

Codex visually inspected representative current SE3 xLarge/AX5 light/dark rings and metric captures, iPhone16 dark/AX5 HRV, hosted320 and unavailable state. Claude still needs to review the full gallery, source and acceptance. Full VoiceOver, real Display Zoom and iOS17 runtime remain M6 risks; real HealthKit permissions/Watch/GPS/background remain M7.

## Prior failures and infrastructure

- Historical run43075144693/job130712960837/artifact13883405985: app BUILD SUCCEEDED, boot timed out after5min before UI tests. Exact head/merge tree proof and original excerpt are preserved here. No UI PASS claimed.
- Run43105037599 at3e86451: iPhone16 4/4 PASS; SE3 exceeded four-minute layout-method limit (273s), other3 PASS; overall FAILURE. Commit713ead4 gives only the expanded seven-launch layout method six minutes, maximum seven, retaining all assertions. Current completed result supersedes it; application source unchanged by that correction.
- GitHub Actions incident dvy0t3mvh1lg was later resolved. `github-incident.json` and `ci-infrastructure.json` record public status plus sanitized permissions/account checks. This does not establish account billing quotas; current successful jobs establish resumed runner execution. No empty trigger commits or settings changes.
