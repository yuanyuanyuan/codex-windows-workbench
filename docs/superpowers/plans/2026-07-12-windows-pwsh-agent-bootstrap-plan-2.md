# Windows PowerShell 7 AI Agent 工作台方案

> **面向 Agent Worker：** 实施本方案时，必须使用 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans`，逐项执行任务。所有步骤使用 checkbox（`- [ ]`）跟踪。

**目标：** 构建一个可重复执行的原生 Windows PowerShell 7 初始化器，优先准备现有的 Node/fnm/Codex 工作站，安装经过验证的 AI Agent 开发基础环境，并将 Developer、NativeBuild、Containers 等重量级能力作为显式阶段提供。

**架构：** 使用 `winget configure`/DSC 作为 Windows 应用的声明式安装层，使用 Scoop 作为用户级 CLI 工具层，使用 PowerShell 脚本负责编排、Profile、状态、验证和回滚。默认路径为 Core + Agent；Developer、NativeBuild、Containers 和 AgentClients 都必须显式启用。现有配置采用增量修改，变更前先备份。

**技术栈：** PowerShell 7.5+、WinGet 1.29+、WinGet Configuration/DSC v3、Scoop、fnm、Node.js LTS、Python/uv、Go、Git、Codex CLI、Windows Terminal、VS Code、Pester、PSScriptAnalyzer。

---

## 1. 固定决策

- 支持的 Shell：仅 PowerShell 7。检测到 Windows PowerShell 5.1 时直接拒绝执行。
- 支持的平台：仅原生 Windows。
- 永不调用 WSL、`bash`、`sh`、`apt`、`brew` 或 Linux package manager。
- 保留现有 Node 决策：由 `fnm` 管理 Node，默认 Node 版本为 `24.18.0` LTS。
- 保留现有 Codex 决策：优先使用 `%LOCALAPPDATA%\OpenAI\Codex\bin`，不使用 WindowsApps 内部路径。
- 保留现有编码决策：UTF-8、PlainText 输出、Windows Terminal 使用 `JetBrainsMono NFM`。
- 保留现有网络决策：Proxy 使用用户级设置，仓库中不保存凭据。
- PATH 必须使用精确条目匹配和去重；禁止用子字符串匹配删除 PATH。
- 默认不覆盖已有 Profile、Agent 设置、MCP 配置、权限或 Secrets。
- 默认不安装完整的 Claude/Agent plugin marketplace。
- 默认不复制第三方 MCP credentials 或 remote endpoints。
- Package 安装成功与 Runtime 可用是两个独立事实；Docker CLI 可用不代表 Docker daemon 可用。

## 2. 当前需要保留的状态

已有记录和配置决策：

- `2026-07-12-powershell-node-codex-env.md`：fnm、Node 24.18.0、Codex PATH、Corepack、旧 NVM 清理、Profile 幂等性。
- `2026-07-12-powershell-terminal-font-encoding-fix.md`：UTF-8 验证和 Windows Terminal 字体修复。
- `config/pwsh-ai-agent-overlay.ps1`：输出规范化、Proxy、Go 默认值、PATH 来源、path doctor。
- `scripts/Install-PwshAgentEnv.ps1`：独立的 Profile/Environment 安装器。
- `scripts/Refresh-EnvPath.ps1`：基于 Registry 的当前 Session PATH/PSModulePath 刷新脚本。
- `scripts/Test-PwshAgentEnv.ps1`：Command inventory 以及 Node/Python/Go/uv/Docker 检查。
- `config/windows-agent-core.winget`：当前 Core package inventory。
- `config/windows-agent-developer.winget`：Go/.NET/build/devops package inventory。
- `config/windows-agent-native-build.winget`：Visual Studio Build Tools 和 vswhere inventory。
- `scripts/Initialize-PwshAgentWindows.ps1`：当前 phase orchestrator。

当前机器已经验证 required tools、Node/Python/Go/uv smoke tests 和 Codex path resolution。`msbuild` 仍然缺失，这是因为 NativeBuild 阶段尚未执行。Docker server 当前报告为 optional warning，因为 daemon 没有运行。

## 3. 目标使用方式

先预览：

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Full -WhatIf -Json
```

执行默认基础环境：

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json
```

显式启用扩展 workload：

```powershell
.\scripts\Initialize-PwshAgentWindows.ps1 -Developer
.\scripts\Initialize-PwshAgentWindows.ps1 -NativeBuild
.\scripts\Initialize-PwshAgentWindows.ps1 -Containers
.\scripts\Initialize-PwshAgentWindows.ps1 -AgentClients
.\scripts\Initialize-PwshAgentWindows.ps1 -Full
```

运维命令：

```powershell
.\scripts\Initialize-PwshAgentWindows.ps1 -Status -Json
.\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json
.\scripts\Initialize-PwshAgentWindows.ps1 -Rollback
```

`-Full` 表示启用所有已定义的 workload，不代表静默安装 WSL，也不代表自动完成 Agent authentication。

## 4. Phase 模型

### Core

安装并验证通用 Runtime：

- PowerShell 7
- Git、Git LFS、GitHub CLI
- Windows Terminal 和 VS Code
- VC++ runtime
- Node.js LTS、npm、npx、Corepack、pnpm
- Python、pip、uv
- 仅安装 Docker CLI 和 kubectl
- curl、OpenSSH、winget
- Scoop 以及小型 CLI 工具：`rg`、`fd`、`fzf`、`jq`、`bat`、`delta`、`yq`、`7z`、`zip`、`nuget`

### Agent

准备 AI Agent Shell 和受管理的安全状态：

- 将 Profile overlay 安装到 `~\.config\pwsh-ai`。
- 在追加 loader 前备份已有的 `pwsh-ai-core.ps1`。
- 确保 `%LOCALAPPDATA%\OpenAI\Codex\bin` 优先于 WindowsApps 内部路径。
- 确保 fnm 初始化具备幂等性，不重复插入 PATH 条目。
- 设置 UTF-8、PlainText、Proxy、Go 和 Python Environment policy。
- 创建 `hooks`、`mcp`、`skills`、`commands`、`rules` 和 `agents` 目录，但不自动启用第三方内容。
- 写入只包含受管理文件和受管理 Registry values 的 manifest。

### AgentClients

显式安装或验证用户选择的 Agent CLI。该阶段必须：

- 使用 allowlisted manifest，其中的 official package IDs/commands 必须先依据当前 Vendor documentation 验证。
- 独立支持 Codex、Claude Code、Gemini CLI 和 GitHub Copilot CLI。
- 不从安装状态推断 authentication 状态。
- 不写入 tokens、credentials、MCP endpoints 或 permission grants。
- 分别验证 command existence、version output 和 Windows PowerShell invocation。
- 在 phase state 中记录 source、version 和 install command。

### Developer

- Go SDK 和 `gofmt`。
- `gopls`、`dlv`、`air`、`golangci-lint`。
- .NET SDK、CMake、Ninja。
- Helm、Terraform、yq、zip、nuget。
- Pester、PSScriptAnalyzer、PSResourceGet。

### NativeBuild

显式安装重量级组件：

- Visual Studio Build Tools。
- MSVC workload。
- Windows SDK。
- MSBuild。
- vswhere/Visual Studio Locator。

该阶段必须能够独立恢复执行，并清楚报告 elevation、reboot、disk 和 installer failures。

### Containers

- 仅在用户选择时安装 Docker Desktop。
- 不选择或安装 WSL backend。
- 不静默启用 virtualization backend。
- 分别验证 Docker client 和 Docker server。
- 将 daemon 未运行报告为明确 warning；只有当用户明确要求运行中的 daemon 时，才把它视为失败。

## 5. State 和 Safety Contract

State 位置：

```text
%LOCALAPPDATA%\PwshAiAgent\state\
  phase-core.json
  phase-agent.json
  phase-agentclients.json
  phase-developer.json
  phase-nativebuild.json
  phase-containers.json
  manifest.json
  backups\
  logs\
```

规则：

- 只有该 phase 的所有 required actions 成功后，才能写入 phase sentinel。
- 有效 sentinel 会让 phase 在重复执行时跳过；使用 `-Force` 才重新执行。
- Logs 记录 command output 和 exit codes，但不记录完整的 Secrets/Environment dump。
- File rollback 恢复原有文件；对于新建文件，只有当前 hash 仍等于安装后记录的 hash 时才删除。
- Registry rollback 只能修改 manifest 中记录为本工具所有的 values。
- Rollback 不代表 Package rollback。已安装的 packages 保留，除非用户单独卸载。
- Rollback 必须明确报告恢复了哪些文件和用户 Environment values。

## 6. 实施计划

### Task 1：用 Tests 锁定 Contract

**Files：**
- 修改：`scripts/Test-InitializePwshAgentWindows.ps1`
- 修改：`scripts/Test-PwshAgentEnv.ps1`

- [ ] 增加 PowerShell 7 rejection、默认 Core + Agent selection、Full phase selection 和 zero WSL-like actions 测试。
- [ ] 增加测试，确认 `Invoke-Phase` 声明了 `SupportsShouldProcess`，并且直接执行 `-WhatIf` probe 时不会运行 action。
- [ ] 增加测试，确认 WhatIf 不会创建 `%LOCALAPPDATA%\PwshAiAgent\state`。
- [ ] 增加 sentinel status、stale sentinel handling 和 `-Force` behavior 测试。
- [ ] 增加 required 与 recommended command failures 测试。
- [ ] 执行测试脚本，确认新增测试在实现修改前会失败。

### Task 2：拆分 Phase Definitions 和 Orchestration

**Files：**
- 修改：`scripts/Initialize-PwshAgentWindows.ps1`
- 新建：`scripts/Private/PwshAiAgent.Phases.ps1`
- 新建：`scripts/Private/PwshAiAgent.State.ps1`

- [ ] 将 phase metadata、action-plan generation、sentinel read/write 和 manifest helpers 移到职责明确的 private scripts。
- [ ] 保持 public entry point 作为唯一用户入口。
- [ ] 通过 advanced functions 传递 ShouldProcess context；禁止在 non-advanced function 中直接访问 `$PSCmdlet`。
- [ ] 保留当前 JSON shape：`Mode`、`Changed`、`StateRoot`、`Phases`、`Actions` 和 `Verification`。
- [ ] 执行 parser checks 和 Task 1 tests。

### Task 3：加入真正的 Preflight 和 Declarative Validation

**Files：**
- 新建：`scripts/Preflight-PwshAgentWindows.ps1`
- 修改：`scripts/Initialize-PwshAgentWindows.ps1`
- 修改：`docs/windows-agent-env.md`

- [ ] 检查 PowerShell major version、Windows platform、winget availability 和 required local directories。
- [ ] 在 command checks 前刷新 PATH。
- [ ] 检查 Proxy reachability，但不记录 credentials 或 proxy secrets。
- [ ] 对当前选择的 document 执行 `winget configure validate`。
- [ ] 将 YAML/schema/resource errors 视为 blockers。
- [ ] 将当前内置 DSC module-publicity warning 记录为 warning，而不是 blocker。
- [ ] 只有在所选 configuration 和已安装 WinGet 支持时，才执行 `winget configure test`；不能把 warning-only 结果静默视为成功。
- [ ] 将 machine-readable preflight report 加入 `-Status -Json` 和 `-Verify -Json`。

### Task 4：让 Core + Agent 真正做到一键并自动验证

**Files：**
- 修改：`scripts/Initialize-PwshAgentWindows.ps1`
- 修改：`scripts/Install-PwshAgentEnv.ps1`
- 修改：`config/pwsh-ai-agent-overlay.ps1`
- 修改：`scripts/Test-PwshAgentEnv.ps1`

- [ ] 使用 retry 和 logging 执行 Core 与 Agent phases。
- [ ] 在 winget、Scoop、fnm 和 Corepack 操作后刷新 PATH。
- [ ] 确保 Profile installation 是 additive 且 idempotent。
- [ ] 验证 `fnm`、Node 24.18.0、npm、npx、pnpm、yarn 和 Codex 从目标路径解析。
- [ ] 默认 apply 完成后自动执行 Node、Python、uv 和 PowerShell smoke tests。
- [ ] 只有 required failures 返回 non-zero；recommended omissions 单独展示。
- [ ] 即使 post-apply verification 成功，也保留显式 `-Verify` 供后续诊断。

### Task 5：加入显式的 AgentClients Phase

**Files：**
- 新建：`config/agent-clients.json`
- 新建：`scripts/Install-AgentClients.ps1`
- 修改：`scripts/Initialize-PwshAgentWindows.ps1`
- 修改：`scripts/Test-PwshAgentEnv.ps1`
- 新建：`scripts/Test-AgentClients.ps1`

- [ ] 每个 client 定义 `Name`、`Source`、`InstallCommand`、`Command`、`VersionCommand` 和 `RequiresLogin`。
- [ ] 在加入 manifest 前，依据 official vendor documentation 验证每个 package/command。
- [ ] 必须显式传入 `-AgentClients`；不能将 third-party clients 放入默认 Core phase。
- [ ] 只有 official client distribution 要求时，才使用 Node/npm 安装。
- [ ] 使用 logs 和 retry 执行安装，然后验证 command 与 version output。
- [ ] 分别报告 `Installed`、`Missing`、`LoginRequired` 和 `InvocationFailed`。
- [ ] 增加测试，证明不会写入 token、MCP URL 或 permissions file。

### Task 6：加入 Modular Agent Governance，但不自动扩大信任边界

**Files：**
- 新建：`config/agent-content/README.md`
- 新建：`config/agent-content/rules/README.md`
- 新建：`config/agent-content/hooks/README.md`
- 新建：`config/agent-content/skills/README.md`
- 新建：`config/agent-content/commands/README.md`
- 新建：`config/agent-content/agents/README.md`
- 修改：`scripts/Install-PwshAgentEnv.ps1`
- 修改：`scripts/Initialize-PwshAgentWindows.ps1`

- [ ] 使用从 `awesome-claude-code-toolkit` 学到的 taxonomy 定义 content categories。
- [ ] 增加 Windows-native dangerous-git hook，覆盖 force push、hard reset、aggressive clean、forced checkout、amend 和 interactive rebase。
- [ ] 使用 `-EnableSafetyHooks` 显式启用 hooks。
- [ ] 合并 hook/rule configuration 前备份现有 Agent settings。
- [ ] 分离 Codex、Claude、Gemini 和 Copilot 内容，避免一个 client 占用另一个 client 的 config。
- [ ] 为 content installation 增加 dry-run、status 和 rollback 输出。
- [ ] 禁止隐式安装 marketplace plugins 或 remote MCP servers。

### Task 7：完成重量级 Workload 行为

**Files：**
- 修改：`scripts/Initialize-PwshAgentWindows.ps1`
- 修改：`config/windows-agent-native-build.winget`
- 修改：`scripts/Test-PwshAgentEnv.ps1`
- 修改：`docs/windows-agent-env.md`

- [ ] 验证 Visual Studio Build Tools override 确实选择 MSVC 和 Windows SDK components。
- [ ] 检测 elevation 和 reboot-required installer results。
- [ ] 安装后定位 MSBuild 和 vswhere。
- [ ] 只有选择 NativeBuild 时，才执行 native compile smoke test。
- [ ] Baseline 中 `msbuild` 保持 recommended；NativeBuild verification 时必须要求它存在。

### Task 8：完成 Docker Phase，但不加入 WSL Compatibility

**Files：**
- 修改：`scripts/Initialize-PwshAgentWindows.ps1`
- 修改：`scripts/Test-PwshAgentEnv.ps1`
- 修改：`docs/windows-agent-env.md`

- [ ] 只有使用 `-Containers` 或 `-Full` 时安装 Docker Desktop。
- [ ] 不执行任何 WSL commands 或 backend selection commands。
- [ ] 分别验证 `docker version` 的 client 和 server。
- [ ] 分别报告 daemon、virtualization、permissions 或 named-pipe failures。
- [ ] 只有满足选定的 success policy 时，才将 Containers 标记为完成。

### Task 9：完成 Verification、Documentation 和 CI

**Files：**
- 修改：`scripts/Test-InitializePwshAgentWindows.ps1`
- 修改：`scripts/Test-PwshAgentEnv.ps1`
- 修改：`docs/windows-agent-env.md`
- 修改：`docs/gap-analysis-github-windows-bootstrap.md`
- 新建：`.github/workflows/pwsh-agent-bootstrap.yml`

- [ ] 对每个 PowerShell 文件执行 parser checks。
- [ ] 对 default 和 Full plans 执行 WhatIf，并断言 zero WSL-like actions。
- [ ] 执行 Status 和 Verify JSON parsing checks。
- [ ] 执行 Node/Python/Go/uv smoke tests。
- [ ] 对三个 declarative documents 执行 winget validation，并保留已知 warning 的解释。
- [ ] 在可用时执行 PSScriptAnalyzer。
- [ ] 如果安装了 graphify executable，执行 `graphify update`；否则记录 tool unavailable 状态。
- [ ] 明确记录 CI job 不得执行真实 machine installation。
- [ ] 记录 default、Developer、NativeBuild、Containers、AgentClients、Full、Verify、Status 和 Rollback 的准确命令。

## 7. 验收标准

只有满足以下全部条件，方案才算完成：

- 新的 PowerShell 7 process 可以运行 default initializer，且不会调用 WSL、bash 或 Linux package manager。
- Default initialization 只准备 Core + Agent，不安装 Visual Studio Build Tools 或 Docker Desktop。
- 现有 fnm、Node、Codex、PowerShell Profile、PATH、Proxy、encoding 和 Terminal font 决策保持不变。
- 重复运行时会跳过有效 completed phases，使用 `-Force` 时会重新执行。
- `-WhatIf -Json`、`-Status -Json`、`-Verify -Json` 和 `-Rollback` 的行为稳定且可机器读取。
- Profile 和 Registry changes 会备份，Rollback 满足 ownership-safe 原则。
- Core + Agent 完成后，Node、npm、npx、pnpm、Python、uv、Go、Git、rg、fd、jq 和 Codex 都能正确解析。
- AgentClients 不写入 authentication 或 remote MCP state。
- 显式安装 NativeBuild 后，verification 能找到 MSBuild、MSVC、Windows SDK 和 vswhere。
- Containers 分别报告 Docker client/server，且不假设 WSL 存在。
- 仓库中的所有 PowerShell files 都能通过 parser checks。
- Tests 以 exit code 0 通过。
- Documentation 明确区分“当前机器已验证”和“作为显式安装 phase 可用”。

## 8. 执行顺序

1. 执行 Tasks 1-3，并验证没有 machine changes。
2. 执行 Task 4；查看 WhatIf plan 后，再在当前机器上执行 Core + Agent。
3. 执行 Tasks 5-6，加入 Agent priority 能力和 governance；在 vendor package identities 验证前保持显式启用。
4. 只有在明确需要重量级能力时，执行 Tasks 7-8。
5. 执行 Task 9，并发布最终 verification report。

首个 production milestone 是 Core + Agent + Verify。最终 milestone 是 Full + AgentClients + safety hooks；authentication 和 third-party MCP setup 仍然保持手动执行，并单独审计。
