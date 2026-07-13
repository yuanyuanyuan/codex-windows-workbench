# Stark Codex Windows Workbench

> English README: [README.md](./README.md)

**Skill：** `stark-codex-windows-workbench`

## 痛点

在原生 Windows 上，想让 Codex 真正能做工程，常见情况是：

- Agent 习惯性滑向 WSL / bash / `apt`，把 Windows 环境搞乱
- 安装路径分散在 winget、scoop、PATH、Profile 和各种临时脚本里
- 没法在装包前安全预览“到底会改什么”
- 重复执行不稳定，出问题也不知道怎么回滚
- 安装文档里夹杂登录/密钥步骤，容易被 Agent 过度自动化

## 这个 Skill 解决什么

`stark-codex-windows-workbench` 是面向 Codex 的 **原生 Windows PowerShell 7 工作台 skill**。

它给 Agent 一个直接入口，用来：

1. 安装 skill 本身
2. 预检机器
3. 预览 Core + Agent 变更
4. 应用最小托管基线
5. 验证 / 查看状态
6. 仅回滚受管设置

默认路径：**Core + Agent**。不用 WSL。不自动登录。不写 secret。

## Before / After

| | Before | After |
|---|---|---|
| 入口 | 一堆临时脚本和聊天指令 | 直接调用 `stark-codex-windows-workbench` / `/stark-codex-windows-workbench` |
| 宿主模型 | WSL/bash 渗透、shell 混用 | 仅原生 Windows + PowerShell 7 |
| 变更安全 | 先装再看影响 | 先 `-WhatIf` 预览，再显式 Apply |
| 基线 | 机器各自为政 | 托管的 Core + Agent 默认路径 |
| 密钥 | 安装文档诱导自动登录/写 token | 永不自动登录，不写 MCP/secrets |
| 恢复 | 靠猜卸载 | 仅回滚受管设置 |
| 可重复 | “我这能跑” | 幂等 phase + status/verify |

## 执行过程与效果

调用 skill 后，实际会按这条链路跑：

```text
调用 skill
  -> 定位脚本
  -> 预检 Preflight
  -> 默认先 WhatIf 预览
  -> 你确认
  -> Apply Core + Agent
  -> 应用后冒烟验证
  -> 需要时再 Status / Verify / Rollback
```

| 步骤 | 实际执行 | 对机器的影响 | 你能看到什么 |
|------|----------|--------------|--------------|
| 1. 调用 skill | `stark-codex-windows-workbench` / `/stark-codex-windows-workbench` | 还不动机器 | Agent 载入 skill 指令 |
| 2. 预检 | `Preflight-PwshAgentWindows.ps1 -Json` | 只读检查 | 宿主/工具阻断项与警告 |
| 3. 预览 | `Initialize-...ps1 -WhatIf -Json` | **不改动**（`Changed=false`） | `Selected`、`Phases`、`Actions`、`SafetyHooks` |
| 4. 确认 | Agent 向你确认 | 不改动 | 清楚说明 Core + Agent 影响 |
| 5. 应用 | `Initialize-...ps1 -Confirm:$false -Json` | 安装基线工具 + 托管 overlay | 各 phase 结果 + 冒烟验证 |
| 6. 验证/状态 | `-Verify` / `-Status` | 只读 | 通过/失败与 phase 完成情况 |
| 7. 回滚 | `-Rollback -Confirm:$false` | 只恢复受管设置 | 已装软件包不会被卸载 |

### 默认 Apply 会带来什么（Core + Agent）

**Core**

- 用 winget-configure 应用 `config/windows-agent-core.winget` 基线包
- 如需则 bootstrap scoop
- 安装常用 CLI：`ripgrep fd fzf jq bat delta yq 7zip zip nuget`
- 部分包可能需要提权

**Agent**

- 写入托管 PowerShell overlay 到 `%USERPROFILE%\.config\pwsh-ai`
- 创建托管 agent 目录（hooks/mcp/skills/...）
- 在 `%LOCALAPPDATA%\PwshAiAgent\state` 记录受管状态

**默认一定不会发生**

- 不用 WSL / bash / apt / brew
- 不自动登录 Codex
- 不写 secret / MCP 凭据
- 不启用 Developer / NativeBuild / Containers（除非你明确要求）
- 回滚不会卸载软件包

### 预览输出长什么样

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

怎么读：

- 以 `Selected` + `Actions` 为准
- `Planned` = 会执行
- `NotSelected` = 不会执行
- `Changed=false` = 预览没有改机器

## UAT：真实安装与配置过程

这一节记录的是原生 Windows 上的真实验收路径，不是理论清单。
下面命令都真实执行过，并记录了观察到的结果。

### 本次 UAT 范围

| 阶段 | 是否真实执行 | 说明 |
|------|--------------|------|
| 宿主预检 | 是 | 确认 Windows + PowerShell 7 + winget/npx |
| Skill 发现（`npx skills add --list`） | 是 | 确认包可被发现 |
| Skill 安装到用户 skill 目录 | 是 | 确认落到 `%USERPROFILE%\.agents\skills\...` |
| Skill/plugin 结构校验 | 是 | 确认清单合法 |
| 工作台预览（`-WhatIf -Json`） | 是 | 确认 Core+Agent 计划且无改动 |
| 完整包 Apply（winget/scoop 安装） | 记录标准流程 | 耗时长/有副作用，需用户确认后执行 |
| Apply 后 verify/status | 记录标准流程 | 真实 Apply 后执行 |

### 观察到的宿主

```text
OS: Windows
PowerShell: 7.5.8
winget: available
npx: available
```

### 阶段 A — 安装 skill（真实执行）

1. 从仓库/包发现 skill：

```bash
npx --yes skills add yuanyuanyuan/stark-codex-windows-workbench --list -y
```

观察到：

```text
Found 1 skill
stark-codex-windows-workbench
```

2. 全局安装 skill（Codex）：

```bash
npx --yes skills add yuanyuanyuan/stark-codex-windows-workbench -g -y -s stark-codex-windows-workbench -a codex --copy
```

观察到的安装位置：

```text
%USERPROFILE%\.agents\skills\stark-codex-windows-workbench
SKILL.md = present
scripts\Initialize-PwshAgentWindows.ps1 = present
```

3. 校验包结构：

```text
Skill is valid!
Plugin validation passed
```

### 阶段 B — 配置/预览工作台（真实执行）

在 skill/仓库根目录执行：

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -WhatIf -Json
```

观察到的结果（已脱敏）：

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

这次真实预览说明：

- 机器**没有被修改**（`Changed=false`）
- 默认只选中 **Core + Agent**
- Developer/NativeBuild/Containers/AgentClients 都是 `NotSelected`
- 除非显式要求，否则不启用 SafetyHooks

### 阶段 C — 应用配置（真实流程）

只有用户确认预览后才执行：

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Confirm:$false -Json
```

真实 Apply 会做什么：

1. 先跑 preflight；有 blocker 直接失败
2. 应用 **Core**
   - `winget configure` 使用 `config/windows-agent-core.winget`
   - 如需则 bootstrap scoop
   - 安装 CLI：`ripgrep fd fzf jq bat delta yq 7zip zip nuget`
3. 应用 **Agent**
   - 写托管 overlay 到 `%USERPROFILE%\.config\pwsh-ai`
   - 创建托管 agent 目录
   - 在 `%LOCALAPPDATA%\PwshAiAgent\state` 记录受管状态
4. 自动跑 post-apply 冒烟验证
5. 返回 phase 结果 + `PostApplyVerification` JSON

然后复查：

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Status -Json
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json
```

### 阶段 D — UAT 验收标准

| 检查项 | 期望真实结果 |
|--------|--------------|
| Skill 可发现 | `Found 1 skill: stark-codex-windows-workbench` |
| Skill 已安装 | 用户 skill 目录下有 `SKILL.md` + 初始化脚本 |
| 预览安全 | `-WhatIf` 返回 `Changed=false` |
| 默认选择 | 仅 `Selected=["Core","Agent"]` |
| 可选 workload 未误开 | Developer/NativeBuild/Containers/AgentClients = `NotSelected` |
| 无 WSL 路径 | plan 中无 wsl/bash/apt/brew |
| 无认证自动化 | 不写 login/token/MCP secret |
| Apply 受控 | 需用户确认；无人值守使用 `-Confirm:$false` |
| 验证路径可用 | `-Status` / `-Verify` 返回可解析 JSON |

### 给 Agent 的一句话复现

```text
按 docs/install.md 安装 stark-codex-windows-workbench；先 npx 安装 skill，再执行 -WhatIf -Json 预览 Core+Agent，把 Selected/Actions 报告给我确认后，才允许 -Confirm:$false Apply，最后跑 -Status/-Verify。
```

完整记录见：[docs/uat-real-install-configure.md](./docs/uat-real-install-configure.md)

## 安装

把下面这段发给你的 Agent：

```text
帮我安装 stark-codex-windows-workbench：https://raw.githubusercontent.com/yuanyuanyuan/stark-codex-windows-workbench/master/docs/install.md
```

完整 Agent 安装文档：[docs/install.md](./docs/install.md)

### RedSkill

```text
现在为你安装 Skill，先来检查是否已安装 Red Skill 商店，请根据 https://redskill.xiaohongshu.net/install.md 安装 RedSkill 商店，然后安装 stark-codex-windows-workbench 技能。若已安装，则直接安装 stark-codex-windows-workbench 技能。
```

### npx（推荐）

```bash
npx skills add yuanyuanyuan/stark-codex-windows-workbench
```

### Codex Plugin CLI


在终端使用 Codex CLI。这不是聊天里的 `/plugin` 斜杠命令。

```bash
codex plugin marketplace add yuanyuanyuan/stark-codex-windows-workbench
codex plugin add stark-codex-windows-workbench@stark-codex-windows-workbench
```

### 手动安装（Git Clone）

```bash
# Windows + Codex
git clone https://github.com/yuanyuanyuan/stark-codex-windows-workbench.git %USERPROFILE%\.codex\skills\stark-codex-windows-workbench

# Windows + Claude Code
git clone https://github.com/yuanyuanyuan/stark-codex-windows-workbench.git %USERPROFILE%\.claude\skills\stark-codex-windows-workbench
```

## 使用

```text
stark-codex-windows-workbench
```

```text
/stark-codex-windows-workbench
```

## 能做什么

- 审计 / 预检
- 预览（`-WhatIf`）
- 默认应用 Core + Agent
- 验证 / 状态
- 仅回滚受管设置

可选显式 workload：

- `-Developer`
- `-NativeBuild`
- `-Containers`
- `-AgentClients`（仅探测 Codex 是否存在/版本；不安装、不登录）
- `-EnableSafetyHooks`
- `-Full`

## 约束

- 仅 Windows + PowerShell 7+
- 不支持 Windows PowerShell 5.1
- 不使用 WSL / bash / apt / brew
- 不自动登录
- 不写 secret / MCP 凭据
- 回滚不卸载软件包
- Apply 需要 `winget`
- 非交互 Apply/Rollback 应使用 `-Confirm:$false`

## 包结构

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

## 许可证

MIT — 见 [LICENSE](./LICENSE)。



