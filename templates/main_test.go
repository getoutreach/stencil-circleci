package main

import (
	"testing"

	"github.com/getoutreach/stencil/pkg/stenciltest"
)

// Replace this with your own tests.
func TestRenderAFile(t *testing.T) {
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	st.Args(map[string]interface{}{
		"releaseOptions": map[string]interface{}{
			"enablePrereleases": true,
			"prereleasesBranch": "main",
		},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestConfigForAutoPrerelease(t *testing.T) {
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	st.Args(map[string]interface{}{
		"releaseOptions": map[string]interface{}{
			"enablePrereleases": true,
			"prereleasesBranch": "main",
			"autoPrereleases":   true,
		},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestConfigForDisabledPrerelease(t *testing.T) {
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	st.Args(map[string]interface{}{
		"releaseOptions": map[string]interface{}{
			// when enablePrereleases is false, other prerelease options are ignored
			"enablePrereleases": false,
		},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestConfigForDisabledPrereleaseWithAutoPrerelease(t *testing.T) {
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	st.Args(map[string]interface{}{
		"releaseOptions": map[string]interface{}{
			"enablePrereleases": false,
			// The autoPrereleases should be ignored.
			"autoPrereleases": true,
		},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestConfigForLibraryWithNodeJSGRPCClient(t *testing.T) {
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	st.Args(map[string]interface{}{
		"grpcClients": []interface{}{
			"node",
		},
		"service": false,
		"versions": map[string]interface{}{
			"devbase": "my-custom-version",
		},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestRenderWithSkipE2eAndDocker(t *testing.T) {
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	st.Args(map[string]interface{}{
		"releaseOptions": map[string]interface{}{
			"enablePrereleases": true,
			"prereleasesBranch": "main",
		},
		"versions": map[string]interface{}{
			"devbase": "my-custom-version",
		},
		"ciOptions": map[string]interface{}{
			"skipE2e":    true,
			"skipDocker": true,
		},
	})
	st.Run(stenciltest.RegenerateSnapshots())
}
