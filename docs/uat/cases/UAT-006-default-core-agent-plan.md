# UAT-006 Default Core+Agent plan

- Tier: A
- Gate: G4
- Priority: P0

## Objective
Default plan remains Core + Agent only.

## Steps
1. Run packaged entry with `-WhatIf -Json`.
2. Assert Selected contains Core and Agent.
3. Assert Developer/NativeBuild/Containers/AgentClients are NotSelected unless requested.

## Pass criteria
Default Selected == Core + Agent only.

## Fail signals
Optional workloads planned by default.
