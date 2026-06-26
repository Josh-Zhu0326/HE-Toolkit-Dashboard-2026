# Week 3 Evidence

## Summary

Week 3 focused on turning the clarified project brief into a more concrete dashboard workflow, preparing an updated demo for client review, and collecting evidence from an end-to-end walkthrough of the existing dashboard. The team compared alternative workflow structures, documented technical questions about WQ/RHS integration and O:E ratio calculation, and prepared a think-aloud user evaluation plan.

The main outcome was a clearer evidence trail from client requirements to workflow design, implementation priorities, testing findings, and planned user evaluation.

## Client / Supervisor Communication

### Client Feedback

Thomas Aspin replied to the team's update about workflow options and the first updated dashboard demo on 22 June 2026. His response confirmed that:

- a Thursday afternoon meeting after 2pm would be possible;
- the team could use the meeting to discuss dashboard workflow options and the updated demo;
- WQ/RHS and O:E ratio questions could be covered either during the meeting or through written answers;
- technical clarification on WQ/RHS and O:E calculation should be recorded as requirements evidence.

The team's update to Thomas included:

- the GitHub repository link: <https://github.com/Josh-Zhu0326/HE-Toolkit-Dashboard-2026.git>;
- three possible dashboard workflow options based on HE Toolkit case studies and related research;
- a request for EA feedback on the workflow most suitable for EA users;
- confirmation that dashboard functionality had been updated according to current requirements;
- confirmation that several bugs found during implementation and testing had been fixed;
- preparation of the updated version as the first dashboard demo for review.

### Evidence Source

- `ProjectInfo/mail_summaries/2026-06-22_154041_dashboard-workflow-options-meeting.md`

### Items Still To Confirm

- Final meeting date and time.
- Meeting attendees.
- Thomas's preferred workflow option.
- Whether WQ/RHS and O:E questions were answered live, in writing, or both.
- Final technical decisions from the meeting.

## Meeting Notes

Formal Week 3 meeting notes have not yet been added to the repository.

The intended Week 3 meeting agenda should include:

- comparison of the three dashboard workflow options;
- review of updated dashboard functionality;
- review of current bug fixes and demo readiness;
- discussion of next development priorities;
- clarification of WQ/RHS handling;
- clarification of O:E ratio calculation and modelling expectations.

## Design and Prototype Evidence

Week 3 produced design evidence for the dashboard workflow and early user-facing structure.

Relevant local design materials:

- `../week03/3.5 Workflow Optimisation Options.pdf`

These materials should be used as evidence that the team considered alternative dashboard structures rather than implementing a single design without comparison.

Design questions considered during Week 3:

- Should the dashboard follow the HE Toolkit package workflow closely, or provide separate tools for each data type?
- How should non-coder users move from data upload/import to processing, joining, visualisation, and modelling?
- Where should WQ and RHS sit in the workflow?
- Which workflow best supports a guided step-by-step user journey?
- Which design would be easiest for EA users to understand during a demo?

## Requirements and Technical Clarification

Week 3 identified technical questions that affect the future data model and implementation scope.

Relevant local materials:

- `../week03/3.1 Shiny App.pdf`
- `../week03/3.7 WQ_RHS assumptions and questions list.pdf`

Key clarification areas:

- Whether WQ and RHS data should feed into the joined hydroecology dataset.
- How WQ/RHS data should be matched to biology and flow sites.
- Whether multiple O:E calculation methods should be retained.
- Whether O:E calculations using only biology and flow data, or also WQ/RHS, can be implemented using the current HE Toolkit.
- Whether some O:E and modelling behaviour requires further confirmation from EA before implementation.

Decision status:

- WQ/RHS and O:E questions were prepared for Thomas.
- Final answers and resulting implementation decisions still need to be recorded after the meeting or written response.

## Background Research

Week 3 included background research on freshwater monitoring and improvement.

Relevant local material:

- `../week03/3.2 New Zealand Freshwater Monitoring and Improvement.md`

This research should only be used in the final report where it directly supports discussion of user needs, environmental monitoring context, workflow design, or evaluation criteria.

## Implementation and GitHub Evidence

Relevant repository setup and documentation commits available by Week 3:

- `4bc91bb` - Initial commit
- `e2e7956` - Add project files
- `21c6d7e` - update readme
- `62bf938` - Set up GitHub workflow templates and testing checklist
- `66de9d8` - Merge pull request #2 from `setup/github-workflow-and-testing-docs`
- `5845070` - Add week 1 project evidence
- `33b9ec1` - Merge pull request #4 from `docs/week-1-evidence`
- `a79c1ab` - Add existing dashboard audit and evidences
- `2f74a1c` - Merge pull request #5 from `docs/existing-dashboard-audit`

Relevant repository evidence:

- GitHub repository: <https://github.com/Josh-Zhu0326/HE-Toolkit-Dashboard-2026.git>
- Existing dashboard audit: `HE-Toolkit-Dashboard-2026/docs/existing-dashboard-audit.md`
- Testing checklist: `HE-Toolkit-Dashboard-2026/docs/testing-checklist.md`
- Picture evidence folder: `HE-Toolkit-Dashboard-2026/docs/picture evidence/`

Items still to link once available:

- Week 3 implementation issues.
- Pull requests for Week 3 dashboard changes.
- Code review comments.
- Merge records for Week 3 feature branches.

## Testing Records

Week 3 included a functional walkthrough of the dashboard using valid demo data. The walkthrough tested the main hydroecological workflow:

1. Import metadata.
2. Import biology data.
3. Import environmental data.
4. Import flow data.
5. Review environmental PCA and flow completeness views.
6. Review imported sites on the map.
7. Run RICT predictions.
8. Calculate O:E ratios.
9. Impute missing flow data.
10. Import additional donor flow data.
11. Re-run flow imputation.
12. Calculate flow statistics.
13. Pair biology and flow data.
14. Generate an HEV plot.
15. Download HEV outputs in PDF, PNG, and JPEG formats.

### Test Results

The walkthrough confirmed that the existing dashboard can complete the core workflow from import through HEV output generation when valid demo data and required dependencies are available.

Important results recorded in `docs/existing-dashboard-audit.md`:

- Biology data imported successfully in approximately 7 seconds.
- Environmental data imported successfully in approximately 1 second.
- Flow data imported successfully in approximately 6 seconds.
- RICT predictions generated successfully in approximately 2 seconds.
- O:E ratio results generated successfully in less than 1 second.
- Flow statistics calculation completed successfully in approximately 37 seconds.
- Biology and flow data pairing completed successfully in approximately 3 seconds.
- HEV plot generation initially failed because `ggnewscale` was missing locally.
- After installing `ggnewscale`, HEV plot generation and PDF/PNG/JPEG downloads passed.

### Issues Found

- Invalid additional donor-site input can trigger a raw `fread()` error.
- Some errors can leave the application in a persistent loading state.
- Missing local dependencies can produce raw R package errors in the dashboard.
- Long calculations need clearer progress feedback.
- Long warning messages containing many site IDs are difficult to read.
- Some empty result areas need clearer placeholder guidance.

### Priority Recommendations

High-priority recommendations from the audit:

1. Validate donor-site input before passing it to `fread()`.
2. Ensure the application always exits the loading state after an error.
3. Replace raw R errors and local file paths with user-friendly messages.
4. Provide clearer dependency installation or restoration instructions.

## User Evaluation Planning

Week 3 included preparation for a think-aloud user evaluation.

Relevant local material:

- `../week03/3.3 Think-aloud plan.docx`

The plan should support later evaluation evidence by defining:

- participant type;
- task sequence;
- observation approach;
- success criteria;
- notes to collect during testing;
- how findings will feed into dashboard improvements.

Items still to confirm:

- Number of testers.
- Tester profile.
- Whether EA staff or representative users will participate.
- Ethics or approval constraints for user testing.
- Final task script and data used during testing.

## Documentation Contributions

Week 3 documentation evidence includes:

- workflow option comparison;
- Feishu/Shiny app design material;
- WQ/RHS and O:E assumptions and question list;
- end-to-end dashboard audit;
- picture evidence from dashboard testing;
- think-aloud evaluation planning.

These documents support the final report sections on:

- requirements refinement;
- design and prototyping;
- implementation process;
- evaluation and testing;
- project management and iterative client feedback.

## Outcomes

- The team prepared three dashboard workflow options for client comparison.
- The team prepared the first updated dashboard demo for review.
- The team identified technical questions requiring EA clarification.
- The team recorded an end-to-end dashboard audit with test outcomes.
- The team identified high-priority reliability and usability improvements.
- The team prepared material for later user evaluation.

## Next Steps

- Add formal Week 3 meeting notes after the client/supervisor meeting.
- Record Thomas's preferred workflow option and technical answers.
- Convert WQ/RHS and O:E decisions into GitHub issues with acceptance criteria.
- Link Week 3 implementation PRs and commits once available.
- Fix high-priority validation, dependency, loading-state, and error-message issues.
- Run a retest after fixes and record the results.
- Finalise the think-aloud task script and tester plan.
