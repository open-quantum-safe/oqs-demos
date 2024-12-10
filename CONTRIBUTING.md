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

Each demo should have it's own GitHub Actions workflow to handle building, testing, and pushing its Docker image. An [example template](.github/workflow-templates/template.yml) is provided to get started.

A workflow should run the build and test steps whenever changes are detected for the integration in a pull request or push to main.
The push step should only be triggered when the workflow is run on the main branch of the upstream repository (not forks) and not when building against the latest liboqs and oqs-provider code.