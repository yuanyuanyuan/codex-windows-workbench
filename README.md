# Stark Codex Windows Workbench

> 中文说明：[README.zh-CN.md](./README.zh-CN.md)

**Skill:** `stark-codex-windows-workbench`

## Pain Points

On native Windows, getting Codex ready for real engineering work is usually messy:

- Agents fall back to WSL/bash/`apt` habits that do not belong on Windows
- Setup is scattered across winget, scoop, PATH, profile, and random one-off scripts
- You cannot safely preview what will change before packages land
- Re-running setup is not idempotent; rollback is unclear
- Auth/secrets get mixed into bootstrap docs and accidentally over-automated

## What This Skill Solves

`stark-codex-windows-workbench` is a **native Windows PowerShell 7 workbench skill for Codex**.

It gives agents one direct entrypoint to:

1. Install the skill itself
2. Preflight the machine
3. Preview Core + Agent changes
4. Apply a minimal managed baseline
5. Verify / show status
6. Roll back managed settings only

Default path: **Core + Agent**. No WSL. No auth automation. No secret writes.

## Before / After

| | Before | After |
|---|---|---|
| Entry | Many ad-hoc scripts and chat instructions | Call `stark-codex-windows-workbench` / `/stark-codex-windows-workbench` |
| Host model | WSL/bash leakage, mixed shells | Native Windows + PowerShell 7 only |
| Change safety | Install first, discover impact later | `-WhatIf` preview, then explicit Apply |
| Baseline | Inconsistent machine-specific tool soup | Managed Core + Agent default |
| Secrets | Bootstrap docs tempt token/login automation | Never auto-login; never write MCP/secrets |
| Recovery | Uninstall guesswork | Rollback managed settings only |
| Repeatability | “Works on my machine” | Idempotent phases + status/verify |

## Execution Effects

What happens when you call the skill, step by step:

```text
call skill
  -> resolve scripts
  -> Preflight
  -> WhatIf preview (default)
  -> user confirms
  -> Apply Core + Agent
  -> post-apply smoke verify
  -> Status / Verify / Rollback on request
```

| Step | What runs | Machine effect | What you see |
|------|-----------|----------------|--------------|
| 1. Call skill | `stark-codex-windows-workbench` / `/stark-codex-windows-workbench` | No machine change yet | Agent loads skill instructions |
| 2. Preflight | `Preflight-PwshAgentWindows.ps1 -Json` | Read-only checks | Host/tool blockers and warnings |
| 3. Preview | `Initialize-...ps1 -WhatIf -Json` | **No changes** (`Changed=false`) | `Selected`, `Phases`, `Actions`, `SafetyHooks` |
| 4. Confirm | Agent asks you | No changes | Clear Core + Agent impact summary |
| 5. Apply | `Initialize-...ps1 -Confirm:$false -Json` | Installs baseline tools + managed overlay | Phase results + smoke verification |
| 6. Verify/Status | `-Verify` / `-Status` | Read-only | Pass/fail and phase completeness |
| 7. Rollback | `-Rollback -Confirm:$false` | Restores managed settings only | Packages stay installed |

### Default Apply effects (Core + Agent)

**Core**

- winget-configure baseline packages from `config/windows-agent-core.winget`
- bootstrap scoop if needed
- install common CLI tools: `ripgrep fd fzf jq bat delta yq 7zip zip nuget`
- some packages may require elevation

**Agent**

- write managed PowerShell overlay under `%USERPROFILE%\.config\pwsh-ai`
- create managed agent directories (hooks/mcp/skills/...)
- record managed state under `%LOCALAPPDATA%\PwshAiAgent\state`

**Never happens by default**

- no WSL / bash / apt / brew
- no Codex auto-login
- no secret / MCP credential writes
- no Developer / NativeBuild / Containers unless requested
- no package uninstall on rollback

### Example preview output shape

```json
{
  "Mode": "WhatIf",
  "Changed": false,
  "Selected": ["Core", "Agent"],
  "Phases": [
    { "Name": "Core", "Status": "Planned" },
    { "Name": "Agent", "Status": "Planned" },
    { "Name": "Developer", "Status": "NotSelected" }
  ],
  "SafetyHooks": false
}
```

Read preview like this:

- trust `Selected` + `Actions`
- `Planned` means it will run
- `NotSelected` means it will not run
- `Changed=false` means preview did not modify the machine

## UAT: Real Install And Configure Process

This section records a real user-acceptance path on a native Windows host.
It is not a theoretical checklist. Commands below were executed and observed.

### Scope of this UAT

| Stage | Executed for real? | Why |
|-------|--------------------|-----|
| Host precheck | Yes | Confirm Windows + PowerShell 7 + winget/npx |
| Skill discovery (`npx skills add --list`) | Yes | Confirm package is discoverable |
| Skill install to user skill dir | Yes | Confirm skill lands in `%USERPROFILE%\.agents\skills\...` |
| Skill/plugin structure validation | Yes | Confirm package manifests are valid |
| Workbench preview (`-WhatIf -Json`) | Yes | Confirm Core+Agent plan without mutation |
| Full package Apply (winget/scoop install) | Documented procedure | Destructive/long-running; run only with user consent |
| Post-apply verify/status | Documented procedure | Runs after real Apply |

### Observed host

```text
OS: Windows
PowerShell: 7.5.8
winget: available
npx: available
```

### Stage A — Install the skill (real)

1. Discover skill from repo/package:

```bash
npx --yes skills add yuanyuanyuan/stark-codex-windows-workbench --list -y
```

Observed:

```text
Found 1 skill
stark-codex-windows-workbench
```

2. Install skill globally for Codex:

```bash
npx --yes skills add yuanyuanyuan/stark-codex-windows-workbench -g -y -s stark-codex-windows-workbench -a codex --copy
```

Observed install target:

```text
%USERPROFILE%\.agents\skills\stark-codex-windows-workbench
SKILL.md = present
scripts\Initialize-PwshAgentWindows.ps1 = present
```

3. Validate package structure:

```text
Skill is valid!
Plugin validation passed
```

### Stage B — Configure/preview the workbench (real)

From the skill/repo root:

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -WhatIf -Json
```

Observed result (sanitized):

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

Interpretation of this real preview:

- machine was **not** modified (`Changed=false`)
- only **Core + Agent** are selected
- Developer/NativeBuild/Containers/AgentClients are `NotSelected`
- Safety hooks stay off unless explicitly requested

### Stage C — Apply configuration (real procedure)

Only after the user confirms the preview:

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Confirm:$false -Json
```

What this real Apply does:

1. Runs preflight first; fails closed on blockers
2. Applies **Core**
   - `winget configure` with `config/windows-agent-core.winget`
   - bootstraps scoop if needed
   - installs CLI tools: `ripgrep fd fzf jq bat delta yq 7zip zip nuget`
3. Applies **Agent**
   - writes managed overlay under `%USERPROFILE%\.config\pwsh-ai`
   - creates managed agent directories
   - records managed state under `%LOCALAPPDATA%\PwshAiAgent\state`
4. Auto-runs post-apply smoke verification
5. Returns JSON with phase results + `PostApplyVerification`

Then re-check:

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Status -Json
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json
```

### Stage D — Acceptance criteria used in UAT

| Check | Expected real result |
|-------|----------------------|
| Skill discoverable | `Found 1 skill: stark-codex-windows-workbench` |
| Skill installed | `SKILL.md` + `scripts/Initialize-...ps1` under user skill dir |
| Preview safe | `-WhatIf` returns `Changed=false` |
| Default selection | `Selected=["Core","Agent"]` only |
| Optional workloads hidden | Developer/NativeBuild/Containers/AgentClients = `NotSelected` |
| No WSL path | plan contains no wsl/bash/apt/brew actions |
| No auth automation | no login/token/MCP secret writes |
| Apply gated | requires explicit user confirm + `-Confirm:$false` for unattended run |
| Verify path exists | `-Status` / `-Verify` return machine-readable JSON |

### One-command UAT replay for agents

```text
按 docs/install.md 安装 stark-codex-windows-workbench；先 npx 安装 skill，再执行 -WhatIf -Json 预览 Core+Agent，把 Selected/Actions 报告给我确认后，才允许 -Confirm:$false Apply，最后跑 -Status/-Verify。
```

Full raw notes: [docs/uat-real-install-configure.md](./docs/uat-real-install-configure.md)

## Install

Copy this to your Agent:

```text
帮我安装 stark-codex-windows-workbench：https://raw.githubusercontent.com/yuanyuanyuan/stark-codex-windows-workbench/master/docs/install.md
```

Full agent install guide: [docs/install.md](./docs/install.md)

### RedSkill

```text
现在为你安装 Skill，先来检查是否已安装 Red Skill 商店，请根据 https://redskill.xiaohongshu.net/install.md 安装 RedSkill 商店，然后安装 stark-codex-windows-workbench 技能。若已安装，则直接安装 stark-codex-windows-workbench 技能。
```

### npx (Recommended)

```bash
npx skills add yuanyuanyuan/stark-codex-windows-workbench
```

### Codex Plugin CLI


Use the Codex CLI in a terminal. This is not a chat `/plugin` slash command.

```bash
codex plugin marketplace add yuanyuanyuan/stark-codex-windows-workbench
codex plugin add stark-codex-windows-workbench@stark-codex-windows-workbench
```

### Manual (Git Clone)

```bash
# Windows + Codex
git clone https://github.com/yuanyuanyuan/stark-codex-windows-workbench.git %USERPROFILE%\.codex\skills\stark-codex-windows-workbench

# Windows + Claude Code
git clone https://github.com/yuanyuanyuan/stark-codex-windows-workbench.git %USERPROFILE%\.claude\skills\stark-codex-windows-workbench
```

## Uninstall

Uninstall removes the skill package from agent skill directories. It does **not** uninstall winget/scoop packages installed by Apply.

### 1) Optional: rollback managed workbench settings first

```powershell
pwsh -NoLogo -NoProfile -File "$env:USERPROFILE\.agents\skills\stark-codex-windows-workbench\scripts\Initialize-PwshAgentWindows.ps1" -Rollback -Confirm:$false -Json
```

If the skill is only under Codex/Claude skill dirs, replace the path above with the installed skill root.

### 2) Remove skill directories

```powershell
$paths = @(
  "$env:USERPROFILE\.agents\skills\stark-codex-windows-workbench"
  "$env:USERPROFILE\.codex\skills\stark-codex-windows-workbench"
  "$env:USERPROFILE\.claude\skills\stark-codex-windows-workbench"
  # legacy names from earlier renames
  "$env:USERPROFILE\.agents\skills\codex-windows-workbench"
  "$env:USERPROFILE\.agents\skills\windows-pwsh-agent-workbench"
  "$env:USERPROFILE\.codex\skills\codex-windows-workbench"
  "$env:USERPROFILE\.claude\skills\codex-windows-workbench"
)
$paths | Where-Object { Test-Path $_ } | ForEach-Object {
  Remove-Item -LiteralPath $_ -Recurse -Force
  Write-Host "Removed $_"
}
```

### 3) Optional: remove Codex plugin entry

If installed via Codex Plugin CLI:

```bash
codex plugin remove stark-codex-windows-workbench@stark-codex-windows-workbench
```

If your Codex CLI version does not support `plugin remove`, delete the installed plugin directory manually and remove the marketplace entry from Codex config.

### What uninstall does not do

- Does not uninstall packages installed by Core (`winget` / `scoop`)
- Does not delete your unrelated PowerShell profile content
- Does not log out of Codex

## Use

```text
stark-codex-windows-workbench
```

```text
/stark-codex-windows-workbench
```

## What it does

- Audit / preflight
- Preview (`-WhatIf`)
- Apply Core + Agent by default
- Verify / status
- Rollback managed settings only

Optional explicit workloads:

- `-Developer`
- `-NativeBuild`
- `-Containers`
- `-AgentClients` (Codex presence/version probe only; does not install or login)
- `-EnableSafetyHooks`
- `-Full`

## Constraints

- Windows + PowerShell 7+ only
- No Windows PowerShell 5.1
- No WSL / bash / apt / brew
- No auth login automation
- No secret / MCP credential writes
- Rollback does not uninstall packages
- Apply requires `winget`
- Non-interactive Apply/Rollback should use `-Confirm:$false`

## Package

```text
SKILL.md
agents/openai.yaml
.codex-plugin/plugin.json
.claude-plugin/plugin.json
.claude-plugin/marketplace.json
package.json
scripts/
config/
references/
docs/
```

## License

MIT — see [LICENSE](./LICENSE).



