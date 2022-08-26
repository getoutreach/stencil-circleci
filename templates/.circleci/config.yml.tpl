# Please re-run stencil after any changes to this file as invalid
# syntax, such as anchors, will be fixed automatically.
version: 2.1
{{- $prereleases := stencil.Arg "releaseOptions.enablePrereleases" }}
{{- $testNodeClient := and (has "grpc" (stencil.Arg "serviceActivities")) (has "node" (stencil.Arg "grpcClients")) }}
orbs:
  shared: getoutreach/shared@2.3.0

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
  ###Block(extraContexts)
{{ $userContexts | toYaml | indent 2 }}
  ###EndBlock(extraContexts)

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
  ###Block(circleJobs)
{{ file.Block "circleJobs" }}
  ###EndBlock(circleJobs)

  ### Start jobs inserted by other modules
{{- $jobsHook := (stencil.GetModuleHook "jobs") }}
{{- range $jobsHook }}
{{ toYaml . | indent 2 }}
{{- end }}
  ### End jobs inserted by other modules

workflows:
  version: 2
  ###Block(circleWorkflows)
{{ file.Block "circleWorkflows" }}
  ###EndBlock(circleWorkflows)

  ### Start workflows inserted by other modules
{{- $workflowsHook := (stencil.GetModuleHook "workflows") }}
{{- range $workflowsHook }}
{{ toYaml . | indent 2 }}
{{- end }}
  ### End workflows inserted by other modules

  release:
    jobs:
      ###Block(circleWorkflowJobs)
{{ file.Block "circleWorkflowJobs" }}
      ###EndBlock(circleWorkflowJobs)
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
            ###Block(testNodeClientSteps)
{{ file.Block "testNodeClientSteps" | default "[]" | fromYaml | toYaml | indent 12 }}
            ###EndBlock(testNodeClientSteps)
          requires:
            ###Block(testNodeRequires)
{{ file.Block "testNodeRequires" | default "[]" | fromYaml | toYaml | indent 12 }}
            ###EndBlock(testNodeRequires)
      {{- end }}
      - shared/release: &release
          dryrun: false
          {{- if $testNodeClient }}
          node_client: true
          {{- end }}
          context: *contexts
          ###Block(circleReleaseExtra)
{{ file.Block "circleReleaseExtra" }}
          ###EndBlock(circleReleaseExtra)
          requires:
            ###Block(circleReleaseRequires)
{{ file.Block "circleReleaseRequires" }}
            ###EndBlock(circleReleaseRequires)
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
          ###Block(circleTestExtra)
{{ file.Block "circleTestExtra" }}
          ###EndBlock(circleTestExtra)

      - shared/publish_docs:
          context: *contexts
          filters:
            branches:
              ignore: /.*/
            tags:
              only: /v[0-9]+(\.[0-9]+)*(-.*)*/
      - shared/finalize-coverage:
          context: *contexts
          requires:
            - shared/e2e
            - shared/test
      - shared/e2e:
          context: *contexts
          ###Block(circleE2EExtra)
{{ file.Block "circleE2EExtra" }}
          ###EndBlock(circleE2EExtra)
      - shared/docker:
          context: *contexts
          filters:
            branches:
              ignore: *release_branches
            tags:
              only: /v\d+(\.\d+)*(-.*)*/
