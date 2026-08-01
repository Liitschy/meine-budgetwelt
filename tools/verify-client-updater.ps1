$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$managerPath = Join-Path $repositoryRoot "core\update_manager.gd"
$managerSource = Get-Content -LiteralPath $managerPath -Raw -Encoding UTF8
$scriptMatch = [regex]::Match(
    $managerSource,
    '(?s)const AUTOMATIC_UPDATE_SCRIPT_CONTENTS := """(?<script>.*?)"""'
)
if (-not $scriptMatch.Success) {
    throw "Das eingebettete Windows-Update-Skript wurde nicht gefunden."
}

$updaterSource = $scriptMatch.Groups["script"].Value
$tokens = $null
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseInput(
    $updaterSource,
    [ref]$tokens,
    [ref]$parseErrors
) | Out-Null
if ($parseErrors.Count -gt 0) {
    throw "Das automatische Windows-Update-Skript ist ungültig: $($parseErrors[0].Message)"
}

$requiredFragments = @(
    "Get-Process -Id `$ParentProcessId",
    "-ArgumentList @('/S')",
    "-Wait -PassThru -WindowStyle Hidden",
    "Start-Process -FilePath `$ApplicationPath",
    "Remove-Item -LiteralPath `$InstallerPath"
)
foreach ($fragment in $requiredFragments) {
    if (-not $updaterSource.Contains($fragment)) {
        throw "Dem automatischen Windows-Updater fehlt: $fragment"
    }
}

Write-Host "Client-Updater-Pruefung erfolgreich: Syntax, stilles Setup, Prozesswartezeit und Neustart."
