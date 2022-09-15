# HACK(jaredallard): Remove when stencil-base is cleaned up
APP := stencil-circleci
OSS := true

_ := $(shell ./scripts/devbase.sh) 

include .bootstrap/root/Makefile

.PHONY: build-orb
pre-build:: build-orb

.PHONY: build-orb
build-orb:
	circleci orb pack devbase/orbs/shared > orb.yml

.PHONY: validate-orb
validate-orb: build-orb
	circleci orb validate orb.yml

.PHONY: publish-orb
publish-orb: validate-orb
	circleci orb publish orb.yml getoutreach/stencil-circleci@dev:first
