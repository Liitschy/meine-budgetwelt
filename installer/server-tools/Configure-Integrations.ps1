param(
    [ValidateSet("LocalAi", "GoCardless", "Both")]
    [string]$Integration = "Both",
    [ValidateSet("Sandbox", "Production")]
    [string]$GoCardlessMode = "Production",
    [string]$DataRoot = "$env:ProgramData\Meine Budgetwelt Server",
    [string]$ServiceName = "MeineBudgetweltServer"
)

$ErrorActionPreference = "Stop"

function Assert-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Bitte diese PowerShell als Administrator starten."
    }
}

function Read-SecretValue {
    param([string]$Prompt)

    $secureValue = Read-Host -Prompt $Prompt -AsSecureString
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureValue)
    try {
        $plainValue = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
        if ([string]::IsNullOrWhiteSpace($plainValue)) {
            throw "Der geheime Wert darf nicht leer sein."
        }
        return $plainValue
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
}

function Set-ServiceEnvironmentEntry {
    param(
        [string[]]$Entries,
        [string]$Name,
        [string]$Value
    )

    $result = @($Entries | Where-Object {
        $_ -notlike "$Name=*"
    })
    $result += "$Name=$Value"
    return [string[]]$result
}

function Ensure-ConfigurationSection {
    param(
        [object]$Configuration,
        [string]$Name,
        [hashtable]$Defaults
    )

    if ($null -eq $Configuration.PSObject.Properties[$Name]) {
        $Configuration | Add-Member -MemberType NoteProperty -Name $Name -Value ([pscustomobject]$Defaults)
    }
    foreach ($key in $Defaults.Keys) {
        if ($null -eq $Configuration.$Name.PSObject.Properties[$key]) {
            $Configuration.$Name | Add-Member -MemberType NoteProperty -Name $key -Value $Defaults[$key]
        }
    }
}

Assert-Administrator

$configurationPath = Join-Path $DataRoot "appsettings.json"
if (-not (Test-Path -LiteralPath $configurationPath -PathType Leaf)) {
    throw "Die Serverkonfiguration wurde nicht gefunden: $configurationPath"
}
if ($null -eq (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue)) {
    throw "Der Budgetwelt-Serverdienst wurde nicht gefunden: $ServiceName"
}

$configuration = Get-Content -LiteralPath $configurationPath -Raw | ConvertFrom-Json
$serviceRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"
$serviceProperties = Get-ItemProperty -LiteralPath $serviceRegistryPath
$environmentEntries = @()
if ($null -ne $serviceProperties.PSObject.Properties["Environment"]) {
    $environmentEntries = @($serviceProperties.Environment)
}
$environmentEntries = @($environmentEntries | Where-Object {
    $_ -notlike "BUDGETWELT_OPENAI_API_KEY=*"
})

if ($Integration -in @("LocalAi", "Both")) {
    Ensure-ConfigurationSection `
        -Configuration $configuration `
        -Name "LocalAi" `
        -Defaults @{
            Enabled = $true
            Endpoint = "http://127.0.0.1:11434/api/chat"
            Model = "qwen3.5:4b"
            ContextTokens = 16384
            TimeoutSeconds = 300
            KeepAlive = "30m"
        }
    $configuration.LocalAi.Enabled = $true
    $configuration.LocalAi.Endpoint = "http://127.0.0.1:11434/api/chat"
    $configuration.LocalAi.Model = "qwen3.5:4b"
}

if ($Integration -in @("GoCardless", "Both")) {
    $secretId = Read-SecretValue "GoCardless Secret ID"
    $secretKey = Read-SecretValue "GoCardless Secret Key"
    try {
        $environmentEntries = Set-ServiceEnvironmentEntry `
            -Entries $environmentEntries `
            -Name "BUDGETWELT_GOCARDLESS_SECRET_ID" `
            -Value $secretId
        $environmentEntries = Set-ServiceEnvironmentEntry `
            -Entries $environmentEntries `
            -Name "BUDGETWELT_GOCARDLESS_SECRET_KEY" `
            -Value $secretKey
    }
    finally {
        $secretId = $null
        $secretKey = $null
    }
    Ensure-ConfigurationSection `
        -Configuration $configuration `
        -Name "GoCardless" `
        -Defaults @{
            Enabled = $false
            BaseUrl = "https://bankaccountdata.gocardless.com/api/v2/"
            RedirectBaseUrl = "https://budget.leno.info"
            DefaultCountry = "DE"
            SandboxMode = $false
            TimeoutSeconds = 45
        }
    $configuration.GoCardless.Enabled = $true
    $configuration.GoCardless.SandboxMode = ($GoCardlessMode -eq "Sandbox")
}

New-ItemProperty `
    -LiteralPath $serviceRegistryPath `
    -Name "Environment" `
    -PropertyType MultiString `
    -Value ([string[]]$environmentEntries) `
    -Force | Out-Null

$temporaryPath = "$configurationPath.new"
$backupPath = "$configurationPath.before-integrations-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$json = $configuration | ConvertTo-Json -Depth 20
[IO.File]::WriteAllText(
    $temporaryPath,
    $json + [Environment]::NewLine,
    [Text.UTF8Encoding]::new($false)
)
[IO.File]::Replace($temporaryPath, $configurationPath, $backupPath)

Restart-Service -Name $ServiceName -Force
$service = Get-Service -Name $ServiceName
$service.WaitForStatus([ServiceProcess.ServiceControllerStatus]::Running, [TimeSpan]::FromSeconds(30))

Write-Host "Integrationen wurden sicher konfiguriert."
if ($Integration -in @("GoCardless", "Both")) {
    Write-Host "GoCardless-Modus: $GoCardlessMode"
}
Write-Host "Die vorherige Konfiguration liegt unter: $backupPath"
Write-Host "Kein geheimer Wert wurde in appsettings.json oder auf der Befehlszeile gespeichert."
