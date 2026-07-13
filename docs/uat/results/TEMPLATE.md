# UAT Result Template

- Date:
- Commit:
- Operator:
- Host: Windows + PowerShell
- Command:
- Tier: A / A+B / A+B+C
- Overall: PASS / FAIL

## Case results

| Case ID | Title | Result | Notes |
|---|---|---|---|
| UAT-001 | Package layout |  |  |
| UAT-002 | Identity consistency |  |  |
| UAT-003 | Required package files |  |  |
| UAT-004 | Simulated install completeness |  |  |
| UAT-005 | Runtime from packaged path |  |  |
| UAT-006 | Default Core+Agent |  |  |
| UAT-007 | No WSL-like actions |  |  |
| UAT-008 | Summary/Impact |  |  |
| UAT-009 | Contract unit tests |  |  |
| UAT-010 | Docs/install path correctness |  |  |
| UAT-011 | No chat `/plugin` install path |  |  |
| UAT-012 | npx discovery (network) |  |  |
| UAT-013 | npx install completeness (network) |  |  |

## Product tree checks

```text
SkillDir=
SKILL.md=
scripts/Initialize-PwshAgentWindows.ps1=
config/windows-agent-core.winget=
agents/openai.yaml=
```

## WhatIf snapshot (sanitized)

```json
{
  "Mode": "WhatIf",
  "Selected": ["Core", "Agent"],
  "Changed": false
}
```

## Follow-ups

-
