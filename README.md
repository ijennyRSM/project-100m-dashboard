# PROJECT 100M — Athlete Training Journey (V2)

Mobile-first training tracker hosted on GitHub Pages.

**Website:** https://ijennyrsm.github.io/project-100m-dashboard/

## What works now (no login required)
- Default **100M — The Comeback** program: 12 training blocks, 60 sessions.
- Choose preset programs: **5K Foundation, Strength Foundation, Active Wellness**.
- Sessions **do not expire and are not bound to weekdays**. Completed advances, Partial stays on that session, Skipped advances but remains counted as skipped.
- Named profiles, separate plans, quick/detailed workout logs, progress and history.
- Sprint time trial trend, RHR trend, sleep trend, daily recovery and Coach Report export.
- Apple Health manual import from export.xml/export.zip in **Settings** (selected data only, processed in your browser).
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

## Notes
- Not a medical device.
- Apple Health imports are not automatic Apple Watch sync, and Watch workouts do not automatically prove the prescribed sprint session was completed.
- Track 100m time with a consistent timing method, not Watch GPS.
- Build sprint fitness gradually and avoid high-intensity exercise during illness.
- Edits to main branch auto-deploy via GitHub Pages.

## Source
- index.html, v2.css, v2-data.js, v2-ui.js, v2-health.js — V2.
- cloud-config.js — public cloud settings (empty by default).
- supabase-schema.sql — private account data with RLS.
- v1.html, app.js, style.css, payload/ — V1 fallback.
