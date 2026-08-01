param(
    [string]$Configuration = "Release",
    [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$serverProject = Join-Path $repositoryRoot "server\MeineBudgetwelt.Server\MeineBudgetwelt.Server.csproj"
$serverDll = Join-Path $repositoryRoot "server\MeineBudgetwelt.Server\bin\$Configuration\net10.0\Meine-Budgetwelt-Server.dll"
$testParent = Join-Path ([System.IO.Path]::GetTempPath()) "MeineBudgetwelt-client-server-tests"
$testRoot = Join-Path $testParent ("MeineBudgetwelt-" + [Guid]::NewGuid().ToString("N"))
$dataRoot = Join-Path $testRoot "server-data"
$clientAAppData = Join-Path $testRoot "client-a"
$clientBAppData = Join-Path $testRoot "client-b"
$standardOutput = Join-Path $testRoot "server.stdout.log"
$standardError = Join-Path $testRoot "server.stderr.log"
$liveClientOutput = Join-Path $testRoot "live-client.stdout.log"
$liveClientError = Join-Path $testRoot "live-client.stderr.log"
$liveClientReady = Join-Path $testRoot "live-client.ready"
$serverProcess = $null
$liveClientProcess = $null
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
$previousDataDirectory = $env:BUDGETWELT_DATA_DIR
$testEnvironmentNames = @(
    "BUDGETWELT_TEST_SERVER_URL",
    "BUDGETWELT_TEST_EMAIL",
    "BUDGETWELT_TEST_PASSWORD",
    "BUDGETWELT_TEST_PHASE",
    "BUDGETWELT_TEST_READY_FILE"
)

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
    throw "Godot 4.7.1 wurde nicht gefunden."
}

function Get-FreeLoopbackPort {
    $listener = [System.Net.Sockets.TcpListener]::new(
        [System.Net.IPAddress]::Loopback,
        0
    )
    $listener.Start()
    try {
        return ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port
    }
    finally {
        $listener.Stop()
    }
}

function Normalize-ProcessPathEnvironment {
    $pathKeys = @(
        [System.Environment]::GetEnvironmentVariables("Process").Keys |
            Where-Object { $_ -ieq "Path" }
    )
    if ($pathKeys.Count -le 1) {
        return
    }

    $pathValue = [System.Environment]::GetEnvironmentVariable("Path", "Process")
    [System.Environment]::SetEnvironmentVariable("PATH", $null, "Process")
    [System.Environment]::SetEnvironmentVariable("Path", $pathValue, "Process")
}

function Invoke-SyncClient {
    param(
        [string]$Phase,
        [string]$Email,
        [string]$Password,
        [string]$AppDataPath,
        [string]$ServerUrl
    )
    New-Item -ItemType Directory -Force -Path $AppDataPath | Out-Null
    $env:APPDATA = $AppDataPath
    $env:LOCALAPPDATA = Join-Path $AppDataPath "local"
    New-Item -ItemType Directory -Force -Path $env:LOCALAPPDATA | Out-Null
    $env:BUDGETWELT_TEST_SERVER_URL = $ServerUrl
    $env:BUDGETWELT_TEST_EMAIL = $Email
    $env:BUDGETWELT_TEST_PASSWORD = $Password
    $env:BUDGETWELT_TEST_PHASE = $Phase
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & $script:GodotExecutable `
        --headless `
        --path $repositoryRoot `
        --scene "res://tests/SyncClientE2E.tscn" 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    $output | ForEach-Object { Write-Host $_ }
    if ($exitCode -ne 0) {
        throw "Godot-Clientphase '$Phase' ist mit Exitcode $exitCode fehlgeschlagen."
    }
    if (-not ($output | Select-String -SimpleMatch "SYNC_CLIENT_E2E_OK:$Phase")) {
        throw "Godot-Clientphase '$Phase' hat den Erfolg nicht bestätigt."
    }
    $relevantErrors = $output | Where-Object {
        $_ -match '(^|\s)(SCRIPT ERROR|ERROR):' -and
        $_ -notmatch '^ERROR: Failed to read the root certificate store\.$'
    }
    if ($relevantErrors) {
        throw "Godot-Clientphase '$Phase' enthält Engine- oder Skriptfehler."
    }
}

try {
    New-Item -ItemType Directory -Force -Path $testRoot | Out-Null
    $script:GodotExecutable = Resolve-GodotExecutable
    dotnet build $serverProject --configuration $Configuration --no-restore
    if ($LASTEXITCODE -ne 0) {
        throw "Server-Build fehlgeschlagen."
    }

    $env:BUDGETWELT_DATA_DIR = $dataRoot
    $bootstrapPassword = "Admin!" + [Guid]::NewGuid().ToString("N")
    $secondPassword = "Nutzer!" + [Guid]::NewGuid().ToString("N")
    $env:BUDGETWELT_BOOTSTRAP_PASSWORD = $bootstrapPassword
    & dotnet $serverDll bootstrap-admin `
        --name "E2E Admin" `
        --email "admin@example.invalid"
    $env:BUDGETWELT_BOOTSTRAP_PASSWORD = $null
    if ($LASTEXITCODE -ne 0) {
        throw "E2E-Administratorkonto konnte nicht angelegt werden."
    }

    $port = Get-FreeLoopbackPort
    $serverUrl = "http://127.0.0.1:$port"
    $serverArguments = @(
        $serverDll,
        "--Server:ListenUrl=$serverUrl",
        "--Email:FromAddress=noreply@example.invalid",
        "--Email:PublicBaseUrl=http://localhost/"
    )
    Normalize-ProcessPathEnvironment
    $serverProcess = Start-Process `
        -FilePath "dotnet" `
        -ArgumentList $serverArguments `
        -PassThru `
        -WindowStyle Hidden `
        -RedirectStandardOutput $standardOutput `
        -RedirectStandardError $standardError

    $health = $null
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        if ($serverProcess.HasExited) {
            throw "E2E-Server wurde unerwartet beendet."
        }
        try {
            $health = Invoke-RestMethod -Uri "$serverUrl/health" -TimeoutSec 2
            break
        }
        catch {
            Start-Sleep -Milliseconds 250
        }
    }
    if ($null -eq $health -or $health.status -ne "ok" -or $health.database -ne "ok") {
        throw "E2E-Server ist nicht gesund."
    }

    $loginBody = @{
        email = "admin@example.invalid"
        password = $bootstrapPassword
        rememberMe = $false
    } | ConvertTo-Json
    $login = Invoke-RestMethod `
        -Uri "$serverUrl/api/auth/desktop-login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loginBody
    $headers = @{ Authorization = "Bearer $($login.token)" }
    $createUserBody = @{
        name = "E2E Nutzer"
        email = "user@example.invalid"
        password = $secondPassword
        isSystemAdmin = $false
    } | ConvertTo-Json
    $secondUser = Invoke-RestMethod `
        -Uri "$serverUrl/api/admin/users" `
        -Method Post `
        -Headers $headers `
        -ContentType "application/json" `
        -Body $createUserBody
    $groups = @(Invoke-RestMethod -Uri "$serverUrl/api/admin/groups" -Headers $headers)
    if ($groups.Count -ne 1) {
        throw "E2E-Budgetgruppe fehlt."
    }
    $memberBody = @{
        userId = $secondUser.id
        role = "member"
    } | ConvertTo-Json
    Invoke-RestMethod `
        -Uri "$serverUrl/api/admin/groups/$($groups[0].id)/members" `
        -Method Put `
        -Headers $headers `
        -ContentType "application/json" `
        -Body $memberBody | Out-Null

    Invoke-SyncClient `
        -Phase "seed" `
        -Email "admin@example.invalid" `
        -Password $bootstrapPassword `
        -AppDataPath $clientAAppData `
        -ServerUrl $serverUrl

    $env:APPDATA = $clientAAppData
    $env:LOCALAPPDATA = Join-Path $clientAAppData "local"
    $env:BUDGETWELT_TEST_SERVER_URL = $serverUrl
    $env:BUDGETWELT_TEST_EMAIL = "admin@example.invalid"
    $env:BUDGETWELT_TEST_PASSWORD = $bootstrapPassword
    $env:BUDGETWELT_TEST_PHASE = "wait-live-change"
    $env:BUDGETWELT_TEST_READY_FILE = $liveClientReady
    $liveClientProcess = Start-Process `
        -FilePath $script:GodotExecutable `
        -ArgumentList @(
            "--headless",
            "--path", $repositoryRoot,
            "--scene", "res://tests/SyncClientE2E.tscn"
        ) `
        -PassThru `
        -WindowStyle Hidden `
        -RedirectStandardOutput $liveClientOutput `
        -RedirectStandardError $liveClientError
    for ($attempt = 0; $attempt -lt 80; $attempt++) {
        if ($liveClientProcess.HasExited) {
            throw "Live-Client wurde vor dem Aenderungstest beendet."
        }
        if (Test-Path -LiteralPath $liveClientReady -PathType Leaf) {
            break
        }
        Start-Sleep -Milliseconds 250
    }
    if (-not (Test-Path -LiteralPath $liveClientReady -PathType Leaf)) {
        throw "Live-Client hat seine Testbereitschaft nicht bestaetigt."
    }
    Invoke-SyncClient `
        -Phase "receive-change" `
        -Email "user@example.invalid" `
        -Password $secondPassword `
        -AppDataPath $clientBAppData `
        -ServerUrl $serverUrl

    if (-not $liveClientProcess.WaitForExit(30000)) {
        throw "Live-Client hat die mobile Aenderung nicht rechtzeitig empfangen."
    }
    $liveClientProcess.WaitForExit()
    $liveOutput = @(
        Get-Content -LiteralPath $liveClientOutput -ErrorAction SilentlyContinue
        Get-Content -LiteralPath $liveClientError -ErrorAction SilentlyContinue
    )
    $liveOutput | ForEach-Object { Write-Host $_ }
    if ($null -ne $liveClientProcess.ExitCode -and $liveClientProcess.ExitCode -ne 0) {
        throw "Live-Client ist mit Exitcode $($liveClientProcess.ExitCode) fehlgeschlagen."
    }
    if (-not ($liveOutput | Select-String -SimpleMatch "SYNC_CLIENT_E2E_OK:wait-live-change")) {
        throw "Live-Client hat den automatischen Abgleich nicht bestaetigt."
    }
    Invoke-SyncClient `
        -Phase "verify-return" `
        -Email "admin@example.invalid" `
        -Password $bootstrapPassword `
        -AppDataPath $clientAAppData `
        -ServerUrl $serverUrl

    Write-Host "Client-Server-E2E erfolgreich: Server -> Client A -> Client B -> Client A."
}
finally {
    if ($null -ne $liveClientProcess -and -not $liveClientProcess.HasExited) {
        Stop-Process -Id $liveClientProcess.Id -Force
        $liveClientProcess.WaitForExit()
    }
    if ($null -ne $serverProcess -and -not $serverProcess.HasExited) {
        Stop-Process -Id $serverProcess.Id -Force
        $serverProcess.WaitForExit()
    }
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
    $env:BUDGETWELT_DATA_DIR = $previousDataDirectory
    $env:BUDGETWELT_BOOTSTRAP_PASSWORD = $null
    foreach ($name in $testEnvironmentNames) {
        [System.Environment]::SetEnvironmentVariable($name, $null, "Process")
    }
    if (Test-Path -LiteralPath $testRoot) {
        $resolvedTestRoot = (Resolve-Path -LiteralPath $testRoot).Path
        $safePrefix = [System.IO.Path]::GetFullPath(
            (Join-Path $testParent "MeineBudgetwelt-")
        )
        if (-not $resolvedTestRoot.StartsWith(
            $safePrefix,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Unsicherer E2E-Testpfad; Aufräumen wurde verweigert."
        }
        for ($cleanupAttempt = 0; $cleanupAttempt -lt 5; $cleanupAttempt++) {
            if (-not (Test-Path -LiteralPath $resolvedTestRoot)) {
                break
            }
            try {
                [System.IO.Directory]::Delete($resolvedTestRoot, $true)
            }
            catch {
                if ($cleanupAttempt -eq 4) {
                    Write-Warning "Temporärer E2E-Ordner konnte nicht vollständig entfernt werden: $resolvedTestRoot"
                }
                else {
                    [System.GC]::Collect()
                    [System.GC]::WaitForPendingFinalizers()
                    Start-Sleep -Milliseconds 400
                }
            }
        }
    }
}
