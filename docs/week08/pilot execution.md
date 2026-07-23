# Week 8 Pilot Session Pack (WK8-10)

Each session takes about 45–60 minutes.

---

## 1. Facilitator Runsheet

### Start
- Confirm the participant has signed the approved consent form (WK8-13) and agreed to screen/audio recording.
- Explain that this is a test of the dashboard, not of the participant. If something is hard, that is a problem with our design, not with them.
- Explain that this is a pilot session and the data will not be used in the formal analysis.
- Start the screen recording / observation notes and start the timer.

### Think-aloud rules
- Ask the participant to say what they are thinking, what they are looking for, and what they expect to happen.
- When the participant goes quiet, use only neutral prompts: "What are you thinking right now?" / "What do you expect to happen if you click this?"
- Do not explain the interface in developer language and do not hint at the correct action.
- Only step in when the participant is completely stuck and cannot continue, and record every time you do.

### Task order
1. Task A — HEV flagship path
2. Task B — filter + model refine path

Record the start and end time of each task.

### After each task
- Ask the participant to complete the SEQ (single-question difficulty rating).
- Short follow-up: "Which step was the least clear?" / "Where did you hesitate?"

### Wrap-up (about 10 minutes)
- Ask the participant to complete the SUS and the confidence rating.
- Run the semi-structured interview (see the questionnaire section).
- Stop the recording, save the files, and name them using the de-identification rules below.

### De-identification
- Refer to participants by number only (P01, P02, …); never use real names.
- Recording / notes file name: `pilot_P01_2026-07-23.*`.
- Personal information must not be stored in the public repository.

---

## 2. Participant Task Sheet (participant-facing)

You'll be using a dashboard for hydro-ecology data. There are no trick questions — please think aloud as you go, and it's completely fine to get stuck.

### Task A — Produce an HEV result from a dataset

Scenario: You have a standard data workbook and you want to produce an HEV result and save it.

Please:
1. Find where to begin and choose what you want to do.
2. Upload the provided workbook.
3. Check whether the data was accepted, and say out loud what the screen is telling you.
4. Continue through the steps needed to build the dataset.
5. Produce the HEV result and download it.

*(Facilitator-only success criteria: the participant reaches a downloaded HEV output without being told which buttons to press, and can explain the validation / checkpoint messages in their own words.)*

### Task B — Refine the analysis and re-run

Scenario: You want to remove a site (or record) from the analysis and see how the result changes.

Please:
1. Exclude one record from the analysis.
2. Find where the excluded record is listed and explain why it's there.
3. Restore the record you just excluded.
4. Choose two variables and run the model, then read the result out loud.

*(Facilitator-only success criteria: the participant finds the exclusion log, understands it, can restore a record, and can read the model summary. If a feature isn't ready yet, record it as a blocker, not as a participant failure.)*

---

## 3. Observation + Timing Log (facilitator)

One copy per participant. One column per task.

| Item | Task A | Task B |
|---|---|---|
| Start time | | |
| End time | | |
| Time taken (minutes) | | |
| Completed independently? (yes / needed help / not completed) | | |
| Number of facilitator interventions | | |
| Wrong turns / backtracking | | |
| Error messages shown | | |
| Wording / terminology the participant couldn't understand | | |
| Key think-aloud quotes | | |

Extra notes:
- Questions the participant asked unprompted (verbatim):
- Clear emotional reactions (confusion, frustration, surprise):
- Issues the facilitator noticed on the spot:

---

## 4. Pilot-specific Checks

### Right after **Pilot 1**, check:
- Task completion and wrong turns.
- Understanding of Task / Stage / Start / Resume.
- Understanding of "Upload an already processed dataset" vs checkpoint download.
- Understanding of checkpoint and stale messages.
- Completion time and facilitator interventions.
- Error recovery.
- Completeness of the log, questionnaire, and recording.

### Right after **Pilot 2 **, check:
- Whether an earlier-goal output can be reused directly in a later goal.
- Whether processed-dataset download / re-upload is an understandable path across tasks and sessions.
- Whether the participant can tell apart blocked, warning, complete, and stale.
- Whether they understand WQ/RHS as optional enrichment.
- Whether error recovery works without developer help.
- Whether the overall duration is suitable for a formal session.

### Cross-pilot readiness questions (answer only these)
1. Are the tasks doable?
2. Are the key terms understood consistently?
3. Does the log capture the main behaviour?
4. Can the questionnaire be completed without obvious ambiguity?
5. Is there any systematic intervention?
6. Is the duration within the target range?

### **Pilot 3 **decision rule
- If the first two participants show the same major issue: Pilot 3 must verify the fix.
- If the first two are stable: use Pilot 3 for a different background / task order.
- If a fix has not passed testing yet: cancel Pilot 3 and restore system correctness first.

---

## 5. Questionnaire + Issue Triage

### After each task: SEQ (participant-facing)

> Overall, how difficult or easy was this task?
> 1 = Very difficult … 7 = Very easy
> Score: ___
> One thing that was unclear: ____________________

### At the end of the session: SUS (participant-facing, 10 items, 1 = Strongly disagree … 5 = Strongly agree)

1. I think that I would like to use this dashboard frequently.
2. I found the dashboard unnecessarily complex.
3. I thought the dashboard was easy to use.
4. I think that I would need support to be able to use this dashboard.
5. I found the various functions in this dashboard were well integrated.
6. I thought there was too much inconsistency in this dashboard.
7. I would imagine that most people would learn to use this dashboard very quickly.
8. I found the dashboard very cumbersome to use.
9. I felt very confident using the dashboard.
10. I needed to learn a lot of things before I could get going with this dashboard.

### Confidence rating (participant-facing)
> How confident are you that the result you produced is correct?
> 1 = Not at all … 5 = Very confident
> Score: ___

### Semi-structured interview (facilitator asks)
- Which step in the process was the least clear?
- Was there any word or message you weren't sure about?
- When an error or warning appeared, did you know what to do?
- If you did this again, what would you do first?
- Did anything surprise you?

### Issue triage sheet (facilitator fills in)

| Issue | Task | Evidence (screenshot / timestamp) | Severity | Fix? | Owner | Regression test |
|---|---|---|---|---|---|---|
| | | | Blocker / Major / Minor / Enhancement | | | |

Severity definitions:
- **Blocker:** cannot complete the task, wrong result, data corruption, no recovery → stop the pilot, fix immediately, and re-run the full test.
- **Major:** can complete but needs significant help, or the measurement is contaminated → fix, then re-run the affected task.
- **Minor:** does not affect completion or the primary measurement → record, and fix later if low-risk.
- **Enhancement:** new feature or preference → out of scope before this week's freeze.

Fix priority (in order): scientific correctness and data corruption → blockers that prevent completion or recovery → wording/log issues that would contaminate the primary metrics → accessibility blockers → other major usability issues. Do not act on pure aesthetic preferences or new feature requests, and do not change the study's primary metrics because of one participant's feedback.

---

## Session packet checklist (one per participant)
- [ ] Signed consent (stored in the authorised location, not in the public repository)
- [ ] Observation + timing log
- [ ] SEQ / SUS / confidence scores
- [ ] Interview notes
- [ ] Screen recording / observation notes (de-identified file name)
- [ ] This session's issues added to the issue triage sheet
