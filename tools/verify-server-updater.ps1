param()

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path `
    (Join-Path $repositoryRoot ".godot\server-updater-tests") `
    ([Guid]::NewGuid().ToString("N"))
$privateKeyPath = Join-Path $testRoot "private-key.xml"
$publicKeyPath = Join-Path $testRoot "public-key.xml"
$installerPath = Join-Path $testRoot "test-installer.exe"
$manifestPath = Join-Path $testRoot "server-update-manifest.json"
$tamperedManifestPath = Join-Path $testRoot "tampered-manifest.json"
$dataRoot = Join-Path $testRoot "data"
$signingScript = Join-Path $PSScriptRoot "New-ServerUpdateManifest.ps1"
$updaterScript = Join-Path $repositoryRoot "installer\server-updater\ServerUpdate.ps1"
$contentConverterScript = Join-Path $repositoryRoot "installer\server-updater\ServerUpdateContent.ps1"

try {
    New-Item -ItemType Directory -Force -Path $testRoot | Out-Null

    $rsa = New-Object Security.Cryptography.RSACryptoServiceProvider(2048)
    try {
        [IO.File]::WriteAllText(
            $privateKeyPath,
            $rsa.ToXmlString($true),
            [Text.UTF8Encoding]::new($false))
        [IO.File]::WriteAllText(
            $publicKeyPath,
            $rsa.ToXmlString($false),
            [Text.UTF8Encoding]::new($false))
    }
    finally {
        $rsa.Dispose()
    }

    $testBytes = New-Object byte[] 8192
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($testBytes)
    [IO.File]::WriteAllBytes($installerPath, $testBytes)

    & $signingScript `
        -Version "0.1.1" `
        -InstallerPath $installerPath `
        -InstallerUrl "https://github.com/unique1986/meine-budgetwelt/releases/download/server-v0.1.1/Meine-Budgetwelt-Server-Setup-0.1.1.exe" `
        -PrivateKeyPath $privateKeyPath `
        -OutputPath $manifestPath `
        -PublishedUtc "2026-08-01T00:00:00+00:00"

    . $contentConverterScript
    $manifestBytes = [IO.File]::ReadAllBytes($manifestPath)
    $decodedManifest = Convert-ServerUpdateContentToText $manifestBytes | ConvertFrom-Json
    if ($decodedManifest.schemaVersion -ne 1 -or $decodedManifest.version -ne "0.1.1") {
        throw "Als Byte-Array geliefertes UTF-8-Manifest wurde nicht korrekt dekodiert."
    }
    $manifestString = Get-Content -LiteralPath $manifestPath -Raw
    if ((Convert-ServerUpdateContentToText $manifestString) -ne $manifestString) {
        throw "Bereits als Text geliefertes Manifest wurde veraendert."
    }

    $downloadOutput = & $updaterScript `
        -ManifestPath $manifestPath `
        -InstallerPath $installerPath `
        -PublicKeyPath $publicKeyPath `
        -DataRoot $dataRoot `
        -CurrentVersion "0.1.0" `
        -DownloadOnly
    if ($LASTEXITCODE -ne 0) {
        throw "Gueltiges signiertes Update wurde abgelehnt."
    }
    $downloadedPath = [string]($downloadOutput | Select-Object -Last 1)
    if (-not (Test-Path -LiteralPath $downloadedPath -PathType Leaf)) {
        throw "Geprueftes Updatepaket wurde nicht gespeichert."
    }
    $sourceHash = (Get-FileHash -LiteralPath $installerPath -Algorithm SHA256).Hash
    $downloadHash = (Get-FileHash -LiteralPath $downloadedPath -Algorithm SHA256).Hash
    if ($sourceHash -ne $downloadHash) {
        throw "Gespeichertes Updatepaket wurde veraendert."
    }

    $tampered = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $tampered.version = "9.9.9"
    [IO.File]::WriteAllText(
        $tamperedManifestPath,
        ($tampered | ConvertTo-Json) + [Environment]::NewLine,
        [Text.UTF8Encoding]::new($false))
    & $updaterScript `
        -ManifestPath $tamperedManifestPath `
        -InstallerPath $installerPath `
        -PublicKeyPath $publicKeyPath `
        -DataRoot (Join-Path $testRoot "tampered-data") `
        -CurrentVersion "0.1.0" `
        -DownloadOnly 2>$null
    if ($LASTEXITCODE -eq 0) {
        throw "Manipuliertes Update-Manifest wurde akzeptiert."
    }

    $olderDataRoot = Join-Path $testRoot "older-data"
    & $updaterScript `
        -ManifestPath $manifestPath `
        -InstallerPath $installerPath `
        -PublicKeyPath $publicKeyPath `
        -DataRoot $olderDataRoot `
        -CurrentVersion "0.1.1" `
        -DownloadOnly | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Gleiche Version wurde nicht sauber ignoriert."
    }
    if (Test-Path -LiteralPath (Join-Path $olderDataRoot "updates") -PathType Container) {
        throw "Gleiche Version wurde unnoetig heruntergeladen."
    }

    Write-Host "Server-Updater-Pruefung erfolgreich: UTF-8-Byteantwort, RSA-Signatur, SHA-256, Versionsschutz und Manipulationsabwehr."
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
