# UAT-009 Contract unit tests

- Tier: A
- Gate: G8
- Priority: P0

## Objective
Existing script contract suites still pass from packaged scripts path.

## Steps
1. Run `skills/.../scripts/Test-InitializePwshAgentWindows.ps1`
2. Run `skills/.../scripts/Test-AgentClients.ps1`

## Pass criteria
Both exit 0.

## Fail signals
Contract assertion failure or path breakage.
