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
