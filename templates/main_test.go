package main

import (
	"os"
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

// render renders the CircleCI config template with the given arguments, and
// compares the config with its snapshot.
func render(t *testing.T, args ...rendertest.ArgOption) {
	t.Helper()

	newConfigTemplate(args...).Run(t).Snapshot(t)
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
		rendertest.NestedArg("versions.devbase", "my-custom-version"),
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
