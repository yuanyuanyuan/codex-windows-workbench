# 公开 Codex 工作台 Skill 设计

## 目标

将本仓库建设为一个带版本的、自包含的 Codex Skill 与原生 Windows PowerShell 7 工作台。它必须支持换机和公开复用，且绝不复制认证信息、密钥、机器专属状态或未经审查的第三方内容。

## Skill 包结构

仓库根目录就是 Skill 目录。它包含精简的 `SKILL.md`、`agents/openai.yaml`、现有运行时资源和按需加载的参考资料。Skill 负责路由审计、预览、配置、执行、验证、回滚受管理配置、导出脱敏诊断，以及生成清理后的模板副本等请求。它必须拒绝 Windows PowerShell 5.1、WSL、bash 和未经批准的软件源。

## 运行模型

默认交互式配置向导会先展示计划安装的包、来源、提权影响和协议，再安装 Codex Base。它采集可选的代理端点，并将其保存为工作台局部的非敏感设置。它使用 fnm 安装默认的当前 Node LTS，记录实际解析的版本，并允许指定明确版本。它只在用户确认后通过 OpenAI 官方渠道安装或更新 Codex，绝不自动完成认证；命令解析时优先使用已经存在的官方 Codex App CLI，其次才使用独立安装的 Codex CLI。

`-NonInteractive` 会跳过向导，只使用已提供或已保存的设置。安装包时必须显式提供接受协议的标志。安装器绝不自行触发 UAC；它只说明所需权限，用户自行用相应权限重新运行。代理默认只在工作台会话中生效；写入全局用户环境是可逆的显式高级选项。

## 工作负载与状态

Codex Base 包含 PowerShell 7、Git、fnm 与 Node LTS、Scoop、Shell 导航 CLI、curl、SSH、Codex 和受管理的 PowerShell overlay。Developer Tools、Cloud Tools、Containers 和 Native Build 是可选工作负载。状态保存在当前用户的 LocalAppData 中，记录阶段和已解析包，但不记录凭据。回滚仅在哈希和所有权检查后恢复受本工具管理的文件与明确管理的设置；它绝不卸载软件包，也不移除认证状态。

## 验证与诊断

验证只会因 Codex Base 或已选可选工作负载失败。未选择的工作负载显示为 `NotSelected`；仅在选择 Containers 后 Docker CLI 不可用才是失败，Docker daemon 未运行仍是警告。报告同时提供稳定 JSON 和面向人的摘要。原始诊断只保留在本机。显式诊断导出必须删除用户路径、代理端点、环境变量值、凭据及日志中疑似凭据的内容。

## 分发

本仓库是权威模板，通过语义化 Git tag、GitHub Release、SHA-256 校验值、前置条件和变更说明发布。模板生成器会产生独立副本，并排除 `.git`、状态、日志、备份、认证和本地配置。项目使用 MIT License。

## 公开发布仓库净化规则

本仓库是公开发布仓库，不是个人工作站归档。提交前必须运行敏感信息扫描，并由发布检查阻止下列内容进入 Git：用户名、`C:\\Users\\<用户名>` 等绝对个人路径、代理端点、token、密码、Cookie、私钥、认证目录、Profile 备份、环境变量导出、状态文件、原始日志和诊断报告。

本机迁移记录与本机代理/PATH 覆盖已移至私有仓库 `windows-agent-env-init-private`。公开仓库不得包含用户名、绝对个人路径、固定代理端点或厂商私有绝对路径；代理与本机 PATH 覆盖只能通过可选的 private overlay 注入。

可提交的脚本只能使用 `%USERPROFILE%`、`%LOCALAPPDATA%`、`$env:USERPROFILE`、`$env:LOCALAPPDATA` 和 `HKCU:\\Environment` 等抽象位置，不能展开为具体用户路径。即使是可移植变量，默认也不得把代理写入全局用户环境；全局写入必须是显式高级选项并可由受管理回滚恢复。

## 验证标准

验证分为 Skill 结构校验和 PowerShell 单元/契约测试。二者都必须可在当前主机运行，且不进行真实软件安装、不要求管理员权限，也不改动当前用户的 Profile、注册表或真实工作台状态。真实软件安装的端到端验证不属于本机默认测试，后续仅在独立虚拟机环境中执行。

### Skill 结构校验

每次修改 Skill 后执行 `skill-creator` 提供的 `quick_validate.py`。通过标准如下：

- 仓库根目录直接包含 `SKILL.md`，不得再嵌套一个同名 Skill 目录。
- `SKILL.md` 的 YAML frontmatter 只包含 `name` 和 `description`；名称必须为小写连字符形式，描述必须覆盖 Windows、PowerShell 7、Codex 工作台及审计、配置、安装、验证、回滚、模板生成等触发场景。
- `agents/openai.yaml` 必须存在，且其 display name、短描述和默认提示词与 `SKILL.md` 的职责一致；它由 `skill-creator` 的生成工具生成或重新生成，不手工漂移。
- `SKILL.md` 必须少于 500 行，只保留核心工作流；详细契约放在 `references/`，并且所有引用均能从根目录解析。
- `scripts/` 仅包含可重复执行、需要确定性的自动化脚本；`references/` 仅包含按需读取的规范；不得创建与 Skill 无关的 README、安装指南或临时示例文件。
- 对所有 Skill 文本、引用和模板运行静态敏感信息扫描：不得包含 token、密码、Cookie、私钥、用户代理端点、`C:\\Users\\<具体用户名>`、`%LOCALAPPDATA%` 展开后的具体路径，或任何认证文件内容。
- 校验失败必须阻止发布；校验成功的输出与 Skill 版本、Git commit/tag 一起写入发布工件。

### PowerShell 单元与契约测试

使用 Pester 驱动测试，并保留 `scripts/Test-InitializePwshAgentWindows.ps1` 作为可由用户直接运行的测试入口。测试启动时创建独立临时目录，并通过显式注入的 `StateRoot`、`SettingsPath`、`UserProfileRoot`、`PackageCommand` 和环境变量替身隔离所有副作用；测试结束后删除临时目录。单元/契约测试不得调用 `winget install`、`scoop install`、`fnm install`、`npm install`、网络下载、UAC、Docker daemon 或真实的 Codex 登录。

测试必须覆盖以下契约：

- **宿主与安全边界**：Windows PowerShell 5.1、非 Windows、WSL/bash 入口必须被拒绝并给出可操作错误；PowerShell 7 可以继续。任何路径、日志、状态或命令参数中出现 WSL、bash、apt、brew、认证导入或未批准软件源时，测试必须失败。
- **预览与同意**：`-WhatIf` 和计划模式不得创建目录、文件、注册表值、状态或包安装调用；交互模式在显示包、来源、提权影响和协议前不得执行动作；非交互模式缺少显式 `-AcceptPackageAgreements` 时必须以非零退出码失败。
- **工作负载选择**：默认只选择 Codex Base；Developer Tools、Cloud Tools、Containers、Native Build 只有显式选择时才进入计划；`-Full` 只选择已定义的可选工作负载；未选择项在验证 JSON 中严格显示为 `NotSelected`。
- **fnm 与 Node**：计划使用 `Schniz.fnm`，不得使用系统级 `OpenJS.NodeJS.LTS`；默认版本选择为 LTS，显式 `-NodeVersion` 覆盖默认值；fnm 初始化在同一 Profile 会话中重复运行不得重复插入 PATH。
- **Codex 解析与认证**：已有官方 Codex App CLI 时必须优先解析它；不存在时才计划独立官方 CLI 安装；多个候选只报告不删除；安装、验证、模板和日志路径中不得出现认证复制、token 或自动登录调用。
- **设置与代理隐私**：默认代理只进入临时 Workbench-local settings，并只在 overlay 会话生效；默认不得写入 `HKCU:\\Environment`；只有显式高级选项才允许全局用户环境写入，并在 manifest 中记录以支持回滚；诊断 JSON 不得回显代理端点或环境变量值。
- **幂等性与回滚**：成功 phase 才能写 sentinel；有效 sentinel 阻止重复动作，`-Force` 才允许重跑；Rollback 只恢复 manifest 中受管理且哈希匹配的文件/设置，不调用包卸载命令，不删除认证或用户修改后的文件。
- **验证输出与退出码**：`-Verify -Json` 同时包含 Base、所选工作负载、`NotSelected` 项、命令来源、版本与失败原因；Base 或已选 workload 的 required failure 返回非零；Docker daemon 不运行在已选 Containers 中保持 warning，不能伪装为 client 成功。
- **模板与诊断导出**：模板生成结果不含 `.git`、状态、日志、备份、认证目录、局部设置和用户路径；脱敏导出会删除临时测试中植入的用户名、代理端点和凭据样式标记，同时保留失败阶段、错误码和工作负载状态。

每个契约至少有一个正向用例和一个反向用例。测试需断言结构化 JSON 字段和退出码，不得只匹配人类可读字符串。失败时保留脱敏的临时测试报告，成功时不得向仓库写入测试产物。

## 范围

首个公开版本只支持 Codex。Claude Code、Gemini CLI、GitHub Copilot CLI、第三方市场、MCP endpoint、凭据和 WSL 均不在范围内。

