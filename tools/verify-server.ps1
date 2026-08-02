param(
    [string]$Configuration = "Release",
    [string]$ExecutablePath = "",
    [string]$PwaRoot = ""
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$serverProject = Join-Path $repositoryRoot "server\MeineBudgetwelt.Server\MeineBudgetwelt.Server.csproj"
$serverDll = Join-Path $repositoryRoot "server\MeineBudgetwelt.Server\bin\$Configuration\net10.0\Meine-Budgetwelt-Server.dll"
$testParent = Join-Path $repositoryRoot ".godot\server-tests"
$testRoot = Join-Path $testParent ("MeineBudgetweltServer-Test-" + [Guid]::NewGuid().ToString("N"))
$dataRoot = Join-Path $testRoot "isolated-data"
$emailPickupDirectory = Join-Path $testRoot "email-pickup"
$standardOutput = Join-Path $testRoot "server.stdout.log"
$standardError = Join-Path $testRoot "server.stderr.log"
$serverProcess = $null
$previousDataDirectory = $env:BUDGETWELT_DATA_DIR
$resolvedPwaRoot = ""

if (-not [string]::IsNullOrWhiteSpace($PwaRoot)) {
    if (-not (Test-Path -LiteralPath $PwaRoot -PathType Container)) {
        throw "PWA-Ordner wurde nicht gefunden: $PwaRoot"
    }
    $resolvedPwaRoot = (Resolve-Path -LiteralPath $PwaRoot).Path
    foreach ($requiredPwaFile in @(
        "index.html",
        "index.js",
        "index.pck",
        "index.wasm",
        "index.manifest.json",
        "index.service.worker.js"
    )) {
        if (-not (Test-Path -LiteralPath (Join-Path $resolvedPwaRoot $requiredPwaFile) -PathType Leaf)) {
            throw "PWA-Datei fehlt: $requiredPwaFile"
        }
    }
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

try {
    New-Item -ItemType Directory -Force -Path $testRoot | Out-Null

    if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
        dotnet build $serverProject --configuration $Configuration --no-restore
        if ($LASTEXITCODE -ne 0) {
            throw "Server-Build fehlgeschlagen."
        }
        $launchFile = "dotnet"
        $launchArguments = @($serverDll)
    }
    else {
        if (-not (Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) {
            throw "Veroeffentlichte Server-EXE wurde nicht gefunden."
        }
        $launchFile = (Resolve-Path -LiteralPath $ExecutablePath).Path
        $launchArguments = @()
    }

    $port = Get-FreeLoopbackPort
    $env:BUDGETWELT_DATA_DIR = $dataRoot
    $env:BUDGETWELT_EMAIL_PICKUP_DIR = $emailPickupDirectory
    $bootstrapPassword = "Test!" + [Guid]::NewGuid().ToString("N")
    $env:BUDGETWELT_BOOTSTRAP_PASSWORD = $bootstrapPassword
    $bootstrapArguments = $launchArguments + @(
        "bootstrap-admin",
        "--name",
        "Test Admin",
        "--email",
        "admin@example.invalid"
    )
    & $launchFile @bootstrapArguments
    $env:BUDGETWELT_BOOTSTRAP_PASSWORD = $null
    if ($LASTEXITCODE -ne 0) {
        throw "Erstes Administratorkonto konnte nicht angelegt werden."
    }

    $launchArguments += @(
        "--Server:ListenUrl=http://127.0.0.1:$port",
        "--Email:FromAddress=noreply@example.invalid",
        "--Email:PublicBaseUrl=http://localhost/"
    )
    if (-not [string]::IsNullOrWhiteSpace($resolvedPwaRoot)) {
        $launchArguments += "--Server:PwaRoot=$resolvedPwaRoot"
    }
    Normalize-ProcessPathEnvironment
    $serverProcess = Start-Process -FilePath $launchFile -ArgumentList $launchArguments -PassThru -WindowStyle Hidden -RedirectStandardOutput $standardOutput -RedirectStandardError $standardError

    $healthUri = "http://127.0.0.1:$port/health"
    $health = $null
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        if ($serverProcess.HasExited) {
            throw "Server wurde unerwartet beendet."
        }
        try {
            $health = Invoke-RestMethod -Uri $healthUri -TimeoutSec 2
            break
        }
        catch {
            Start-Sleep -Milliseconds 250
        }
    }

    if ($null -eq $health) {
        throw "Gesundheitspruefung war nicht erreichbar."
    }
    if ($health.status -ne "ok" -or $health.database -ne "ok") {
        throw "Gesundheitspruefung meldet keinen fehlerfreien Zustand."
    }
    if ($health.service -ne "MeineBudgetweltServer") {
        throw "Gesundheitspruefung meldet einen unerwarteten Dienstnamen."
    }
    if ($health.aiPlanningEnabled -ne $false -or $health.bankDataEnabled -ne $false) {
        throw "Nicht konfigurierte externe Dienste werden im Gesundheitsstatus faelschlich als aktiv gemeldet."
    }

    $adminPage = Invoke-WebRequest `
        -Uri "http://127.0.0.1:$port/admin/" `
        -UseBasicParsing
    if (
        $adminPage.StatusCode -ne 200 -or
        $adminPage.Content -notmatch "Meine Budgetwelt" -or
        $adminPage.Content -notmatch "Administration"
    ) {
        throw "Admin-Oberflaeche wurde nicht korrekt ausgeliefert."
    }
    if (
        $adminPage.Headers["Cache-Control"] -notmatch "no-store" -or
        $adminPage.Headers["Content-Security-Policy"] -notmatch "default-src 'self'" -or
        $adminPage.Headers["X-Frame-Options"] -ne "DENY"
    ) {
        throw "Admin-Oberflaeche besitzt unvollstaendige Sicherheitsheader."
    }
    foreach ($adminAsset in @(
        @{ Path = "admin.css"; Type = "text/css" },
        @{ Path = "admin.js"; Type = "javascript" },
        @{ Path = "budget-world-island.png"; Type = "image/png" }
    )) {
        $assetResponse = Invoke-WebRequest `
            -Uri "http://127.0.0.1:$port/admin/$($adminAsset.Path)" `
            -Method Head `
            -UseBasicParsing
        if ($assetResponse.Headers["Content-Type"] -notmatch $adminAsset.Type) {
            throw "Admin-Asset hat einen falschen MIME-Typ: $($adminAsset.Path)"
        }
    }

    foreach ($legalPage in @(
        @{ Path = "datenschutz"; Required = "Datenschutz" },
        @{ Path = "nutzungsbedingungen"; Required = "Nutzungsbedingungen" }
    )) {
        $legalResponse = Invoke-WebRequest `
            -Uri "http://127.0.0.1:$port/$($legalPage.Path)" `
            -UseBasicParsing
        if (
            $legalResponse.StatusCode -ne 200 -or
            $legalResponse.Headers["Content-Type"] -notmatch "text/html" -or
            $legalResponse.Content -notmatch $legalPage.Required -or
            $legalResponse.Content -notmatch "Enable Banking"
        ) {
            throw "Öffentliche Rechtstextseite wurde nicht korrekt ausgeliefert: $($legalPage.Path)"
        }
        if (
            $legalResponse.Headers["Cache-Control"] -notmatch "no-store" -or
            $legalResponse.Headers["Content-Security-Policy"] -notmatch "default-src 'self'" -or
            $legalResponse.Headers["X-Frame-Options"] -ne "DENY"
        ) {
            throw "Rechtstextseite besitzt unvollständige Sicherheitsheader: $($legalPage.Path)"
        }
    }
    $legalCssResponse = Invoke-WebRequest `
        -Uri "http://127.0.0.1:$port/legal/legal.css" `
        -Method Head `
        -UseBasicParsing
    if (
        $legalCssResponse.Headers["Content-Type"] -notmatch "text/css" -or
        $legalCssResponse.Headers["Cache-Control"] -notmatch "no-store"
    ) {
        throw "Stylesheet der Rechtstextseiten wird nicht sicher ausgeliefert."
    }

    if (-not [string]::IsNullOrWhiteSpace($resolvedPwaRoot)) {
        $rootResponse = Invoke-WebRequest -Uri "http://127.0.0.1:$port/" -UseBasicParsing
        if ($rootResponse.StatusCode -ne 200 -or $rootResponse.Headers["Content-Type"] -notmatch "text/html") {
            throw "PWA-Startseite wurde nicht korrekt ausgeliefert."
        }
        if ($rootResponse.Headers["Cache-Control"] -notmatch "no-store") {
            throw "PWA-Startseite darf nicht dauerhaft zwischengespeichert werden."
        }
        $contentSecurityPolicy = $rootResponse.Headers["Content-Security-Policy"]
        $hasRequiredContentPolicy = (
            $contentSecurityPolicy -match "default-src 'self'" -and
            $contentSecurityPolicy -match "connect-src 'self'"
        )
        if (
            -not $hasRequiredContentPolicy -or
            $rootResponse.Headers["X-Content-Type-Options"] -ne "nosniff" -or
            $rootResponse.Headers["X-Frame-Options"] -ne "DENY"
        ) {
            throw "PWA-Sicherheitsheader fehlen oder sind unvollstaendig."
        }
        $serviceWorkerResponse = Invoke-WebRequest -Uri "http://127.0.0.1:$port/index.service.worker.js" -UseBasicParsing
        if ($serviceWorkerResponse.Headers["Cache-Control"] -notmatch "no-store") {
            throw "PWA-Service-Worker darf nicht dauerhaft zwischengespeichert werden."
        }
        $pckResponse = Invoke-WebRequest -Uri "http://127.0.0.1:$port/index.pck" -Method Head -UseBasicParsing
        if ($pckResponse.Headers["Content-Type"] -notmatch "application/octet-stream") {
            throw "PWA-Paket hat einen unerwarteten MIME-Typ."
        }
        $wasmResponse = Invoke-WebRequest -Uri "http://127.0.0.1:$port/index.wasm" -Method Head -UseBasicParsing
        if ($wasmResponse.Headers["Content-Type"] -notmatch "application/wasm") {
            throw "PWA-WebAssembly-Datei hat einen unerwarteten MIME-Typ."
        }
    }

    $loginBody = @{
        email = "admin@example.invalid"
        password = $bootstrapPassword
        rememberMe = $false
    } | ConvertTo-Json
    $login = Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/auth/desktop-login" -Method Post -ContentType "application/json" -Body $loginBody
    if ([string]::IsNullOrWhiteSpace($login.token)) {
        throw "Desktop-Anmeldung hat kein Sitzungstoken geliefert."
    }
    $headers = @{ Authorization = "Bearer $($login.token)" }

    $unauthenticatedSyncWasRejected = $false
    try {
        Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/sync/groups" | Out-Null
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 401) {
            $unauthenticatedSyncWasRejected = $true
        }
        else {
            throw
        }
    }
    if (-not $unauthenticatedSyncWasRejected) {
        throw "Synchronisationsdaten waren ohne Anmeldung erreichbar."
    }

    $unauthenticatedAdminWasRejected = $false
    try {
        Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/admin/users" | Out-Null
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 401) {
            $unauthenticatedAdminWasRejected = $true
        }
        else {
            throw
        }
    }
    if (-not $unauthenticatedAdminWasRejected) {
        throw "Admin-Daten waren ohne Anmeldung erreichbar."
    }

    $pwaLoginResponse = Invoke-WebRequest `
        -Uri "http://127.0.0.1:$port/api/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loginBody `
        -UseBasicParsing
    $pwaSessionCookie = $pwaLoginResponse.Headers["Set-Cookie"]
    $hasProtectedPwaCookie = (
        $pwaSessionCookie -match "__Host-mbw_session=" -and
        $pwaSessionCookie -match "httponly" -and
        $pwaSessionCookie -match "secure" -and
        $pwaSessionCookie -match "samesite=strict" -and
        $pwaSessionCookie -match "path=/"
    )
    if (
        $pwaLoginResponse.StatusCode -ne 200 -or
        -not $hasProtectedPwaCookie
    ) {
        throw "PWA-Anmeldung setzt kein vollstaendig geschuetztes Sitzungscookie."
    }

    $users = @(Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/admin/users" -Headers $headers)
    if ($users.Count -ne 1 -or -not $users[0].isSystemAdmin) {
        throw "Admin-Benutzerliste ist ungueltig."
    }

    $newUserPassword = "Nutzer!" + [Guid]::NewGuid().ToString("N")
    $createUserBody = @{
        name = "Test Nutzer"
        email = "user@example.invalid"
        password = $newUserPassword
        isSystemAdmin = $false
    } | ConvertTo-Json
    $newUser = Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/admin/users" -Method Post -Headers $headers -ContentType "application/json" -Body $createUserBody
    if ([string]::IsNullOrWhiteSpace($newUser.id)) {
        throw "Benutzerkonto wurde nicht erstellt."
    }

    $groups = @(Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/admin/groups" -Headers $headers)
    if ($groups.Count -ne 1) {
        throw "Persoenliche Start-Budgetgruppe fehlt."
    }
    $planningBody = @{
        weeklyBudgetCents = 7000
        safetyBufferCents = 1000
        people = 2
        servingsPerMeal = 2
        maxActiveMinutes = 30
        dietaryStyle = "Alles"
        planningStyle = "Meal-Prep"
        allergies = @()
        excludedIngredients = @()
        preferredIngredients = @()
        pantry = @()
        personalPrices = @()
    } | ConvertTo-Json -Depth 10
    $planningWithoutLoginWasRejected = $false
    try {
        Invoke-RestMethod `
            -Uri "http://127.0.0.1:$port/api/planning/groups/$($groups[0].id)/weekly-plan" `
            -Method Post `
            -ContentType "application/json" `
            -Body $planningBody | Out-Null
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 401) {
            $planningWithoutLoginWasRejected = $true
        }
        else {
            throw
        }
    }
    if (-not $planningWithoutLoginWasRejected) {
        throw "KI-Planung war ohne Anmeldung erreichbar."
    }
    $invalidPlanningWasRejected = $false
    try {
        Invoke-RestMethod `
            -Uri "http://127.0.0.1:$port/api/planning/groups/$($groups[0].id)/weekly-plan" `
            -Method Post `
            -Headers $headers `
            -ContentType "application/json" `
            -Body (@{
                weeklyBudgetCents = 0
                safetyBufferCents = 0
                people = 2
                servingsPerMeal = 2
                maxActiveMinutes = 30
                dietaryStyle = "Alles"
                planningStyle = "Meal-Prep"
                allergies = @()
                excludedIngredients = @()
                preferredIngredients = @()
                pantry = @()
                personalPrices = @()
            } | ConvertTo-Json -Depth 10) | Out-Null
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 400) {
            $invalidPlanningWasRejected = $true
        }
        else {
            throw
        }
    }
    if (-not $invalidPlanningWasRejected) {
        throw "Ungueltige KI-Planungsdaten wurden angenommen."
    }
    $disabledPlanningWasRejected = $false
    try {
        Invoke-RestMethod `
            -Uri "http://127.0.0.1:$port/api/planning/groups/$($groups[0].id)/weekly-plan" `
            -Method Post `
            -Headers $headers `
            -ContentType "application/json" `
            -Body $planningBody | Out-Null
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 503) {
            $disabledPlanningWasRejected = $true
        }
        else {
            throw
        }
    }
    if (-not $disabledPlanningWasRejected) {
        throw "Nicht konfigurierte KI-Planung wurde nicht sicher gestoppt."
    }
    $bankingWithoutLoginWasRejected = $false
    try {
        Invoke-RestMethod `
            -Uri "http://127.0.0.1:$port/api/banking/status" | Out-Null
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 401) {
            $bankingWithoutLoginWasRejected = $true
        }
        else {
            throw
        }
    }
    if (-not $bankingWithoutLoginWasRejected) {
        throw "Bankstatus war ohne Anmeldung erreichbar."
    }
    $bankingStatus = Invoke-RestMethod `
        -Uri "http://127.0.0.1:$port/api/banking/status" `
        -Headers $headers
    if (
        $bankingStatus.enabled -ne $false -or
        $bankingStatus.mode -ne "read-only" -or
        $bankingStatus.automaticRefresh -ne $false -or
        $bankingStatus.payments -ne $false
    ) {
        throw "Bankstatus verletzt den strikt lesenden, manuellen Betriebsmodus."
    }
    $bankConnectionsResponse = Invoke-WebRequest `
        -Uri "http://127.0.0.1:$port/api/banking/groups/$($groups[0].id)/connections" `
        -Headers $headers `
        -UseBasicParsing
    if ($bankConnectionsResponse.Content.Trim() -ne "[]") {
        throw "Neue Budgetgruppe enthaelt unerwartete Bankverbindungen."
    }
    $disabledBankingWasRejected = $false
    try {
        Invoke-RestMethod `
            -Uri "http://127.0.0.1:$port/api/banking/institutions?country=DE" `
            -Headers $headers | Out-Null
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 503) {
            $disabledBankingWasRejected = $true
        }
        else {
            throw
        }
    }
    if (-not $disabledBankingWasRejected) {
        throw "Nicht konfigurierte Bankanbindung wurde nicht sicher gestoppt."
    }
    $disabledBankConnectionWasRejected = $false
    try {
        Invoke-RestMethod `
            -Uri "http://127.0.0.1:$port/api/banking/groups/$($groups[0].id)/connections" `
            -Method Post `
            -Headers $headers `
            -ContentType "application/json" `
            -Body (@{ institutionId = "eb_00000000000000000000000000000000" } | ConvertTo-Json) | Out-Null
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 503) {
            $disabledBankConnectionWasRejected = $true
        }
        else {
            throw
        }
    }
    if (-not $disabledBankConnectionWasRejected) {
        throw "Bankverbindung konnte ohne serverseitige Zugangsdaten angelegt werden."
    }
    $memberBody = @{
        userId = $newUser.id
        role = "member"
    } | ConvertTo-Json
    Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/admin/groups/$($groups[0].id)/members" -Method Put -Headers $headers -ContentType "application/json" -Body $memberBody | Out-Null
    $members = Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/admin/groups/$($groups[0].id)/members" -Headers $headers
    if ($members.Count -ne 2) {
        throw ("Zuordnung zur gemeinsamen Budgetgruppe ist fehlgeschlagen. Anzahl={0}; Daten={1}" -f $members.Count, ($members | ConvertTo-Json -Compress))
    }

    $temporaryGroup = Invoke-RestMethod `
        -Uri "http://127.0.0.1:$port/api/admin/groups" `
        -Method Post `
        -Headers $headers `
        -ContentType "application/json" `
        -Body (@{ name = "Nur zum Loeschen" } | ConvertTo-Json)
    $wrongConfirmationWasRejected = $false
    try {
        Invoke-RestMethod `
            -Uri "http://127.0.0.1:$port/api/admin/groups/$($temporaryGroup.id)?confirmationName=Falscher%20Name" `
            -Method Delete `
            -Headers $headers | Out-Null
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 400) {
            $wrongConfirmationWasRejected = $true
        }
        else {
            throw
        }
    }
    if (-not $wrongConfirmationWasRejected) {
        throw "Budgetgruppe konnte ohne korrekten Bestaetigungsnamen geloescht werden."
    }
    Invoke-RestMethod `
        -Uri "http://127.0.0.1:$port/api/admin/groups/$($temporaryGroup.id)?confirmationName=Nur%20zum%20Loeschen" `
        -Method Delete `
        -Headers $headers | Out-Null
    $groupsAfterDeletion = @(
        Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/admin/groups" -Headers $headers
    )
    if ($groupsAfterDeletion.Count -ne 1) {
        throw "Budgetgruppe wurde nicht sicher geloescht."
    }

    $invitationBody = @{
        name = "Eingeladene Person"
        email = "invited@example.invalid"
        groupId = $groups[0].id
        role = "member"
    } | ConvertTo-Json
    $invitation = Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/admin/invitations" -Method Post -Headers $headers -ContentType "application/json" -Body $invitationBody
    if ([string]::IsNullOrWhiteSpace($invitation.id)) {
        throw "Einladung wurde nicht angelegt."
    }
    $invitationMail = Get-ChildItem -LiteralPath $emailPickupDirectory -Filter *.eml | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    if ($null -eq $invitationMail) {
        throw "Einladungs-E-Mail wurde nicht erzeugt."
    }
    $invitationMailText = Get-Content -LiteralPath $invitationMail.FullName -Raw
    $invitationTokenMatch = [regex]::Match(
        $invitationMailText,
        "konto-erstellen\?token=([A-Za-z0-9_-]+)"
    )
    if (-not $invitationTokenMatch.Success) {
        throw "Einladungstoken fehlt in der E-Mail."
    }
    $invitedPassword = "Eingeladen!" + [Guid]::NewGuid().ToString("N")
    $registerBody = @{
        token = $invitationTokenMatch.Groups[1].Value
        name = "Eingeladene Person"
        password = $invitedPassword
    } | ConvertTo-Json
    $registered = Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/auth/register" -Method Post -ContentType "application/json" -Body $registerBody
    if ($registered.email -ne "invited@example.invalid") {
        throw "Registrierung mit Einladung ist fehlgeschlagen."
    }

    $invitedLoginBody = @{
        email = "invited@example.invalid"
        password = $invitedPassword
        rememberMe = $false
    } | ConvertTo-Json
    $invitedLogin = Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/auth/desktop-login" -Method Post -ContentType "application/json" -Body $invitedLoginBody
    $invitedHeaders = @{ Authorization = "Bearer $($invitedLogin.token)" }

    $syncGroups = Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/sync/groups" -Headers $headers
    if ($syncGroups.Count -ne 1 -or $syncGroups[0].revision -ne 0) {
        throw "Leere Synchronisationsgruppe wurde nicht korrekt gemeldet."
    }
    $incompleteSyncBody = @{
        baseRevision = 0
        deviceId = "desktop-test-0001"
        data = @{
            schemaVersion = 1
            files = @{
                "budget_data.json" = @{ balance = 1234.56 }
            }
        }
    } | ConvertTo-Json -Depth 20
    $incompleteSyncWasRejected = $false
    try {
        Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/sync/groups/$($groups[0].id)/snapshot" -Method Put -Headers $headers -ContentType "application/json" -Body $incompleteSyncBody | Out-Null
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 400) {
            $incompleteSyncWasRejected = $true
        }
        else {
            throw
        }
    }
    if (-not $incompleteSyncWasRejected) {
        throw "Unvollstaendiger Synchronisationsstand wurde angenommen."
    }
    $initialSyncBody = @{
        baseRevision = 0
        deviceId = "desktop-test-0001"
        data = @{
            schemaVersion = 1
            files = @{
                "budget_data.json" = @{ balance = 1234.56 }
                "fixed_costs.json" = @()
                "month_history.json" = @{}
                "savings_goals.json" = @()
                "transactions.json" = @{}
                "shopping.json" = @{}
                "meal_plans.json" = @{}
                "custom_recipes.json" = @()
            }
        }
    } | ConvertTo-Json -Depth 20
    $firstSnapshot = Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/sync/groups/$($groups[0].id)/snapshot" -Method Put -Headers $headers -ContentType "application/json" -Body $initialSyncBody
    if ($firstSnapshot.revision -ne 1) {
        throw "Erster Synchronisationsstand wurde nicht gespeichert."
    }
    $downloadedSnapshot = Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/sync/groups/$($groups[0].id)/snapshot" -Headers $invitedHeaders
    if ($downloadedSnapshot.revision -ne 1 -or $downloadedSnapshot.data.files.'budget_data.json'.balance -ne 1234.56) {
        throw "Zweiter Client hat nicht denselben Synchronisationsstand erhalten."
    }
    $changedSyncBody = @{
        baseRevision = 1
        deviceId = "pwa-test-0002"
        data = @{
            schemaVersion = 1
            files = @{
                "budget_data.json" = @{ balance = 987.65 }
                "fixed_costs.json" = @()
                "month_history.json" = @{}
                "savings_goals.json" = @()
                "transactions.json" = @{}
                "shopping.json" = @{}
                "meal_plans.json" = @{}
                "custom_recipes.json" = @()
            }
        }
    } | ConvertTo-Json -Depth 20
    $secondSnapshot = Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/sync/groups/$($groups[0].id)/snapshot" -Method Put -Headers $invitedHeaders -ContentType "application/json" -Body $changedSyncBody
    if ($secondSnapshot.revision -ne 2) {
        throw "Aenderung des zweiten Clients wurde nicht gespeichert."
    }
    $staleWriteWasRejected = $false
    try {
        Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/sync/groups/$($groups[0].id)/snapshot" -Method Put -Headers $headers -ContentType "application/json" -Body $changedSyncBody | Out-Null
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 409) {
            $staleWriteWasRejected = $true
        }
        else {
            throw
        }
    }
    if (-not $staleWriteWasRejected) {
        throw "Veralteter Synchronisationsstand konnte neuere Daten ueberschreiben."
    }

    $forgotBody = @{ email = "invited@example.invalid" } | ConvertTo-Json
    Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/auth/forgot-password" -Method Post -ContentType "application/json" -Body $forgotBody | Out-Null
    $resetMail = Get-ChildItem -LiteralPath $emailPickupDirectory -Filter *.eml | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    $resetMailText = Get-Content -LiteralPath $resetMail.FullName -Raw
    $resetTokenMatch = [regex]::Match(
        $resetMailText,
        "kennwort-zuruecksetzen\?token=([A-Za-z0-9_-]+)"
    )
    if (-not $resetTokenMatch.Success) {
        throw "Kennwort-Reset-Token fehlt in der E-Mail."
    }
    $newInvitedPassword = "Neu!" + [Guid]::NewGuid().ToString("N")
    $resetBody = @{
        token = $resetTokenMatch.Groups[1].Value
        password = $newInvitedPassword
    } | ConvertTo-Json
    Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/auth/reset-password" -Method Post -ContentType "application/json" -Body $resetBody | Out-Null

    $oldSessionWasRevoked = $false
    try {
        Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/auth/me" -Headers $invitedHeaders | Out-Null
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 401) {
            $oldSessionWasRevoked = $true
        }
        else {
            throw
        }
    }
    if (-not $oldSessionWasRevoked) {
        throw "Kennwortaenderung hat die alte Sitzung nicht widerrufen."
    }
    $newInvitedLoginBody = @{
        email = "invited@example.invalid"
        password = $newInvitedPassword
        rememberMe = $false
    } | ConvertTo-Json
    $newInvitedLogin = Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/auth/desktop-login" -Method Post -ContentType "application/json" -Body $newInvitedLoginBody
    if ([string]::IsNullOrWhiteSpace($newInvitedLogin.token)) {
        throw "Anmeldung mit dem neuen Kennwort ist fehlgeschlagen."
    }

    $deactivateBody = @{ isActive = $false } | ConvertTo-Json
    Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/admin/users/$($newUser.id)/active" -Method Patch -Headers $headers -ContentType "application/json" -Body $deactivateBody | Out-Null
    $blockedLoginBody = @{
        email = "user@example.invalid"
        password = $newUserPassword
        rememberMe = $false
    } | ConvertTo-Json
    $blockedLoginWasRejected = $false
    try {
        Invoke-RestMethod -Uri "http://127.0.0.1:$port/api/auth/desktop-login" -Method Post -ContentType "application/json" -Body $blockedLoginBody | Out-Null
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 401) {
            $blockedLoginWasRejected = $true
        }
        else {
            throw
        }
    }
    if (-not $blockedLoginWasRejected) {
        throw "Gesperrtes Benutzerkonto konnte sich weiterhin anmelden."
    }

    $databasePath = Join-Path $dataRoot "data\budgetwelt.sqlite3"
    if (-not (Test-Path -LiteralPath $databasePath -PathType Leaf)) {
        throw "Die isolierte SQLite-Datenbank wurde nicht angelegt."
    }

    $pwaResult = if ([string]::IsNullOrWhiteSpace($resolvedPwaRoot)) { "" } else { ", PWA-Auslieferung" }
    Write-Host "Server-Pruefung erfolgreich: Konten, PWA-Cookie, API-Schutz, E-Mail, KI-Schutz, Nur-Lese-Banking, zwei synchronisierte Clients, Konfliktschutz, Sperre, Datenbank, Gesundheitsstatus$pwaResult."
}
finally {
    if ($null -ne $serverProcess -and -not $serverProcess.HasExited) {
        Stop-Process -Id $serverProcess.Id -Force
        $serverProcess.WaitForExit()
    }

    $env:BUDGETWELT_DATA_DIR = $previousDataDirectory
    $env:BUDGETWELT_BOOTSTRAP_PASSWORD = $null
    $env:BUDGETWELT_EMAIL_PICKUP_DIR = $null

    if (Test-Path -LiteralPath $testRoot) {
        $resolvedTestRoot = (Resolve-Path -LiteralPath $testRoot).Path
        $safePrefix = [System.IO.Path]::GetFullPath(
            (Join-Path $testParent "MeineBudgetweltServer-Test-")
        )
        if (-not $resolvedTestRoot.StartsWith(
            $safePrefix,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Unsicherer Testpfad; Aufraeumen wurde verweigert."
        }
        Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
}
