# Codex Windows Workbench — Installation Guide

## For Humans

把下面这句话发给你的 AI Agent：

```text
帮我安装 codex-windows-workbench：https://raw.githubusercontent.com/yuanyuanyuan/codex-windows-workbench/master/docs/install.md
```

只要 skill、不要改机器配置（安全模式）：

```text
帮我安装 codex-windows-workbench（安全模式）：https://raw.githubusercontent.com/yuanyuanyuan/codex-windows-workbench/master/docs/install.md
安装时只安装 skill，不要执行工作台 Apply；先用 -WhatIf 预览。
```

默认安装 + 应用 Core + Agent 工作台：

```text
帮我安装 codex-windows-workbench 并配置默认工作台：https://raw.githubusercontent.com/yuanyuanyuan/codex-windows-workbench/master/docs/install.md
先预览，确认后再 Apply Core + Agent。
```

源仓库：

```text
https://github.com/yuanyuanyuan/codex-windows-workbench
```

---

## For AI Agents

### Goal

Install the `codex-windows-workbench` skill, then optionally configure a native Windows PowerShell 7 Codex workbench.

Default workbench path after skill install:

1. Preflight
2. Preview (`-WhatIf`)
3. Ask user to confirm Apply
4. Apply **Core + Agent only**
5. Verify / Status
6. Report results

This skill maintains a Windows engineering workbench for Codex.  
It is not an auth tool, marketplace installer, or multi-agent SDK.

### Boundaries

Stay within these limits:

- **DO** install the skill into agent skill directories
- **DO** run the skill scripts with PowerShell 7 (`pwsh`)
- **DO** preview with `-WhatIf` before Apply when the user has not confirmed
- **DO NOT** use Windows PowerShell 5.1
- **DO NOT** use WSL, bash, apt, or brew
- **DO NOT** auto-login Codex
- **DO NOT** write tokens, MCP endpoints, secrets, cookies, or permission grants
- **DO NOT** run package uninstall during rollback
- **DO NOT** enable optional workloads (`-Developer`, `-NativeBuild`, `-Containers`, `-AgentClients`, `-EnableSafetyHooks`, `-Full`) unless the user explicitly asks
- **DO NOT** use `sudo` / elevation unless the user explicitly approves
- If elevated permissions or global environment changes are required, **tell the user** and wait

### Directory Rules

Keep skill files and managed workbench state out of the user's project workspace whenever possible.

| Purpose | Directory | Example |
|---------|-----------|---------|
| Preferred skill install (skills CLI) | `~/.agents/skills/codex-windows-workbench/` | `SKILL.md` |
| Codex manual skill path | `%USERPROFILE%\.codex\skills\codex-windows-workbench\` | `SKILL.md` |
| Claude manual skill path | `%USERPROFILE%\.claude\skills\codex-windows-workbench\` | `SKILL.md` |
| Managed workbench state | `%LOCALAPPDATA%\PwshAiAgent\state\` | sentinels, backups, logs |
| Runtime scripts | `<skill-root>\scripts\` | `Initialize-PwshAgentWindows.ps1` |

**Why?** Cloning or applying inside the user's current project pollutes the workspace. Prefer global/user skill directories.

### Host Preconditions

Before install, verify:

```powershell
pwsh -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString(); $IsWindows'
```

Required:

- Native Windows
- PowerShell 7+
- Network access for skill download / package install
- Prefer an existing `winget` for workbench Apply

If PowerShell 7 is missing, stop and tell the user to install PowerShell 7 first. Do not fall back to 5.1.

---

### Step 1: Install the skill

Choose the first method that works in the current host. Prefer **npx**.

#### Option A — npx (Recommended)

```powershell
npx --yes skills add yuanyuanyuan/codex-windows-workbench -g -y -s codex-windows-workbench
```

If the host only needs Codex:

```powershell
npx --yes skills add yuanyuanyuan/codex-windows-workbench -g -y -s codex-windows-workbench -a codex
```

Expected install root:

```text
%USERPROFILE%\.agents\skills\codex-windows-workbench
```

#### Option B — RedSkill

If the user is on RedSkill / asks for RedSkill, follow this install wording:

```text
现在为你安装 Skill，先来检查是否已安装 Red Skill 商店，请根据 https://redskill.xiaohongshu.net/install.md 安装 RedSkill 商店，然后安装 codex-windows-workbench 技能。若已安装，则直接安装 codex-windows-workbench 技能。
```

#### Option C — Plugin Marketplace

```text
/plugin marketplace add yuanyuanyuan/codex-windows-workbench
/plugin install codex-windows-workbench@codex-windows-workbench
```

#### Option D — Manual Git Clone

```powershell
# Codex
git clone https://github.com/yuanyuanyuan/codex-windows-workbench.git $env:USERPROFILE\.codex\skills\codex-windows-workbench

# Claude Code
git clone https://github.com/yuanyuanyuan/codex-windows-workbench.git $env:USERPROFILE\.claude\skills\codex-windows-workbench
```

#### Resolve skill root

After install, set `$SkillRoot` to the first existing path:

```powershell
$candidates = @(
  Join-Path $env:USERPROFILE '.agents\skills\codex-windows-workbench'
  Join-Path $env:USERPROFILE '.codex\skills\codex-windows-workbench'
  Join-Path $env:USERPROFILE '.claude\skills\codex-windows-workbench'
)
$SkillRoot = $candidates | Where-Object { Test-Path (Join-Path $_ 'SKILL.md') } | Select-Object -First 1
if (-not $SkillRoot) { throw 'codex-windows-workbench skill not found after install.' }
$Init = Join-Path $SkillRoot 'scripts\Initialize-PwshAgentWindows.ps1'
$Preflight = Join-Path $SkillRoot 'scripts\Preflight-PwshAgentWindows.ps1'
```

Verify skill files:

```powershell
Test-Path (Join-Path $SkillRoot 'SKILL.md')
Test-Path $Init
Test-Path $Preflight
```

If skill install succeeded and the user asked for **safe mode / skill only**, stop here and report:

```text
skill installed
skill root: <path>
next: codex-windows-workbench
```

---

### Step 2: Preflight the workbench

```powershell
pwsh -NoLogo -NoProfile -File $Preflight -Json
```

Interpret result:

- blockers / `FAIL` → fix or ask user
- warnings only → continue, report them
- all OK → continue

Do not Apply when preflight is blocked.

---

### Step 3: Preview default workbench plan

Always preview first unless the user already explicitly confirmed Apply in the same request.

```powershell
pwsh -NoLogo -NoProfile -File $Init -WhatIf -Json
```

Then tell the user, in plain language:

1. Skill is installed
2. Default plan is **Core + Agent only**
3. Optional workloads were not selected
4. Ask whether to Apply now

Suggested user prompt:

```text
预览完成。默认只会应用 Core + Agent。
要现在 Apply 吗？还是只要 skill / 只要预览？
如果你还要 Developer / NativeBuild / Containers / AgentClients / SafetyHooks，请明确说。
```

---

### Step 4: Apply default workbench (only after confirmation)

Default Apply:

```powershell
pwsh -NoLogo -NoProfile -File $Init -Json
```

Notes:

- Default = Core + Agent only
- May install packages through managed scripts / winget / scoop as implemented by the skill
- Does **not** auto-login Codex
- Does **not** write secrets

If the user asked only for skill install or safe mode, skip this step.

---

### Step 5: Verify and report

```powershell
pwsh -NoLogo -NoProfile -File $Init -Verify -Json
pwsh -NoLogo -NoProfile -File $Init -Status -Json
```

Report to the user:

- skill install path
- whether Apply ran
- verify/status summary
- remaining warnings
- how to invoke the skill next time

Invocation after install:

```text
codex-windows-workbench
```

```text
/codex-windows-workbench
```

---

### Optional workloads (explicit request only)

Only when the user clearly asks:

```powershell
pwsh -NoLogo -NoProfile -File $Init -Developer -Json
pwsh -NoLogo -NoProfile -File $Init -NativeBuild -Json
pwsh -NoLogo -NoProfile -File $Init -Containers -Json
pwsh -NoLogo -NoProfile -File $Init -AgentClients -Json
pwsh -NoLogo -NoProfile -File $Init -EnableSafetyHooks -Json
pwsh -NoLogo -NoProfile -File $Init -Full -Json
```

Public MVP note:

- `-AgentClients` supports **Codex only**
- Do not claim multi-agent client setup beyond Codex

---

### Rollback

Rollback restores managed settings/files only. It does **not** uninstall packages.

```powershell
pwsh -NoLogo -NoProfile -File $Init -Rollback -Json
```

Ask the user before rollback.

---

### Safe Mode

If the user says 安全模式 / safe mode / dry-run / 只安装 skill:

1. Install skill only
2. Run preflight if useful
3. Run `-WhatIf`
4. Do **not** Apply
5. Do **not** enable optional workloads
6. Return the preview and wait

---

### Failure Handling

When something fails:

1. Capture the command and exit code
2. Prefer JSON output (`-Json`) for diagnosis
3. Sanitize secrets, usernames, proxy endpoints, and absolute personal paths before showing logs
4. Retry only idempotent install steps that the skill already supports
5. If elevation, login, cookies, or secrets are required, stop and ask the user

Common failures:

| Symptom | What to do |
|---------|------------|
| PowerShell 5.1 only | Stop. Ask user to install PowerShell 7 |
| Not Windows / WSL | Stop. This skill is native Windows only |
| skill not found after install | Retry another install channel; verify `SKILL.md` path |
| winget missing during Apply | Report blocker; do not invent bash/apt/brew fallback |
| Codex not logged in | Expected. Tell user to login manually; never automate auth |
| Verify failed after Apply | Run `-Status -Json`, report failed phases, ask before retry/`-Force` |

---

### Final Check

Before finishing, confirm:

1. `SKILL.md` exists under a user skill directory
2. User knows how to call:
   - `codex-windows-workbench`
   - `/codex-windows-workbench`
3. If Apply ran, `-Verify` / `-Status` was executed
4. No secrets were written
5. No optional workload was enabled silently

Success message template:

```text
codex-windows-workbench 已安装。
Skill 路径: <SkillRoot>
工作台: <not applied | previewed | applied Core+Agent>
验证: <pass/fail/skipped>
以后直接调用: codex-windows-workbench 或 /codex-windows-workbench
```

---

## Quick Reference

| Action | Command |
|--------|---------|
| Install skill (npx) | `npx --yes skills add yuanyuanyuan/codex-windows-workbench -g -y -s codex-windows-workbench` |
| Plugin marketplace | `/plugin marketplace add yuanyuanyuan/codex-windows-workbench` then `/plugin install codex-windows-workbench@codex-windows-workbench` |
| Manual Codex clone | `git clone https://github.com/yuanyuanyuan/codex-windows-workbench.git %USERPROFILE%\.codex\skills\codex-windows-workbench` |
| Preflight | `pwsh -NoLogo -NoProfile -File .\scripts\Preflight-PwshAgentWindows.ps1 -Json` |
| Preview | `pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -WhatIf -Json` |
| Apply default | `pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Json` |
| Verify | `pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json` |
| Status | `pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Status -Json` |
| Rollback | `pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Rollback -Json` |

## Related

- Skill entry: [`SKILL.md`](../SKILL.md)
- English README: [`README.md`](../README.md)
- 中文 README: [`README.zh-CN.md`](../README.zh-CN.md)
- Contracts: [`references/contracts.md`](../references/contracts.md)
