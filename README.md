# PROJECT 100M — Move at Your Pace (Wellbeing Edition V4)

Mobile-first training companion hosted on GitHub Pages. V4 uses a warm, accessible fitness design with clearer Thai navigation, large touch targets and a one-tap quick logging experience.

**Website:** https://ijennyrsm.github.io/project-100m-dashboard/

## What works now (no login required)
- **Live Workout Mode**: tick off prescribed sprint repeats, strength sets, warm-up and cooldown; rest timer, elapsed timer and resume after leaving the page. Completing the whole prescription advances the plan; a partial session does not.
- **Sleep Insights**: Apple Health Core/Deep/REM sleep-stage import, sleep target and 7-night average. Percent shown is goal attainment, not a clinical or WHOOP score.
- **Coach Insights (beta)**: transparent rule-based observations using the athlete’s own sleep/recovery/training records. Not a generative AI provider; no data is silently sent to a model.

- Default **100M — The Comeback** program: 12 training blocks, 60 sessions.
- Choose preset programs: **5K Foundation, Strength Foundation, Active Wellness**.
- Sessions **do not expire and are not bound to weekdays**. Completed advances, Partial stays on that session, Skipped advances but remains counted as skipped.
- Named profiles, separate plans, quick/detailed workout logs, progress and history.
- Sprint time trial trend, RHR trend, sleep trend, daily recovery and Coach Report export.
- Apple Health manual import from export.xml/export.zip in **Settings** (selected data only, processed in your browser). **Large ZIPs are streamed** with fflate: a 36MB compressed archive may contain a 250MB+ XML file. The original archive is never uploaded. Keep Safari open until import finishes.
- JSON backup and restore; V1 is preserved at [v1.html](./v1.html). Older V1 workouts and recovery can migrate from the same browser.

### Important: local vs cloud
The Supabase project, protected database and public client configuration have now been created and pushed. **The owner must still add the GitHub Pages URL in Supabase Auth URL Configuration before Magic Link sign-in can be tested.** See [CLOUD_SETUP.md](./CLOUD_SETUP.md). Do **not** place secret keys or Apple Health exports in GitHub.
Each person should sign in with a different email. Account data is isolated with database RLS.

## How to use
1. Open the site in iPhone Safari and optionally Share → Add to Home Screen.
2. On Dashboard tap **Next Workout**, view exercises, and log Completed, Partial or Skipped.
3. Tap **My Plans** to see all 12 blocks or start another program.
4. Use **Recovery** to log sleep, resting HR, HRV and fatigue; use **Settings** for Apple Health import and backups.
5. Use **History → Export Coach Report** to share a training summary for coaching review.

## NOOP research and future integrations
- Read [NOOP_INTEGRATION_ROADMAP.md](./NOOP_INTEGRATION_ROADMAP.md) for a source-level review of NOOP Forge, its noncommercial license, the required iOS HealthKit companion and a secure generative-AI coaching backend.
- Neither direct Apple Watch HealthKit sync nor a generative AI provider is enabled by this static GitHub Pages app. These require separate native and secure server components.

## Notes
- Not a medical device.
- Apple Health imports are not automatic Apple Watch sync, and Watch workouts do not automatically prove the prescribed sprint session was completed.
- Track 100m time with a consistent timing method, not Watch GPS.
- Build sprint fitness gradually and avoid high-intensity exercise during illness.
- Edits to main branch auto-deploy via GitHub Pages.

## Source
- index.html, v3.css, live-wellness.css, icon.svg, v2-data.js, v2-ui.js, v2-health.js, live-workout.js, wellness-insights.js — V4 wellbeing UI with live sessions and sleep summaries.
- v2.css — previous dark-theme stylesheet retained in Git history.
- cloud-config.js — public cloud settings (empty by default).
- supabase-schema.sql — private account data with RLS.
- v1.html, app.js, style.css, payload/ — V1 fallback.

## Photography and fonts
- [Uran Wang / Unsplash — running through morning light](https://unsplash.com/photos/a-person-running-through-a-field-at-sunrise-d6mx781xnvM)
- [Peter Zhan / Unsplash — runner at starting blocks](https://unsplash.com/photos/a-male-runner-in-starting-blocks-on-a-track-P-UYSWGKilA)
- Both images are provided under the Unsplash License and loaded from the Unsplash image CDN.
- Google Fonts: Plus Jakarta Sans and Noto Sans Thai, with platform font fallbacks.

Design-only changes do not reset workouts, profiles, or Supabase cloud data.

## Streaming ZIP dependency
- [fflate 0.8.2](https://github.com/101arrowz/fflate) (MIT) powers incremental ZIP decompression. The page loads the version-pinned UMD build from jsDelivr. No ZIP data is sent to the CDN.
- iOS Safari can suspend long imports if you leave the app; do not switch tabs or lock the phone during a large first import.
