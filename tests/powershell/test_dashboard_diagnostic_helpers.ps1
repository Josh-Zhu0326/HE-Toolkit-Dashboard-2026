$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'scripts\dashboard_diagnostic_helpers.ps1')

function Assert-Equal {
  param(
    [Parameter(Mandatory = $true)]$Expected,
    [Parameter(Mandatory = $true)]$Actual,
    [Parameter(Mandatory = $true)][string]$Message
  )

  if ($Expected -ne $Actual) {
    throw "$Message Expected '$Expected', received '$Actual'."
  }
}

function Assert-False {
  param(
    [Parameter(Mandatory = $true)][bool]$Value,
    [Parameter(Mandatory = $true)][string]$Message
  )

  if ($Value) { throw $Message }
}

function Assert-True {
  param(
    [Parameter(Mandatory = $true)][bool]$Value,
    [Parameter(Mandatory = $true)][string]$Message
  )

  if (-not $Value) { throw $Message }
}

$normal = Get-DiagnosticExitCodeInfo -ExitCode 0
Assert-Equal 'NORMAL_EXIT' $normal.Status 'Exit code zero should be normal.'
Assert-False $normal.IsCrash 'A normal exit must not be labelled as a crash.'

$requested = Get-DiagnosticExitCodeInfo -ExitCode ([Int64][Int32]0xC000013A) -RequestedStop $true
Assert-Equal 'USER_STOPPED' $requested.Status 'An intentional stop should be recognised.'
Assert-False $requested.IsCrash 'An intentional stop must not be labelled as a crash.'

$native = Get-DiagnosticExitCodeInfo -ExitCode ([Int64][Int32]0xC0000005)
Assert-Equal 'NATIVE_CRASH_CONFIRMED' $native.Status 'An access violation should confirm a native crash.'
Assert-True $native.IsCrash 'An access violation must be labelled as a crash.'

$memoryExit = Get-DiagnosticExitCodeInfo -ExitCode ([Int64][Int32]0xC0000017)
Assert-Equal 'MEMORY_CRASH_CONFIRMED' $memoryExit.Status 'The no-memory exit code should confirm a memory crash.'
Assert-True $memoryExit.IsCrash 'The no-memory exit code must be labelled as a crash.'

$memoryLog = Get-DiagnosticExitCodeInfo -ExitCode 1 -CombinedLog 'Error: cannot allocate vector of size 2.0 Gb'
Assert-Equal 'MEMORY_CRASH_CONFIRMED' $memoryLog.Status 'An R allocation signature should confirm a memory crash after exit.'

$ordinaryError = Get-DiagnosticExitCodeInfo -ExitCode 70 -CombinedLog 'FATAL_R_ERROR: missing value where TRUE/FALSE needed'
Assert-Equal 'UNEXPECTED_EXIT' $ordinaryError.Status 'An ordinary top-level R error is not a native crash.'
Assert-False $ordinaryError.IsCrash 'An ordinary R error must not be labelled as a native crash.'

$timeoutText = Get-DiagnosticExitCodeInfo -ExitCode 70 -CombinedLog 'HTTP probe: BUSY_OR_UNRESPONSIVE'
Assert-Equal 'UNEXPECTED_EXIT' $timeoutText.Status 'An HTTP timeout is not crash evidence.'
Assert-False $timeoutText.IsCrash 'An HTTP timeout must not be labelled as a crash.'

$normalPressure = Get-DiagnosticMemoryPressureState -SystemAvailableMB 8000 -SystemTotalMB 16000 -RPrivateMB 1000
Assert-Equal 'NORMAL' $normalPressure.Level 'Healthy memory should be normal.'
$highPressure = Get-DiagnosticMemoryPressureState -SystemAvailableMB 900 -SystemTotalMB 16000 -RPrivateMB 2000
Assert-Equal 'HIGH' $highPressure.Level 'Less than 1 GB available should be high pressure.'
$criticalPressure = Get-DiagnosticMemoryPressureState -SystemAvailableMB 400 -SystemTotalMB 16000 -RPrivateMB 2000
Assert-Equal 'CRITICAL' $criticalPressure.Level 'Less than 512 MB available should be critical pressure.'

$sensitiveText = 'C:\Users\Alice\AppData\Local\HE-Toolkit on WORKSTATION-7 belongs to Alice; home C:\Users\Alice'
$safeText = ConvertTo-SafeDiagnosticText `
  -Text $sensitiveText `
  -UserProfile 'C:\Users\Alice' `
  -LocalAppData 'C:\Users\Alice\AppData\Local' `
  -UserName 'Alice' `
  -ComputerName 'WORKSTATION-7'
Assert-True ($safeText -match [regex]::Escape('%LOCALAPPDATA%\HE-Toolkit')) 'Local AppData should be replaced.'
Assert-True ($safeText -match [regex]::Escape('%USERPROFILE%')) 'The user profile should be replaced.'
Assert-True ($safeText -match [regex]::Escape('%USERNAME%')) 'The user name should be replaced.'
Assert-True ($safeText -match [regex]::Escape('%COMPUTERNAME%')) 'The computer name should be replaced.'
Assert-False ($safeText -match '(?i)Alice|WORKSTATION-7') 'Sensitive names should not remain after redaction.'

Write-Output 'PASS: dashboard diagnostic helper tests'
