param(
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$checkProject = Join-Path $repositoryRoot "server\MeineBudgetwelt.PlanningChecks\MeineBudgetwelt.PlanningChecks.csproj"

dotnet run --project $checkProject --configuration $Configuration
if ($LASTEXITCODE -ne 0) {
    throw "Die Prüfungen der KI-Wochenplanung sind fehlgeschlagen."
}
