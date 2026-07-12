[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Assert-True {
    param(
        [Parameter(Mandatory=$true)][bool]$Condition,
        [Parameter(Mandatory=$true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$entryPoint = Join-Path $PSScriptRoot 'Initialize-PwshAgentWindows.ps1'
Assert-True -Condition (Test-Path -LiteralPath $entryPoint) -Message "Entry point not found: $entryPoint"
$entrySource = Get-Content -LiteralPath $entryPoint -Raw
Assert-True -Condition ($entrySource -match '(?s)function\s+Invoke-Phase\s*\{\s*\[CmdletBinding\([^]]*SupportsShouldProcess=\$true') -Message 'Invoke-Phase must declare ShouldProcess before calling $PSCmdlet.ShouldProcess.'

$statusJson = & pwsh -NoLogo -NoProfile -File $entryPoint -Status -Json
Assert-True -Condition ($LASTEXITCODE -eq 0) -Message "-Status failed with exit code $LASTEXITCODE"
$status = $statusJson | ConvertFrom-Json
Assert-True -Condition ($status.Mode -eq 'Status') -Message 'Status report has the wrong mode.'
Assert-True -Condition (@($status.Phases | Where-Object Name -eq 'Core').Count -eq 1) -Message 'Core phase is missing.'
Assert-True -Condition (@($status.Phases | Where-Object Name -eq 'Agent').Count -eq 1) -Message 'Agent phase is missing.'
Assert-True -Condition (@($status.Phases | Where-Object { $_.Name -match 'WSL|Bash|Linux' }).Count -eq 0) -Message 'WSL/Linux compatibility work appeared in the plan.'

$whatIfJson = & pwsh -NoLogo -NoProfile -File $entryPoint -WhatIf -Json
Assert-True -Condition ($LASTEXITCODE -eq 0) -Message "-WhatIf failed with exit code $LASTEXITCODE"
$whatIf = $whatIfJson | ConvertFrom-Json
Assert-True -Condition ($whatIf.Mode -eq 'WhatIf') -Message 'WhatIf report has the wrong mode.'
Assert-True -Condition ($whatIf.Changed -eq $false) -Message 'WhatIf reported machine changes.'
Assert-True -Condition (@($whatIf.Actions | Where-Object { $_.Action -match 'WSL|bash|Linux' }).Count -eq 0) -Message 'WhatIf planned a WSL/Linux action.'

'Initialize-PwshAgentWindows tests passed.'
