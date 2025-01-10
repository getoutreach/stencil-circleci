APP := stencil-circleci
OSS := false
_ := $(shell ./scripts/devbase.sh)

include .bootstrap/root/Makefile

## <<Stencil::Block(targets)>>
post-stencil::
	@# Make sure that the shared orb is updated appropriately
	@SKIP_VALIDATE=true make test; exit 0
## <</Stencil::Block>>
