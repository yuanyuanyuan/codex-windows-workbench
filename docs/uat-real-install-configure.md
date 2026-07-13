# UAT: Real Install And Configure Process

Date: 2026-07-13  
Skill: `codex-windows-workbench`  
Host: native Windows + PowerShell 7.5.8  
Repo: `yuanyuanyuan/codex-windows-workbench`

## Goal

Prove the public skill can be:

1. discovered
2. installed into a user skill directory
3. previewed safely
4. configured through the managed Core + Agent path
5. verified with machine-readable JSON

## What was executed for real in this UAT pass

### 1) Host precheck

```powershell
$PSVersionTable.PSVersion
$IsWindows
Get-Command winget,npx,git,pwsh
```

Observed:

```text
PowerShell: 7.5.8
Windows: True
winget: available
npx: available
```

### 2) Skill discovery

```bash
npx --yes skills add . --list -y
# equivalent published form:
# npx --yes skills add yuanyuanyuan/codex-windows-workbench --list -y
```

Observed:

```text
Found 1 skill
codex-windows-workbench
```

### 3) Skill install

```bash
npx --yes skills add yuanyuanyuan/codex-windows-workbench -g -y -s codex-windows-workbench -a codex --copy
```

Observed install root:

```text
%USERPROFILE%\.agents\skills\codex-windows-workbench
SKILL.md = present
scripts\Initialize-PwshAgentWindows.ps1 = present
```

### 4) Structure validation

```text
Skill is valid!
Plugin validation passed
```

### 5) Workbench preview (no mutation)

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -WhatIf -Json
```

Observed (sanitized):

```json
{
  "Mode": "WhatIf",
  "Changed": false,
  "Selected": ["Core", "Agent"],
  "Phases": [
    { "Name": "Core", "Status": "Planned" },
    { "Name": "Agent", "Status": "Planned" },
    { "Name": "AgentClients", "Status": "NotSelected" },
    { "Name": "Developer", "Status": "NotSelected" },
    { "Name": "NativeBuild", "Status": "NotSelected" },
    { "Name": "Containers", "Status": "NotSelected" }
  ],
  "Actions": [
    { "Phase": "Core", "Action": "winget-configure", "Target": "config\\windows-agent-core.winget" },
    { "Phase": "Core", "Action": "scoop-bootstrap", "Target": "https://get.scoop.sh" },
    { "Phase": "Core", "Action": "scoop-install", "Target": "ripgrep fd fzf jq bat delta yq 7zip zip nuget" },
    { "Phase": "Agent", "Action": "install-profile-overlay", "Target": "%USERPROFILE%\\.config\\pwsh-ai" },
    { "Phase": "Agent", "Action": "initialize-managed-agent-directories", "Target": "%USERPROFILE%\\.config\\pwsh-ai\\hooks" }
  ],
  "SafetyHooks": false
}
```

## Real configure/apply procedure after preview confirmation

```powershell
# Apply default Core + Agent only
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Confirm:$false -Json

# Recheck
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Status -Json
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json
```

Expected Apply effects:

1. Preflight first; stop on blockers
2. Core: winget baseline + scoop CLI tools
3. Agent: managed overlay + state
4. Automatic post-apply smoke verification
5. No WSL/bash/apt/brew
6. No Codex auto-login
7. No secret/MCP credential writes

## Acceptance matrix

| Check | Result in this UAT |
|------|---------------------|
| Skill discoverable | Pass |
| Skill installed to user dir | Pass |
| Skill/plugin manifests valid | Pass |
| WhatIf non-mutating | Pass (`Changed=false`) |
| Default selection Core+Agent only | Pass |
| Optional workloads not selected | Pass |
| WSL/bash/apt/brew absent from plan | Pass |
| Auth/secret automation absent | Pass |
| Full package Apply | Procedure documented; run only with explicit user consent |

## Notes

- Absolute personal paths were sanitized to `%USERPROFILE%` / relative repo paths in published docs.
- Full winget/scoop package Apply is intentionally gated because it changes the machine and may require elevation.
- Agents should always report `Selected` + `Actions` from `-WhatIf` before Apply.
