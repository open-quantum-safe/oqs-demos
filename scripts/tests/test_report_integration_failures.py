import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "report-integration-failures.py"
SPEC = importlib.util.spec_from_file_location("reporter", SCRIPT)
reporter = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(reporter)


def job(
    integration="curl",
    arch="x86_64",
    step="Build the Docker image",
    conclusion="failure",
):
    return {
        "name": f"{integration} / build ({arch}, ubuntu-latest)",
        "conclusion": conclusion,
        "html_url": f"https://github.com/example/jobs/{arch}",
        "steps": [{"name": step, "conclusion": conclusion}],
    }


class FakeGitHub:
    """In-memory API replacement: these tests make no network requests."""

    def __init__(self, jobs=(), issues=()):
        self.jobs = list(jobs)
        self.issues = list(issues)
        self.reads = []
        self.writes = []

    def pages(self, path, key=None):
        self.reads.append(path)
        if key == "jobs":
            return iter(self.jobs)
        return iter(
            issue for issue in self.issues
            if issue.get("state", "open") == "open"
        )

    def request(self, path, data):
        self.writes.append((path, data))
        issue = {
            **data,
            "state": "open",
            "html_url": f"https://github.com/example/issues/{len(self.writes)}",
        }
        self.issues.append(issue)
        return issue


class ReporterTests(unittest.TestCase):
    def setUp(self):
        self.env = {
            "GITHUB_REPOSITORY": "open-quantum-safe/oqs-demos",
            "GITHUB_REF": "refs/heads/main",
            "GITHUB_EVENT_NAME": "schedule",
            "GITHUB_RUN_ID": "123",
            "GITHUB_RUN_ATTEMPT": "2",
            "GITHUB_SHA": "abc123",
            "CANARY_BUILD": "true",
            "UPSTREAM_ISSUE_ROUTES": (
                '{"curl":"open-quantum-safe/oqs-provider"}'
            ),
        }

    def test_groups_architectures_and_links_current_attempt(self):
        source = FakeGitHub(jobs=[job(), job(arch="arm64")])
        target = FakeGitHub()

        reporter.report(source, target, self.env, [])

        self.assertEqual(len(target.writes), 1)
        self.assertEqual(
            source.reads,
            [
                "/repos/open-quantum-safe/oqs-demos/actions/runs/"
                "123/attempts/2/jobs"
            ],
        )
        path, payload = target.writes[0]
        self.assertEqual(path, "/repos/open-quantum-safe/oqs-provider/issues")
        for expected in (
            "x86_64",
            "arm64",
            "abc123",
            "/attempts/2",
            "<!-- oqs-demos-canary:curl -->",
            "not a confirmed root-cause diagnosis",
        ):
            self.assertIn(expected, payload["body"])

    def test_repeated_failure_does_not_create_or_comment_again(self):
        source = FakeGitHub(jobs=[job()])
        target = FakeGitHub()

        reporter.report(source, target, self.env, [])
        reporter.report(source, target, self.env, [])

        self.assertEqual(len(target.writes), 1)

    def test_closed_report_allows_new_issue(self):
        source = FakeGitHub(jobs=[job()])
        target = FakeGitHub()

        reporter.report(source, target, self.env, [])
        target.issues[0]["state"] = "closed"
        reporter.report(source, target, self.env, [])

        self.assertEqual(len(target.writes), 2)

    def test_pull_requests_and_unrelated_issues_do_not_suppress_report(self):
        target = FakeGitHub(
            issues=[
                {"body": None},
                {"body": "<!-- oqs-demos-canary:nginx -->"},
                {
                    "body": "<!-- oqs-demos-canary:curl -->",
                    "pull_request": {},
                },
            ]
        )

        reporter.report(FakeGitHub(jobs=[job()]), target, self.env, [])

        self.assertEqual(len(target.writes), 1)

    def test_missing_route_or_token_produces_preview(self):
        cases = [
            (dict(self.env, UPSTREAM_ISSUE_ROUTES="{}"), FakeGitHub()),
            (self.env, None),
        ]
        for env, target in cases:
            with self.subTest(routes=env["UPSTREAM_ISSUE_ROUTES"]):
                summary = []
                reporter.report(
                    FakeGitHub(jobs=[job()]), target, env, summary
                )

                self.assertIn("preview", "\n".join(summary))
                self.assertIn("Build the Docker image", "\n".join(summary))
                if target is not None:
                    self.assertEqual(target.reads, [])
                    self.assertEqual(target.writes, [])

    def test_non_build_failures_and_cancelled_jobs_are_ignored(self):
        jobs = [
            job(step="Login to Docker Hub"),
            job(step="Scan Docker Image"),
            job(step="Upload Scan Results"),
            job(step="Push Docker image to registries"),
            job(step="Set up job"),
            job(step="Post Build the Docker image"),
            job(conclusion="success"),
            job(conclusion="cancelled"),
            job(integration="unknown"),
            dict(job(), name="report-integration-failures"),
        ]
        target = FakeGitHub()
        summary = []

        reporter.report(FakeGitHub(jobs=jobs), target, self.env, summary)

        self.assertEqual(target.reads, [])
        self.assertEqual(target.writes, [])
        self.assertIn("No failed build or test steps", "\n".join(summary))

    def test_test_steps_and_locust_are_recognized(self):
        failures = reporter.collect_failures(
            [
                job(step="Test curl and curl generic"),
                job(integration="locust", step="Run Locust load test"),
            ]
        )

        self.assertEqual(set(failures), {"curl", "locust"})

    def test_untrusted_and_release_runs_are_rejected_before_api_access(self):
        cases = [
            ("GITHUB_REPOSITORY", "someone/oqs-demos"),
            ("GITHUB_REF", "refs/heads/topic"),
            ("GITHUB_EVENT_NAME", "pull_request"),
            ("GITHUB_EVENT_NAME", "push"),
            ("CANARY_BUILD", "false"),
        ]
        for key, value in cases:
            with self.subTest(key=key, value=value):
                source = FakeGitHub(jobs=[job()])
                target = FakeGitHub()
                env = dict(self.env, **{key: value})

                with self.assertRaises(ValueError):
                    reporter.report(source, target, env, [])

                self.assertEqual(source.reads, [])
                self.assertEqual(target.writes, [])

    def test_manual_canary_is_supported(self):
        env = dict(self.env, GITHUB_EVENT_NAME="workflow_dispatch")
        target = FakeGitHub()

        reporter.report(FakeGitHub(jobs=[job()]), target, env, [])

        self.assertEqual(len(target.writes), 1)

    def test_invalid_routes_are_rejected(self):
        for raw in (
            "[]",
            '{"unknown":"owner/repo"}',
            '{"curl":"../bad/path"}',
            '{"curl":["owner/repo"]}',
            "invalid JSON",
        ):
            with self.subTest(raw=raw):
                with self.assertRaises(ValueError):
                    reporter.parse_routes(raw)

    def test_job_pagination(self):
        client = reporter.GitHub("unused")
        paths = []

        def request(path, data=None):
            paths.append(path)
            return {
                "jobs": list(range(100)) if len(paths) == 1 else [100]
            }

        client.request = request

        self.assertEqual(
            list(client.pages("/jobs", "jobs")),
            list(range(101)),
        )
        self.assertEqual(
            paths,
            ["/jobs?per_page=100&page=1", "/jobs?per_page=100&page=2"],
        )

    def test_duplicate_on_second_issue_page_is_found(self):
        target = reporter.GitHub("unused")
        reads = []
        writes = []

        def request(path, data=None):
            if data is not None:
                writes.append((path, data))
                raise AssertionError("Must not create a duplicate issue")

            reads.append(path)
            if path.endswith("page=1"):
                return [{"body": "Unrelated issue"} for _ in range(100)]

            return [{
                "body": "<!-- oqs-demos-canary:curl -->",
                "html_url": "https://github.com/example/issues/101",
            }]

        target.request = request
        summary = []

        reporter.report(
            FakeGitHub(jobs=[job()]), target, self.env, summary
        )

        self.assertEqual(len(reads), 2)
        self.assertIn("?state=open&per_page=100&page=2", reads[1])
        self.assertEqual(writes, [])
        self.assertIn("already tracked", "\n".join(summary))

    def test_issue_lookup_error_does_not_trigger_creation(self):
        target = FakeGitHub()

        def fail(*args, **kwargs):
            raise RuntimeError("API unavailable")

        target.pages = fail

        with self.assertRaisesRegex(RuntimeError, "API unavailable"):
            reporter.report(
                FakeGitHub(jobs=[job()]), target, self.env, []
            )

        self.assertEqual(target.writes, [])


if __name__ == "__main__":
    unittest.main()