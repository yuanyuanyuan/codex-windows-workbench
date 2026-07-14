[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Deep
)

$ErrorActionPreference = 'Stop'

$required = @(
    'pwsh',
    'git',
    'git-lfs',
    'gh',
    'rg',
    'fd',
    'fzf',
    'jq',
    'bat',
    'delta',
    'node',
    'npm',
    'pnpm',
    'python',
    'uv',
    'docker',
    'kubectl',
    'winget',
    'scoop',
    'curl',
    'ssh'
)

$recommended = @(
    'go',
    'gofmt',
    'gopls',
    'dlv',
    'golangci-lint',
    'air',
    'cmake',
    'ninja',
    'msbuild',
    'nuget',
    'yq',
    'zip',
    '7z',
    'helm',
    'terraform'
)

function Get-CommandRow {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Tier
    )

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Name = $Name
        Tier = $Tier
        Status = if ($cmd) { 'OK' } else { 'MISSING' }
        Type = if ($cmd) { $cmd.CommandType.ToString() } else { '' }
        Source = if ($cmd) { $cmd.Source } else { '' }
    }
}

$commands = @()
$commands += foreach ($name in $required) { Get-CommandRow -Name $name -Tier 'required' }
$commands += foreach ($name in $recommended) { Get-CommandRow -Name $name -Tier 'recommended' }

function Get-RedactedProxyHint {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    try {
        $uri = [Uri]$Value
        if ($uri.IsAbsoluteUri) {
            return '{0}://{1}:{2}' -f $uri.Scheme, $uri.Host, $uri.Port
        }
    } catch {
        # Fall through to generic redaction.
    }
    $redacted = $Value -replace '://[^@/]+@', '://***@'
    $redacted = $redacted -replace '([?&](token|key|password|secret)=)[^&]+', '$1***'
    if ($redacted.Length -gt 80) { $redacted = $redacted.Substring(0, 80) + '...' }
    return $redacted
}

$envChecks = [pscustomobject]@{
    PSVersion = $PSVersionTable.PSVersion.ToString()
    OutputRendering = if ($PSStyle) { $PSStyle.OutputRendering.ToString() } else { 'n/a' }
    ConsoleOutputEncoding = [Console]::OutputEncoding.WebName
    ConsoleInputEncoding = [Console]::InputEncoding.WebName
    PythonIOEncoding = $env:PYTHONIOENCODING
    PythonUTF8 = $env:PYTHONUTF8
    HTTP_PROXY = Get-RedactedProxyHint -Value $env:HTTP_PROXY
    HTTPS_PROXY = Get-RedactedProxyHint -Value $env:HTTPS_PROXY
    ALL_PROXY = Get-RedactedProxyHint -Value $env:ALL_PROXY
    NO_PROXY = $env:NO_PROXY
    GOPATH = $env:GOPATH
    GOPROXY = $env:GOPROXY
    GOSUMDB = $env:GOSUMDB
}

$pathWarnings = @()
$sevenZip = Get-Command 7z -ErrorAction SilentlyContinue
if ($sevenZip) {
    $preferred = @(
        (Join-Path $env:USERPROFILE 'scoop\shims'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links'),
        (Join-Path $env:USERPROFILE '.local\bin')
    )
    $sourceDir = Split-Path -Parent $sevenZip.Source
    $isPreferred = $preferred | Where-Object {
        [string]::Equals($_.TrimEnd('\'), $sourceDir.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)
    }
    if (-not $isPreferred) {
        $pathWarnings += "7z resolves outside preferred package-manager paths: $($sevenZip.Source)"
    }
}

if (-not (Get-Command rsync -ErrorAction SilentlyContinue)) {
    $pathWarnings += 'rsync is not installed. Windows does not have a first-party rsync; prefer robocopy/rclone unless a project explicitly requires rsync.'
}

$missingRequired = @($commands | Where-Object { $_.Tier -eq 'required' -and $_.Status -ne 'OK' })
$missingRecommended = @($commands | Where-Object { $_.Tier -eq 'recommended' -and $_.Status -ne 'OK' })

$result = [pscustomobject]@{
    Summary = [pscustomobject]@{
        RequiredMissing = $missingRequired.Count
        RecommendedMissing = $missingRecommended.Count
        PathWarnings = $pathWarnings.Count
    }
    Environment = $envChecks
    Commands = $commands
    Warnings = $pathWarnings
    RuntimeChecks = @()
}

if ($Deep) {
    $runtimeChecks = [System.Collections.Generic.List[object]]::new()

    function Add-RuntimeCheck {
        param(
            [Parameter(Mandatory=$true)][string]$Name,
            [Parameter(Mandatory=$true)][scriptblock]$ScriptBlock,
            [switch]$Optional
        )

        $status = 'OK'
        $detail = ''
        try {
            $output = & $ScriptBlock 2>&1
            if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
                $status = if ($Optional) { 'WARN' } else { 'FAIL' }
                $detail = "exit=$LASTEXITCODE; $($output -join ' ')"
            } else {
                $detail = ($output | Select-Object -First 3) -join ' '
            }
        } catch {
            $status = if ($Optional) { 'WARN' } else { 'FAIL' }
            $detail = $_.Exception.Message
        } finally {
            $global:LASTEXITCODE = 0
        }

        $runtimeChecks.Add([pscustomobject]@{
            Name = $Name
            Status = $status
            Optional = [bool]$Optional
            Detail = $detail
        })
    }

    Add-RuntimeCheck -Name 'node-eval' -ScriptBlock {
        node -e "console.log('node-ok')"
    }

    Add-RuntimeCheck -Name 'node-version-24.18.0' -Optional -ScriptBlock {
        $v = (node -v 2>&1 | Out-String).Trim()
        if ($v -notmatch 'v?24\.18\.0') { throw "Expected Node 24.18.0, got $v" }
        $v
    }

    Add-RuntimeCheck -Name 'codex-path-resolution' -Optional -ScriptBlock {
        $cmd = Get-Command codex -ErrorAction SilentlyContinue
        if (-not $cmd) { throw 'codex command not found' }
        $sourceDir = Split-Path -Parent $cmd.Source
        if ($sourceDir -like '*WindowsApps*') {
            throw "codex resolves via WindowsApps internal path: $($cmd.Source)"
        }
        "codex=>$($cmd.Source)"
    }

    Add-RuntimeCheck -Name 'fnm-available' -Optional -ScriptBlock {
        fnm --version
    }

    Add-RuntimeCheck -Name 'python-eval' -ScriptBlock {
        python -c "print('python-ok')"
    }

    Add-RuntimeCheck -Name 'go-run' -Optional -ScriptBlock {
        $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("pwsh-agent-go-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $dir | Out-Null
        try {
            $file = Join-Path $dir 'main.go'
            Set-Content -LiteralPath $file -Encoding utf8 -Value 'package main
import "fmt"
func main() { fmt.Println("go-ok") }
'
            go run $file
        } finally {
            Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Add-RuntimeCheck -Name 'uv-version' -ScriptBlock {
        uv --version
    }

    Add-RuntimeCheck -Name 'docker-client-server' -Optional -ScriptBlock {
        if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
            throw 'docker command not found'
        }
        $job = Start-Job {
            docker version --format '{{.Client.Version}} {{.Server.Version}}' 2>&1 | Out-String
        }
        if (-not (Wait-Job $job -Timeout 8)) {
            Stop-Job $job -Force -ErrorAction SilentlyContinue
            Remove-Job $job -Force -ErrorAction SilentlyContinue
            throw 'docker version timed out (daemon may be unavailable)'
        }
        $output = Receive-Job $job
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        if (-not $output) { throw 'docker version returned empty output' }
        $output.Trim()
    }

    $result.RuntimeChecks = @($runtimeChecks)
    $runtimeFailures = @($runtimeChecks | Where-Object { $_.Status -eq 'FAIL' })
    $result.Summary | Add-Member -NotePropertyName RuntimeFailures -NotePropertyValue $runtimeFailures.Count
}

if ($Json) {
    $result | ConvertTo-Json -Depth 5
    if ($missingRequired.Count -gt 0) { exit 1 }
    if ($Deep -and ($result.Summary.PSObject.Properties.Name -contains 'RuntimeFailures') -and $result.Summary.RuntimeFailures -gt 0) { exit 1 }
    return
}

'Environment'
$envChecks | Format-List

'Commands'
$commands | Sort-Object Tier, Name | Format-Table -AutoSize

if ($pathWarnings.Count -gt 0) {
    'Warnings'
    $pathWarnings | ForEach-Object { "- $_" }
}

if ($Deep) {
    'Runtime Checks'
    $result.RuntimeChecks | Format-Table -AutoSize
}

'Summary'
$result.Summary | Format-List

if ($missingRequired.Count -gt 0) { exit 1 }
if ($Deep -and $result.Summary.RuntimeFailures -gt 0) { exit 1 }
