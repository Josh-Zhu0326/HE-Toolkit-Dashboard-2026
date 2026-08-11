# Formal Session Manifest + Daily QA

Rule: de-identified IDs only. No names, emails, signatures, audio, or screen
recordings go into the public repository. Consent and any personal data stay in
the authorised location.

---

## 1. Master session log (one row per participant)

Fill one row as each session is scheduled, update as it runs.

| session_id | date | facilitator | observer | sequence | Task B checkpoint | status | valid? | notes |
|---|---|---|---|---|---|---|---|---|
| P01 | | | | A_then_B | | scheduled/done | yes/no | |
| P02 | | | | A_then_B | | | | |
| P03 | | | | A_then_B | | | | |
| … | | | | A_then_B | | | | |

- `status`: scheduled → in_progress → done.
- `valid?`: no if consent incomplete, wrong build/materials, blocking bug not the
  participant's fault, or key measurements missing (see protocol Section 2).
- The sequence is fixed at A_then_B for every participant.
- Enter the frozen Task B checkpoint ID/version used in the session.

## 2. Per-session manifest (one filled copy per participant)

```
session_id            (P01 …)
date
facilitator
observer
build_tag             (frozen RC — must match everyone else's)
material_version
task_sequence         (A_then_B; fixed)
taskB_checkpoint_id   (frozen checkpoint version/checksum)
taskB_checkpoint_ok   (yes / no)

taskA_completion      (independent / with_help / not_completed)
taskA_time_sec
taskA_interventions
taskB_completion
taskB_time_sec
taskB_interventions

seq_taskA             (1-7)
seq_taskB             (1-7)
sus_total             (0-100)
confidence            (1-5)
rubric_a rubric_b rubric_c   (0-2 each)

notable_issues
deviations
files_saved           (list de-identified file names)
```

File naming: `session_P01_2026-07-30.<ext>`. Never put a real name in a file name.

## 3. End-of-day QA checklist (do this every session day)

Run once per participant, then a batch check at day end.

Per participant:
- [ ] Consent completed and stored in the authorised location (not the repo)
- [ ] Manifest fully filled (no blank timing/completion unless truly missing)
- [ ] Task A was scored before the Task B checkpoint transition
- [ ] Frozen Task B checkpoint ID/version recorded and verified
- [ ] Checkpoint loading was not counted as a facilitator intervention
- [ ] All files use the de-identified naming pattern
- [ ] No real name / email / signature in any file or file name
- [ ] Recordings (if any) stored in the authorised location only
- [ ] Any deviation written in the manifest with its reason

Day-end batch:
- [ ] Master log updated for every session run today
- [ ] valid? decided for each session with a reason for any "no"
- [ ] Running count of valid participants updated (target 12, aim 16)
- [ ] Access permissions checked (personal data not readable by the public repo)
- [ ] Blocker / data-correctness issues, if any → pause new sessions, log which
      sessions are affected, and follow the fix/retain/exclude rule

## 4. Recruitment gap note (fill Friday if short of 12)

If the valid count is under 12 by Friday and the reason is participant
availability (not the team), record here:
- Named recruitment/coordination for 3–4 Aug: ____
- Anonymous schedule for those slots: ____
- Do NOT use empty placeholder bookings to hit the target.

## 5. Batch summary (fill at end of each day)

| batch | sessions run | valid | invalid (reason) | running valid total |
|---|---|---|---|---|
| A | | | | |
| B | | | | |
