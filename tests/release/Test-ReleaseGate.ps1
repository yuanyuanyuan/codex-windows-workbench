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
    $testedCommit = [regex]::Match($evidence, '(?m)^Tested source commit:\s*([A-Fa-f0-9]{40})\s*$')
    if (-not $testedCommit.Success) {
        throw 'Release evidence must contain a 40-character Tested source commit SHA.'
    }
    & git merge-base --is-ancestor $testedCommit.Groups[1].Value HEAD
    if ($LASTEXITCODE -ne 0) {
        throw "Tested source commit '$($testedCommit.Groups[1].Value)' is not an ancestor of the release commit."
    }
}

Write-Host "Release gate passed for v$Version."
