# Stark Codex Windows Workbench

> Chinese README: [README.zh-CN.md](./README.zh-CN.md)

**Skill:** `stark-codex-windows-workbench`

A direct entry point for Codex to safely preflight, preview, apply, verify, and roll back a managed workbench on **native Windows + PowerShell 7**.  
Default path: **Core + Agent**. No WSL. No auto-login. No secret writes.

## What This Skill Is For

`stark-codex-windows-workbench` is a **native Windows PowerShell 7 workbench skill** for Codex.

It is used to:

1. Install the skill itself
2. Preflight whether the host can run
3. Preview what Core + Agent will change with `-WhatIf`
4. Explicitly Apply a minimal managed baseline
5. Verify / inspect status
6. Roll back managed settings only

In one sentence: give the agent a repeatable, previewable, rollback-friendly Windows workbench instead of a pile of ad-hoc scripts.

## What Problem It Solves

Turning Codex into an engineering-ready state on native Windows usually hits these pain points:

- Agents drift into WSL / bash / `apt` and mess up the Windows host
- Install paths are scattered across winget, scoop, PATH, Profile, and temporary scripts
- There is no safe preview of impact before packages are installed
- Re-runs are unstable, and recovery is unclear when something breaks
- Install docs mix login/secret steps and tempt agents into over-automation

This skill collapses those problems into one direct invocation path and hardens the boundaries:

- Native Windows + PowerShell 7 only
- Preview first, Apply only after confirmation
- Default path is Core + Agent only
- Never auto-login, never write MCP/secrets
- Rollback restores managed settings only; it does not uninstall packages

## Why Use It

| If you currently... | This skill helps you... |
|---|---|
| Bootstrap with chat prompts and scattered scripts | Call one skill for preflight / preview / apply / verify |
| Install first and discover impact later | Preview with `-WhatIf`, then Apply after confirmation |
| Still get pulled into WSL/bash on Windows | Stay on a fixed native Windows + PowerShell 7 path |
| Keep inconsistent machine baselines | Use a managed Core + Agent default |
| Recover by guessing uninstall steps | Roll back managed settings with fixed uninstall steps |

## User Scenario Comparison

| | Before | After |
|---|---|---|
| Entry | Many ad-hoc scripts and chat instructions | Call `$stark-codex-windows-workbench` |
| Host model | WSL/bash leakage, mixed shells | Native Windows + PowerShell 7 only |
| Change safety | Install first, discover impact later | `-WhatIf` preview, then explicit Apply |
| Baseline | Machine-specific tool soup | Managed Core + Agent default |
| Secrets | Bootstrap docs tempt token/login automation | Never auto-login; never write MCP/secrets |
| Recovery | Uninstall guesswork | Rollback managed settings only |
| Repeatability | "Works on my machine" | Idempotent phases + status/verify |

### Typical flow after you call it

```text
call skill
  -> Preflight
  -> WhatIf preview
  -> you confirm
  -> Apply Core + Agent
  -> smoke verify
  -> Status / Verify / Rollback on request
```

## Install

### One-line for agents

```text
Install stark-codex-windows-workbench for me using https://raw.githubusercontent.com/yuanyuanyuan/stark-codex-windows-workbench/master/docs/install.md
```

Full agent install guide: [docs/install.md](./docs/install.md)

### RedSkill

RedSkill install wording is Chinese-market specific. Use this exact text with a RedSkill-capable agent:

```text
现在为你安装 Skill，先来检查是否已安装 Red Skill 商店，请根据 https://redskill.xiaohongshu.net/install.md 安装 RedSkill 商店，然后安装 stark-codex-windows-workbench 技能。若已安装，则直接安装 stark-codex-windows-workbench 技能。
```

### npx (Recommended)

```bash
npx skills add yuanyuanyuan/stark-codex-windows-workbench
```

### Codex Plugin CLI

Use the Codex CLI in a terminal. This is **not** a chat `/plugin` slash command.

```bash
codex plugin marketplace add yuanyuanyuan/stark-codex-windows-workbench
codex plugin add stark-codex-windows-workbench@stark-codex-windows-workbench
```

### Manual (Git Clone)

`npx skills` installs the skill folder under `skills/stark-codex-windows-workbench/` (not the whole repo root).

```powershell
git clone --depth 1 https://github.com/yuanyuanyuan/stark-codex-windows-workbench.git $env:TEMP\stark-codex-windows-workbench
Copy-Item -Recurse -Force $env:TEMP\stark-codex-windows-workbench\skills\stark-codex-windows-workbench $env:USERPROFILE\.codex\skills\stark-codex-windows-workbench
```

## Use

```text
$stark-codex-windows-workbench
```

Default behavior after invoke:

- audit / preflight
- preview with `-WhatIf`
- apply **Core + Agent** only after confirm
- verify / status
- rollback managed settings only

Optional workloads (explicit only):

- `-Developer`
- `-NativeBuild`
- `-Containers`
- `-AgentClients` (Codex presence/version probe only; does **not** install or login)
- `-EnableSafetyHooks`
- `-Full`

## Uninstall

Uninstall removes the skill package from agent skill directories.  
It does **not** uninstall winget/scoop packages installed by Apply.

### 1) Optional: rollback managed workbench settings first

```powershell
pwsh -NoLogo -NoProfile -File "$env:USERPROFILE\.agents\skills\stark-codex-windows-workbench\scripts\Initialize-PwshAgentWindows.ps1" -Rollback -Confirm:$false -Json
```

### 2) Remove skill directories

```powershell
$paths = @(
  "$env:USERPROFILE\.agents\skills\stark-codex-windows-workbench"
  "$env:USERPROFILE\.codex\skills\stark-codex-windows-workbench"
  # legacy names from earlier renames
  "$env:USERPROFILE\.agents\skills\codex-windows-workbench"
  "$env:USERPROFILE\.agents\skills\windows-pwsh-agent-workbench"
  "$env:USERPROFILE\.codex\skills\codex-windows-workbench"
)
$paths | Where-Object { Test-Path $_ } | ForEach-Object {
  Remove-Item -LiteralPath $_ -Recurse -Force
  Write-Host "Removed $_"
}
```

### 3) Optional: remove Codex plugin entry

```bash
codex plugin remove stark-codex-windows-workbench@stark-codex-windows-workbench
```

If your Codex CLI version does not support `plugin remove`, delete the installed plugin directory manually and remove the marketplace entry from Codex config.

### What uninstall does not do

- Does not uninstall packages installed by Core (`winget` / `scoop`)
- Does not delete your unrelated PowerShell profile content
- Does not log out of Codex

## Execution Effects

| Step | What runs | Machine effect | What you see |
|------|-----------|----------------|--------------|
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
- create managed agent directories
- record managed state under `%LOCALAPPDATA%\PwshAiAgent\state`

**Never happens by default**

- no WSL / bash / apt / brew
- no Codex auto-login
- no secret / MCP credential writes
- no Developer / NativeBuild / Containers unless requested
- no package uninstall on rollback

### Example preview output

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

Preview/apply reports now include human-readable `Summary` and structured `Impact` so you can see packages, managed files, and non-actions without decoding raw JSON.

How to read it:

- trust `Selected` + `Actions`
- `Planned` means it will run
- `NotSelected` means it will not run
- `Changed=false` means preview did not modify the machine

## Constraints

- Windows + PowerShell 7+ only
- No Windows PowerShell 5.1
- No WSL / bash / apt / brew
- No auth login automation
- No secret / MCP credential writes
- Rollback does not uninstall packages
- Apply requires `winget`
- Non-interactive Apply/Rollback should use `-Confirm:$false`

## UAT Evidence

After every update, run the mandatory regression suite:

```powershell
pwsh -NoLogo -NoProfile -File .\tests\uat\Invoke-UatRegression.ps1
```

- Rules: [docs/uat/REGRESSION-RULES.md](./docs/uat/REGRESSION-RULES.md)
- Cases: [docs/uat/cases/](./docs/uat/cases/)
- This gate checks **installed skill product completeness**, not only source-tree discovery/WhatIf.

Real install + configure notes live here:

- [docs/uat-real-install-configure.md](./docs/uat-real-install-configure.md)

Observed on a native Windows host:

- skill discoverable via `npx skills add ... --list`
- skill install lands under `%USERPROFILE%\.agents\skills\stark-codex-windows-workbench`
- `-WhatIf -Json` returns `Changed=false` with `Selected=["Core","Agent"]`
- full package Apply is gated behind explicit user confirmation

One-command agent replay:

```text
Install stark-codex-windows-workbench using docs/install.md. First install the skill with npx, then run -WhatIf -Json to preview Core+Agent, report Selected/Actions for confirmation, and only after I confirm run -Confirm:$false Apply, then -Status/-Verify.
```

## Package

```text
skills/stark-codex-windows-workbench/
  SKILL.md
  agents/openai.yaml
  scripts/
  config/
  references/
.codex-plugin/plugin.json
package.json
docs/
```

## License

MIT — see [LICENSE](./LICENSE).

