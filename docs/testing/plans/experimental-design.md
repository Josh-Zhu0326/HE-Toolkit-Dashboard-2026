# Experimental Design — Modelling / Evaluation Module

**Owner:** Yutong  **Reviewer:** Di
**Scope:** filtering, exclusion log, and the model interface (`run_model`).
**Last updated:** 2026-07-19

This document defines how we evaluate the Modelling/Evaluation module: the
functional test cases, the think-aloud user tasks, and the metrics we record.
It complements `high-level-test-plan.md` and `manual_test_cases.md`.

---

## 1. What we are evaluating

The module covers three user-facing capabilities:

1. **Filtering** — bad rows in uploaded invertebrate data are removed before
   analysis (`filter_records`).
2. **Exclusion log** — every removed or flagged row is recorded with a reason
   and can be viewed and downloaded (`build_exclusion_log`).
3. **Model interface** — non-coding users run a flow–ecology model by choosing
   variables and pressing Run, never touching R (`run_model`).

The target users understand environmental data but may have little or no
programming experience, so the evaluation weighs **understandability** as
heavily as correctness.

---

## 2. Functional test cases

Automated unit tests (Source in RStudio):

- `tests/test_filtering_helpers.R`
- `tests/test_exclusion_log_helpers.R`
- `tests/test_model_interface_helpers.R`

Manual / black-box cases are recorded in `tests/manual_test_matrix.csv`
(TC-024 to TC-039), covering four input classes for each capability:

| Input class | Filtering | Exclusion log | Model interface |
| --- | --- | --- | --- |
| Normal | TC-024 | TC-031 | TC-035 |
| Abnormal | TC-025, TC-026, TC-027, TC-028 | TC-032, TC-033 | TC-036, TC-039 |
| Empty | TC-029 | TC-034 | TC-037 |
| Boundary | TC-030 | — | TC-038 |

For each manual case, record: input, action, expected result, actual result,
pass/fail, and any observed message wording.

---

## 3. Think-aloud user tasks

Method follows `Think-aloud plan.docx`. Recruit proxy users who have basic
computer skills but little programming experience (e.g. environmental-science
students, spreadsheet-comfortable researchers). Ask them to speak their
thoughts aloud while completing each task. The facilitator does not help unless
the participant is fully stuck.

### Task A — Upload data and understand what was removed
Give the participant an invertebrate CSV that contains a few deliberately bad
rows (missing site ID, negative abundance, bad date). Ask them to upload it on
**Data Import → Local File Import** and then explain, in their own words, what
the exclusion log is telling them.

*Observe:* Do they notice the exclusion log? Can they say why each row was
removed without help? Is "excluded_value" / "rule" wording clear?
*Record:* time to locate the log, number of clarifying questions, points of
confusion.

### Task B — Run the flow–ecology model
From joined data, ask the participant to go to **Analysis → Flow-Ecology
Model**, choose a flow variable and an ecology variable, and produce a result.

*Observe:* Can they find the model page and the variable selectors? Do they
understand they must press Run? Can they read the summary (slope, direction,
p-value, R²) and the scatter plot?
*Record:* task completion (yes/no/with help), time taken, whether they
interpret the result correctly.

### Task C — Recover from an error (optional, if time allows)
Ask the participant to press Run *before* selecting variables (or before data
is joined) and describe what happens and what they would do next.

*Observe:* Is the error message understood as "I need to do X" rather than a
scary failure? Do they recover without restarting?
*Record:* whether the message is actionable, whether they recover unaided.

---

## 4. Evaluation metrics

Aligned with the evaluation aims (effectiveness, efficiency, satisfaction).

| Dimension | Metric | How measured |
| --- | --- | --- |
| Effectiveness | Task completion rate | % of participants completing each task unaided |
| Effectiveness | Interpretation accuracy | Can the participant correctly explain the log / model result |
| Efficiency | Time on task | Seconds from task start to completion |
| Efficiency | Assistance needed | Count of facilitator prompts / clarifying questions |
| Understandability | Error-message clarity | Participant can state the required next action after an error |
| Satisfaction | Post-task rating | Short questionnaire (e.g. 1–5) per task, plus free-text comments |

**Success guideline (to confirm with Di):** a capability is "acceptable" when a
majority of proxy users complete its core task unaided and can correctly explain
the outcome. Exact thresholds to be agreed before testing.

---

## 5. Open items for Di

- Confirm the "acceptable" success threshold in Section 4.
- Confirm filtering thresholds used during testing (`min_records_per_site`,
  `max_abundance`).
- Confirm the proxy-user profile and how many participants to recruit.
