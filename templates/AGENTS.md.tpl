{{- file.Skip "Virtual file for AGENTS.md module hooks" }}

{{- define "circleciDirectoryStructure" }}
* `.circleci/`: CircleCI configuration files.
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsDirectoryStructure" (list (stencil.ApplyTemplate "circleciDirectoryStructure")) }}

{{- define "circleciAgentsReferences" }}
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsReferencesTable" (list (stencil.ApplyTemplate "circleciAgentsReferences")) }}

{{- define "circleciBoundariesAlways" }}
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsBoundariesAlways" (list (stencil.ApplyTemplate "circleciBoundariesAlways")) }}

{{- define "circleciBoundariesAsk" }}
- Before modifying CI/CD pipeline configuration (.github/, .circleci/, etc.)
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsBoundariesAsk" (list (stencil.ApplyTemplate "circleciBoundariesAsk")) }}

{{- define "circleciBoundariesNever" }}
{{- end }}

{{ stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "agentsBoundariesNever" (list (stencil.ApplyTemplate "circleciBoundariesNever")) }}
