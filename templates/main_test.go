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
	st.Run(true)
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
	st.Run(true)
}

func TestRenderWithNoSkipE2eAndSkipE2eOnMain(t *testing.T) {
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
			"skipE2eOnMain": true,
			"skipE2eOn":     false,
		},
	})
	st.Run(true)
}
