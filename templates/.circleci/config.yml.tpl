# Please re-run stencil after any changes to this file as invalid
# syntax, such as anchors, will be fixed automatically.
version: 2.1
{{- $prereleases := stencil.Arg "releaseOptions.enablePrereleases" }}
{{- $prereleaseBranch := stencil.Arg "releaseOptions.prereleasesBranch" }}
{{- $testNodeClient := and (or (not (stencil.Arg "service")) (has "grpc" (stencil.Arg "serviceActivities"))) (has "node" (stencil.Arg "grpcClients")) }}
{{- $defaultBranch := .Git.DefaultBranch | default "main" }}
{{- $releaseFailureSlackChannel :=  stencil.Arg "notifications.slackChannel" }}
{{- $executorName := "" }}
{{- if contains "amazonaws.com" .Runtime.Box.Docker.ImagePullRegistry }}
{{- $executorName = "testbed-docker-aws" }}
{{- else }}
{{- $executorName = "testbed-docker" }}
{{- end }}
orbs:
  shared: getoutreach/shared@{{ stencil.Arg "versions.devbase" | default (stencil.ApplyTemplate "devbase.orb_version") }}
  queue: eddiewebb/queue@2.2.1
  {{- $orbsHook := (stencil.GetModuleHook "orbs") }}
  {{- range $orbsHook }}
{{ toYaml . | indent 2 }}
  {{- end }}
  ## <<Stencil::Block(CircleCIExtraOrbs)>>
{{ file.Block "CircleCIExtraOrbs" }}
  ## <</Stencil::Block>>

parameters:
  rebuild_cache:
    type: boolean
    default: false
  {{- if stencil.Arg "releaseOptions.enablePrereleases" }}
  release_rc:
    type: boolean
    default: false
  {{- end }}
  ## <<Stencil::Block(CircleCIExtraParams)>>
{{ file.Block "CircleCIExtraParams" }}
  ## <</Stencil::Block>>


# Extra contexts to expose to all jobs below
contexts: &contexts
{{- $userContexts := (file.Block "extraContexts" | fromYaml) }}
{{- $contexts := (stencil.ApplyTemplate "contexts" | fromYaml | default (list) | uniq) }}
{{- if $contexts }}
  {{- /* If we have user contexts, ensure that we don't duplicate builtin ones */}}
  {{- /* We also have to persist their context in the extra contexts list, so we */}}
  {{- /* process the supplied contexts list */}}
  {{- range $contexts }}
    {{- if not (has . $userContexts) }}
  - {{ . }}
    {{- end }}
  {{- end }}
{{- else }}
  {{- /* Always generate an array if there are no contexts */}}
  []
{{- end }}
  ## <<Stencil::Block(extraContexts)>>
{{ $userContexts | toYaml | indent 2 }}
  ## <</Stencil::Block>>

# Test configs to pass to test and cache jobs
test: &test
  context: *contexts
  app_name: {{ .Config.Name }}
  {{- if not (stencil.Arg "oss") }}
  executor_name: {{ $executorName }}
  {{- end }}
  ### Start parameters inserted by other modules
  {{- /* [][]interface{} */}}
  {{- $testParametersHook := (stencil.GetModuleHook "workflows.release.jobs.test.parameters") }}
  {{- range $testParametersHook }}
  {{ toYaml . }}
  {{- end }}
  ### End parameters inserted by other modules
  ## <<Stencil::Block(circleTestExtra)>>
{{ file.Block "circleTestExtra" }}
  ## <</Stencil::Block>>


# Branches used for releasing code, pre-release or not
release_branches: &release_branches
  {{- $stableBranch := $defaultBranch }}
  {{- if $prereleases }}
  {{- $pb := stencil.Arg "releaseOptions.prereleasesBranch" }}
  {{- $stableBranch = "release" }}
  # Release branch
  - {{ $stableBranch | quote }}
  # Pre-releases branch
  - {{ default $defaultBranch $pb | quote }}
    {{- /*
      If we have a pre-release branch set, but it's not the
      default branch we need to include the default branch
      */}}
    {{- if and $pb (ne $pb $defaultBranch) }}
  # Unstable branch, e.g. HEAD development
  - {{ $defaultBranch | quote }}
    {{- end }}
  {{- else }}
  - {{ $defaultBranch | quote }}
  {{- end }}

## <<Stencil::Block(circleAnchorExtra)>>
{{ file.Block "circleAnchorExtra" }}
## <</Stencil::Block>>

jobs: {{ if and (empty (file.Block "circleJobs")) (empty (stencil.GetModuleHook "jobs")) }} {} {{ end }}
  ## <<Stencil::Block(circleJobs)>>
{{ file.Block "circleJobs" }}
  ## <</Stencil::Block>>

  ### Start jobs inserted by other modules
{{- $jobsHook := (stencil.GetModuleHook "jobs") }}
{{- range $jobsHook }}
{{ toYaml . | indent 2 }}
{{- end }}
  ### End jobs inserted by other modules

workflows:
  ## <<Stencil::Block(circleWorkflows)>>
{{ file.Block "circleWorkflows" }}
  ## <</Stencil::Block>>

  ### Start workflows inserted by other modules
{{- $workflowsHook := (stencil.GetModuleHook "workflows") }}
{{- range $workflowsHook }}
{{ toYaml . | indent 2 }}
{{- end }}
  ### End workflows inserted by other modules

  rebuild-cache:
    triggers:
      - schedule:
          # Every day at 00:00 UTC.
          cron: "0 0 * * *"
          filters:
            branches:
              only:
                - {{ $defaultBranch }}
    jobs:
      - shared/save_cache: *test

  manual-rebuild-cache:
    when: << pipeline.parameters.rebuild_cache >>
    jobs:
      - shared/save_cache: *test
  {{- if and (stencil.Arg "releaseOptions.enablePrereleases") (stencil.Arg "releaseOptions.autoPrereleases") }}

  auto-release-rc:
    triggers:
      - schedule:
        {{- $cronTime := "0 19 * * 2"}}
        {{- if not ( empty (stencil.Arg "releaseOptions.prereleasesCron" )) }}
        {{- $cronTime = stencil.Arg "releaseOptions.prereleasesCron" }}
        {{- end }}
          cron: {{ $cronTime }}
          filters:
            branches:
              only:
                - {{ $prereleaseBranch }}
    jobs:
      - shared/trigger_rc_release:
          context: *contexts
          {{- if $releaseFailureSlackChannel }}
          release_failure_slack_channel: "{{ $releaseFailureSlackChannel }}"
          {{- end }}
          ## <<Stencil::Block(circleAutoTriggerRCExtra)>>
{{ file.Block "circleAutoTriggerRCExtra" }}
          ## <</Stencil::Block>>
  {{- end }}

  {{- if stencil.Arg "releaseOptions.enablePrereleases" }}

  manual-release-rc:
    when: << pipeline.parameters.release_rc>>
    jobs:
      - shared/trigger_rc_release:
          context: *contexts
          {{- if $releaseFailureSlackChannel }}
          release_failure_slack_channel: "{{ $releaseFailureSlackChannel }}"
          {{- end }}
          ## <<Stencil::Block(circleManualTriggerRCExtra)>>
{{ file.Block "circleManualTriggerRCExtra" }}
          ## <</Stencil::Block>>
  {{- end }}

  release:
    when:
      and:
        - not: << pipeline.parameters.rebuild_cache >>
        {{- if stencil.Arg "releaseOptions.enablePrereleases" }}
        - not: << pipeline.parameters.release_rc >>
        {{- end }}
    jobs:
      ## <<Stencil::Block(circleWorkflowJobs)>>
{{ file.Block "circleWorkflowJobs" }}
      ## <</Stencil::Block>>
      ### Start jobs inserted by other modules
      {{- /* [][]interface{} */}}
      {{- $releaseJobs := (stencil.GetModuleHook "workflows.release.jobs") }}
      {{- range $releaseJobs }}
{{ toYaml (list .) | indent 6 }}
      {{- end }}
      ### End jobs inserted by other modules
      {{- if $testNodeClient }}
      - shared/test_node_client:
          context: *contexts
          {{- if not (stencil.Arg "oss") }}
          executor_name: {{ $executorName }}
          {{- end }}
          steps:
            ## <<Stencil::Block(testNodeClientSteps)>>
{{ file.Block "testNodeClientSteps" | default "[]" | fromYaml | toYaml | indent 12 }}
            ## <</Stencil::Block>>
          requires:
            ## <<Stencil::Block(testNodeRequires)>>
{{ file.Block "testNodeRequires" | default "[]" | fromYaml | toYaml | indent 12 }}
            ## <</Stencil::Block>>
      {{- end }}
      - shared/release: &release
          dryrun: false
          {{- if $testNodeClient }}
          node_client: true
          {{- end }}
          context: *contexts
          {{- if $releaseFailureSlackChannel }}
          release_failure_slack_channel: "{{ $releaseFailureSlackChannel }}"
          {{- end }}
          ## <<Stencil::Block(circleReleaseExtra)>>
{{ file.Block "circleReleaseExtra" }}
          ## <</Stencil::Block>>
          requires:
            ## <<Stencil::Block(circleReleaseRequires)>>
{{ file.Block "circleReleaseRequires" }}
            ## <</Stencil::Block>>
            - shared/test
        {{- if $testNodeClient }}
            - shared/test_node_client
        {{- end }}
          filters:
            branches:
              only: {{ $stableBranch }}

      {{- if stencil.Arg "releaseOptions.enablePrereleases" }}
      - shared/pre-release: &pre-release
          dryrun: false
          context: *contexts
          {{- if $releaseFailureSlackChannel }}
          release_failure_slack_channel: "{{ $releaseFailureSlackChannel }}"
          {{- end }}
          ## <<Stencil::Block(circlePreReleaseExtra)>>
{{ file.Block "circlePreReleaseExtra" }}
          ## <</Stencil::Block>>
          requires:
            ## <<Stencil::Block(circlePreReleaseRequires)>>
{{ file.Block "circlePreReleaseRequires" }}
            ## <</Stencil::Block>>
            - shared/test
          filters:
            branches:
              only:
                - {{ $prereleaseBranch }}
      {{- end }}
      # Dryrun for PRs
      - shared/pre-release: &pre-release
          dryrun: true
          context: *contexts
          {{- if stencil.Arg "oss" }}
          executor_name: oss-docker
          docker_image: ghcr.io/getoutreach/bootstrap/ci-oss
          {{- end }}
          ## <<Stencil::Block(circlePreReleaseDryRunExtra)>>
{{ file.Block "circlePreReleaseDryRunExtra" }}
          ## <</Stencil::Block>>
          requires:
            ## <<Stencil::Block(circlePreReleaseDryRunRequires)>>
{{ file.Block "circlePreReleaseDryRunRequires" }}
            ## <</Stencil::Block>>
            - shared/test
          filters:
            branches:
              ignore: *release_branches
      - shared/test:
          <<: *test
          {{- if stencil.Arg "oss" }}
          executor_name: oss-docker
          docker_image: ghcr.io/getoutreach/bootstrap/ci-oss
          {{- end }}
          ## <<Stencil::Block(circleSharedTestExtra)>>
{{ file.Block "circleSharedTestExtra" }}
          ## <</Stencil::Block>>
      - shared/publish_docs:
          context: *contexts
          {{- if not (stencil.Arg "oss") }}
          executor_name: {{ $executorName }}
          {{- end }}
          filters:
            branches:
              only:
                - {{ $defaultBranch }}
            tags:
              only: /v\d+(\.\d+)*(-.*)*/
      {{- if not (stencil.Arg "ciOptions.skipE2e") }}
      - shared/e2e:
          context: *contexts
          ## <<Stencil::Block(circleE2EExtra)>>
{{ file.Block "circleE2EExtra" }}
          ## <</Stencil::Block>>
      {{- end }}
      {{- if not (stencil.Arg "ciOptions.skipDocker") }}
      - shared/docker_stitch:
          context: *contexts
          requires:
            - shared/docker_amd64
            - shared/docker_arm64
          filters:
            branches:
              ignore: *release_branches
            tags:
              only: /v\d+(\.\d+)*(-.*)*/
      - shared/docker_amd64:
          context: *contexts
          filters:
            branches:
              ignore: *release_branches
            tags:
              only: /v\d+(\.\d+)*(-.*)*/
      - shared/docker_arm64:
          context: *contexts
          filters:
            branches:
              ignore: *release_branches
            tags:
              only: /v\d+(\.\d+)*(-.*)*/
      {{- end }}
