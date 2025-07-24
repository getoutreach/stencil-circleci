package main

import (
	"os"
	"testing"

	"github.com/getoutreach/stencil/pkg/configuration"
	"github.com/getoutreach/stencil/pkg/stenciltest"
)

// fakeDockerPullRegistry sets the BOX_DOCKER_PULL_IMAGE_REGISTRY environment
// variable to a fake value for the duration of the test.
func fakeDockerPullRegistry(t *testing.T) {
	t.Helper()
	oldRegistryValue := os.Getenv("BOX_DOCKER_PULL_IMAGE_REGISTRY")
	os.Setenv("BOX_DOCKER_PULL_IMAGE_REGISTRY", "registry.example.com/foo")
	t.Cleanup(func() {
		os.Setenv("BOX_DOCKER_PULL_IMAGE_REGISTRY", oldRegistryValue)
	})
}

// fakeECRPullRegistry sets the BOX_DOCKER_PULL_IMAGE_REGISTRY environment
// variable to a fake ECR value for the duration of the test.
func fakeECRPullRegistry(t *testing.T) {
	t.Helper()
	oldRegistryValue := os.Getenv("BOX_DOCKER_PULL_IMAGE_REGISTRY")
	os.Setenv("BOX_DOCKER_PULL_IMAGE_REGISTRY", "registry.example.amazonaws.com/foo")
	t.Cleanup(func() {
		os.Setenv("BOX_DOCKER_PULL_IMAGE_REGISTRY", oldRegistryValue)
	})
}

func TestRenderAFile(t *testing.T) {
	fakeDockerPullRegistry(t)
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	st.Args(map[string]any{
		"releaseOptions": map[string]any{
			"enablePrereleases": true,
			"prereleasesBranch": "main",
		},
	})
	// We don't actually need any templates from devbase, so using a
	// fake version works here.
	st.AddModule(&configuration.TemplateRepository{
		Name:    "github.com/getoutreach/devbase",
		Version: "v9.99.0",
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestConfigForAutoPrerelease(t *testing.T) {
	fakeDockerPullRegistry(t)
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	st.Args(map[string]any{
		"releaseOptions": map[string]any{
			"enablePrereleases": true,
			"prereleasesBranch": "main",
			"autoPrereleases":   true,
		},
	})
	// We don't actually need any templates from devbase, so using a
	// fake version works here.
	st.AddModule(&configuration.TemplateRepository{
		Name:    "github.com/getoutreach/devbase",
		Version: "v9.99.0",
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestConfigForDisabledPrerelease(t *testing.T) {
	fakeDockerPullRegistry(t)
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	st.Args(map[string]any{
		"releaseOptions": map[string]any{
			// when enablePrereleases is false, other prerelease options are ignored
			"enablePrereleases": false,
		},
	})
	// We don't actually need any templates from devbase, so using a
	// fake version works here.
	st.AddModule(&configuration.TemplateRepository{
		Name:    "github.com/getoutreach/devbase",
		Version: "v9.99.0",
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestConfigForDisabledPrereleaseWithAutoPrerelease(t *testing.T) {
	fakeDockerPullRegistry(t)
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	st.Args(map[string]any{
		"releaseOptions": map[string]any{
			"enablePrereleases": false,
			// The autoPrereleases should be ignored.
			"autoPrereleases": true,
		},
	})
	// We don't actually need any templates from devbase, so using a
	// fake version works here.
	st.AddModule(&configuration.TemplateRepository{
		Name:    "github.com/getoutreach/devbase",
		Version: "v9.99.0",
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestConfigForLibraryWithNodeJSGRPCClient(t *testing.T) {
	fakeDockerPullRegistry(t)
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	st.Args(map[string]any{
		"grpcClients": []any{
			"node",
		},
		"service": false,
		"versions": map[string]any{
			"devbase": "my-custom-version",
		},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestConfigForLibraryWithNodeJSGRPCClientAndECR(t *testing.T) {
	fakeECRPullRegistry(t)
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	st.Args(map[string]any{
		"grpcClients": []any{
			"node",
		},
		"service": false,
		"versions": map[string]any{
			"devbase": "my-custom-version",
		},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestRenderWithSkipE2eAndDocker(t *testing.T) {
	fakeDockerPullRegistry(t)
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	st.Args(map[string]any{
		"releaseOptions": map[string]any{
			"enablePrereleases": true,
			"prereleasesBranch": "main",
		},
		"versions": map[string]any{
			"devbase": "my-custom-version",
		},
		"ciOptions": map[string]any{
			"skipE2e":    true,
			"skipDocker": true,
		},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestRenderAsOSSRepo(t *testing.T) {
	fakeDockerPullRegistry(t)
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	st.Args(map[string]any{
		"oss": true,
	})
	// We don't actually need any templates from devbase, so using a
	// fake version works here.
	st.AddModule(&configuration.TemplateRepository{
		Name:    "github.com/getoutreach/devbase",
		Version: "v9.99.0",
	})
	st.Run(stenciltest.RegenerateSnapshots())
}
