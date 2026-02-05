APP := stencil-circleci
OSS := false
_ := $(shell ./scripts/devbase.sh)

include .bootstrap/root/Makefile

## <<Stencil::Block(targets)>>
## <</Stencil::Block>>
