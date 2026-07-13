[CmdletBinding()]
param([switch]$Json)

$ErrorActionPreference = 'Stop'
$installer = Join-Path $PSScriptRoot 'Install-AgentClients.ps1'
$raw = & pwsh -NoLogo -NoProfile -File $installer -StatusOnly -Json
$report = $raw | ConvertFrom-Json
if ($report.Policy.WritesAuthTokens -or $report.Policy.WritesMcpEndpoints -or $report.Policy.WritesPermissions) {
    throw 'Agent client installer must not write auth/MCP/permissions state.'
}
foreach ($client in @($report.Clients)) {
    if ($client.AuthStateWritten -or $client.McpStateWritten -or $client.PermissionsWritten) {
        throw "Client $($client.Name) reported secret/config writes."
    }
}
# Public surface is Codex only for MVP.
$public = @($report.Policy.PublicClients)
if ($public -ne @('Codex') -and -not ($public.Count -eq 1 -and $public[0] -eq 'Codex')) {
    throw "Public clients must be Codex-only for MVP. Found: $($public -join ',')"
}
if ($Json) { $report | ConvertTo-Json -Depth 6 } else { 'Agent client tests passed.' }
