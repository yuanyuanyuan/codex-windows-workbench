# UAT Result

- Date: 2026-07-13
- Commit: local-uncommitted (regression suite introduced)
- Operator: agent
- Host: Windows + PowerShell 7.5.8
- Command: `pwsh -NoLogo -NoProfile -File .\tests\uat\Invoke-UatRegression.ps1`
- Tier: A
- Overall: PASS

## Case results

| Case ID | Title | Result | Notes |
|---|---|---|---|
| UAT-001 | Package layout | PASS | skills/stark-codex-windows-workbench layout OK |
| UAT-002 | Identity consistency | PASS | identity=stark-codex-windows-workbench |
| UAT-003 | Required package files | PASS | 6 required files present |
| UAT-004 | Simulated install product completeness | PASS | files=26 |
| UAT-005 | Runtime from packaged path | PASS | packaged entry WhatIf OK |
| UAT-006 | Default Core+Agent | PASS | Selected=Core,Agent |
| UAT-007 | No WSL-like actions | PASS | default+full clean |
| UAT-008 | Summary/Impact | PASS | summaryLines=49 |
| UAT-009 | Contract unit tests | PASS | Initialize+AgentClients passed |
| UAT-010 | Docs/install path correctness | PASS | README + install.md OK |
| UAT-011 | No chat `/plugin` install path | PASS | no invalid chat /plugin install commands |
| UAT-012 | npx discovery (network) | SKIP | Tier B not requested |
| UAT-013 | npx install completeness (network) | SKIP | Tier B not requested |

## Product tree checks

```text
SkillDir=skills/stark-codex-windows-workbench
SKILL.md=true
scripts/Initialize-PwshAgentWindows.ps1=true
config/windows-agent-core.winget=true
agents/openai.yaml=true
```

## Follow-ups

- Run `-IncludeNetwork` before publish claims that depend on npx packaging.
