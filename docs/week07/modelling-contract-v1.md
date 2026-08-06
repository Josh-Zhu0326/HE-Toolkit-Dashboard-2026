# Modelling Contract — v1 (Frozen)

> Date: 14 July 2026 (baseline); frozen 30 July 2026  
> Status: **Frozen v1** — all `MC-O01`–`MC-O11` decided (see Section 3)  
> Owner / decider: Yutong (Modelling/Evaluation), delegated by the team  
> Reviewer: Di (Data Pipeline, data feasibility); Lin (Modelling)  
> Decisions: `DEC-08`, `DEC-09`, `DEC-10`, `DEC-21`  
> Requirements: `RTM-08A`, `RTM-08B`, `RTM-09`, `RTM-10`, `RTM-21`  
> Closes: `OPEN-06`  
> Sources: [Client Decision Log](../client-decision-log-v1.md) and [Requirement Traceability Matrix](requirement-traceability-matrix-v1.md)

## 1. Purpose and Current State

This document defines the frozen v1 rules for Dashboard modelling. It records both the confirmed rules and the thresholds and failure policies that were still open in the review baseline, all of which are now decided in Section 3.

The single-site additive `lm()` path is implemented and verified. The multi-site mixed-effects path is now enabled and must be implemented and verified against the frozen rules below; until its automated tests pass in a clean environment, individual multi-site results must report their state honestly (`success`, `warning`, `failed`, or `blocked`) and must never be replaced by a pooled `lm()`.

This freeze closes `OPEN-06`. Any later change to a frozen value requires a change request and a contract revision.

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

- Mixed-model execution is **enabled** under this frozen contract, subject to the data-sufficiency, structure, collinearity, and failure rules decided in Section 3.
- A mixed model that does not satisfy the frozen eligibility, convergence/singularity, or numerical-parity rules must stop with an explicit `not_ready`, `blocked`, or `failed` state as defined by this contract.
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

## 3. Frozen Decisions (MC-O01 – MC-O11)

All items below are decided and frozen. Values were adopted as the recommended
defaults, delegated to Yutong by the team; Di confirms data feasibility for the
sample-size items. Any change requires a change request.

| ID | Decision (frozen) | Status |
|---|---|---|
| `MC-O01` | A mixed model requires at least **5 unique valid sites**. With 2–4 valid sites the mixed path is `blocked` (too few sites); the single-site path is offered per site where eligible. | Frozen |
| `MC-O02` | Total complete cases must be at least **10 × the number of fixed-effect parameters**, with an absolute floor of **20**. Otherwise `blocked`. | Frozen |
| `MC-O03` | Each site needs at least **3 complete observations** to enter the mixed fit. Sites below this are excluded from the fit and their count is reported. | Frozen |
| `MC-O04` | A random slope `(sampling_year_centered \| biol_site_id)` is allowed only when a majority of eligible sites have **≥ 3 distinct valid years** and non-zero within-site variation in the term; otherwise only a random intercept `(1 \| biol_site_id)` is used. | Frozen |
| `MC-O05` | Multi-site flow predictors use the Z-score `Q10z/Q95z` fields (DEC-21). Other numeric predictors (e.g. WQ) are standardised to mean 0 / SD 1 over the analysis dataset; `sampling_year` is centred (DEC-09); categorical RHS predictors are not scaled. Scaling is recorded in provenance. | Frozen |
| `MC-O06` | Complete-case analysis (listwise deletion). Any `NA`/`Inf` in a model variable drops that row; the excluded count is reported. If more than **20%** of rows are dropped, a `warning` is raised. | Frozen |
| `MC-O07` | Collinearity: fixed-effect **VIF > 10 blocks** the fit; VIF **5–10 warns**; pairwise absolute correlation **> 0.9 warns**. | Frozen |
| `MC-O08` | Non-convergence → `failed` with a clear message. Singular fit or near-zero random-effect variance → `warning` recommending a random-intercept-only or single-site analysis. A pooled `lm()` fallback is never used. | Frozen |
| `MC-O09` | Report Nakagawa & Schielzeth **marginal and conditional R²** via `performance::r2_nakagawa` (fallback `MuMIn::r.squaredGLMM`); the package and version are recorded in provenance. | Frozen |
| `MC-O10` | Numerical parity: fixed-effect estimates are checked against an independent reference (a second implementation or a hand-computed fixture) within a tolerance of **1e-4**; fixtures with known structure are provided. | Frozen |
| `MC-O11` | Export boundaries: `blocked` → no export with a clear message; `warning` → export allowed with the warning recorded in provenance; `failed` → no export. Exports contain all MC-R06 / MC-R07 fields. | Frozen |

## 4. Freeze and Readiness Status

**Decisions:** frozen. Every `MC-O01`–`MC-O11` item has a decided value with no
placeholder threshold (Section 3), and `OPEN-06` is closed.

**Remaining before the mixed path is marked `Verified`** (implementation gate, not
a decision gate):

1. Implement the mixed path in code per Section 3 (`R/mixed_model_helpers.R`).
2. Tests cover path routing, data sufficiency, both permitted random-effects structures, missingness, scaling, collinearity, convergence failure, singular fit, near-zero variance, stale data, output/provenance, and the prohibited pooled-`lm()` fallback.
3. Single-site results match an independent `lm()` reference and mixed results match an independent mixed-model reference within the 1e-4 tolerance (MC-O10).
4. `RTM-08B` and `RTM-10` link the reproducible evidence; the readiness status changes to `Verified` only after implementation and tests pass in a clean environment.
5. English and Chinese contracts keep identical rule IDs, values, and states.

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
