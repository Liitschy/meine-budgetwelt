param(
    [string]$GodotPath = "",
    [string]$MakensisPath = ""
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$projectFile = Join-Path $repositoryRoot "project.godot"
$exportPreset = Join-Path $repositoryRoot "export_presets.cfg"
$installerScript = Join-Path $repositoryRoot "installer\meine-budgetwelt.nsi"
$buildRoot = Join-Path $repositoryRoot "build\windows"
$isolatedAppData = Join-Path $repositoryRoot ".godot\windows-export-appdata"
$isolatedLocalAppData = Join-Path $repositoryRoot ".godot\windows-export-localappdata"
$isolatedTemplateRoot = Join-Path $isolatedAppData "Godot\export_templates\4.7.1.stable"
$templateArchive = Join-Path $repositoryRoot ".godot\windows-export-templates\Godot_v4.7.1-stable_export_templates.tpz"

$projectText = Get-Content -LiteralPath $projectFile -Raw
$versionMatch = [regex]::Match($projectText, '(?m)^config/version="(?<version>\d+\.\d+\.\d+)"\r?$')
if (-not $versionMatch.Success) {
    throw "Die Windows-App-Version fehlt in project.godot."
}
$version = $versionMatch.Groups["version"].Value

if (-not (Test-Path -LiteralPath $exportPreset -PathType Leaf)) {
    throw "Die Godot-Exportvorgabe fehlt."
}
if (-not (Test-Path -LiteralPath $installerScript -PathType Leaf)) {
    throw "Das Windows-Installerskript fehlt."
}

if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    $godotCommand = Get-Command godot -ErrorAction SilentlyContinue
    if ($null -ne $godotCommand) {
        $GodotPath = $godotCommand.Source
    }
    else {
        foreach ($candidate in @(
            (Join-Path $repositoryRoot ".godot\godot-standard\Godot_v4.7.1-stable_win64_console.exe"),
            "C:\Godot\Godot_v4.7.1-stable_win64_console.exe",
            "C:\Godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe",
            "C:\Godot\Godot_v4.7.1-stable_mono_win64_console.exe"
        )) {
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                $GodotPath = $candidate
                break
            }
        }
    }
}
if ([string]::IsNullOrWhiteSpace($GodotPath) -or -not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw "Godot 4.7.1 wurde nicht gefunden."
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
if ([string]::IsNullOrWhiteSpace($MakensisPath) -or -not (Test-Path -LiteralPath $MakensisPath -PathType Leaf)) {
    throw "NSIS wurde nicht gefunden."
}

New-Item -ItemType Directory -Force -Path $buildRoot | Out-Null
New-Item -ItemType Directory -Force -Path $isolatedTemplateRoot | Out-Null
New-Item -ItemType Directory -Force -Path $isolatedLocalAppData | Out-Null
$requiredTemplates = @(
    "version.txt",
    "windows_debug_x86_64.exe",
    "windows_release_x86_64.exe"
)
$sourceTemplateRoot = Join-Path $env:APPDATA "Godot\export_templates\4.7.1.stable"
foreach ($templateName in $requiredTemplates) {
    $targetTemplate = Join-Path $isolatedTemplateRoot $templateName
    $sourceTemplate = Join-Path $sourceTemplateRoot $templateName
    if (-not (Test-Path -LiteralPath $targetTemplate -PathType Leaf) -and
        (Test-Path -LiteralPath $sourceTemplate -PathType Leaf)) {
        Copy-Item -LiteralPath $sourceTemplate -Destination $targetTemplate
    }
}
if ($requiredTemplates | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $isolatedTemplateRoot $_) -PathType Leaf)
}) {
    if (-not (Test-Path -LiteralPath $templateArchive -PathType Leaf)) {
        throw "Die offiziellen Godot-4.7.1-Windows-Exportvorlagen fehlen."
    }
    & tar -xf $templateArchive `
        -C $isolatedTemplateRoot `
        --strip-components=1 `
        templates/version.txt `
        templates/windows_debug_x86_64.exe `
        templates/windows_release_x86_64.exe
    if ($LASTEXITCODE -ne 0) {
        throw "Die Windows-Exportvorlagen konnten nicht entpackt werden."
    }
}
foreach ($templateName in $requiredTemplates) {
    if (-not (Test-Path -LiteralPath (Join-Path $isolatedTemplateRoot $templateName) -PathType Leaf)) {
        throw "Windows-Exportvorlage fehlt: $templateName"
    }
}
$applicationPath = Join-Path $buildRoot ("Meine-Budgetwelt-{0}.exe" -f $version)
$installerPath = Join-Path $buildRoot ("Meine-Budgetwelt-Setup-{0}.exe" -f $version)

$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
try {
    $env:APPDATA = $isolatedAppData
    $env:LOCALAPPDATA = $isolatedLocalAppData
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $exportOutput = & $GodotPath `
        --headless `
        --path $repositoryRoot `
        --export-release "Windows Desktop" `
        $applicationPath 2>&1
    $exportExitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
}
finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
$exportOutput | ForEach-Object { Write-Host $_ }
if ($exportExitCode -ne 0) {
    throw "Der Windows-Export ist mit Exitcode $exportExitCode fehlgeschlagen."
}
$exportErrors = $exportOutput | Where-Object {
    $_ -match '(^|\s)(SCRIPT ERROR|ERROR):' -and
    $_ -notmatch '^ERROR: Failed to read the root certificate store\.$'
}
if ($exportErrors) {
    throw "Der Windows-Export enthält Engine- oder Skriptfehler."
}
if (-not (Test-Path -LiteralPath $applicationPath -PathType Leaf)) {
    throw "Die exportierte Windows-App fehlt."
}

& $MakensisPath @(
    "/WX",
    "/DAPP_VERSION=$version",
    "/DAPP_EXE=$applicationPath",
    "/DOUTPUT_FILE=$installerPath",
    $installerScript
)
if ($LASTEXITCODE -ne 0) {
    throw "Der Windows-Installer konnte nicht erstellt werden."
}

$hash = Get-FileHash -LiteralPath $installerPath -Algorithm SHA256
$hashPath = [System.IO.Path]::ChangeExtension($installerPath, ".sha256")
Set-Content -LiteralPath $hashPath -Encoding ASCII -Value (
    "{0}  {1}" -f $hash.Hash.ToLowerInvariant(), [IO.Path]::GetFileName($installerPath))

$downloadUrl = (
    "https://github.com/unique1986/meine-budgetwelt/releases/download/v{0}/Meine-Budgetwelt-Setup-{0}.exe" -f $version
)
$manifestPath = Join-Path $buildRoot "update-manifest.json"
$manifest = [ordered]@{
    version = $version
    download_url = $downloadUrl
    sha256_url = [System.IO.Path]::ChangeExtension($downloadUrl, ".sha256")
} | ConvertTo-Json
Set-Content -LiteralPath $manifestPath -Encoding UTF8 -Value $manifest

Write-Host "Windows-Installer erstellt: $installerPath"
Write-Host "SHA-256: $($hash.Hash.ToLowerInvariant())"
Write-Host "Update-Manifest erstellt: $manifestPath"
