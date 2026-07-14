#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version,
    [switch]$RequireEvidence
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..') | Select-Object -ExpandProperty Path
$skillRoot = Join-Path $repoRoot 'skills\stark-codex-windows-workbench'
$requiredFiles = @(
    'AGENTS.md',
    'SECURITY.md',
    'rules\release\RELEASE-RULES.md',
    'skills\stark-codex-windows-workbench\scripts\Initialize-PwshAgentWindows.ps1',
    'skills\stark-codex-windows-workbench\config\external-artifacts.json'
)

foreach ($relativePath in $requiredFiles) {
    $path = Join-Path $repoRoot $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Release requirement missing: $relativePath"
    }
}

$package = Get-Content -LiteralPath (Join-Path $repoRoot 'package.json') -Raw | ConvertFrom-Json
$plugin = Get-Content -LiteralPath (Join-Path $repoRoot '.codex-plugin\plugin.json') -Raw | ConvertFrom-Json
if ($package.version -ne $Version) { throw "package.json version '$($package.version)' does not match '$Version'." }
if ($plugin.version -ne $Version) { throw "plugin version '$($plugin.version)' does not match '$Version'." }

$changelog = Get-Content -LiteralPath (Join-Path $repoRoot 'CHANGELOG.md') -Raw
if ($changelog -notmatch "(?m)^##\s+$([regex]::Escape($Version))\s+-\s+\d{4}-\d{2}-\d{2}\s*$") {
    throw "CHANGELOG.md must begin with a dated $Version heading."
}

$artifactManifest = Get-Content -LiteralPath (Join-Path $skillRoot 'config\external-artifacts.json') -Raw | ConvertFrom-Json
if (-not $artifactManifest.scoopBootstrap -or
    [string]::IsNullOrWhiteSpace($artifactManifest.scoopBootstrap.source) -or
    [string]::IsNullOrWhiteSpace($artifactManifest.scoopBootstrap.sha256) -or
    $artifactManifest.scoopBootstrap.sha256 -notmatch '^[A-Fa-f0-9]{64}$') {
    throw 'external-artifacts.json must pin scoopBootstrap source and SHA-256.'
}

$docsToCheck = @('README.md', 'README.zh-CN.md', 'docs\install.md')
foreach ($relativePath in $docsToCheck) {
    $content = Get-Content -LiteralPath (Join-Path $repoRoot $relativePath) -Raw
    if ($content -match 'https://raw\.githubusercontent\.com/[^\s)]+/(master|main)/') {
        throw "$relativePath contains a mutable raw branch URL."
    }
    if ($content -match '(?i)\bred\s*skill\b|\bcodex\s+plugin\b') {
        throw "$relativePath advertises an unsupported installation channel."
    }
}

# High-signal secret / personal-data content scan for public packaging hygiene.
$denyPatterns = @(
    [pscustomobject]@{ Name = 'AWS access key id'; Regex = 'AKIA[0-9A-Z]{16}' }
    [pscustomobject]@{ Name = 'GitHub token'; Regex = 'gh[po]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}' }
    [pscustomobject]@{ Name = 'Slack token'; Regex = 'xox[baprs]-[A-Za-z0-9-]{10,}' }
    [pscustomobject]@{ Name = 'Stripe live key'; Regex = 'sk_live_[A-Za-z0-9]{20,}' }
    [pscustomobject]@{ Name = 'Anthropic API key'; Regex = 'sk-ant-[A-Za-z0-9\-_]{20,}' }
    [pscustomobject]@{ Name = 'Private key block'; Regex = '-----BEGIN (?:RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----' }
    [pscustomobject]@{ Name = 'Basic-auth URL credential'; Regex = '://[^/\s"''`:]+:[^/\s"''`@]+@' }
    [pscustomobject]@{ Name = 'Absolute Windows user path'; Regex = '(?i)C:\\Users\\(?!Public\\|Everyone\\|<|%|用户名|username|your[_-]?name|xxx|example)[^\s\\/:"<>|]+\\' }
)

$scanRoots = @(
    (Join-Path $repoRoot 'skills')
    (Join-Path $repoRoot '.github')
    (Join-Path $repoRoot 'tests')
    (Join-Path $repoRoot '.codex-plugin')
)
$scanFiles = [System.Collections.Generic.List[string]]::new()
foreach ($root in $scanRoots) {
    if (Test-Path -LiteralPath $root) {
        Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -match '\.(ps1|psm1|psd1|yml|yaml|json|md|winget|txt|xml)$' -or $_.Name -in @('CODEOWNERS','LICENSE') } |
            ForEach-Object { $scanFiles.Add($_.FullName) | Out-Null }
    }
}
foreach ($relativePath in @('package.json', 'AGENTS.md', 'SECURITY.md', 'CHANGELOG.md')) {
    $path = Join-Path $repoRoot $relativePath
    if (Test-Path -LiteralPath $path) { $scanFiles.Add($path) | Out-Null }
}

foreach ($file in ($scanFiles | Select-Object -Unique)) {
    $content = Get-Content -LiteralPath $file -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($content)) { continue }
    foreach ($pattern in $denyPatterns) {
        if ($content -match $pattern.Regex) {
            $rel = $file.Substring($repoRoot.Length).TrimStart('\', '/')
            throw "Sensitive content scan failed ($($pattern.Name)) in $rel"
        }
    }
}

if ($RequireEvidence) {
    $evidencePath = Join-Path $repoRoot "docs\uat\results\v$Version-release-uat.md"
    if (-not (Test-Path -LiteralPath $evidencePath)) {
        throw "Versioned release UAT evidence missing: $evidencePath"
    }
    $evidence = Get-Content -LiteralPath $evidencePath -Raw
    foreach ($requiredText in @('Overall: PASS', 'Tier B: PASS', 'Current host: PASS', 'Upgrade: PASS', 'Redaction review: PASS')) {
        if ($evidence -notmatch [regex]::Escape($requiredText)) {
            throw "Release evidence is missing '$requiredText'."
        }
    }
    $testedCommit = [regex]::Match($evidence, '(?m)^\s*(?:-\s*)?Tested source commit:\s*([A-Fa-f0-9]{40})\s*$')
    if (-not $testedCommit.Success) {
        throw 'Release evidence must contain a 40-character Tested source commit SHA.'
    }
    & git merge-base --is-ancestor $testedCommit.Groups[1].Value HEAD
    if ($LASTEXITCODE -ne 0) {
        throw "Tested source commit '$($testedCommit.Groups[1].Value)' is not an ancestor of the release commit."
    }
}

Write-Host "Release gate passed for v$Version."