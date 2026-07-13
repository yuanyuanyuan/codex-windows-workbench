# Stark Codex Windows Workbench

> 中文说明：[README.zh-CN.md](./README.zh-CN.md)

**Skill:** `stark-codex-windows-workbench`

给 Codex 一条直接入口，在**原生 Windows + PowerShell 7** 上安全地预检、预览、应用、验证并回滚托管工作台。  
默认路径：**Core + Agent**。不用 WSL。不自动登录。不写 secret。

## What This Skill Is For

`stark-codex-windows-workbench` 是面向 Codex 的 **原生 Windows PowerShell 7 workbench skill**。

它用来做这些事：

1. 安装 skill 本身
2. 预检机器是否可跑
3. 用 `-WhatIf` 预览 Core + Agent 会改什么
4. 显式 Apply 最小托管基线
5. 验证 / 查看状态
6. 仅回滚受管设置

一句话：让 Agent 在 Windows 上有一套可重复、可预览、可回滚的工作台，而不是一堆临时脚本。

## What Problem It Solves

在原生 Windows 上把 Codex 变成能做工程的状态，通常会踩这些坑：

- Agent 习惯性滑向 WSL / bash / `apt`，把 Windows 环境搞乱
- 安装路径散落在 winget、scoop、PATH、Profile 和各种临时脚本里
- 装包前没法安全预览“到底会改什么”
- 重复执行不稳定，出问题也不知道怎么回滚
- 安装文档夹杂登录/密钥步骤，容易被 Agent 过度自动化

这个 skill 把它们收敛成一条直接调用入口，并把边界写死：

- 只走原生 Windows + PowerShell 7
- 默认先预览，再确认 Apply
- 默认只做 Core + Agent
- 永不自动登录，不写 MCP/secret
- 回滚只恢复受管设置，不卸载软件包

## Why Use It

| 如果你现在是… | 这个 skill 让你变成… |
|---|---|
| 靠聊天指令和零散脚本搭环境 | 直接调用 skill 完成预检/预览/应用/验证 |
| 先装包再发现影响面 | 先 `-WhatIf`，确认后再 Apply |
| Windows 上仍被 WSL/bash 带偏 | 固定原生 Windows + PowerShell 7 路径 |
| 每台机器基线不一致 | 托管的 Core + Agent 默认路径 |
| 出问题只能猜着卸载 | 明确回滚受管设置，卸载 skill 也有固定步骤 |

## User Scenario Comparison

| | Before | After |
|---|---|---|
| Entry | Many ad-hoc scripts and chat instructions | Call `stark-codex-windows-workbench` / `/stark-codex-windows-workbench` |
| Host model | WSL/bash leakage, mixed shells | Native Windows + PowerShell 7 only |
| Change safety | Install first, discover impact later | `-WhatIf` preview, then explicit Apply |
| Baseline | Machine-specific tool soup | Managed Core + Agent default |
| Secrets | Bootstrap docs tempt token/login automation | Never auto-login; never write MCP/secrets |
| Recovery | Uninstall guesswork | Rollback managed settings only |
| Repeatability | “Works on my machine” | Idempotent phases + status/verify |

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

Use the Codex CLI in a terminal. This is **not** a chat `/plugin` slash command.

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

## Use

```text
stark-codex-windows-workbench
```

```text
/stark-codex-windows-workbench
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

If the skill is only under Codex/Claude skill dirs, replace the path with your installed skill root.

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

Real install + configure notes live here:

- [docs/uat-real-install-configure.md](./docs/uat-real-install-configure.md)

Observed on a native Windows host:

- skill discoverable via `npx skills add ... --list`
- skill install lands under `%USERPROFILE%\.agents\skills\stark-codex-windows-workbench`
- `-WhatIf -Json` returns `Changed=false` with `Selected=["Core","Agent"]`
- full package Apply is gated behind explicit user confirmation

One-command agent replay:

```text
按 docs/install.md 安装 stark-codex-windows-workbench；先 npx 安装 skill，再执行 -WhatIf -Json 预览 Core+Agent，把 Selected/Actions 报告给我确认后，才允许 -Confirm:$false Apply，最后跑 -Status/-Verify。
```

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
