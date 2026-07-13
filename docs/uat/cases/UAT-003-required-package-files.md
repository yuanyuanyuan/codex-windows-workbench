# UAT-003 Required package files

- Tier: A
- Gate: G2
- Priority: P0

## Objective
Source skill package contains the minimum product files users need after install.

## Required files
- `SKILL.md`
- `scripts/Initialize-PwshAgentWindows.ps1`
- `scripts/Private/PwshAiAgent.Phases.ps1`
- `scripts/Private/PwshAiAgent.State.ps1`
- `config/windows-agent-core.winget`
- `agents/openai.yaml`

## Pass criteria
Every required file exists in the skill package.

## Fail signals
Any required path missing in source package.
