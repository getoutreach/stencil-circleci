# Please re-run stencil after any changes to this file as invalid
# syntax, such as anchors, will be fixed automatically.
version: 2.1
{{- $prereleases := stencil.Arg "releaseOptions.enablePrereleases" }}
{{- $testNodeClient := and (has "grpc" (stencil.Arg "serviceActivities")) (has "node" (stencil.Arg "grpcClients")) }}
orbs:
  shared: getoutreach/shared@{{ stencil.Arg "versions.devbase" | default (stencil.ApplyTemplate "devbase.orb_version") }}

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

# Branches used for releasing code, pre-release or not
release_branches: &release_branches
  {{- if $prereleases }}
  {{- $pb := stencil.Arg "releaseOptions.prereleasesBranch" }}
  # Release branch
  - release
  # Pre-releases branch
  - {{ default .Git.DefaultBranch $pb | squote }}
    {{- /*
      If we have a pre-release branch set, but it's not the
      default branch we need to include the default branch
      */}}
    {{- if and $pb (ne $pb .Git.DefaultBranch) }}
  # Unstable branch, e.g. HEAD development
  - {{ .Git.DefaultBranch | squote }}
    {{- end }}
  {{- else }}
  - {{ .Git.DefaultBranch | squote }}
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

  release:
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

      - shared/publish_docs:
          context: *contexts
          filters:
            branches:
              ignore: /.*/
            tags:
              only: /v[0-9]+(\.[0-9]+)*(-.*)*/
      {{- if not (stencil.Arg "ciOptions.skipE2e") }}
      - shared/e2e:
          context: *contexts
          ## <<Stencil::Block(circleE2EExtra)>>
{{ file.Block "circleE2EExtra" }}
          ## <</Stencil::Block>>
      {{- end }}
      {{- if not (stencil.Arg "ciOptions.skipDocker") }}
      - shared/docker:
          context: *contexts
          filters:
            branches:
              ignore: *release_branches
            tags:
              only: /v\d+(\.\d+)*(-.*)*/
      {{- end }}
