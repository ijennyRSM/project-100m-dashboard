# Windows local development

The existing root checkout is retained. Web development uses `E:\Project100M\web` on `codex/web-platform-expansion`, based on `origin/main`. Native development uses `E:\Project100M\ios` on `codex/ios-development`, based on the latest `origin/codex/m0-foundation-handover` (which contains newer work than `feat/ios-native-foundation`). Both share Git objects/remotes but have separate indexes and files.

## Web commands

From the Web worktree:

```powershell
npm.cmd ci
npx.cmd playwright install chromium
npm.cmd run dev
# In a second terminal:
npm.cmd test
```

Preview: http://localhost:5500. The server binds loopback only and hides dot paths, dependency directories and browser artifacts. Set `$env:PORT='5501'` and `$env:BASE_URL='http://127.0.0.1:5501'` together if port 5500 is occupied. Playwright starts a server automatically if none is running.

If browser download is unavailable, an installed Chromium browser can be selected explicitly:

```powershell
$env:PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH='C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'
npm.cmd test
```

Tests use fresh disposable browser contexts and synthetic training records. Supabase requests are blocked; do not log into a real account for these tests. Browser artifacts are ignored. Never commit health exports, account storage, credentials, MCP configuration or machine paths to runtime code. External CDN scripts/fonts remain production dependencies and are checked by the asset test.

The default suite checks local assets. Run the separate live CDN diagnostic with `$env:CHECK_EXTERNAL_ASSETS='1'; npx.cmd playwright test --grep '@online' --workers=1`. A DNS outage can fail that diagnostic independently of local application behavior.

## Git and review

Run `git fetch origin`, inspect `git status` and `git diff`, and commit only the intended worktree files. Push a `codex/` feature branch, open a PR to `main`, require passing Web browser tests and Claude review, and merge only after owner/reviewer acceptance. Never force-push or push unfinished work directly to main. Pages currently publishes `main:/` using legacy branch publishing; this setup does not change deployment settings.

Codex owns infrastructure/implementation/tests. Claude owns architecture, UX, privacy and acceptance review. Assign one owner and worktree per task. A reviewer can inspect commits with `git show` without editing the implementer's worktree; create another worktree/branch before review fixes. Do not run concurrent Git mutations or edits against the same working directory. Git metadata is shared across worktrees.

## Native preservation

Read `native-ios/AGENTS.md`, `CLAUDE.md`, `README.md`, `ROADMAP.md` and the handover in the native worktree. Windows does not compile Xcode projects. Existing macOS CI handles simulator compilation/UI tests and the separate unsigned device IPA workflow. Signing, physical launch, real HealthKit and live auth acceptance remain separate evidence categories. No native source or existing native workflows are changed here.

The Web branch is based on production and does not contain the newer native/handover files. Run `python scripts/handover.py status` and `python scripts/handover.py validate` from the retained root/native worktree before handoff; do not copy a newer native ledger into Web just to make the branch appear complete.

## REA

Follow the [official setup](https://rea.tools/get-started/): review each client's dry-run plan, approve changes, preserve backups, then run scoped setup and doctor for `codex` and `claude_code`. REA needs Node ^22.23.4, ^24.22.1 or >=26.12.1. The original machine Node v24.12.0 is too old.

REA setup and doctor do not prove a tool is connected to an active agent. Restart affected sessions after registration and execute a real REA tool. Preserve other MCP registrations; keep all local MCP settings/backups outside Git. Native analysis engines are unnecessary for this static Web task. Use Playwright for reproducible Chromium testing and REA's advertised browser/runtime tools for inspection after connection.
