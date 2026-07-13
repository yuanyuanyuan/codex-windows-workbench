# Phase definitions and action-plan generation for the workbench.
# Dot-sourced by Initialize-PwshAgentWindows.ps1 only.

$script:PwshAiAgentPhaseDefinitions = @(
    [pscustomobject]@{
        Name        = 'Core'
        Config      = 'windows-agent-core.winget'
        Description = 'PowerShell 7, version control, Node, Python, Docker CLI, and kubectl.'
    }
    [pscustomobject]@{
        Name        = 'Agent'
        Config      = $null
        Description = 'PowerShell profile overlay, agent paths, and managed hook directories.'
    }
    [pscustomobject]@{
        Name        = 'AgentClients'
        Config      = $null
        Description = 'Verify public agent CLI presence. Public MVP checks Codex only; does not install or login.'
    }
    [pscustomobject]@{
        Name        = 'Developer'
        Config      = 'windows-agent-developer.winget'
        Description = 'Go, .NET, native build helpers, and DevOps CLI tools.'
    }
    [pscustomobject]@{
        Name        = 'NativeBuild'
        Config      = 'windows-agent-native-build.winget'
        Description = 'Visual Studio Build Tools, MSVC, Windows SDK, MSBuild, and vswhere.'
    }
    [pscustomobject]@{
        Name        = 'Containers'
        Config      = $null
        Description = 'Docker Desktop installation; no backend or WSL configuration.'
    }
)

# Compatibility alias used by the public entry point.
$phaseDefinitions = $script:PwshAiAgentPhaseDefinitions

function Add-Action {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Actions,
        [Parameter(Mandatory = $true)][string]$Phase,
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][string]$Target,
        [string]$Description = '',
        [string]$Category = 'change',
        [string[]]$Items = @()
    )
    $Actions.Add([pscustomobject]@{
            Phase       = $Phase
            Action      = $Action
            Target      = $Target
            Description = $Description
            Category    = $Category
            Items       = @($Items)
        })
}

function Get-WingetConfigPackages {
    param([Parameter(Mandatory = $true)][string]$ConfigFile)

    if (-not (Test-Path -LiteralPath $ConfigFile)) {
        return @()
    }

    $packages = [System.Collections.Generic.List[object]]::new()
    $name = $null
    $id = $null
    $description = $null

    foreach ($line in Get-Content -LiteralPath $ConfigFile) {
        if ($line -match '^\s*name:\s*(.+)\s*$') {
            if ($id) {
                $packages.Add([pscustomobject]@{
                        Manager     = 'winget'
                        Name        = $(if ($name) { $name } else { $id })
                        Id          = $id
                        Description = $(if ($description) { $description } else { "Install $id" })
                    }) | Out-Null
            }
            $name = $Matches[1].Trim()
            $id = $null
            $description = $null
            continue
        }
        if ($line -match '^\s*id:\s*(.+)\s*$') {
            $id = $Matches[1].Trim()
            continue
        }
        if ($line -match '^\s*description:\s*(.+)\s*$') {
            $description = $Matches[1].Trim()
            continue
        }
    }

    if ($id) {
        $packages.Add([pscustomobject]@{
                Manager     = 'winget'
                Name        = $(if ($name) { $name } else { $id })
                Id          = $id
                Description = $(if ($description) { $description } else { "Install $id" })
            }) | Out-Null
    }

    return @($packages)
}

function Get-SelectedPhaseNames {
    # Default selection is Core + Agent only. All other workloads are explicit opt-in.
    $selected = [System.Collections.Generic.List[string]]::new()
    $selected.Add('Core') | Out-Null
    $selected.Add('Agent') | Out-Null
    if ($Full -or $AgentClients) { $selected.Add('AgentClients') | Out-Null }
    if ($Full -or $Developer) { $selected.Add('Developer') | Out-Null }
    if ($Full -or $NativeBuild) { $selected.Add('NativeBuild') | Out-Null }
    if ($Full -or $Containers) { $selected.Add('Containers') | Out-Null }
    return @($selected)
}

function Get-SelectedPhases {
    $selected = @(Get-SelectedPhaseNames)
    return @($phaseDefinitions | Where-Object { $_.Name -in $selected })
}

function Get-Plan {
    $actions = [System.Collections.Generic.List[object]]::new()
    foreach ($phase in (Get-SelectedPhases)) {
        if ($phase.Config) {
            $configPath = Join-Path $configRoot $phase.Config
            $packages = @(Get-WingetConfigPackages -ConfigFile $configPath)
            $packageIds = @($packages | ForEach-Object { $_.Id })
            Add-Action $actions $phase.Name 'winget-configure' $configPath `
                -Description ("Apply winget baseline packages: " + ($(if ($packageIds) { $packageIds -join ', ' } else { $phase.Config }))) `
                -Category 'install-package' `
                -Items $packageIds
        }
        switch ($phase.Name) {
            'Core' {
                $scoopPackages = @('ripgrep', 'fd', 'fzf', 'jq', 'bat', 'delta', 'yq', '7zip', 'zip', 'nuget')
                Add-Action $actions $phase.Name 'scoop-bootstrap' 'https://get.scoop.sh' `
                    -Description 'Bootstrap Scoop package manager if missing' `
                    -Category 'bootstrap'
                Add-Action $actions $phase.Name 'scoop-install' ($scoopPackages -join ' ') `
                    -Description 'Install common CLI tools via Scoop' `
                    -Category 'install-package' `
                    -Items $scoopPackages
            }
            'Agent' {
                $agentRoot = Join-Path $env:USERPROFILE '.config\pwsh-ai'
                Add-Action $actions $phase.Name 'install-profile-overlay' $agentRoot `
                    -Description 'Write managed PowerShell overlay and core profile loader' `
                    -Category 'write-file' `
                    -Items @(
                        (Join-Path $agentRoot 'pwsh-ai-agent-overlay.ps1')
                        (Join-Path $agentRoot 'pwsh-ai-core.ps1')
                    )
                Add-Action $actions $phase.Name 'initialize-managed-agent-directories' (Join-Path $agentRoot 'hooks') `
                    -Description 'Create managed agent directories (hooks/mcp/skills/commands/rules/agents)' `
                    -Category 'create-directory' `
                    -Items @(
                        (Join-Path $agentRoot 'hooks')
                        (Join-Path $agentRoot 'mcp')
                        (Join-Path $agentRoot 'skills')
                        (Join-Path $agentRoot 'commands')
                        (Join-Path $agentRoot 'rules')
                        (Join-Path $agentRoot 'agents')
                    )
            }
            'AgentClients' {
                Add-Action $actions $phase.Name 'verify-agent-clients' 'command/version only; never install, login, or write auth/MCP secrets' `
                    -Description 'Probe whether Codex CLI exists and report version only' `
                    -Category 'probe'
            }
            'Developer' {
                Add-Action $actions $phase.Name 'scoop-install' 'golangci-lint air' `
                    -Description 'Install Go lint/hot-reload tools via Scoop' `
                    -Category 'install-package' `
                    -Items @('golangci-lint', 'air')
                Add-Action $actions $phase.Name 'go-install' 'gopls dlv air' `
                    -Description 'Install Go language tools via go install' `
                    -Category 'install-package' `
                    -Items @('gopls', 'dlv', 'air')
                Add-Action $actions $phase.Name 'powershell-modules' 'Pester PSScriptAnalyzer Microsoft.PowerShell.PSResourceGet' `
                    -Description 'Install PowerShell developer modules for current user' `
                    -Category 'install-package' `
                    -Items @('Pester', 'PSScriptAnalyzer', 'Microsoft.PowerShell.PSResourceGet')
            }
            'NativeBuild' {
                Add-Action $actions $phase.Name 'winget-install' 'Microsoft.VisualStudio.2022.BuildTools with MSVC workload' `
                    -Description 'Install Visual Studio 2022 Build Tools with VCTools workload' `
                    -Category 'install-package' `
                    -Items @('Microsoft.VisualStudio.2022.BuildTools')
                Add-Action $actions $phase.Name 'winget-install' 'Microsoft.VisualStudio.Locator' `
                    -Description 'Install vswhere / Visual Studio Locator' `
                    -Category 'install-package' `
                    -Items @('Microsoft.VisualStudio.Locator')
            }
            'Containers' {
                Add-Action $actions $phase.Name 'winget-install' 'Docker.DockerDesktop' `
                    -Description 'Install Docker Desktop package only (no WSL/backend configuration)' `
                    -Category 'install-package' `
                    -Items @('Docker.DockerDesktop')
                Add-Action $actions $phase.Name 'runtime-check' 'docker client/server (daemon may require manual start)' `
                    -Description 'Check docker client availability after install' `
                    -Category 'probe'
            }
        }
    }

    # Optional post-phase action; not a workload phase.
    if ($Full -or $EnableSafetyHooks) {
        Add-Action $actions 'SafetyHooks' 'install-safety-hooks' (Join-Path $env:USERPROFILE '.config\pwsh-ai\hooks\dangerous-git.ps1') `
            -Description 'Install managed dangerous-git safety hook' `
            -Category 'write-file' `
            -Items @((Join-Path $env:USERPROFILE '.config\pwsh-ai\hooks\dangerous-git.ps1'))
    }

    return @($actions)
}

function ConvertTo-DisplayPath {
    param([AllowNull()][string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $Path }
    $result = $Path
    if ($env:USERPROFILE -and $result.StartsWith($env:USERPROFILE, [System.StringComparison]::OrdinalIgnoreCase)) {
        $result = '%USERPROFILE%' + $result.Substring($env:USERPROFILE.Length)
    }
    if ($env:LOCALAPPDATA -and $result.StartsWith($env:LOCALAPPDATA, [System.StringComparison]::OrdinalIgnoreCase)) {
        $result = '%LOCALAPPDATA%' + $result.Substring($env:LOCALAPPDATA.Length)
    }
    return $result
}
function Get-ImpactSummary {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Actions,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$SelectedPhaseNames
    )

    $selected = @($SelectedPhaseNames)
    $notSelected = @(
        foreach ($phaseDef in $phaseDefinitions) {
            $phaseName = [string]$phaseDef.Name
            if ($selected -notcontains $phaseName) { $phaseName }
        }
    )

    $wingetPackages = [System.Collections.Generic.List[object]]::new()
    $scoopPackages = [System.Collections.Generic.List[string]]::new()
    $otherPackages = [System.Collections.Generic.List[object]]::new()
    $files = [System.Collections.Generic.List[string]]::new()
    $directories = [System.Collections.Generic.List[string]]::new()
    $probes = [System.Collections.Generic.List[string]]::new()
    $bootstraps = [System.Collections.Generic.List[string]]::new()

    foreach ($action in @($Actions)) {
        switch -Regex ($action.Action) {
            '^winget-configure$' {
                $configPath = [string]$action.Target
                foreach ($pkg in @(Get-WingetConfigPackages -ConfigFile $configPath)) {
                    $wingetPackages.Add($pkg) | Out-Null
                }
            }
            '^winget-install$' {
                foreach ($item in @($action.Items)) {
                    $otherPackages.Add([pscustomobject]@{
                            Manager     = 'winget'
                            Id          = $item
                            Description = [string]$action.Description
                        }) | Out-Null
                }
            }
            '^scoop-bootstrap$' {
                $bootstraps.Add('Scoop package manager') | Out-Null
            }
            '^scoop-install$' {
                foreach ($item in @($action.Items)) { $scoopPackages.Add([string]$item) | Out-Null }
            }
            '^(go-install|powershell-modules)$' {
                foreach ($item in @($action.Items)) {
                    $otherPackages.Add([pscustomobject]@{
                            Manager     = $(if ($action.Action -eq 'go-install') { 'go' } else { 'powershell-gallery' })
                            Id          = $item
                            Description = [string]$action.Description
                        }) | Out-Null
                }
            }
            '^install-profile-overlay$|^install-safety-hooks$' {
                foreach ($item in @($action.Items)) { $files.Add([string]$item) | Out-Null }
            }
            '^initialize-managed-agent-directories$' {
                foreach ($item in @($action.Items)) { $directories.Add([string]$item) | Out-Null }
            }
            'probe|verify|runtime-check' {
                $probes.Add([string]$action.Description) | Out-Null
            }
        }
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("Selected phases: $(if ($selected) { $selected -join ', ' } else { '(none)' })") | Out-Null
    $lines.Add("Not selected: $(if ($notSelected) { $notSelected -join ', ' } else { '(none)' })") | Out-Null

    if ($wingetPackages.Count -gt 0) {
        $lines.Add('Will install via winget-configure:') | Out-Null
        foreach ($pkg in $wingetPackages) {
            $lines.Add("  - $($pkg.Id) ($($pkg.Name)) — $($pkg.Description)") | Out-Null
        }
    }
    if ($bootstraps.Count -gt 0) {
        $lines.Add('Will bootstrap if missing:') | Out-Null
        foreach ($item in $bootstraps) { $lines.Add("  - $item") | Out-Null }
    }
    if ($scoopPackages.Count -gt 0) {
        $lines.Add('Will install via scoop (skip if already present):') | Out-Null
        foreach ($item in ($scoopPackages | Select-Object -Unique)) { $lines.Add("  - $item") | Out-Null }
    }
    if ($otherPackages.Count -gt 0) {
        $lines.Add('Will install via other managers:') | Out-Null
        foreach ($pkg in $otherPackages) {
            $lines.Add("  - [$($pkg.Manager)] $($pkg.Id)") | Out-Null
        }
    }
    if ($files.Count -gt 0) {
        $lines.Add('Will write managed files:') | Out-Null
        foreach ($item in ($files | Select-Object -Unique)) { $lines.Add("  - $(ConvertTo-DisplayPath $item)") | Out-Null }
    }
    if ($directories.Count -gt 0) {
        $lines.Add('Will create managed directories:') | Out-Null
        foreach ($item in ($directories | Select-Object -Unique)) { $lines.Add("  - $(ConvertTo-DisplayPath $item)") | Out-Null }
    }
    if ($probes.Count -gt 0) {
        $lines.Add('Will probe only (no install/login):') | Out-Null
        foreach ($item in $probes) { $lines.Add("  - $item") | Out-Null }
    }

    $lines.Add('Will NOT do by default:') | Out-Null
    $lines.Add('  - WSL / bash / apt / brew') | Out-Null
    $lines.Add('  - Codex auto-login or token/MCP secret writes') | Out-Null
    $lines.Add('  - Uninstall packages on rollback') | Out-Null
    if ($notSelected -contains 'Developer') { $lines.Add('  - Developer workload') | Out-Null }
    if ($notSelected -contains 'NativeBuild') { $lines.Add('  - NativeBuild workload') | Out-Null }
    if ($notSelected -contains 'Containers') { $lines.Add('  - Containers workload') | Out-Null }
    if ($notSelected -contains 'AgentClients') { $lines.Add('  - AgentClients probe') | Out-Null }

    $mayElevate = ($wingetPackages.Count -gt 0) -or (@($Actions | Where-Object Action -match 'winget').Count -gt 0)

    return [pscustomobject]@{
        Selected              = @($selected)
        NotSelected           = @($notSelected)
        WingetPackages        = @($wingetPackages)
        ScoopPackages         = @($scoopPackages | Select-Object -Unique)
        OtherPackages         = @($otherPackages)
        ManagedFiles          = @($files | Select-Object -Unique)
        ManagedDirectories    = @($directories | Select-Object -Unique)
        Probes                = @($probes)
        Bootstraps            = @($bootstraps)
        MayRequireElevation   = [bool]$mayElevate
        HumanReadableLines    = @($lines)
    }
}

function Get-ResultSummary {
    param(
        [Parameter(Mandatory = $true)][string]$Mode,
        [Parameter(Mandatory = $true)]$Impact,
        [object[]]$PhaseResults = @(),
        [object[]]$StepResults = @(),
        [object]$PostApplyVerification = $null,
        [bool]$Changed = $false
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("Mode: $Mode") | Out-Null
    $lines.Add("Changed: $Changed") | Out-Null
    $lines.Add("Selected: $((@($Impact.Selected) -join ', '))") | Out-Null

    if ($Mode -eq 'WhatIf') {
        $lines.Add('This is a preview only. No packages or managed files were changed.') | Out-Null
    }

    foreach ($line in @($Impact.HumanReadableLines)) {
        $lines.Add([string]$line) | Out-Null
    }

    if (@($PhaseResults).Count -gt 0) {
        $lines.Add('Phase results:') | Out-Null
        foreach ($phase in @($PhaseResults)) {
            $detail = if ($phase.PSObject.Properties.Name -contains 'Detail' -and $phase.Detail) { " — $($phase.Detail)" } else { '' }
            $lines.Add("  - $($phase.Name): $($phase.Status)$detail") | Out-Null
        }
    }

    if (@($StepResults).Count -gt 0) {
        $lines.Add('Step results:') | Out-Null
        foreach ($step in @($StepResults)) {
            $reason = if ($step.PSObject.Properties.Name -contains 'Reason' -and $step.Reason) { " ($($step.Reason))" } else { '' }
            $lines.Add("  - [$($step.Phase)] $($step.Action): $($step.Status)$reason") | Out-Null
            if ($step.PSObject.Properties.Name -contains 'Items' -and @($step.Items).Count -gt 0) {
                $lines.Add("      items: $((@($step.Items) -join ', '))") | Out-Null
            }
        }
    }

    if ($null -ne $PostApplyVerification) {
        if ($PostApplyVerification.PSObject.Properties.Name -contains 'Summary') {
            $summary = $PostApplyVerification.Summary
            $requiredMissing = if ($summary.PSObject.Properties.Name -contains 'RequiredMissing') { $summary.RequiredMissing } else { 'n/a' }
            $runtimeFailures = if ($summary.PSObject.Properties.Name -contains 'RuntimeFailures') { $summary.RuntimeFailures } else { 'n/a' }
            $lines.Add("Post-apply verification: RequiredMissing=$requiredMissing RuntimeFailures=$runtimeFailures") | Out-Null
        } elseif ($PostApplyVerification.PSObject.Properties.Name -contains 'Error') {
            $lines.Add("Post-apply verification error: $($PostApplyVerification.Error)") | Out-Null
        }
    }

    return @($lines)
}
