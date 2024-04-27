{{ file.Skip "Virtual file to write to package.json from stencil-base" }}

{{- define "publishOrbNodeJSDeps" }}
- name: "@getoutreach/semantic-release-circleci-orb"
  version: "^1.1.10"
{{- end }}

{{- if stencil.Arg "releaseOptions.publishOrb" }}
{{- stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "nodejs_dependencies" (stencil.ApplyTemplate "publishOrbNodeJSDeps" | fromYaml) }}
{{- end }}
