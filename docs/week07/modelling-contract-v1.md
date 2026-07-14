# Modelling Contract — v1 Review Baseline

> Date: 14 July 2026  
> Status: Review baseline — not frozen  
> Owner: Lin (Modelling/Evaluation)  
> Reviewer: Di (Data Pipeline)  
> Decisions: `DEC-08`, `DEC-09`, `DEC-10`, `DEC-21`  
> Requirements: `RTM-08A`, `RTM-08B`, `RTM-09`, `RTM-10`, `RTM-21`  
> Open item: `OPEN-06`  
> Sources: [Client Decision Log](client-decision-log-v1.md) and [Requirement Traceability Matrix](requirement-traceability-matrix-v1.md)  

## 1. Purpose and Current State

This document is the review baseline for Dashboard v1 modelling. It separates confirmed rules from thresholds and failure policies that still require Lin/Di review.

The current Dashboard implementation and automated tests contain only the basic single-site additive `lm()` helper. Mixed-effects modelling is present in the requirements and delivery plan but is not yet implemented or verified. Until every `MC-O*` item in this document is closed and the readiness gate passes, multi-site modelling must remain `not_ready`.

This baseline does not close `OPEN-06` and must not be cited as evidence that the mixed-model path is complete.

## 2. Confirmed Rules

### MC-R01 — Model-path routing

- Path routing is based on the number of distinct valid `biol_site_id` values in the current `analysis_dataset` after model-specific exclusions are applied.
- Exactly one valid site routes to the single-site additive path.
- Two or more valid sites identify a candidate multi-site path only; they do not establish mixed-model eligibility. Eligibility remains blocked until the `MC-O*` thresholds are frozen.
- Zero valid sites blocks modelling with a field-level message.

### MC-R02 — Predictor eligibility and limits

- V1 allows at most two flow predictors, one WQ predictor, and one RHS predictor.
- A single-site additive model may use raw Q10/Q95 lag fields.
- A candidate multi-site mixed-effects model may use only Q10z/Q95z lag fields for flow predictors.
- UI filtering and server-side validation must enforce the same eligibility rules.

### MC-R03 — Sampling year

- `sampling_year_centered = sampling_year - (min_year + max_year) / 2` is calculated from the applicable current analysis data.
- When at least two distinct valid years exist, applicable models include `sampling_year_centered` by default.
- Missing, blank, unparseable, partially missing, and constant-year behaviour follows `DEC-09`/`RTM-09` and must be recorded in provenance.

### MC-R04 — Permitted random-effects structures

The only permitted mixed-model random-effects structures are:

```text
(1 | biol_site_id)
(sampling_year_centered | biol_site_id)
```

No alternative grouping factor, nested structure, uncorrelated-slope syntax, or additional random term may be introduced without a new decision and contract revision.

### MC-R05 — Mixed-model execution gate

- Mixed-model execution is disabled while this document remains a review baseline.
- A mixed model that does not satisfy the frozen eligibility, convergence/singularity, or numerical-parity rules must stop with an explicit `not_ready`, `blocked`, or `failed` state as defined by the final contract.
- A multi-site failure must never be silently replaced with a pooled `lm()`.
- The independently verified single-site additive path may remain available, but it must not be presented as a model of the multi-site data.

### MC-R06 — Minimum result contract

When a model path is eventually eligible, its result must expose at least:

```text
status
messages
formula
model_path
random_effect_structure
n_input
n_complete
n_excluded
site_count
year_range
year_center
fixed_effects
random_effects
fit_metrics
diagnostics
convergence_status
singularity_status
provenance
```

- Single-site results leave mixed-only fields explicitly not applicable rather than fabricating values.
- Mixed-model R² must use an explicitly named marginal/conditional R² definition, implementation, and package version. No mixed-model R² is considered contracted until `MC-O09` is closed.

### MC-R07 — Reproducibility and output

- Downloads must identify the source dataset/version, filtering version, complete-case exclusions, fitted formula, selected predictors, year-centring reference, software/package versions, warnings, and final model state.
- Fixed effects, random effects, diagnostics, and fit metrics must be reproducible against a frozen independent reference implementation within an approved tolerance.

### MC-R08 — No implicit policy

Implementation code must not choose an unresolved threshold, R² definition, tolerance, warning boundary, or failure fallback. Each unresolved choice must first close the corresponding `MC-O*` item and be reviewed in both language versions.

## 3. Open Decisions Required Before Freeze

| ID | Decision to freeze | Interim rule | Owner | Reviewer | Status |
|---|---|---|---|---|---|
| `MC-O01` | Minimum number of unique sites for a mixed model | Two or more sites identify only a candidate path; execution remains disabled | Lin | Di | Open |
| `MC-O02` | Minimum total complete cases and parameter-to-record rule | Do not fit a mixed model | Lin | Di | Open |
| `MC-O03` | Minimum observations and complete cases per site | Do not fit a mixed model | Lin | Di | Open |
| `MC-O04` | Repeated years/observations and within-site variation required for a random slope | Do not offer or fit the random-slope form | Lin | Di | Open |
| `MC-O05` | Scaling rules for flow and non-flow predictors | Enforce only the confirmed Q10z/Q95z multi-site flow rule; do not infer other scaling | Lin | Di | Open |
| `MC-O06` | Complete-case, missingness, NA/Inf, and excluded-record policy beyond DEC-09 | Do not fit a mixed model | Lin | Di | Open |
| `MC-O07` | Collinearity/high-correlation thresholds and blocking versus warning behaviour | Do not fit a mixed model | Lin | Di | Open |
| `MC-O08` | Convergence failure, singular fit, and zero/near-zero random-effect variance state mapping | Treat the mixed path as unavailable; never fall back to pooled `lm()` | Lin | Di | Open |
| `MC-O09` | Marginal/conditional R² definition, implementation, and package version | Do not report a contracted mixed-model R² | Lin | Di | Open |
| `MC-O10` | Independent reference implementation, fixtures, metrics, and numerical tolerances | Do not mark numerical parity as passed | Lin | Di | Open |
| `MC-O11` | Warning/error/export boundaries and user-facing messages | Do not expose the mixed path as ready or export a result | Lin | Di | Open |

## 4. Freeze and Readiness Gate

This document may move to `Frozen v1`, and `OPEN-06` may close, only when all of the following are true:

1. Every `MC-O01`–`MC-O11` item has a reviewed decision with no placeholder threshold.
2. English and Chinese contracts have identical rule IDs, formulas, states, and acceptance meaning.
3. Lin approves the modelling rules and Di approves their data/validation feasibility.
4. Tests cover path routing, data sufficiency, both permitted random-effects structures, missingness, scaling, collinearity, convergence failure, singular fit, near-zero variance, stale data, output/provenance, and prohibited pooled-`lm()` fallback.
5. Single-site results match an independent `lm()` reference and mixed results match the frozen mixed-model reference within approved tolerances.
6. `RTM-08B` and `RTM-10` link the reproducible evidence; status changes occur only after implementation and tests pass.

## 5. Required Test Files

Planned evidence includes:

```text
tests/test_model_paths.R
tests/test_predictor_constraints.R
tests/test_mixed_effect_structure.R
tests/test_flow_predictor_eligibility.R
tests/fixtures/model_single_site.*
tests/fixtures/model_multi_site.*
tests/reference/reference_single_site_lm.R
tests/reference/reference_mixed_model.R
```

File names may be adjusted during implementation, but every readiness-gate behaviour must retain reproducible evidence and RTM links.
