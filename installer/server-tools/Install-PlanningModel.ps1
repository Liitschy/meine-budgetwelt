param(
    [string]$Model = "qwen3.5:4b",
    [string]$OllamaBaseUrl = "http://127.0.0.1:11434",
    [string]$DataRoot = "$env:ProgramData\Meine Budgetwelt Server",
    [string]$ServiceName = "MeineBudgetweltServer",
    [switch]$SkipConfiguration
)

$ErrorActionPreference = "Stop"

$baseUri = [Uri]$OllamaBaseUrl
if ($baseUri.Scheme -ne "http" -or -not $baseUri.IsLoopback) {
    throw "Ollama muss aus Sicherheitsgruenden ueber eine lokale HTTP-Adresse angesprochen werden."
}
if ([string]::IsNullOrWhiteSpace($Model)) {
    throw "Der Modellname darf nicht leer sein."
}

$baseUrl = $OllamaBaseUrl.TrimEnd("/")
$tagsUrl = "$baseUrl/api/tags"
$pullUrl = "$baseUrl/api/pull"

Write-Host "Pruefe lokale Ollama-Laufzeit unter $baseUrl ..."
try {
    $tags = Invoke-RestMethod -Method Get -Uri $tagsUrl -TimeoutSec 15
}
catch {
    throw "Ollama ist unter $baseUrl nicht erreichbar. Bitte zuerst den lokalen Ollama-Dienst starten. $($_.Exception.Message)"
}

$installedNames = @($tags.models | ForEach-Object { [string]$_.name })
if ($installedNames -notcontains $Model) {
    Write-Host "Lade das kostenlose Planungsmodell $Model. Der erste Download kann einige Minuten dauern ..."
    $payload = @{ model = $Model; stream = $false } | ConvertTo-Json -Compress
    Invoke-RestMethod `
        -Method Post `
        -Uri $pullUrl `
        -ContentType "application/json" `
        -Body $payload `
        -TimeoutSec 3600 | Out-Null

    $tags = Invoke-RestMethod -Method Get -Uri $tagsUrl -TimeoutSec 15
    $installedNames = @($tags.models | ForEach-Object { [string]$_.name })
    if ($installedNames -notcontains $Model) {
        throw "Ollama meldet das Modell $Model nach dem Download nicht als installiert."
    }
} else {
    Write-Host "Das Planungsmodell $Model ist bereits installiert."
}

if (-not $SkipConfiguration) {
    $configurationTool = Join-Path $PSScriptRoot "Configure-Integrations.ps1"
    if (-not (Test-Path -LiteralPath $configurationTool -PathType Leaf)) {
        throw "Das Konfigurationswerkzeug wurde nicht gefunden: $configurationTool"
    }

    & $configurationTool `
        -Integration LocalAi `
        -DataRoot $DataRoot `
        -ServiceName $ServiceName
}

Write-Host "Das Planungsmodell $Model ist installiert und fuer Meine Budgetwelt aktiviert."
Write-Host "Blenk Voice kann sein bisheriges Modell unveraendert weiterverwenden."