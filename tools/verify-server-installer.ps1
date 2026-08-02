param(
    [string]$MakensisPath = "",
    [string]$ResultPath = "",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$installerScript = Join-Path $repositoryRoot "installer\meine-budgetwelt-server.nsi"
$payloadRoot = Join-Path $repositoryRoot "build\server\win-x64"
$buildScript = Join-Path $PSScriptRoot "build-server-installer.ps1"
$suffix = [Guid]::NewGuid().ToString("N").Substring(0, 10)
$serviceName = "MBWServerTest$suffix"
$updateTaskName = "MeineBudgetweltServerUpdater$suffix"
$testParent = "C:\tmp"
$testRoot = Join-Path $testParent "MeineBudgetweltServerInstaller-$suffix"
$installRoot = Join-Path $testRoot "program with spaces"
$dataRoot = Join-Path $testRoot "data"
$testInstallerRoot = Join-Path $repositoryRoot ".godot\server-installer-tests"
$testInstaller = Join-Path $testInstallerRoot "server-test-setup.exe"
$testPort = 0
$uninstaller = Join-Path $installRoot "Meine-Budgetwelt-Server-deinstallieren.exe"
$productKey = "Software\Meine Budgetwelt Server Tests\$suffix"
$uninstallKey = "Software\Microsoft\Windows\CurrentVersion\Uninstall\MBWServerTest$suffix"

function Get-FreeLoopbackPort {
    $listener = [System.Net.Sockets.TcpListener]::new(
        [System.Net.IPAddress]::Loopback,
        0)
    $listener.Start()
    try {
        return ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port
    }
    finally {
        $listener.Stop()
    }
}

function Resolve-Makensis {
    if (-not [string]::IsNullOrWhiteSpace($MakensisPath)) {
        return (Resolve-Path -LiteralPath $MakensisPath).Path
    }
    foreach ($candidate in @(
        (Join-Path $repositoryRoot ".godot\nsis-3.12\nsis-3.12\makensis.exe"),
        "C:\Program Files (x86)\NSIS\makensis.exe",
        "C:\Program Files\NSIS\makensis.exe"
    )) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    throw "NSIS wurde nicht gefunden."
}

function Remove-TestService {
    if ($serviceName -notmatch '^MBWServerTest[a-f0-9]{10}$') {
        throw "Unsicherer Testdienstname."
    }
    & sc.exe stop $serviceName 2>&1 | Out-Null
    & sc.exe delete $serviceName 2>&1 | Out-Null
}

function Remove-TestUpdateTask {
    if ($updateTaskName -notmatch '^MeineBudgetweltServerUpdater[a-f0-9]{10}$') {
        throw "Unsicherer Testaufgabenname."
    }
    Unregister-ScheduledTask `
        -TaskName $updateTaskName `
        -Confirm:$false `
        -ErrorAction SilentlyContinue
}

function Remove-TestFiles {
    if (-not (Test-Path -LiteralPath $testRoot)) {
        return
    }
    $resolvedRoot = (Resolve-Path -LiteralPath $testRoot).Path
    $safePrefix = [System.IO.Path]::GetFullPath(
        (Join-Path $testParent "MeineBudgetweltServerInstaller-"))
    if (-not $resolvedRoot.StartsWith(
        $safePrefix,
        [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsicherer Installer-Testpfad."
    }
    for ($attempt = 0; $attempt -lt 10; $attempt++) {
        if (-not (Test-Path -LiteralPath $resolvedRoot)) {
            return
        }
        try {
            [System.IO.Directory]::Delete($resolvedRoot, $true)
        }
        catch {
            if ($attempt -eq 9) {
                Write-Warning ("Der absichtlich erhaltene Test-Datenordner ist noch durch Windows geschuetzt: " + $resolvedRoot)
                return
            }
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            Start-Sleep -Milliseconds 500
        }
    }
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Der isolierte Diensttest benoetigt ein administratives PowerShell-Fenster."
}

$makensis = Resolve-Makensis
$testPort = Get-FreeLoopbackPort
New-Item -ItemType Directory -Force -Path $testRoot | Out-Null
New-Item -ItemType Directory -Force -Path $testInstallerRoot | Out-Null

try {
    if (-not $SkipBuild) {
        & $buildScript -SkipPwaBuild -SkipRestore -MakensisPath $makensis
        if ($LASTEXITCODE -ne 0) {
            throw "Produktiver Server-Installer-Build ist fehlgeschlagen."
        }
    }

    $compileArguments = @(
        "/WX",
        "/DTEST_MODE=1",
        "/DSERVER_VERSION=0.1.0",
        "/DSERVER_PAYLOAD=$payloadRoot",
        "/DOUTPUT_FILE=$testInstaller",
        "/DTEST_INSTALL_DIR=$installRoot",
        "/DTEST_DATA_DIR=$dataRoot",
        "/DTEST_PORT=$testPort",
        "/DSERVICE_NAME=$serviceName",
        "/DUPDATE_TASK_NAME=$updateTaskName",
        "/DPRODUCT_KEY=$productKey",
        "/DUNINSTALL_KEY=$uninstallKey",
        $installerScript
    )
    & $makensis @compileArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Isolierter Testinstaller konnte nicht erstellt werden."
    }

    $installProcess = Start-Process -FilePath $testInstaller -ArgumentList "/S" -PassThru -Wait
    if ($installProcess.ExitCode -ne 0) {
        throw "Server-Testinstallation ist mit Exitcode $($installProcess.ExitCode) fehlgeschlagen."
    }

    $service = Get-Service -Name $serviceName -ErrorAction Stop
    if ($service.Status -ne "Running") {
        throw "Isolierter Serverdienst laeuft nach der Installation nicht."
    }
    $serviceRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$serviceName"
    $imagePath = (Get-ItemProperty -LiteralPath $serviceRegistryPath -Name ImagePath).ImagePath
    $expectedImagePath = '"' + (Join-Path $installRoot "app\Meine-Budgetwelt-Server.exe") + '"'
    if ($imagePath -ne $expectedImagePath) {
        throw "Dienstpfad ist nicht sicher gequotet. Erwartet: $expectedImagePath; gefunden: $imagePath"
    }
    $updateTask = Get-ScheduledTask -TaskName $updateTaskName -ErrorAction Stop
    if ($updateTask.State -eq "Disabled") {
        throw "Autonome Server-Updateaufgabe ist deaktiviert."
    }
    foreach ($updaterFile in @(
        "app\updater\ServerUpdate.ps1",
        "app\updater\ServerUpdateContent.ps1",
        "app\updater\Install-ServerUpdateTask.ps1",
        "app\updater\server-update-public-key.xml",
        "app\tools\Configure-Integrations.ps1"
    )) {
        if (-not (Test-Path -LiteralPath (Join-Path $installRoot $updaterFile) -PathType Leaf)) {
            throw "Installierte Updater-Datei fehlt: $updaterFile"
        }
    }
    $health = Invoke-RestMethod -Uri "http://127.0.0.1:$testPort/health" -TimeoutSec 5
    if ($health.status -ne "ok" -or $health.database -ne "ok") {
        throw "Installierter Server meldet keinen gesunden Zustand."
    }

    $loginBody = @{
        email = "installer-test@example.invalid"
        password = "Installer-Test-2026!"
        rememberMe = $false
    } | ConvertTo-Json
    $login = Invoke-RestMethod `
        -Uri "http://127.0.0.1:$testPort/api/auth/desktop-login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loginBody
    if ([string]::IsNullOrWhiteSpace($login.token)) {
        throw "Das vom Installer erzeugte Administratorkonto funktioniert nicht."
    }

    $configPath = Join-Path $dataRoot "appsettings.json"
    $databasePath = Join-Path $dataRoot "data\budgetwelt.sqlite3"
    if (
        -not (Test-Path -LiteralPath $configPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $databasePath -PathType Leaf)
    ) {
        throw "Installierte Konfiguration oder isolierte Datenbank fehlt."
    }
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    if ($config.Server.ListenUrl -ne "http://127.0.0.1:$testPort") {
        throw "Installer hat einen falschen lokalen Port gespeichert."
    }
    if (
        $config.Updates.Enabled -ne $true -or
        $config.Email.PublicBaseUrl -ne "https://budget.leno.info" -or
        $config.LocalAi.Enabled -ne $true -or
        $config.LocalAi.Endpoint -ne "http://127.0.0.1:11434/api/chat" -or
        $config.LocalAi.Model -ne "qwen3.5:4b" -or
        $config.EnableBanking.Enabled -ne $false -or
        $config.EnableBanking.ApplicationId -ne "" -or
        $config.EnableBanking.PrivateKeyPath -ne (Join-Path $dataRoot "secrets\enable-banking-private.pem") -or
        $config.EnableBanking.RedirectBaseUrl -ne "https://budget.leno.info" -or
        $config.AllowedHosts -notmatch "budget\.leno\.info"
    ) {
        throw "Installierte Domain- oder Updatekonfiguration ist unvollstaendig."
    }

    $config.PSObject.Properties.Remove("LocalAi")
    $config.PSObject.Properties.Remove("EnableBanking")
    $config | Add-Member -MemberType NoteProperty -Name "GoCardless" -Value ([pscustomobject]@{
        Enabled = $true
        BaseUrl = "https://bankaccountdata.gocardless.com/api/v2/"
        RedirectBaseUrl = "https://budget.leno.info"
        DefaultCountry = "DE"
        SandboxMode = $false
        TimeoutSeconds = 45
    })
    [IO.File]::WriteAllText(
        $configPath,
        ($config | ConvertTo-Json -Depth 20) + [Environment]::NewLine,
        [Text.UTF8Encoding]::new($false)
    )

    $updateProcess = Start-Process -FilePath $testInstaller -ArgumentList "/S", "/SERVER_AUTO_UPDATE" -PassThru -Wait
    if ($updateProcess.ExitCode -ne 0) {
        throw "Server-Testupdate ist mit Exitcode $($updateProcess.ExitCode) fehlgeschlagen."
    }
    $service = Get-Service -Name $serviceName -ErrorAction Stop
    if ($service.Status -ne "Running") {
        throw "Isolierter Serverdienst laeuft nach dem Update nicht."
    }
    if (Test-Path -LiteralPath (Join-Path $installRoot "app.previous")) {
        throw "Rueckfallkopie wurde nach erfolgreichem Update nicht bereinigt."
    }
    if (-not (Get-ChildItem -LiteralPath (Join-Path $dataRoot "backups") -Directory -ErrorAction SilentlyContinue)) {
        throw "Vor dem Update wurde keine Serversicherung erzeugt."
    }
    $health = Invoke-RestMethod -Uri "http://127.0.0.1:$testPort/health" -TimeoutSec 5
    if ($health.status -ne "ok" -or $health.database -ne "ok") {
        throw "Aktualisierter Server meldet keinen gesunden Zustand."
    }
    $migratedConfig = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    if (
        $migratedConfig.LocalAi.Enabled -ne $true -or
        $migratedConfig.LocalAi.Endpoint -ne "http://127.0.0.1:11434/api/chat" -or
        $migratedConfig.LocalAi.Model -ne "qwen3.5:4b" -or
        $migratedConfig.EnableBanking.Enabled -ne $false -or
        $migratedConfig.EnableBanking.ApplicationId -ne "" -or
        $migratedConfig.EnableBanking.PrivateKeyPath -ne (Join-Path $dataRoot "secrets\enable-banking-private.pem") -or
        $migratedConfig.GoCardless.Enabled -ne $false
    ) {
        throw "Bestehende Serverkonfiguration wurde beim Update nicht sicher migriert."
    }
    if (-not (Get-ChildItem -LiteralPath $dataRoot -Filter "appsettings.json.before-integration-migration-*" -File)) {
        throw "Sicherung der Konfiguration vor der Integrationsmigration fehlt."
    }
    $loginAfterUpdate = Invoke-RestMethod `
        -Uri "http://127.0.0.1:$testPort/api/auth/desktop-login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loginBody
    if ([string]::IsNullOrWhiteSpace($loginAfterUpdate.token)) {
        throw "Administratorkonto blieb nach dem Update nicht erhalten."
    }

    $uninstallProcess = Start-Process -FilePath $uninstaller -ArgumentList "/S" -PassThru -Wait
    if ($uninstallProcess.ExitCode -ne 0) {
        throw "Server-Testdeinstallation ist fehlgeschlagen."
    }
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        if ($null -eq (Get-Service -Name $serviceName -ErrorAction SilentlyContinue)) {
            break
        }
        Start-Sleep -Milliseconds 250
    }
    if ($null -ne (Get-Service -Name $serviceName -ErrorAction SilentlyContinue)) {
        throw "Testdienst wurde bei der Deinstallation nicht entfernt."
    }
    if ($null -ne (Get-ScheduledTask -TaskName $updateTaskName -ErrorAction SilentlyContinue)) {
        throw "Server-Updateaufgabe wurde bei der Deinstallation nicht entfernt."
    }
    if (Test-Path -LiteralPath $installRoot) {
        throw "Testprogrammordner wurde bei der Deinstallation nicht entfernt."
    }
    if (-not (Test-Path -LiteralPath $databasePath -PathType Leaf)) {
        throw "Deinstallation hat persoenliche Serverdaten geloescht."
    }

    if (-not [string]::IsNullOrWhiteSpace($ResultPath)) {
        @{
            status = "ok"
            service = $serviceName
            port = $testPort
            testRoot = $testRoot
        } |
            ConvertTo-Json |
            Set-Content -LiteralPath $ResultPath -Encoding UTF8
    }
    Write-Host "Server-Installer-E2E erfolgreich: Setup, eigener Dienst, autonomer Updater, Update-Sicherung, Admin, PWA/API, Datenbank und Deinstallation."
}
catch {
    if (-not [string]::IsNullOrWhiteSpace($ResultPath)) {
        $tracePath = Join-Path $dataRoot "installer-test.log"
        $trace = if (Test-Path -LiteralPath $tracePath) {
            Get-Content -LiteralPath $tracePath -Raw
        }
        else {
            ""
        }
        @{
            status = "error"
            message = $_.Exception.Message
            service = $serviceName
            port = $testPort
            trace = $trace
        } | ConvertTo-Json | Set-Content -LiteralPath $ResultPath -Encoding UTF8
    }
    throw
}
finally {
    if (Test-Path -LiteralPath $uninstaller -PathType Leaf) {
        Start-Process -FilePath $uninstaller -ArgumentList "/S" -Wait | Out-Null
    }
    Remove-TestService
    Remove-TestUpdateTask
    Remove-Item -LiteralPath "HKLM:\$productKey" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath "HKLM:\$uninstallKey" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 1500
    Remove-TestFiles
}

exit 0
