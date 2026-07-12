[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [switch]$Developer,
    [switch]$NativeBuild,
    [switch]$Containers,
    [switch]$Full,
    [switch]$Status,
    [switch]$Verify,
    [switch]$Rollback,
    [switch]$Force,
    [switch]$Json,
    [int]$RetryCount = 3
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'PowerShell 7 or newer is required. Windows PowerShell 5.1 is not supported.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$configRoot = Join-Path $repoRoot 'config'
$stateRoot = Join-Path $env:LOCALAPPDATA 'PwshAiAgent\state'
$backupRoot = Join-Path $stateRoot 'backups'
$logRoot = Join-Path $stateRoot 'logs'
$installer = Join-Path $PSScriptRoot 'Install-PwshAgentEnv.ps1'
$refreshPath = Join-Path $PSScriptRoot 'Refresh-EnvPath.ps1'
$sentinelVersion = '2026.07.12.1'

$phaseDefinitions = @(
    [pscustomobject]@{ Name = 'Core'; Config = 'windows-agent-core.winget'; Description = 'PowerShell 7, source control, Node, Python, Docker CLI, and kubectl.' },
    [pscustomobject]@{ Name = 'Agent'; Config = $null; Description = 'PowerShell profile overlay, agent paths, and managed hook directories.' },
    [pscustomobject]@{ Name = 'Developer'; Config = 'windows-agent-developer.winget'; Description = 'Go, .NET, native build helpers, and DevOps CLI tools.' },
    [pscustomobject]@{ Name = 'NativeBuild'; Config = 'windows-agent-native-build.winget'; Description = 'Visual Studio Build Tools, MSVC, Windows SDK, MSBuild, and vswhere.' },
    [pscustomobject]@{ Name = 'Containers'; Config = $null; Description = 'Docker Desktop installation; no backend or WSL configuration.' }
)

function ConvertTo-PlainObject {
    param([Parameter(Mandatory=$true)]$InputObject)
    if ($InputObject -is [System.Collections.IDictionary]) {
        $result = [ordered]@{}
        foreach ($key in $InputObject.Keys) { $result[$key] = ConvertTo-PlainObject $InputObject[$key] }
        return [pscustomobject]$result
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        return @($InputObject | ForEach-Object { ConvertTo-PlainObject $_ })
    }
    return $InputObject
}

function Write-JsonFile {
    param([Parameter(Mandatory=$true)][string]$Path, [Parameter(Mandatory=$true)]$Value)
    $temp = "$Path.tmp-$([guid]::NewGuid().ToString('N'))"
    $json = (ConvertTo-PlainObject $Value | ConvertTo-Json -Depth 12)
    [System.IO.File]::WriteAllText($temp, $json, [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temp -Destination $Path -Force
}

function Read-JsonFile {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Ensure-StateDirectories {
    New-Item -ItemType Directory -Force -Path $stateRoot, $backupRoot, $logRoot | Out-Null
}

function Get-SentinelPath {
    param([Parameter(Mandatory=$true)][string]$Name)
    return Join-Path $stateRoot "phase-$($Name.ToLowerInvariant()).json"
}

function Get-PhaseStatus {
    param([Parameter(Mandatory=$true)][string]$Name)
    $path = Get-SentinelPath $Name
    $sentinel = Read-JsonFile $path
    if ($sentinel -and $sentinel.Version -eq $sentinelVersion -and $sentinel.Status -eq 'Complete') {
        return [pscustomobject]@{ Name = $Name; Status = 'Complete'; UpdatedAt = $sentinel.UpdatedAt; Sentinel = $path }
    }
    return [pscustomobject]@{ Name = $Name; Status = 'Pending'; UpdatedAt = $null; Sentinel = $path }
}

function Add-Action {
    param(
        [Parameter(Mandatory=$true)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Actions,
        [Parameter(Mandatory=$true)][string]$Phase,
        [Parameter(Mandatory=$true)][string]$Action,
        [Parameter(Mandatory=$true)][string]$Target
    )
    $Actions.Add([pscustomobject]@{ Phase = $Phase; Action = $Action; Target = $Target })
}

function Get-SelectedPhases {
    $selected = @('Core', 'Agent')
    if ($Full -or $Developer) { $selected += 'Developer' }
    if ($Full -or $NativeBuild) { $selected += 'NativeBuild' }
    if ($Full -or $Containers) { $selected += 'Containers' }
    return @($phaseDefinitions | Where-Object { $_.Name -in $selected })
}

function Get-Plan {
    $actions = [System.Collections.Generic.List[object]]::new()
    foreach ($phase in (Get-SelectedPhases)) {
        if ($phase.Config) {
            Add-Action $actions $phase.Name 'winget-configure' (Join-Path $configRoot $phase.Config)
        }
        switch ($phase.Name) {
            'Core' {
                Add-Action $actions $phase.Name 'scoop-bootstrap' 'https://get.scoop.sh'
                Add-Action $actions $phase.Name 'scoop-install' 'ripgrep fd fzf jq bat delta yq 7zip zip nuget'
            }
            'Agent' {
                Add-Action $actions $phase.Name 'install-profile-overlay' (Join-Path $env:USERPROFILE '.config\pwsh-ai')
                Add-Action $actions $phase.Name 'initialize-managed-agent-directories' '~\.config\pwsh-ai\hooks; ~\.config\pwsh-ai\mcp'
            }
            'Developer' {
                Add-Action $actions $phase.Name 'scoop-install' 'golangci-lint air'
                Add-Action $actions $phase.Name 'go-install' 'gopls dlv air'
                Add-Action $actions $phase.Name 'powershell-modules' 'Pester PSScriptAnalyzer Microsoft.PowerShell.PSResourceGet'
            }
            'NativeBuild' {
                Add-Action $actions $phase.Name 'winget-install' 'Microsoft.VisualStudio.2022.BuildTools with MSVC workload'
                Add-Action $actions $phase.Name 'winget-install' 'Microsoft.VisualStudio.Locator'
            }
            'Containers' {
                Add-Action $actions $phase.Name 'winget-install' 'Docker.DockerDesktop'
                Add-Action $actions $phase.Name 'runtime-check' 'docker client/server (daemon may require manual start)'
            }
        }
    }
    return @($actions)
}

function Write-ProgressLine {
    param([Parameter(Mandatory=$true)][string]$Message)
    if (-not $Json) { Write-Host $Message }
}

function Invoke-LoggedCommand {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][scriptblock]$ScriptBlock
    )
    Ensure-StateDirectories
    $logPath = Join-Path $logRoot "$Name-$((Get-Date).ToString('yyyyMMdd-HHmmss'))-$([guid]::NewGuid().ToString('N')).log"
    $output = @(& $ScriptBlock 2>&1)
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    $output | Out-File -LiteralPath $logPath -Encoding utf8
    if ($exitCode -ne 0) {
        throw "$Name failed with exit code $exitCode. See $logPath"
    }
    return $output
}

function Invoke-Retry {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][scriptblock]$ScriptBlock
    )
    $delay = 3
    for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
        try {
            Write-ProgressLine "[$Name] attempt $attempt/$RetryCount"
            Invoke-LoggedCommand -Name $Name -ScriptBlock $ScriptBlock | Out-Null
            return
        } catch {
            if ($attempt -eq $RetryCount) { throw }
            Write-ProgressLine "[$Name] retrying in ${delay}s: $($_.Exception.Message)"
            Start-Sleep -Seconds $delay
            $delay = [Math]::Min($delay * 2, 30)
        }
    }
}

function Invoke-WingetConfigure {
    param([Parameter(Mandatory=$true)][string]$ConfigFile, [Parameter(Mandatory=$true)][string]$Phase)
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'winget is required before applying a configuration.' }
    if (-not (Test-Path -LiteralPath $ConfigFile)) { throw "Configuration not found: $ConfigFile" }
    Invoke-Retry -Name "winget-$($Phase.ToLowerInvariant())" -ScriptBlock {
        & winget configure --file $ConfigFile --accept-configuration-agreements --disable-interactivity
        if ($LASTEXITCODE -ne 0) { throw "winget configure exited with $LASTEXITCODE" }
    }
    if (Test-Path -LiteralPath $refreshPath) { . $refreshPath | Out-Null }
}

function Install-Scoop {
    if (Get-Command scoop -ErrorAction SilentlyContinue) { return }
    $download = Join-Path ([System.IO.Path]::GetTempPath()) "install-scoop-$([guid]::NewGuid().ToString('N')).ps1"
    try {
        Invoke-WebRequest -Uri 'https://get.scoop.sh' -OutFile $download -UseBasicParsing
        Invoke-LoggedCommand -Name 'scoop-bootstrap' -ScriptBlock { & pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File $download }
        if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
            if (Test-Path -LiteralPath $refreshPath) { . $refreshPath | Out-Null }
        }
    } finally {
        Remove-Item -LiteralPath $download -Force -ErrorAction SilentlyContinue
    }
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) { throw 'Scoop bootstrap completed but scoop is still unavailable.' }
}

function Install-ScoopPackageList {
    param([Parameter(Mandatory=$true)][string[]]$Packages)
    foreach ($package in $Packages) {
        $command = switch ($package) {
            'ripgrep' { 'rg'; break }
            '7zip' { '7z'; break }
            default { $package }
        }
        if (Get-Command $command -ErrorAction SilentlyContinue) { continue }
        Invoke-LoggedCommand -Name "scoop-$package" -ScriptBlock {
            & scoop install --skip-update $package
            if ($LASTEXITCODE -ne 0) { throw "scoop install $package exited with $LASTEXITCODE" }
        } | Out-Null
    }
    if (Test-Path -LiteralPath $refreshPath) { . $refreshPath | Out-Null }
}

function Install-GoTools {
    $tools = @(
        'golang.org/x/tools/gopls@latest',
        'github.com/go-delve/delve/cmd/dlv@latest',
        'github.com/air-verse/air@latest'
    )
    if (-not (Get-Command go -ErrorAction SilentlyContinue)) { throw 'Go is missing after the Developer workload.' }
    foreach ($tool in $tools) {
        Invoke-LoggedCommand -Name ('go-' + (($tool -split '/|@')[0] -replace '[^A-Za-z0-9]', '-')) -ScriptBlock {
            & go install $tool
            if ($LASTEXITCODE -ne 0) { throw "go install $tool exited with $LASTEXITCODE" }
        } | Out-Null
    }
    if (Test-Path -LiteralPath $refreshPath) { . $refreshPath | Out-Null }
}

function Install-PowerShellDeveloperModules {
    $modules = @('Pester', 'PSScriptAnalyzer', 'Microsoft.PowerShell.PSResourceGet')
    if (Get-Command Install-PSResource -ErrorAction SilentlyContinue) {
        Invoke-LoggedCommand -Name 'powershell-modules' -ScriptBlock {
            Install-PSResource -Name $modules -Scope CurrentUser -TrustRepository -Reinstall
        } | Out-Null
        return
    }
    if (Get-Command Install-Module -ErrorAction SilentlyContinue) {
        Invoke-LoggedCommand -Name 'powershell-modules' -ScriptBlock {
            Install-Module -Name $modules -Scope CurrentUser -Force -AllowClobber
        } | Out-Null
    }
}

function Get-ManagedFileBackupName {
    param([Parameter(Mandatory=$true)][string]$Path)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Path)
    return ([Convert]::ToBase64String($bytes) -replace '[=+/]', '_')
}

function Backup-ManagedFile {
    param([Parameter(Mandatory=$true)][string]$Path)
    Ensure-StateDirectories
    $backup = Join-Path $backupRoot (Get-ManagedFileBackupName $Path)
    $entry = [ordered]@{ Path = $Path; Existed = (Test-Path -LiteralPath $Path); Backup = $backup; PostHash = $null }
    if ($entry.Existed) { Copy-Item -LiteralPath $Path -Destination $backup -Force }
    return [pscustomobject]$entry
}

function Get-RegistryValueState {
    param([Parameter(Mandatory=$true)][string]$Name)
    $path = 'HKCU:\Environment'
    try {
        return [pscustomobject]@{ Name = $Name; Existed = $true; Value = (Get-ItemPropertyValue -Path $path -Name $Name -ErrorAction Stop) }
    } catch {
        return [pscustomobject]@{ Name = $Name; Existed = $false; Value = $null }
    }
}

function Install-AgentProfile {
    $targetDir = Join-Path $env:USERPROFILE '.config\pwsh-ai'
    $managedFiles = @(
        (Join-Path $targetDir 'pwsh-ai-agent-overlay.ps1'),
        (Join-Path $targetDir 'pwsh-ai-core.ps1')
    )
    $manifest = [ordered]@{
        Version = $sentinelVersion
        CreatedAt = (Get-Date).ToUniversalTime().ToString('o')
        Files = @($managedFiles | ForEach-Object { Backup-ManagedFile $_ })
        Environment = @('HTTP_PROXY','HTTPS_PROXY','ALL_PROXY','NO_PROXY','GOPATH','GOPROXY','GOSUMDB','PYTHONIOENCODING','PYTHONUTF8' | ForEach-Object { Get-RegistryValueState $_ })
    }
    if (-not (Test-Path -LiteralPath $installer)) { throw "Profile installer not found: $installer" }
    Invoke-LoggedCommand -Name 'agent-profile' -ScriptBlock { & pwsh -NoLogo -NoProfile -File $installer -ApplyUserEnvironment }
    foreach ($dir in @((Join-Path $targetDir 'hooks'), (Join-Path $targetDir 'mcp'))) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    foreach ($entry in $manifest.Files) {
        if (Test-Path -LiteralPath $entry.Path) { $entry.PostHash = (Get-FileHash -LiteralPath $entry.Path -Algorithm SHA256).Hash }
    }
    Write-JsonFile -Path (Join-Path $stateRoot 'manifest.json') -Value $manifest
}

function Restore-AgentProfile {
    $manifestPath = Join-Path $stateRoot 'manifest.json'
    $manifest = Read-JsonFile $manifestPath
    if (-not $manifest) { throw "No managed agent manifest found at $manifestPath" }
    foreach ($entry in $manifest.Files) {
        if ($entry.Existed) {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $entry.Path) | Out-Null
            Copy-Item -LiteralPath $entry.Backup -Destination $entry.Path -Force
        } elseif (Test-Path -LiteralPath $entry.Path) {
            $current = (Get-FileHash -LiteralPath $entry.Path -Algorithm SHA256).Hash
            if ($current -eq $entry.PostHash) { Remove-Item -LiteralPath $entry.Path -Force }
        }
    }
    foreach ($entry in $manifest.Environment) {
        $path = 'HKCU:\Environment'
        if ($entry.Existed) {
            Set-ItemProperty -Path $path -Name $entry.Name -Value $entry.Value
        } else {
            Remove-ItemProperty -Path $path -Name $entry.Name -ErrorAction SilentlyContinue
        }
    }
    foreach ($phase in $phaseDefinitions) { Remove-Item -LiteralPath (Get-SentinelPath $phase.Name) -Force -ErrorAction SilentlyContinue }
    Remove-Item -LiteralPath $manifestPath -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $refreshPath) { . $refreshPath | Out-Null }
}

function Complete-Phase {
    param([Parameter(Mandatory=$true)][string]$Name)
    Ensure-StateDirectories
    $sentinel = [ordered]@{ Version = $sentinelVersion; Status = 'Complete'; Phase = $Name; UpdatedAt = (Get-Date).ToUniversalTime().ToString('o') }
    Write-JsonFile -Path (Get-SentinelPath $Name) -Value $sentinel
}

function Invoke-Phase {
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param([Parameter(Mandatory=$true)][string]$Name, [Parameter(Mandatory=$true)][scriptblock]$Action)
    $existing = Get-PhaseStatus $Name
    if ($existing.Status -eq 'Complete' -and -not $Force) {
        Write-ProgressLine "[$Name] already complete; use -Force to rerun."
        return [pscustomobject]@{ Name = $Name; Status = 'Skipped'; Detail = 'Valid sentinel exists.' }
    }
    Write-ProgressLine "[$Name] starting"
    if ($PSCmdlet.ShouldProcess($Name, 'Initialize phase')) {
        & $Action
        Complete-Phase $Name
        return [pscustomobject]@{ Name = $Name; Status = 'Complete'; Detail = 'Phase completed.' }
    }
    return [pscustomobject]@{ Name = $Name; Status = 'WhatIf'; Detail = 'No change requested.' }
}

function Invoke-Apply {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'winget is required for the Windows baseline.' }
    if (Test-Path -LiteralPath $refreshPath) { . $refreshPath | Out-Null }
    $results = [System.Collections.Generic.List[object]]::new()
    foreach ($phase in (Get-SelectedPhases)) {
        $result = switch ($phase.Name) {
            'Core' { Invoke-Phase 'Core' { Invoke-WingetConfigure (Join-Path $configRoot $phase.Config) 'Core'; Install-Scoop; Install-ScoopPackageList @('ripgrep','fd','fzf','jq','bat','delta','yq','7zip','zip','nuget') } }
            'Agent' { Invoke-Phase 'Agent' { Install-AgentProfile } }
            'Developer' { Invoke-Phase 'Developer' { Invoke-WingetConfigure (Join-Path $configRoot $phase.Config) 'Developer'; Install-ScoopPackageList @('golangci-lint','air'); Install-GoTools; Install-PowerShellDeveloperModules } }
            'NativeBuild' { Invoke-Phase 'NativeBuild' { Invoke-LoggedCommand -Name 'visualstudio-buildtools' -ScriptBlock { & winget install --id Microsoft.VisualStudio.2022.BuildTools --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity --override '--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended' ; if ($LASTEXITCODE -ne 0) { throw "Build Tools exited with $LASTEXITCODE" } } | Out-Null; Invoke-LoggedCommand -Name 'visualstudio-locator' -ScriptBlock { & winget install --id Microsoft.VisualStudio.Locator --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity; if ($LASTEXITCODE -ne 0) { throw "vswhere package exited with $LASTEXITCODE" } } | Out-Null } }
            'Containers' { Invoke-Phase 'Containers' { Invoke-LoggedCommand -Name 'docker-desktop' -ScriptBlock { & winget install --id Docker.DockerDesktop --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity; if ($LASTEXITCODE -ne 0) { throw "Docker Desktop exited with $LASTEXITCODE" } } | Out-Null } }
        }
        $results.Add($result)
    }
    return @($results)
}

$plan = @(Get-Plan)
$mode = if ($Status) { 'Status' } elseif ($Verify) { 'Verify' } elseif ($Rollback) { 'Rollback' } elseif ($WhatIfPreference) { 'WhatIf' } else { 'Apply' }

if ($Status) {
    $report = [ordered]@{ Mode = 'Status'; Changed = $false; StateRoot = $stateRoot; Phases = @($phaseDefinitions | ForEach-Object { Get-PhaseStatus $_.Name }); Actions = $plan }
    if ($Json) { $report | ConvertTo-Json -Depth 12 } else { $report | Format-List }
    return
}

if ($WhatIfPreference) {
    $report = [ordered]@{ Mode = 'WhatIf'; Changed = $false; StateRoot = $stateRoot; Phases = @($phaseDefinitions | ForEach-Object { [pscustomobject]@{ Name = $_.Name; Status = 'Planned' } }); Actions = $plan }
    if ($Json) { $report | ConvertTo-Json -Depth 12 } else { $report | Format-List }
    return
}

if ($Rollback) {
    if ($PSCmdlet.ShouldProcess($stateRoot, 'Restore managed agent files and environment values')) { Restore-AgentProfile }
    $report = [ordered]@{ Mode = 'Rollback'; Changed = $true; StateRoot = $stateRoot; Status = 'Complete' }
    if ($Json) { $report | ConvertTo-Json -Depth 12 } else { $report | Format-List }
    return
}

if ($Verify) {
    $testScript = Join-Path $PSScriptRoot 'Test-PwshAgentEnv.ps1'
    $verification = if (Test-Path -LiteralPath $testScript) { & pwsh -NoLogo -NoProfile -File $testScript -Deep -Json | ConvertFrom-Json } else { throw "Verification script not found: $testScript" }
    $report = [ordered]@{ Mode = 'Verify'; Changed = $false; StateRoot = $stateRoot; Verification = $verification }
    if ($Json) { $report | ConvertTo-Json -Depth 12 } else { $verification | Format-List }
    if ($verification.Summary.RequiredMissing -gt 0 -or $verification.Summary.RuntimeFailures -gt 0) { exit 1 }
    return
}

$results = Invoke-Apply
$report = [ordered]@{ Mode = $mode; Changed = $true; StateRoot = $stateRoot; Phases = $results; Actions = $plan }
if ($Json) { $report | ConvertTo-Json -Depth 12 } else { $results | Format-Table -AutoSize }
