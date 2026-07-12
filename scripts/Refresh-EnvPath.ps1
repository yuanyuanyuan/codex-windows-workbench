[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Get-EnvValue {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name
    )

    try {
        $value = Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction Stop
        if ($null -eq $value) { return '' }
        return [string]$value
    } catch {
        return ''
    }
}

$machineKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
$userKey = 'HKCU:\Environment'

$machinePath = Get-EnvValue -Path $machineKey -Name 'Path'
$userPath = Get-EnvValue -Path $userKey -Name 'Path'
$env:Path = (@($machinePath, $userPath) | Where-Object { $_ }) -join ';'

$machinePathext = Get-EnvValue -Path $machineKey -Name 'PATHEXT'
if ($machinePathext) {
    $env:PATHEXT = $machinePathext
}

$machinePsModulePath = Get-EnvValue -Path $machineKey -Name 'PSModulePath'
$userPsModulePath = Get-EnvValue -Path $userKey -Name 'PSModulePath'
$psModulePath = (@($machinePsModulePath, $userPsModulePath) | Where-Object { $_ }) -join ';'
if ($psModulePath) {
    $env:PSModulePath = $psModulePath
}

'Refreshed Path, PATHEXT, and PSModulePath from registry.'
