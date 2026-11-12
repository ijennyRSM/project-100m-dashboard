# Current handover — screenshot-led M0 redesign

2026-11-12 (Asia/Bangkok). Codex owns **P100-UI-001 READY_FOR_REVIEW** on `codex/m0-foundation-handover`, [draft PR#1](https://github.com/ijennyRSM/project-100m-dashboard/pull/1), base `feat/ios-native-foundation`. **Parent M0 remains CHANGES_REQUESTED; M1 remains BLOCKED.** No merge, self-acceptance or production operation.

## Approved direction and reference handling

Owner's new UI brief supersedes the v1 dashboard styling. Eight local dark iPhone images were inspected and take precedence over older web references. [Alignment](../product/DESIGN_ALIGNMENT.md), [reference SHA256 inventory](../product/DESIGN_REFERENCES.json), UI-01 and [design v2](../product/DESIGN_SYSTEM.md) persist the decision. All eight original files are unchanged and ignored/local; no personal names/photos/routes were transcribed into app fixtures or published. Light mode is an original adaptation. Mobbin/Flownato MCP unavailable; public Flownato is an Android inventory, Mobbin inaccessible. No unobserved vendor transitions/version claims.

Exactly **Feed, Today, Train, Health, Me**. Maps is secondary under Train; Groups under Feed. Health stays first-class with Sleep/Recovery/Strain first and none in Me. This preserves the five-tab contract while adapting Home/Maps/Workout/Groups/You visual patterns. Moving Health under Profile was rejected; see ADR-011/012.

## Implemented presentation

- Shared adaptive near-white/near-black surfaces, forest/mint actions, typography/spacing, flat activity sections, avatar/stat strips, outlined chips, circular material controls and capsule actions.
- Floating translucent Material capsule over native TabView, selected accessibility traits, ≥44pt targets, opaque Reduce Transparency fallback, no selection animation, enlarged-content labels. Five native stacks and restored selected tab remain.
- Feed: compact header, local sport filter, activity identity/title/stats and original route illustration. Today: next-session/progress/recovery hierarchy. Train: prominent Running/Strength previews and existing five-program catalog. Workout: labeled session composition.
- Groups: Events/Clubs/Challenges samples. Maps: coordinate-free illustration, local sample selector and overlaid summary (vertical fallback for accessibility sizes). Me: identity/bio/stats and local Progress/Activities/Gallery/More sections. Health retains real connection states, measured sample dates, interactive missing-score rings and read-only service.
- Width-driven Feed header stacks when its full introduction/action do not fit. AX5 asserts vertical placement, target bounds and bounded action height rather than accepting narrow text columns.

| Boundary | Actual status |
|---|---|
| Fictional presentation | Activities, totals, progress bars, gallery illustration, groups/events and route summaries; visibly labeled |
| Local interactions implemented | Filter/section/sample selection, navigation/back, tab/stack preservation, settings screens and existing web links |
| Existing real integration | Read-only on-device HealthKit retained unchanged; mock simulator tests do not verify real permissions/data |
| Not implemented by sprint | Accounts, posting/likes/comments/join, GPS, recording, enrollment, photo upload, cloud/AI or scores |

## Commits and verification

- `7026375`: alignment/requirements committed before feature development.
- `30bebd2881788ebd28fb6b9c31122589a9ccc3fa`: first presentation pass. [Run43129292963](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43129292963): app builds PASS, UI0/4 on each device. A parent identifier overwrote all five button IDs; runtime tree excerpt/provenance retained in evidence/UI-redesign.
- `6158ec90fba4ff94489d846c5a2fce0a13ad1bbd`: fixed identity propagation; added launch failure diagnostics, enlarged-content labels and map-summary adaptation. [Run43130713599](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43130713599): both builds and4/4 UI zero failures each PASS (16:476.423s; SE:503.140s). Artifact digests/head+merge trees verified. **Visual acceptance withheld:** manual inspection found AX5 Feed squeeze that the tests missed; prior screenshot/provenance retained.
- `f379701309dd2893620724fab86de2dab6e6a631`: responsive Feed correction plus stronger assertions. SE3 passed4/4 (424.161s); iPhone16 layout case passed326.890s but the15min UI step timed out during case2 after nearly9min preparation. No full iPhone16 PASS claimed; timeout evidence retained.
- `370addedb5637cf984aff957878ed848f4de4b00`: UI-step25min/job40min budget; per-test maximum420s unchanged. [Run43138252275](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43138252275) both builds and4/4 UI zero failures each PASS (16:420.150s; SE:568.950s). ZIP digests verified and head/merge native/.github trees matched. AX5 header visually corrected; some adjacent captures partially rendered and default stats appeared clipped, so capture-quality acceptance was withheld. Evidence preserved.
- **Current implementation `5ecb4f212932418d4257dd8c2b6cda390f196d9d`** preserves intrinsic StatStrip height and settles UI captures after a preflight screenshot. Native tree `32941871117b0fd1a74c66db854780d08ad526ac`; .github tree `3a8c647eb5c6842617ea45141b175610840bde3f`. [Current native run43141777432](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43141777432) completed SUCCESS: both unsigned builds PASS and all4 UI tests zero failures each (iPhone16:368.545s; SE3:402.776s). Tested merge `79c26b3b2401f20855fc7053d2183f116a9bf128` matches both head trees, checked with git. Artifact13909953454/13910042452 ZIP digests verified; [52 original selected screenshots](evidence/UI-redesign/README.md), attachment mappings/test excerpts/provenance committed. Previous-source evidence remains historical.
- Local Windows:15 handover/grant unit tests PASS; ledger11-record validation PASS; diff/source checks PASS; eight reference images unchanged/ignored. Web files, Health services, SQL and credentials unchanged in this sprint.
- Current [Windows/Linux handover43141777372](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43141777372) and [PG16/17 security43141777481](https://github.com/ijennyRSM/project-100m-dashboard/actions/runs/43141777481) completed SUCCESS. Security source unchanged; no live database operation.

## Remaining limits and review

This is **iOS17-compatible Liquid Glass styling using Material**, not verified SDK26 native glassEffect. OS large-content-viewer/Reduce Transparency interaction, full VoiceOver, iOS17 runtime and real Display Zoom require separate acceptance; app-level AX5 fixtures are not OS-setting proof. No signed iPhone/Watch/GPS/background acceptance (M7). Representative current Feed light/dark, both-device AX5 heading/action, Me light, Health dark, Maps light, Train dark and Workout light inspected. Settled header frames now show complete content and Groups below the heading. Complete gallery still needs independent Claude review; representative inspection is not acceptance. Claude must compare references privately; hashes are not a substitute for the images.

Claude: review UI-01 alignment/originality, five-tab mapping, custom bar accessibility, local sample boundaries and new runtime gallery; return severity/requirement/file-line/evidence/disposition. Codex resolves findings and resubmits. No automated Claude integration or self-verification.

## Preserved security and prior-review gate

Original Claude findings remain in REVIEW.md; previous M0 fix evidence is in evidence/M0-review-fix and handover commit694c23a. New UI evidence must use the current trees above. **SEC-001 live Critical grants remain unchanged**: preparation ated7b525 is READY_FOR_REVIEW, not production resolution. Migration A/setup correction and separate global-default B proposal require independent scope review, hosted disposable Auth/PostgREST/web smoke, backup confirmation and explicit owner production approval/read-only verification. No private production payload or hosted SQL operation occurred. See supabase/security/README.md. M1 remains blocked until M0/SEC gates pass.

## Copy-ready Claude request

> Review P100-UI-001 and parent M0 at5ecb4f212932418d4257dd8c2b6cda390f196d9d on codex/m0-foundation-handover / draft PR#1. Read root/native instructions, DESIGN_ALIGNMENT, UI-01/design v2, CURRENT/REVIEW/tasks and the current52-image gallery/provenance. Compare owner reference images privately. Re-review original M0 findings against the new UI, five-tab mapping, Material-bar accessibility, privacy/sample boundaries and exact-source4/4+4/4 CI. Return requirement-linked findings and acceptance disposition. No self-acceptance, production SQL, merge or M1.
