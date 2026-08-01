param(
    [Parameter(Mandatory = $true)]
    [string]$BaseInstaller,
    [Parameter(Mandatory = $true)]
    [string]$UpdateInstaller,
    [Parameter(Mandatory = $true)]
    [string]$RollbackInstaller,
    [string]$TestRoot = "C:\tmp\meine-budgetwelt-installer-verification"
)

$ErrorActionPreference = "Stop"
$uninstallRegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\MeineBudgetwelt"
$applicationRegistryPath = "HKCU:\Software\Meine Budgetwelt"

function Resolve-RequiredFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Erforderliche Testdatei fehlt: $Path"
    }
    return (Resolve-Path -LiteralPath $Path).Path
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )
    if (-not $Condition) {
        throw $Message
    }
}

function Invoke-Installer {
    param(
        [string]$Path,
        [bool]$ExpectFailure = $false
    )
    $process = Start-Process -FilePath $Path -ArgumentList @(
        "/S",
        "/D=$script:ResolvedTestRoot"
    ) -Wait -PassThru
    if ($ExpectFailure) {
        Assert-True ($process.ExitCode -ne 0) "Der erzwungene Installationsfehler wurde nicht gemeldet."
    }
    else {
        Assert-True ($process.ExitCode -eq 0) "Setup fehlgeschlagen: $Path (Exitcode $($process.ExitCode))"
    }
}

$baseInstallerPath = Resolve-RequiredFile $BaseInstaller
$updateInstallerPath = Resolve-RequiredFile $UpdateInstaller
$rollbackInstallerPath = Resolve-RequiredFile $RollbackInstaller
$script:ResolvedTestRoot = [System.IO.Path]::GetFullPath($TestRoot).TrimEnd("\")
$resolvedTempRoot = [System.IO.Path]::GetFullPath("C:\tmp").TrimEnd("\")
$requiredPrefix = "$resolvedTempRoot\"

if (-not $script:ResolvedTestRoot.StartsWith(
    $requiredPrefix,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw "Der Installer-Testordner muss innerhalb von C:\tmp liegen."
}

if (Test-Path -LiteralPath $uninstallRegistryPath) {
    $existing = Get-ItemProperty -LiteralPath $uninstallRegistryPath
    throw "Eine bestehende Installation wurde gefunden: $($existing.InstallLocation). Der isolierte Test wurde nicht gestartet."
}

if (Test-Path -LiteralPath $script:ResolvedTestRoot) {
    Remove-Item -LiteralPath $script:ResolvedTestRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $script:ResolvedTestRoot | Out-Null

$installedExecutable = Join-Path $script:ResolvedTestRoot "Meine-Budgetwelt.exe"
$previousExecutable = "$installedExecutable.previous"
$uninstaller = Join-Path $script:ResolvedTestRoot "Meine-Budgetwelt-deinstallieren.exe"

try {
    Invoke-Installer $baseInstallerPath
    Assert-True (Test-Path -LiteralPath $installedExecutable -PathType Leaf) "Die Basisinstallation enthält keine App-EXE."
    Assert-True (Test-Path -LiteralPath $uninstaller -PathType Leaf) "Die Basisinstallation enthält keinen Uninstaller."
    $installed = Get-ItemProperty -LiteralPath $uninstallRegistryPath
    Assert-True ($installed.DisplayVersion -eq "0.39.2") "Die Basisversion wurde nicht korrekt registriert."
    Assert-True ($installed.InstallLocation -eq $script:ResolvedTestRoot) "Der isolierte Installationspfad wurde nicht registriert."

    Invoke-Installer $baseInstallerPath
    Assert-True (Test-Path -LiteralPath $installedExecutable -PathType Leaf) "Die Reparatur hat die App-EXE nicht wiederhergestellt."
    Assert-True (-not (Test-Path -LiteralPath $previousExecutable)) "Nach der Reparatur blieb eine Rückfallkopie liegen."

    Invoke-Installer $updateInstallerPath
    $updated = Get-ItemProperty -LiteralPath $uninstallRegistryPath
    Assert-True ($updated.DisplayVersion -eq "0.39.3") "Das Update wurde nicht korrekt registriert."
    Assert-True (-not (Test-Path -LiteralPath $previousExecutable)) "Nach dem Update blieb eine Rückfallkopie liegen."

    Invoke-Installer $baseInstallerPath $true
    $afterDowngradeAttempt = Get-ItemProperty -LiteralPath $uninstallRegistryPath
    Assert-True ($afterDowngradeAttempt.DisplayVersion -eq "0.39.3") "Ein stiller Rückstufungsversuch hat die registrierte Version verändert."

    $hashBeforeRollbackTest = (Get-FileHash -LiteralPath $installedExecutable -Algorithm SHA256).Hash

    Invoke-Installer $rollbackInstallerPath $true
    $hashAfterRollbackTest = (Get-FileHash -LiteralPath $installedExecutable -Algorithm SHA256).Hash
    $afterRollback = Get-ItemProperty -LiteralPath $uninstallRegistryPath
    Assert-True ($hashAfterRollbackTest -eq $hashBeforeRollbackTest) "Die bisherige App-EXE wurde nach dem Fehler nicht wiederhergestellt."
    Assert-True ($afterRollback.DisplayVersion -eq "0.39.3") "Ein fehlgeschlagenes Update hat die registrierte Version verändert."
    Assert-True (-not (Test-Path -LiteralPath $previousExecutable)) "Nach dem Rückfalltest blieb eine temporäre Programmdatei liegen."

    Write-Host "Installer-Pruefung erfolgreich: Installation, Reparatur, Update, Downgrade-Schutz und Rueckfall."
}
finally {
    if (Test-Path -LiteralPath $uninstaller -PathType Leaf) {
        Start-Process -FilePath $uninstaller -ArgumentList "/S" -Wait | Out-Null
    }
    if (Test-Path -LiteralPath $uninstallRegistryPath) {
        Remove-Item -LiteralPath $uninstallRegistryPath -Recurse -Force
    }
    if (Test-Path -LiteralPath $applicationRegistryPath) {
        Remove-Item -LiteralPath $applicationRegistryPath -Recurse -Force
    }
    if (Test-Path -LiteralPath $script:ResolvedTestRoot) {
        $cleanupPath = [System.IO.Path]::GetFullPath($script:ResolvedTestRoot).TrimEnd("\")
        if ($cleanupPath.StartsWith($requiredPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $cleanupPath -Recurse -Force
        }
    }
}
