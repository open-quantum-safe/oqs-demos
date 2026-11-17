# Contributing new quantum-safe application integrations

All submissions must meet acceptance criteria given below. Demos may be removed if they no longer meet the acceptance criteria.

## Documentation requirements

- Purpose of integration and upstream (code origin) location must be clearly documented.
- README must contain all steps to build the OQS-enabled code.
- An optional USAGE file must be present if the integration can be built into a docker image.

## Execution requirements

- If possible, a Dockerfile should be provided such as to automate the integration completely. In this case, a separate USAGE file must be available that shall document usage of the docker file at [docker hub](https://hub.docker.com/orgs/openquantumsafe/repositories).
- If a docker file is provided, it is expected that build-and-test code is added to the continuous integration environment testing (see below).

## Maintenance

We hope the contributor will intend to help update the integration over time as the upstream code bases as well as the underlying algorithms and APIs evolve.

## Continuous Integration

Each demo should have its own GitHub Actions workflow to handle building, testing, and pushing its Docker image. An [example template](.github/workflow-templates/template.yml) is provided to get started.

A workflow should run the build and test steps whenever changes are detected for the integration in a pull request or push to main.
The push step should only be triggered when the workflow is run on the main branch of the upstream repository (not forks) and not when building against the latest liboqs and oqs-provider code.

### Reporting upstream integration failures

The aggregate `OQS Demos` workflow can report failed integration builds and
tests to upstream repositories. Reporting covers scheduled runs and manual
runs with `build_main: true`, on the `main` branch of
`open-quantum-safe/oqs-demos`.

Before enabling issue creation, ensure the `build_main` fixes from
[PR #404](https://github.com/open-quantum-safe/oqs-demos/pull/404)
are incorporated. Otherwise, a run configured as a canary may still build
pinned releases rather than upstream main branches.

#### Maintainer configuration

Configure the following in the oqs-demos repository's Actions settings:

1. Set the repository variable `UPSTREAM_ISSUE_ROUTES` to a JSON object
   mapping integration job IDs to destination repositories. For example:

   ```json
   {"curl": "open-quantum-safe/oqs-provider"}
   ```

   Supported integration IDs are `curl`, `h2load`, `httpd`, `locust`,
   `nginx`, `openssl3`, `nodejs`, `postgresql`, `wireshark`, and `epiphany`.

   Choose destinations with the receiving maintainers. Routing identifies
   where a notification should go; it does not establish which dependency
   caused the failure.

2. Before adding credentials, manually run `OQS Demos` with
   `build_main: true`. Any reportable failures appear as previews in the
   reporting job's summary.

3. To enable issue creation, set the Actions secret `UPSTREAM_ISSUES_TOKEN`
   to a fine-grained personal access token with **Issues: read and write**
   permission for the configured destination repositories. Its owner must
   have access to those repositories, and organization approval may be
   required.

   The regular `GITHUB_TOKEN` reads this repository's workflow jobs.
   Cross-repository issue creation uses `UPSTREAM_ISSUES_TOKEN`; it does
   not require permission to modify upstream code.

An integration without a configured route produces a preview only.
If the token is missing, all reports remain previews. Invalid routing
configuration or API errors fail the reporting job.

#### Reporting behavior

The reporter examines jobs from the current run attempt and groups failed
architectures into one report per integration. Reports include the
oqs-demos revision, run-attempt link, failed job links, and failed step
names. Dependency revisions must be obtained from the build logs where
available; current upstream branch heads may have moved since the build.

Only failed steps whose names begin with `Build ` or `Test ` are reported,
along with the existing `Run Locust load test` step. Separate login,
scanning, artifact-upload, publishing, and runner-setup failures are
excluded. Network or package-service failures inside a build step can
still produce a report, so notifications are not confirmed upstream
root-cause diagnoses.

Before creating an issue, the reporter checks all open issues in the
destination repository for a stable hidden marker. An existing report
suppresses further issues and comments for that integration. Keep this
marker when editing an automated issue. Closing a report allows a later
failure to create a new one; successful runs do not automatically close
reports. Reporting jobs are serialized to prevent concurrent
check-and-create operations.

Reporting is disabled for forks, pull requests, other branches, release
builds, and cancelled runs. Individually dispatched integration workflows
and the separate QUIC workflow are outside this reporter's scope.

#### Development and testing

Run the offline tests from the repository root:

```sh
python3 -B -m unittest discover -s scripts/tests -v
```

The tests use fake API clients and do not create GitHub issues.
The `Test integration reporter` workflow runs them on relevant changes.

When enabling another integration, update the reporting job's `needs`
list in `.github/workflows/build.yml`, the script's `INTEGRATIONS` set,
and the supported IDs above. Ensure its build and test step names follow
the naming convention used by the reporter.