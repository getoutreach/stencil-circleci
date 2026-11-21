package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"testing"

	"github.com/getoutreach/stencil/pkg/rendertest"
)

// TestRenderedConfigIsValid checks that the CircleCI CLI accepts the rendered
// config. It renders with the arguments that the integration job used to set.
// The config has no jobs or hook values from other modules, because the tests
// render only the templates of this module.
//
// The test needs the circleci CLI, and credentials to resolve the shared orb.
// Without the CLI, the test fails in CI and is skipped elsewhere.
func TestRenderedConfigIsValid(t *testing.T) {
	t.Parallel()

	cli, err := exec.LookPath("circleci")
	if err != nil {
		if os.Getenv("CI") != "" {
			t.Fatalf("the circleci CLI is required in CI: %v", err)
		}
		t.Skipf("the circleci CLI is not installed: %v", err)
	}

	result := newConfigTemplate(
		prereleaseArgs("rc"),
		// Validate against a released version of the shared orb, because the
		// default "dev:first" changes over time.
		rendertest.NestedArg("versions.devbase", "2.39.1"),
	).Run(t)
	if result.Error() != nil {
		t.Fatalf("failed to render the config: %v", result.Error())
	}
	config := result.File(".circleci/config.yml")
	if config == nil {
		t.Fatal("the config was not rendered")
	}

	path := filepath.Join(t.TempDir(), "config.yml")
	if err := os.WriteFile(path, config.Contents(), 0o600); err != nil {
		t.Fatal(err)
	}

	out, err := exec.CommandContext(t.Context(), cli, "config", "validate", path).CombinedOutput()
	if err != nil {
		t.Fatalf("circleci config validate failed: %v\n%s", err, out)
	}
}
