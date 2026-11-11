# PROJECT 100M V2 — Cloud setup

The website is already functional in **local mode**. Training plans, profiles, session completion, quick/detailed workout logging, recovery, history and JSON export work without Supabase. Local mode saves data only in that browser. It does NOT automatically sync between phones.

## Enable real cross-device sync (user action required)
1. Create a Supabase project in your own Supabase account at https://supabase.com/dashboard .
2. In **SQL Editor**, run the entire content of [supabase-schema.sql](./supabase-schema.sql).
3. In Supabase **Authentication → URL Configuration**, set Site URL to:
   https://ijennyrsm.github.io/project-100m-dashboard/
   and add that same address to **Redirect URLs**.
4. Find your **Project URL** and **publishable key** (sb_publishable_...) in Supabase project settings. Edit [cloud-config.js](./cloud-config.js), adding the URL and *publishable* key only. NEVER upload a service_role key, secret key, private token or password.
5. Commit/push cloud-config.js; refresh the website. On each iPhone, open Settings → send email magic-link. Use a different email account for each person.
6. Check that both accounts see only their own data. Test by recording one workout on phone A, logging into the SAME account on another device and checking sync. The two users' different accounts should remain isolated.

## Training experience
- Each program is a sequence of training blocks and workouts, **not a calendar**.
- Opening the site after several days continues from the same next session.
- Completed advances; Partial stays on same step; Skipped advances deliberately but does not count as completed.
- Safety messages remind you to respect recovery; they cannot diagnose your health.
- Each account can create multiple named profiles and each profile can have its own plans.
- Change profile via the selector. For separate users on separate phones, use separate Supabase auth accounts.
- Export JSON backup before changing devices or restoring data.
- When you first open V2 on the same browser as V1, existing V1 workout records are copied into **Previous V1 History**; the original V1 key remains untouched.

## Limits / privacy
- GitHub Pages serves static public files; it is not a backend, database or private storage.
- Supabase Auth + Postgres RLS provide authentication and per-account private data, once set up.
- This V2 does NOT yet auto-import Apple Watch HealthKit or directly sync Apple Health XML/ZIP. Existing V1 logs can be migrated and manual recovery data can be entered. HealthKit needs an iOS bridge and clear user permissions.
- Cloud sync uses a revision check; if two devices update the same account concurrently, the newer state is not silently overwritten. Export backup and manually resolve a reported conflict.
- Safari private browsing, clearing site storage, or using another browser may lose locally stored data until cloud sync is configured.
- HR and HRV are wellness/training indicators and not medical diagnosis.
- No supabase account, project or credentials were created by the GitHub deployment process.

## Files
- index.html → V2 entrypoint
- v2-data.js → training templates, profile state, persistence, optional cloud auth/sync
- v2-ui.js → pages, forms, user interaction
- v2.css → responsive styles
- cloud-config.js → public Supabase project configuration (empty by default)
- supabase-schema.sql → SQL you must run inside your Supabase project
- Old V1 files are still in the repository for rollback if needed.
