# HACK(jaredallard): Remove when stencil-base is cleaned up
APP := stencil-circleci
OSS := true

_ := $(shell ./scripts/devbase.sh) 

.PHONY: build-orb
pre-build:: build-orb

.PHONY: build-orb
build-orb:
	@cd devbase; circleci orb pack orbs/shared > orb.yml

.PHONY: validate-orb
validate-orb: build-orb
	@cd devbase; circleci orb validate orb.yml

.PHONY: publish-orb
publish-orb: validate-orb
	@cd devbase; circleci orb publish orb.yml getoutreach/shared@dev:first


include .bootstrap/root/Makefile
