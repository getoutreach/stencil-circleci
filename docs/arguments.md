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
