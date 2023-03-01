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

## `serviceActivities`

**Type**: `list`
**Default**: `[]`
**Options**: `['grpc', 'http', 'kafka']`

A list of service activities that should be generated. Requires `service` to be set to `true`.

```yaml
serviceActivities:
  - grpc
  - http
  - kafka
```

## `grpcClients`

**Type**: `list`
**Default**: `[]`
**Options**: `['node', 'ruby']`

A list of gRPC clients to run tests for.

```yaml
grpcClients:
  - node
  - ruby
```


## `ciOptions.skipDocker`

Disables the docker ci pipeline

```yaml
ciOptions:
  skipDocker: true
```
