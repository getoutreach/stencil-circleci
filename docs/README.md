# stencil-circleci

A stencil module for interacting with CircleCI for application development.

## Structure

This module takes an opinionated approach to what types of jobs are ran in CI/CD.

### Jobs

- **shared/test**: Runs tests for the project.
- **shared/e2e**: Runs end-to-end tests for all packages in the project.
- **shared/docker**: Builds and pushes Docker images for all packages in the project. Runs on tag creation.
- **shared/release**: Creates tags/releases for the project and pushes them to GitHub.
- **shared/finalize-coverage**: Finalizes the coverage report for the project and submits it (currently coveralls only).

All of the above jobs are codified in the CircleCI orb located in [devbase](https://github.com/getoutreach/devbase/tree/main/orbs/shared). The documentation for each step and how they work is located there.

## Module hooks

Other stencil modules extend `.circleci/config.yml` by writing to these module hooks with `stencil.AddToModuleHook "github.com/getoutreach/stencil-circleci" "<hook>" (list ...)`. Each list item is one entry.

| Hook | Entry | Rendered as |
| --- | --- | --- |
| `orbs` | map of orb name to orb | extra entries under `orbs:` |
| `contexts` | list of context names | extra contexts on every job |
| `pipeline.parameters` | map of pipeline parameter name to CircleCI parameter definition, with a `type` of `boolean`, `string`, `integer` or `enum` and a `default` | extra entries under the top-level `parameters:`, sorted by name. A name declared twice, one of the built-in `rebuild_cache` / `release_rc`, or a definition without a valid `type` or a `default` fails the render |
| `jobs` | map of job name to job | extra entries under `jobs:` |
| `workflows` | map of workflow name to workflow | extra workflows |
| `workflows.release.jobs` | workflow job entry | extra jobs in the `release` workflow |
| `workflows.release.jobs.test.parameters` | map of job parameters | extra parameters on the `*test` anchor |
| `workflows.release.release.params` | YAML string | extra parameters on the `shared/release` job |
| `workflows.release.release.requires` | job name | extra `requires` on the `shared/release` job |
| `workflows.release.when.not` | condition string, e.g. `<< pipeline.parameters.my_param >>` | an extra `- not: <condition>` in the `release` workflow's `when.and` (duplicates are dropped), so `release` is skipped when the condition is true |

CircleCI rejects API-triggered pipelines that pass undeclared parameters, and a config that references an undeclared parameter is invalid for every pipeline. A module that uses a pipeline parameter must declare it through `pipeline.parameters`, and must require a stencil-circleci version that supports `pipeline.parameters` and `workflows.release.when.not`.

For example, a module that adds a workflow that only runs when a pipeline is triggered with `my_check=true`, and keeps `release` from running in that pipeline:

```gotemplate
{{- $circleci := "github.com/getoutreach/stencil-circleci" }}
{{- stencil.AddToModuleHook $circleci "pipeline.parameters" (list (dict
      "my_check" (dict "type" "boolean" "default" false))) }}
{{- stencil.AddToModuleHook $circleci "workflows" (list (dict
      "my-check-on-demand" (dict
        "when" "<< pipeline.parameters.my_check >>"
        "jobs" (list "my_check_job")))) }}
{{- stencil.AddToModuleHook $circleci "workflows.release.when.not"
      (list "<< pipeline.parameters.my_check >>") }}
```

## Releasing

Releasing is a two-step process. First, the project is tagged and released to GitHub. Then, the project is pushed to the Docker registry.

Releases are automated via semantic-release. The [semantic-release](https://github.com/semantic-release/semantic-release) behaviour is different based on which modules are being used. For example, [stencil-golang](https://github.com/getoutreach/stencil-golang/blob/main/docs/releasing.md). By default there are no release rules configured, so releasing will essentially be a no-op.

Docker images are built by the [`ci/release/docker.sh`](https://github.com/getoutreach/devbase/blob/main/shell/ci/release/docker.sh) script. These images are pushed to the Docker registry configured in your organization's box configuration.

<!-- TODO(jaredallard): Need to document box in the future. Outreach lives at: getoutreach/box -->

## E2E

E2E tests use the runner that lives in [devbase](https://github.com/getoutreach/devbase/tree/main/e2e). The E2E runner only supports go tests currently, however other tests could be shimmed in if needed. An E2E environment is provisioned using a [devenv](https://github.com/getoutreach/devenv). The application is then deployed into the devenv, if applicable, and E2E tests are ran.
