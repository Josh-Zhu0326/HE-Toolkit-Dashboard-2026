# Formal Study Protocol v1 (draft)


## 1. Research questions

- RQ1: Can a non-programming user complete the core workflow (produce and
  download an HEV result) on their own?
- RQ2: Can a non-programming user refine the analysis (exclude a record, see it
  in the log, restore it) and run and read the single-site model?
- RQ3: Do users correctly understand the workflow state (blocked / warning /
  complete / stale) and recover from errors without developer help?

## 2. Participants

- Target: 12–16 valid participants (proxy users: people comfortable with
  spreadsheets but with little or no R/Shiny experience).
- Pilot participants are NOT counted in the main sample.
- Each participant gets a de-identified ID (P01, P02, …).
- Exclude a session from analysis if: consent is incomplete, a blocking software
  bug prevents the task through no fault of the participant, the build/materials
  used were not the frozen versions, or key measurements are missing.

## 3. Materials and version

- Frozen RC build: commit/tag ____ (fill after RC freeze).
- Material manifest: task sheet, observation log, SEQ/SUS/confidence forms,
  interview guide, consent (approved ethics version) — all version-stamped.
- All facilitators use the SAME build and the SAME material manifest.

## 4. Tasks

Two tasks. Order is counterbalanced (see Section 6).

- Task A — Produce an HEV result: choose a goal, upload the workbook, read the
  validation/checkpoint messages, build the dataset, produce and download HEV.
- Task B — Refine and model: exclude one record, find it in the exclusion log
  and explain why, restore it, then choose variables and run the single-site
  model and read the result.

## 5. Measurement definitions (frozen)

- Timing start point: the moment the facilitator finishes reading the task and
  says "you can start". Stop point: the participant produces the required output
  (Task A: file downloaded; Task B: model result shown) or gives up.
- Help / intervention: any facilitator input beyond a neutral think-aloud prompt
  ("what are you thinking?"). Count each one. A task needing any direct help is
  "completed with help".
- Completion: "independent" (no help), "with help", or "not completed".
- Interpretation correctness rubric (0–2 per item): 0 = wrong, 1 = partly right,
  2 = correct. Items: (a) what the validation message meant, (b) why a record
  was excluded, (c) what the model result (slope direction, fit) means.
- SEQ: single 1–7 ease rating after each task.
- SUS: standard 10-item scale at the end.
- Confidence: 1–5, "how confident that your result is correct", at the end.
- Semi-structured interview: 5 fixed questions (see pilot pack).
- Missing data: if a single item is missing, keep the session and mark that item
  NA; do not fill it in. If a whole task's timing/completion is missing, exclude
  that task from the timing/completion analysis only.

## 6. Condition allocation (counterbalancing)

- The only manipulated factor is task order (A→B or B→A).
- Assign order by alternating as participants are scheduled: P01 A→B, P02 B→A,
  P03 A→B, … Keep the two orders as balanced as the final count allows.
- Record the assigned order in the session schema before the session starts;
  do not change it afterwards.

## 7. Session schema (recorded per session)

```
session_id            (P01 …)
date
facilitator
observer
build_tag             (frozen RC)
material_version
task_order            (A_first / B_first)
taskA_completion      (independent / with_help / not_completed)
taskA_time_sec
taskA_interventions
taskB_completion
taskB_time_sec
taskB_interventions
seq_taskA             (1-7)
seq_taskB
sus_total             (0-100)
confidence            (1-5)
rubric_a / rubric_b / rubric_c   (0-2 each)
notable_issues
deviations
```

## 8. Analysis plan v1

- Primary metrics: task completion rate (independent %), and interpretation
  correctness (mean rubric score). These answer RQ1–RQ3.
- Secondary metrics: time on task, number of interventions, SEQ, SUS, confidence.
- Analysis: report counts/percentages and simple summaries (mean, median, range).
  With 12–16 participants this is descriptive; no significance testing is claimed.
  If comparing task orders, report the difference with an effect size and a
  confidence interval, not a p-value claim.
- Qualitative: code interview notes and think-aloud quotes into themes
  (navigation, terminology, error understanding, trust).
- Deviations: log any protocol deviation with reason; deviations do not change
  the primary metrics.
- Scope note: results describe the whole redesigned workflow, not the causal
  effect of any single component.

## 9. Freeze and open items

- Freeze this protocol at Gate D. After that, changes need a change request.
- Open item blocking full freeze: the mixed-model scope decision (Section 0
  assumption). Confirm with Di/Lin before Gate D.
