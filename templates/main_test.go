package main

import (
	"maps"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/getoutreach/stencil/pkg/configuration"
	"github.com/getoutreach/stencil/pkg/stenciltest"
	"gotest.tools/v3/assert"
)

// fakeDockerPullRegistry sets the BOX_DOCKER_PULL_IMAGE_REGISTRY environment
// variable to a fake value for the duration of the test.
func fakeDockerPullRegistry(t *testing.T) {
	t.Helper()
	t.Setenv("BOX_DOCKER_PULL_IMAGE_REGISTRY", "registry.example.com/foo")
}

// fakeECRPullRegistry sets the BOX_DOCKER_PULL_IMAGE_REGISTRY environment
// variable to a fake ECR value for the duration of the test.
func fakeECRPullRegistry(t *testing.T) {
	t.Helper()
	t.Setenv("BOX_DOCKER_PULL_IMAGE_REGISTRY", "registry.example.amazonaws.com/foo")
}

// setTestArgs is a helper function to set arguments for the stencil test.
// In particular, it provides default values for "required" arguments from
// dependent modules.
func setTestArgs(st *stenciltest.Template, args map[string]any) {
	stArgs := map[string]any{
		"description":   "Service description",
		"reportingTeam": "foo-bar",
	}
	maps.Copy(stArgs, args)
	st.Args(stArgs)
}

func TestRenderAFile(t *testing.T) {
	fakeDockerPullRegistry(t)
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	setTestArgs(st, map[string]any{
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
	setTestArgs(st, map[string]any{
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

func TestConfigForDisabledReleases(t *testing.T) {
	fakeDockerPullRegistry(t)
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	setTestArgs(st, map[string]any{
		"releaseOptions": map[string]any{
			"enabled": false,
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
	setTestArgs(st, map[string]any{
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
	setTestArgs(st, map[string]any{
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

func TestRenderWithSkipE2eAndDocker(t *testing.T) {
	fakeDockerPullRegistry(t)
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl")
	setTestArgs(st, map[string]any{
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
	setTestArgs(st, map[string]any{
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

// newStencilUpgradeTest returns a config test with the given stencilUpgrade
// arguments. The harness always names the service "testing".
func newStencilUpgradeTest(t *testing.T, stencilUpgrade map[string]any) *stenciltest.Template {
	t.Helper()
	fakeDockerPullRegistry(t)
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl", "_stencil_upgrade.tpl")
	args := map[string]any{}
	if stencilUpgrade != nil {
		args["stencilUpgrade"] = stencilUpgrade
	}
	setTestArgs(st, args)
	// We don't actually need any templates from devbase, so using a
	// fake version works here.
	st.AddModule(&configuration.TemplateRepository{
		Name:    "github.com/getoutreach/devbase",
		Version: "v9.99.0",
	})
	return st
}

// readSnapshot returns the contents of the config snapshot of the given test.
func readSnapshot(t *testing.T, testName string) string {
	t.Helper()
	b, err := os.ReadFile(filepath.Join(".snapshots", testName+"-.circleci-config.yml.tpl-.circleci-config.yml.snapshot"))
	assert.NilError(t, err)
	return string(b)
}

func TestStencilUpgradeDisabled(t *testing.T) {
	newStencilUpgradeTest(t, nil).Run(stenciltest.RegenerateSnapshots())
	snapshot := readSnapshot(t, t.Name())
	for _, unwanted := range []string{"stencil-upgrade", "stencil_upgrade"} {
		assert.Check(t, !strings.Contains(snapshot, unwanted), "snapshot has %q, but stencilUpgrade.scheduled is not set", unwanted)
	}
}

func TestStencilUpgradeEnabled(t *testing.T) {
	newStencilUpgradeTest(t, map[string]any{"scheduled": true}).Run(stenciltest.RegenerateSnapshots())
	snapshot := readSnapshot(t, t.Name())
	// stencilUpgradeCron for the service name "testing".
	for _, want := range []string{`cron: "59 18 * * 4"`, "shared/stencil_upgrade:",
		"force_pr: << pipeline.parameters.stencil_upgrade_force_pr >>", "stencil_upgrade_force_pr:\n    type: boolean",
		"stencil_upgrade_note:", "note: << pipeline.parameters.stencil_upgrade_note >>",
		"  stencil_upgrade:\n    type: boolean", "manual-stencil-upgrade:",
		"when: << pipeline.parameters.stencil_upgrade >>", "- not: << pipeline.parameters.stencil_upgrade >>",
		"Stencil::Block(circleStencilUpgradeExtra)"} {
		assert.Check(t, strings.Contains(snapshot, want), "snapshot does not contain %q", want)
	}
}

func TestStencilUpgradeCronOverride(t *testing.T) {
	newStencilUpgradeTest(t, map[string]any{"scheduled": true, "cron": "0 5 * * 1"}).Run(stenciltest.RegenerateSnapshots())
	snapshot := readSnapshot(t, t.Name())
	assert.Check(t, strings.Contains(snapshot, `cron: "0 5 * * 1"`), "snapshot does not contain the stencilUpgrade.cron value")
}
