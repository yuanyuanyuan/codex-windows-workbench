# Codex Windows Workbench

> English README: [README.md](./README.md)

**Skill：** `codex-windows-workbench`

面向 Codex 的原生 Windows PowerShell 7 工作台 skill。  
默认路径：**Core + Agent**。不使用 WSL。

## 安装

### RedSkill

把下面这段发给你的 Agent：

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
- `-AgentClients`（公开 MVP：仅 Codex）
- `-EnableSafetyHooks`
- `-Full`

## 约束

- 仅 Windows + PowerShell 7+
- 不支持 Windows PowerShell 5.1
- 不使用 WSL / bash / apt / brew
- 不自动登录
- 不写 secret / MCP 凭据
- 回滚不卸载软件包

## 包结构

```text
SKILL.md
agents/openai.yaml
.codex-plugin/plugin.json
.claude-plugin/plugin.json
package.json
scripts/
config/
references/
docs/
```

## 许可证

MIT — 见 [LICENSE](./LICENSE)。
