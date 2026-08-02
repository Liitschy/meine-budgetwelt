param(
    [string]$ManifestPath = "",
    [string]$InstallerPath = "",
    [string]$PublicKeyPath = "",
    [string]$DataRoot = "",
    [string]$InstallRoot = "",
    [string]$CurrentVersion = "",
    [switch]$DownloadOnly
)

$ErrorActionPreference = "Stop"
$officialRepositoryPath = "/unique1986/meine-budgetwelt/releases/"
$defaultManifestUrl = "https://github.com/unique1986/meine-budgetwelt/releases/download/server-updates/server-update-manifest.json"
$maximumInstallerBytes = 160MB
$mutex = $null
$hasMutex = $false
$contentConverterPath = Join-Path $PSScriptRoot "ServerUpdateContent.ps1"
if (-not (Test-Path -LiteralPath $contentConverterPath -PathType Leaf)) {
    throw "Die sichere Manifest-Dekodierung fehlt."
}
. $contentConverterPath

function Write-UpdateLog([string]$Message) {
    if ([string]::IsNullOrWhiteSpace($script:DataRoot)) {
        return
    }
    $logDirectory = Join-Path $script:DataRoot "logs"
    New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
    $logPath = Join-Path $logDirectory "server-updater.log"
    $line = "{0} {1}{2}" -f [DateTimeOffset]::UtcNow.ToString("O"), $Message, [Environment]::NewLine
    [IO.File]::AppendAllText($logPath, $line, [Text.UTF8Encoding]::new($false))
}

function Get-CanonicalManifestText($Manifest) {
    return "schemaVersion={0}`nversion={1}`ninstallerUrl={2}`nsha256={3}`npublishedUtc={4}" -f `
        $Manifest.schemaVersion,
        $Manifest.version,
        $Manifest.installerUrl,
        $Manifest.sha256.ToLowerInvariant(),
        $Manifest.publishedUtc
}

function Assert-OfficialHttpsUrl([string]$Value, [string]$Label, [string]$RequiredPath) {
    $uri = $null
    if (-not [Uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$uri)) {
        throw "$Label ist keine gueltige Adresse."
    }
    if (
        $uri.Scheme -ne "https" -or
        $uri.Host -ne "github.com" -or
        -not $uri.AbsolutePath.StartsWith($RequiredPath, [StringComparison]::Ordinal)
    ) {
        throw "$Label verweist nicht auf die festgelegte offizielle HTTPS-Quelle."
    }
    return $uri
}

function Get-FileSha256([string]$Path) {
    $stream = [IO.File]::OpenRead($Path)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace("-", "").ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
        $stream.Dispose()
    }
}

try {
    $mutex = New-Object Threading.Mutex($false, "Global\MeineBudgetweltServerUpdater")
    $hasMutex = $mutex.WaitOne(0)
    if (-not $hasMutex) {
        exit 0
    }

    if ([string]::IsNullOrWhiteSpace($DataRoot)) {
        $DataRoot = Join-Path $env:ProgramData "Meine Budgetwelt Server"
    }
    $script:DataRoot = [IO.Path]::GetFullPath($DataRoot)

    $configurationPath = Join-Path $script:DataRoot "appsettings.json"
    $configuration = $null
    if (Test-Path -LiteralPath $configurationPath -PathType Leaf) {
        $configuration = Get-Content -LiteralPath $configurationPath -Raw | ConvertFrom-Json
    }
    if (
        [string]::IsNullOrWhiteSpace($ManifestPath) -and
        $null -ne $configuration -and
        $configuration.Updates.Enabled -ne $true
    ) {
        Write-UpdateLog "Updatepruefung ist deaktiviert."
        exit 0
    }

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        $InstallRoot = (Get-ItemProperty `
            -LiteralPath "HKLM:\Software\Meine Budgetwelt Server" `
            -Name InstallDir `
            -ErrorAction SilentlyContinue).InstallDir
    }
    if ([string]::IsNullOrWhiteSpace($CurrentVersion)) {
        $CurrentVersion = (Get-ItemProperty `
            -LiteralPath "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\MeineBudgetweltServer" `
            -Name DisplayVersion `
            -ErrorAction SilentlyContinue).DisplayVersion
    }
    if ([string]::IsNullOrWhiteSpace($CurrentVersion)) {
        throw "Die installierte Serverversion wurde nicht gefunden."
    }
    $current = [Version]$CurrentVersion

    if ([string]::IsNullOrWhiteSpace($PublicKeyPath)) {
        $PublicKeyPath = Join-Path $PSScriptRoot "server-update-public-key.xml"
    }
    if (-not (Test-Path -LiteralPath $PublicKeyPath -PathType Leaf)) {
        throw "Der fest eingebaute Update-Pruefschluessel fehlt."
    }

    if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
        $manifestUrl = if (
            $null -ne $configuration -and
            -not [string]::IsNullOrWhiteSpace($configuration.Updates.ManifestUrl)
        ) { [string]$configuration.Updates.ManifestUrl } else { $defaultManifestUrl }
        Assert-OfficialHttpsUrl $manifestUrl "Manifestadresse" ($officialRepositoryPath + "download/server-updates/") | Out-Null
        $manifestResponse = Invoke-WebRequest -UseBasicParsing -Uri $manifestUrl -TimeoutSec 30
        $manifestText = Convert-ServerUpdateContentToText $manifestResponse.Content
    }
    else {
        $manifestText = Get-Content -LiteralPath $ManifestPath -Raw
    }
    $manifest = $manifestText | ConvertFrom-Json
    if (
        $manifest.schemaVersion -ne 1 -or
        [string]::IsNullOrWhiteSpace($manifest.version) -or
        [string]::IsNullOrWhiteSpace($manifest.installerUrl) -or
        $manifest.sha256 -notmatch '^[a-fA-F0-9]{64}$' -or
        [string]::IsNullOrWhiteSpace($manifest.publishedUtc) -or
        [string]::IsNullOrWhiteSpace($manifest.signature)
    ) {
        throw "Das Update-Manifest ist unvollstaendig."
    }

    $canonicalBytes = [Text.Encoding]::UTF8.GetBytes((Get-CanonicalManifestText $manifest))
    $signatureBytes = [Convert]::FromBase64String([string]$manifest.signature)
    $publicKeyXml = Get-Content -LiteralPath $PublicKeyPath -Raw
    $rsa = New-Object Security.Cryptography.RSACryptoServiceProvider
    try {
        $rsa.FromXmlString($publicKeyXml)
        $signatureValid = $rsa.VerifyData(
            $canonicalBytes,
            [Security.Cryptography.CryptoConfig]::MapNameToOID("SHA256"),
            $signatureBytes)
    }
    finally {
        $rsa.Dispose()
    }
    if (-not $signatureValid) {
        throw "Die kryptografische Release-Signatur ist ungueltig."
    }

    $available = [Version]$manifest.version
    if ($available -le $current) {
        Write-UpdateLog "Kein neueres Update verfuegbar. Installiert=$current; Manifest=$available"
        exit 0
    }

    $updatesDirectory = Join-Path $script:DataRoot "updates"
    New-Item -ItemType Directory -Force -Path $updatesDirectory | Out-Null
    $downloadPath = Join-Path $updatesDirectory ("Meine-Budgetwelt-Server-Setup-{0}.exe" -f $available)
    $partialPath = "$downloadPath.part"
    if (-not [string]::IsNullOrWhiteSpace($InstallerPath)) {
        Copy-Item -LiteralPath $InstallerPath -Destination $partialPath -Force
    }
    else {
        Assert-OfficialHttpsUrl ([string]$manifest.installerUrl) "Installeradresse" ($officialRepositoryPath + "download/") | Out-Null
        Invoke-WebRequest -UseBasicParsing -Uri $manifest.installerUrl -OutFile $partialPath -TimeoutSec 300
    }
    $download = Get-Item -LiteralPath $partialPath
    if ($download.Length -le 0 -or $download.Length -gt $maximumInstallerBytes) {
        throw "Das Updatepaket besitzt eine ungueltige Groesse."
    }
    $actualHash = Get-FileSha256 $partialPath
    if ($actualHash -ne $manifest.sha256.ToLowerInvariant()) {
        throw "Die SHA-256-Pruefsumme des Updatepakets stimmt nicht."
    }
    Move-Item -LiteralPath $partialPath -Destination $downloadPath -Force
    Write-UpdateLog "Signiertes Update $available wurde geprueft und gespeichert."

    if ($DownloadOnly) {
        Write-Output $downloadPath
        exit 0
    }

    $setup = Start-Process `
        -FilePath $downloadPath `
        -ArgumentList @("/S", "/SERVER_AUTO_UPDATE") `
        -PassThru `
        -Wait `
        -WindowStyle Hidden
    if ($setup.ExitCode -ne 0) {
        throw "Das Server-Setup ist mit Exitcode $($setup.ExitCode) fehlgeschlagen."
    }
    Write-UpdateLog "Update auf Version $available wurde erfolgreich installiert."
}
catch {
    Write-UpdateLog ("Updatefehler: " + $_.Exception.Message)
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 2
}
finally {
    if ($hasMutex -and $null -ne $mutex) {
        $mutex.ReleaseMutex()
    }
    if ($null -ne $mutex) {
        $mutex.Dispose()
    }
}
