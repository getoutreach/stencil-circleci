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
			"prereleasesBranch": "rc",
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
	})
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestRenderWithSkipE2eAndDocker(t *testing.T) {
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	st.Args(map[string]interface{}{
		"releaseOptions": map[string]interface{}{
			"enablePrereleases": true,
			"prereleasesBranch": "rc",
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
