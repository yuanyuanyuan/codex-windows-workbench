# Codex Windows Workbench

> 中文说明：[README.zh-CN.md](./README.zh-CN.md)

**Skill:** `codex-windows-workbench`

## Pain Points

On native Windows, getting Codex ready for real engineering work is usually messy:

- Agents fall back to WSL/bash/`apt` habits that do not belong on Windows
- Setup is scattered across winget, scoop, PATH, profile, and random one-off scripts
- You cannot safely preview what will change before packages land
- Re-running setup is not idempotent; rollback is unclear
- Auth/secrets get mixed into bootstrap docs and accidentally over-automated

## What This Skill Solves

`codex-windows-workbench` is a **native Windows PowerShell 7 workbench skill for Codex**.

It gives agents one direct entrypoint to:

1. Install the skill itself
2. Preflight the machine
3. Preview Core + Agent changes
4. Apply a minimal managed baseline
5. Verify / show status
6. Roll back managed settings only

Default path: **Core + Agent**. No WSL. No auth automation. No secret writes.

## Before / After

| | Before | After |
|---|---|---|
| Entry | Many ad-hoc scripts and chat instructions | Call `codex-windows-workbench` / `/codex-windows-workbench` |
| Host model | WSL/bash leakage, mixed shells | Native Windows + PowerShell 7 only |
| Change safety | Install first, discover impact later | `-WhatIf` preview, then explicit Apply |
| Baseline | Inconsistent machine-specific tool soup | Managed Core + Agent default |
| Secrets | Bootstrap docs tempt token/login automation | Never auto-login; never write MCP/secrets |
| Recovery | Uninstall guesswork | Rollback managed settings only |
| Repeatability | “Works on my machine” | Idempotent phases + status/verify |

## Install

Copy this to your Agent:

```text
帮我安装 codex-windows-workbench：https://raw.githubusercontent.com/yuanyuanyuan/codex-windows-workbench/master/docs/install.md
```

Full agent install guide: [docs/install.md](./docs/install.md)

### RedSkill

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
- `-AgentClients` (Codex presence/version probe only; does not install or login)
- `-EnableSafetyHooks`
- `-Full`

## Constraints

- Windows + PowerShell 7+ only
- No Windows PowerShell 5.1
- No WSL / bash / apt / brew
- No auth login automation
- No secret / MCP credential writes
- Rollback does not uninstall packages
- Apply requires `winget`
- Non-interactive Apply/Rollback should use `-Confirm:$false`

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
