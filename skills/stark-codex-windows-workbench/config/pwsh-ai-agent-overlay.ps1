# ============================================
# pwsh-ai-agent-overlay.ps1
# Codex/AI agent runtime overlay for Windows PowerShell.
# Low-noise, deterministic, and safe to source repeatedly.
# ============================================

$script:PwshAiAgentOverlayVersion = '2026.07.14.3'

function Add-AgentPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [switch]$Prepend
    )

    $expanded = [Environment]::ExpandEnvironmentVariables($Path)
    if (-not (Test-Path -LiteralPath $expanded)) { return }

    $entries = @($env:PATH -split ';' | Where-Object { $_ })
    $normalized = $expanded.TrimEnd('\')
    $exists = $entries | Where-Object {
        [string]::Equals($_.TrimEnd('\'), $normalized, [StringComparison]::OrdinalIgnoreCase)
    }

    if ($exists) { return }
    if ($Prepend) { $env:PATH = "$expanded;$env:PATH" }
    else { $env:PATH = "$env:PATH;$expanded" }
}

function Remove-AgentPath {
    param([Parameter(Mandatory=$true)][string[]]$Path)

    $remove = @($Path | ForEach-Object {
        [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\')
    })

    $env:PATH = (($env:PATH -split ';' | Where-Object { $_ } | Where-Object {
        $entry = $_.TrimEnd('\')
        -not ($remove | Where-Object {
            [string]::Equals($_, $entry, [StringComparison]::OrdinalIgnoreCase)
        })
    }) -join ';')
}

# 1. Clean, machine-readable output for agent subprocesses.
if ($PSStyle) { $PSStyle.OutputRendering = 'PlainText' }
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$env:PYTHONIOENCODING = 'utf-8'
$env:PYTHONUTF8 = '1'

# 2. Proxy policy:
# Keep already configured process/user proxy values.
# Machine-specific endpoints are supplied by an optional local private overlay.
if (-not $env:NO_PROXY) {
    $env:NO_PROXY = 'localhost,127.0.0.1,::1'
}

# 3. Go defaults. GOPATH remains the standard user-level location.
$env:GOPATH = Join-Path $env:USERPROFILE 'go'
if (-not $env:GOPROXY) {
    $env:GOPROXY = 'https://proxy.golang.org,direct'
}
if (-not $env:GOSUMDB) {
    $env:GOSUMDB = 'sum.golang.org'
}
Add-AgentPath -Path "$env:USERPROFILE\go\bin" -Prepend

# 4. Prefer predictable CLI sources over incidental application folders.
Add-AgentPath -Path "$env:USERPROFILE\scoop\shims" -Prepend
Add-AgentPath -Path "$env:USERPROFILE\scoop\shims\busybox-tools" -Prepend
Add-AgentPath -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Links" -Prepend
# Prefer persistent npm global CLI; desktop OpenAI bin is fallback only.
# Same authority policy as codex/bun: %APPDATA%\npm wins over fnm multishell shims.
Add-AgentPath -Path "$env:APPDATA\npm" -Prepend
Add-AgentPath -Path "$env:LOCALAPPDATA\OpenAI\Codex\bin"
Add-AgentPath -Path "$env:USERPROFILE\.local\bin" -Prepend
Add-AgentPath -Path "$env:LOCALAPPDATA\pnpm" -Prepend
Add-AgentPath -Path "$env:APPDATA\Python\Python313\Scripts" -Prepend

# Optional machine-local private overlay. Install/copy from a private settings repo.
$privateOverlay = Join-Path $env:USERPROFILE '.config\pwsh-ai\private-overlay.ps1'
if (Test-Path -LiteralPath $privateOverlay) {
    . $privateOverlay
}

# Final authority: persistent npm global CLIs (codex, bun) must stay ahead of
# fnm multishell paths that can appear later via profile re-entry.
$npmGlobalPath = Join-Path $env:APPDATA 'npm'
if (Test-Path -LiteralPath $npmGlobalPath) {
    $env:PATH = (($env:PATH -split ';' | Where-Object {
        $_ -and -not [string]::Equals($_.TrimEnd('\'), $npmGlobalPath.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)
    }) -join ';')
    $env:PATH = "$npmGlobalPath;$env:PATH"
}

$env:PATH = (($env:PATH -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';')

function Update-BunCli {
    param(
        [string]$Version = 'latest'
    )
    $prefix = Join-Path $env:APPDATA 'npm'
    Write-Host "Installing bun@$Version into $prefix"
    npm install -g "bun@$Version" --prefix $prefix
    if (Get-Command fnm -ErrorAction SilentlyContinue) {
        Write-Host 'Also installing into current fnm node prefix for consistency'
        npm install -g "bun@$Version"
    }
    $cmd = Get-Command bun -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "Resolved: $($cmd.Source)"
        & bun --version
    }
}

function agent-path-doctor {
    $interesting = @('codex','bun','node','npm','fnm','rg','fd','fzf','jq','yq','7z','go','gofmt','gopls','dlv','golangci-lint','air','cmake','ninja','msbuild','nuget','rsync','zip','winget','scoop','choco')
    foreach ($command in $interesting) {
        $resolved = Get-Command $command -ErrorAction SilentlyContinue
        [pscustomobject]@{
            Command = $command
            Status = if ($resolved) { 'OK' } else { 'MISSING' }
            Type = if ($resolved) { $resolved.CommandType } else { '' }
            Source = if ($resolved) { $resolved.Source } else { '' }
        }
    }
}

function Get-RedactedProxyHint {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    try {
        $uri = [Uri]$Value
        if ($uri.IsAbsoluteUri) {
            return '{0}://{1}:{2}' -f $uri.Scheme, $uri.Host, $uri.Port
        }
    } catch {
        # Fall through to generic redaction.
    }
    $redacted = $Value -replace '://[^@/]+@', '://***@'
    $redacted = $redacted -replace '([?&](token|key|password|secret)=)[^&]+', '$1***'
    if ($redacted.Length -gt 80) { $redacted = $redacted.Substring(0, 80) + '...' }
    return $redacted
}

function agent-env-doctor {
    [pscustomobject]@{
        PSVersion = $PSVersionTable.PSVersion.ToString()
        OverlayVersion = $script:PwshAiAgentOverlayVersion
        OutputRendering = if ($PSStyle) { $PSStyle.OutputRendering } else { 'n/a' }
        OutputEncoding = [Console]::OutputEncoding.WebName
        InputEncoding = [Console]::InputEncoding.WebName
        HTTP_PROXY = Get-RedactedProxyHint -Value $env:HTTP_PROXY
        HTTPS_PROXY = Get-RedactedProxyHint -Value $env:HTTPS_PROXY
        ALL_PROXY = Get-RedactedProxyHint -Value $env:ALL_PROXY
        NO_PROXY = $env:NO_PROXY
        GOPATH = $env:GOPATH
        GOPROXY = $env:GOPROXY
        GOSUMDB = $env:GOSUMDB
        BunResolved = (Get-Command bun -ErrorAction SilentlyContinue).Source
        CodexResolved = (Get-Command codex -ErrorAction SilentlyContinue).Source
        GstackRepo = if (Test-Path -LiteralPath (Join-Path $env:USERPROFILE 'gstack')) { '%USERPROFILE%\gstack' } else { '' }
        GstackCodexSkill = if (Test-Path -LiteralPath (Join-Path $env:USERPROFILE '.codex\skills\gstack\SKILL.md')) { 'present' } else { 'missing' }
    } | Format-List
}
