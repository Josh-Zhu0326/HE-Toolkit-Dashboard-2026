# Windows customer crash diagnostics

`03_Run_Dashboard_With_Diagnostics.cmd` launches the Dashboard under a
read-only diagnostic monitor. It is intended for reports such as a greyed-out
page, a spinner that does not finish, an R process that disappears, or a
suspected out-of-memory failure.

## Instructions for the customer

1. Close any HE Toolkit Dashboard window that is already running.
2. In the current Dashboard folder, double-click
   `03_Run_Dashboard_With_Diagnostics.cmd`.
3. Keep the diagnostic window open. Wait for the Dashboard to open in the
   browser, then follow the same workflow that produced the problem.
4. Leave the diagnostic window visible while **Pair biology and flow data** is
   running. It prints a time-stamped `STILL RUNNING` heartbeat while the
   monitored R process is alive, including elapsed time, R memory, available
   system memory and R thread count.
5. After the problem has occurred—or after the operation completes—click the
   diagnostic window and press **Q**. This stops that diagnostic Dashboard
   session and creates the evidence ZIP.
6. Reply to the existing support email and attach the ZIP whose full path is
   shown in yellow at the bottom of the window.

The ZIP is normally written beneath:

```text
%LOCALAPPDATA%\HE-Toolkit\diagnostics
```

Do not start `02_Setup_R_and_Run_Dashboard.cmd` at the same time; both launchers
use local port 3838. If the diagnostic reports missing R packages, run the
normal setup launcher once, close its Dashboard server, and then retry the
diagnostic launcher.

## What the customer messages mean

| Result or message | Meaning |
|---|---|
| `STILL RUNNING` | The monitored R process was alive at that exact time. |
| `BUSY_OR_UNRESPONSIVE` | The local web probe timed out while R remained alive. This can occur during a long synchronous calculation and is not proof of a crash. |
| `USER_STOPPED` | The customer pressed Q, or the test duration was deliberately limited. No crash is reported. |
| `NORMAL_EXIT` | R returned exit code 0. No crash is reported. |
| `UNEXPECTED_EXIT` | R stopped with a non-zero result, but the evidence does not prove a native or memory crash. The R logs should show an ordinary application error if one occurred. |
| `MEMORY_CRASH_CONFIRMED` | R exited and a memory allocation failure, matching Windows resource-exhaustion event, or memory-specific process exit code was found. |
| `NATIVE_CRASH_CONFIRMED` | R exited and a native failure exit code, native crash signature, or matching Windows crash event was found. |
| `DIAGNOSTIC_SETUP_FAILURE` | The monitor could not start the test—for example R was missing or port 3838 was already occupied. This is not reported as a Dashboard crash. |

The monitor deliberately does not classify a spinner, grey page, slow HTTP
response, low CPU usage, high memory pressure, or an R application error alone
as a native crash. Those observations remain in the evidence so support can
distinguish a long calculation, an application-level error, resource pressure
and a process crash.

## Evidence captured

The ZIP contains:

- operating-system, computer model, CPU, installed RAM, page-file and disk
  details;
- R version, architecture, locale, library paths and relevant package versions;
- SHA-256 identities of `global.R`, `server.R` and `ui.R` so the tested build
  can be identified;
- periodic R CPU, working/private memory, handle and thread counts;
- total/available system memory and aggregate Edge, Chrome or Firefox memory;
- the Dashboard R standard output and error streams; and
- matching Windows Application Error, Windows Error Reporting, .NET Runtime and
  resource-exhaustion events around the test window, when access is available.

The script does not deliberately copy uploaded Biology, Flow, WQ, RHS or
metadata files, browser history, credentials or email contents. Error messages
can still contain an uploaded filename or a rejected value. User-profile paths,
Windows user name and computer name are replaced with placeholders in text
logs before packaging.

If Windows restarts or the diagnostic window itself is forcibly closed before a
ZIP is made, the latest timestamped evidence folder under the diagnostics path
can be sent instead. `run-state.txt` and `monitor.log` show the last recorded
heartbeat.

## Support interpretation

Start with `diagnostic-summary.txt`, then correlate the last rows in
`process-samples.csv` with `r-stderr.log` and `windows-events.log`.

- Repeated heartbeats, rising CPU and a temporary failed web probe indicate a
  live synchronous calculation more strongly than a crash.
- Repeated heartbeats with near-zero CPU and no HTTP response indicate a live
  but waiting or blocked R process; this is a hang candidate, not a confirmed
  crash.
- An ordinary Shiny error followed by further heartbeats is an application
  error with a surviving R process.
- A stopped R process plus memory/native evidence produces a confirmed crash
  classification and a likely-cause statement in the summary.
