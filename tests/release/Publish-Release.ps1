#Requires -Version 7.0
<#
.SYNOPSIS
  One-click publish for stark-codex-windows-workbench.

.DESCRIPTION
  Merges the current release branch (or ensures master is current), waits for CI,
  then lets the Release workflow create the immutable tag and GitHub Release.
  Prefer: prepare version + UAT evidence, then run this script once.

.EXAMPLE
  pwsh -NoLogo -NoProfile -File .\tests\release\Publish-Release.ps1
.EXAMPLE
  pwsh -NoLogo -NoProfile -File .\tests\release\Publish-Release.ps1 -Version 0.1.2
#>
[CmdletBinding()]
param(
    [ValidatePattern('^$|^\d+\.\d+\.\d+$')]
    [string]$Version = '',
    [string]$PullRequest = '',
    [switch]$SkipLocalGate,
    [switch]$NoWait
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Step([string]$Message) {
    Write-Host ""
    Write-Host "==> $Message"
}

function Invoke-Gh([string[]]$Args) {
    & gh @Args
    if ($LASTEXITCODE -ne 0) {
        throw "gh $($Args -join ' ') failed with exit $LASTEXITCODE"
    }
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI (gh) is required for one-click publish.'
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git is required for one-click publish.'
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..') | Select-Object -ExpandProperty Path
Set-Location -LiteralPath $repoRoot

$package = Get-Content -LiteralPath (Join-Path $repoRoot 'package.json') -Raw | ConvertFrom-Json
if (-not $Version) { $Version = [string]$package.version }
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Version must be numeric X.Y.Z; got '$Version'."
}
if ($package.version -ne $Version) {
    throw "package.json version '$($package.version)' does not match requested '$Version'."
}

$tag = "v$Version"
Write-Step "One-click publish for $tag"

# Already published?
$existing = & git ls-remote --tags origin "refs/tags/$tag"
if ($LASTEXITCODE -eq 0 -and $existing) {
    Write-Host "Tag $tag already exists on origin. Nothing to publish."
    $rel = & gh release view $tag --json url --jq .url 2>$null
    if ($rel) { Write-Host "Release: $rel" }
    return
}

if (-not $SkipLocalGate) {
    Write-Step 'Running local release gate'
    & pwsh -NoLogo -NoProfile -File (Join-Path $repoRoot 'tests\release\Test-ReleaseGate.ps1') -Version $Version -RequireEvidence
    if ($LASTEXITCODE -ne 0) { throw 'Local release gate failed.' }
}

# Ensure changes are on origin. Prefer merging an open PR, else require master to already contain the version.
Write-Step 'Ensuring version is on origin/master'
& git fetch origin master --tags
if ($LASTEXITCODE -ne 0) { throw 'git fetch origin master failed.' }

$branch = (git branch --show-current).Trim()
$prNumber = $PullRequest
if (-not $prNumber -and $branch -and $branch -ne 'master') {
    $prNumber = (& gh pr list --head $branch --base master --state open --json number --jq '.[0].number' 2>$null)
}

if ($prNumber) {
    Write-Step "Merging PR #$prNumber into master"
    # Admin merge bypasses waiting on optional review when the actor has permission.
    # Still requires GitHub to accept the merge (checks may still apply unless admin).
    Invoke-Gh @('pr', 'merge', "$prNumber", '--merge', '--admin', '--delete-branch=false')
} else {
    $masterPackage = & git show origin/master:package.json | ConvertFrom-Json
    if ($masterPackage.version -ne $Version) {
        throw "origin/master package.json is '$($masterPackage.version)', not '$Version'. Push/merge the release branch first or pass -PullRequest."
    }
}

Write-Step 'Refreshing origin/master'
& git fetch origin master --tags
$masterSha = (git rev-parse origin/master).Trim()
Write-Host "origin/master = $masterSha"

# Wait for contract check on master tip when possible
if (-not $NoWait) {
    Write-Step 'Waiting for required CI check (contract) on master'
    $deadline = (Get-Date).AddMinutes(25)
    $green = $false
    while ((Get-Date) -lt $deadline) {
        $runs = & gh run list --branch master --workflow pwsh-agent-bootstrap.yml --limit 5 --json databaseId,headSha,conclusion,status | ConvertFrom-Json
        $match = @($runs | Where-Object { $_.headSha -eq $masterSha } | Select-Object -First 1)
        if ($match.Count -eq 0) {
            Write-Host 'No CI run for master tip yet...'
            Start-Sleep -Seconds 10
            continue
        }
        $run = $match[0]
        Write-Host "CI status=$($run.status) conclusion=$($run.conclusion)"
        if ($run.status -eq 'completed' -and $run.conclusion -eq 'success') {
            $green = $true
            break
        }
        if ($run.status -eq 'completed' -and $run.conclusion -ne 'success') {
            throw "Required CI failed on master ($($run.conclusion)). Inspect: gh run view $($run.databaseId)"
        }
        Start-Sleep -Seconds 15
    }
    if (-not $green) {
        Write-Host 'CI wait timed out; continuing because Release workflow re-validates gates.'
    }
}

Write-Step 'Dispatching Release workflow'
# Prefer auto path: empty version input lets workflow read package.json on master.
# Explicit version remains supported for manual re-runs.
Invoke-Gh @('workflow', 'run', 'Release', '--ref', 'master', '-f', "version=$Version")

if ($NoWait) {
    Write-Host 'Release workflow dispatched. Not waiting (-NoWait).'
    Write-Host 'Track with: gh run list --workflow Release --branch master --limit 3'
    return
}

Write-Step 'Waiting for Release workflow'
$deadline = (Get-Date).AddMinutes(35)
$runId = $null
while ((Get-Date) -lt $deadline) {
    $runs = & gh run list --workflow Release --branch master --limit 5 --json databaseId,status,conclusion,createdAt,displayTitle,headSha | ConvertFrom-Json
    $run = @($runs | Sort-Object createdAt -Descending | Select-Object -First 1)[0]
    if (-not $run) {
        Start-Sleep -Seconds 8
        continue
    }
    $runId = $run.databaseId
    Write-Host "Release run $runId status=$($run.status) conclusion=$($run.conclusion)"
    if ($run.status -eq 'completed') {
        if ($run.conclusion -ne 'success') {
            throw "Release workflow failed ($($run.conclusion)). Inspect: gh run view $runId --log-failed"
        }
        break
    }
    Start-Sleep -Seconds 12
}

# Verify tag/release
$existing = & git ls-remote --tags origin "refs/tags/$tag"
if (-not $existing) {
    throw "Release workflow finished but tag $tag is still missing on origin."
}
$url = & gh release view $tag --json url --jq .url
Write-Step "Published $tag"
Write-Host $url