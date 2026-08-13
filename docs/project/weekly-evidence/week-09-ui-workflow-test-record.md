# Week 9 UI and Workflow Automated Test Record

## Test metadata

| Field | Recorded value |
|---|---|
| Final exact-state revalidation | `2026-07-29`, completed `18:36 BST` |
| HEAD commit SHA | `7b200c118d2de7521604a2e0c22ef1cf96aacb1c` |
| R version | `R version 4.6.0 (2026-04-24)` |
| Implementation diff SHA-256 | `80abaa681f61edc1619f89887558ca97367f51bb0a3d26e2f2c4837f55b50ad4` |

The tests were run with uncommitted UI/workflow changes present. The HEAD SHA
therefore identifies the baseline commit, while the diff fingerprint identifies
the tested changes in:

- `R/workflow_state.R`
- `R/workflow_ui.R`
- `server.R`
- `tests/testthat/test-workflow-state.R`
- `tests/testthat/test-workflow-ui.R`
- `tests/testthat/test-workflow-server.R`
- `tests/testthat/test-server-local-flow-source.R`

The fingerprint command was:

```bash
git diff -- R/workflow_state.R R/workflow_ui.R server.R \
  tests/testthat/test-workflow-state.R \
  tests/testthat/test-workflow-ui.R \
  tests/testthat/test-workflow-server.R \
  tests/testthat/test-server-local-flow-source.R | shasum -a 256
```

## Related tests

| Command | Pass | Failure | Error | Warning | Skip | Result |
|---|---:|---:|---:|---:|---:|---|
| `Rscript -e 'testthat::test_file("tests/testthat/test-workflow-state.R")'` | 69 | 0 | 0 | 0 | 0 | Passed |
| `Rscript -e 'testthat::test_file("tests/testthat/test-workflow-ui.R")'` | 142 | 0 | 0 | 0 | 0 | Passed |
| `Rscript -e 'testthat::test_file("tests/testthat/test-workflow-server.R")'` | 36 | 0 | 0 | 0 | 0 | Passed |
| `Rscript -e 'testthat::test_file("tests/testthat/test-server-local-flow-source.R")'` | 60 | 0 | 0 | 0 | 0 | Passed |

## Complete suite

Command:

```bash
R_USER_CACHE_DIR=/tmp/he-toolkit-r-cache Rscript tests/testthat.R
```

The complete suite finished with `DONE`. All reported expectations passed in
the following test contexts:

- `dashboard-backlog-helpers`
- `flow-mapping-contract`
- `flow-metadata-defaults`
- `local-flow-contract`
- `rhs-contract`
- `server-local-flow-source`
- `setup`
- `site-metadata-helpers`
- `workflow-config`
- `workflow-server`
- `workflow-state`
- `workflow-ui`

Complete-suite result: `0 failure`, `0 error`, `0 warning`, and `0 skip`.

## Real UI follow-up

The production Shiny UI was run locally against the same implementation source
state. The follow-up evidence is indexed in
[`docs/testing/evidence/ui-parity/`](../../testing/evidence/ui-parity/).

| Scenario | Result |
|---|---|
| Attempt Flow statistics without Flow input | PASS — Stage 2 became `Blocked` with a concrete upload/import and retry action |
| Valid Flow result, then replace the upstream Flow source | PASS — Stage 2 moved from `Complete` to `Stale` |
| Change Task after a reusable Flow-statistics result | PASS — `Processed flow` and `Flow statistics` remained listed and Task 2 remained complete |
| Flow-statistics exception from an insufficient short source | PASS — Stage 2 became recoverable `Failed`, displayed a safe retry action, and did not retain the busy overlay |

## Diff validation

Command:

```bash
git diff --check
```

Result: passed with no output, confirming no whitespace or patch-format errors.

## Completion criteria

| Criterion | Result |
|---|---|
| Zero failures | Met |
| Zero errors | Met |
| No new warnings | Met |
| `git diff --check` clean | Met |
| Missing-input blocked browser evidence | Met |
| Complete → upstream change → stale browser evidence | Met |
| Change Task reusable completion evidence | Met |
| Recoverable Flow-statistics failure evidence | Met |

Bo's formal follow-up approval has been recorded. The controlled mapping is
`FROZEN`.
