# Arguments

Below is a list of all of the arguments that `stencil-circleci` supports. Other options from [stencil-base](TODO) are also used here.

## `releaseOptions.enablePrereleases`

**Type:** `boolean`
**Default**: `false`

Enables pre-releasing on this repository. This will configure `main` to be a pre-release branch, and `release` to be a release branch.

```yaml
releaseOptions:
  enablePrereleases: true
```

## `service`

**Type**: `bool`
**Default**: `false`

Indicates that this application is a service and that docker images should be built and pushed to the Docker registry.

```yaml
service: true
```

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
