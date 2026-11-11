# Task ledger

Canonical records: [tasks.json](tasks.json). One owner per task. Never have Claude and Codex edit the same active implementation concurrently. Each record contains requirements, acceptance, evidence, issues and next actions.

Lifecycle: BACKLOG, READY, IN_PROGRESS, READY_FOR_REVIEW, CHANGES_REQUESTED, VERIFIED, ACCEPTED; BLOCKED requires explanation and unblock condition. VERIFIED needs reviewer evidence and passing acceptance; ACCEPTED requires explicit reviewer acceptance. CI alone cannot grant either status.

Commands (Python 3 standard library, Windows PowerShell compatible, run at repository root):

```
python scripts/handover.py status
python scripts/handover.py next
python scripts/handover.py prepare P100-M0-001
python scripts/handover.py validate
python scripts/handover.py archive P100-M0-001
python -m unittest discover -s scripts/tests -v
```

`prepare` validates and writes a copy-ready review snapshot to `docs/handover/prepared/`; it never starts another agent or changes lifecycle. `archive` accepts only ACCEPTED records and writes an immutable JSON snapshot in history, retaining the active ledger entry for traceability. Commit implementation first, then reference that SHA in a separate handover commit; do not use HEAD placeholders or attempt self-referential SHAs. Commit refs must be full reachable SHA ancestors of the recorded branch. Missing branch refs/commits fail validation; CI checkout fetches full history. `modified_files` refer to tracked existing files; tests and review evidence are explicit, including unavailable checks.

Validator limits: reviewer identity is a normalized text comparison, not authenticated identity proof. No transition history is inferred; Git history and REVIEW.md preserve the review trail. `next` follows actionable ledger order and does not rank blocked/backlog P0 work; inspect `status` and the security gate explicitly. These limits are not authorization to self-accept. Owner's review-fix instruction keeps M0 **CHANGES_REQUESTED** until Claude re-review and required acceptance evidence; preparing a second-review packet does not change that status.
