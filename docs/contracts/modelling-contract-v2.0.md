# Modelling Contract — v2.0 (Frozen Requirements)

> Date: 25 August 2026  
> Status: **Frozen requirements; implementation not yet verified**  
> Supersedes: [Modelling Contract v1.0](modelling-contract-v1.0.md) for new work  
> Authority: `DEC-39`, `DEC-45`, `DEC-47`, `DEC-49`; client email `SRC-09` in the [Client Decision Log](../decisions/client-decision-log-v1.md)
> Traceability: `RTM-03`, `RTM-08A`, `RTM-08B`, `RTM-09`, `RTM-10`, `RTM-21`, `RTM-30` in [RTM v2.0](requirement-traceability-matrix-v2.0.md)

## 1. Scope and model paths

Both single-site and multiple-site models use `mgcv::gam()`. A single-site model has no site-level term. A multiple-site model may use only a scientifically reviewed site-intercept, year-by-site, or selected-Flow-by-site structure expressed as valid `mgcv` terms. An ineligible or failed multiple-site model must not silently fall back to a pooled or single-site model.

Fitting changes only the current `analysis_dataset`; it must not alter upstream source, processed, or joined datasets.

## 2. Frozen modelling rules

1. The builder proceeds in five steps: choose the model path; choose exactly one ecological receptor and up to two Flow predictors; optionally choose up to one WQ predictor, one RHS predictor, and sampling year and/or season; choose up to two Flow × season and/or Flow × RHS interactions; then, for a multiple-site model, choose one reviewed site-level structure.
2. Supported Flow lags are `0`, `1`, `3`, `6`, and `12`.
3. Single-site models offer Raw `Q95_lagL` and standardised `Q95z_lagL`. Multiple-site models offer and accept only standardised `Q95z_lagL`. This contract does not independently change inherited Q10 eligibility.
4. When year is selected, calculate `sampling_year_centered = sampling_year - (min_year + max_year) / 2` from the applicable analysis data.
5. UI and server validation enforce identical limits and reject unsupported variables, interactions, structures, or lag values before fitting.

## 3. Candidate and preferred-model lifecycle

Each fit creates an identifiable candidate and must not overwrite earlier candidates. Compare candidates initially through `summary()` and `AIC()` with the sample basis disclosed. The user explicitly selects the preferred model; only that model proceeds to applicable partial-effect and diagnostic outputs through `gratia::draw()`, `mgcv::gam.check()`, and `gratia::appraise()`.

User-facing result tables use three significant figures; stored and exported values retain reproducible precision.

## 4. Result and provenance contract

Every result provides:

```text
status, messages, candidate_id, preferred_model_status, formula, model_path,
family, link, method, n_input, n_complete, n_excluded, site_count,
year_range, year_center, parametric_terms, smooth_terms, fit_metrics,
diagnostics, convergence_status, provenance
```

Provenance records source versions, selected predictors and lags, transformations, year centring, exclusions, warnings, formula, and package versions. Permitted states are `success`, `warning`, `failed`, and `blocked`; `failed` and `blocked` results are not exportable as fitted models, while warning exports retain the warning.

## 5. Scientific and verification gate

`OPEN-08` blocks verified implementation until scientific review freezes the GAM families and links, basis and smoothing settings, valid multiple-site terms, data-sufficiency rules, missing-data and diagnostic boundaries, and numerical/scientific tolerances. Code must not infer these settings; affected paths remain `blocked` or explicitly experimental.

A path becomes `Verified` only after automated evidence covers routing and builder limits, path-specific Q95 eligibility and all lags, formula validation, candidate/preferred-model behaviour, diagnostic gating, exclusions and failure states, prohibited fallbacks, export/provenance, and comparison with an independent scientific reference.

Any change to a frozen requirement requires a controlled decision and a new contract revision.
