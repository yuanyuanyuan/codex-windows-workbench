# UAT-002 Identity consistency

- Tier: A
- Gate: G6
- Priority: P0

## Objective
Skill name, package folder, plugin manifests, and package.json stay aligned on `stark-codex-windows-workbench`.

## Steps
1. Read skill frontmatter name from `skills/.../SKILL.md`.
2. Read `.codex-plugin/plugin.json` name.
3. Read `.claude-plugin/plugin.json` name if present.
4. Read `package.json` name.
5. Compare to canonical identity.

## Pass criteria
All names equal `stark-codex-windows-workbench`.

## Fail signals
- Old names like `codex-windows-workbench` or `windows-pwsh-agent-workbench`
- Folder/name mismatch
