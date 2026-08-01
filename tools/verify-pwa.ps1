param(
    [string]$Configuration = "Release",
    [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$webRoot = Join-Path $repositoryRoot "web"
$serverVerifier = Join-Path $PSScriptRoot "verify-server.ps1"
$verificationRoot = Join-Path $repositoryRoot ".godot\pwa-verification"
$verificationAppData = Join-Path $verificationRoot "appdata"
$sourceTemplateRoot = Join-Path $env:APPDATA "Godot\export_templates\4.7.1.stable"
$isolatedTemplateRoot = Join-Path $verificationAppData "Godot\export_templates\4.7.1.stable"
$previousAppData = $env:APPDATA

function Resolve-GodotExecutable {
    if (-not [string]::IsNullOrWhiteSpace($GodotPath)) {
        if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
            throw "Godot wurde unter '$GodotPath' nicht gefunden."
        }
        return (Resolve-Path -LiteralPath $GodotPath).Path
    }

    $command = Get-Command godot -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    foreach ($candidate in @(
        (Join-Path $repositoryRoot ".godot\godot-standard\Godot_v4.7.1-stable_win64_console.exe"),
        "C:\Godot\Godot_v4.7.1-stable_win64_console.exe",
        "C:\Godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe"
    )) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "Godot 4.7.1 Standard wurde nicht gefunden."
}

$godotExecutable = Resolve-GodotExecutable
New-Item -ItemType Directory -Force -Path $webRoot | Out-Null
New-Item -ItemType Directory -Force -Path $isolatedTemplateRoot | Out-Null
foreach ($templateName in @(
    "version.txt",
    "web_debug.zip",
    "web_nothreads_debug.zip",
    "web_nothreads_release.zip",
    "web_release.zip"
)) {
    $sourceTemplate = Join-Path $sourceTemplateRoot $templateName
    $isolatedTemplate = Join-Path $isolatedTemplateRoot $templateName
    if (-not (Test-Path -LiteralPath $sourceTemplate -PathType Leaf)) {
        throw "Godot-Web-Exportvorlage fehlt: $sourceTemplate"
    }
    if (-not (Test-Path -LiteralPath $isolatedTemplate -PathType Leaf)) {
        Copy-Item -LiteralPath $sourceTemplate -Destination $isolatedTemplate
    }
}

try {
    $env:APPDATA = $verificationAppData
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $exportOutput = & $godotExecutable `
        --headless `
        --path $repositoryRoot `
        --export-release "Web" `
        (Join-Path $webRoot "index.html") 2>&1
    $exportExitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    $exportOutput | ForEach-Object { Write-Host $_ }
}
finally {
    $env:APPDATA = $previousAppData
}

if ($exportExitCode -ne 0) {
    throw "PWA-Export ist mit Exitcode $exportExitCode fehlgeschlagen."
}
$relevantExportErrors = $exportOutput | Where-Object {
    $_ -match '(^|\s)(SCRIPT ERROR|ERROR):' -and
    $_ -notmatch '^ERROR: Failed to read the root certificate store\.$'
}
if ($relevantExportErrors) {
    throw "PWA-Export enthaelt Engine- oder Skriptfehler."
}

foreach ($requiredPwaFile in @(
    "index.html",
    "index.js",
    "index.pck",
    "index.wasm",
    "index.manifest.json",
    "index.service.worker.js"
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $webRoot $requiredPwaFile) -PathType Leaf)) {
        throw "PWA-Exportdatei fehlt: $requiredPwaFile"
    }
}

$packageBytes = [System.IO.File]::ReadAllBytes((Join-Path $webRoot "index.pck"))
$packageText = [System.Text.Encoding]::ASCII.GetString($packageBytes)
foreach ($forbiddenText in @(
    "Meine-Budgetwelt-Server",
    "SyncClientE2E",
    "packages.lock.json"
)) {
    if ($packageText.Contains($forbiddenText)) {
        throw "PWA-Paket enthaelt ausgeschlossene Entwicklungsdatei: $forbiddenText"
    }
}

& $serverVerifier -Configuration $Configuration -PwaRoot $webRoot
if ($LASTEXITCODE -ne 0) {
    throw "Server- und PWA-Durchstichtest ist fehlgeschlagen."
}

Write-Host "PWA-Pruefung erfolgreich: Export, Paketinhalt, Serverauslieferung, Sicherheitsheader, Sitzungscookie und API-Schutz."
