{{ file.Skip "Virtual file to write to mise.toml from stencil-base" }}

{{- define "miseOrbEnvironment" }}
- CIRCLECI_ORB_NAME: {{ (stencil.Arg "releaseOptions.orbName") | quote }}
- CIRCLECI_ORB_PATH: {{ (stencil.Arg "releaseOptions.orbPath") | quote }}
{{- end }}

{{- define "miseOrbTools" }}
- circleci: latest
{{- end }}

{{- if stencil.Arg "releaseOptions.publishOrb" }}
{{- if not (stencil.Arg "releaseOptions.orbName") }}
{{- fail "releaseOptions.orbName is required when releaseOptions.publishOrb is true" }}
{{- end }}
{{- if not (stencil.Arg "releaseOptions.orbPath") }}
{{- fail "releaseOptions.orbPath is required when releaseOptions.publishOrb is true" }}
{{- end }}

{{- stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "miseEnvironment" ((stencil.ApplyTemplate "miseOrbEnvironment") | fromYaml) }}
{{- stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "miseTools" ((stencil.ApplyTemplate "miseOrbTools") | fromYaml) }}
{{- end }}
