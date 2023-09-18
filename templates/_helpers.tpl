{{- file.Skip "Virtual file with functions"}}

# devbase.orb_version returns the version to use for devbase orb
{{- define "devbase.orb_version" }}
{{- $version := (.Runtime.Modules.ByName "github.com/getoutreach/devbase").Version }}
{{- /* If we're on 'main' (the default branch) or use local version of devbase, use the latest orb:  dev:first */}}
{{- if or (eq $version "main") (eq $version "local")}}
{{- "dev:first" }}
{{- /* If we don't have a v, assume it's a branch and default to dev:<branch> */}}
{{- else if not (hasPrefix "v" $version) }}
{{- printf "dev:%s" $version }}
{{- /* If we have a v and -rc. assume it's a rc version, use special tag */}}
{{- /* Example: dev:2.6.1-rc.2 */}}
{{- else if and (hasPrefix "v" $version) (contains "-rc." $version ) }}
{{- printf "dev:%s" (trimPrefix "v" $version) }}
{{- /* Otherwise this is probably a semantic-version, so just assume that */}}
{{- else }}
{{- trimPrefix "v" $version }}
{{- end }}
{{- end }}

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
