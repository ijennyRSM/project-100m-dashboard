# PROJECT 100M design system v1

Direction: calm forward motion; forest actions, warm neutral surfaces, spacious rounded cards, native chrome, Thai copy without calendar guilt. Original implementation informed by existing web visual identity; no copied Strava/WHOOP artwork. External access limitations: PRODUCT_BLUEPRINT.

| Token | Use |
|---|---|
| accent | Adaptive deep forest in light, mint in dark; tint/actions and progress |
| canvas / surface | System grouped background / secondary grouped surface, automatic dark mode |
| primary / secondary | System text semantics, no low-contrast custom body labels |
| sleep / recovery / strain | Indigo / forest-mint / warm orange; always accompanied by names/states/values |
| spacing | 4, 8, 12, 16, 24, 32 pt; card padding 20, screen padding 16 |
| shape | Continuous 24 pt cards, circle avatar/ring; restrained hairline borders |
| type | System title/largeTitle/headline and body/subheadline/caption. Dynamic Type; never shrink body text to fit |

## Components and behavior

Reusable Screen container, Card, SectionHeading, StatusBanner, MetricTile, ActivityCard and HealthRing. NavigationLink rows provide native transitions/back behavior. Standard buttons minimum 44pt target; no inert action styled as working. Sample content has a visible Thai sample banner and individual post labels; no real route/person/photo fixture. No automatic animation; honor system reduced motion. Health rings are 88pt at standard size and scale up to 160pt, with a vertical arrangement from xxLarge text onward; pending score shows dash plus text, never zero. Ring opens a detail view with current evidence and missing-model explanation.

Five tabs in approved English order; screen content Thai first. Each tab owns independent path; selected tab restored locally. Today prioritizes next-session prescription and progress; M0 data clearly marked sample. Train contains five catalog previews with no enroll/log side effects. Feed sample cards only; unavailable social controls not presented as functional. Me profile preview and actual connection/privacy settings; health rings only in Health. Health renders existing on-device sample values separately from unimplemented scoring, with last read and source limitation notice.

## QA scenarios

M0 runtime review: 320/375/393pt widths, light/dark, default/AX5 type, VoiceOver order/labels, Health detail/back, tab-switch stack retention, relaunch selection, unavailable/no-sample/request-error/loading states. CI simulator screenshots are synthetic UI evidence only. No real HealthKit data screenshots committed. Full accessibility audit and transition refinement remain M6 tasks.
