param(
    [Parameter(Mandatory = $true)]
    [string]$RuntimeDirectory,

    [Parameter(Mandatory = $true)]
    [string]$ExpectedProjectDirectory,

    [int]$ExpectedPort = 3838
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\rscript_process_identity.ps1"

function Remove-RuntimeRecord {
    param(
        [Parameter(Mandatory = $true)][string]$PidPath,
        [Parameter(Mandatory = $true)][string]$MetadataPath
    )

    Remove-Item -LiteralPath $MetadataPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $PidPath -Force -ErrorAction SilentlyContinue

    if ((Test-Path -LiteralPath $PidPath) -or (Test-Path -LiteralPath $MetadataPath)) {
        throw "The stale Dashboard runtime record could not be removed."
    }
}

$pidPath = Join-Path $RuntimeDirectory "dashboard.pid"
$metadataPath = Join-Path $RuntimeDirectory "dashboard.json"

try {
    if (-not (Test-Path -LiteralPath $pidPath -PathType Leaf)) {
        if (Test-Path -LiteralPath $metadataPath) {
            Remove-Item -LiteralPath $metadataPath -Force -ErrorAction Stop
        }
        Write-Host "No launcher-started Dashboard is currently recorded."
        Write-Host "The Dashboard is already stopped."
        exit 0
    }

    $pidText = (Get-Content -LiteralPath $pidPath -Raw).Trim()
    $recordedPid = 0
    if (-not [int]::TryParse($pidText, [ref]$recordedPid) -or $recordedPid -le 0) {
        throw "The Dashboard PID record is invalid. No process was stopped."
    }

    if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
        throw "Dashboard ownership metadata is missing. No process was stopped."
    }

    try {
        $metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
    }
    catch {
        throw "Dashboard ownership metadata is unreadable. No process was stopped."
    }

    $requiredProperties = @(
        "recordFormatVersion",
        "pid",
        "processName",
        "executablePath",
        "commandLine",
        "projectDirectory",
        "port",
        "processStartTimeUtc"
    )
    foreach ($propertyName in $requiredProperties) {
        if ($null -eq $metadata.PSObject.Properties[$propertyName]) {
            throw "Dashboard ownership metadata is incomplete. No process was stopped."
        }
    }

    $recordFormatVersion = [int]$metadata.recordFormatVersion
    if ($recordFormatVersion -eq 2 -and $null -eq $metadata.PSObject.Properties["launcherRscriptPath"]) {
        throw "Dashboard ownership metadata is incomplete. No process was stopped."
    }

    $expectedProject = Get-NormalizedPath -Path $ExpectedProjectDirectory
    if ($recordFormatVersion -notin @(1, 2) -or
        [int]$metadata.pid -ne $recordedPid -or
        [int]$metadata.port -ne $ExpectedPort -or
        (Get-NormalizedPath -Path ([string]$metadata.projectDirectory)) -ine $expectedProject) {
        throw "Dashboard ownership metadata does not match this HE Toolkit launcher. No process was stopped."
    }

    $nativeProcess = Get-Process -Id $recordedPid -ErrorAction SilentlyContinue
    if ($null -eq $nativeProcess) {
        Remove-RuntimeRecord -PidPath $pidPath -MetadataPath $metadataPath
        Write-Host "The recorded Dashboard process is no longer running."
        Write-Host "The stale runtime record was removed; the Dashboard is already stopped."
        exit 0
    }

    $process = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $recordedPid"
    if ($null -eq $process) {
        throw "The recorded PID exists, but its process details could not be read. No process was stopped."
    }

    $ownershipErrors = New-Object System.Collections.Generic.List[string]
    $recordedLauncherPath = if ($recordFormatVersion -eq 2) {
        [string]$metadata.launcherRscriptPath
    }
    else {
        [string]$metadata.executablePath
    }
    $launcherExecutable = Get-CanonicalExecutablePath -Path $recordedLauncherPath
    $expectedExecutable = Get-CanonicalExecutablePath -Path ([string]$metadata.executablePath)
    $actualExecutable = Get-CanonicalExecutablePath -Path ([string]$process.ExecutablePath)
    $currentCommandLine = [string]$process.CommandLine
    $requiredCommandText = @(
        "--vanilla",
        "shiny::runApp",
        "port=$ExpectedPort",
        "host='127.0.0.1'",
        "launch.browser=FALSE"
    )

    if ([string]$process.Name -ine [string]$metadata.processName -or
        [string]$process.Name -ine [System.IO.Path]::GetFileName($expectedExecutable)) {
        $ownershipErrors.Add("process name")
    }
    if ($actualExecutable -ine $expectedExecutable) {
        $ownershipErrors.Add("executable path")
    }
    if (-not (Test-EquivalentRscriptExecutable -ExpectedPath $launcherExecutable -ActualPath $actualExecutable)) {
        $ownershipErrors.Add("R installation executable relationship")
    }
    if ($currentCommandLine -cne [string]$metadata.commandLine) {
        $ownershipErrors.Add("recorded command line")
    }
    foreach ($requiredText in $requiredCommandText) {
        if ($currentCommandLine.IndexOf($requiredText, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            $ownershipErrors.Add("Dashboard command marker '$requiredText'")
        }
    }

    $currentStartTimeUtc = $nativeProcess.StartTime.ToUniversalTime().ToString("o")
    if ($currentStartTimeUtc -cne [string]$metadata.processStartTimeUtc) {
        $ownershipErrors.Add("process start time")
    }

    if ($ownershipErrors.Count -gt 0) {
        $details = $ownershipErrors -join ", "
        throw "Process ownership could not be verified ($details). PID $recordedPid was not stopped."
    }

    Write-Host "Stopping the verified HE Toolkit Dashboard process (PID $recordedPid)..."
    Stop-Process -InputObject $nativeProcess -ErrorAction Stop
    if (-not $nativeProcess.WaitForExit(10000)) {
        throw "The verified Dashboard process did not stop within 10 seconds. The runtime record was preserved."
    }

    $portDeadline = [DateTime]::UtcNow.AddSeconds(5)
    do {
        $recordedProcessStillListening = @(
            Get-NetTCPConnection -LocalPort $ExpectedPort -State Listen -ErrorAction SilentlyContinue |
                Where-Object { $_.OwningProcess -eq $recordedPid }
        ).Count -gt 0
        if (-not $recordedProcessStillListening) {
            break
        }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $portDeadline)

    if ($recordedProcessStillListening) {
        throw "The Dashboard process stopped, but its recorded port did not close in time. The runtime record was preserved."
    }

    Remove-RuntimeRecord -PidPath $pidPath -MetadataPath $metadataPath
    Write-Host "Dashboard stopped successfully."
    exit 0
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "For safety, no unverified process has been terminated."
    exit 1
}
