"""Portable, dependency-free handover ledger commands. Never executes another agent."""
import argparse
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STATES = {"BACKLOG", "READY", "IN_PROGRESS", "READY_FOR_REVIEW",
          "CHANGES_REQUESTED", "VERIFIED", "ACCEPTED", "BLOCKED"}
FIELDS = {"id", "milestone", "owner", "status", "branch", "commit", "requirements",
          "implemented_changes", "modified_files", "test_results", "known_issues",
          "reviewer_findings", "next_actions", "acceptance_criteria", "review",
          "blocker", "unblock_condition"}


def git(root, *args):
    return subprocess.run(["git", "-C", str(root), *args], capture_output=True,
                          text=True, encoding="utf-8")


def load(root):
    data = json.loads((root / "docs/handover/tasks.json").read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise ValueError("tasks.json must contain a list")
    return data


def validate(tasks, root):
    errors, seen = [], set()
    spec = (root / "docs/product/FEATURE_REQUIREMENTS.md").read_text(encoding="utf-8")
    requirements = set(re.findall(r"\| ([A-Z]+-\d+) \|", spec))
    tracked = set(git(root, "ls-files").stdout.splitlines())
    for task in tasks:
        if not isinstance(task, dict):
            errors.append("task must be an object")
            continue
        tid = task.get("id", "<missing>")
        prefix = f"{tid}: "
        missing = FIELDS - task.keys()
        if missing:
            errors.append(prefix + "missing fields " + ", ".join(sorted(missing)))
            continue
        if not isinstance(tid, str) or not re.fullmatch(r"P100-[A-Z0-9]+-\d{3}", tid):
            errors.append(prefix + "invalid task ID")
            continue
        if tid in seen:
            errors.append(prefix + "duplicate ID")
        seen.add(tid)
        if not isinstance(task["status"], str) or task["status"] not in STATES:
            errors.append(prefix + "invalid status")
            continue
        if not re.fullmatch(r"M[0-7]", str(task["milestone"])):
            errors.append(prefix + "invalid milestone")
        for key in ("owner", "branch", "commit"):
            if not isinstance(task[key], str) or not task[key].strip():
                errors.append(prefix + key + " must be nonempty text")
        for key in ("requirements", "implemented_changes", "modified_files", "test_results",
                    "known_issues", "reviewer_findings", "next_actions"):
            if not isinstance(task[key], list) or not task[key] or not all(
                    isinstance(x, str) and x.strip() for x in task[key]):
                errors.append(prefix + key + " must be a nonempty list of text")
        if not isinstance(task["requirements"], list) or any(
                not isinstance(x, str) or x not in requirements for x in task["requirements"]):
            errors.append(prefix + "unknown requirement reference")
        if isinstance(task["modified_files"], list):
            for name in task["modified_files"]:
                if not isinstance(name, str) or name not in tracked or not (root / name).is_file():
                    errors.append(prefix + f"file is missing or untracked: {name}")
        sha, branch = task["commit"], task["branch"]
        valid_sha = isinstance(sha, str) and re.fullmatch(r"[0-9a-f]{40}", sha)
        if not valid_sha or git(root, "cat-file", "-e", f"{sha}^{{commit}}").returncode:
            errors.append(prefix + "commit must be an existing full SHA")
        else:
            # Resolve only a branch ref, never an arbitrary revision expression.
            branch_ref = f"refs/heads/{branch}"
            if git(root, "show-ref", "--verify", "--quiet", branch_ref).returncode:
                branch_ref = f"refs/remotes/origin/{branch}"
            if git(root, "show-ref", "--verify", "--quiet", branch_ref).returncode:
                errors.append(prefix + "branch does not exist")
            elif git(root, "merge-base", "--is-ancestor", sha, branch_ref).returncode:
                errors.append(prefix + "commit is not on branch")
        criteria = task["acceptance_criteria"]
        if not isinstance(criteria, list) or not criteria:
            errors.append(prefix + "acceptance criteria required")
            criteria = []
        for criterion in criteria:
            if (not isinstance(criterion, dict) or not isinstance(criterion.get("description"), str)
                    or not criterion["description"].strip()
                    or type(criterion.get("passed")) is not bool
                    or not isinstance(criterion.get("evidence"), str)
                    or not criterion["evidence"].strip()):
                errors.append(prefix + "invalid criterion (description/passed/evidence required)")
        if task["status"] == "BLOCKED" and not all(
                isinstance(task[k], str) and task[k].strip() for k in ("blocker", "unblock_condition")):
            errors.append(prefix + "BLOCKED needs blocker and unblock condition")
        review = task["review"]
        if not isinstance(review, dict) or not {"reviewer", "commit", "decision", "evidence"} <= review.keys():
            errors.append(prefix + "review fields required")
        elif not all(isinstance(review[k], str) for k in ("reviewer", "commit", "decision", "evidence")):
            errors.append(prefix + "review fields must be text")
        elif task["status"] in {"VERIFIED", "ACCEPTED"}:
            owner = str(task["owner"]).strip().casefold()
            if (not review["reviewer"].strip() or review["reviewer"].strip().casefold() == owner
                    or review["commit"] != sha or not review["evidence"].strip()
                    or review["decision"] not in ({"ACCEPTED"} if task["status"] == "ACCEPTED"
                                                  else {"VERIFIED", "ACCEPTED"})):
                errors.append(prefix + "reviewer evidence for exact commit required; no self-acceptance")
            if not criteria or any(not isinstance(c, dict) or c.get("passed") is not True for c in criteria):
                errors.append(prefix + "all acceptance criteria must pass")
    return errors


def prepare(task, root):
    dest = root / "docs/handover/prepared" / f"{task['id']}.md"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(
        f"# Review {task['id']}\n\nReview branch `{task['branch']}` at `{task['commit']}`.\n"
        "Read AGENTS.md, native-ios instructions, docs/product, docs/architecture and REVIEW.md.\n"
        "Return findings with severity, requirement, file/line and acceptance evidence.\n"
        "Do not infer device acceptance from CI or mark unreviewed work accepted.\n\n"
        + "```json\n" + json.dumps(task, ensure_ascii=False, indent=2) + "\n```\n", encoding="utf-8")
    return dest


def archive(task, root):
    if task["status"] != "ACCEPTED":
        raise ValueError("Only ACCEPTED handovers can be archived")
    dest = root / "docs/handover/history" / f"{task['id']}-{task['commit']}.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    # Exclusive creation prevents replacing past reviewer evidence.
    with dest.open("x", encoding="utf-8") as stream:
        json.dump(task, stream, ensure_ascii=False, indent=2)
        stream.write("\n")
    return dest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["status", "next", "prepare", "validate", "archive"])
    parser.add_argument("task_id", nargs="?")
    args = parser.parse_args()
    try:
        tasks = load(ROOT)
        errors = validate(tasks, ROOT)
        if errors:
            raise ValueError("\n".join(errors))
        if args.command == "validate":
            print(f"PASS: {len(tasks)} handover records; fields, files, requirements, commits and review gates")
        elif args.command == "status":
            for task in tasks:
                print(f"{task['id']} | {task['milestone']} | {task['owner']} | {task['status']} | {task['commit'][:12]}")
        elif args.command == "next":
            candidates = [t for t in tasks if t["status"] in {"CHANGES_REQUESTED", "IN_PROGRESS", "READY", "READY_FOR_REVIEW"}]
            task = candidates[0] if candidates else None
            print(f"{task['id']} ({task['status']}): " + "; ".join(task["next_actions"]) if task else "No actionable task; inspect blockers/review gates")
        else:
            task = next((t for t in tasks if t["id"] == args.task_id), None)
            if task is None:
                raise ValueError("Provide an existing task ID")
            print(prepare(task, ROOT) if args.command == "prepare" else archive(task, ROOT))
        return 0
    except (ValueError, OSError) as error:
        print(f"FAIL: {error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
