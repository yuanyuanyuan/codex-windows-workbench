[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Json,
    [switch]$StatusOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'PowerShell 7 or newer is required. Windows PowerShell 5.1 is not supported.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $repoRoot 'config\agent-clients.json'
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Agent client manifest not found: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$results = [System.Collections.Generic.List[object]]::new()

foreach ($client in @($manifest.Clients)) {
    $command = Get-Command $client.Command -ErrorAction SilentlyContinue
    $status = if ($command) { 'Installed' } else { 'Missing' }
    $version = $null
    $invocation = 'n/a'
    if ($command) {
        try {
            $versionOutput = & $client.Command --version 2>&1 | Out-String
            $version = $versionOutput.Trim()
            $invocation = 'OK'
        } catch {
            $status = 'InvocationFailed'
            $invocation = $_.Exception.Message
        }
    }

    $login = if ($client.RequiresLogin) { 'LoginRequired' } else { 'NotRequired' }
    $results.Add([pscustomobject]@{
            Name            = $client.Name
            Source          = $client.Source
            Command         = $client.Command
            Status          = $status
            Version         = $version
            Login           = $login
            Invocation      = $invocation
            Public          = [bool]$client.Public
            AuthStateWritten = $false
            McpStateWritten  = $false
            PermissionsWritten = $false
            ResolvedPath    = if ($command) { $command.Source } else { $null }
        }) | Out-Null
}

# Safety contract: this installer never writes tokens, MCP URLs, or permission grants.
$report = [pscustomobject]@{
    Mode    = if ($StatusOnly) { 'Status' } else { 'InstallOrVerify' }
    Changed = $false
    Clients = @($results)
    Policy  = [pscustomobject]@{
        WritesAuthTokens = $false
        WritesMcpEndpoints = $false
        WritesPermissions = $false
        PublicClients = @($manifest.Clients | Where-Object Public -eq $true | ForEach-Object Name)
    }
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
} else {
    $results | Format-Table -AutoSize
    'Policy: never write auth tokens, MCP endpoints, or permissions files.'
}
