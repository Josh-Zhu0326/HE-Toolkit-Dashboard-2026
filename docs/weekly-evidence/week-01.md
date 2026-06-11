# Week 1 Evidence

## Summary

Week 1 focused on clarifying the project direction with the client, reviewing the existing HE Toolkit Dashboard scope, and preparing an initial proposal draft. The team used client feedback from Thomas Aspin to identify the intended user workflow, likely dashboard improvements, and early project boundaries.

The main outcome was an initial proposal draft dated 10 June 2026. The proposal positions the project as an extension of the existing HE Toolkit Dashboard rather than a rewrite of the underlying `hetoolkit` R package.

## Client / Supervisor Communication

### Client Feedback

Thomas Aspin replied to the team's clarification questions on 8 June 2026. The response helped define several important project assumptions:

- The dashboard should follow the same general workflow as the underlying `hetoolkit` R package.
- The expected workflow is site list upload, data import, data processing and joining, data visualisation, and data modelling.
- The current dashboard does not yet include the final modelling stage.
- The main users are expected to include non-coders, so the dashboard should support a guided step-by-step workflow.
- Users may start with site IDs for publicly available EA data and CSV or Excel files for local data.
- WQ and RHS functionality should feed into the joined dataset and modelling workflow rather than remain isolated tools.
- Local file upload support should focus on CSV and Excel files.
- Modelling outputs should prioritise simple regression plots, model summaries, downloadable results, and potentially plain-English interpretation if accuracy can be checked.
- The team should create a new GitHub repository by cloning the existing dashboard repository.

### Supervisor Communication

The team arranged a follow-up meeting with the supervisor based on the initial proposal direction.

Details to confirm:

- Meeting date: 15 June 2026
- Meeting participants: supervisor, Bo Sun, Benyu Zhu, Lin Zhu, Yutong Liu, and Zhaohang He
- Main agenda: To be confirmed
- Outcome of the meeting: To be confirmed after the meeting

## Meeting Notes

No formal meeting notes have been recorded in this repository yet.

Planned discussion points for the next supervisor meeting:

- Confirm whether the proposed project scope is realistic for the available time.
- Confirm which dashboard improvements should be treated as highest priority.
- Confirm how much modelling functionality should be included in the first implementation phase.
- Confirm whether user evaluation will require ethics approval or a limited evaluation approach.
- Confirm how evidence, issues, pull requests, and weekly documentation should be maintained in GitHub.

## Design Decisions

- Use `HE-Toolkit-Dashboard-2026` as the main project repository for dashboard development.
- Treat `HE-Toolkit-Shiny-UI-APEM-LTD` as the `hetoolkit` package dependency rather than the main dashboard development repository.
- Extend the existing Shiny dashboard instead of rebuilding the whole application from scratch.
- Do not rewrite the underlying `hetoolkit` R package unless a specific package-level change becomes necessary.
- Prioritise a guided workflow for non-coding users.
- Keep hosting, authentication, and production security as later recommendations after core dashboard content has been reviewed and tested.

## Documentation Contributions

- Reviewed the existing project scope document for the HE Toolkit Dashboard.
- Reviewed Thomas Aspin's email response to the team's clarification questions.
- Prepared an initial proposal draft covering:
  - project background and motivation;
  - project aim and objectives;
  - scope and boundaries;
  - related work;
  - planned implementation approach;
  - functional modules;
  - UI/UX, reliability, and documentation plans;
  - evaluation approach;
  - time plan.

## Testing Records

No implementation testing was carried out in Week 1 because the focus was project clarification, planning, and proposal drafting.

Testing-related requirements identified during planning:

- The dashboard should be tested locally using `shiny::runApp(".")`.
- File upload should be tested with valid and invalid CSV/Excel inputs.
- Data import and joining should be tested with normal, missing, and invalid inputs.
- Error messages should be understandable for non-technical users.
- Future pull requests should include evidence of relevant manual or automated testing.

## GitHub Evidence

Relevant repository setup commits from 8 June 2026:

- `4bc91bb` - Initial commit
- `e2e7956` - Add project files
- `21c6d7e` - update readme

GitHub issues and pull requests to link once created:

- Issue: #3 - [TASK] Record Week 1 project evidence
- Pull Request: To be created

## Source Materials Reviewed

The following local source materials were reviewed and summarised. Sensitive communication content should not be copied into the repository verbatim unless approved.

- `ProjectInfo/RE_ MSc Computer Science projects - agreement reminder.eml`
- `ProjectInfo/HE Toolkit dashboard summer 2026 project scope.docx`
- `proposal.pdf`

## Outcomes

- The team clarified the intended dashboard workflow and user needs from client feedback.
- The team identified the main repository for project work.
- The team produced an initial proposal draft.
- The team prepared to discuss scope, priorities, and feasibility with the supervisor.
- The team identified early testing and documentation needs for later development.

## Next Steps

- Confirm the proposal scope with the supervisor.
- Convert the proposal priorities into GitHub issues.
- Add project workflow and QA documentation to the repository.
- Define first implementation tasks for the dashboard.
- Start recording weekly evidence in `docs/weekly-evidence/`.
