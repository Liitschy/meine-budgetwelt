param(
    [string]$Configuration = "Release",
    [string]$MakensisPath = "",
    [string]$GodotPath = "",
    [switch]$SkipPwaBuild,
    [switch]$SkipRestore
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$serverProject = Join-Path $repositoryRoot "server\MeineBudgetwelt.Server\MeineBudgetwelt.Server.csproj"
$publishRoot = Join-Path $repositoryRoot "build\server\win-x64"
$webRoot = Join-Path $repositoryRoot "web"
$installerScript = Join-Path $repositoryRoot "installer\meine-budgetwelt-server.nsi"
$updaterSourceRoot = Join-Path $repositoryRoot "installer\server-updater"
$serverToolsSourceRoot = Join-Path $repositoryRoot "installer\server-tools"

[xml]$projectXml = Get-Content -LiteralPath $serverProject -Raw
$serverVersion = [string]$projectXml.Project.PropertyGroup.Version
if ($serverVersion -notmatch '^\d+\.\d+\.\d+$') {
    throw "Serverversion fehlt oder ist ungültig."
}

if (-not $SkipPwaBuild) {
    & (Join-Path $PSScriptRoot "verify-pwa.ps1") `
        -Configuration $Configuration `
        -GodotPath $GodotPath
    if ($LASTEXITCODE -ne 0) {
        throw "PWA-Prüfung vor dem Serverpaket ist fehlgeschlagen."
    }
}
foreach ($file in @(
    "index.html",
    "index.js",
    "index.pck",
    "index.wasm",
    "index.manifest.json",
    "index.service.worker.js"
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $webRoot $file) -PathType Leaf)) {
        throw "PWA-Datei fehlt: $file"
    }
}

if (-not $SkipRestore) {
    & dotnet restore $serverProject --runtime win-x64 --force-evaluate
    if ($LASTEXITCODE -ne 0) {
        throw "Server-Abhängigkeiten konnten nicht wiederhergestellt werden."
    }
}

$publishArguments = @(
    "publish",
    $serverProject,
    "--configuration",
    $Configuration,
    "-p:PublishProfile=win-x64",
    "--no-restore"
)
& dotnet @publishArguments
if ($LASTEXITCODE -ne 0) {
    throw "Server-Veröffentlichung ist fehlgeschlagen."
}

$publishedPwaRoot = Join-Path $publishRoot "pwa"
New-Item -ItemType Directory -Force -Path $publishedPwaRoot | Out-Null
Copy-Item -Path (Join-Path $webRoot "*") -Destination $publishedPwaRoot -Recurse -Force
$publishedUpdaterRoot = Join-Path $publishRoot "updater"
New-Item -ItemType Directory -Force -Path $publishedUpdaterRoot | Out-Null
Copy-Item -Path (Join-Path $updaterSourceRoot "*") -Destination $publishedUpdaterRoot -Recurse -Force
$publishedToolsRoot = Join-Path $publishRoot "tools"
New-Item -ItemType Directory -Force -Path $publishedToolsRoot | Out-Null
Copy-Item -Path (Join-Path $serverToolsSourceRoot "*") -Destination $publishedToolsRoot -Recurse -Force
foreach ($updaterFile in @(
    "ServerUpdate.ps1",
    "Install-ServerUpdateTask.ps1",
    "server-update-public-key.xml"
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $publishedUpdaterRoot $updaterFile) -PathType Leaf)) {
        throw "Server-Updater-Datei fehlt: $updaterFile"
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $publishedToolsRoot "Configure-Integrations.ps1") -PathType Leaf)) {
    throw "Server-Konfigurationswerkzeug fehlt: Configure-Integrations.ps1"
}

if ([string]::IsNullOrWhiteSpace($MakensisPath)) {
    $makensisCommand = Get-Command makensis -ErrorAction SilentlyContinue
    if ($null -ne $makensisCommand) {
        $MakensisPath = $makensisCommand.Source
    }
    else {
        foreach ($candidate in @(
            (Join-Path $repositoryRoot ".godot\nsis-3.12\nsis-3.12\makensis.exe"),
            "C:\Program Files (x86)\NSIS\makensis.exe",
            "C:\Program Files\NSIS\makensis.exe"
        )) {
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                $MakensisPath = $candidate
                break
            }
        }
    }
}
if (
    [string]::IsNullOrWhiteSpace($MakensisPath) -or
    -not (Test-Path -LiteralPath $MakensisPath -PathType Leaf)
) {
    throw "NSIS wurde nicht gefunden. Übergib den Pfad mit -MakensisPath."
}

$outputFile = Join-Path $repositoryRoot (
    "build\server\Meine-Budgetwelt-Server-Setup-{0}.exe" -f $serverVersion)
$makensisArguments = @(
    "/WX",
    "/DSERVER_VERSION=$serverVersion",
    "/DSERVER_PAYLOAD=$publishRoot",
    "/DOUTPUT_FILE=$outputFile",
    $installerScript
)
& $MakensisPath @makensisArguments
if ($LASTEXITCODE -ne 0) {
    throw "Server-Installer konnte nicht erstellt werden."
}

$hash = Get-FileHash -LiteralPath $outputFile -Algorithm SHA256
$hashFile = "$outputFile.sha256"
Set-Content -LiteralPath $hashFile -Encoding ASCII -Value (
    "{0}  {1}" -f $hash.Hash.ToLowerInvariant(), [System.IO.Path]::GetFileName($outputFile))

Write-Host "Server-Installer erstellt: $outputFile"
Write-Host "SHA-256: $($hash.Hash.ToLowerInvariant())"
