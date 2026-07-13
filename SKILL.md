---
name: stark-codex-windows-workbench
description: Maintain a native Windows PowerShell 7 workbench for Codex. Use when auditing, previewing, configuring, installing, verifying, or rolling back a Windows AI agent environment without WSL; default Core+Agent path with optional Developer, NativeBuild, Containers, Codex presence checks, and safety hooks.
---

# Stark Codex Windows Workbench

## Invocation

```text
stark-codex-windows-workbench
/stark-codex-windows-workbench
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
   pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Confirm:$false -Json
   ```
3. Verify / status / rollback on request:
   ```powershell
   pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json
   pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Status -Json
   pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Rollback -Confirm:$false -Json
   ```

## Execution effects

Default call should feel like:

1. Preview plan (`-WhatIf`) → no machine changes
2. User confirms
3. Apply Core + Agent (`-Confirm:$false`) → packages + managed overlay
4. Automatic post-apply smoke verification
5. Optional `-Status` / `-Verify` / `-Rollback`

Report phase results and whether anything was `NotSelected`.

## Optional workloads

Only when explicitly requested:

```powershell
.\scripts\Initialize-PwshAgentWindows.ps1 -Developer -Confirm:$false -Json
.\scripts\Initialize-PwshAgentWindows.ps1 -NativeBuild -Confirm:$false -Json
.\scripts\Initialize-PwshAgentWindows.ps1 -Containers -Confirm:$false -Json
.\scripts\Initialize-PwshAgentWindows.ps1 -AgentClients -Confirm:$false -Json   # Codex probe only
.\scripts\Initialize-PwshAgentWindows.ps1 -EnableSafetyHooks -Confirm:$false -Json
.\scripts\Initialize-PwshAgentWindows.ps1 -Full -Confirm:$false -Json
```

## Host constraints

- PowerShell 7+ only
- Native Windows only
- Never use WSL, bash, apt, or brew
- Public MVP supports Codex only
- Apply requires winget

## Safety

- Never write tokens, MCP endpoints, or permission grants
- Never auto-login Codex
- Never uninstall packages during rollback
- Safety git hooks install only with `-EnableSafetyHooks` or `-Full`
- Keep diagnostics free of usernames, proxy secrets, and absolute personal paths

## References

- `docs/install.md` — agent-executable install guide
- `references/contracts.md`
- `docs/windows-agent-env.md`
- `CONTEXT.md`


