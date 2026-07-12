---
name: windows-pwsh-agent-workbench
description: Maintain a native Windows PowerShell 7 Codex workbench. Use when auditing, previewing, configuring, installing, verifying, or rolling back a Windows AI agent environment without WSL; supports Core+Agent by default and optional Developer/NativeBuild/Containers/AgentClients.
---

# Windows PowerShell 7 Codex Workbench Skill

## Role

You are operating the **Workbench Skill** for a native Windows PowerShell 7 Codex workbench.

This package maintains a workbench; it is not a generic installer FAQ and not a multi-agent marketplace.

## When to use

Use this skill when the user wants to:

- bootstrap or repair a Windows Codex/AI agent shell
- preview what the workbench would change
- verify required tools and phase status
- roll back workbench-managed settings
- prepare a portable workbench baseline without copying secrets

## Host constraints

- PowerShell 7+ only
- Native Windows only
- Never use WSL, bash, apt, or brew
- Public MVP supports Codex only

## Default workflow

1. Prefer preview first:
   ```powershell
   pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -WhatIf -Json
   ```
2. Apply Codex Base (Core + Agent) only unless the user explicitly opts into more:
   ```powershell
   pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1
   ```
3. Verify / report status:
   ```powershell
   pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json
   pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Status -Json
   ```

## Optional workloads

Only when explicitly requested:

```powershell
.\scripts\Initialize-PwshAgentWindows.ps1 -Developer
.\scripts\Initialize-PwshAgentWindows.ps1 -NativeBuild
.\scripts\Initialize-PwshAgentWindows.ps1 -Containers
.\scripts\Initialize-PwshAgentWindows.ps1 -AgentClients
.\scripts\Initialize-PwshAgentWindows.ps1 -EnableSafetyHooks
.\scripts\Initialize-PwshAgentWindows.ps1 -Full
```

## Safety

- Never write tokens, MCP endpoints, or permission grants
- Never auto-login Codex
- Never uninstall packages during rollback
- Safety git hooks install only with `-EnableSafetyHooks`
- Keep diagnostics free of usernames, proxy secrets, and absolute personal paths

## References

- Detailed contracts: `references/contracts.md`
- Operator notes: `docs/windows-agent-env.md`
- Domain language: `CONTEXT.md`
