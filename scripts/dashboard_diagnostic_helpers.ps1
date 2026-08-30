Set-StrictMode -Version 2.0

function ConvertTo-DiagnosticUnsignedExitCode {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [Int64]$ExitCode
  )

  if ($ExitCode -ge 0 -and $ExitCode -le [UInt32]::MaxValue -and $ExitCode -gt [Int32]::MaxValue) {
    return [UInt32]$ExitCode
  }

  $signed = [Int32]$ExitCode
  return [BitConverter]::ToUInt32([BitConverter]::GetBytes($signed), 0)
}

function Get-DiagnosticExitCodeInfo {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [Int64]$ExitCode,

    [AllowEmptyString()]
    [string]$CombinedLog = "",

    [bool]$CrashEventDetected = $false,

    [bool]$ResourceExhaustionEventDetected = $false,

    [bool]$RequestedStop = $false
  )

  $unsignedExitCode = ConvertTo-DiagnosticUnsignedExitCode -ExitCode $ExitCode
  $exitCodeHex = "0x{0:X8}" -f $unsignedExitCode
  $normalExitCodes = @(0)
  $interruptExitCodes = @([Convert]::ToUInt32('C000013A', 16), [UInt32]130)
  $memoryExitCodes = @([Convert]::ToUInt32('C0000017', 16))
  $nativeCrashExitCodes = @(
    [Convert]::ToUInt32('C0000005', 16), # access violation
    [Convert]::ToUInt32('C00000FD', 16), # stack overflow
    [Convert]::ToUInt32('C0000374', 16), # heap corruption
    [Convert]::ToUInt32('C0000409', 16)  # stack buffer overrun / fail-fast
  )

  $memoryPattern = '(?i)(cannot allocate (vector|memory)|memory exhausted|out of memory|not enough memory|std::bad_alloc|fatal error[^\r\n]*memory)'
  # A normal R error can contain words such as "fatal error" without being a
  # native process crash. Keep this deliberately limited to unambiguous native
  # failure signatures so that an application error is not over-reported.
  $nativeCrashPattern = '(?i)(segmentation fault|segfault|access violation|R session aborted|stack buffer overrun|heap corruption)'
  $hasMemorySignature = $CombinedLog -match $memoryPattern
  $hasNativeCrashSignature = $CombinedLog -match $nativeCrashPattern

  if ($RequestedStop -or $interruptExitCodes -contains $unsignedExitCode) {
    return [pscustomobject]@{
      Status = 'USER_STOPPED'
      IsCrash = $false
      ExitCodeHex = $exitCodeHex
      LikelyCause = 'The diagnostic session was stopped by the user or by an interrupt signal.'
      CustomerMessage = 'Monitoring stopped by request. No dashboard crash was reported.'
    }
  }

  if ($normalExitCodes -contains [Int64]$ExitCode) {
    return [pscustomobject]@{
      Status = 'NORMAL_EXIT'
      IsCrash = $false
      ExitCodeHex = $exitCodeHex
      LikelyCause = 'The R process ended with exit code 0.'
      CustomerMessage = 'The dashboard process ended normally. No crash was detected.'
    }
  }

  if (($memoryExitCodes -contains $unsignedExitCode) -or $hasMemorySignature -or $ResourceExhaustionEventDetected) {
    return [pscustomobject]@{
      Status = 'MEMORY_CRASH_CONFIRMED'
      IsCrash = $true
      ExitCodeHex = $exitCodeHex
      LikelyCause = 'The process exited and the evidence indicates memory allocation or system resource exhaustion.'
      CustomerMessage = 'The dashboard process crashed. The available evidence indicates a memory-related failure.'
    }
  }

  if (($nativeCrashExitCodes -contains $unsignedExitCode) -or $hasNativeCrashSignature -or $CrashEventDetected) {
    return [pscustomobject]@{
      Status = 'NATIVE_CRASH_CONFIRMED'
      IsCrash = $true
      ExitCodeHex = $exitCodeHex
      LikelyCause = 'The process exited with native-crash evidence such as an access violation, fail-fast code, or Windows crash event.'
      CustomerMessage = 'The dashboard process crashed. Native process-failure evidence was detected.'
    }
  }

  return [pscustomobject]@{
    Status = 'UNEXPECTED_EXIT'
    IsCrash = $false
    ExitCodeHex = $exitCodeHex
    LikelyCause = 'The R process returned a non-zero exit code, but no native-crash or memory-exhaustion evidence was found.'
    CustomerMessage = 'The dashboard process stopped unexpectedly. The log does not prove that it crashed.'
  }
}

function Get-DiagnosticMemoryPressureState {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [double]$SystemAvailableMB,

    [Parameter(Mandatory = $true)]
    [double]$SystemTotalMB,

    [Parameter(Mandatory = $true)]
    [double]$RPrivateMB
  )

  if ($SystemTotalMB -le 0) {
    return [pscustomobject]@{
      Level = 'UNKNOWN'
      Message = 'Memory pressure could not be calculated; the R process is still being monitored.'
    }
  }

  $availablePercent = 100.0 * $SystemAvailableMB / $SystemTotalMB
  $rPrivatePercent = 100.0 * $RPrivateMB / $SystemTotalMB

  if ($SystemAvailableMB -lt 512 -or $availablePercent -lt 3 -or $rPrivatePercent -gt 85) {
    return [pscustomobject]@{
      Level = 'CRITICAL'
      Message = 'Critical memory pressure detected, but the R process is still running. Please wait while monitoring continues.'
    }
  }

  if ($SystemAvailableMB -lt 1024 -or $availablePercent -lt 8 -or $rPrivatePercent -gt 65) {
    return [pscustomobject]@{
      Level = 'HIGH'
      Message = 'High memory pressure detected, but the R process is still running. Please wait while monitoring continues.'
    }
  }

  return [pscustomobject]@{
    Level = 'NORMAL'
    Message = 'Memory pressure is within the monitoring threshold and the R process is still running.'
  }
}

function ConvertTo-SafeDiagnosticText {
  [CmdletBinding()]
  param(
    [AllowEmptyString()]
    [string]$Text,

    [AllowEmptyString()]
    [string]$UserProfile = $env:USERPROFILE,

    [AllowEmptyString()]
    [string]$LocalAppData = $env:LOCALAPPDATA,

    [AllowEmptyString()]
    [string]$UserName = $env:USERNAME,

    [AllowEmptyString()]
    [string]$ComputerName = $env:COMPUTERNAME
  )

  if ($null -eq $Text) {
    return ''
  }

  $safeText = [string]$Text
  $replacements = @(
    [pscustomobject]@{ Value = $LocalAppData; Sentinel = '__HE_DIAG_LOCALAPPDATA__'; Replacement = '%LOCALAPPDATA%' },
    [pscustomobject]@{ Value = $UserProfile; Sentinel = '__HE_DIAG_USERPROFILE__'; Replacement = '%USERPROFILE%' },
    [pscustomobject]@{ Value = $ComputerName; Sentinel = '__HE_DIAG_COMPUTERNAME__'; Replacement = '%COMPUTERNAME%' },
    [pscustomobject]@{ Value = $UserName; Sentinel = '__HE_DIAG_USERNAME__'; Replacement = '%USERNAME%' }
  ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Value) } |
    Sort-Object { $_.Value.Length } -Descending

  foreach ($replacement in $replacements) {
    $safeText = [regex]::Replace(
      $safeText,
      [regex]::Escape([string]$replacement.Value),
      [string]$replacement.Sentinel,
      [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
  }

  foreach ($replacement in $replacements) {
    $safeText = $safeText.Replace(
      [string]$replacement.Sentinel,
      [string]$replacement.Replacement
    )
  }

  return $safeText
}
