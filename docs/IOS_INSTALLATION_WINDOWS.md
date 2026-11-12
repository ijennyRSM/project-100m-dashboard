# Installing PROJECT 100M on an iPhone from Windows

This guide takes the **unsigned iPhone build** produced by GitHub Actions and installs it on your
own iPhone with **Sideloadly** and a **personal Apple ID**. No paid Apple Developer Program
membership is needed for this basic personal-testing route, but it has real limits (below),
especially for **Apple Health (HealthKit)**.

> Status: build-level evidence only. Until you install and launch it yourself and record the
> result, nobody has proven that this IPA installs or runs on a physical iPhone.

## 0. What you are installing and why it needs signing

- The workflow **iPhone Device Build (Unsigned IPA)** compiles the real **arm64 iPhoneOS** app
  (not the Simulator app) and packages it as `PROJECT100M-unsigned.ipa`.
- iOS **only runs apps signed by a certificate Apple trusts for that device**. The IPA carries
  no Apple certificate and no provisioning profile. Tapping or opening it on the iPhone, emailing
  it, or putting it in Files **will not install it**.
- The IPA has an *ad-hoc pseudo-signature* (no identity) whose only job is to record which
  entitlements the app declares (`com.apple.developer.healthkit`). Sideloadly replaces it with
  a real development signature that it creates using your Apple ID.

## 1. Open the successful GitHub Actions run

1. Sign in to GitHub in your browser (artifacts can only be downloaded by signed-in users with access).
2. Open the workflow page:
   <https://github.com/ijennyRSM/project-100m-dashboard/actions/workflows/ios-device-ipa.yml>
3. Click the newest run with a **green check** on branch `codex/m0-foundation-handover`
   (the latest verified run is also listed in `docs/handover/CURRENT.md`).
4. The run **Summary** shows the commit, Xcode/SDK, build number and the IPA **SHA256**.

To build again without a code change: on the workflow page click **Run workflow**, choose the
branch, and wait about 10 minutes.

## 2. Download the artifact

On the run's Summary page, scroll to **Artifacts** and download **`PROJECT100M-iPhone-Unsigned`**.
Artifacts are kept for 30 days; re-run the workflow if it has expired.

## 3. Extract the IPA from the artifact ZIP

GitHub always delivers artifacts as a `.zip`. The IPA is *inside* it.

1. Right-click `PROJECT100M-iPhone-Unsigned.zip` → **Extract All…**
2. In the extracted folder you will find:
   - `PROJECT100M-unsigned.ipa` ← the file Sideloadly needs. **Do not unzip the IPA itself.**
   - `SHA256SUMS.txt`, `provenance.json`, `verification.txt`, `verification.json`,
     `declared-entitlements.plist` ← build evidence.
3. Optional integrity check in PowerShell (the hash must equal the one in `SHA256SUMS.txt`
   and the run Summary):

   ```powershell
   Get-FileHash .\PROJECT100M-unsigned.ipa -Algorithm SHA256
   ```

## 4. Install Sideloadly

Download only from the official site: <https://sideloadly.io/>. Do not use mirrors or
"pre-signed" IPA sites. Follow the Windows instructions on that page; at the time of writing
it asks for the **web (non-Microsoft Store) versions of iTunes and iCloud from Apple** and
asks you to uninstall the Microsoft Store versions first. If the official page says something
different from this guide, follow the official page.

## 5. Prepare Apple device connectivity on Windows

1. Install iTunes and iCloud as described by Sideloadly's page, then restart Windows.
2. Open iTunes once so Apple's device drivers finish installing.
3. Use a data-capable USB cable (some charging-only cables do not work).
4. Wi-Fi installation is possible but less reliable; use USB for the first install.

## 6. Connect and trust the iPhone

1. Unlock the iPhone and connect it by USB.
2. On the iPhone tap **Trust** on *Trust This Computer?* and enter your passcode.
3. iTunes should show the device. If it does not, reconnect, try another port/cable, and
   restart the Apple Mobile Device Service (or Windows).

## 7. Sign with your Apple ID in Sideloadly

1. Open Sideloadly. Your iPhone appears in the **iDevice** list.
2. Drag `PROJECT100M-unsigned.ipa` onto the IPA area (or click the IPA icon and select it).
3. Enter your Apple ID **in Sideloadly's own Apple account field**. Sideloadly asks for the
   password and, for two-factor accounts, the code shown on your Apple device.
   - Type these only into Sideloadly's prompts. **Never put your Apple ID password or 2FA codes
     into this repository, a GitHub issue/log, a commit, or a chat with Claude or Codex.**
   - Many people use a secondary Apple ID for sideloading; that is your choice.
4. Leave **Advanced Options** at their defaults for the first attempt. Keeping the default
   bundle identifier (`com.project100m.ios`) means later re-installs update the same app and
   keep its on-device data. If Sideloadly reports the identifier is unavailable to your team,
   let it change the bundle ID, and note that in your test report.

## 8. Install

Click **Start**. Sideloadly registers the device with your personal team, creates a free
development certificate and profile, re-signs the app and installs it. Watch the log window;
**Done** means the install step finished, not that the app works.

## 9. Trust the developer and enable Developer Mode

1. **Developer Mode** (iOS 16 and later): *Settings → Privacy & Security → Developer Mode* →
   switch on → **Restart** → after restart confirm **Turn On** and enter the passcode.
   The switch usually appears only after a development-signed app has been installed.
2. If iOS says *Untrusted Developer*: *Settings → General → VPN & Device Management* → select
   your Apple ID under *Developer App* → **Trust** → confirm.

## 10. Open PROJECT 100M and test

Launch **PROJECT 100M** from the Home Screen. Record UI results and Health results separately:

| Area | What to check | Counts as |
|---|---|---|
| Launch | App opens to five tabs: Feed, Today, Train, Health, Me | UI install success |
| Layout | Light/Dark mode, larger text, floating tab bar, scrolling | UI evidence |
| Account | Me → sign-in sheet; sign in with your existing PROJECT 100M email; force-quit and reopen | Account evidence |
| Training | Choose a plan, start a Live Workout, close the app mid-workout, reopen, finish as Partial/Completed | Training evidence |
| Health | Health tab → connect Apple Health → allow → values or calm "missing" states | **HealthKit evidence (see §13)** |

A UI success is **not** proof that HealthKit works. Report them separately.

## 11. Collect installation and launch errors

When something fails, capture all of these (none of them should contain your password):

1. **Sideloadly**: copy or save the full log text shown in the window, and a screenshot of the error.
2. **iPhone error dialogs**: screenshot the message.
3. **Crash reports**: *Settings → Privacy & Security → Analytics & Improvements → Analytics Data*,
   open entries starting with `PROJECT100M`, tap Share and save them.
4. **In-app Health error**: Health tab / *Me → More → Apple Health และอุปกรณ์* shows the exact
   HealthKit error text in red; screenshot it.
5. Record the GitHub run URL, the IPA SHA256, iPhone model, and iOS version.

Remove email addresses, Apple IDs or device serial numbers before sharing logs publicly.

## 12. Repeat signing when the free provisioning expires

- Apps signed with a free personal team **expire after 7 days**. The app then refuses to open.
- Re-run steps 6–8 with the same Apple ID and the same (or newer) IPA. Installing over the
  existing app with the same bundle ID normally **keeps the app's local data**; deleting the app
  from the iPhone deletes its local data.
- Sideloadly offers optional automatic refresh while the PC and iPhone are on the same network;
  see the official site.
- Free personal teams have additional Apple limits (for example a small number of
  simultaneously installed sideloaded apps and of new App IDs per week). If you hit them, wait
  for the limit window or remove other sideloaded apps.

## 13. HealthKit compatibility — what is and is not known

- The main app **keeps HealthKit**: source, usage description and the
  `com.apple.developer.healthkit` entitlement are all present, and the IPA's verification
  proves the entitlement is declared in the binary.
- Whether a **free personal team** can provision HealthKit is **not guaranteed**. Developer
  reports show free/team profiles that "doesn't support the HealthKit capability", and Apple
  does not document a guarantee. Sideloadly may also drop entitlements that your account cannot
  provision. **This route is therefore unverified for HealthKit** until you test it.
- How to tell on the device: open the Health tab and tap connect.
  - The Apple Health permission sheet appears and, after allowing, values or "missing" states
    appear → HealthKit is provisioned for this install. Record it as HealthKit evidence.
  - A red error mentioning a missing HealthKit **entitlement**, or no permission sheet at all →
    the signing route did not provision HealthKit. The rest of the app (UI, account, training)
    still works; Health shows a failure state and no fabricated numbers.
- **Supported route for full HealthKit testing**: sign with an **Apple Developer Program**
  team (paid) — in Xcode on a Mac (local or cloud Mac), via TestFlight, or with that paid
  account in Sideloadly — so the App ID has the HealthKit capability enabled and the
  provisioning profile contains the entitlement.
- No separate "UI-only" build is published: the main app already degrades to honest Health
  failure states, and a second variant would risk being mistaken for the full app.

## 14. Signing in to your existing PROJECT 100M account

The native app uses the **same Supabase account** as the website (email sign-in, no password).
On the Me tab choose sign in, enter your email, and then either:

- type the **6-digit code** from the email, if the email contains one; or
- long-press the sign-in **link** in the email, choose **Copy Link**, and paste it into the app.
  Do **not** tap the link first — the link is single-use and tapping it opens the website instead.

Your session is stored in the iPhone **Keychain**, restored after restarting the app and
removed when you sign out. Training data on the phone is kept separately per account.
If you trained in Guest mode before signing in, *Me* offers an explicit **copy into this
account** action; nothing is merged automatically and nothing is uploaded.

Optional Supabase dashboard settings (owner decision; no database change, none applied by agents):

- *Authentication → Email Templates → Magic Link*: adding `{{ .Token }}` to the template makes
  emails include the 6-digit code, which is the easiest way to sign in on the phone.
- *Authentication → URL Configuration → Redirect URLs*: adding `project100m://auth-callback`
  lets tapping the email link open the app directly. Without it the link opens the website.

Native training is **not synced** to Supabase yet and never overwrites the website's history.

## 15. Known reasons installation can fail

| Symptom | Likely cause | What to do |
|---|---|---|
| Device not listed | Store-version iTunes/iCloud, driver missing, not trusted, cable | Reinstall Apple's web versions, Trust, change cable/port |
| Apple ID / 2FA / "Your session has expired" | Login rejected, 2FA timeout, app-specific restrictions | Retry in Sideloadly; never share codes |
| "Maximum number of apps" / App ID limit | Free-team limits | Remove other sideloaded apps or wait for the limit window |
| Bundle ID unavailable | Identifier registered to another team | Let Sideloadly change the bundle ID and note it |
| "Untrusted Developer" | Developer certificate not trusted yet | Settings → General → VPN & Device Management → Trust |
| App will not open after a week | Free 7-day provisioning expired | Re-sign (§12) |
| "Developer Mode required" | iOS 16+ setting off | §9 |
| iOS version error | iPhone below iOS 17.0 | Update iOS; the app requires iOS 17 or later |
| Health shows entitlement error | Signing route did not provision HealthKit | Expected possibility on free teams; see §13 |
| Crash at launch | App defect or signing problem | Collect §11 evidence and report it |
