{{ file.Skip "Virtual file to write to Makefile from stencil-golang" }}

{{- define "publishOrbMakeCommands" }}
ORB_DEV_TAG ?= first

.PHONY: build-orb
pre-build:: build-orb
build-orb:
	circleci orb pack orbs/shared > orb.yml

.PHONY: validate-orb
validate-orb: build-orb
	circleci orb validate orb.yml

.PHONY: publish-orb
publish-orb: validate-orb
	circleci orb publish orb.yml {{ stencil.Arg "releaseOptions.orbName" }}@dev:$(ORB_DEV_TAG)
{{- end }}

{{- if stencil.Arg "releaseOptions.publishOrb" }}
{{- stencil.AddToModuleHook "github.com/getoutreach/stencil-golang" "Makefile.commands" (list (stencil.ApplyTemplate "publishOrbMakeCommands")) }}
{{- end }}
