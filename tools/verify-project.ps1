param(
    [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$verificationDirectory = Join-Path $repositoryRoot ".godot\verification"
$verificationAppData = Join-Path $verificationDirectory "appdata"
$verificationLocalAppData = Join-Path $verificationDirectory "localappdata"

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

    $candidates = @(
        "C:\Godot\Godot_v4.7.1-stable_win64_console.exe",
        "C:\Godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe",
        "C:\Godot\Godot_v4.7.1-stable_mono_win64_console.exe"
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    throw "Godot 4.7.1 wurde nicht gefunden. Uebergib den Pfad mit -GodotPath."
}

function Invoke-GodotChecked {
    param(
        [string]$Label,
        [string[]]$Arguments
    )

    $logPath = Join-Path $verificationDirectory "$Label.log"
    Write-Host "Godot-Pruefung: $Label"

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & $script:GodotExecutable @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference

    $output | Tee-Object -FilePath $logPath

    if ($exitCode -ne 0) {
        throw "Godot-Pruefung '$Label' ist mit Exitcode $exitCode fehlgeschlagen."
    }

    $engineErrors = @($output | Where-Object {
        $_ -match '(^|\s)(SCRIPT ERROR|ERROR):' -and
        $_ -notmatch '^ERROR: Failed to read the root certificate store\.$' -and
        # Godot 4.7 Dummy-Renderer meldet beim sofortigen Testprozess-Ende nur seine RID-Cachebereinigung.
        $_ -notmatch '^ERROR: \d+ RID allocations of type .* were leaked at exit\.$'
    })
    if ($engineErrors.Count -gt 0) {
        throw "Godot-Pruefung '$Label' enthaelt Engine- oder Skriptfehler. Siehe $logPath"
    }
}

New-Item -ItemType Directory -Force -Path $verificationDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $verificationAppData | Out-Null
New-Item -ItemType Directory -Force -Path $verificationLocalAppData | Out-Null
$script:GodotExecutable = Resolve-GodotExecutable
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
$env:APPDATA = $verificationAppData
$env:LOCALAPPDATA = $verificationLocalAppData

Push-Location $repositoryRoot
try {
    Invoke-GodotChecked -Label "import" -Arguments @(
        "--headless",
        "--editor",
        "--import",
        "--path",
        "."
    )
    Invoke-GodotChecked -Label "tests" -Arguments @(
        "--headless",
        "--path",
        ".",
        "--scene",
        "res://tests/TestRunner.tscn"
    )

    & git diff --check
    if ($LASTEXITCODE -ne 0) {
        throw "git diff --check ist fehlgeschlagen."
    }

    Write-Host "Projektpruefung erfolgreich."
}
finally {
	Pop-Location
	$env:APPDATA = $previousAppData
	$env:LOCALAPPDATA = $previousLocalAppData
}
