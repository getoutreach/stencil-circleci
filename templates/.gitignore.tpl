{{ file.Skip "Virtual file for .gitignore module hooks" }}

{{- define "orbIgnores"}}
/orb.yml
{{- end }}

{{- if stencil.Arg "releaseOptions.publishOrb" }}
{{- stencil.AddToModuleHook "github.com/getoutreach/stencil-base" "gitIgnore/extraIgnores" (list (stencil.ApplyTemplate "orbIgnores")) }}
{{- end }}
