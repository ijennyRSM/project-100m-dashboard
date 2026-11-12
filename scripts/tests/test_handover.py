import copy
import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("handover", Path(__file__).parents[1] / "handover.py")
handover = importlib.util.module_from_spec(spec)
spec.loader.exec_module(handover)


class LedgerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.run_git("init", "-b", "codex/test")
        path = self.root / "docs/product/FEATURE_REQUIREMENTS.md"
        path.parent.mkdir(parents=True)
        path.write_text("| NAV-01 | five tabs |\n", encoding="utf-8")
        self.run_git("add", ".")
        self.run_git("-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-m", "fixture")
        sha = self.run_git("rev-parse", "HEAD").strip()
        self.task = dict(id="P100-M0-001", milestone="M0", owner="Codex", status="READY_FOR_REVIEW",
                         branch="codex/test", commit=sha, requirements=["NAV-01"], implemented_changes=["Fixture"],
                         modified_files=["docs/product/FEATURE_REQUIREMENTS.md"], test_results=["PASS"],
                         known_issues=["Review pending"], reviewer_findings=["Pending"], next_actions=["Claude review"],
                         acceptance_criteria=[dict(description="Review", passed=False, evidence="Pending")],
                         review=dict(reviewer="", commit="", decision="PENDING", evidence=""), blocker="", unblock_condition="")

    def run_git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.root), *args], text=True, stderr=subprocess.DEVNULL)

    def errors(self):
        return handover.validate([self.task], self.root)

    def test_valid_review_pending_record(self):
        self.assertEqual(self.errors(), [])

    def test_duplicate_and_missing_fields(self):
        self.assertTrue(handover.validate([self.task, self.task], self.root))
        del self.task["owner"]
        self.assertTrue(self.errors())

    def test_malformed_record_is_reported_without_crashing(self):
        for key, value in [("id", []), ("status", []), ("review", {"reviewer": [], "commit": "", "decision": "", "evidence": ""})]:
            with self.subTest(key=key):
                original = copy.deepcopy(self.task)
                self.task[key] = value
                self.assertTrue(self.errors())
                self.task = original

    def test_invalid_commit_branch_file_requirement(self):
        for key, value in [("commit", "0" * 40), ("branch", "missing"),
                           ("modified_files", ["../outside"]), ("requirements", ["FAKE-01"])]:
            with self.subTest(key=key):
                original = copy.deepcopy(self.task)
                self.task[key] = value
                self.assertTrue(self.errors())
                self.task = original

    def test_unrelated_commit_rejected(self):
        self.run_git("checkout", "--orphan", "other")
        self.run_git("-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-m", "unrelated")
        self.task["commit"] = self.run_git("rev-parse", "HEAD").strip()
        self.assertTrue(any("not on branch" in e for e in self.errors()))

    def test_blocked_requires_unblock_condition(self):
        self.task["status"] = "BLOCKED"
        self.assertTrue(self.errors())
        self.task.update(blocker="No signing identity", unblock_condition="Signed-device access")
        self.assertEqual(self.errors(), [])

    def test_review_gate_and_stale_review(self):
        self.task["status"] = "ACCEPTED"
        self.assertTrue(self.errors())
        self.task["acceptance_criteria"][0].update(passed=True, evidence="review evidence")
        self.task["review"] = dict(reviewer="Claude", commit=self.task["commit"], decision="ACCEPTED", evidence="Review link")
        self.assertEqual(self.errors(), [])
        self.task["review"]["commit"] = "0" * 40
        self.assertTrue(self.errors())
        self.task["review"].update(commit=self.task["commit"], reviewer="Codex")
        self.assertTrue(self.errors())
        self.task["review"]["reviewer"] = " codex "
        self.assertTrue(self.errors())

    def test_prepare_does_not_mutate_status(self):
        before = copy.deepcopy(self.task)
        path = handover.prepare(self.task, self.root)
        self.assertIn(self.task["commit"], path.read_text(encoding="utf-8"))
        self.assertEqual(self.task, before)

    def test_archive_requires_acceptance_and_is_immutable(self):
        with self.assertRaises(ValueError):
            handover.archive(self.task, self.root)
        self.task["status"] = "ACCEPTED"
        handover.archive(self.task, self.root)
        with self.assertRaises(FileExistsError):
            handover.archive(self.task, self.root)


if __name__ == "__main__":
    unittest.main()
