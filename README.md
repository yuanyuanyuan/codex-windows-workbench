# Codex Windows Workbench

> 中文说明：[README.zh-CN.md](./README.zh-CN.md)

**Skill:** `codex-windows-workbench`

Native Windows PowerShell 7 workbench skill for Codex.  
Default path: **Core + Agent**. No WSL.

## Install

### RedSkill

Copy this to your Agent:

```text
现在为你安装 Skill，先来检查是否已安装 Red Skill 商店，请根据 https://redskill.xiaohongshu.net/install.md 安装 RedSkill 商店，然后安装 codex-windows-workbench 技能。若已安装，则直接安装 codex-windows-workbench 技能。
```

### npx (Recommended)

```bash
npx skills add yuanyuanyuan/codex-windows-workbench
```

### Plugin Marketplace

```text
/plugin marketplace add yuanyuanyuan/codex-windows-workbench
/plugin install codex-windows-workbench@codex-windows-workbench
```

### Manual (Git Clone)

```bash
# Windows + Codex
git clone https://github.com/yuanyuanyuan/codex-windows-workbench.git %USERPROFILE%\.codex\skills\codex-windows-workbench

# Windows + Claude Code
git clone https://github.com/yuanyuanyuan/codex-windows-workbench.git %USERPROFILE%\.claude\skills\codex-windows-workbench
```

## Use

```text
codex-windows-workbench
```

```text
/codex-windows-workbench
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
