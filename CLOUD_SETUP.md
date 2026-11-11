# PROJECT 100M — Cloud connection

**Supabase project:** project-100m (Singapore)
**Project ID:** rbryddekjwytcoqqgcgu
**Website:** https://ijennyrsm.github.io/project-100m-dashboard/

## Connected and verified
- Supabase project created and ACTIVE_HEALTHY.
- Database migration applied: public.training_states and public.save_training_state.
- RLS active with per-account select, insert and update policies.
- Unauthenticated role has no table SELECT or RPC EXECUTE privilege.
- Supabase security/performance advisors returned no notices at setup time.
- Only Supabase Project URL and public **publishable key** were committed to cloud-config.js. No private/secret keys were added.

## One-time setting required in Supabase Dashboard
The available integration cannot edit Supabase Auth URL Configuration. Before using email Magic Link, the project owner must open:
https://supabase.com/dashboard/project/rbryddekjwytcoqqgcgu/auth/url-configuration

Set:
- **Site URL:** https://ijennyrsm.github.io/project-100m-dashboard/
- **Redirect URLs:** add https://ijennyrsm.github.io/project-100m-dashboard/

Then press Save.

## Login and synchronization test
1. Open the website using Safari (avoid private browsing).
2. Open **Settings → Cloud Login & Sync**, enter your email, and select **Send login link**. Check email and open the Magic Link **on the same iPhone** in Safari.
3. The Cloud status should change to "synced" once data is available, or "ready" on a new account.
4. Record a test workout and press **Sync now**. Check that Cloud status is "synced".
5. Open the website from a second device with **the same** email. Verify the test workout is visible there.
6. Your partner should log in with a **different email**. They should not see your training history; they can choose their own preset plan.

If login email sends you to localhost or another wrong URL, check the Auth URL Configuration above.

## How cloud data is stored
- training_states contains one JSON document per Supabase auth user ID, plus an integer revision.
- Public GitHub Pages code cannot read other accounts because authenticated requests are protected by per-user RLS policies.
- On saving, the browser sends a changed document with optimistic revision checking (preventing silent overwrite by a stale device).
- If two devices write concurrently and you see "conflict", download a JSON backup on both devices before proceeding.
- Default local profiles in the same browser do not by themselves sync; the website syncs the account associated with the current authenticated email.
- When first signing into an empty account, the app offers to copy the **selected local profile** up to that account, only after confirmation.
- Imported Apple Health XML/ZIP is processed locally, but the selected extracted health metrics can be included in cloud sync after sign-in.
- Apple Watch automatic HealthKit sync is not implemented. You must export Apple Health to a file and import it manually.

## Important safety notes
- GitHub Pages is public, but data stored in the Supabase table is private under RLS. Do not commit personal health files into the GitHub repository.
- **Never** use an sb_secret, service_role or any private token in cloud-config.js.
- Magic Link authentication requires the redirect setting above; until this is saved, end-to-end login has **not** been verified.
- A published frontend and database do not guarantee successful two-device sync until a real user tests email login and a saved workout on both phones.

## Source files
- supabase-schema.sql — migration code (already applied)
- cloud-config.js — connected public Project URL and publishable key
- v2-data.js — cloud auth and revision-checked sync logic
- v2-ui.js — login, progress, recovery, logs
- v2-health.js — manual Apple Health import
