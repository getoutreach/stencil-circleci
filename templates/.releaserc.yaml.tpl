{{ file.Skip "Virtual file to write to .releaserc.yaml from stencil-base" }}

{{- define "publishOrbReleaseRC" }}
- - "@semantic-release/exec"
  - prepareCmd: make build-orb
- - "@getoutreach/semantic-release-circleci-orb"
  - orbName: "{{ stencil.Arg "releaseOptions.orbName" }}"
    orbPath: "orb.yml"
{{- end }}

{{- if stencil.Arg "releaseOptions.publishOrb" }}
{{- if not (stencil.Arg "releaseOptions.orbName") }}
{{- fail "releaseOptions.orbName is required when releaseOptions.publishOrb is true" }}
{{- end }}
{{- stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "releaseConfig" (stencil.ApplyTemplate "publishOrbReleaseRC" | fromYaml) }}
{{- end }}
