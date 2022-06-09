{{- file.Skip "Virtual file with functions"}}

{{- define "contexts" }}
### Start contexts inserted by other modules
{{- $contextsHook := (stencil.GetModuleHook "contexts") }}
{{- if $contextsHook }}
  {{- range $contextsHook }}
    {{- range . }}
- {{ . }}
    {{- end }}
  {{- end }}
{{- end }}
### End contexts inserted by other modules
### Start contexts from box config
{{- with .Runtime.Box.CI.CircleCI.Contexts }}
  {{- if .AWS }}
# AWS Authentication Context
- {{ .AWS }}
  {{- end }}
  {{- if .Github }}
# Github Authentication Context
- {{ .Github }}
  {{- end }}
  {{- if .Docker }}
# Docker Authentication Context
- {{ .Docker }}
  {{- end }}
  {{- if .NPM }}
# NPM Authentication Context
- {{ .NPM }}
  {{- end }}
  {{- if .ExtraContexts }}
# Extra Contexts from box config
  {{- end }}
  {{- range .ExtraContexts }}
- {{ . }}
  {{- end }}
{{- end }}
### End contexts from box config
{{- end }}
