# PROJECT 100M — Athlete Dashboard

Sprint-first 12-week training dashboard for running, strength, recovery and Apple Health exports.

## Publish with GitHub Pages

Open **Settings → Pages → Build and deployment** and choose:
- **Source:** Deploy from a branch
- **Branch:** main
- **Folder:** /(root)
- Click **Save**

Once enabled, open: https://ijennyrsm.github.io/project-100m-dashboard/

## Privacy and backups

This is a static, local-first website. Workout logs, Apple Health summaries and recovery entries remain in **this browser's localStorage**. No Apple Health file is uploaded to GitHub. There is no account-based sync across devices.

Regularly choose **Data & Settings → Download full backup**. The **Create coach report** feature exports a Markdown training summary the user can choose to share.

Apple Health ZIP imports use JSZip from cdnjs; the ZIP/XML itself is processed locally in-browser. Modern Safari is required for the static application loader.

The 100m sprint timing must be entered manually. Apple Watch GPS pace is not an accurate substitute for track timing.

## Application source

The original JavaScript application was losslessly gzip-packaged in 4 text chunks under `payload/` to support the GitHub upload process; `app.js` reconstructs and loads it in the browser. These chunks contain **source code only**, not personal data.