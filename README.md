# stencil-circleci
[![go.dev reference](https://img.shields.io/badge/go.dev-reference-007d9c?logo=go&logoColor=white)](https://engdocs.outreach.cloud/github.com/getoutreach/stencil-circleci)
[![Generated via Bootstrap](https://img.shields.io/badge/Outreach-Bootstrap-%235951ff)](https://github.com/getoutreach/bootstrap)
[![Coverage Status](https://coveralls.io/repos/github/getoutreach/stencil-circleci/badge.svg?branch=main)](https://coveralls.io/github//getoutreach/stencil-circleci?branch=main)
<!-- <<Stencil::Block(extraBadges)>> -->

<!-- <</Stencil::Block>> -->

Stencil Module for CircleCI

## Contributing

Please read the [CONTRIBUTING.md](CONTRIBUTING.md) document for guidelines on developing and contributing changes.

## High-level Overview

<!-- <<Stencil::Block(overview)>> -->

For usage documentation, see the [docs/](docs/) directory.

### Scheduled stencil upgrades

Set `stencilUpgrade.scheduled: true` to add a `stencil-upgrade` workflow that runs the `shared/stencil_upgrade` job on a schedule. This argument controls only the scheduled job; running `stencil` by hand is unaffected. Set the `stencil_upgrade` pipeline parameter to `true` to run the job on demand. The `stencil_upgrade_note` pipeline parameter (a string, empty by default) is passed to the job as `note`. When it is not empty, its Markdown is shown at the top of the pull request description, for example to explain a migration to another vendor.

- `stencilUpgrade.cron`: when the job runs, using cron syntax, in UTC. The default is a time on Thursday between 08:00 and 19:59 UTC, derived from the service name.
- `stencilUpgrade.forcePR`: passed to the job as `force_pr`. Defaults to `false`.

<!-- <</Stencil::Block>> -->
