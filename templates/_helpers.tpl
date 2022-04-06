{{- file.Skip "Virtual file with functions"}}

{{- /* isService returns "true" if a service is a service, or "false" if not */}}
{{- define "isService" }}
  {{- $types := (stencil.Arg "type") }}
  {{- if not (or (has "http" $types) (or (has "grpc" $types) (or (has "kafka" $types) (has "temporal" $types)))) }}
    {{- "false" }}
  {{- else }}
    {{- "true" }}
  {{- end }}
{{- end }}