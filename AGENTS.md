# PROJECT 100M agent entry point

Read [Product Blueprint](docs/product/PRODUCT_BLUEPRINT.md), [requirements](docs/product/FEATURE_REQUIREMENTS.md), [design](docs/product/DESIGN_SYSTEM.md), [architecture](docs/architecture/SYSTEM_ARCHITECTURE.md), [data model](docs/architecture/DATA_MODEL.md), and [decisions](docs/architecture/DECISIONS.md).
Resume from [CURRENT](docs/handover/CURRENT.md), [TASKS](docs/handover/TASKS.md), and [REVIEW](docs/handover/REVIEW.md). Run `python scripts/handover.py status` and `validate` before a handoff.

- Native changes must also follow `native-ios/AGENTS.md` and `native-ios/CLAUDE.md`; preserve their privacy and licensing safeguards. The approved blueprint supersedes the legacy roadmap's milestone numbering and four-tab layout.
- Codex implements; Claude reviews architecture, UX, privacy and acceptance. One owner per task. Do not self-accept or expand into the next milestone before required review.
- Preserve the website, legacy payloads and production history. Develop on `codex/` branches; never merge unfinished work into main.
- No destructive database migration, private health fixture, service key, automatic public workout sharing, health upload, or AI transmission. Use explicit consent and owner-scoped RLS.
- Commit evidence before recording its SHA. Simulator build, simulator runtime, signing and real-device acceptance are separate evidence categories.
