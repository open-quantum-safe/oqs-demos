#!/usr/bin/env python3
"""Report upstream-main integration failures using the GitHub REST API."""

import json
import os
import re
import urllib.request
from collections import defaultdict


INTEGRATIONS = {
    "curl",
    "h2load",
    "httpd",
    "locust",
    "nginx",
    "openssl3",
    "nodejs",
    "postgresql",
    "wireshark",
    "epiphany",
}


class GitHub:
    def __init__(self, token):
        self.token = token

    def request(self, path, data=None):
        request = urllib.request.Request(
            "https://api.github.com" + path,
            data=None if data is None else json.dumps(data).encode(),
            headers={
                "Authorization": "Bearer " + self.token,
                "Accept": "application/vnd.github+json",
                "X-GitHub-Api-Version": "2022-11-28",
                "Content-Type": "application/json",
            },
        )

        # Do not retry POSTs: a lost response could create duplicate issues.
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.load(response)

    def pages(self, path, key=None):
        separator = "&" if "?" in path else "?"
        page = 1

        while True:
            data = self.request(
                f"{path}{separator}per_page=100&page={page}"
            )
            items = data[key] if key else data
            yield from items

            if len(items) < 100:
                break

            page += 1


def parse_routes(raw):
    routes = json.loads(raw or "{}")

    if not isinstance(routes, dict):
        raise ValueError("UPSTREAM_ISSUE_ROUTES must be a JSON object")

    for integration, target in routes.items():
        if integration not in INTEGRATIONS:
            raise ValueError(f"Unknown integration: {integration}")

        if not isinstance(target, str) or not re.fullmatch(
            r"[A-Za-z0-9-]+/[A-Za-z0-9_.-]+", target
        ):
            raise ValueError(f"Invalid repository for {integration}")

    return routes


def collect_failures(jobs):
    failures = defaultdict(list)

    for job in jobs:
        # Reusable jobs are named e.g. "curl / build (x86_64, ubuntu-latest)".
        integration, separator, _ = job["name"].partition(" / ")

        if not separator or integration not in INTEGRATIONS:
            continue

        if job.get("conclusion") != "failure":
            continue

        failed_steps = [
            step["name"]
            for step in job.get("steps", [])
            if step.get("conclusion") == "failure"
            and (
                step["name"].startswith(("Build ", "Test "))
                or step["name"] == "Run Locust load test"
            )
        ]

        if failed_steps:
            failures[integration].append((job, failed_steps))

    return failures


def report(source, upstream, env, summary):
    # The workflow also checks these conditions before starting this job.
    if (
        env["GITHUB_REPOSITORY"] != "open-quantum-safe/oqs-demos"
        or env["GITHUB_REF"] != "refs/heads/main"
        or env.get("CANARY_BUILD") != "true"
        or env["GITHUB_EVENT_NAME"]
        not in {"schedule", "workflow_dispatch"}
    ):
        raise ValueError(
            "Reporting is restricted to trusted main-branch canary runs"
        )

    routes = parse_routes(env.get("UPSTREAM_ISSUE_ROUTES", ""))
    repository = env["GITHUB_REPOSITORY"]
    run_id = env["GITHUB_RUN_ID"]
    attempt = env["GITHUB_RUN_ATTEMPT"]

    # Restrict results to this attempt so reruns do not report stale failures.
    jobs = source.pages(
        f"/repos/{repository}/actions/runs/{run_id}"
        f"/attempts/{attempt}/jobs",
        "jobs",
    )
    failures = collect_failures(jobs)

    summary.append("## Upstream integration reports\n")

    if not failures:
        summary.append("No failed build or test steps in this attempt.\n")

    existing_issues = {}

    for integration, entries in sorted(failures.items()):
        marker = f"<!-- oqs-demos-canary:{integration} -->"

        body = "\n".join(
            [
                marker,
                f"The **{integration}** integration failed in an "
                "oqs-demos canary run configured to build liboqs and "
                "oqs-provider from `main`.",
                "",
                "This is an integration failure notification, not a "
                "confirmed root-cause diagnosis. The destination is "
                "configured by oqs-demos maintainers.",
                "",
                f"- Run: https://github.com/{repository}/actions/runs/"
                f"{run_id}/attempts/{attempt}",
                f"- oqs-demos revision: {env['GITHUB_SHA']}",
                "- Failed jobs and steps:",
                *[
                    f"  - [{job['name']}]({job['html_url']}): "
                    f"{', '.join(steps)}"
                    for job, steps in entries
                ],
                "",
                "See the linked job logs for build output and dependency "
                "revisions where available. Upstream branch heads may "
                "have moved since this run.",
            ]
        )

        target = routes.get(integration)

        if not target or upstream is None:
            summary.append(
                f"### {integration}: preview (route or token missing)\n\n"
                f"{body}\n"
            )
            continue

        if target not in existing_issues:
            existing_issues[target] = list(
                upstream.pages(f"/repos/{target}/issues?state=open")
            )

        duplicate = next(
            (
                issue
                for issue in existing_issues[target]
                if "pull_request" not in issue
                and marker in (issue.get("body") or "")
            ),
            None,
        )

        if duplicate:
            summary.append(
                f"- {integration}: already tracked in "
                f"{duplicate['html_url']}\n"
            )
            continue

        issue = upstream.request(
            f"/repos/{target}/issues",
            {
                "title": (
                    f"oqs-demos: {integration} integration fails against main"
                ),
                "body": body,
            },
        )
        existing_issues[target].append(issue)
        summary.append(
            f"- {integration}: created {issue['html_url']}\n"
        )


def main():
    summary = []
    token = os.environ.get("UPSTREAM_ISSUES_TOKEN")

    try:
        report(
            source=GitHub(os.environ["GH_TOKEN"]),
            upstream=GitHub(token) if token else None,
            env=os.environ,
            summary=summary,
        )
    finally:
        with open(
            os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8"
        ) as output:
            output.write("\n".join(summary))


if __name__ == "__main__":
    main()