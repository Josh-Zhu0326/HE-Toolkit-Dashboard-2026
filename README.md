# HE Toolkit Dashboard

This is the Shiny dashboard for the HE Toolkit.

Original project: [EA-Hydroecology/HE-Toolkit-Dashboard](https://github.com/EA-Hydroecology/HE-Toolkit-Dashboard)

Project proposal: [Overleaf](https://www.overleaf.com/7427589993rsjqjnvgtrbh#92fa97)

## Windows Setup and Launch

Windows users can set up and start the Dashboard without RStudio or Git:

1. Download or extract the Dashboard folder.
2. Double-click `02_Setup_R_and_Run_Dashboard.cmd`.
3. The launcher checks for a working installation of R.
4. Required Dashboard packages are checked and prepared.
5. A startup check confirms that the application can load.
6. The Dashboard starts locally on port 3838.
7. The default browser opens automatically.

The same launcher is used for both first-time setup and normal later use:

- **First use:** setup may take longer while R or required packages are prepared.
- **Later use:** double-click the same file. Dependencies that are already available
  at the verified versions are reused rather than reinstalled unnecessarily.

For normal use, run `02_Setup_R_and_Run_Dashboard.cmd`, then use the Dashboard.
You do not need to run the stop script after each session.

Windows is the supported platform for this CMD launcher. RStudio is not required,
and Git is not required for normal Dashboard startup. Internet access may be
required during initial setup so that R and packages can be obtained from CRAN
and GitHub. Automatic R installation relies on available Windows tooling such as
`winget`. Managed organisation devices may block automatic installation through
software-installation permissions, firewall or proxy rules, or restricted CRAN
or GitHub access. The launcher does not provide a complete offline installation
and does not guarantee installation without user or administrator permission.

### Setup and update files

- `02_Setup_R_and_Run_Dashboard.cmd` is the normal customer setup and launch
  tool. Use it for the first launch and each later launch.
- `01_Update_Dashboard.cmd` is an optional repository download/update tool. It
  is not required each time the Dashboard starts. The updater may require Git
  and network access; users who downloaded or extracted a ZIP do not need to run
  it before normal Dashboard use.

### Logs and troubleshooting

Setup, startup-check, and server logs are stored under:

```text
%LOCALAPPDATA%\HE-Toolkit\logs
```

If setup or startup fails, the CMD window displays the relevant log path.

For an intermittent grey screen, persistent loading spinner, suspected memory
failure, or disappearing R process, close the normal Dashboard server and run
`03_Run_Dashboard_With_Diagnostics.cmd`. Its visible monitor distinguishes a
live but busy R process from a confirmed process crash and creates an email-ready
diagnostic ZIP under `%LOCALAPPDATA%\HE-Toolkit\diagnostics`. See the
[Windows customer diagnostic guide](docs/operations/windows-customer-crash-diagnostics.md).

- **R installation or detection fails:** review the CMD message and displayed
  log path, and check whether automatic software installation is permitted on
  the machine.
- **Dependency installation fails:** check internet connectivity and whether
  firewall or proxy rules allow access to CRAN and GitHub.
- **Dashboard startup fails:** open the log path displayed by the launcher for
  the detailed startup or server messages.

### If the Dashboard says port 3838 is already in use

If `02_Setup_R_and_Run_Dashboard.cmd` displays:

> `[ERROR] Port 3838 is already in use. Another Dashboard instance or program may already be running.`

this usually means a previous Dashboard server is still running in the
background. Closing its browser tab or window does not necessarily stop the
server.

Only in this situation:

1. Run `04_Stop_Dashboard.cmd`. It safely stops only a Dashboard process
   previously recorded by the HE Toolkit launcher.
2. Wait for confirmation that the Dashboard has stopped.
3. Run `02_Setup_R_and_Run_Dashboard.cmd` again.

If `02_Setup_R_and_Run_Dashboard.cmd` starts normally without the port-3838
error, you do not need to run `04_Stop_Dashboard.cmd`.

## Repository Layout

- `global.R`, `ui.R`, and `server.R` are the Shiny application entry points.
- `R/` contains application helpers and workflow modules.
- `www/` contains runtime web assets used by Shiny.
- `data/examples/` contains downloadable example input data.
- `scripts/` contains project automation utilities.
- `tests/` contains automated tests, fixtures, and manual test material.
- [`docs/`](docs/README.md) contains project documentation organised by purpose.

## Developer / Manual Launch

From R or RStudio, set the working directory to the repository root and run:

```r
shiny::runApp(".")
```

Alternatively, launch the dashboard from a terminal:

```bash
R -e 'shiny::runApp(".", launch.browser = TRUE)'
```
