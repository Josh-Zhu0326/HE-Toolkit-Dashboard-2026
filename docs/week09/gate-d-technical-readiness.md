# Gate D Technical Readiness

This record closes the Bo-owned technical preparation for `DEBT-02`, `DEBT-10`,
`WK9-03`, and the technical portion of `WK9-10`. It is not a team Gate D `GO`.

## Delivered

- The Joined HE dataset has a dedicated, versioned RDS checkpoint download.
- Every checkpoint records app version, UTC creation time, row/column schema,
  column classes, provenance, and an MD5 integrity checksum.
- A new dashboard session can upload the checkpoint, verify its schema and
  checksum, and use the restored dataset for filtering and modelling. When the
  joined dataset includes its real sample `date`, a read-only HEV view also
  normalises lag-zero metric names without changing the checkpoint data.
- An invalid or corrupted checkpoint is rejected without replacing the current
  dataset or exposing a raw R error or local path.
- A checkpoint loaded as an independent frozen data source is not made stale by
  edits to earlier import/mapping controls. An explicit new join switches back
  to the generated-data path and restores the normal invalidation rules.
- The checkpoint download control is absent unless the current Joined HE
  dataset artifact is current, so stale data cannot be downloaded as a valid
  checkpoint.
- RAW-01 is guarded before HEV plotting. A missing declared `ggnewscale`
  dependency now blocks the HEV artifact with the agreed safe message and ends
  the plot request instead of exposing `loadNamespace` or leaving the plot in a
  permanent loading state.

## Executed Verification

The following checks were run on 2026-08-04 before creating the candidate
manifest:

- `Rscript --vanilla tests/testthat.R`: passed.
- Fourteen standalone regression scripts under `tests/`: passed. The existing
  Leaflet interrupted-promise warnings remained non-failing.
- Task 05, clean browser session: loaded a verified six-row checkpoint,
  excluded and restored records, ran the basic model, and reached `Task
  complete` without rebuilding upstream inputs.
- Task 04, clean browser session: loaded a verified six-row checkpoint with
  real sample dates, rendered the HEV plot at 772 by 400 CSS pixels, and reached
  `Task complete` and Stage 4 `Complete` without a server error or permanent
  loading state.
- The Task 04 screenshot and Shiny stdout/stderr logs are retained outside the
  repository under `E:\SummerProjectWorkingArea\gate-d-browser`. They contain
  synthetic fixture data only.
- The RAW-01 missing-dependency path is covered by helper and server tests that
  assert the safe user-facing message and reject raw namespace, stack, and local
  path details.

## Candidate Manifest

Generate a reproducibility packet from a clean candidate commit:

```powershell
Rscript --vanilla scripts/generate_gate_d_candidate_manifest.R E:\gate-d-evidence\<candidate-sha>
```

The packet contains:

- `gate-d-candidate-manifest.json`: exact commit/branch/`origin/main`, clean
  worktree state, R/platform/package versions, and explicit human-evidence
  boundaries;
- `checksums.csv`: dependency entrypoint, research-material, and synthetic
  fixture checksums;
- `session-info.txt`: full R session information.

The output directory must remain outside the repository and inside the approved
project evidence location. Do not put participant or consent data in Git.

## Gate D Decision Boundary

Technical automation can establish the software candidate and reproducibility
packet. It cannot create evidence for real participants, ethics/material scope,
or team sign-off. Until those records exist, the only evidence-supported Gate D
decision is `NO-GO`:

- Pilot 1 packet: missing from the authorised evidence set available here.
- Pilot 2 packet: missing from the authorised evidence set available here.
- Ethics/material boundary confirmation: requires the authorised research team.
- Facilitator acceptance of one RC/material manifest: requires team sign-off.
- Final RC tag: must be created only after Gate D passes; a candidate manifest
  must not be relabelled as the final RC.

Formal sessions must not start from this record alone.
