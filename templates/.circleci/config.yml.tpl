# Please re-run stencil after any changes to this file.
version: 2.1
{{- $isService := eq (stencil.ApplyTemplate "isService") "true" }}
{{- $prereleases := stencil.Arg "releaseOptions.enablePrereleases" }}
orbs:
  shared: getoutreach/shared@1.60.0

# Extra contexts to expose to all jobs below
contexts: &contexts
  {{- /* Ensure we generate a valid structure if no block or module hook entries */}}
  {{ if and (empty (file.Block "extraContexts")) (empty (stencil.GetModuleHook "contexts")) }}[]{{ end }}
  ### Start contexts inserted by other modules
{{- $contextsHook := (stencil.GetModuleHook "contexts") }}
{{- if $contextsHook }}
{{ toYaml $contextsHook | indent 2 }}
{{- end }}
  ### End contexts inserted by other modules
  ###Block(extraContexts)
{{ file.Block "extraContexts"}}
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
        {{- /* TODO(jaredallard): We'll need to migrate this into the go module */}}
        {{- if and (has "grpc" (stencil.Arg "type")) (has "node" (stencil.Arg "grpcClients")) }}
            - shared/test-node-client
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
          {{- if stencil.Arg "resources.postgres" }}
          postgres_version: {{ stencil.Arg "resources.postgres" }}
          {{- end }}
          {{- if stencil.Arg "resources.mysql" }}
          mysql_version: {{ stencil.Arg "resources.mysql" }}
          {{- end }}
          {{- if stencil.Arg "resources.redis" }}
          redis_version: {{ stencil.Arg "resources.redis" }}
          {{- end }}
          {{- if stencil.Arg "resources.kafka" }}
          kafka_version: {{ stencil.Arg "resources.kafka" }}
          {{- end }}
          {{- if stencil.Arg "resources.s3" }}
          minio_version: {{ stencil.Arg "resources.minio" }}
          {{- end }}
          {{- if stencil.Arg "resources.dynamo" }}
          localstack_version: {{ stencil.Arg "resources.dynamo" }}
          localstack_services: dyanmodb
          {{- end }}

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
