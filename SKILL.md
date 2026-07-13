---
name: codex-windows-workbench
description: Maintain a native Windows PowerShell 7 workbench for Codex. Use when auditing, previewing, configuring, installing, verifying, or rolling back a Windows AI agent environment without WSL; default Core+Agent path with optional Developer, NativeBuild, Containers, and Codex client checks.
---

# Codex Windows Workbench

## Invocation

```text
codex-windows-workbench
/codex-windows-workbench
```

## Role

Maintain a native Windows PowerShell 7 engineering workbench for Codex.
Not a multi-agent marketplace. Not an auth/login tool.

## Default workflow

1. Preview first when the user has not confirmed apply:
   ```powershell
   pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -WhatIf -Json
   ```
2. Apply Core + Agent only unless explicitly asked for more:
   ```powershell
   pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1
   ```
3. Verify / status / rollback on request:
   ```powershell
   pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json
   pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Status -Json
   pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Rollback
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

## Host constraints

- PowerShell 7+ only
- Native Windows only
- Never use WSL, bash, apt, or brew
- Public MVP supports Codex only

## Safety

- Never write tokens, MCP endpoints, or permission grants
- Never auto-login Codex
- Never uninstall packages during rollback
- Safety git hooks install only with `-EnableSafetyHooks`
- Keep diagnostics free of usernames, proxy secrets, and absolute personal paths

## References

- `references/contracts.md`
- `docs/windows-agent-env.md`
- `CONTEXT.md`

- `docs/install.md` — agent-executable install guide

