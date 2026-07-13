# State helpers for the Windows PowerShell 7 AI Agent workbench.
# Dot-sourced by Initialize-PwshAgentWindows.ps1 only.

function ConvertTo-PlainObject {
    param([Parameter(Mandatory = $true)]$InputObject)
    if ($InputObject -is [System.Collections.IDictionary]) {
        $result = [ordered]@{}
        foreach ($key in $InputObject.Keys) {
            $result[$key] = ConvertTo-PlainObject $InputObject[$key]
        }
        return [pscustomobject]$result
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        return @($InputObject | ForEach-Object { ConvertTo-PlainObject $_ })
    }
    return $InputObject
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Value
    )
    $temp = "$Path.tmp-$([guid]::NewGuid().ToString('N'))"
    $json = (ConvertTo-PlainObject $Value | ConvertTo-Json -Depth 12)
    [System.IO.File]::WriteAllText($temp, $json, [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temp -Destination $Path -Force
}

function Read-JsonFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Ensure-StateDirectories {
    New-Item -ItemType Directory -Force -Path $stateRoot, $backupRoot, $logRoot | Out-Null
}

function Get-SentinelPath {
    param([Parameter(Mandatory = $true)][string]$Name)
    return Join-Path $stateRoot "phase-$($Name.ToLowerInvariant()).json"
}

function Get-PhaseStatus {
    param([Parameter(Mandatory = $true)][string]$Name)
    $path = Get-SentinelPath $Name
    $sentinel = Read-JsonFile $path
    if ($sentinel -and $sentinel.Version -eq $sentinelVersion -and $sentinel.Status -eq 'Complete') {
        return [pscustomobject]@{
            Name      = $Name
            Status    = 'Complete'
            UpdatedAt = $sentinel.UpdatedAt
            Sentinel  = $path
        }
    }
    return [pscustomobject]@{
        Name      = $Name
        Status    = 'Pending'
        UpdatedAt = $null
        Sentinel  = $path
    }
}

function Complete-Phase {
    param([Parameter(Mandatory = $true)][string]$Name)
    Ensure-StateDirectories
    $sentinel = [ordered]@{
        Version   = $sentinelVersion
        Status    = 'Complete'
        Phase     = $Name
        UpdatedAt = (Get-Date).ToUniversalTime().ToString('o')
    }
    Write-JsonFile -Path (Get-SentinelPath $Name) -Value $sentinel
}

function Get-ManagedFileBackupName {
    param([Parameter(Mandatory = $true)][string]$Path)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Path)
    return ([Convert]::ToBase64String($bytes) -replace '[=+/]', '_')
}

function Backup-ManagedFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    Ensure-StateDirectories
    $backup = Join-Path $backupRoot (Get-ManagedFileBackupName $Path)
    $entry = [ordered]@{
        Path     = $Path
        Existed  = (Test-Path -LiteralPath $Path)
        Backup   = $backup
        PostHash = $null
    }
    if ($entry.Existed) {
        Copy-Item -LiteralPath $Path -Destination $backup -Force
    }
    return [pscustomobject]$entry
}

function Get-RegistryValueState {
    param([Parameter(Mandatory = $true)][string]$Name)
    $path = 'HKCU:\Environment'
    try {
        return [pscustomobject]@{
            Name    = $Name
            Existed = $true
            Value   = (Get-ItemPropertyValue -Path $path -Name $Name -ErrorAction Stop)
        }
    } catch {
        return [pscustomobject]@{
            Name    = $Name
            Existed = $false
            Value   = $null
        }
    }
}

function Write-ManagedManifest {
    param([Parameter(Mandatory = $true)]$Manifest)
    Ensure-StateDirectories
    Write-JsonFile -Path (Join-Path $stateRoot 'manifest.json') -Value $Manifest
}

function Read-ManagedManifest {
    return Read-JsonFile (Join-Path $stateRoot 'manifest.json')
}
