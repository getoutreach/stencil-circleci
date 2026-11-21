package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"testing"

	"github.com/getoutreach/gobox/pkg/box"
	"github.com/getoutreach/stencil/pkg/rendertest"
)

var suite *rendertest.Suite

func TestMain(m *testing.M) {
	// The tests render templates of this module only. The dependencies are
	// stand-ins that have just a manifest: stencil-base provides the arguments
	// that this module reads with "from", and the templates read only the
	// version of devbase. Replacing them also keeps the tests off the network.
	//
	// A replaced module has the version "local", so the devbase orb version is
	// always "dev:first". To get another orb version, set the argument
	// versions.devbase.
	suite = rendertest.NewSuite(m, rendertest.WithModuleReplacements(map[string]string{
		"github.com/getoutreach/devbase":      "testdata/modules/devbase",
		"github.com/getoutreach/stencil-base": "testdata/modules/stencil-base",
	}))
	os.Exit(suite.Run())
}

// boxConfig returns a box config with the CircleCI contexts of the Outreach
// box configuration, and an image pull registry that is not on AWS.
func boxConfig() *box.Config {
	c := &box.Config{}
	c.Docker.ImagePullRegistry = "registry.example.com/foo"
	c.CI.CircleCI.Contexts.AWS = "aws-credentials"
	c.CI.CircleCI.Contexts.Github = "ghaccesstoken"
	c.CI.CircleCI.Contexts.Docker = "docker-registry"
	c.CI.CircleCI.Contexts.NPM = "npm-credentials"
	c.CI.CircleCI.Contexts.ExtraContexts = []string{
		"box",
		"vault-dev",
		"confluence",
		"circleci-credentials",
		"tray-webhooks",
		"wizcli",
		"datadog",
	}
	return c
}

// newConfigTemplate returns a builder for the CircleCI config template with the
// given arguments.
func newConfigTemplate(args ...rendertest.ArgOption) *rendertest.TemplateBuilder {
	return suite.NewTemplate(".circleci/config.yml.tpl").
		WithTemplates("_helpers.tpl").
		WithBoxConfig(boxConfig()).
		WithArgs(args...)
}

// render renders the CircleCI config template with the given arguments,
// compares the config with its snapshot, and validates it with the CircleCI CLI.
// The validation is a subtest, so a missing CLI skips only the validation.
func render(t *testing.T, args ...rendertest.ArgOption) {
	t.Helper()

	result := newConfigTemplate(args...).Run(t)
	result.Snapshot(t)
	t.Run("circleci config validate", func(t *testing.T) {
		validateConfig(t, result)
	})
}

// validateConfig checks that the CircleCI CLI accepts the rendered config. The
// config has no jobs or hook values from other modules, because the tests
// render only the templates of this module.
//
// It needs the circleci CLI, and credentials to resolve the shared orb. Without
// the CLI, it fails the test in CI and skips it elsewhere.
func validateConfig(t *testing.T, result *rendertest.Result) {
	t.Helper()

	cli, err := exec.LookPath("circleci")
	if err != nil {
		if os.Getenv("CI") != "" {
			t.Fatalf("the circleci CLI is required in CI: %v", err)
		}
		t.Skipf("the circleci CLI is not installed: %v", err)
	}

	path := filepath.Join(t.TempDir(), "config.yml")
	if err := os.WriteFile(path, result.File(".circleci/config.yml").Contents(), 0o600); err != nil {
		t.Fatal(err)
	}

	out, err := exec.CommandContext(t.Context(), cli, "config", "validate", path).CombinedOutput()
	if err != nil {
		t.Fatalf("circleci config validate failed: %v\n%s", err, out)
	}
}

// prereleaseArgs enables prereleases from the given branch.
func prereleaseArgs(branch string) rendertest.ArgOption {
	return rendertest.Args(
		rendertest.NestedArg("releaseOptions.enablePrereleases", true),
		rendertest.NestedArg("releaseOptions.prereleasesBranch", branch),
	)
}

func TestRenderAFile(t *testing.T) {
	t.Parallel()

	render(t,
		prereleaseArgs("main"),
	)
}

func TestConfigForAutoPrerelease(t *testing.T) {
	t.Parallel()

	render(t,
		prereleaseArgs("main"),
		rendertest.NestedArg("releaseOptions.autoPrereleases", true),
	)
}

func TestConfigForDisabledReleases(t *testing.T) {
	t.Parallel()

	render(t,
		rendertest.NestedArg("releaseOptions.enabled", false),
	)
}

func TestConfigForDisabledPrerelease(t *testing.T) {
	t.Parallel()

	// when enablePrereleases is false, other prerelease options are ignored
	render(t,
		rendertest.NestedArg("releaseOptions.enablePrereleases", false),
	)
}

func TestConfigForDisabledPrereleaseWithAutoPrerelease(t *testing.T) {
	t.Parallel()

	render(t,
		rendertest.NestedArg("releaseOptions.enablePrereleases", false),
		// The autoPrereleases should be ignored.
		rendertest.NestedArg("releaseOptions.autoPrereleases", true),
	)
}

func TestRenderWithSkipE2eAndDocker(t *testing.T) {
	t.Parallel()

	render(t,
		prereleaseArgs("main"),
		// A released version of the shared orb, because the CircleCI CLI
		// validates that the orb version exists.
		rendertest.NestedArg("versions.devbase", "2.39.1"),
		rendertest.NestedArg("ciOptions.skipE2e", true),
		rendertest.NestedArg("ciOptions.skipDocker", true),
	)
}

func TestRenderAsOSSRepo(t *testing.T) {
	t.Parallel()

	render(t,
		rendertest.Arg("oss", true),
	)
}
