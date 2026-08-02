param(
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$checkProject = Join-Path $repositoryRoot "server\MeineBudgetwelt.BankingChecks\MeineBudgetwelt.BankingChecks.csproj"

dotnet run --project $checkProject --configuration $Configuration
if ($LASTEXITCODE -ne 0) {
    throw "Die Prüfungen des read-only-Bankabrufs sind fehlgeschlagen."
}
