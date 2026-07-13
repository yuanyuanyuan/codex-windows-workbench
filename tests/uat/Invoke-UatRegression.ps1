#Requires -Version 7.0
<#
.SYNOPSIS
  Mandatory UAT regression suite for stark-codex-windows-workbench.

.DESCRIPTION
  Tier A (default): package layout, identity, install product completeness simulation,
  runtime WhatIf from packaged path, contracts, docs/path checks.
  Tier B (-IncludeNetwork): optional npx discovery/install completeness probes.

  Exit 0 only when all selected cases pass.
#>
[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$IncludeNetwork,
    [string]$SkillName = 'stark-codex-windows-workbench'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function New-CaseResult {
    param(
        [string]$Id,
        [string]$Title,
        [string]$Tier,
        [bool]$Passed,
        [string]$Message = ''
    )
    [pscustomobject]@{
        Id      = $Id
        Title   = $Title
        Tier    = $Tier
        Passed  = $Passed
        Message = $Message
    }
}

function Write-CaseHost {
    param($Case)
    $mark = if ($Case.Passed) { 'PASS' } else { 'FAIL' }
    $color = if ($Case.Passed) { 'Green' } else { 'Red' }
    $line = '[{0}] {1} {2}' -f [string]$mark, [string]$Case.Id, [string]$Case.Title
    Write-Host $line -ForegroundColor $color
    if (-not [string]::IsNullOrWhiteSpace([string]$Case.Message)) {
        Write-Host ('       {0}' -f [string]$Case.Message)
    }
}

function Get-JsonObjectFromText {
    param([string]$Text)

    $preferredModes = @('WhatIf', 'Status', 'Apply', 'Verify', 'Rollback', 'PreflightFailed')
    $candidates = New-Object System.Collections.Generic.List[int]
    for ($i = 0; $i -lt $Text.Length; $i++) {
        if ($Text[$i] -eq '{') { $candidates.Add($i) | Out-Null }
    }

    $parsed = New-Object System.Collections.Generic.List[object]
    foreach ($startIdx in $candidates) {
        $slice = $Text.Substring($startIdx)
        if ($slice -notmatch '"Mode"\s*:') { continue }

        $depth = 0
        $end = -1
        $inString = $false
        $escape = $false
        for ($i = 0; $i -lt $slice.Length; $i++) {
            $ch = $slice[$i]
            if ($inString) {
                if ($escape) { $escape = $false; continue }
                if ($ch -eq '\') { $escape = $true; continue }
                if ($ch -eq '"') { $inString = $false }
                continue
            }
            switch ($ch) {
                '"' { $inString = $true }
                '{' { $depth++ }
                '}' {
                    $depth--
                    if ($depth -eq 0) { $end = $i; break }
                }
            }
            if ($end -ge 0) { break }
        }
        if ($end -lt 0) { continue }

        $json = $slice.Substring(0, $end + 1)
        try {
            $obj = $json | ConvertFrom-Json
            if ($obj.PSObject.Properties.Name -contains 'Mode') {
                $parsed.Add([pscustomobject]@{
                        Start  = $startIdx
                        Mode   = [string]$obj.Mode
                        Object = $obj
                    }) | Out-Null
            }
        } catch {
            continue
        }
    }

    if ($parsed.Count -eq 0) {
        throw "No JSON report object with Mode found.`n$Text"
    }

    $preferred = @($parsed | Where-Object { $preferredModes -contains $_.Mode } | Sort-Object Start -Descending)
    if ($preferred.Count -gt 0) {
        return $preferred[0].Object
    }
    return ($parsed | Sort-Object Start -Descending | Select-Object -First 1).Object
}

function Test-RequiredSkillFiles {
    param([string]$Root)
    $required = @(
        'SKILL.md',
        'scripts/Initialize-PwshAgentWindows.ps1',
        'scripts/Private/PwshAiAgent.Phases.ps1',
        'scripts/Private/PwshAiAgent.State.ps1',
        'config/windows-agent-core.winget',
        'agents/openai.yaml'
    )
    $missing = @()
    foreach ($rel in $required) {
        $path = Join-Path $Root ($rel -replace '/', [IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $path)) {
            $missing += $rel
        }
    }
    return [pscustomobject]@{
        Required = $required
        Missing  = $missing
        Ok       = ($missing.Count -eq 0)
    }
}

function Get-FrontMatterName {
    param([string]$SkillMdPath)
    $raw = Get-Content -LiteralPath $SkillMdPath -Raw
    if ($raw -match '(?ms)\A---\s*.*?\bname\s*:\s*([^\r\n#]+).*?---') {
        return $Matches[1].Trim().Trim('"').Trim("'")
    }
    return $null
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..') | Select-Object -ExpandProperty Path
$skillRoot = Join-Path $repoRoot "skills\$SkillName"
$scriptsRoot = Join-Path $skillRoot 'scripts'
$entryPoint = Join-Path $scriptsRoot 'Initialize-PwshAgentWindows.ps1'
$results = New-Object System.Collections.Generic.List[object]

Write-Host '======== UAT Regression ========'
Write-Host "Repo: $repoRoot"
Write-Host "Skill package: $skillRoot"
Write-Host ("Network cases: {0}" -f ($(if ($IncludeNetwork) { 'enabled' } else { 'disabled' })))
Write-Host ''

# UAT-001 Package layout
try {
    $hasSkillMd = Test-Path -LiteralPath (Join-Path $skillRoot 'SKILL.md')
    $rootSkillMd = Test-Path -LiteralPath (Join-Path $repoRoot 'SKILL.md')
    $dirsOk = (@('scripts', 'config', 'agents', 'references') | ForEach-Object {
            Test-Path -LiteralPath (Join-Path $skillRoot $_)
        }) -notcontains $false
    if (-not $hasSkillMd) { throw "Missing skills/$SkillName/SKILL.md" }
    if ($rootSkillMd) { throw 'Root-level SKILL.md must not be packaging source of truth' }
    if (-not $dirsOk) { throw 'Skill package missing one of scripts/config/agents/references' }
    $results.Add((New-CaseResult -Id 'UAT-001' -Title 'Package layout' -Tier 'A' -Passed $true -Message "skills/$SkillName layout OK")) | Out-Null
} catch {
    $results.Add((New-CaseResult -Id 'UAT-001' -Title 'Package layout' -Tier 'A' -Passed $false -Message "$_")) | Out-Null
}

# UAT-002 Identity consistency
try {
    $expected = $SkillName
    $skillName = Get-FrontMatterName -SkillMdPath (Join-Path $skillRoot 'SKILL.md')
    if ($skillName -ne $expected) { throw "SKILL.md name='$skillName' expected='$expected'" }

    $pkg = Get-Content -LiteralPath (Join-Path $repoRoot 'package.json') -Raw | ConvertFrom-Json
    if ($pkg.name -ne $expected) { throw "package.json name='$($pkg.name)' expected='$expected'" }

    $codexPlugin = Get-Content -LiteralPath (Join-Path $repoRoot '.codex-plugin\plugin.json') -Raw | ConvertFrom-Json
    if ($codexPlugin.name -ne $expected) { throw ".codex-plugin name='$($codexPlugin.name)' expected='$expected'" }


    $results.Add((New-CaseResult -Id 'UAT-002' -Title 'Identity consistency' -Tier 'A' -Passed $true -Message "identity=$expected")) | Out-Null
} catch {
    $results.Add((New-CaseResult -Id 'UAT-002' -Title 'Identity consistency' -Tier 'A' -Passed $false -Message "$_")) | Out-Null
}

# UAT-003 Required package files
try {
    $check = Test-RequiredSkillFiles -Root $skillRoot
    if (-not $check.Ok) { throw ("Missing: {0}" -f ($check.Missing -join ', ')) }
    $results.Add((New-CaseResult -Id 'UAT-003' -Title 'Required package files' -Tier 'A' -Passed $true -Message ("{0} required files present" -f $check.Required.Count))) | Out-Null
} catch {
    $results.Add((New-CaseResult -Id 'UAT-003' -Title 'Required package files' -Tier 'A' -Passed $false -Message "$_")) | Out-Null
}

# UAT-004 Simulated install product completeness
$simRoot = $null
try {
    $simRoot = Join-Path ([IO.Path]::GetTempPath()) ("uat-skill-install-" + [guid]::NewGuid().ToString('N'))
    $simSkill = Join-Path $simRoot $SkillName
    New-Item -ItemType Directory -Force -Path $simSkill | Out-Null
    Copy-Item -Path (Join-Path $skillRoot '*') -Destination $simSkill -Recurse -Force
    $check = Test-RequiredSkillFiles -Root $simSkill
    if (-not $check.Ok) { throw ("Simulated install missing: {0}" -f ($check.Missing -join ', ')) }
    $fileCount = @(Get-ChildItem -LiteralPath $simSkill -Recurse -File).Count
    if ($fileCount -le 1) { throw "Simulated install fileCount=$fileCount (only SKILL.md class failure)" }
    $results.Add((New-CaseResult -Id 'UAT-004' -Title 'Simulated install product completeness' -Tier 'A' -Passed $true -Message "files=$fileCount")) | Out-Null
} catch {
    $results.Add((New-CaseResult -Id 'UAT-004' -Title 'Simulated install product completeness' -Tier 'A' -Passed $false -Message "$_")) | Out-Null
} finally {
    if ($simRoot -and (Test-Path -LiteralPath $simRoot)) {
        Remove-Item -LiteralPath $simRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Shared WhatIf report for later cases
$whatIfReport = $null
$fullReport = $null

# UAT-005 Runtime from packaged path
try {
    if (-not (Test-Path -LiteralPath $entryPoint)) { throw "Entry missing: $entryPoint" }
    $env:PWSH_AI_AGENT_SKIP_WINGET_PREFLIGHT = '1'
    $raw = & pwsh -NoLogo -NoProfile -File $entryPoint -WhatIf -Json 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "WhatIf exit=$LASTEXITCODE`n$raw" }
    $whatIfReport = Get-JsonObjectFromText -Text $raw
    if ($whatIfReport.Mode -ne 'WhatIf') { throw "Mode=$($whatIfReport.Mode)" }
    $results.Add((New-CaseResult -Id 'UAT-005' -Title 'Runtime from packaged path' -Tier 'A' -Passed $true -Message "entry=$entryPoint")) | Out-Null
} catch {
    $results.Add((New-CaseResult -Id 'UAT-005' -Title 'Runtime from packaged path' -Tier 'A' -Passed $false -Message "$_")) | Out-Null
}

# UAT-006 Default Core+Agent plan
try {
    if ($null -eq $whatIfReport) { throw 'No WhatIf report from UAT-005' }
    $selected = @($whatIfReport.Selected)
    if ($selected -notcontains 'Core' -or $selected -notcontains 'Agent') {
        throw "Selected missing Core/Agent: $($selected -join ',')"
    }
    $unexpected = @($selected | Where-Object { $_ -notin @('Core', 'Agent') })
    if ($unexpected.Count -gt 0) {
        throw "Default selected unexpected: $($unexpected -join ',')"
    }
    if ($whatIfReport.Changed -ne $false) { throw 'WhatIf Changed must be false' }
    $notSelected = @($whatIfReport.Phases | Where-Object Status -eq 'NotSelected' | ForEach-Object Name)
    foreach ($name in @('AgentClients', 'Developer', 'NativeBuild', 'Containers')) {
        if ($notSelected -notcontains $name) { throw "$name not marked NotSelected" }
    }
    $results.Add((New-CaseResult -Id 'UAT-006' -Title 'Default Core+Agent plan' -Tier 'A' -Passed $true -Message 'Selected=Core,Agent')) | Out-Null
} catch {
    $results.Add((New-CaseResult -Id 'UAT-006' -Title 'Default Core+Agent plan' -Tier 'A' -Passed $false -Message "$_")) | Out-Null
}

# UAT-007 No WSL-like actions
try {
    if ($null -eq $whatIfReport) { throw 'No WhatIf report from UAT-005' }
    $env:PWSH_AI_AGENT_SKIP_WINGET_PREFLIGHT = '1'
    $fullRaw = & pwsh -NoLogo -NoProfile -File $entryPoint -Full -WhatIf -Json 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "Full WhatIf exit=$LASTEXITCODE`n$fullRaw" }
    $fullReport = Get-JsonObjectFromText -Text $fullRaw
    $badDefault = @($whatIfReport.Actions | Where-Object {
            $_.Action -match '(?i)WSL|bash|Linux|apt|brew' -or $_.Target -match '(?i)WSL|bash|Linux|apt|brew'
        })
    $badFull = @($fullReport.Actions | Where-Object {
            $_.Action -match '(?i)WSL|bash|Linux|apt|brew' -or $_.Target -match '(?i)WSL|bash|Linux|apt|brew'
        })
    if ($badDefault.Count -gt 0 -or $badFull.Count -gt 0) {
        throw "WSL-like actions found default=$($badDefault.Count) full=$($badFull.Count)"
    }
    $results.Add((New-CaseResult -Id 'UAT-007' -Title 'No WSL-like actions' -Tier 'A' -Passed $true -Message 'default+full clean')) | Out-Null
} catch {
    $results.Add((New-CaseResult -Id 'UAT-007' -Title 'No WSL-like actions' -Tier 'A' -Passed $false -Message "$_")) | Out-Null
}

# UAT-008 Summary/Impact readability
try {
    if ($null -eq $whatIfReport) { throw 'No WhatIf report from UAT-005' }
    if (-not ($whatIfReport.PSObject.Properties.Name -contains 'Summary') -or @($whatIfReport.Summary).Count -eq 0) {
        throw 'Summary missing/empty'
    }
    if (-not ($whatIfReport.PSObject.Properties.Name -contains 'Impact') -or $null -eq $whatIfReport.Impact) {
        throw 'Impact missing'
    }
    $summaryText = @($whatIfReport.Summary) -join "`n"
    if ($summaryText -notmatch 'Will NOT do by default|NotSelected|winget|scoop') {
        throw 'Summary lacks readable install/non-action cues'
    }
    $results.Add((New-CaseResult -Id 'UAT-008' -Title 'Summary/Impact readability' -Tier 'A' -Passed $true -Message ("summaryLines={0}" -f @($whatIfReport.Summary).Count))) | Out-Null
} catch {
    $results.Add((New-CaseResult -Id 'UAT-008' -Title 'Summary/Impact readability' -Tier 'A' -Passed $false -Message "$_")) | Out-Null
}

# UAT-009 Contract unit tests
try {
    $env:PWSH_AI_AGENT_SKIP_WINGET_PREFLIGHT = '1'
    $contract1 = Join-Path $scriptsRoot 'Test-InitializePwshAgentWindows.ps1'
    $contract2 = Join-Path $scriptsRoot 'Test-AgentClients.ps1'
    $out1 = & pwsh -NoLogo -NoProfile -File $contract1 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "Test-Initialize failed: $out1" }
    $out2 = & pwsh -NoLogo -NoProfile -File $contract2 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "Test-AgentClients failed: $out2" }
    $results.Add((New-CaseResult -Id 'UAT-009' -Title 'Contract unit tests' -Tier 'A' -Passed $true -Message 'Initialize+AgentClients passed')) | Out-Null
} catch {
    $results.Add((New-CaseResult -Id 'UAT-009' -Title 'Contract unit tests' -Tier 'A' -Passed $false -Message "$_")) | Out-Null
}

# UAT-010 Docs/install path correctness
try {
    $docs = @(
        (Join-Path $repoRoot 'docs\install.md'),
        (Join-Path $repoRoot 'README.md'),
        (Join-Path $repoRoot 'README.zh-CN.md')
    )
    foreach ($d in $docs) {
        if (-not (Test-Path -LiteralPath $d)) { throw "Missing doc: $d" }
        $text = Get-Content -LiteralPath $d -Raw
        if ($text -notmatch [regex]::Escape("skills/$SkillName") -and $text -notmatch [regex]::Escape("skills\$SkillName")) {
            throw "$(Split-Path $d -Leaf) missing skills/$SkillName path"
        }
        if ($text -notmatch 'npx(?:\s+--yes)?\s+skills\s+add') {
            throw "$(Split-Path $d -Leaf) missing npx skills add guidance"
        }
    }
    $installText = Get-Content -LiteralPath (Join-Path $repoRoot 'docs\install.md') -Raw
    if ($installText -notmatch [regex]::Escape("skills/$SkillName") ) {
        throw 'docs/install.md must document skill-folder package path'
    }
    $results.Add((New-CaseResult -Id 'UAT-010' -Title 'Docs/install path correctness' -Tier 'A' -Passed $true -Message 'README + install.md OK')) | Out-Null
} catch {
    $results.Add((New-CaseResult -Id 'UAT-010' -Title 'Docs/install path correctness' -Tier 'A' -Passed $false -Message "$_")) | Out-Null
}

# UAT-011 No chat /plugin install path
try {
    $scanFiles = @(
        (Join-Path $repoRoot 'README.md'),
        (Join-Path $repoRoot 'README.zh-CN.md'),
        (Join-Path $repoRoot 'docs\install.md')
    )
    $bad = @()
    foreach ($f in $scanFiles) {
        $lines = Get-Content -LiteralPath $f
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            # Invalid chat slash form: starts with /plugin (not codex plugin)
            if ($line -match '(?m)^\s*/plugin\b' -or $line -match '(?<!codex\s)/plugin\s+(marketplace|install|add)\b') {
                # allow mentions in "do not use" / error explanations
                if ($line -match '(?i)do not|不要|invalid|unrecognized|rejected|错误|禁止') { continue }
                $bad += ("{0}:{1}:{2}" -f (Split-Path $f -Leaf), ($i + 1), $line.Trim())
            }
        }
    }
    if ($bad.Count -gt 0) {
        throw ("Invalid chat /plugin docs remain:`n{0}" -f ($bad -join "`n"))
    }
    $results.Add((New-CaseResult -Id 'UAT-011' -Title 'No chat /plugin install path' -Tier 'A' -Passed $true -Message 'no invalid chat /plugin install commands')) | Out-Null
} catch {
    $results.Add((New-CaseResult -Id 'UAT-011' -Title 'No chat /plugin install path' -Tier 'A' -Passed $false -Message "$_")) | Out-Null
}

if ($IncludeNetwork) {
    # UAT-012 npx discovery
    try {
        Push-Location $repoRoot
        $listOut = & npx --yes skills add . --list -y 2>&1 | Out-String
        if ($listOut -notmatch [regex]::Escape($SkillName)) {
            throw "Skill not discovered by npx skills.`n$listOut"
        }
        $results.Add((New-CaseResult -Id 'UAT-012' -Title 'npx discovery' -Tier 'B' -Passed $true -Message 'Found skill via npx skills --list')) | Out-Null
    } catch {
        $results.Add((New-CaseResult -Id 'UAT-012' -Title 'npx discovery' -Tier 'B' -Passed $false -Message "$_")) | Out-Null
    } finally {
        Pop-Location
    }

    # UAT-013 npx install completeness
    $netRoot = $null
    try {
        $netRoot = Join-Path ([IO.Path]::GetTempPath()) ("uat-npx-install-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Force -Path $netRoot | Out-Null
        Push-Location $netRoot
        # Project-scope local source install into temp workspace.
        $installOut = & npx --yes skills add $repoRoot -a codex --copy -y 2>&1 | Out-String
        $candidates = @(
            (Join-Path $netRoot ".agents\skills\$SkillName"),
            (Join-Path $netRoot ".codex\skills\$SkillName")
        )
        $installed = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if (-not $installed) {
            throw "Installed skill dir not found after npx add.`n$installOut"
        }
        $check = Test-RequiredSkillFiles -Root $installed
        if (-not $check.Ok) {
            throw ("Installed product incomplete at $installed ; missing: {0}`n{1}" -f ($check.Missing -join ', '), $installOut)
        }
        $fileCount = @(Get-ChildItem -LiteralPath $installed -Recurse -File).Count
        if ($fileCount -le 1) { throw "Installed only $fileCount file(s) under $installed" }
        $results.Add((New-CaseResult -Id 'UAT-013' -Title 'npx install completeness' -Tier 'B' -Passed $true -Message "installed=$installed files=$fileCount")) | Out-Null
    } catch {
        $results.Add((New-CaseResult -Id 'UAT-013' -Title 'npx install completeness' -Tier 'B' -Passed $false -Message "$_")) | Out-Null
    } finally {
        Pop-Location -ErrorAction SilentlyContinue
        if ($netRoot -and (Test-Path -LiteralPath $netRoot)) {
            Remove-Item -LiteralPath $netRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host ''
foreach ($case in $results) { Write-CaseHost -Case $case }

$failed = @($results | Where-Object { -not $_.Passed })
$passed = @($results | Where-Object { $_.Passed })
$caseRows = @(
    foreach ($c in $results) {
        [pscustomobject]@{
            Id      = [string]$c.Id
            Title   = [string]$c.Title
            Tier    = [string]$c.Tier
            Passed  = [bool]$c.Passed
            Message = [string]$c.Message
        }
    }
)
$summary = [pscustomobject]@{
    Suite          = 'stark-codex-windows-workbench-uat-regression'
    Skill          = [string]$SkillName
    RepoRoot       = [string]$repoRoot
    SkillRoot      = [string]$skillRoot
    IncludeNetwork = [bool]$IncludeNetwork
    Total          = [int]$results.Count
    Passed         = [int]$passed.Count
    Failed         = [int]$failed.Count
    Cases          = $caseRows
    Overall        = $(if ($failed.Count -eq 0) { 'PASS' } else { 'FAIL' })
}

Write-Host ''
Write-Host '======== UAT Summary ========'
Write-Host ("Overall: {0}" -f $summary.Overall)
Write-Host ("Passed: {0}/{1}" -f $summary.Passed, $summary.Total)
if ($failed.Count -gt 0) {
    Write-Host 'Failed cases:'
    foreach ($f in $failed) {
        Write-Host (" - {0}: {1}" -f $f.Id, $f.Message)
    }
}

if ($Json) {
    $summary | ConvertTo-Json -Depth 8
}

if ($failed.Count -gt 0) {
    exit 1
}
exit 0

