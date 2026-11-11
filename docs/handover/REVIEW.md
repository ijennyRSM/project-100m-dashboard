# Claude review

Status: pending; no Claude review has been received. No task is ACCEPTED.

Copy-ready instruction:

> Review branch `codex/m0-foundation-handover` against `feat/ios-native-foundation`. Read root AGENTS.md, native-ios/AGENTS.md and CLAUDE.md, docs/product/*, docs/architecture/* and docs/handover/tasks.json. Review the exact implementation SHA in task P100-M0-001. Check five-tab order/state, Health-only rings and honest missing scoring states, fixture labeling, Thai/Dynamic Type/dark-mode layout, preservation of HealthKit controls and privacy, portable handover validation and CI evidence. Review P100-SEC-001 live grant drift urgently: authenticated TRUNCATE must not be treated as RLS-protected. Do not run destructive tests on production. Write findings with severity, file/line, requirement and acceptance test. Mark CHANGES_REQUESTED if needed; do not claim device acceptance or functioning M1–M5 features. Provide explicit acceptance only for satisfied criteria with evidence.

Current implementation SHA: `52cc51ab5ba0799425a0788d8b9766e0e440ef71`. Final CI is blocked/unverified (P100-M0-002); earlier compile and partial UI results do not satisfy the latest-source build/UI criterion. Review architecture and source now, but do not accept M0 before actual passing verification and updated large-text screenshot inspection. Original simulator captures and provenance: [evidence gallery](evidence/M0-9399655/README.md).

Record reviewer identity, reviewed SHA, actual findings, required changes and acceptance disposition in the task ledger and this file. Codex resolves findings and resubmits; a handover file cannot execute Claude.
