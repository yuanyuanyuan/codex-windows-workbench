[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$Developer,
    [switch]$NativeBuild,
    [switch]$Containers,
    [switch]$AgentClients,
    [switch]$EnableSafetyHooks,
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
if ($env:PWSH_AI_AGENT_STATE_ROOT) {
    $stateRoot = $env:PWSH_AI_AGENT_STATE_ROOT
} else {
    $stateRoot = Join-Path $env:LOCALAPPDATA 'PwshAiAgent\state'
}
$backupRoot = Join-Path $stateRoot 'backups'
$logRoot = Join-Path $stateRoot 'logs'
$installer = Join-Path $PSScriptRoot 'Install-PwshAgentEnv.ps1'
$refreshPath = Join-Path $PSScriptRoot 'Refresh-EnvPath.ps1'
$sentinelVersion = '2026.07.12.1'

. (Join-Path $PSScriptRoot 'Private\PwshAiAgent.State.ps1')
. (Join-Path $PSScriptRoot 'Private\PwshAiAgent.Phases.ps1')

function Write-ProgressLine {
    param([Parameter(Mandatory = $true)][string]$Message)
    if (-not $Json) { Write-Host $Message }
}

function Invoke-LoggedCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock
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
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock
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
    param(
        [Parameter(Mandatory = $true)][string]$ConfigFile,
        [Parameter(Mandatory = $true)][string]$Phase
    )
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget is required before applying a configuration.'
    }
    if (-not (Test-Path -LiteralPath $ConfigFile)) {
        throw "Configuration not found: $ConfigFile"
    }
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
        Invoke-LoggedCommand -Name 'scoop-bootstrap' -ScriptBlock {
            & pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File $download
        }
        if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
            if (Test-Path -LiteralPath $refreshPath) { . $refreshPath | Out-Null }
        }
    } finally {
        Remove-Item -LiteralPath $download -Force -ErrorAction SilentlyContinue
    }
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        throw 'Scoop bootstrap completed but scoop is still unavailable.'
    }
}

function Install-ScoopPackageList {
    param([Parameter(Mandatory = $true)][string[]]$Packages)
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
        'golang.org/x/tools/gopls@latest'
        'github.com/go-delve/delve/cmd/dlv@latest'
        'github.com/air-verse/air@latest'
    )
    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        throw 'Go is missing after the Developer workload.'
    }
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

function Install-AgentProfile {
    $targetDir = Join-Path $env:USERPROFILE '.config\pwsh-ai'
    $managedFiles = @(
        (Join-Path $targetDir 'pwsh-ai-agent-overlay.ps1')
        (Join-Path $targetDir 'pwsh-ai-core.ps1')
    )
    $manifest = [ordered]@{
        Version     = $sentinelVersion
        CreatedAt   = (Get-Date).ToUniversalTime().ToString('o')
        Files       = @($managedFiles | ForEach-Object { Backup-ManagedFile $_ })
        Environment = @(
            'HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'NO_PROXY',
            'GOPATH', 'GOPROXY', 'GOSUMDB', 'PYTHONIOENCODING', 'PYTHONUTF8' |
                ForEach-Object { Get-RegistryValueState $_ }
        )
    }
    if (-not (Test-Path -LiteralPath $installer)) {
        throw "Profile installer not found: $installer"
    }
    Invoke-LoggedCommand -Name 'agent-profile' -ScriptBlock {
        & pwsh -NoLogo -NoProfile -File $installer -ApplyUserEnvironment
    }
    foreach ($dir in @(
            (Join-Path $targetDir 'hooks')
            (Join-Path $targetDir 'mcp')
            (Join-Path $targetDir 'skills')
            (Join-Path $targetDir 'commands')
            (Join-Path $targetDir 'rules')
            (Join-Path $targetDir 'agents')
        )) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    foreach ($entry in $manifest.Files) {
        if (Test-Path -LiteralPath $entry.Path) {
            $entry.PostHash = (Get-FileHash -LiteralPath $entry.Path -Algorithm SHA256).Hash
        }
    }
    Write-ManagedManifest -Manifest $manifest
}

function Restore-AgentProfile {
    $manifest = Read-ManagedManifest
    if (-not $manifest) {
        throw "No managed agent manifest found at $(Join-Path $stateRoot 'manifest.json')"
    }
    foreach ($entry in $manifest.Files) {
        if ($entry.Existed) {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $entry.Path) | Out-Null
            Copy-Item -LiteralPath $entry.Backup -Destination $entry.Path -Force
        } elseif (Test-Path -LiteralPath $entry.Path) {
            $current = (Get-FileHash -LiteralPath $entry.Path -Algorithm SHA256).Hash
            if ($current -eq $entry.PostHash) {
                Remove-Item -LiteralPath $entry.Path -Force
            }
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
    foreach ($phase in $phaseDefinitions) {
        Remove-Item -LiteralPath (Get-SentinelPath $phase.Name) -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath (Join-Path $stateRoot 'manifest.json') -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $refreshPath) { . $refreshPath | Out-Null }
}


function Install-SafetyHooks {
    $source = Join-Path $configRoot 'agent-content\hooks\dangerous-git.ps1'
    $targetDir = Join-Path $env:USERPROFILE '.config\pwsh-ai\hooks'
    $target = Join-Path $targetDir 'dangerous-git.ps1'
    if (-not (Test-Path -LiteralPath $source)) {
        throw "Safety hook source missing: $source"
    }
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    if (Test-Path -LiteralPath $target) {
        Backup-ManagedFile $target | Out-Null
    }
    Copy-Item -LiteralPath $source -Destination $target -Force
    Write-ProgressLine "Installed safety hook: $target"
}

function Install-AgentClientsPhase {
    $script = Join-Path $PSScriptRoot 'Install-AgentClients.ps1'
    if (-not (Test-Path -LiteralPath $script)) {
        throw "Agent client installer missing: $script"
    }
    Invoke-LoggedCommand -Name 'agent-clients' -ScriptBlock {
        & pwsh -NoLogo -NoProfile -File $script -Json | Out-Null
    } | Out-Null
}
function Invoke-Phase {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )
    $existing = Get-PhaseStatus $Name
    if ($existing.Status -eq 'Complete' -and -not $Force) {
        Write-ProgressLine "[$Name] already complete; use -Force to rerun."
        return [pscustomobject]@{
            Name   = $Name
            Status = 'Skipped'
            Detail = 'Valid sentinel exists.'
        }
    }
    Write-ProgressLine "[$Name] starting"
    if ($PSCmdlet.ShouldProcess($Name, 'Initialize phase')) {
        & $Action
        Complete-Phase $Name
        return [pscustomobject]@{
            Name   = $Name
            Status = 'Complete'
            Detail = 'Phase completed.'
        }
    }
    return [pscustomobject]@{
        Name   = $Name
        Status = 'WhatIf'
        Detail = 'No change requested.'
    }
}

function Invoke-Apply {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget is required for the Windows baseline.'
    }
    if (Test-Path -LiteralPath $refreshPath) { . $refreshPath | Out-Null }
    $results = [System.Collections.Generic.List[object]]::new()
    foreach ($phase in (Get-SelectedPhases)) {
        $result = switch ($phase.Name) {
            'Core' {
                Invoke-Phase 'Core' {
                    Invoke-WingetConfigure (Join-Path $configRoot $phase.Config) 'Core'
                    Install-Scoop
                    Install-ScoopPackageList @(
                        'ripgrep', 'fd', 'fzf', 'jq', 'bat', 'delta', 'yq', '7zip', 'zip', 'nuget'
                    )
                }
            }
            'Agent' {
                Invoke-Phase 'Agent' { Install-AgentProfile }
            }
            'AgentClients' {
                Invoke-Phase 'AgentClients' { Install-AgentClientsPhase }
            }
            'Developer' {
                Invoke-Phase 'Developer' {
                    Invoke-WingetConfigure (Join-Path $configRoot $phase.Config) 'Developer'
                    Install-ScoopPackageList @('golangci-lint', 'air')
                    Install-GoTools
                    Install-PowerShellDeveloperModules
                }
            }
            'NativeBuild' {
                Invoke-Phase 'NativeBuild' {
                    Invoke-LoggedCommand -Name 'visualstudio-buildtools' -ScriptBlock {
                        & winget install --id Microsoft.VisualStudio.2022.BuildTools --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity --override '--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended'
                        if ($LASTEXITCODE -ne 0) { throw "Build Tools exited with $LASTEXITCODE" }
                    } | Out-Null
                    Invoke-LoggedCommand -Name 'visualstudio-locator' -ScriptBlock {
                        & winget install --id Microsoft.VisualStudio.Locator --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
                        if ($LASTEXITCODE -ne 0) { throw "vswhere package exited with $LASTEXITCODE" }
                    } | Out-Null
                }
            }
            'Containers' {
                Invoke-Phase 'Containers' {
                    Invoke-LoggedCommand -Name 'docker-desktop' -ScriptBlock {
                        & winget install --id Docker.DockerDesktop --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
                        if ($LASTEXITCODE -ne 0) { throw "Docker Desktop exited with $LASTEXITCODE" }
                    } | Out-Null
                }
            }
        }
        $results.Add($result)
    }
    return @($results)
}


function Get-SelectedConfigPaths {
    $paths = [System.Collections.Generic.List[string]]::new()
    foreach ($phase in (Get-SelectedPhases)) {
        if ($phase.Config) {
            $paths.Add((Join-Path $configRoot $phase.Config)) | Out-Null
        }
    }
    return @($paths)
}

function Invoke-WorkbenchPreflight {
    param(
        [switch]$SkipWingetTest,
        [switch]$SkipWingetDocuments
    )
    $preflightScript = Join-Path $PSScriptRoot 'Preflight-PwshAgentWindows.ps1'
    if (-not (Test-Path -LiteralPath $preflightScript)) {
        throw "Preflight script not found: $preflightScript"
    }
    $args = @('-NoLogo', '-NoProfile', '-File', $preflightScript, '-Json')
    $configs = @(Get-SelectedConfigPaths)
    foreach ($cfg in $configs) {
        $args += @('-Configs', $cfg)
    }
    if ($SkipWingetTest) { $args += '-SkipWingetTest' }
    $envBackup = $env:PWSH_AI_AGENT_SKIP_WINGET_PREFLIGHT
    try {
        if ($SkipWingetDocuments -or $env:PWSH_AI_AGENT_SKIP_WINGET_PREFLIGHT -eq '1') {
            $env:PWSH_AI_AGENT_SKIP_WINGET_PREFLIGHT = '1'
        }
        $raw = & pwsh @args 2>&1
        $code = $LASTEXITCODE
    } finally {
        if ($null -eq $envBackup) {
            Remove-Item Env:PWSH_AI_AGENT_SKIP_WINGET_PREFLIGHT -ErrorAction SilentlyContinue
        } else {
            $env:PWSH_AI_AGENT_SKIP_WINGET_PREFLIGHT = $envBackup
        }
    }
    $text = ($raw | ForEach-Object { "$_" }) -join "`n"
    $start = $text.IndexOf('{')
    $end = $text.LastIndexOf('}')
    if ($start -lt 0 -or $end -le $start) {
        throw "Preflight did not return JSON. Exit=$code Text=$text"
    }
    $report = $text.Substring($start, $end - $start + 1) | ConvertFrom-Json
    return [pscustomobject]@{
        ExitCode = $code
        Report   = $report
    }
}

$plan = @(Get-Plan)
$mode = if ($Status) { 'Status' } elseif ($Verify) { 'Verify' } elseif ($Rollback) { 'Rollback' } elseif ($WhatIfPreference) { 'WhatIf' } else { 'Apply' }

if ($Status) {
    $preflight = Invoke-WorkbenchPreflight -SkipWingetTest -SkipWingetDocuments
    $report = [ordered]@{
        Mode      = 'Status'
        Changed   = $false
        StateRoot = $stateRoot
        Phases    = @($phaseDefinitions | ForEach-Object { Get-PhaseStatus $_.Name })
        Actions   = $plan
        Preflight = $preflight.Report
    }
    if ($Json) { $report | ConvertTo-Json -Depth 12 } else { $report | Format-List }
    return
}

if ($WhatIfPreference) {
    $report = [ordered]@{
        Mode      = 'WhatIf'
        Changed   = $false
        StateRoot = $stateRoot
        Phases    = @($phaseDefinitions | ForEach-Object { [pscustomobject]@{ Name = $_.Name; Status = 'Planned' } })
        Actions   = $plan
    }
    if ($Json) { $report | ConvertTo-Json -Depth 12 } else { $report | Format-List }
    return
}

if ($Rollback) {
    if ($PSCmdlet.ShouldProcess($stateRoot, 'Restore managed agent files and environment values')) {
        Restore-AgentProfile
    }
    $report = [ordered]@{
        Mode      = 'Rollback'
        Changed   = $true
        StateRoot = $stateRoot
        Status    = 'Complete'
    }
    if ($Json) { $report | ConvertTo-Json -Depth 12 } else { $report | Format-List }
    return
}

if ($Verify) {
    $preflight = Invoke-WorkbenchPreflight
    $testScript = Join-Path $PSScriptRoot 'Test-PwshAgentEnv.ps1'
    if (-not (Test-Path -LiteralPath $testScript)) {
        throw "Verification script not found: $testScript"
    }
    $verifyRaw = & pwsh -NoLogo -NoProfile -File $testScript -Deep -Json 2>&1
    $verifyText = ($verifyRaw | ForEach-Object { "$_" }) -join "`n"
    $vs = $verifyText.IndexOf('{')
    $ve = $verifyText.LastIndexOf('}')
    if ($vs -lt 0 -or $ve -le $vs) {
        throw "Verification did not return JSON. Text=$verifyText"
    }
    $verification = $verifyText.Substring($vs, $ve - $vs + 1) | ConvertFrom-Json
    $report = [ordered]@{
        Mode         = 'Verify'
        Changed      = $false
        StateRoot    = $stateRoot
        Verification = $verification
        Preflight    = $preflight.Report
    }
    if ($Json) { $report | ConvertTo-Json -Depth 12 } else { $verification | Format-List }
    $runtimeFailures = 0
    if ($verification.Summary.PSObject.Properties.Name -contains 'RuntimeFailures') {
        $runtimeFailures = [int]$verification.Summary.RuntimeFailures
    }
    if ($preflight.ExitCode -ne 0) { exit 1 }
    if ([int]$verification.Summary.RequiredMissing -gt 0 -or $runtimeFailures -gt 0) { exit 1 }
    return
}

$preflight = Invoke-WorkbenchPreflight
if ($preflight.ExitCode -ne 0) {
    $report = [ordered]@{
        Mode      = 'PreflightFailed'
        Changed   = $false
        StateRoot = $stateRoot
        Actions   = $plan
        Preflight = $preflight.Report
    }
    if ($Json) { $report | ConvertTo-Json -Depth 12 } else { $preflight.Report | Format-List }
    exit 1
}

$results = Invoke-Apply

# Auto-run smoke verification after successful apply (explicit -Verify remains available).
$testScript = Join-Path $PSScriptRoot 'Test-PwshAgentEnv.ps1'
$postVerify = $null
$postVerifyFailed = $false
if (Test-Path -LiteralPath $testScript) {
    Write-ProgressLine 'Running post-apply smoke verification...'
    if (Test-Path -LiteralPath $refreshPath) { . $refreshPath | Out-Null }
    $rawVerify = & pwsh -NoLogo -NoProfile -File $testScript -Deep -Json 2>&1
    $verifyText = ($rawVerify | ForEach-Object { "$_" }) -join "`n"
    $vs = $verifyText.IndexOf('{'); $ve = $verifyText.LastIndexOf('}')
    if ($vs -ge 0 -and $ve -gt $vs) {
        $postVerify = $verifyText.Substring($vs, $ve - $vs + 1) | ConvertFrom-Json
        if ($postVerify.Summary.RequiredMissing -gt 0 -or $postVerify.Summary.RuntimeFailures -gt 0) {
            $postVerifyFailed = $true
        }
    } else {
        $postVerifyFailed = $true
        $postVerify = [pscustomobject]@{ Error = 'Post-apply verification did not return JSON.'; Raw = $verifyText }
    }
}

$report = [ordered]@{
    Mode                   = $mode
    Changed                = $true
    StateRoot              = $stateRoot
    Phases                 = $results
    Actions                = $plan
    Preflight              = $preflight.Report
    PostApplyVerification  = $postVerify
}
if ($Json) { $report | ConvertTo-Json -Depth 12 } else {
    $results | Format-Table -AutoSize
    if ($postVerify) { 'Post-apply verification'; $postVerify.Summary | Format-List }
}
if ($postVerifyFailed) { exit 1 }
