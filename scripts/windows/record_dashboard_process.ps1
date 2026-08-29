param(
    [Parameter(Mandatory = $true)]
    [int]$Port,

    [Parameter(Mandatory = $true)]
    [string]$RscriptPath,

    [Parameter(Mandatory = $true)]
    [string]$ProjectDirectory,

    [Parameter(Mandatory = $true)]
    [string]$RuntimeDirectory,

    [Parameter(Mandatory = $true)]
    [string]$RunStamp,

    [Parameter(Mandatory = $true)]
    [string]$ServerLog
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\rscript_process_identity.ps1"

try {
    $expectedRscript = Get-CanonicalExecutablePath -Path $RscriptPath
    $expectedProject = Get-NormalizedPath -Path $ProjectDirectory
    $expectedProcessName = [System.IO.Path]::GetFileName($expectedRscript)

    $ownerIds = @(
        Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop |
            Where-Object { $_.LocalAddress -eq "127.0.0.1" } |
            Select-Object -ExpandProperty OwningProcess -Unique
    )

    if ($ownerIds.Count -ne 1) {
        throw "Expected one 127.0.0.1:$Port listener, but found $($ownerIds.Count)."
    }

    $dashboardPid = [int]$ownerIds[0]
    $process = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $dashboardPid"
    if ($null -eq $process) {
        throw "The listener process $dashboardPid no longer exists."
    }

    $reportedActualExecutable = [string]$process.ExecutablePath
    try {
        $actualExecutable = Get-CanonicalExecutablePath -Path $reportedActualExecutable
    }
    catch {
        throw "The listener executable could not be resolved. Listener PID: $dashboardPid. Expected Rscript executable: $expectedRscript. Actual listener executable: $reportedActualExecutable."
    }
    $commandLine = [string]$process.CommandLine
    $requiredCommandText = @(
        "--vanilla",
        "shiny::runApp",
        "port=$Port",
        "host='127.0.0.1'",
        "launch.browser=FALSE"
    )

    if ([string]$process.Name -ine $expectedProcessName) {
        throw "The listener is not the expected Rscript process."
    }
    if (-not (Test-EquivalentRscriptExecutable -ExpectedPath $expectedRscript -ActualPath $actualExecutable)) {
        throw "The listener executable does not match the Rscript selected by the launcher. Listener PID: $dashboardPid. Expected Rscript executable: $expectedRscript. Actual listener executable: $actualExecutable. Reported listener executable: $reportedActualExecutable."
    }
    foreach ($requiredText in $requiredCommandText) {
        if ($commandLine.IndexOf($requiredText, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            throw "The listener command line is missing the expected Dashboard marker: $requiredText"
        }
    }

    $nativeProcess = Get-Process -Id $dashboardPid -ErrorAction Stop
    $metadata = [ordered]@{
        recordFormatVersion = 2
        pid = $dashboardPid
        processName = [string]$process.Name
        launcherRscriptPath = $expectedRscript
        executablePath = $actualExecutable
        commandLine = $commandLine
        projectDirectory = $expectedProject
        port = $Port
        processStartTimeUtc = $nativeProcess.StartTime.ToUniversalTime().ToString("o")
        recordedAtUtc = [DateTime]::UtcNow.ToString("o")
        launcherRunStamp = $RunStamp
        serverLog = Get-NormalizedPath -Path $ServerLog
    }

    [System.IO.Directory]::CreateDirectory($RuntimeDirectory) | Out-Null
    $pidPath = Join-Path $RuntimeDirectory "dashboard.pid"
    $metadataPath = Join-Path $RuntimeDirectory "dashboard.json"
    $temporaryPidPath = Join-Path $RuntimeDirectory ("dashboard.pid.{0}.tmp" -f [Guid]::NewGuid().ToString("N"))
    $temporaryMetadataPath = Join-Path $RuntimeDirectory ("dashboard.json.{0}.tmp" -f [Guid]::NewGuid().ToString("N"))
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)

    try {
        [System.IO.File]::WriteAllText(
            $temporaryMetadataPath,
            (($metadata | ConvertTo-Json -Depth 3) + [Environment]::NewLine),
            $utf8WithoutBom
        )
        [System.IO.File]::WriteAllText(
            $temporaryPidPath,
            ([string]$dashboardPid + [Environment]::NewLine),
            $utf8WithoutBom
        )

        Move-Item -LiteralPath $temporaryMetadataPath -Destination $metadataPath -Force
        Move-Item -LiteralPath $temporaryPidPath -Destination $pidPath -Force
    }
    finally {
        Remove-Item -LiteralPath $temporaryMetadataPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $temporaryPidPath -Force -ErrorAction SilentlyContinue
    }

    Write-Host "Recorded HE Toolkit Dashboard process ID $dashboardPid."
    exit 0
}
catch {
    Write-Error ("Dashboard process ownership was not recorded: {0}" -f $_.Exception.Message)
    exit 1
}
