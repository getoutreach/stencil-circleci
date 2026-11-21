package main

import (
	"regexp"
	"strconv"
	"strings"
	"testing"
	"text/template"

	"github.com/Masterminds/sprig/v3"
)

// stencilUpgradeCron runs the stencilUpgradeCron template for a service name.
func stencilUpgradeCron(t *testing.T, tpl *template.Template, name string) string {
	t.Helper()
	var sb strings.Builder
	if err := tpl.ExecuteTemplate(&sb, "stencilUpgradeCron", name); err != nil {
		t.Fatal(err)
	}
	return sb.String()
}

func TestStencilUpgradeCronDerivation(t *testing.T) {
	// The file calls file.Skip outside of the template under test. A stub
	// lets the file parse; the test never runs that part.
	funcs := sprig.TxtFuncMap()
	funcs["file"] = func() any { return nil }
	tpl := template.Must(template.New("c").Funcs(funcs).ParseFiles("_stencil_upgrade.tpl"))

	svcA := stencilUpgradeCron(t, tpl, "svc-a")
	svcB := stencilUpgradeCron(t, tpl, "svc-b")
	if want := "31 18 * * 4"; svcA != want {
		t.Errorf("svc-a: got %q, want %q", svcA, want)
	}
	if want := "48 19 * * 4"; svcB != want {
		t.Errorf("svc-b: got %q, want %q", svcB, want)
	}
	if svcA == svcB {
		t.Errorf("svc-a and svc-b have the same cron %q", svcA)
	}
	if again := stencilUpgradeCron(t, tpl, "svc-a"); again != svcA {
		t.Errorf("svc-a: second run gave %q, first gave %q", again, svcA)
	}

	cronRe := regexp.MustCompile(`^(\d{1,2}) (\d{1,2}) \* \* 4$`)
	for i := range 250 {
		name := "service-" + strconv.Itoa(i)
		cron := stencilUpgradeCron(t, tpl, name)
		m := cronRe.FindStringSubmatch(cron)
		if m == nil {
			t.Errorf("%s: cron %q does not match %s", name, cron, cronRe)
			continue
		}
		if minute, _ := strconv.Atoi(m[1]); minute > 59 {
			t.Errorf("%s: minute %d is not in 0-59", name, minute)
		}
		if hour, _ := strconv.Atoi(m[2]); hour < 8 || hour > 19 {
			t.Errorf("%s: hour %d is not in 8-19", name, hour)
		}
	}
}
