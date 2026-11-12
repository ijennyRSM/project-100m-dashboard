# UI redesign alignment — P100-UI-001

Owner-approved brief, 2026-11-12. Continue M0 on the existing branch; no M1, production SQL, account integration or merge. This supersedes v1's spacious dashboard treatment while retaining the approved capabilities and review gate.

## Reference hierarchy and verified observations

Eight owner-provided local iPhone images in `iOS Strava ss/` were visually inspected: Feed, Maps, Workout, Groups/events, and Profile progress/activities/gallery/more. They take priority over dated secondary web references. All eight depict dark presentation; light mode is an original semantic adaptation, not an observed vendor light screen. Filenames and SHA256 inventory are recorded separately; raw images remain ignored/local because they contain personal identity, routes and third-party media. Copy none of their photographs, logos, custom icons, text, routes or user data.

Observed structure: compact header controls in circular translucent surfaces; strong titles with restrained secondary text; relatively flat activity sections separated by dividers; avatar/name/time above activity title and three-column stats; large route media; sport cards with prominent capsule actions; profile identity followed by stats and section navigation; Groups filters above event cards; Maps with overlaid chips and a route summary; floating translucent five-item capsule with a distinct selected pill. These observations guide original SwiftUI composition, not pixel copying.

No Mobbin/Flownato MCP tools are configured. [Flownato](https://www.flownato.com/apps/strava) exposes an Android flow inventory, not proof of current iOS styling; [Mobbin](https://mobbin.com/apps/strava-ios-1ac190cf-46ee-4c65-845d-38bb8354219d/0581b139-5dc9-492d-89ad-da56951a027b/screens) was inaccessible. WHOOP references apply only to Health hierarchy/insight presentation; no new accessible WHOOP screens claimed.

## Navigation mapping

| Reference language | PROJECT 100M destination | Reason |
|---|---|---|
| Home | Feed + Today remain separate primary tabs | Public community and private next-session guidance have different privacy/purpose |
| Maps | Train → Maps sample screen | Route discovery supports workouts; no extra primary tab or location permission |
| Workout | Train | Prescribed training remains central; no fake recording action |
| Groups | Feed → Groups → Events/Clubs/Challenges samples | Community belongs beside public activities |
| You | Me | Identity, activity previews, progress and real local settings |
| Health / Insights | Dedicated Health tab | Preserves HEALTH-01: three rings first; no profile-ring duplication |

Exactly **Feed, Today, Train, Health, Me** in that order. Native TabView and five independent NavigationStacks retain state. Its presentation bar becomes a custom SwiftUI floating capsule; hiding the stock bar must preserve navigation, selected accessibility state and restoration. This intentionally forgoes the stock UITabBar accessibility container; tests target stable tab identifiers and selected traits. Maps/Groups are secondary views, not six primary tabs. Moving Health under Me would reduce discoverability and contradict HEALTH-01, so is rejected for this sprint.

## Implementation contract

Shared adaptive colours, typography/spacing, flatter activity sections, outlined chips, profile avatar/stats, circular icon links, original illustrated routes and floating material components. All examples visibly labeled; filters switch actual local sample collections/sections. Unavailable social/edit/start/join actions are not presented as working backend operations. Maps is an original coordinate-free illustration: no MapKit tiles, location reads, GPS, real route or saved-route claim.

The iOS17 minimum and Xcode16.4/iOS18.5 acceptance matrix remain. The bar uses an iOS17-compatible material with edge highlight, shadow and selected pill; Reduce Transparency becomes opaque, Reduce Motion avoids animated selection, large text retains full accessible labels. This is **Liquid Glass styling using Material**, not a claim that Apple's newer `glassEffect` API was compiled/tested. Actual SDK26 Liquid Glass adoption is a separately tracked visual/platform refinement; do not introduce an uncompiled conditional API path. [Apple custom-glass documentation](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views) distinguishes the native effect.

## Acceptance and evidence

Compile and run four meaningful UI methods on named iPhone16/SE3 iOS18.5. Preserve prior Health states, sample dates, ring details, bounds, theme/type probes, stack/restoration checks; adapt bar queries to its actual accessibility tree. Add light/dark captures for all five tabs and secondary Maps/Groups/Workout/Profile sections. Verify filters/section selection, capsule order/count/selected state, targets≥44pt, narrow width, safe areas and AX5; evidence must name actual commit, trees, run/job/artifact, attachment and SHA256. No source-only PASS. Claude independently reviews alignment, privacy and acceptance; parent M0 stays CHANGES_REQUESTED. No real-device or live backend acceptance claimed.
