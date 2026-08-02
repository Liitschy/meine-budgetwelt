param(
    [ValidateSet("LocalAi", "EnableBanking", "Both")]
    [string]$Integration = "Both",
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

function Read-RequiredText {
    param([string]$Prompt)

    $value = (Read-Host -Prompt $Prompt).Trim()
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "$Prompt darf nicht leer sein."
    }
    return $value
}

function Protect-SecretPath {
    param(
        [string]$Path,
        [switch]$Directory
    )

    $systemSid = [Security.Principal.SecurityIdentifier]::new(
        [Security.Principal.WellKnownSidType]::LocalSystemSid,
        $null
    )
    $administratorsSid = [Security.Principal.SecurityIdentifier]::new(
        [Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid,
        $null
    )
    $localServiceSid = [Security.Principal.SecurityIdentifier]::new(
        [Security.Principal.WellKnownSidType]::LocalServiceSid,
        $null
    )
    $acl = if ($Directory) {
        [Security.AccessControl.DirectorySecurity]::new()
    } else {
        [Security.AccessControl.FileSecurity]::new()
    }
    $inheritance = [Security.AccessControl.InheritanceFlags]::None
    $propagation = [Security.AccessControl.PropagationFlags]::None
    if ($Directory) {
        $inheritance = (
            [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
            [Security.AccessControl.InheritanceFlags]::ObjectInherit
        )
    }
    $acl.SetAccessRuleProtection($true, $false)
    $accessRules = @(
        @{ Sid = $systemSid; Rights = [Security.AccessControl.FileSystemRights]::FullControl },
        @{ Sid = $administratorsSid; Rights = [Security.AccessControl.FileSystemRights]::FullControl },
        @{ Sid = $localServiceSid; Rights = [Security.AccessControl.FileSystemRights]::ReadAndExecute }
    )
    foreach ($accessRule in $accessRules) {
        $rule = [Security.AccessControl.FileSystemAccessRule]::new(
            $accessRule.Sid,
            $accessRule.Rights,
            $inheritance,
            $propagation,
            [Security.AccessControl.AccessControlType]::Allow
        )
        $acl.AddAccessRule($rule) | Out-Null
    }
    Set-Acl -LiteralPath $Path -AclObject $acl
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
    -not [string]::IsNullOrWhiteSpace($_)
    -and $_ -notlike "BUDGETWELT_OPENAI_API_KEY=*"
    -and $_ -notlike "BUDGETWELT_GOCARDLESS_SECRET_ID=*"
    -and $_ -notlike "BUDGETWELT_GOCARDLESS_SECRET_KEY=*"
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

if ($Integration -in @("EnableBanking", "Both")) {
    $applicationId = Read-RequiredText "Enable Banking App-ID"
    $parsedApplicationId = [Guid]::Empty
    if (-not [Guid]::TryParse($applicationId, [ref]$parsedApplicationId)) {
        throw "Die Enable-Banking-App-ID muss eine gültige UUID sein."
    }

    $sourceKeyPath = Read-RequiredText "Vollständiger Pfad zur heruntergeladenen PEM-Datei"
    if (-not (Test-Path -LiteralPath $sourceKeyPath -PathType Leaf)) {
        throw "Die PEM-Datei wurde nicht gefunden: $sourceKeyPath"
    }
    $sourceKeyPath = (Resolve-Path -LiteralPath $sourceKeyPath).Path
    $privateKey = [IO.File]::ReadAllText($sourceKeyPath)
    if (
        $privateKey -notmatch "-----BEGIN (RSA )?PRIVATE KEY-----" -or
        $privateKey -notmatch "-----END (RSA )?PRIVATE KEY-----"
    ) {
        throw "Die ausgewählte Datei enthält keinen unterstützten privaten PEM-Schlüssel."
    }

    $secretDirectory = Join-Path $DataRoot "secrets"
    New-Item -ItemType Directory -Path $secretDirectory -Force | Out-Null
    Protect-SecretPath -Path $secretDirectory -Directory
    $destinationKeyPath = Join-Path $secretDirectory "enable-banking-private.pem"
    if (-not [string]::Equals(
        $sourceKeyPath,
        $destinationKeyPath,
        [StringComparison]::OrdinalIgnoreCase)) {
        [IO.File]::Copy($sourceKeyPath, $destinationKeyPath, $true)
    }
    Protect-SecretPath -Path $destinationKeyPath
    $privateKey = $null

    Ensure-ConfigurationSection `
        -Configuration $configuration `
        -Name "EnableBanking" `
        -Defaults @{
            Enabled = $false
            BaseUrl = "https://api.enablebanking.com/"
            RedirectBaseUrl = "https://budget.leno.info"
            DefaultCountry = "DE"
            ApplicationId = ""
            PrivateKeyPath = $destinationKeyPath
            TimeoutSeconds = 45
        }
    $configuration.EnableBanking.Enabled = $true
    $configuration.EnableBanking.BaseUrl = "https://api.enablebanking.com/"
    $configuration.EnableBanking.RedirectBaseUrl = "https://budget.leno.info"
    $configuration.EnableBanking.ApplicationId = $parsedApplicationId.ToString()
    $configuration.EnableBanking.PrivateKeyPath = $destinationKeyPath

    if ($null -ne $configuration.PSObject.Properties["GoCardless"]) {
        $configuration.GoCardless.Enabled = $false
    }
}

if ($environmentEntries.Count -eq 0) {
    Remove-ItemProperty `
        -LiteralPath $serviceRegistryPath `
        -Name "Environment" `
        -ErrorAction SilentlyContinue
} else {
    New-ItemProperty `
        -LiteralPath $serviceRegistryPath `
        -Name "Environment" `
        -PropertyType MultiString `
        -Value ([string[]]$environmentEntries) `
        -Force | Out-Null
}

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
if ($Integration -in @("EnableBanking", "Both")) {
    Write-Host "Enable Banking ist eingerichtet. Sandbox oder Produktion wird durch die registrierte App-ID bestimmt."
}
Write-Host "Die vorherige Konfiguration liegt unter: $backupPath"
Write-Host "Der private Schlüssel liegt ausschließlich in der geschützten Serverablage."
