# PROJECT 100M design system v2

Direction: screenshot-led social fitness structure; compact headers, flat activity sections, bold numbers, large original route illustrations, pill actions and a floating translucent navigation capsule. Forest/mint identity, near-white/near-black themes and Thai-first copy remain original. User iPhone images override older web references; see DESIGN_ALIGNMENT for observations and mapping. WHOOP influence is limited to Health/Insights. Light/dark support is mandatory.

| Token | Use |
|---|---|
| accent | Adaptive deep forest in light, mint in dark; tint/actions and progress |
| canvas / surface | System background (white/black) / adaptive quiet warm-white or near-black green surface; both themes required |
| primary / secondary | System text semantics, no low-contrast custom body labels |
| sleep / recovery / strain | Indigo / forest-mint / warm orange; always accompanied by names/states/values |
| spacing | 4, 8, 12, 16, 24, 32 pt; card padding 20, screen padding 16 |
| shape | Continuous 20 pt cards, capsule actions/chips/nav, circle avatar/icon controls; flat feed sections with hairline dividers |
| type | System title/largeTitle/headline and body/subheadline/caption. Dynamic Type; never shrink body text to fit |

## Components and behavior

Reusable Screen, Card, Heading, Banner, MetricTile, ActivityCard, HealthRing plus Typography/Space tokens, ProfileAvatar, StatStrip, ChipPicker, IconLink, PrimaryAction and MaterialCapsuleBar. Feed uses flat activity sections with large media; grouped cards are reserved for training, profile summaries and health. Shared material is for navigation/controls, not every surface. NavigationLink rows provide native transitions/back behavior. Standard buttons minimum 44pt target; no inert action styled as working. Sample content has a visible Thai sample banner and individual post labels; no real route/person/photo fixture. No automatic animation; honor system reduced motion. Health rings are 88pt at standard size and scale up to 160pt. Width-driven ViewThatFits uses a horizontal row only when all scaled columns fit; otherwise it stacks vertically. Metric tiles use the same width-driven fallback. Pending score shows dash plus text, never zero. Ring opens a detail view with current evidence and missing-model explanation.

Five tabs in approved English order; screen content Thai first. Each tab owns independent path; selected tab restored locally. Today prioritizes next-session prescription and progress; M0 data clearly marked sample. Train contains five catalog previews with no enroll/log side effects. Feed sample cards only; unavailable social controls not presented as functional. Me profile preview and actual connection/privacy settings; health rings only in Health. Health renders existing on-device sample values separately from unimplemented scoring, with last read and source limitation notice.

## QA scenarios

M0 tests pin iPhone SE (3rd generation), 375pt, and iPhone 16, 393pt, on iOS 18.5. Each checks light/dark at default/xLarge/AX5: actual SwiftUI theme/type probe, ring/tile horizontal bounds and hittability, dates, detail/back, stack retention and relaunch selection. A 320pt hosted Health container at xLarge exercises the narrow layout; this is not a Display Zoom/device claim. DEBUG-only Health fixtures cover notRequested/unavailable/failed/missing/loading and old dated samples without constructing HealthKit. Selection resets only under --ui-reset; restoration relaunch removes that argument. Runtime PASS requires completed CI evidence in CURRENT; test source alone is not proof. Full VoiceOver audit, real Display Zoom, iOS 17 runtime and transition refinement remain M6 risks requiring Claude disposition.

UI-prefixed captures flush a preflight frame and allow0.6s compositor settling in the separate test process after observed partial transition frames; images are never edited. StatStrip preserves full intrinsic vertical height to avoid cutting large values. Cold preparation receives a25min workflow step budget (40min job), while individual tests retain a420s maximum. Native simulator acceptance still requires all four methods on each device and review of current-source images, not a timeout retry alone.

## Floating navigation and reference-led screens

Feed's introduction and Groups action use a width-driven horizontal/vertical fallback; title/body text keeps its full vertical extent. AX5 tests assert Groups sits below the complete heading and remains a bounded, hittable action. This was added after visual review caught squeezing despite a passing capsule/Health test matrix; automated PASS is not visual acceptance.

Exactly five labels/order retained. Maps is reachable from Train, Groups from Feed. Compact navigation headers use circular material controls linking to real local preview/settings destinations; no inert fake backend buttons. Capsule uses ultraThinMaterial, hairline highlight, shadow and a strong selected pill, plus opaque Reduce Transparency fallback. At accessibility text sizes icon-only tab items retain complete spoken labels/selected traits and large-content viewers; ordinary labels scale with Dynamic Type. Header icon links also expose enlarged-content labels. Bottom safeAreaInset reserves the full capsule/spacing so scroll content remains reachable; independent native stacks remain. This is iOS17 Material styling, not verified SDK26 glassEffect. OS-level large-content-viewer interaction and Reduce Transparency still need explicit manual acceptance; app-level Dynamic Type fixtures alone do not prove system settings.

Profile uses avatar/name/bio, synthetic stat strip and functioning sample section picker (Progress/Activities/Gallery/More). Groups has local Events/Clubs/Challenges sections. Workout previews expose prescribed sessions, not fake recording. Maps uses independently drawn abstract geometry without coordinates or location access. Light mode adapts the eight dark reference compositions with semantic foreground/surface tokens. No vendor artwork/photos or private reference data enter app fixtures.

## v2.1 activity-app pass (Claude, 2026-11-12)

Owner feedback after the first device install: keep the green palette, move closer to the reference screenshots' structure. Added `DesignSystem/ActivityStyle.swift`: `SectionBand` (8pt surface band between flat sections), `ActivityHeader`/`ActivityPost` (48pt avatar, name, meta, context line; title2 bold title; bold stat columns; optional full-bleed media), `UnderlineTabs` (text or icon-over-text, 3pt accent underline, equal widths with horizontal-scroll fallback at large text; no container identifier), `SessionStartCard` (icon + title2 title + chevron row, full-width Start capsule), `ProgramTile` (220pt carousel tile, original gradient + SF Symbol art), `ListRowLabel` (icon, title, value, chevron), `OutlineAction` (outlined capsule, neutral or accent). `P100Screen` gains `horizontalPadding`/`spacing` for full-bleed layouts; stat values are bold.

Screens: Feed = real weekly summary card + flat sample posts with edge-to-edge route art and circular Groups/Privacy header controls. Train = next-session start card, outlined plan action, program carousel, flat history. Me = profile header, outlined capsule actions, icon underline tabs, real weekly stats with a 12-week Swift Charts line/area chart, week streak (display only; never progression), list-style More. Groups = underlined Challenges/Clubs/Events + large event card with date chip. Maps = full-bleed art with overlaid pill, chips and route summary. Health and Today unchanged. Mobbin has an MCP connector in the registry but it is not connected; owner screenshots remain the primary reference.
