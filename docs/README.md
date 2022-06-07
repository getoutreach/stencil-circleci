# stencil-circleci

A stencil module for interacting with CircleCI for application development.

## Structure

This module takes an opinionated approach to what types of jobs are ran in CI/CD.
 
### Jobs

* **shared/test**: Runs tests for the project.
* **shared/e2e**: Runs end-to-end tests for all packages in the project.
* **shared/docker**: Builds and pushes Docker images for all packages in the project. Runs on tag creation.
* **shared/release**: Creates tags/releases for the project and pushes them to GitHub.
* **shared/finalize-coverage**: Finalizes the coverage report for the project and submits it (currently coveralls only).

All of the above jobs are codified in the CircleCI orb located in [devbase](https://github.com/getoutreach/devbase/tree/main/orbs/shared). The documentation for each step and how they work is located there.

## Releasing

Releasing is a two-step process. First, the project is tagged and released to GitHub. Then, the project is pushed to the Docker registry.

Releases are automated via semantic-release. The [semantic-release](https://github.com/semantic-release/semantic-release) behaviour is different based on which modules are being used. For example, [stencil-golang](https://github.com/getoutreach/stencil-golang/blob/main/docs/releasing.md). By default there are no release rules configured, so releasing will essentially be a no-op.

Docker images are built by the [`ci/release/docker.sh`](https://github.com/getoutreach/devbase/blob/main/shell/ci/release/docker.sh) script. These images are pushed to the Docker registry configured in your organization's box configuration.

<!-- TODO(jaredallard): Need to document box in the future. Outreach lives at: getoutreach/box -->

## E2E

E2E tests use the runner that lives in [devbase](https://github.com/getoutreach/devbase/tree/main/e2e). The E2E runner only supports go tests currently, however other tests could be shimmed in if needed. An E2E environment is provisioned using a [devenv](https://github.com/getoutreach/devenv). The application is then deployed into the devenv, if applicable, and E2E tests are ran.
