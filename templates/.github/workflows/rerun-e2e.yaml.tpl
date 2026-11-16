{{- if stencil.Arg "ciOptions.skipE2e" }}
{{- file.Skip "E2E tests are disabled" }}
{{- else if stencil.Arg "oss" }}
{{- file.Skip "Open source repositories can't read the CIRCLECI_API_TOKEN organization secret" }}
{{- else -}}
name: Rerun E2E Tests
on:
  pull_request:
    types: [ready_for_review, labeled]

jobs:
  # The shared/e2e CircleCI job skips its tests on draft pull requests
  # without the run-e2e label. This re-runs that job when the pull request
  # is marked ready for review or gets the run-e2e label.
  rerun_e2e:
    name: Rerun E2E
    uses: getoutreach/actions/.github/workflows/rerun_e2e.yaml@main
    secrets:
      CIRCLECI_API_TOKEN: {{ `${{ secrets.CIRCLECI_API_TOKEN }}` }}
{{- end }}
