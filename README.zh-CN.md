# Windows PowerShell 7 Codex 工作台

> English README: [README.md](./README.md)

面向 Codex / AI Agent 的**原生 Windows PowerShell 7** 工作台初始化仓库。

目标：在不使用 WSL、bash、apt、brew 的前提下，把一台 Windows 机器整理成可重复、可检查、可回滚的 AI 工程环境。

## 它能做什么

默认路径只准备：

- **Core**：通用运行时与 CLI（Git、Node/fnm 就绪、Python/uv、Docker CLI、Scoop 小工具等）
- **Agent**：PowerShell Profile 覆盖层、受管 agent 目录、PATH/编码/代理策略

默认 apply 成功后会**自动跑 smoke 验证**；之后仍可用显式 `-Verify` 复检。

可选能力必须显式开启：

| 开关 | 作用 |
|---|---|
| `-Developer` | Go/.NET/构建辅助/DevOps CLI |
| `-NativeBuild` | VS Build Tools / MSVC / Windows SDK |
| `-Containers` | Docker Desktop（client/server 分开报告） |
| `-AgentClients` | Agent CLI 安装/校验（公开 MVP：**仅 Codex**） |
| `-EnableSafetyHooks` | 危险 git 操作防护 hook |
| `-Full` | 启用全部已定义 workload |

## 明确不做的事

- 不支持 Windows PowerShell 5.1
- 不走 WSL / Linux 包管理器
- 不自动登录 Codex/Claude
- 不静默安装远程 MCP 或 marketplace 插件
- 回滚时不卸载软件包
- 公开发布 MVP 不把多 Agent 客户端当默认产品面

## 运行要求

- 原生 Windows
- PowerShell 7+
- 需要 `winget`（声明式配置与安装路径）

## 快速开始

```powershell
# 预览（不改机器）
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -WhatIf -Json

# 默认执行 Core + Agent，并自动 smoke 验证
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1

# 后续诊断
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Status -Json
```

可选：

```powershell
.\scripts\Initialize-PwshAgentWindows.ps1 -Developer
.\scripts\Initialize-PwshAgentWindows.ps1 -NativeBuild
.\scripts\Initialize-PwshAgentWindows.ps1 -Containers
.\scripts\Initialize-PwshAgentWindows.ps1 -AgentClients
.\scripts\Initialize-PwshAgentWindows.ps1 -EnableSafetyHooks
.\scripts\Initialize-PwshAgentWindows.ps1 -Full
.\scripts\Initialize-PwshAgentWindows.ps1 -Rollback
```

仅预检：

```powershell
.\scripts\Preflight-PwshAgentWindows.ps1 -Json
```

## 安全模型

- Profile 采用增量修改，受管覆盖前先备份
- PATH 使用精确条目匹配 + 去重
- AgentClients 从不写入 token、MCP endpoint 或 permissions
- Rollback 仅在 ownership/hash 检查后恢复受管文件/注册表值
- 已安装软件包保留，除非用户自行卸载
- 密钥与机器本地代理地址不应进入本仓库

## 目录结构

```text
scripts/                     # 公共入口与测试
scripts/Private/             # phase/state 私有辅助
config/                      # winget 文档、overlay、agent content
docs/                        # 设计与操作文档
SKILL.md                     # Codex skill 包装入口
.github/workflows/           # CI（不做真实装机）
```

## 测试与 CI

本地合同测试：

```powershell
$env:PWSH_AI_AGENT_SKIP_WINGET_PREFLIGHT = '1'
pwsh -NoLogo -NoProfile -File .\scripts\Test-InitializePwshAgentWindows.ps1
pwsh -NoLogo -NoProfile -File .\scripts\Test-AgentClients.ps1
pwsh -NoLogo -NoProfile -File .\scripts\Test-PwshAgentEnv.ps1 -Json
```

CI 会跑解析检查、合同测试和 WhatIf 断言，**故意不执行**真实 `winget install` / `scoop install` / Docker daemon 安装。

## 文档

- 操作说明：[docs/windows-agent-env.md](./docs/windows-agent-env.md)
- 设计材料：`docs/superpowers/`
- 领域语言：[CONTEXT.md](./CONTEXT.md)

## 版本说明

当前公开发布定位为 **Codex Workbench MVP**。  
NativeBuild / Containers 属于显式能力，不应被宣传成默认一键全家桶。

## 许可证

MIT — 见 [LICENSE](./LICENSE)。
