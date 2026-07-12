# Codex Windows Workbench

> 中文说明：[README.zh-CN.md](./README.zh-CN.md)

**Skill:** `codex-windows-workbench`

Native Windows PowerShell 7 workbench skill for Codex.  
Default path: **Core + Agent**. No WSL.

## Install

Copy this to your Agent:

```text
现在为你安装 Skill，先来检查是否已安装 Red Skill 商店。
请根据 https://redskill.xiaohongshu.net/install.md 安装 RedSkill 商店，然后安装 codex-windows-workbench 技能。
若已安装 RedSkill，则直接安装 codex-windows-workbench 技能。
```

CLI equivalent after RedSkill is available:

```bash
redskill install codex-windows-workbench
```

Source repository (distribution only):

```text
https://github.com/yuanyuanyuan/windows-pwsh-agent-workbench
```

## Use

Directly call:

```text
codex-windows-workbench
```

or:

```text
/codex-windows-workbench
```

Examples:

```text
codex-windows-workbench 预览默认安装
/codex-windows-workbench 只做 Core + Agent 并验证
codex-windows-workbench status
/codex-windows-workbench rollback
```

No keyword hunting. Call the skill name directly.

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
- `-AgentClients` (public MVP: Codex only)
- `-EnableSafetyHooks`
- `-Full`

## Constraints

- Windows + PowerShell 7+ only
- No Windows PowerShell 5.1
- No WSL / bash / apt / brew
- No auth login automation
- No secret / MCP credential writes
- Rollback does not uninstall packages

## Package

```text
SKILL.md
agents/openai.yaml
scripts/
config/
references/
docs/
```

## License

MIT — see [LICENSE](./LICENSE).
