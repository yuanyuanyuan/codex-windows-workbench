# Agent Content Pack

Modular taxonomy for workbench agent governance content.

Categories:

- `rules` — persistent instruction fragments
- `hooks` — shell/git safety hooks (opt-in)
- `skills` — reusable agent skills
- `commands` — slash/command templates
- `agents` — role definitions

Safety:

- Never silently install marketplace plugins.
- Never install remote MCP servers from this pack.
- Dangerous git hooks install only with `-EnableSafetyHooks`.
- Client-specific content stays under client-named subtrees when multi-client scaffolding exists.
- Public MVP client surface is Codex only.
