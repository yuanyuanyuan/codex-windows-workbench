# Stark Codex Windows Workbench — Installation Guide

## For Humans

把下面这句话发给你的 AI Agent：

```text
帮我安装 stark-codex-windows-workbench：https://raw.githubusercontent.com/yuanyuanyuan/stark-codex-windows-workbench/master/docs/install.md
```

只要 skill、不要改机器配置（安全模式）：

```text
帮我安装 stark-codex-windows-workbench（安全模式）：https://raw.githubusercontent.com/yuanyuanyuan/stark-codex-windows-workbench/master/docs/install.md
安装时只安装 skill，不要执行工作台 Apply；先用 -WhatIf 预览。
```

默认安装 + 应用 Core + Agent 工作台：

```text
帮我安装 stark-codex-windows-workbench 并配置默认工作台：https://raw.githubusercontent.com/yuanyuanyuan/stark-codex-windows-workbench/master/docs/install.md
先预览，确认后再 Apply Core + Agent。使用 -Confirm:$false 执行。
```

源仓库：

```text
https://github.com/yuanyuanyuan/stark-codex-windows-workbench
```

---

## For AI Agents

### Goal

Install the `stark-codex-windows-workbench` skill, then optionally configure a native Windows PowerShell 7 Codex workbench.

### Execution effects (what the user should expect)

When the skill runs end-to-end, the observable effect is:

1. **Skill resolved** — scripts found under a user skill directory
2. **Preflight** — blockers/warnings only; no mutation
3. **WhatIf** — JSON plan with `Selected`, `Phases(Planned|NotSelected)`, `Actions`, `SafetyHooks=false` by default; `Changed=false`
4. **Apply (after confirm)** — Core + Agent only:
   - Core: winget baseline + scoop CLI tools
   - Agent: managed overlay under `%USERPROFILE%\.config\pwsh-ai` and state under `%LOCALAPPDATA%\PwshAiAgent\state`
5. **Post-apply smoke verify** — automatic after Apply
6. **Status/Verify** — read-only health/completeness
7. **Rollback** — restore managed settings/files only; packages remain

Tell the user these effects in plain language before Apply.

Default path after skill install:

1. Resolve skill root
2. Preflight
3. Preview with `-WhatIf -Json` and read **`Actions` + `Selected`**
4. Tell the user the real Core impact, then ask for Apply confirmation
5. Apply **Core + Agent only** with `-Confirm:$false`
6. Verify / Status
7. Report results

This skill maintains a Windows engineering workbench for Codex.  
It is not an auth tool, cookie importer, marketplace installer, or multi-agent SDK.

### Key definitions

| Term | Meaning |
|------|---------|
| **Skill install** | Put `SKILL.md` + scripts into an agent skill directory |
| **Workbench Apply** | Change the machine via managed Core/Agent phases |
| **Core** | Baseline packages + CLI tools through winget/scoop |
| **Agent** | Managed PowerShell overlay and agent directories under `%USERPROFILE%\.config\pwsh-ai` |
| **AgentClients** | Verify whether public agent CLIs exist. Public MVP: **Codex probe only**. Does **not** install or login Codex |
| **SafetyHooks** | Optional copy of managed git safety hook. Only with explicit `-EnableSafetyHooks` or `-Full` |

### Boundaries

- **DO** install the skill into user/agent skill directories
- **DO** run scripts with PowerShell 7 (`pwsh`)
- **DO** preview with `-WhatIf` before Apply when the user has not confirmed
- **DO** use `-Confirm:$false` for non-interactive Apply / Rollback
- **DO NOT** use Windows PowerShell 5.1
- **DO NOT** use WSL, bash, apt, or brew
- **DO NOT** auto-login Codex
- **DO NOT** write tokens, MCP endpoints, secrets, cookies, or permission grants
- **DO NOT** enable optional workloads unless the user explicitly asks
- **DO NOT** claim `-AgentClients` installs Codex; it only verifies presence/version
- **DO NOT** use elevation / admin unless the user explicitly approves
- If elevated permissions are required, **tell the user** and wait

### Directory Rules

Prefer global/user skill dirs. Do not pollute the current project workspace.

| Purpose | Directory |
|---------|-----------|
| Preferred skill install (`npx skills`) | `%USERPROFILE%\.agents\skills\stark-codex-windows-workbench\` |
| Codex manual skill path | `%USERPROFILE%\.codex\skills\stark-codex-windows-workbench\` |
| Claude manual skill path | `%USERPROFILE%\.claude\skills\stark-codex-windows-workbench\` |
| Managed workbench state | `%LOCALAPPDATA%\PwshAiAgent\state\` |
| Managed agent overlay | `%USERPROFILE%\.config\pwsh-ai\` |
| Runtime scripts | `<skill-root>\scripts\` |

### Host Preconditions

```powershell
pwsh -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString(); $IsWindows; Get-Command winget,npx,git -ErrorAction SilentlyContinue | Select-Object Name,Source'
```

Required for skill install:

- Native Windows
- PowerShell 7+
- Network access

Required for workbench **Apply**:

- `winget` available
- User consent for package install / possible elevation

If PowerShell 7 is missing, stop. Do not fall back to 5.1.

---

### Step 1: Install the skill

Choose the first method that works. Prefer **npx**.

#### Option A — npx (Recommended)

```powershell
npx --yes skills add yuanyuanyuan/stark-codex-windows-workbench -g -y -s stark-codex-windows-workbench
```

Codex-only host:

```powershell
npx --yes skills add yuanyuanyuan/stark-codex-windows-workbench -g -y -s stark-codex-windows-workbench -a codex
```

Expected path:

```text
%USERPROFILE%\.agents\skills\stark-codex-windows-workbench
```

#### Option B — RedSkill

```text
现在为你安装 Skill，先来检查是否已安装 Red Skill 商店，请根据 https://redskill.xiaohongshu.net/install.md 安装 RedSkill 商店，然后安装 stark-codex-windows-workbench 技能。若已安装，则直接安装 stark-codex-windows-workbench 技能。
```

#### Option C — Codex Plugin CLI


Use the Codex CLI in a terminal. This is not a chat `/plugin` slash command.

```bash
codex plugin marketplace add yuanyuanyuan/stark-codex-windows-workbench
codex plugin add stark-codex-windows-workbench@stark-codex-windows-workbench
```

After plugin install, locate the installed plugin/skill files on disk. If they are not under the candidate paths below, search for `SKILL.md` whose frontmatter name is `stark-codex-windows-workbench`.

#### Option D — Manual Git Clone

```powershell
git clone https://github.com/yuanyuanyuan/stark-codex-windows-workbench.git $env:USERPROFILE\.codex\skills\stark-codex-windows-workbench
# or Claude:
git clone https://github.com/yuanyuanyuan/stark-codex-windows-workbench.git $env:USERPROFILE\.claude\skills\stark-codex-windows-workbench
```

#### Resolve skill root

```powershell
$candidates = @(
  (Join-Path $env:USERPROFILE '.agents\skills\stark-codex-windows-workbench')
  (Join-Path $env:USERPROFILE '.codex\skills\stark-codex-windows-workbench')
  (Join-Path $env:USERPROFILE '.claude\skills\stark-codex-windows-workbench')
)
$SkillRoot = $candidates | Where-Object { Test-Path (Join-Path $_ 'SKILL.md') } | Select-Object -First 1
if (-not $SkillRoot) {
  $hit = Get-ChildItem -Path (Join-Path $env:USERPROFILE '.codex'), (Join-Path $env:USERPROFILE '.agents'), (Join-Path $env:USERPROFILE '.claude') -Filter SKILL.md -Recurse -ErrorAction SilentlyContinue |
    Where-Object { (Get-Content $_.FullName -TotalCount 5 -ErrorAction SilentlyContinue) -match 'stark-codex-windows-workbench' } |
    Select-Object -First 1
  if ($hit) { $SkillRoot = $hit.Directory.FullName }
}
if (-not $SkillRoot) { throw 'stark-codex-windows-workbench skill not found after install.' }
$Init = Join-Path $SkillRoot 'scripts\Initialize-PwshAgentWindows.ps1'
$Preflight = Join-Path $SkillRoot 'scripts\Preflight-PwshAgentWindows.ps1'
Test-Path (Join-Path $SkillRoot 'SKILL.md'); Test-Path $Init; Test-Path $Preflight
```

If the user asked for **safe mode / skill only**, stop after skill install and report the path.

---

### Step 2: Preflight

```powershell
pwsh -NoLogo -NoProfile -File $Preflight -Json
```

- `FAIL` / blockers → fix or ask user; do not Apply
- warnings only → continue and report
- all OK → continue

Note: Apply also runs preflight internally and will fail closed if blocked.

---

### Step 3: Preview default plan

Always preview first unless the user already confirmed Apply in the same request.

```powershell
pwsh -NoLogo -NoProfile -File $Init -WhatIf -Json
```

How to read the JSON:

1. Prefer **`Selected`** and **`Actions`**
2. `Phases[].Status`:
   - `Planned` = selected
   - `NotSelected` = not selected
3. `SafetyHooks=false` by default
4. Do **not** invent WSL/bash/apt/brew steps

Default selected phases:

- `Core`
- `Agent`

Default Core impact to tell the user before Apply:

- Uses **winget configure** for baseline packages (may require elevation for some packages)
- Bootstraps **scoop** and installs common CLI tools (`ripgrep`, `fd`, `fzf`, `jq`, `bat`, `delta`, `yq`, `7zip`, `zip`, `nuget`)
- Agent phase writes managed overlay/state under `%USERPROFILE%\.config\pwsh-ai` and `%LOCALAPPDATA%\PwshAiAgent\state`
- Does **not** auto-login Codex
- Does **not** write secrets/MCP credentials

Suggested confirmation prompt:

```text
预览完成。默认只会应用 Core + Agent。
Core 可能通过 winget/scoop 安装基线工具，并可能需要提权。
Agent 会写入托管 PowerShell overlay / 状态目录。
要现在 Apply 吗？还是只要 skill / 只要预览？
如需 Developer / NativeBuild / Containers / AgentClients(仅探测Codex) / SafetyHooks，请明确说。
```

---

### Step 4: Apply default workbench (only after confirmation)

```powershell
pwsh -NoLogo -NoProfile -File $Init -Confirm:$false -Json
```

Rules:

- Default = Core + Agent only
- `-Confirm:$false` is required for unattended Apply because the script uses high-confirm ShouldProcess
- `winget` is a hard requirement for Apply, not optional
- Apply runs preflight first, then phases, then post-apply smoke verification
- Still does not auto-login Codex or write secrets

Safe mode / skill only: skip this step.

---

### Step 5: Verify and report

Apply already includes smoke verification. Still run explicit checks when reporting:

```powershell
pwsh -NoLogo -NoProfile -File $Init -Verify -Json
pwsh -NoLogo -NoProfile -File $Init -Status -Json
```

Report:

- skill path
- whether Apply ran
- selected phases
- verify/status summary
- remaining warnings
- next invocation:

```text
stark-codex-windows-workbench
/stark-codex-windows-workbench
```

---

### Optional flags (explicit request only)

```powershell
# Developer tools
pwsh -NoLogo -NoProfile -File $Init -Developer -Confirm:$false -Json

# Native build toolchain
pwsh -NoLogo -NoProfile -File $Init -NativeBuild -Confirm:$false -Json

# Docker Desktop package only (no WSL backend setup)
pwsh -NoLogo -NoProfile -File $Init -Containers -Confirm:$false -Json

# Verify Codex CLI presence/version only; does NOT install or login
pwsh -NoLogo -NoProfile -File $Init -AgentClients -Confirm:$false -Json

# Install managed git safety hook
pwsh -NoLogo -NoProfile -File $Init -EnableSafetyHooks -Confirm:$false -Json

# All optional workloads + safety hooks
pwsh -NoLogo -NoProfile -File $Init -Full -Confirm:$false -Json
```

Public MVP notes:

- `-AgentClients` = Codex probe only
- If Codex is missing, tell the user to install/login manually; never automate auth

---

### Rollback

Restores managed settings/files only. Does **not** uninstall packages.

```powershell
pwsh -NoLogo -NoProfile -File $Init -Rollback -Confirm:$false -Json
```

Ask the user before rollback.

---

### Safe Mode

Aliases: `安全模式` / `safe mode` / `dry-run` / `只安装 skill`

Mapped behavior:

1. Install skill only
2. Optional preflight
3. `-WhatIf -Json` preview
4. Do **not** Apply
5. Do **not** enable optional workloads
6. Wait for user decision

There is no `--safe` CLI flag. Safe mode is a procedure, not a switch.

---

### Failure Handling

1. Capture command + exit code
2. Prefer `-Json`
3. Sanitize secrets, usernames, proxy endpoints, absolute personal paths
4. Retry only idempotent skill-supported steps
5. If elevation / login / secrets are required, stop and ask

| Symptom | Action |
|---------|--------|
| PowerShell 5.1 only | Stop; install PowerShell 7 |
| Not Windows / WSL | Stop; native Windows only |
| skill not found | Retry another install channel; search for `SKILL.md` |
| winget missing on Apply | Report hard blocker; no bash/apt/brew fallback |
| Confirm prompt / hung Apply | Rerun with `-Confirm:$false` |
| Codex missing / not logged in | Expected for AgentClients probe; user must install/login manually |
| Verify failed after Apply | Run `-Status -Json`; ask before `-Force` retry |

---

### Final Check

1. SKILL.md exists under a user skill directory
2. scripts/Initialize-PwshAgentWindows.ps1 and config/ also exist under that same skill directory
2. User can call `stark-codex-windows-workbench` / `/stark-codex-windows-workbench`
3. If Apply ran, verification was reported
4. No secrets written
5. No optional workload enabled silently
6. No false claim that Codex was installed/logged in

Success template:

```text
stark-codex-windows-workbench 已安装。
Skill 路径: <SkillRoot>
工作台: <not applied | previewed | applied Core+Agent>
验证: <pass/fail/skipped>
以后直接调用: stark-codex-windows-workbench 或 /stark-codex-windows-workbench
```

---

## Quick Reference

| Action | Command |
|--------|---------|
| Install skill (npx) | `npx --yes skills add yuanyuanyuan/stark-codex-windows-workbench -g -y -s stark-codex-windows-workbench` |
| Codex plugin CLI | `codex plugin marketplace add yuanyuanyuan/stark-codex-windows-workbench` then `codex plugin add stark-codex-windows-workbench@stark-codex-windows-workbench` |
| Manual Codex install | clone repo then copy `skills/stark-codex-windows-workbench` into `%USERPROFILE%\.codex\skills\stark-codex-windows-workbench` |
| Preflight | `pwsh -NoLogo -NoProfile -File .\scripts\Preflight-PwshAgentWindows.ps1 -Json` |
| Preview | `pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -WhatIf -Json` |
| Apply default | `pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Confirm:$false -Json` |
| Verify | `pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json` |
| Status | `pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Status -Json` |
| Rollback | `pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Rollback -Confirm:$false -Json` |

## Related

- Skill entry: [`SKILL.md`](../skills/stark-codex-windows-workbench/SKILL.md)
- English README: [`README.md`](../README.md)
- 中文 README: [`README.zh-CN.md`](../README.zh-CN.md)
- Contracts: [`references/contracts.md`](../references/contracts.md)

- UAT real process notes: [docs/uat-real-install-configure.md](./uat-real-install-configure.md)



