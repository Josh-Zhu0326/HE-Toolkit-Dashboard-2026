# Testing Checklist

This document provides a basic testing checklist for the HE Toolkit Dashboard.

## 1. Local Deployment Test

- [ ] R is installed
- [ ] RStudio is installed
- [ ] Required packages are installed
- [ ] `hetoolkit` is installed successfully
- [ ] Working directory is set to the dashboard folder
- [ ] Dashboard starts with:

```r
shiny::runApp(".")
```

- [ ] Browser opens the local dashboard successfully
- [ ] No critical error appears in the R console

## 2. General UI Test

- [ ] Dashboard loads successfully
- [ ] Navigation bar is visible
- [ ] Introduction page loads correctly
- [ ] Import datasets page loads correctly
- [ ] All visible buttons and inputs are usable
- [ ] No broken images, missing resources, or major layout issues are visible

## 3. Data Import Test

- [ ] Valid metadata input is accepted
- [ ] Empty metadata input shows an appropriate validation message
- [ ] Invalid metadata format is handled safely
- [ ] Valid CSV input can be processed
- [ ] Valid Excel input can be processed if supported
- [ ] Missing required columns are detected
- [ ] Duplicate site IDs are handled or reported
- [ ] Empty files do not crash the dashboard

## 4. Data Processing Test

- [ ] Imported datasets can be processed
- [ ] Joined dataset is generated correctly
- [ ] Missing values are handled appropriately
- [ ] Outliers or unsuitable records can be reviewed if supported
- [ ] Processing errors show clear user-facing messages

## 5. Visualisation Test

- [ ] Plots render correctly
- [ ] Tables render correctly
- [ ] Map visualisations render correctly if applicable
- [ ] Outputs update when inputs change
- [ ] Downloadable outputs work correctly

## 6. Error Handling Test

- [ ] Empty inputs do not crash the app
- [ ] Wrong file types are rejected or handled
- [ ] Missing data is reported clearly
- [ ] Console errors are recorded
- [ ] User-facing error messages are understandable for non-technical users

## 7. Regression Test Before Merging PR

Before merging a pull request, check:

- [ ] Dashboard still launches locally
- [ ] Existing pages still load
- [ ] Existing import workflow still works
- [ ] No new critical console errors appear
- [ ] Related issue acceptance criteria are satisfied
- [ ] PR description explains how the change was tested

## 8. Notes

Record known issues, limitations, or areas requiring future automated testing here.

```
```
