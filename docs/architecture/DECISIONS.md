# Architecture decisions

| ID | Date | Decision / reason / consequence |
|---|---|---|
| ADR-001 | 2026-11-12 | Continue from native branch `15e10f0` on `codex/m0-foundation-handover`; web/main `53ba1b5` preserved. No unrelated repository or production writes. |
| ADR-002 | 2026-11-12 | Owner blueprint supersedes old roadmap numbering. M0 is foundation; device acceptance is M7. Retain native agent safeguards and original HealthKit service pending review. |
| ADR-003 | 2026-11-12 | iOS 17 minimum retained; native TabView with five independent stacks and persisted selected tab. Dynamic Type and semantic light/dark surfaces; no vendor artwork. |
| ADR-004 | 2026-11-12 | M0 fixture screens explicitly labeled; no fake functioning social/training/account actions. Health rings show missing scoring state and explain it. No experimental score implementation before M2 research review. |
| ADR-005 | 2026-11-12 | Task JSON is canonical structured ledger; Markdown is human context/review. Portable Python validates schema, commits, files and gates; archives accepted records. Claude review cannot be executed by a Markdown file or inferred from CI. |
| ADR-006 | 2026-11-12 | Legacy payload preserved; additive schema/adapters only after review. P0 excessive live grants tracked separately; audit is read-only. |
| ADR-007 | 2026-11-12 | No NOOP code/assets copied. Independently implement Apple APIs. No paid service/signing assumption. |
