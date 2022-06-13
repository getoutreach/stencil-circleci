# Please re-run stencil after any changes to this file as invalid
# syntax, such as anchors, will be fixed automatically.
version: 2.1
{{- $isService := stencil.Arg "service" }}
{{- $prereleases := stencil.Arg "releaseOptions.enablePrereleases" }}
{{- $testNodeClient := and (has "grpc" (stencil.Arg "serviceActivities")) (has "node" (stencil.Arg "grpcClients")) }}
orbs:
  shared: getoutreach/shared@1.65.0

# Extra contexts to expose to all jobs below
contexts: &contexts
{{- $userContexts := (file.Block "extraContexts" | fromYaml) }}
{{- $contexts := (stencil.ApplyTemplate "contexts" | fromYaml | uniq) }}
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


jobs: {{ if and (empty (file.Block "circleJobs")) (empty (stencil.GetModuleHook "jobs")) }} {} {{ end }}
  ###Block(circleJobs)
{{ file.Block "circleJobs" }}
  ###EndBlock(circleJobs)

  ### Start jobs inserted by other modules
{{- $jobsHook := (stencil.GetModuleHook "jobs") }}
{{- if $jobsHook }}
{{ toYaml $jobsHook | indent 2 }}
{{- end }}
  ### End jobs inserted by other modules

workflows:
  version: 2
  ###Block(circleWorkflows)
{{ file.Block "circleWorkflows" }}
  ###EndBlock(circleWorkflows)

  ### Start workflows inserted by other modules
{{- $workflowsHook := (stencil.GetModuleHook "workflows") }}
{{- if $workflowsHook }}
{{ toYaml $workflowsHook | indent 2 }}
{{- end }}
  ### End workflows inserted by other modules

  release:
    jobs:
      ###Block(circleWorkflowJobs)
{{ file.Block "circleWorkflowJobs" }}
      ###EndBlock(circleWorkflowJobs)
      {{- if $testNodeClient }}
      - shared/test_node_client:
          requires:
            ###Block(testNodeRequires)
{{ file.Block "testNodeRequires" | fromYaml | toYaml | indent 12 }}
            ###EndBlock(testNodeRequires)
      {{- end }}
      - shared/release: &release
          dryrun: false
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
              only:
                - master
                - main
                {{- if $prereleases }}
                - release
                {{- end }}
      # Dryrun release for PRs
      - shared/release: 
          <<: *release
          dryrun: true
          filters:
            branches:
              ignore:
                - master
                - main
                {{- if $prereleases }}
                - release
                {{- end }}
      - shared/test:
          context: *contexts
          app_name: {{ .Config.Name }}

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
          {{- if $isService }}
            - shared/e2e
          {{- end }}
            - shared/test
{{- if $isService }}
      - shared/e2e:
          context: *contexts
      - shared/docker:
          context: *contexts
          filters:
            branches:
              ignore:
                - master
                - main
                {{- if $prereleases }}
                - release
                {{- end }}
            tags:
              only: /v\d+(\.\d+)*(-.*)*/
{{- end }}
