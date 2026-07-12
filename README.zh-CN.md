# windows-pwsh-agent-workbench

> English README: [README.md](./README.md)

这是一个 **Codex Skill**：用于维护「原生 Windows PowerShell 7 + Codex」工程工作台。

本仓库是 **Workbench Source Repository（工作台源仓库）**：发布 Skill 包，以及 Skill 驱动的运行时脚本/配置。  
它**不是**普通 Windows 安装器项目，也**不是**个人 dotfiles 仓库。

## 这个 Skill 是什么

**Skill 名称：** `windows-pwsh-agent-workbench`

**一句话职责：** 帮助 Codex 在原生 Windows 上搭建、审计、验证并安全维护 PowerShell 7 工程工作台——不使用 WSL。

当用户这样说时，应使用本 skill：

- “帮我初始化 Windows AI agent 环境”
- “检查我的 Windows PowerShell 工作台”
- “准备一个给 Codex 用的 Windows shell”
- “验证 Windows 上的 Node/Git/Codex 路径”
- “回滚工作台管理过的 profile 变更”

## Skill 做什么

Skill 负责路由并执行工作台操作：

1. **审计 / 预检**：宿主检查、计划检查、声明式校验
2. **预览**：`-WhatIf` 展示将发生的变更，不改机器
3. **应用**：安装/维护选定工作台路径
4. **验证 / 状态**：机器可读健康报告与阶段状态
5. **回滚**：仅恢复工作台管理的文件/设置
6. **安全边界**：拒绝 Windows PowerShell 5.1、WSL、bash、apt、brew

默认 workload 只有 **Codex Base（Core + Agent）**。更重能力必须显式开启。

| Workload | 触发方式 | 含义 |
|---|---|---|
| Core + Agent（默认） | 无额外参数 | Codex 可工作的 shell、运行时、profile overlay |
| Developer | `-Developer` | Go/.NET/构建辅助/DevOps CLI |
| NativeBuild | `-NativeBuild` | VS Build Tools / MSVC / Windows SDK |
| Containers | `-Containers` | Docker Desktop（client/server 分开报告） |
| AgentClients | `-AgentClients` | Agent CLI 路径（公开 MVP：**仅 Codex**） |
| Safety hooks | `-EnableSafetyHooks` | 可选危险 git 防护 |
| Full | `-Full` | 全部已定义可选 workload |

## Skill 明确不做什么

- 不是多 Agent 市场安装器
- 不是自动登录/认证工具
- 不是 MCP 凭据迁移工具
- 不是 WSL/Linux bootstrap
- 不是“静默把整台电脑装成完整开发机”

公开 MVP **只支持 Codex**。

## 如何安装这个 Skill

### 方式 A：把本仓库当作 skill 根目录

克隆仓库，然后将 Codex / skill installer 指向仓库根目录（包含 `SKILL.md` 的目录）：

```powershell
git clone https://github.com/yuanyuanyuan/windows-pwsh-agent-workbench.git
```

Skill 包入口：

- [`SKILL.md`](./SKILL.md) — skill 说明（仅 `name` + `description` frontmatter）
- [`agents/openai.yaml`](./agents/openai.yaml) — Codex agent 接口元数据
- [`scripts/`](./scripts/) — skill 调用的确定性自动化
- [`references/`](./references/) — 按需加载的详细契约

### 方式 B：已安装到 Codex skills 目录

如果本仓库已安装到你的 Codex skills 路径，可按 skill 名称调用：

```text
windows-pwsh-agent-workbench
```

或用匹配 skill 描述的自然语言任务触发。

## 用户该怎么对 Skill 说话

推荐说法：

- “用 Windows PowerShell Codex workbench skill 预览默认安装计划。”
- “审计我当前的 Windows 工作台，报告缺了哪些 required 工具。”
- “只应用 Core + Agent，然后验证。”
- “启用 safety hooks，并告诉我会改哪些文件。”
- “只回滚工作台管理过的设置。”

Skill 应优先执行：

```powershell
# 预览
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -WhatIf -Json

# 应用默认 Codex Base
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1

# 验证 / 状态 / 回滚
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Status -Json
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Rollback
```

预检：

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\Preflight-PwshAgentWindows.ps1 -Json
```

## 宿主约束

- 支持：**原生 Windows + PowerShell 7+**
- 拒绝：Windows PowerShell 5.1、WSL、bash、sh、apt、brew
- 真正改机器只发生在用户明确执行的 workbench run
- CI 与合同测试故意不做真实装机

## 安全模型

- Profile 增量修改；受管覆盖前先备份
- PATH 精确条目匹配 + 去重
- AgentClients 从不写 token、MCP endpoint、permissions
- Rollback 仅在 ownership/hash 检查后恢复受管文件/设置
- 回滚从不卸载软件包
- 公开仓库不得包含用户名、绝对个人路径、代理密钥或认证状态

## 仓库结构

```text
SKILL.md                 # skill 入口（仓库根即 skill 根）
agents/openai.yaml       # Codex skill 接口元数据
scripts/                 # skill 运行时自动化 + 合同测试
scripts/Private/         # phase/state 辅助
config/                  # winget 文档、overlay、agent content
references/              # 渐进披露契约
docs/                    # 设计与操作说明
.github/workflows/       # skill 包 CI（不做真实安装）
```

## 测试

Skill 运行时合同测试：

```powershell
$env:PWSH_AI_AGENT_SKIP_WINGET_PREFLIGHT = '1'
pwsh -NoLogo -NoProfile -File .\scripts\Test-InitializePwshAgentWindows.ps1
pwsh -NoLogo -NoProfile -File .\scripts\Test-AgentClients.ps1
```

## 文档

- 领域语言：[CONTEXT.md](./CONTEXT.md)
- 操作备注：[docs/windows-agent-env.md](./docs/windows-agent-env.md)
- Skill 设计：[docs/superpowers/specs/2026-07-12-public-codex-workbench-skill-design.md](./docs/superpowers/specs/2026-07-12-public-codex-workbench-skill-design.md)

## 版本

当前公开发布：**Codex Workbench MVP（`v0.1.0`）**。

## 许可证

MIT — 见 [LICENSE](./LICENSE)。
