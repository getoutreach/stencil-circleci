# Please re-run stencil after any changes to this file as invalid
# syntax, such as anchors, will be fixed automatically.
version: 2.1
{{- $prereleases := stencil.Arg "releaseOptions.enablePrereleases" }}
{{- $testNodeClient := and (has "grpc" (stencil.Arg "serviceActivities")) (has "node" (stencil.Arg "grpcClients")) }}
{{- $defaultBranch := .Git.DefaultBranch | default "main" }}
orbs:
  shared: getoutreach/shared@{{ stencil.Arg "versions.devbase" | default (stencil.ApplyTemplate "devbase.orb_version") }}
  queue: eddiewebb/queue@2.2.1

parameters:
  rebuild_cache:
    type: boolean
    default: false

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
  {{- if $prereleases }}
  {{- $pb := stencil.Arg "releaseOptions.prereleasesBranch" }}
  # Release branch
  - release
  # Pre-releases branch
  - {{ default $defaultBranch $pb | squote }}
    {{- /*
      If we have a pre-release branch set, but it's not the
      default branch we need to include the default branch
      */}}
    {{- if and $pb (ne $pb $defaultBranch) }}
  # Unstable branch, e.g. HEAD development
  - {{ $defaultBranch | squote }}
    {{- end }}
  {{- else }}
  - {{ $defaultBranch | squote }}
  {{- end }}

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
  version: 2
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

  release:
    when:
      not: << pipeline.parameters.rebuild_cache >>
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
          {{- $releaseFailureSlackChannel :=  stencil.Arg "notifications.slackChannel" }}
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
              only: *release_branches

      # Dryrun release for PRs.
      - shared/release:
          <<: *release
          dryrun: true
          filters:
            branches:
              ignore: *release_branches
      - shared/test:
          <<: *test
          ## <<Stencil::Block(circleSharedTestExtra)>>
{{ file.Block "circleSharedTestExtra" }}
          ## <</Stencil::Block>>
      - shared/publish_docs:
          context: *contexts
          filters:
            branches:
              only:
                - {{ $defaultBranch }}
            tags:
              only: /v\d+(\.\d+)*(-.*)*/
      {{- if not (stencil.Arg "ciOptions.skipE2e") }}
      - shared/e2e:
          context: *contexts
          {{- if stencil.Arg "ciOptions.skipE2eOnMain" }}
          filters:
            branches:
              ignore: *release_branches
          {{- end }}
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
