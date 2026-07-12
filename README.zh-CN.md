# Codex Windows Workbench

> English README: [README.md](./README.md)

**Skill：** `codex-windows-workbench`

面向 Codex 的原生 Windows PowerShell 7 工作台 skill。  
默认路径：**Core + Agent**。不使用 WSL。

## 安装

把下面这段发给你的 Agent：

```text
现在为你安装 Skill，先来检查是否已安装 Red Skill 商店。
请根据 https://redskill.xiaohongshu.net/install.md 安装 RedSkill 商店，然后安装 codex-windows-workbench 技能。
若已安装 RedSkill，则直接安装 codex-windows-workbench 技能。
```

已有 RedSkill 时，也可直接：

```bash
redskill install codex-windows-workbench
```

源仓库（仅分发）：

```text
https://github.com/yuanyuanyuan/windows-pwsh-agent-workbench
```

## 使用

直接调用：

```text
codex-windows-workbench
```

或：

```text
/codex-windows-workbench
```

示例：

```text
codex-windows-workbench 预览默认安装
/codex-windows-workbench 只做 Core + Agent 并验证
codex-windows-workbench status
/codex-windows-workbench rollback
```

不要靠触发词碰运气，直接调用 skill 名。

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
scripts/
config/
references/
docs/
```

## 许可证

MIT — 见 [LICENSE](./LICENSE)。
