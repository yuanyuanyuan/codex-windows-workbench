[CmdletBinding()]
param(
    [switch]$Json,
    [string[]]$Configs,
    [switch]$SkipWingetTest
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'PowerShell 7 or newer is required. Windows PowerShell 5.1 is not supported.'
}

if (-not $IsWindows) {
    throw 'Native Windows is required. WSL and non-Windows hosts are not supported.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$configRoot = Join-Path $repoRoot 'config'
$refreshPath = Join-Path $PSScriptRoot 'Refresh-EnvPath.ps1'

if (-not $Configs -or @($Configs).Count -eq 0) {
    $Configs = @((Join-Path $configRoot 'windows-agent-core.winget'))
} else {
    $Configs = @($Configs)
}

$checks = [System.Collections.Generic.List[object]]::new()
$blockers = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-Check {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][ValidateSet('OK', 'WARN', 'FAIL', 'SKIP')]$Status,
        [string]$Detail = ''
    )
    $checks.Add([pscustomobject]@{
            Name   = $Name
            Status = $Status
            Detail = $Detail
        })
    if ($Status -eq 'FAIL') { $blockers.Add(("{0}: {1}" -f $Name, $Detail)) | Out-Null }
    if ($Status -eq 'WARN') { $warnings.Add(("{0}: {1}" -f $Name, $Detail)) | Out-Null }
}

# 1) Host checks
$psMajor = $PSVersionTable.PSVersion.Major
if ($psMajor -ge 7) {
    Add-Check -Name 'powershell-version' -Status 'OK' -Detail $PSVersionTable.PSVersion.ToString()
} else {
    Add-Check -Name 'powershell-version' -Status 'FAIL' -Detail "PowerShell $psMajor is unsupported"
}

if ($IsWindows) {
    Add-Check -Name 'windows-platform' -Status 'OK' -Detail ([System.Environment]::OSVersion.VersionString)
} else {
    Add-Check -Name 'windows-platform' -Status 'FAIL' -Detail 'Not native Windows'
}

# 2) Refresh PATH before command checks
if (Test-Path -LiteralPath $refreshPath) {
    try {
        . $refreshPath | Out-Null
        Add-Check -Name 'path-refresh' -Status 'OK' -Detail $refreshPath
    } catch {
        Add-Check -Name 'path-refresh' -Status 'WARN' -Detail $_.Exception.Message
    }
} else {
    Add-Check -Name 'path-refresh' -Status 'WARN' -Detail "Refresh script missing: $refreshPath"
}

# 3) Required local directories / tools
$requiredPaths = @(
    $repoRoot
    $configRoot
    (Join-Path $PSScriptRoot 'Initialize-PwshAgentWindows.ps1')
    (Join-Path $PSScriptRoot 'Install-PwshAgentEnv.ps1')
    (Join-Path $PSScriptRoot 'Test-PwshAgentEnv.ps1')
)
foreach ($path in $requiredPaths) {
    if (Test-Path -LiteralPath $path) {
        Add-Check -Name "path:$([System.IO.Path]::GetFileName($path))" -Status 'OK' -Detail $path
    } else {
        Add-Check -Name "path:$([System.IO.Path]::GetFileName($path))" -Status 'FAIL' -Detail "Missing $path"
    }
}

$winget = Get-Command winget -ErrorAction SilentlyContinue
if ($winget) {
    $wingetVersion = (& winget --version 2>&1 | Out-String).Trim()
    Add-Check -Name 'winget-available' -Status 'OK' -Detail $wingetVersion
} else {
    Add-Check -Name 'winget-available' -Status 'FAIL' -Detail 'winget command not found'
}

# 4) Proxy reachability without logging secrets
function Get-ProxyEndpointHint {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    try {
        $uri = [Uri]$Value
        if ($uri.IsAbsoluteUri) {
            return '{0}://{1}:{2}' -f $uri.Scheme, $uri.Host, $uri.Port
        }
    } catch {
        # Fall through to host:port redaction.
    }
    # Redact credentials and path/query; keep only host-like fragment.
    $redacted = $Value -replace '://[^@/]+@', '://***@'
    $redacted = $redacted -replace '([?&](token|key|password|secret)=)[^&]+', '$1***'
    if ($redacted.Length -gt 80) { $redacted = $redacted.Substring(0, 80) + '...' }
    return $redacted
}

$proxyCandidates = @(@(
    [pscustomobject]@{ Name = 'HTTPS_PROXY'; Value = $env:HTTPS_PROXY }
    [pscustomobject]@{ Name = 'HTTP_PROXY'; Value = $env:HTTP_PROXY }
    [pscustomobject]@{ Name = 'ALL_PROXY'; Value = $env:ALL_PROXY }
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Value) })

if (@($proxyCandidates).Count -eq 0) {
    Add-Check -Name 'proxy-reachability' -Status 'SKIP' -Detail 'No process proxy environment variables set'
} else {
    $primary = $proxyCandidates[0]
    $hint = Get-ProxyEndpointHint -Value $primary.Value
    try {
        $uri = $null
        try { $uri = [Uri]$primary.Value } catch { $uri = $null }
        if ($null -eq $uri -or -not $uri.IsAbsoluteUri) {
            Add-Check -Name 'proxy-reachability' -Status 'WARN' -Detail "Proxy value for $($primary.Name) is not a parseable absolute URI ($hint)"
        } else {
            $client = [System.Net.Sockets.TcpClient]::new()
            $iar = $client.BeginConnect($uri.Host, $uri.Port, $null, $null)
            $ok = $iar.AsyncWaitHandle.WaitOne(2000, $false)
            if (-not $ok) {
                $client.Close()
                Add-Check -Name 'proxy-reachability' -Status 'WARN' -Detail "TCP connect timeout to $hint ($($primary.Name))"
            } else {
                try {
                    $client.EndConnect($iar)
                    Add-Check -Name 'proxy-reachability' -Status 'OK' -Detail "TCP connect succeeded to $hint ($($primary.Name))"
                } catch {
                    Add-Check -Name 'proxy-reachability' -Status 'WARN' -Detail "TCP connect failed to $hint ($($primary.Name))"
                } finally {
                    $client.Close()
                }
            }
        }
    } catch {
        Add-Check -Name 'proxy-reachability' -Status 'WARN' -Detail "Proxy check failed for $($primary.Name) ($hint)"
    }
}

# 5) winget configure validate for selected documents
$skipWingetDocs = $env:PWSH_AI_AGENT_SKIP_WINGET_PREFLIGHT -eq '1'
if ($skipWingetDocs) {
    Add-Check -Name 'winget-documents' -Status 'SKIP' -Detail 'PWSH_AI_AGENT_SKIP_WINGET_PREFLIGHT=1'
}

function Invoke-WingetText {
    param(
        [Parameter(Mandatory = $true)][string[]]$ArgumentList
    )
    $output = & winget @ArgumentList 2>&1
    $code = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    return [pscustomobject]@{
        ExitCode = $code
        Text     = (($output | ForEach-Object { "$_" }) -join "`n")
    }
}

function Test-IsKnownModulePublicityWarning {
    param([Parameter(Mandatory = $true)][string]$Text)
    return (
        $Text -match 'not available publicly' -or
        $Text -match 'The module was not provided' -or
        $Text -match 'Microsoft\.WinGet/Package'
    ) -and (
        $Text -notmatch '(?i)YAML|schema validation failed|parse error|resource not found|unable to parse'
    )
}

$wingetResults = [System.Collections.Generic.List[object]]::new()
if (-not $skipWingetDocs) {
foreach ($configPath in $Configs) {
    $name = Split-Path -Leaf $configPath
    if (-not (Test-Path -LiteralPath $configPath)) {
        Add-Check -Name "winget-validate:$name" -Status 'FAIL' -Detail "Missing configuration file $configPath"
        continue
    }
    if (-not $winget) {
        Add-Check -Name "winget-validate:$name" -Status 'FAIL' -Detail 'winget unavailable'
        continue
    }

    $validate = Invoke-WingetText -ArgumentList @(
        'configure', 'validate',
        '-f', $configPath,
        '--disable-interactivity'
    )
    $knownWarning = Test-IsKnownModulePublicityWarning -Text $validate.Text
    $hasParseOrSchemaError = $validate.Text -match '(?i)(YAML|schema).*(error|failed)|parse error|unable to parse|invalid configuration'
    $entry = [ordered]@{
        Config           = $configPath
        ValidateExitCode = $validate.ExitCode
        KnownWarning     = [bool]$knownWarning
        ValidateSnippet  = (($validate.Text -split "`n" | Select-Object -First 8) -join ' ').Trim()
        TestExitCode     = $null
        TestStatus       = 'SKIP'
    }

    if ($hasParseOrSchemaError) {
        Add-Check -Name "winget-validate:$name" -Status 'FAIL' -Detail "YAML/schema/resource error. $($entry.ValidateSnippet)"
        $wingetResults.Add([pscustomobject]$entry) | Out-Null
        continue
    }

    if ($validate.ExitCode -eq 0) {
        Add-Check -Name "winget-validate:$name" -Status 'OK' -Detail 'validate exit 0'
    } elseif ($knownWarning) {
        Add-Check -Name "winget-validate:$name" -Status 'WARN' -Detail 'Known DSC module-publicity warning (not a blocker).'
    } else {
        Add-Check -Name "winget-validate:$name" -Status 'FAIL' -Detail "validate exit $($validate.ExitCode). $($entry.ValidateSnippet)"
        $wingetResults.Add([pscustomobject]$entry) | Out-Null
        continue
    }

    if (-not $SkipWingetTest) {
        try {
            $test = Invoke-WingetText -ArgumentList @(
                'configure', 'test',
                '-f', $configPath,
                '--accept-configuration-agreements',
                '--disable-interactivity'
            )
            $entry.TestExitCode = $test.ExitCode
            $testSnippet = (($test.Text -split "`n" | Select-Object -First 6) -join ' ').Trim()
            if ($test.ExitCode -eq 0) {
                $entry.TestStatus = 'OK'
                Add-Check -Name "winget-test:$name" -Status 'OK' -Detail 'configure test exit 0'
            } elseif (Test-IsKnownModulePublicityWarning -Text $test.Text) {
                $entry.TestStatus = 'WARN'
                Add-Check -Name "winget-test:$name" -Status 'WARN' -Detail "configure test warning-only/known publicity issue: $testSnippet"
            } else {
                # Do not treat "not in desired state" as a preflight blocker; that is for apply.
                $entry.TestStatus = 'WARN'
                Add-Check -Name "winget-test:$name" -Status 'WARN' -Detail "configure test exit $($test.ExitCode): $testSnippet"
            }
        } catch {
            $entry.TestStatus = 'WARN'
            Add-Check -Name "winget-test:$name" -Status 'WARN' -Detail "configure test unsupported or failed: $($_.Exception.Message)"
        }
    } else {
        Add-Check -Name "winget-test:$name" -Status 'SKIP' -Detail 'SkipWingetTest requested'
    }

    $wingetResults.Add([pscustomobject]$entry) | Out-Null
}
}

$summary = [pscustomobject]@{
    Blockers = @($blockers).Count
    Warnings = @($warnings).Count
    Checks   = @($checks).Count
    Ok       = @($checks | Where-Object Status -eq 'OK').Count
}

$report = [pscustomobject]@{
    Mode           = 'Preflight'
    Changed        = $false
    Host           = [pscustomobject]@{
        PSVersion = $PSVersionTable.PSVersion.ToString()
        OS        = [System.Environment]::OSVersion.VersionString
        IsWindows = [bool]$IsWindows
    }
    Summary        = $summary
    Checks         = @($checks)
    Blockers       = @($blockers)
    Warnings       = @($warnings)
    WingetDocuments = @($wingetResults)
}

if ($Json) {
    $report | ConvertTo-Json -Depth 8
} else {
    'Preflight'
    $report.Host | Format-List
    $checks | Format-Table -AutoSize
    if (@($warnings).Count -gt 0) {
        'Warnings'
        $warnings | ForEach-Object { "- $_" }
    }
    if (@($blockers).Count -gt 0) {
        'Blockers'
        $blockers | ForEach-Object { "- $_" }
    }
    'Summary'
    $summary | Format-List
}

if (@($blockers).Count -gt 0) { exit 1 }
