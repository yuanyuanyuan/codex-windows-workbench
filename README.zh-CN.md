# Codex Windows Workbench

> English README: [README.md](./README.md)

**Skill：** `codex-windows-workbench`

## 痛点

在原生 Windows 上，想让 Codex 真正能做工程，常见情况是：

- Agent 习惯性滑向 WSL / bash / `apt`，把 Windows 环境搞乱
- 安装路径分散在 winget、scoop、PATH、Profile 和各种临时脚本里
- 没法在装包前安全预览“到底会改什么”
- 重复执行不稳定，出问题也不知道怎么回滚
- 安装文档里夹杂登录/密钥步骤，容易被 Agent 过度自动化

## 这个 Skill 解决什么

`codex-windows-workbench` 是面向 Codex 的 **原生 Windows PowerShell 7 工作台 skill**。

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
| 入口 | 一堆临时脚本和聊天指令 | 直接调用 `codex-windows-workbench` / `/codex-windows-workbench` |
| 宿主模型 | WSL/bash 渗透、shell 混用 | 仅原生 Windows + PowerShell 7 |
| 变更安全 | 先装再看影响 | 先 `-WhatIf` 预览，再显式 Apply |
| 基线 | 机器各自为政 | 托管的 Core + Agent 默认路径 |
| 密钥 | 安装文档诱导自动登录/写 token | 永不自动登录，不写 MCP/secrets |
| 恢复 | 靠猜卸载 | 仅回滚受管设置 |
| 可重复 | “我这能跑” | 幂等 phase + status/verify |

## 安装

把下面这段发给你的 Agent：

```text
帮我安装 codex-windows-workbench：https://raw.githubusercontent.com/yuanyuanyuan/codex-windows-workbench/master/docs/install.md
```

完整 Agent 安装文档：[docs/install.md](./docs/install.md)

### RedSkill

```text
现在为你安装 Skill，先来检查是否已安装 Red Skill 商店，请根据 https://redskill.xiaohongshu.net/install.md 安装 RedSkill 商店，然后安装 codex-windows-workbench 技能。若已安装，则直接安装 codex-windows-workbench 技能。
```

### npx（推荐）

```bash
npx skills add yuanyuanyuan/codex-windows-workbench
```

### Plugin Marketplace

```text
/plugin marketplace add yuanyuanyuan/codex-windows-workbench
/plugin install codex-windows-workbench@codex-windows-workbench
```

### 手动安装（Git Clone）

```bash
# Windows + Codex
git clone https://github.com/yuanyuanyuan/codex-windows-workbench.git %USERPROFILE%\.codex\skills\codex-windows-workbench

# Windows + Claude Code
git clone https://github.com/yuanyuanyuan/codex-windows-workbench.git %USERPROFILE%\.claude\skills\codex-windows-workbench
```

## 使用

```text
codex-windows-workbench
```

```text
/codex-windows-workbench
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
