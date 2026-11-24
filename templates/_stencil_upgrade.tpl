{{- file.Skip "Virtual file with functions" }}

# stencilUpgradeCron returns the default schedule for the stencil-upgrade
# workflow: Thursday at a time between 08:00 and 19:59 UTC. The time is derived
# from the service name (.), so services do not all upgrade at the same time.
{{- define "stencilUpgradeCron" -}}
{{- printf "%d %d * * 4" (mod (atoi (adler32sum .)) 60) (add 8 (mod (atoi (adler32sum (printf "%s-hour" .))) 12)) -}}
{{- end -}}
