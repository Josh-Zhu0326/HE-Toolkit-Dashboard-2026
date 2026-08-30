[CmdletBinding()]
param(
  [string]$ProjectDir = (Split-Path -Parent $PSScriptRoot),
  [ValidateRange(1, 65535)]
  [int]$Port = 3838,
  [ValidateRange(1, 60)]
  [int]$SampleIntervalSeconds = 5,
  [ValidateRange(2, 120)]
  [int]$HealthProbeIntervalSeconds = 15,
  [switch]$NoBrowser,
  [ValidateRange(0, 86400)]
  [int]$MaxRuntimeSeconds = 0,
  [string]$RscriptPath = ""
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'dashboard_diagnostic_helpers.ps1')

$ProjectDir = [System.IO.Path]::GetFullPath($ProjectDir)
$diagnosticRoot = Join-Path $env:LOCALAPPDATA 'HE-Toolkit\diagnostics'
$runStamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$runName = "HE-Toolkit-Diagnostic-$runStamp"
$runDir = Join-Path $diagnosticRoot $runName
$zipPath = Join-Path $diagnosticRoot ($runName + '.zip')

New-Item -ItemType Directory -Path $runDir -Force | Out-Null

$monitorLogPath = Join-Path $runDir 'monitor.log'
$sampleCsvPath = Join-Path $runDir 'process-samples.csv'
$environmentPath = Join-Path $runDir 'environment.txt'
$stdoutPath = Join-Path $runDir 'r-stdout.log'
$stderrPath = Join-Path $runDir 'r-stderr.log'
$eventPath = Join-Path $runDir 'windows-events.log'
$summaryPath = Join-Path $runDir 'diagnostic-summary.txt'
$statePath = Join-Path $runDir 'run-state.txt'
$emailInstructionsPath = Join-Path $runDir 'EMAIL_THIS_ZIP.txt'

$script:process = $null
$script:requestedStop = $false
$script:runStarted = Get-Date
$script:runEnded = $null
$script:outcomeStatus = 'DIAGNOSTIC_SETUP_FAILURE'
$script:outcomeMessage = 'The diagnostic wrapper did not finish initialisation.'
$script:likelyCause = 'Diagnostic initialisation did not complete.'
$script:exitCode = $null
$script:exitCodeHex = ''
$script:isCrash = $false
$script:peakRWorkingSetMB = 0.0
$script:peakRPrivateMB = 0.0
$script:peakRThreads = 0
$script:peakBrowserWorkingSetMB = 0.0
$script:minimumSystemAvailableMB = [double]::PositiveInfinity
$script:longestUnresponsiveSamples = 0
$script:currentUnresponsiveSamples = 0
$script:unresponsiveAfterReadySamples = 0
$script:unresponsiveAfterReadyCpuTotal = 0.0
$script:lastHealthState = 'NOT_STARTED'
$script:lastHealthDetail = 'No health probe has run.'
$script:lastHeartbeat = ''
$script:lastRPrivateMB = ''
$script:lastRCPUPercent = 0.0
$script:runtimeAssessment = 'No process samples were recorded.'
$script:rscriptResolved = ''
$script:rVersion = ''
$script:rLibrary = ''
$script:diagnosticError = ''

function Write-RunMessage {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Message,
    [ValidateSet('Info', 'Running', 'Warning', 'Error', 'Success')]
    [string]$Level = 'Info'
  )

  $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  $line = "[$timestamp] $Message"
  Add-Content -LiteralPath $monitorLogPath -Value $line -Encoding UTF8

  $colour = switch ($Level) {
    'Running' { 'Green' }
    'Warning' { 'Yellow' }
    'Error' { 'Red' }
    'Success' { 'Cyan' }
    default { 'Gray' }
  }
  Write-Host $line -ForegroundColor $colour
}

function Set-RunState {
  param(
    [string]$Status,
    [string]$LastHeartbeat = '',
    [string]$LastHttpState = '',
    [string]$LastPrivateMemoryMB = ''
  )

  @(
    "Status=$Status"
    "RunId=$runName"
    "Started=$($script:runStarted.ToString('o'))"
    "LastHeartbeat=$LastHeartbeat"
    "LastHttpState=$LastHttpState"
    "LastRPrivateMemoryMB=$LastPrivateMemoryMB"
    "MonitorProcessId=$PID"
    "RProcessId=$(if ($null -ne $script:process) { $script:process.Id } else { '' })"
  ) | Set-Content -LiteralPath $statePath -Encoding UTF8
}

function Find-RscriptExecutable {
  if (-not [string]::IsNullOrWhiteSpace($RscriptPath)) {
    if (Test-Path -LiteralPath $RscriptPath -PathType Leaf) {
      return (Resolve-Path -LiteralPath $RscriptPath).Path
    }
    throw "The supplied Rscript path does not exist: $RscriptPath"
  }

  $command = Get-Command Rscript.exe -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($null -ne $command) {
    return $command.Source
  }

  $candidates = New-Object System.Collections.Generic.List[string]
  foreach ($root in @(
      (Join-Path $env:ProgramFiles 'R'),
      (Join-Path $env:LOCALAPPDATA 'Programs\R')
    )) {
    if (Test-Path -LiteralPath $root -PathType Container) {
      Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        ForEach-Object { $candidates.Add((Join-Path $_.FullName 'bin\Rscript.exe')) }
    }
  }

  foreach ($registryPath in @(
      'HKLM:\SOFTWARE\R-core\R',
      'HKLM:\SOFTWARE\WOW6432Node\R-core\R',
      'HKCU:\SOFTWARE\R-core\R'
    )) {
    if (Test-Path -LiteralPath $registryPath) {
      $installPath = (Get-ItemProperty -LiteralPath $registryPath -ErrorAction SilentlyContinue).InstallPath
      if (-not [string]::IsNullOrWhiteSpace($installPath)) {
        $candidates.Add((Join-Path $installPath 'bin\Rscript.exe'))
      }
    }
  }

  return $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
}

function Resolve-RscriptWorkerExecutable {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
  $containingDirectory = Split-Path -Parent $resolvedPath
  if ((Split-Path -Leaf $containingDirectory) -ieq 'bin') {
    $architectureDirectory = if ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'i386' }
    $workerCandidate = Join-Path $containingDirectory "$architectureDirectory\Rscript.exe"
    if (Test-Path -LiteralPath $workerCandidate -PathType Leaf) {
      return (Resolve-Path -LiteralPath $workerCandidate).Path
    }
  }

  return $resolvedPath
}

function Invoke-RscriptText {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  # Some managed Windows installations emit locale warnings to stderr before R
  # starts. Redirect the two native streams to temporary files so PowerShell's
  # native-stderr adapter cannot turn a warning into a diagnostic exception.
  $commandId = [Guid]::NewGuid().ToString('N')
  $commandStdoutPath = Join-Path $runDir "r-command-$commandId.stdout.tmp"
  $commandStderrPath = Join-Path $runDir "r-command-$commandId.stderr.tmp"
  $previousErrorActionPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    & $script:rscriptResolved @Arguments 1> $commandStdoutPath 2> $commandStderrPath
    $nativeExitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }

  $stdoutText = if (Test-Path -LiteralPath $commandStdoutPath) {
    Get-Content -LiteralPath $commandStdoutPath -Raw -ErrorAction SilentlyContinue
  } else { '' }
  $stderrText = if (Test-Path -LiteralPath $commandStderrPath) {
    Get-Content -LiteralPath $commandStderrPath -Raw -ErrorAction SilentlyContinue
  } else { '' }
  $output = @($stdoutText, $stderrText) -join "`r`n"
  Remove-Item -LiteralPath $commandStdoutPath, $commandStderrPath -Force -ErrorAction SilentlyContinue

  return [pscustomobject]@{
    ExitCode = $nativeExitCode
    Output = $output
  }
}

function Write-EnvironmentSnapshot {
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add('HE Toolkit Dashboard customer diagnostic environment')
  $lines.Add("Captured: $((Get-Date).ToString('o'))")
  $lines.Add("Diagnostic script version: 1.0")
  $lines.Add("PowerShell: $($PSVersionTable.PSVersion) $($PSVersionTable.PSEdition)")
  $lines.Add("Project directory: $ProjectDir")
  $lines.Add("Rscript: $($script:rscriptResolved)")
  $lines.Add("R version: $($script:rVersion)")
  $lines.Add("R library: $($script:rLibrary)")
  $lines.Add("Logical processors reported by .NET: $([Environment]::ProcessorCount)")

  foreach ($sourceFileName in @('global.R', 'server.R', 'ui.R')) {
    $sourceFilePath = Join-Path $ProjectDir $sourceFileName
    if (Test-Path -LiteralPath $sourceFilePath -PathType Leaf) {
      try {
        $sourceFile = Get-Item -LiteralPath $sourceFilePath
        $sourceHash = (Get-FileHash -LiteralPath $sourceFilePath -Algorithm SHA256).Hash
        $lines.Add("Dashboard file $sourceFileName modified/hash: $($sourceFile.LastWriteTime.ToString('o')) / $sourceHash")
      } catch {
        $lines.Add("Dashboard file identity unavailable for ${sourceFileName}: $($_.Exception.Message)")
      }
    }
  }

  try {
    $computer = Get-CimInstance Win32_ComputerSystem
    $lines.Add("Computer manufacturer: $($computer.Manufacturer)")
    $lines.Add("Computer model: $($computer.Model)")
    $lines.Add("Installed RAM MB: $([math]::Round($computer.TotalPhysicalMemory / 1MB, 1))")
  } catch {
    $lines.Add("Computer information unavailable: $($_.Exception.Message)")
  }

  try {
    $os = Get-CimInstance Win32_OperatingSystem
    $lines.Add("Operating system: $($os.Caption)")
    $lines.Add("OS version/build: $($os.Version) / $($os.BuildNumber)")
    $lines.Add("OS architecture: $($os.OSArchitecture)")
    $lines.Add("Total visible memory MB: $([math]::Round($os.TotalVisibleMemorySize / 1024, 1))")
    $lines.Add("Available memory at start MB: $([math]::Round($os.FreePhysicalMemory / 1024, 1))")
    $lines.Add("Last boot: $($os.LastBootUpTime)")
  } catch {
    $lines.Add("Operating-system information unavailable: $($_.Exception.Message)")
  }

  try {
    $processors = Get-CimInstance Win32_Processor
    foreach ($processor in $processors) {
      $lines.Add("Processor: $($processor.Name)")
      $lines.Add("Processor cores/logical processors: $($processor.NumberOfCores) / $($processor.NumberOfLogicalProcessors)")
    }
  } catch {
    $lines.Add("Processor information unavailable: $($_.Exception.Message)")
  }

  try {
    $pageFiles = Get-CimInstance Win32_PageFileUsage
    foreach ($pageFile in $pageFiles) {
      $lines.Add("Page file allocation/current/peak MB: $($pageFile.AllocatedBaseSize) / $($pageFile.CurrentUsage) / $($pageFile.PeakUsage)")
    }
  } catch {
    $lines.Add("Page-file information unavailable: $($_.Exception.Message)")
  }

  try {
    $projectDrive = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f ([System.IO.Path]::GetPathRoot($ProjectDir).TrimEnd('\')))
    if ($null -ne $projectDrive) {
      $lines.Add("Project-drive free/total GB: $([math]::Round($projectDrive.FreeSpace / 1GB, 1)) / $([math]::Round($projectDrive.Size / 1GB, 1))")
    }
  } catch {
    $lines.Add("Disk information unavailable: $($_.Exception.Message)")
  }

  $lines | Set-Content -LiteralPath $environmentPath -Encoding UTF8
}

function Test-PortAvailable {
  param([int]$LocalPort)

  try {
    $listener = Get-NetTCPConnection -LocalPort $LocalPort -State Listen -ErrorAction SilentlyContinue
    return $null -eq $listener
  } catch {
    $tcpListener = $null
    try {
      $tcpListener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $LocalPort)
      $tcpListener.Start()
      return $true
    } catch {
      return $false
    } finally {
      if ($null -ne $tcpListener) {
        $tcpListener.Stop()
      }
    }
  }
}

function Get-SystemMemorySnapshot {
  try {
    $os = Get-CimInstance Win32_OperatingSystem
    return [pscustomobject]@{
      TotalMB = [math]::Round($os.TotalVisibleMemorySize / 1024, 1)
      AvailableMB = [math]::Round($os.FreePhysicalMemory / 1024, 1)
    }
  } catch {
    return [pscustomobject]@{ TotalMB = 0.0; AvailableMB = 0.0 }
  }
}

function Get-BrowserMemorySnapshot {
  $browserProcesses = @(Get-Process -Name 'msedge', 'chrome', 'firefox' -ErrorAction SilentlyContinue)
  if ($browserProcesses.Count -eq 0) {
    return [pscustomobject]@{ Count = 0; WorkingSetMB = 0.0; PrivateMB = 0.0 }
  }

  return [pscustomobject]@{
    Count = $browserProcesses.Count
    WorkingSetMB = [math]::Round(($browserProcesses | Measure-Object WorkingSet64 -Sum).Sum / 1MB, 1)
    PrivateMB = [math]::Round(($browserProcesses | Measure-Object PrivateMemorySize64 -Sum).Sum / 1MB, 1)
  }
}

function Test-DashboardHealth {
  param([string]$Url)

  $healthUrl = $Url.TrimEnd('/') + '/shared/shiny.min.js'
  $stopwatch = [Diagnostics.Stopwatch]::StartNew()
  try {
    # Probe a static Shiny asset instead of requesting the full Dashboard UI.
    # The full UI is expensive to construct and repeated root requests can add
    # workload precisely when the app is already busy.
    $response = Invoke-WebRequest -UseBasicParsing -Uri $healthUrl -TimeoutSec 2 -MaximumRedirection 3
    $stopwatch.Stop()
    if ($response.StatusCode -eq 200 -and $response.Content.Length -gt 0) {
      return [pscustomobject]@{
        State = 'RESPONSIVE'
        Detail = "Static Shiny asset returned HTTP 200 in $($stopwatch.ElapsedMilliseconds) ms."
      }
    }
    return [pscustomobject]@{
      State = "HTTP_$($response.StatusCode)"
      Detail = "Static Shiny asset returned HTTP $($response.StatusCode) in $($stopwatch.ElapsedMilliseconds) ms."
    }
  } catch {
    $stopwatch.Stop()
    return [pscustomobject]@{
      State = 'BUSY_OR_UNRESPONSIVE'
      Detail = "Health probe failed after $($stopwatch.ElapsedMilliseconds) ms: $($_.Exception.Message)"
    }
  }
}

function Add-ProcessSample {
  param([pscustomobject]$Sample)

  if (-not (Test-Path -LiteralPath $sampleCsvPath)) {
    $Sample | Export-Csv -LiteralPath $sampleCsvPath -NoTypeInformation -Encoding UTF8
  } else {
    $Sample | Export-Csv -LiteralPath $sampleCsvPath -NoTypeInformation -Encoding UTF8 -Append
  }
}

function Get-RelevantWindowsEvents {
  param(
    [datetime]$From,
    [datetime]$To
  )

  $events = New-Object System.Collections.Generic.List[object]
  try {
    $applicationEvents = Get-WinEvent -FilterHashtable @{
      LogName = 'Application'
      StartTime = $From
      EndTime = $To
    } -ErrorAction Stop | Where-Object {
      $_.ProviderName -in @('Application Error', 'Windows Error Reporting', '.NET Runtime') -and
      $_.Message -match '(?i)(Rscript\.exe|Rterm\.exe|\\R\.exe|msedge\.exe|chrome\.exe|firefox\.exe)'
    }
    foreach ($event in $applicationEvents) { $events.Add($event) }
  } catch {
    Add-Content -LiteralPath $eventPath -Value "Application event-log query failed: $($_.Exception.Message)" -Encoding UTF8
  }

  try {
    $resourceEvents = Get-WinEvent -FilterHashtable @{
      LogName = 'System'
      ProviderName = 'Microsoft-Windows-Resource-Exhaustion-Detector'
      StartTime = $From
      EndTime = $To
    } -ErrorAction Stop
    foreach ($event in $resourceEvents) { $events.Add($event) }
  } catch {
    Add-Content -LiteralPath $eventPath -Value "Resource-exhaustion event-log query unavailable: $($_.Exception.Message)" -Encoding UTF8
  }

  foreach ($event in ($events | Sort-Object TimeCreated)) {
    @(
      "Time: $($event.TimeCreated.ToString('o'))"
      "Log/Provider/Event ID: $($event.LogName) / $($event.ProviderName) / $($event.Id)"
      "Level: $($event.LevelDisplayName)"
      "Message: $($event.Message)"
      '---'
    ) | Add-Content -LiteralPath $eventPath -Encoding UTF8
  }

  return $events.ToArray()
}

function Protect-DiagnosticTextFiles {
  Get-ChildItem -LiteralPath $runDir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in @('.txt', '.log') } |
    ForEach-Object {
      try {
        $content = Get-Content -LiteralPath $_.FullName -Raw -ErrorAction Stop
        $safeContent = ConvertTo-SafeDiagnosticText -Text $content
        Set-Content -LiteralPath $_.FullName -Value $safeContent -Encoding UTF8
      } catch {
        # A diagnostic file should never prevent the remaining evidence from being packaged.
      }
    }
}

function Complete-DiagnosticPackage {
  $script:runEnded = Get-Date
  $duration = $script:runEnded - $script:runStarted
  $minimumAvailable = if ([double]::IsPositiveInfinity($script:minimumSystemAvailableMB)) {
    'Not recorded'
  } else {
    [math]::Round($script:minimumSystemAvailableMB, 1)
  }

  @(
    'HE Toolkit Dashboard diagnostic summary'
    "Outcome: $($script:outcomeStatus)"
    "Customer message: $($script:outcomeMessage)"
    "Likely cause: $($script:likelyCause)"
    "Runtime assessment: $($script:runtimeAssessment)"
    "Started: $($script:runStarted.ToString('o'))"
    "Ended: $($script:runEnded.ToString('o'))"
    "Duration seconds: $([math]::Round($duration.TotalSeconds, 1))"
    "R exit code: $(if ($null -eq $script:exitCode) { 'Not available' } else { $script:exitCode })"
    "R exit code hex: $($script:exitCodeHex)"
    "Last HTTP state: $($script:lastHealthState)"
    "Last HTTP detail: $($script:lastHealthDetail)"
    "Peak R working set MB: $([math]::Round($script:peakRWorkingSetMB, 1))"
    "Peak R private memory MB: $([math]::Round($script:peakRPrivateMB, 1))"
    "Peak R thread count: $($script:peakRThreads)"
    "Peak aggregate browser working set MB: $([math]::Round($script:peakBrowserWorkingSetMB, 1))"
    "Minimum system-available memory MB: $minimumAvailable"
    "Longest unresponsive sample sequence: $($script:longestUnresponsiveSamples)"
    "Diagnostic wrapper error: $($script:diagnosticError)"
    ''
    'Interpretation:'
    '- RUNNING messages prove that the monitored R process was alive at that time.'
    '- BUSY_OR_UNRESPONSIVE means the web check timed out while R was alive; it is not by itself proof of a crash.'
    '- MEMORY_CRASH_CONFIRMED or NATIVE_CRASH_CONFIRMED is only reported after the R process exits and matching evidence is found.'
    '- UNEXPECTED_EXIT means the process stopped, but the available evidence does not prove a native crash.'
  ) | Set-Content -LiteralPath $summaryPath -Encoding UTF8

  @(
    'Please reply to the existing HE Toolkit support email and attach the ZIP file that contains this note.'
    ''
    'The package contains:'
    '- Windows, hardware, PowerShell and R environment details'
    '- sampled R memory, CPU and thread counts'
    '- aggregate browser memory totals (not browsing history)'
    '- Dashboard R console output'
    '- relevant Windows crash or resource-exhaustion events, when available'
    ''
    'The diagnostic does not copy uploaded Biology, Flow, WQ, RHS or metadata files, and it does not collect browser history.'
  ) | Set-Content -LiteralPath $emailInstructionsPath -Encoding UTF8

  Set-RunState `
    -Status $script:outcomeStatus `
    -LastHeartbeat $script:lastHeartbeat `
    -LastHttpState $script:lastHealthState `
    -LastPrivateMemoryMB $script:lastRPrivateMB
  Protect-DiagnosticTextFiles

  if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
  }
  Compress-Archive -Path (Join-Path $runDir '*') -DestinationPath $zipPath -CompressionLevel Optimal
  return $zipPath
}

Clear-Host
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ' HE Toolkit Dashboard - Customer Crash Diagnostic' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Keep this window open while reproducing the problem.' -ForegroundColor White
Write-Host 'The window will say STILL RUNNING whenever the R process is alive.' -ForegroundColor White
Write-Host 'Press Q in this window after the test to stop the session and create the ZIP.' -ForegroundColor White
Write-Host ''

Set-RunState -Status 'INITIALISING'
Write-RunMessage -Message "Diagnostic output folder: $runDir"

$scriptExitCode = 2

try {
  if (-not (Test-Path -LiteralPath (Join-Path $ProjectDir 'global.R') -PathType Leaf)) {
    throw "The Dashboard project was not found at: $ProjectDir"
  }

  $rscriptCandidate = Find-RscriptExecutable
  if ([string]::IsNullOrWhiteSpace($rscriptCandidate)) {
    throw 'Rscript.exe was not found. Run 02_Setup_R_and_Run_Dashboard.cmd first.'
  }
  $script:rscriptResolved = Resolve-RscriptWorkerExecutable -Path $rscriptCandidate

  $rVersionResult = Invoke-RscriptText -Arguments @('--vanilla', '-e', 'cat(as.character(getRversion()))')
  $rVersionOutput = $rVersionResult.Output.Trim()
  $rVersionExitCode = $rVersionResult.ExitCode
  $rVersionMatch = [regex]::Match($rVersionOutput, '(?m)(?<![0-9.])([0-9]+\.[0-9]+(?:\.[0-9]+)?)(?![0-9.])')
  if ($rVersionExitCode -ne 0 -or -not $rVersionMatch.Success) {
    throw "R could not be started from: $($script:rscriptResolved)"
  }
  $script:rVersion = $rVersionMatch.Groups[1].Value

  $versionParts = $script:rVersion -split '\.'
  $versionKey = "$($versionParts[0]).$($versionParts[1])"
  $script:rLibrary = Join-Path $env:LOCALAPPDATA "HE-Toolkit\R-library\$versionKey"
  if (-not (Test-Path -LiteralPath $script:rLibrary -PathType Container)) {
    New-Item -ItemType Directory -Path $script:rLibrary -Force | Out-Null
  }
  $env:R_LIBS_USER = $script:rLibrary

  Write-EnvironmentSnapshot
  Write-RunMessage -Message "R detected: $($script:rVersion)"
  Write-RunMessage -Message 'Checking required packages without installing or changing anything...'

  $diagnosticPreflightPath = Join-Path $PSScriptRoot 'preflight_dashboard_diagnostics.R'
  if (-not (Test-Path -LiteralPath $diagnosticPreflightPath -PathType Leaf)) {
    throw "The diagnostic package check is missing: $diagnosticPreflightPath"
  }
  $preflightResult = Invoke-RscriptText -Arguments @('--vanilla', $diagnosticPreflightPath, $ProjectDir)
  $preflightOutput = $preflightResult.Output
  Add-Content -LiteralPath $environmentPath -Value "`r`nR package preflight:`r`n$preflightOutput" -Encoding UTF8
  if ($preflightResult.ExitCode -ne 0) {
    throw 'One or more required R packages are missing. Run 02_Setup_R_and_Run_Dashboard.cmd first.'
  }

  if (-not (Test-PortAvailable -LocalPort $Port)) {
    throw "Local port $Port is already in use. Close the existing Dashboard or other program and run this diagnostic again."
  }

  $launcherPath = Join-Path $PSScriptRoot 'run_dashboard_for_diagnostics.R'
  if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf)) {
    throw "The R diagnostic launcher is missing: $launcherPath"
  }

  $arguments = @(
    '--vanilla',
    ('"{0}"' -f $launcherPath),
    ('"{0}"' -f $ProjectDir),
    [string]$Port
  )

  Write-RunMessage -Message "Starting the Dashboard at http://127.0.0.1:$Port ..."
  $script:process = Start-Process -FilePath $script:rscriptResolved `
    -ArgumentList $arguments `
    -WorkingDirectory $ProjectDir `
    -RedirectStandardOutput $stdoutPath `
    -RedirectStandardError $stderrPath `
    -WindowStyle Hidden `
    -PassThru

  Set-RunState -Status 'RUNNING'
  Write-RunMessage -Message "R process started with PID $($script:process.Id)." -Level Running

  $url = "http://127.0.0.1:$Port"
  $browserOpened = $false
  $readySeen = $false
  $lastProbe = [datetime]::MinValue
  $previousCpuSeconds = 0.0
  $previousSampleTime = Get-Date

  while (-not $script:process.HasExited) {
    $now = Get-Date
    $elapsedSeconds = ($now - $script:runStarted).TotalSeconds

    try {
      if (-not [Console]::IsInputRedirected -and [Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Q) {
          $script:requestedStop = $true
          Write-RunMessage -Message 'Stop requested by the user. Closing the monitored Dashboard...' -Level Warning
          Stop-Process -Id $script:process.Id -Force -ErrorAction SilentlyContinue
          break
        }
      }
    } catch {
      # Some hosts do not expose Console.KeyAvailable. Monitoring still works.
    }

    if ($MaxRuntimeSeconds -gt 0 -and $elapsedSeconds -ge $MaxRuntimeSeconds) {
      $script:requestedStop = $true
      Write-RunMessage -Message "Configured monitoring limit of $MaxRuntimeSeconds seconds reached. Stopping the monitored session..." -Level Warning
      Stop-Process -Id $script:process.Id -Force -ErrorAction SilentlyContinue
      break
    }

    $script:process.Refresh()
    $sampleTime = Get-Date
    $sampleDuration = [math]::Max(($sampleTime - $previousSampleTime).TotalSeconds, 0.1)
    $cpuSeconds = $script:process.TotalProcessorTime.TotalSeconds
    $cpuPercent = [math]::Max(0, 100.0 * ($cpuSeconds - $previousCpuSeconds) / $sampleDuration / [Environment]::ProcessorCount)
    $previousCpuSeconds = $cpuSeconds
    $previousSampleTime = $sampleTime
    $script:lastRCPUPercent = [math]::Round($cpuPercent, 1)

    $rWorkingSetMB = [math]::Round($script:process.WorkingSet64 / 1MB, 1)
    $rPrivateMB = [math]::Round($script:process.PrivateMemorySize64 / 1MB, 1)
    $rThreads = $script:process.Threads.Count
    $rHandles = $script:process.HandleCount
    $memory = Get-SystemMemorySnapshot
    $browser = Get-BrowserMemorySnapshot
    $memoryPressure = Get-DiagnosticMemoryPressureState `
      -SystemAvailableMB $memory.AvailableMB `
      -SystemTotalMB $memory.TotalMB `
      -RPrivateMB $rPrivateMB

    if (($sampleTime - $lastProbe).TotalSeconds -ge $HealthProbeIntervalSeconds) {
      $healthResult = Test-DashboardHealth -Url $url
      $script:lastHealthState = $healthResult.State
      $script:lastHealthDetail = $healthResult.Detail
      $lastProbe = Get-Date
      if ($script:lastHealthState -eq 'RESPONSIVE') {
        $readySeen = $true
        $script:currentUnresponsiveSamples = 0
        if (-not $browserOpened -and -not $NoBrowser) {
          Start-Process $url | Out-Null
          $browserOpened = $true
          Write-RunMessage -Message 'Dashboard is ready and has been opened in the default browser.' -Level Success
        }
      } else {
        $script:currentUnresponsiveSamples += 1
        $script:longestUnresponsiveSamples = [math]::Max($script:longestUnresponsiveSamples, $script:currentUnresponsiveSamples)
      }
    }

    if ($readySeen -and $script:lastHealthState -eq 'BUSY_OR_UNRESPONSIVE') {
      $script:unresponsiveAfterReadySamples += 1
      $script:unresponsiveAfterReadyCpuTotal += $script:lastRCPUPercent
    }

    $script:peakRWorkingSetMB = [math]::Max($script:peakRWorkingSetMB, $rWorkingSetMB)
    $script:peakRPrivateMB = [math]::Max($script:peakRPrivateMB, $rPrivateMB)
    $script:peakRThreads = [math]::Max($script:peakRThreads, $rThreads)
    $script:peakBrowserWorkingSetMB = [math]::Max($script:peakBrowserWorkingSetMB, $browser.WorkingSetMB)
    if ($memory.AvailableMB -gt 0) {
      $script:minimumSystemAvailableMB = [math]::Min($script:minimumSystemAvailableMB, $memory.AvailableMB)
    }

    Add-ProcessSample -Sample ([pscustomobject]@{
      Timestamp = $sampleTime.ToString('o')
      ElapsedSeconds = [math]::Round($elapsedSeconds, 1)
      ProcessAlive = $true
      HttpState = $script:lastHealthState
      HttpDetail = $script:lastHealthDetail
      RCPUPercent = [math]::Round($cpuPercent, 1)
      RWorkingSetMB = $rWorkingSetMB
      RPrivateMB = $rPrivateMB
      RThreadCount = $rThreads
      RHandleCount = $rHandles
      SystemTotalMB = $memory.TotalMB
      SystemAvailableMB = $memory.AvailableMB
      MemoryPressure = $memoryPressure.Level
      BrowserProcessCount = $browser.Count
      BrowserWorkingSetMB = $browser.WorkingSetMB
      BrowserPrivateMB = $browser.PrivateMB
    })

    $runningMessage = 'STILL RUNNING'
    if ($script:lastHealthState -eq 'BUSY_OR_UNRESPONSIVE' -and $readySeen) {
      $runningMessage += ' - R is alive; the page is busy or temporarily unresponsive'
    } elseif (-not $readySeen) {
      $runningMessage += ' - R is alive; waiting for the page to become ready'
    } else {
      $runningMessage += ' - R is alive and the page responded to its latest check'
    }
    $runningMessage += " | elapsed=$([math]::Round($elapsedSeconds))s | R private=$rPrivateMB MB | available RAM=$($memory.AvailableMB) MB | threads=$rThreads"
    Write-RunMessage -Message $runningMessage -Level Running
    $script:lastHeartbeat = $sampleTime.ToString('o')
    $script:lastRPrivateMB = [string]$rPrivateMB
    Set-RunState `
      -Status 'RUNNING' `
      -LastHeartbeat $script:lastHeartbeat `
      -LastHttpState $script:lastHealthState `
      -LastPrivateMemoryMB $script:lastRPrivateMB

    if ($memoryPressure.Level -in @('HIGH', 'CRITICAL')) {
      Write-RunMessage -Message $memoryPressure.Message -Level Warning
    }

    Start-Sleep -Seconds $SampleIntervalSeconds
  }

  $script:process.WaitForExit()
  $script:exitCode = [Int64]$script:process.ExitCode
  $script:runEnded = Get-Date

  Start-Sleep -Milliseconds 300
  $eventRecords = Get-RelevantWindowsEvents -From $script:runStarted.AddMinutes(-1) -To $script:runEnded.AddMinutes(1)
  $crashEventDetected = @($eventRecords | Where-Object {
      $_.ProviderName -in @('Application Error', 'Windows Error Reporting') -and
      $_.Message -match '(?i)(Rscript\.exe|Rterm\.exe|\\R\.exe)'
    }).Count -gt 0
  $resourceEventDetected = @($eventRecords | Where-Object {
      $_.ProviderName -eq 'Microsoft-Windows-Resource-Exhaustion-Detector' -and
      $_.Message -match '(?i)(Rscript\.exe|Rterm\.exe|\\R\.exe)'
    }).Count -gt 0

  $combinedLog = ''
  foreach ($logPath in @($stdoutPath, $stderrPath, $eventPath)) {
    if (Test-Path -LiteralPath $logPath -PathType Leaf) {
      $combinedLog += "`r`n" + (Get-Content -LiteralPath $logPath -Raw -ErrorAction SilentlyContinue)
    }
  }

  $classification = Get-DiagnosticExitCodeInfo `
    -ExitCode $script:exitCode `
    -CombinedLog $combinedLog `
    -CrashEventDetected $crashEventDetected `
    -ResourceExhaustionEventDetected $resourceEventDetected `
    -RequestedStop $script:requestedStop

  $script:outcomeStatus = $classification.Status
  $script:outcomeMessage = $classification.CustomerMessage
  $script:likelyCause = $classification.LikelyCause
  $script:exitCodeHex = $classification.ExitCodeHex
  $script:isCrash = $classification.IsCrash

  if ($script:isCrash) {
    $script:runtimeAssessment = 'The monitored R process exited and matching crash evidence was detected.'
  } elseif ($script:outcomeStatus -eq 'UNEXPECTED_EXIT') {
    $script:runtimeAssessment = 'The monitored R process exited unexpectedly, but no evidence confirmed a native or memory crash.'
  } elseif ($script:unresponsiveAfterReadySamples -gt 0) {
    $averageBusyCpu = $script:unresponsiveAfterReadyCpuTotal / $script:unresponsiveAfterReadySamples
    if ($averageBusyCpu -ge 0.5) {
      $script:runtimeAssessment = "R remained alive while the web probe timed out and averaged $([math]::Round($averageBusyCpu, 1))% of total CPU during those samples. This is consistent with a long synchronous calculation, not a confirmed crash."
    } else {
      $script:runtimeAssessment = "R remained alive while the web probe timed out and averaged $([math]::Round($averageBusyCpu, 1))% of total CPU during those samples. It may have been waiting or blocked; this is a hang candidate, not a confirmed crash."
    }
  } elseif ($script:lastHealthState -eq 'RESPONSIVE') {
    $script:runtimeAssessment = 'The monitored R process remained alive and the Shiny web endpoint responded to its latest probe. No crash was detected.'
  } else {
    $script:runtimeAssessment = 'R remained alive until monitoring stopped, but the Dashboard did not finish becoming ready during the recorded interval. No crash was detected.'
  }

  if ($script:isCrash) {
    Write-RunMessage -Message "CRASH CONFIRMED: $($script:outcomeMessage)" -Level Error
    $scriptExitCode = 4
  } elseif ($script:outcomeStatus -eq 'UNEXPECTED_EXIT') {
    Write-RunMessage -Message $script:outcomeMessage -Level Warning
    $scriptExitCode = 3
  } else {
    Write-RunMessage -Message $script:outcomeMessage -Level Success
    $scriptExitCode = 0
  }
} catch {
  $script:diagnosticError = $_.Exception.ToString()
  $script:outcomeStatus = 'DIAGNOSTIC_SETUP_FAILURE'
  $script:outcomeMessage = 'The diagnostic could not start or complete the Dashboard test.'
  $script:likelyCause = $_.Exception.Message
  $script:isCrash = $false
  Write-RunMessage -Message "Diagnostic setup failed: $($_.Exception.Message)" -Level Error

  if ($null -ne $script:process -and -not $script:process.HasExited) {
    $script:requestedStop = $true
    Stop-Process -Id $script:process.Id -Force -ErrorAction SilentlyContinue
  }
  $scriptExitCode = 2
}

try {
  $completedZip = Complete-DiagnosticPackage
  Write-Host ''
  Write-Host '============================================================' -ForegroundColor Cyan
  Write-Host "Diagnostic result: $($script:outcomeStatus)" -ForegroundColor $(if ($script:isCrash) { 'Red' } else { 'Cyan' })
  Write-Host $script:outcomeMessage -ForegroundColor $(if ($script:isCrash) { 'Red' } else { 'White' })
  Write-Host "Assessment: $($script:runtimeAssessment)" -ForegroundColor White
  Write-Host ''
  Write-Host 'Please reply to the existing support email and attach:' -ForegroundColor White
  Write-Host $completedZip -ForegroundColor Yellow
  Write-Host '============================================================' -ForegroundColor Cyan
} catch {
  Write-Host "The evidence folder was created, but ZIP packaging failed: $($_.Exception.Message)" -ForegroundColor Red
  Write-Host "Please send this folder instead: $runDir" -ForegroundColor Yellow
  if ($scriptExitCode -eq 0) { $scriptExitCode = 2 }
}

exit $scriptExitCode
