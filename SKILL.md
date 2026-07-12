---
name: windows-pwsh-agent-workbench
description: Initialize and maintain a native Windows PowerShell 7 Codex workbench (Core + Agent by default; optional Developer/NativeBuild/Containers/AgentClients). Use when setting up or verifying a Windows AI agent environment without WSL.
---

# Windows PowerShell 7 Codex Workbench

## When to use

Use this skill to bootstrap or maintain a native Windows PowerShell 7 workbench for Codex.

## Host constraints

- PowerShell 7+ only
- Native Windows only
- Never use WSL, bash, apt, or brew

## Default path

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -WhatIf -Json
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json
```

Default installs **Core + Agent** only and auto-runs smoke verification after apply.

## Optional workloads

```powershell
.\scripts\Initialize-PwshAgentWindows.ps1 -Developer
.\scripts\Initialize-PwshAgentWindows.ps1 -NativeBuild
.\scripts\Initialize-PwshAgentWindows.ps1 -Containers
.\scripts\Initialize-PwshAgentWindows.ps1 -AgentClients
.\scripts\Initialize-PwshAgentWindows.ps1 -EnableSafetyHooks
.\scripts\Initialize-PwshAgentWindows.ps1 -Full
```

## Ops

```powershell
.\scripts\Preflight-PwshAgentWindows.ps1 -Json
.\scripts\Initialize-PwshAgentWindows.ps1 -Status -Json
.\scripts\Initialize-PwshAgentWindows.ps1 -Rollback
```

## Safety

- No secrets, tokens, MCP endpoints, or permission grants are written by AgentClients.
- Safety git hooks install only with `-EnableSafetyHooks`.
- Rollback restores managed files/settings only; packages are never uninstalled.
- Public MVP supports Codex only.
