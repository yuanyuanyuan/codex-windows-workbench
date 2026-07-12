# Use fnm for Node runtime management

The Codex Workbench MVP will install and initialize fnm, then use its user-scoped Node runtime instead of installing a system-wide Node LTS package. This keeps Node version selection explicit and isolated from existing system Node or competing version-manager state while supporting repeatable Codex CLI setup.
