# Arguments

Below is a list of all of the arguments that `stencil-circleci` supports. Other options from [`stencil-base`](https://github.com/getoutreach/stencil-base/blob/main/manifest.yaml) are also used here.

## `ciOptions.skipDocker`

Disables the `shared/docker` step in the CircleCI pipeline from running

```yaml
ciOptions:
  skipDocker: true
```

## `ciOptions.skipE2e`

Disables the `shared/e2e` step in the CircleCI pipeline from running

```yaml
ciOptions:
  skipE2e: true
```

## `stencilUpgrade.scheduled`

Adds a `stencil-upgrade` workflow that runs the `shared/stencil_upgrade` job on a schedule. Running `stencil` by hand is not affected. The [devbase docs](https://github.com/getoutreach/devbase/blob/main/docs/stencil-upgrade.md) describe what the job does.

```yaml
stencilUpgrade:
  scheduled: true
```

The `manual-stencil-upgrade` workflow, which runs the same job on demand, always exists, whatever the value of this argument. To start it, set the `stencil_upgrade` pipeline parameter (boolean) to `true` when you trigger a pipeline in the CircleCI web app or with the CircleCI API.

The `stencil_upgrade_note` pipeline parameter (string, empty by default) is passed to the job as `note`. The `stencil_upgrade_force_pr` pipeline parameter (boolean, `false` by default) is passed as `force_pr`. Set them together with `stencil_upgrade`. The devbase docs describe `note` and `force_pr`. The schedule does not set them, so the defaults apply.

## `stencilUpgrade.cron`

The time when the scheduled `stencil-upgrade` workflow runs, in cron syntax and UTC. It applies when `stencilUpgrade.scheduled` is `true`. The default is a time on Thursday between 08:00 and 19:59 UTC, derived from the service name, so repositories do not all run at the same time.

```yaml
stencilUpgrade:
  cron: "0 5 * * 1"
```
