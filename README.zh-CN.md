# Stark Codex Windows Workbench

> 英文 README（信息源）：[README.md](./README.md)

**Skill：** `stark-codex-windows-workbench`

给 Codex 一条直接入口，在**原生 Windows + PowerShell 7** 上安全地预检、预览、应用、验证并回滚托管工作台。  
默认路径：**Core + Agent**。不用 WSL。不自动登录。不写 secret。

## 这个 Skill 是干什么的

`stark-codex-windows-workbench` 是面向 Codex 的 **原生 Windows PowerShell 7 工作台 skill**。

它用来做这些事：

1. 安装 skill 本身
2. 预检机器是否可跑
3. 用 `-WhatIf` 预览 Core + Agent 会改什么
4. 显式 Apply 最小托管基线
5. 验证 / 查看状态
6. 仅回滚受管设置

一句话：让 Agent 在 Windows 上有一套可重复、可预览、可回滚的工作台，而不是一堆临时脚本。

## 解决了什么问题

在原生 Windows 上把 Codex 变成能做工程的状态，通常会踩这些坑：

- Agent 习惯性滑向 WSL / bash / `apt`，把 Windows 环境搞乱
- 安装路径散落在 winget、scoop、PATH、Profile 和各种临时脚本里
- 装包前没法安全预览“到底会改什么”
- 重复执行不稳定，出问题也不知道怎么回滚
- 安装文档夹杂登录/密钥步骤，容易被 Agent 过度自动化

这个 skill 把它们收敛成一条直接调用入口，并把边界写死：

- 只走原生 Windows + PowerShell 7
- 默认先预览，再确认 Apply
- 默认只做 Core + Agent
- 永不自动登录，不写 MCP/secret
- 回滚只恢复受管设置，不卸载软件包

## 为什么要用

| 如果你现在是… | 这个 skill 让你变成… |
|---|---|
| 靠聊天指令和零散脚本搭环境 | 直接调用 skill 完成预检/预览/应用/验证 |
| 先装包再发现影响面 | 先 `-WhatIf`，确认后再 Apply |
| Windows 上仍被 WSL/bash 带偏 | 固定原生 Windows + PowerShell 7 路径 |
| 每台机器基线不一致 | 托管的 Core + Agent 默认路径 |
| 出问题只能猜着卸载 | 明确回滚受管设置，卸载 skill 也有固定步骤 |

## 用户场景对比

| | Before | After |
|---|---|---|
| 入口 | 一堆临时脚本和聊天指令 | 调用 `$stark-codex-windows-workbench` |
| 宿主模型 | WSL/bash 渗透、shell 混用 | 仅原生 Windows + PowerShell 7 |
| 变更安全 | 先装再看影响 | 先 `-WhatIf` 预览，再显式 Apply |
| 基线 | 机器各自为政 | 托管的 Core + Agent 默认路径 |
| 密钥 | 安装文档诱导自动登录/写 token | 永不自动登录，不写 MCP/secrets |
| 恢复 | 靠猜卸载 | 仅回滚受管设置 |
| 可重复 | “我这能跑” | 幂等 phase + status/verify |

### 调用后的典型流程

```text
调用 skill
  -> 预检
  -> WhatIf 预览
  -> 你确认
  -> Apply Core + Agent
  -> 冒烟验证
  -> 需要时再 Status / Verify / Rollback
```

## 安装

### 给 Agent 的一句话

```text
帮我安装 stark-codex-windows-workbench，使用 v0.1.1 的安装指南：https://github.com/yuanyuanyuan/stark-codex-windows-workbench/blob/v0.1.1/docs/install.md
```

完整 Agent 安装文档：[docs/install.md](./docs/install.md)

### npx（推荐）

```bash
npx skills add yuanyuanyuan/stark-codex-windows-workbench
```

### 手动安装（Git Clone）

`npx skills` 安装的是 `skills/stark-codex-windows-workbench/` 这个 skill 目录，不是整个仓库根目录。

```powershell
git clone --depth 1 --branch v0.1.1 https://github.com/yuanyuanyuan/stark-codex-windows-workbench.git $env:TEMP\stark-codex-windows-workbench
Copy-Item -Recurse -Force $env:TEMP\stark-codex-windows-workbench\skills\stark-codex-windows-workbench $env:USERPROFILE\.codex\skills\stark-codex-windows-workbench
```

## 使用

```text
$stark-codex-windows-workbench
```

调用后的默认行为：

- 审计 / 预检
- 先用 `-WhatIf` 预览
- 确认后再 Apply **Core + Agent**
- 验证 / 状态
- 仅回滚受管设置

可选 workload（只有你明确要求才启用）：

- `-Developer`
- `-NativeBuild`
- `-Containers`
- `-AgentClients`（仅探测 Codex 是否存在/版本；不安装、不登录）
- `-EnableSafetyHooks`
- `-Full`

## 卸载

卸载只删除 skill 安装目录，**不会**卸载 Apply 装上的 winget/scoop 软件包。

### 1) 可选：先回滚受管工作台设置

```powershell
pwsh -NoLogo -NoProfile -File "$env:USERPROFILE\.agents\skills\stark-codex-windows-workbench\scripts\Initialize-PwshAgentWindows.ps1" -Rollback -Confirm:$false -Json
```

如果 skill 只装在 Codex 目录，把上面的路径换成实际 skill 根目录。

### 2) 删除 skill 目录

```powershell
$paths = @(
  "$env:USERPROFILE\.agents\skills\stark-codex-windows-workbench"
  "$env:USERPROFILE\.codex\skills\stark-codex-windows-workbench"
  # 历史旧名
  "$env:USERPROFILE\.agents\skills\codex-windows-workbench"
  "$env:USERPROFILE\.agents\skills\windows-pwsh-agent-workbench"
  "$env:USERPROFILE\.codex\skills\codex-windows-workbench"
)
$paths | Where-Object { Test-Path $_ } | ForEach-Object {
  Remove-Item -LiteralPath $_ -Recurse -Force
  Write-Host "Removed $_"
}
```

### 卸载不会做什么

- 不会卸载 Core 装过的软件包（`winget` / `scoop`）
- 不会删除你无关的 PowerShell Profile 内容
- 不会退出 Codex 登录

## 执行过程与效果

| 步骤 | 实际执行 | 对机器的影响 | 你能看到什么 |
|------|----------|--------------|--------------|
| 1. 调用 skill | `$stark-codex-windows-workbench` | 还不动机器 | Agent 载入 skill 指令 |
| 2. 预检 | `Preflight-PwshAgentWindows.ps1 -Json` | 只读检查 | 宿主/工具阻断项与警告 |
| 3. 预览 | `Initialize-...ps1 -WhatIf -Json` | **不改动**（`Changed=false`） | `Selected`、`Phases`、`Actions`、`SafetyHooks` |
| 4. 确认 | Agent 向你确认 | 不改动 | 清楚说明 Core + Agent 影响 |
| 5. 应用 | `Initialize-...ps1 -Confirm:$false -Json` | 安装基线工具 + 托管 overlay | 各 phase 结果 + 冒烟验证 |
| 6. 验证/状态 | `-Verify` / `-Status` | 只读 | 通过/失败与 phase 完成情况 |
| 7. 回滚 | `-Rollback -Confirm:$false` | 只恢复受管设置 | 已装软件包不会被卸载 |

### 默认 Apply 会带来什么（Core + Agent）

**Core**

- 用 winget-configure 应用 `config/windows-agent-core.winget` 基线包
- 如需则 bootstrap scoop
- 安装常用 CLI：`ripgrep fd fzf jq bat delta yq 7zip zip nuget`
- 部分包可能需要提权

**Agent**

- 写入托管 PowerShell overlay 到 `%USERPROFILE%\.config\pwsh-ai`
- 创建托管 agent 目录
- 在 `%LOCALAPPDATA%\PwshAiAgent\state` 记录受管状态

**默认一定不会发生**

- 不用 WSL / bash / apt / brew
- 不自动登录 Codex
- 不写 secret / MCP 凭据
- 不启用 Developer / NativeBuild / Containers（除非你明确要求）
- 回滚不会卸载软件包

## 完整安装与配置清单

下表列出当前初始化器的全部安装和配置项。标为**默认**的项目会随 Core + Agent 执行；标为**可选**的项目只会在指定对应开关（或 `-Full`）时执行。底层包管理器发现已安装的软件包时会跳过安装。

### 默认：Core 软件包

| 管理器 | 软件包 / ID | 用途 |
|---|---|---|
| winget configure | `Microsoft.PowerShell` | PowerShell 7 |
| winget configure | `Git.Git` | Git for Windows |
| winget configure | `GitHub.cli` | GitHub CLI（`gh`） |
| winget configure | `Microsoft.WindowsTerminal` | Windows Terminal |
| winget configure | `Microsoft.VisualStudioCode` | Visual Studio Code |
| winget configure | `Microsoft.VCRedist.2015+.x64` | 原生工具和 WinGet 配置所需的 VC++ 运行库 |
| winget configure | `OpenJS.NodeJS.LTS` | 用于 Agent CLI 和 JavaScript 项目的 Node.js LTS |
| winget configure | `Python.Python.3.13` | Python 3.13 |
| winget configure | `astral-sh.uv` | Python 包与虚拟环境管理器 |
| winget configure | `Docker.DockerCLI` | 只安装 Docker 客户端，不配置后端 |
| winget configure | `Kubernetes.kubectl` | Kubernetes CLI |
| Scoop（缺失时 bootstrap） | Scoop | 面向小型 CLI 工具的用户级包管理器 |
| Scoop | `ripgrep`、`fd`、`fzf` | 搜索、文件发现和交互式筛选 |
| Scoop | `jq`、`yq` | JSON 与 YAML 处理 |
| Scoop | `bat`、`delta` | 文件查看和 Git diff |
| Scoop | `7zip`、`zip`、`nuget` | 压缩归档和 NuGet CLI |

### 默认：Agent 配置

| 类别 | 项目 | 效果 |
|---|---|---|
| 托管文件 | `%USERPROFILE%\.config\pwsh-ai\pwsh-ai-agent-overlay.ps1` | 安装 PowerShell 运行时 overlay。 |
| 托管文件 | `%USERPROFILE%\.config\pwsh-ai\pwsh-ai-core.ps1` | 创建或扩展受管 core profile loader；已有文件会在追加 loader 前备份。 |
| 托管目录 | `%USERPROFILE%\.config\pwsh-ai` 下的 `hooks`、`mcp`、`skills`、`commands`、`rules`、`agents` | 创建供本地后续配置使用的空目录；不会安装插件、MCP server 或凭据。 |
| 托管状态 | `%LOCALAPPDATA%\PwshAiAgent\state` | 保存备份、哈希和 phase 完成状态，以便安全回滚受管设置。 |
| 用户环境变量 | `GOPATH`、`GOPROXY`、`GOSUMDB` | 设置为 `%USERPROFILE%\go`、`https://proxy.golang.org,direct`、`sum.golang.org`。 |
| 用户环境变量 | `PYTHONIOENCODING`、`PYTHONUTF8`、`NO_PROXY` | 设置 Python UTF-8 输出和 `localhost,127.0.0.1,::1`。 |
| 进程 overlay | 输出编码和 PowerShell 偏好 | 使用 UTF-8、纯文本输出渲染，并关闭进度显示，便于 Agent 子进程读取。 |
| 进程 overlay | PATH 顺序 | 将已存在的 Go、Scoop、WinGet Links、Codex、`.local\bin`、pnpm 和 Python Scripts 路径加入 PATH，并去重。 |
| 进程 overlay | 代理策略 | 保留已有的 `HTTP_PROXY`、`HTTPS_PROXY`、`ALL_PROXY`；可选的本地 private overlay 可提供机器特定值。 |

Agent 配置不会创建认证 token、MCP endpoint 或权限授予，也不会安装 Codex。`-AgentClients` 只探测既有的 `codex` 命令和版本。

### 可选工作负载与配置

| 开关 | 会安装或配置什么 |
|---|---|
| `-Developer` | winget：`GoLang.Go`、`Microsoft.DotNet.SDK.10`、`Kitware.CMake`、`Ninja-build.Ninja`、`Helm.Helm`、`Hashicorp.Terraform`；Scoop：`golangci-lint`、`air`；Go：`gopls`、`dlv`、`air`；当前用户 PowerShell 模块：`Pester`、`PSScriptAnalyzer`、`Microsoft.PowerShell.PSResourceGet`。 |
| `-NativeBuild` | 带 MSVC 和 Windows SDK 工作负载的 `Microsoft.VisualStudio.2022.BuildTools`，以及 `Microsoft.VisualStudio.Locator`（`vswhere`）。 |
| `-Containers` | `Docker.DockerDesktop`，随后探测 Docker 客户端/服务端可用性；不会选择 Docker 后端，也不会配置 WSL。 |
| `-AgentClients` | 探测公开 Codex CLI 的位置与 `codex --version`；不安装、不登录、不写认证、MCP 或权限。 |
| `-EnableSafetyHooks` | 复制 `%USERPROFILE%\.config\pwsh-ai\hooks\dangerous-git.ps1`，防护 force push、hard reset、aggressive clean、forced checkout、amend 和 interactive rebase。 |
| `-Full` | 选择以上全部可选工作负载，并启用安全 hook。 |

回滚只恢复状态文件中记录的托管文件和用户环境变量，刻意保留已安装的软件包。

### 预览输出示例

```json
{
  "Mode": "WhatIf",
  "Changed": false,
  "Selected": ["Core", "Agent"],
  "Phases": [
    { "Name": "Core", "Status": "Planned" },
    { "Name": "Agent", "Status": "Planned" },
    { "Name": "Developer", "Status": "NotSelected" }
  ],
  "SafetyHooks": false
}
```

预览/应用结果现在包含可读的 `Summary` 和结构化 `Impact`，不用啃原始 JSON 也能看清将安装的包、写入的托管文件，以及默认不会做什么。

怎么读：

- 以 `Selected` + `Actions` 为准
- `Planned` = 会执行
- `NotSelected` = 不会执行
- `Changed=false` = 预览没有改机器

## 约束

- 仅 Windows + PowerShell 7+
- 不支持 Windows PowerShell 5.1
- 不使用 WSL / bash / apt / brew
- 不自动登录
- 不写 secret / MCP 凭据
- 回滚不卸载软件包
- Apply 需要 `winget`
- 非交互 Apply/Rollback 应使用 `-Confirm:$false`

## UAT 证据

每次更新后必须跑回归 UAT：

```powershell
pwsh -NoLogo -NoProfile -File .\tests\uat\Invoke-UatRegression.ps1
```

- 规则：[docs/uat/REGRESSION-RULES.md](./docs/uat/REGRESSION-RULES.md)
- 用例：[docs/uat/cases/](./docs/uat/cases/)
- 门禁会检查**安装后的 skill 产品目录完整性**，不只是源码树发现/WhatIf。

真实安装与配置记录见：

- [docs/uat-real-install-configure.md](./docs/uat-real-install-configure.md)

在原生 Windows 上已观察到：

- 可通过 `npx skills add ... --list` 发现 skill
- skill 会装到 `%USERPROFILE%\.agents\skills\stark-codex-windows-workbench`
- `-WhatIf -Json` 返回 `Changed=false`，且 `Selected=["Core","Agent"]`
- 完整包 Apply 必须等用户明确确认

给 Agent 的一句话复现：

```text
按 docs/install.md 安装 stark-codex-windows-workbench；先 npx 安装 skill，再执行 -WhatIf -Json 预览 Core+Agent，把 Selected/Actions 报告给我确认后，才允许 -Confirm:$false Apply，最后跑 -Status/-Verify。
```

## 包结构

```text
skills/stark-codex-windows-workbench/
  SKILL.md
  agents/openai.yaml
  scripts/
  config/
  references/
.codex-plugin/plugin.json
package.json
docs/
```

## 许可证

MIT — 见 [LICENSE](./LICENSE)。


