function Get-NormalizedPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
}

function Get-CanonicalExecutablePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($item.PSIsContainer) {
        throw "The executable path points to a folder: $Path"
    }

    # FileInfo.FullName expands Windows 8.3 path segments such as PROGRA~1.
    return Get-NormalizedPath -Path $item.FullName
}

function Get-RscriptExecutableIdentity {
    param([Parameter(Mandatory = $true)][string]$Path)

    $canonicalPath = Get-CanonicalExecutablePath -Path $Path
    $item = Get-Item -LiteralPath $canonicalPath -ErrorAction Stop
    if ($item.Name -ine "Rscript.exe") {
        return $null
    }

    $directory = $item.Directory
    $role = $null
    $installationRoot = $null

    if ($directory.Name -ieq "bin") {
        $role = "bin-front-end"
        $installationRoot = $directory.Parent.FullName
    }
    elseif (($directory.Name -ieq "x64" -or $directory.Name -ieq "i386") -and
        $null -ne $directory.Parent -and
        $directory.Parent.Name -ieq "bin") {
        $role = "architecture-runtime"
        $installationRoot = $directory.Parent.Parent.FullName
    }
    else {
        return $null
    }

    return [pscustomobject]@{
        CanonicalPath = $canonicalPath
        InstallationRoot = Get-NormalizedPath -Path $installationRoot
        Role = $role
        FileVersion = [string]$item.VersionInfo.FileVersion
    }
}

function Test-EquivalentRscriptExecutable {
    param(
        [Parameter(Mandatory = $true)][string]$ExpectedPath,
        [Parameter(Mandatory = $true)][string]$ActualPath
    )

    $expected = Get-RscriptExecutableIdentity -Path $ExpectedPath
    $actual = Get-RscriptExecutableIdentity -Path $ActualPath
    if ($null -eq $expected -or $null -eq $actual) {
        return $false
    }

    if ($expected.CanonicalPath -ieq $actual.CanonicalPath) {
        return $true
    }

    # R's Windows bin\Rscript.exe front-end delegates through cmd.exe to the
    # architecture-specific bin\x64 (or legacy bin\i386) Rscript.exe.
    return (
        $expected.Role -eq "bin-front-end" -and
        $actual.Role -eq "architecture-runtime" -and
        $expected.InstallationRoot -ieq $actual.InstallationRoot -and
        -not [string]::IsNullOrWhiteSpace($expected.FileVersion) -and
        $expected.FileVersion -eq $actual.FileVersion
    )
}
