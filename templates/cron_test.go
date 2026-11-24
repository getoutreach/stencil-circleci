package main

import (
	"regexp"
	"strconv"
	"strings"
	"testing"
	"text/template"

	"github.com/Masterminds/sprig/v3"
	"gotest.tools/v3/assert"
)

// stencilUpgradeCron runs the stencilUpgradeCron template for a service name.
func stencilUpgradeCron(t *testing.T, tpl *template.Template, name string) string {
	t.Helper()
	var sb strings.Builder
	assert.NilError(t, tpl.ExecuteTemplate(&sb, "stencilUpgradeCron", name))
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
	assert.Equal(t, svcA, "31 18 * * 4")
	assert.Equal(t, svcB, "48 19 * * 4")
	assert.Assert(t, svcA != svcB, "svc-a and svc-b have the same cron %q", svcA)
	assert.Equal(t, stencilUpgradeCron(t, tpl, "svc-a"), svcA, "the cron of svc-a changed between runs")

	cronRe := regexp.MustCompile(`^(\d{1,2}) (\d{1,2}) \* \* 4$`)
	for i := range 250 {
		name := "service-" + strconv.Itoa(i)
		cron := stencilUpgradeCron(t, tpl, name)
		m := cronRe.FindStringSubmatch(cron)
		if !assert.Check(t, m != nil, "%s: cron %q does not match %s", name, cron, cronRe) {
			continue
		}
		minute, _ := strconv.Atoi(m[1])
		assert.Check(t, minute <= 59, "%s: minute %d is not in 0-59", name, minute)
		hour, _ := strconv.Atoi(m[2])
		assert.Check(t, hour >= 8 && hour <= 19, "%s: hour %d is not in 8-19", name, hour)
	}
}
