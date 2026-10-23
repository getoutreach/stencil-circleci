package main

import (
	"maps"
	"os"
	"path/filepath"
	"testing"

	"github.com/getoutreach/stencil/pkg/configuration"
	"github.com/getoutreach/stencil/pkg/stenciltest"
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

// moduleHooksFixture writes a throwaway template that only populates
// stencil-circleci module hooks (as another module would) and returns its
// path, so it can be rendered alongside the template under test. It lives in
// a temp dir rather than under templates/ so stencil never ships it.
//
// stenciltest loads the module under test twice (once from dependency
// resolution and once explicitly), so every template here is rendered twice in
// the first pass. The global guard keeps the hooks from being added twice,
// which would otherwise trip the duplicate-name checks. The guard is also
// correct if stenciltest ever loads the module once; if it ever renders the
// fixture without shared globals, the duplicate checks fail these tests
// loudly rather than passing by accident.
func moduleHooksFixture(t *testing.T, body string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "module_hooks.tpl")
	contents := `{{- file.Skip "module hooks test fixture" }}
{{- if not (stencil.GetGlobal "moduleHooksFixtureApplied") }}
{{- stencil.SetGlobal "moduleHooksFixtureApplied" true }}
` + body + `
{{- end }}
`
	if err := os.WriteFile(path, []byte(contents), 0o600); err != nil {
		t.Fatalf("failed to write module hooks fixture: %v", err)
	}
	return path
}

// newConfigWithHooks creates a stencil test for .circleci/config.yml.tpl
// rendered together with a fixture that populates module hooks, with
// prereleases (and so the release_rc parameter) enabled.
func newConfigWithHooks(t *testing.T, hooks string) *stenciltest.Template {
	t.Helper()
	return newConfigWithHooksPrereleases(t, hooks, true)
}

// newConfigWithHooksPrereleases is newConfigWithHooks with prereleases set
// explicitly.
func newConfigWithHooksPrereleases(t *testing.T, hooks string, prereleases bool) *stenciltest.Template {
	t.Helper()
	fakeDockerPullRegistry(t)
	st := stenciltest.New(t, ".circleci/config.yml.tpl", "_helpers.tpl", moduleHooksFixture(t, hooks))
	releaseOptions := map[string]any{"enablePrereleases": prereleases}
	if prereleases {
		releaseOptions["prereleasesBranch"] = "main"
	}
	setTestArgs(st, map[string]any{"releaseOptions": releaseOptions})
	// We don't actually need any templates from devbase, so using a
	// fake version works here.
	st.AddModule(&configuration.TemplateRepository{
		Name:    "github.com/getoutreach/devbase",
		Version: "v9.99.0",
	})
	return st
}

func TestRenderWithModuleHooks(t *testing.T) {
	st := newConfigWithHooks(t, `
{{- $mod := "github.com/getoutreach/stencil-circleci" }}
{{- stencil.AddToModuleHook $mod "pipeline.parameters" (list
      (dict "orca_tsc_check" (dict "type" "boolean" "default" false))
      (dict "source-repo" (dict "type" "string" "default" "") "a_param" (dict "type" "string" "default" "x"))) }}
{{- stencil.AddToModuleHook $mod "workflows" (list
      (dict "orca_tsc_check_on_demand" (dict
        "when" "<< pipeline.parameters.orca_tsc_check >>"
        "jobs" (list "shared/test")))) }}
{{- stencil.AddToModuleHook $mod "workflows.release.when.not" (list
      "<< pipeline.parameters.orca_tsc_check >>"
      "<< pipeline.parameters.orca_tsc_check >>") }}
`)
	st.Run(stenciltest.RegenerateSnapshots())
}

func TestRenderFailsOnDuplicateModuleParameter(t *testing.T) {
	st := newConfigWithHooks(t, `
{{- $mod := "github.com/getoutreach/stencil-circleci" }}
{{- stencil.AddToModuleHook $mod "pipeline.parameters" (list
      (dict "orca_tsc_check" (dict "type" "boolean" "default" false))
      (dict "orca_tsc_check" (dict "type" "boolean" "default" true))) }}
`)
	st.ErrorContains(`pipeline.parameters hook: duplicate pipeline parameter "orca_tsc_check"`)
	st.Run(false)
}

func TestRenderFailsOnModuleParameterClashingWithBuiltin(t *testing.T) {
	st := newConfigWithHooks(t, `
{{- stencil.AddToModuleHook "github.com/getoutreach/stencil-circleci" "pipeline.parameters" (list
      (dict "rebuild_cache" (dict "type" "boolean" "default" false))) }}
`)
	st.ErrorContains(`pipeline.parameters hook: duplicate pipeline parameter "rebuild_cache"`)
	st.Run(false)
}

func TestRenderFailsOnModuleParameterWithoutDefault(t *testing.T) {
	st := newConfigWithHooks(t, `
{{- stencil.AddToModuleHook "github.com/getoutreach/stencil-circleci" "pipeline.parameters" (list
      (dict "orca_tsc_check" (dict "type" "boolean"))) }}
`)
	st.ErrorContains(`pipeline.parameters hook: parameter "orca_tsc_check" needs a default`)
	st.Run(false)
}

func TestRenderFailsOnModuleParameterWithInvalidType(t *testing.T) {
	st := newConfigWithHooks(t, `
{{- stencil.AddToModuleHook "github.com/getoutreach/stencil-circleci" "pipeline.parameters" (list
      (dict "orca_tsc_check" (dict "type" "bool" "default" false))) }}
`)
	st.ErrorContains(`pipeline.parameters hook: parameter "orca_tsc_check" has type bool; must be boolean, string, integer or enum`)
	st.Run(false)
}

func TestRenderWithModuleHooksWithoutPrereleases(t *testing.T) {
	st := newConfigWithHooksPrereleases(t, `
{{- $mod := "github.com/getoutreach/stencil-circleci" }}
{{- stencil.AddToModuleHook $mod "pipeline.parameters" (list
      (dict "orca_tsc_check" (dict "type" "boolean" "default" false))) }}
{{- stencil.AddToModuleHook $mod "workflows" (list
      (dict "orca_tsc_check_on_demand" (dict
        "when" "<< pipeline.parameters.orca_tsc_check >>"
        "jobs" (list "shared/test")))) }}
{{- stencil.AddToModuleHook $mod "workflows.release.when.not" (list
      "<< pipeline.parameters.orca_tsc_check >>") }}
`, false)
	st.Run(stenciltest.RegenerateSnapshots())
}
