param(
    [Parameter(Mandatory = $true)]
    [string]$UpdaterScript,
    [string]$TaskName = "MeineBudgetweltServerUpdater",
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

if ($TaskName -notmatch '^MeineBudgetweltServerUpdater[A-Za-z0-9]*$') {
    throw "Unsicherer Aufgabenname."
}

if ($Uninstall) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    exit 0
}

if (-not (Test-Path -LiteralPath $UpdaterScript -PathType Leaf)) {
    throw "Das Server-Updateskript fehlt."
}

$resolvedScript = (Resolve-Path -LiteralPath $UpdaterScript).Path
$powerShellPath = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
$arguments = '-NoProfile -NonInteractive -ExecutionPolicy RemoteSigned -File "{0}"' -f $resolvedScript
$action = New-ScheduledTaskAction -Execute $powerShellPath -Argument $arguments
$startupTrigger = New-ScheduledTaskTrigger -AtStartup
$startupTrigger.Delay = "PT5M"
$dailyTrigger = New-ScheduledTaskTrigger -Daily -At "03:15"
$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 15)

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger @($startupTrigger, $dailyTrigger) `
    -Settings $settings `
    -User "SYSTEM" `
    -RunLevel Highest `
    -Description "Prueft signierte Updates fuer Meine Budgetwelt Server." `
    -Force | Out-Null
