# Dangerous Git Hook (Windows PowerShell)
# Blocks high-risk git operations unless PWSH_AI_ALLOW_DANGEROUS_GIT=1.
param()
$ErrorActionPreference = 'Stop'
$argv = @($args)
$text = ($argv -join ' ')
$patterns = @(
    'push\s+.*(--force|--force-with-lease|-f)\b',
    '\breset\s+--hard\b',
    '\bclean\s+-[a-zA-Z]*f',
    '\bcheckout\s+(--force|-f)\b',
    '\bcommit\s+.*--amend\b',
    '\brebase\s+(-i|--interactive)\b'
)
foreach ($p in $patterns) {
    if ($text -match $p) {
        if ($env:PWSH_AI_ALLOW_DANGEROUS_GIT -eq '1') {
            Write-Host "dangerous-git: allowing blocked pattern via PWSH_AI_ALLOW_DANGEROUS_GIT: $text"
            exit 0
        }
        Write-Error "dangerous-git: blocked potentially destructive git invocation: git $text"
        exit 1
    }
}
exit 0
