# HE Toolkit Dashboard

This is the Shiny dashboard for the HE Toolkit.

Original project: [EA-Hydroecology/HE-Toolkit-Dashboard](https://github.com/EA-Hydroecology/HE-Toolkit-Dashboard)

Project proposal: [Overleaf](https://www.overleaf.com/7427589993rsjqjnvgtrbh#92fa97)

## Repository Layout

- `global.R`, `ui.R`, and `server.R` are the Shiny application entry points.
- `R/` contains application helpers and workflow modules.
- `www/` contains runtime web assets used by Shiny.
- `data/examples/` contains downloadable example input data.
- `scripts/` contains project automation utilities.
- `tests/` contains automated tests, fixtures, and manual test material.
- [`docs/`](docs/README.md) contains project documentation organised by purpose.

## Launch Dashboard

From R or RStudio, set the working directory to the repository root and run:

```r
shiny::runApp(".")
```

Alternatively, launch the dashboard from a terminal:

```bash
R -e 'shiny::runApp(".", launch.browser = TRUE)'
```
