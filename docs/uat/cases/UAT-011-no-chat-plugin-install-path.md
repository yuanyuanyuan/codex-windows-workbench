# UAT-011 No chat `/plugin` install path

- Tier: A
- Gate: G7
- Priority: P0

## Objective
Docs must not instruct users to use chat slash `/plugin ...`, which Codex rejects.

## Steps
1. Scan README / install docs for invalid chat patterns like bare `/plugin marketplace add`.
2. Assert official plugin path uses `codex plugin ...` CLI form when documented.

## Pass criteria
No invalid chat `/plugin` install instructions remain.

## Fail signals
Docs include commands that produce:

```text
Unrecognized command '/plugin'
```
