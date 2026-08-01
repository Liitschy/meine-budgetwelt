param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,
    [Parameter(Mandatory = $true)]
    [string]$InstallerPath,
    [Parameter(Mandatory = $true)]
    [string]$InstallerUrl,
    [Parameter(Mandatory = $true)]
    [string]$PrivateKeyPath,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    [string]$PublishedUtc = [DateTimeOffset]::UtcNow.ToString("O")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $InstallerPath -PathType Leaf)) {
    throw "Installerdatei wurde nicht gefunden."
}
if (-not (Test-Path -LiteralPath $PrivateKeyPath -PathType Leaf)) {
    throw "Privater Signierschluessel wurde nicht gefunden."
}

$hash = (Get-FileHash -LiteralPath $InstallerPath -Algorithm SHA256).Hash.ToLowerInvariant()
$canonical = "schemaVersion=1`nversion={0}`ninstallerUrl={1}`nsha256={2}`npublishedUtc={3}" -f `
    $Version,
    $InstallerUrl,
    $hash,
    $PublishedUtc
$privateKeyXml = Get-Content -LiteralPath $PrivateKeyPath -Raw
$rsa = New-Object Security.Cryptography.RSACryptoServiceProvider
try {
    $rsa.FromXmlString($privateKeyXml)
    $signature = $rsa.SignData(
        [Text.Encoding]::UTF8.GetBytes($canonical),
        [Security.Cryptography.CryptoConfig]::MapNameToOID("SHA256"))
}
finally {
    $rsa.Dispose()
}

$manifest = [ordered]@{
    schemaVersion = 1
    version = $Version
    installerUrl = $InstallerUrl
    sha256 = $hash
    publishedUtc = $PublishedUtc
    signature = [Convert]::ToBase64String($signature)
}
$json = $manifest | ConvertTo-Json
[IO.File]::WriteAllText(
    [IO.Path]::GetFullPath($OutputPath),
    $json + [Environment]::NewLine,
    [Text.UTF8Encoding]::new($false))

Write-Host "Signiertes Server-Update-Manifest erstellt: $OutputPath"
