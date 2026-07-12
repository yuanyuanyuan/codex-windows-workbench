[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$ApplyUserEnvironment,
    [string]$PrivateSettingsPath
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$overlaySource = Join-Path $repoRoot 'config\pwsh-ai-agent-overlay.ps1'
$refreshEnvPath = Join-Path $PSScriptRoot 'Refresh-EnvPath.ps1'
$targetDir = Join-Path $env:USERPROFILE '.config\pwsh-ai'
$overlayTarget = Join-Path $targetDir 'pwsh-ai-agent-overlay.ps1'
$coreProfile = Join-Path $targetDir 'pwsh-ai-core.ps1'
$privateOverlayTarget = Join-Path $targetDir 'private-overlay.ps1'

if (-not (Test-Path -LiteralPath $overlaySource)) {
    throw "Overlay source not found: $overlaySource"
}

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

if ($PSCmdlet.ShouldProcess($overlayTarget, 'Copy agent overlay')) {
    Copy-Item -LiteralPath $overlaySource -Destination $overlayTarget -Force
}

if ($PrivateSettingsPath) {
    if (-not (Test-Path -LiteralPath $PrivateSettingsPath)) {
        throw "Private settings path not found: $PrivateSettingsPath"
    }

    $privateRoot = if ((Get-Item -LiteralPath $PrivateSettingsPath).PSIsContainer) {
        $PrivateSettingsPath
    } else {
        Split-Path -Parent $PrivateSettingsPath
    }

    $privateOverlaySource = Join-Path $privateRoot 'private-overlay.ps1'
    if (-not (Test-Path -LiteralPath $privateOverlaySource)) {
        $privateOverlaySource = Join-Path $privateRoot 'config\private-overlay.ps1'
    }
    if (-not (Test-Path -LiteralPath $privateOverlaySource)) {
        throw "private-overlay.ps1 not found under: $privateRoot"
    }

    if ($PSCmdlet.ShouldProcess($privateOverlayTarget, 'Copy private overlay')) {
        Copy-Item -LiteralPath $privateOverlaySource -Destination $privateOverlayTarget -Force

        # Keep local proxy settings next to the installed private overlay when present.
        $localProxySource = Join-Path (Split-Path -Parent $privateOverlaySource) 'local-proxy-settings.ps1'
        if (Test-Path -LiteralPath $localProxySource) {
            Copy-Item -LiteralPath $localProxySource -Destination (Join-Path $targetDir 'local-proxy-settings.ps1') -Force
        }
    }
}

if (Test-Path -LiteralPath $coreProfile) {
    $marker = 'PWSH_AI_AGENT_OVERLAY'
    $coreText = Get-Content -LiteralPath $coreProfile -Raw
    if ($coreText -notmatch [regex]::Escape($marker)) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backup = "$coreProfile.bak-$stamp"
        if ($PSCmdlet.ShouldProcess($coreProfile, 'Backup and append overlay loader')) {
            Copy-Item -LiteralPath $coreProfile -Destination $backup -Force
            Add-Content -LiteralPath $coreProfile -Encoding utf8 -Value @"

# $marker
`$pwshAiAgentOverlay = "`$env:USERPROFILE\.config\pwsh-ai\pwsh-ai-agent-overlay.ps1"
if (Test-Path -LiteralPath `$pwshAiAgentOverlay) { . `$pwshAiAgentOverlay }
"@
        }
    }
} else {
    if ($PSCmdlet.ShouldProcess($coreProfile, 'Create core profile loading overlay')) {
        Set-Content -LiteralPath $coreProfile -Encoding utf8 -Value @"
# pwsh-ai-core.ps1
`$pwshAiAgentOverlay = "`$env:USERPROFILE\.config\pwsh-ai\pwsh-ai-agent-overlay.ps1"
if (Test-Path -LiteralPath `$pwshAiAgentOverlay) { . `$pwshAiAgentOverlay }
"@
    }
}

if ($ApplyUserEnvironment) {
    $userEnv = @{
        GOPATH = Join-Path $env:USERPROFILE 'go'
        GOPROXY = 'https://proxy.golang.org,direct'
        GOSUMDB = 'sum.golang.org'
        PYTHONIOENCODING = 'utf-8'
        PYTHONUTF8 = '1'
        NO_PROXY = 'localhost,127.0.0.1,::1'
    }

    # Machine-local proxy endpoints are never hardcoded here.
    # Load them from the installed private settings if present.
    $localProxySettings = Join-Path $targetDir 'local-proxy-settings.ps1'
    if (Test-Path -LiteralPath $localProxySettings) {
        . $localProxySettings
        if ($script:PwshAiPrivateProxy) {
            foreach ($entry in $script:PwshAiPrivateProxy.GetEnumerator()) {
                $userEnv[$entry.Key] = $entry.Value
            }
        }
    }

    $userEnvKey = 'HKCU:\Environment'
    foreach ($entry in $userEnv.GetEnumerator()) {
        if ($PSCmdlet.ShouldProcess("User env:$($entry.Key)", "Set $($entry.Value)")) {
            New-ItemProperty -Path $userEnvKey -Name $entry.Key -Value $entry.Value -PropertyType String -Force | Out-Null
            Set-Item -Path "Env:$($entry.Key)" -Value $entry.Value
        }
    }
}

if (Test-Path -LiteralPath $refreshEnvPath) {
    . $refreshEnvPath | Out-Null
}

'Installed pwsh agent overlay.'
"Overlay: $overlayTarget"
"Core:    $coreProfile"
if (Test-Path -LiteralPath $privateOverlayTarget) {
    "Private: $privateOverlayTarget"
}
