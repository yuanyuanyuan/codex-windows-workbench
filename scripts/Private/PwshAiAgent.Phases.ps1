# Phase definitions and action-plan generation for the workbench.
# Dot-sourced by Initialize-PwshAgentWindows.ps1 only.

$script:PwshAiAgentPhaseDefinitions = @(
    [pscustomobject]@{
        Name        = 'Core'
        Config      = 'windows-agent-core.winget'
        Description = 'PowerShell 7, source control, Node, Python, Docker CLI, and kubectl.'
    }
    [pscustomobject]@{
        Name        = 'Agent'
        Config      = $null
        Description = 'PowerShell profile overlay, agent paths, and managed hook directories.'
    }
    [pscustomobject]@{
        Name        = 'AgentClients'
        Config      = $null
        Description = 'Explicit agent CLI install/verify. Public MVP supports Codex only.'
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
        [Parameter(Mandatory = $true)][string]$Target
    )
    $Actions.Add([pscustomobject]@{
            Phase  = $Phase
            Action = $Action
            Target = $Target
        })
}

function Get-SelectedPhases {
    # Default selection is Core + Agent only. All other workloads are explicit opt-in.
    $selected = @('Core', 'Agent')
    if ($Full -or $AgentClients) { $selected += 'AgentClients' }
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
            'AgentClients' {
                Add-Action $actions $phase.Name 'install-agent-clients' (Join-Path $configRoot 'agent-clients.json')
                Add-Action $actions $phase.Name 'verify-agent-clients' 'command/version only; never write auth or MCP secrets'
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
