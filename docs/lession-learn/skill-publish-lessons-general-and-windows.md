# Skill 发布经验提炼：通用 vs Windows

来源：[2026-07-12-publish-skill-experience.md](./2026-07-12-publish-skill-experience.md)  
提炼日期：2026-07-14  
范围：从 `stark-codex-windows-workbench` 公开发布复盘中抽出可复用原则；按**通用**与 **Windows 环境特殊**分开，避免把平台细节误当成全平台真理。

## 怎么用

| 你在做 | 先看 |
|---|---|
| 发任意 Codex / Agent skill | [A. 通用经验](#a-通用经验) |
| 在 Windows 上做原生工作台 / PowerShell skill | [A](#a-通用经验) + [B. Windows 特殊经验](#b-windows-特殊经验) |
| 发版前快速自检 | [C. 检查清单](#c-检查清单) |

原始时间线、坑编号与完整模板仍以源文档为准；本文只保留结论级原则。

---

## A. 通用经验

跨平台、跨 skill 品类都成立。和宿主 OS 无关。

### A1. 身份三件套同名

Skill 名、仓库名、Plugin 名必须是同一个产品身份。

- 用户调用入口只有一个名字
- owner/repo/skill 在安装命令里逐字一致
- rename 后必须同步：remote、README、release 文案、本地安装目录指引

错误模式：Skill 叫 A、仓库叫 B、文档按 “bootstrap installer” 写 C。

### A2. 文档身份是 Skill，不是安装器说明书

README 主角是 skill 的价值与调用，不是脚本 dump。

价值优先阅读顺序：

1. 是什么
2. 解决什么
3. 为什么用
4. Before / After
5. 安装
6. 使用
7. 卸载
8. 执行效果 / 约束 / UAT 证据

原则：

- 先卖清价值与动作闭环，再放证明材料
- UAT 很重要，但不能挡在「怎么装/怎么用」前面
- 中英文 README 结构镜像一致，避免一边新一边旧

### A3. 安装多通道，命令可复制

至少同时提供可落地路径（按宿主生态选齐）：

- 商店 / 固定话术通道（如 RedSkill）
- `npx skills add owner/repo`（推荐通用路径）
- 宿主 plugin CLI
- Manual git clone

原则：

- README 只给命令，不讲长篇原理
- 推荐路径放最前
- 文档写了的通道，代码结构必须真实支持

### A4. 使用区只写直接调用

不要写触发词列表、自然语言示例冒充调用方式。

应写成：

```text
$skill-name
```

参数路由放 skill 内部；README 不承担命令百科。

### A5. 包布局决定「可发现」还是「可运行」

公开 skill 最小清单（按生态取子集）：

```text
SKILL.md
agents/openai.yaml
package.json
.codex-plugin/plugin.json
scripts/
docs/install.md
```

硬约束：

- **不要把 `SKILL.md` 放仓库根**（skills CLI 对 root skill 常只拷 `SKILL.md`，不带 scripts/config）
- 正确布局：`skills/<skill-name>/SKILL.md` + 同级 `scripts/` `config/` `agents/` `references/`
- 验收安装必须检查脚本/配置是否存在，不能只看 `SKILL.md` 出现
- skill 可发现 ≠ skill 可运行

### A6. 提供 Agent 可执行 install.md

参考 Agent Reach 模式：人类给 raw 链接一句话，Agent 按文档执行。

文档主体写给 AI：

- 目标与边界
- 目录规则
- 分步命令
- 安全模式
- 失败处理
- 验收模板

原则：Agent 安装文档会反向暴露运行时契约漏洞；写文档时等于在审接口。

### A7. Plugin 安装写真实 CLI，不写聊天 slash

错误：`/plugin marketplace add ...`（聊天里常报 Unrecognized command）  
正确：宿主真实 CLI，例如：

```bash
codex plugin marketplace add <owner>/<repo>
codex plugin add <plugin>@<marketplace>
```

额外注意：不存在的子命令（如误写的 `codex plugin install`）不要进文档。

### A8. 完整生命周期：安装 → 使用 → 卸载

公开 skill 必须有卸载：

1. 可选回滚受管设置
2. 删除 skill 安装目录
3. 清理历史旧名目录
4. 可选移除 plugin 条目
5. 明确卸载**不会**做什么（不卸第三方包、不清无关配置、不退出登录）

rename 后必须同步「重装 + 清旧名」指引。

### A9. 本地旧副本会劫持判断

发布后用户反馈「测得和 UAT 不一样」时，先核：

- 实际 skill 路径
- `SKILL.md` 的 `name`
- 是否仍在跑改名前的旧安装

仓库改名不会自动更新用户 skill 目录。行为一致 + 名字/路径不一致，通常是本地残留，不是运行时回归。

### A10. 结果要同时服务机器与人

- 机器：JSON / 结构化字段（Phases、Selected、Actions、Impact）
- 人：Summary、Description、步骤表、脱敏路径
- Agent 应先讲 Summary，再给细节
- 安全预览不只是 `Changed=false`，还要让用户读懂影响面

### A11. 真实 UAT + 回归门禁

至少跑通并记录：

- 发现（list）
- 安装到用户目录
- 结构校验
- WhatIf / dry-run
- Apply 规则（确认后）
- Status / Verify / Rollback

制度化：

- 发现一次 false-pass，就永久加一条能抓住它的 UAT case
- CI 默认跑无破坏性 Tier A
- 真实装包 Apply 永不默认进 CI
- 测 **packaged/installed path**，不要只测源码树造成「源码绿、安装残缺」

### A12. 文档结构性改动要防写入事故

对长 README 做插入时：

- 优先整文件重写或按行定位 heading 插入
- 避免大段正则拼接 markdown
- 改完先扫 heading 唯一性、行数、是否正文重复，再 commit
- 污染后立即回滚，不要在坏文件上继续叠补丁

### A13. 发布后清理传播面

1. 旧名本地安装引导重装
2. raw `docs/install.md` 与最新提交一致
3. release note 只保留最终身份
4. 内部历史可留，公开入口全部指向最终名
5. 不落用户名、绝对个人路径、代理、token

---

## B. Windows 特殊经验

只在原生 Windows + PowerShell 工作台 / 同类 skill 上额外成立。

### B1. 公开 MVP 边界先钉死

本类产品默认边界：

- 原生 Windows + PowerShell 7+
- 默认 Core + Agent
- **不做** WSL / bash / apt / brew 作为主路径
- 不自动登录
- 不写 secret / MCP 凭据
- 回滚只恢复受管设置，不卸载软件包

文档与 UAT 必须显式防「被写成跨平台 bootstrap」。

### B2. 路径与克隆目标用 Windows 语义

- Manual clone 目标用 `%USERPROFILE%\.codex\skills\<skill>` 或 PowerShell 等价写法
- 展示路径对用户脱敏为 `%USERPROFILE%...`，避免泄露本机绝对路径
- 排查旧副本时同时查：
  - `~\.agents\skills\...`
  - `~\.codex\skills\...`
  - 历史旧名目录

### B3. PowerShell ConfirmImpact 会卡死 Agent

High ConfirmImpact 的 Apply/Rollback 在无人值守 Agent 场景会停等确认。

修复原则：

- 文档与自动化路径使用 `-Confirm:$false`（在已有显式确认门之后）
- WhatIf 与 Apply 的确认模型要分开：预览可自动，变更需用户同意后再非交互执行

### B4. WhatIf / 计划语义要贴 Windows 工作台现实

- Phases 用 `Planned` / `NotSelected`，并输出 `Selected`
- 计划动作补 `Description` / `Category` / `Items`
- 报告要有人类可读 `Summary` 与结构化 `Impact`
- 始终打印 `======== Workbench Summary ========`
- Apply 分步记录 installed / skipped / log path

### B5. 开关与探测语义写死，防过度宣传

Windows 工作台常见坑：

- `-EnableSafetyHooks` 必须真正接入 Apply 与 WhatIf plan，不能只是文档开关
- `-AgentClients` 是 **Codex 探测**，不是安装/登录 Codex
- Core 真实影响面与 **winget 硬依赖** 必须披露
- UAT 硬门禁：默认 Core+Agent、无 WSL-like action

### B6. 卸载边界写清「不卸什么」

Windows 侧用户容易以为卸载 skill = 卸软件：

- 不卸载 winget / scoop 包
- 不清无关 Profile 段落
- 不退出已有登录态
- 只删 skill 目录 + 可选回滚受管设置 + 可选 plugin 条目

### B7. 本地旧名排查用 PowerShell 一口令

当「本机结果 ≠ UAT」时，先跑路径与 `SKILL.md` name 核验（见源文档「本地旧副本排查口令」）。  
`Exists=True` 但 `SkillName` 仍是旧名 → 优先判本地安装残留。

### B8. 回归 runner 用 pwsh，且分 Tier

```powershell
# Tier A：无网络/无真实装包破坏性
pwsh -NoLogo -NoProfile -File .\tests\uat\Invoke-UatRegression.ps1

# Tier B：含网络安装探针（打包/发布前）
pwsh -NoLogo -NoProfile -File .\tests\uat\Invoke-UatRegression.ps1 -IncludeNetwork
```

Windows 相关硬门禁示例：

- 包布局 `skills/<name>/`
- 安装产物含 scripts/config/agents
- 从 packaged path 跑 WhatIf
- 默认 Core+Agent、无 WSL-like action
- Summary/Impact 可读
- 文档无 chat `/plugin`

---

## C. 检查清单

### C1. 通用（每次发 skill）

1. Skill / 仓库 / plugin 名是否一致
2. README 是否价值优先：是什么 → 解决什么 → 为什么用 → 场景 → 安装 → 使用 → 卸载
3. 执行效果 / 约束 / UAT 是否在动作闭环之后
4. 安装命令是否可复制，且通道结构上真实可用
5. 使用区是否只有直接调用
6. 是否为 `skills/<name>/` 布局，安装后 scripts 齐全
7. 是否有 Agent raw `docs/install.md`
8. 是否误写聊天 `/plugin` 或虚构 CLI
9. 卸载是否覆盖当前名 + 历史旧名
10. 是否有敏感路径 / token
11. 是否有 UAT：发现、安装完整性、packaged-path 运行、文档通道
12. false-pass 是否已沉淀为永久 case

### C2. Windows 附加

1. 边界是否写明：原生 Windows、pwsh 7+、无 WSL 主路径
2. 路径示例是否用 `%USERPROFILE%` / PowerShell，而非 Unix-only
3. Apply/Rollback 自动化路径是否 `-Confirm:$false`
4. WhatIf 是否输出 Selected / Phases / Actions / SafetyHooks / Summary
5. `-AgentClients` 是否被错误宣传成安装/登录
6. Core 影响面与 winget 依赖是否披露
7. SafetyHooks 是否真正接入 plan/apply
8. 卸载是否声明不卸 winget/scoop 包
9. 旧名目录清理是否包含 `.agents` 与 `.codex` 两侧
10. Tier A/B runner 是否在发版门禁内

---

## D. 一页决策表

| 主题 | 通用原则 | Windows 附加 |
|---|---|---|
| 命名 | skill = repo = plugin | 可用 `stark-` 等 owner 前缀；全仓替换旧名 |
| 文档主角 | skill 价值与调用 | 不要写成 Windows bootstrap scripts dump |
| 安装 | 多通道 + 可复制命令 | clone 到 `%USERPROFILE%\.codex\skills\...` |
| 布局 | `skills/<name>/`，禁 root-only SKILL | 同左；验收 `Initialize-*.ps1` 等脚本存在 |
| 调用 | 只写直接调用名 | 同左 |
| 预览/变更 | dry-run + 确认后 apply | `-Confirm:$false`、Summary、winget 依赖披露 |
| 卸载 | 完整生命周期 + 旧名清理 | 不卸包；查 `.agents` / `.codex` |
| 质量门 | UAT + 安装完整性 + 文档通道 | 无 WSL-like；pwsh runner；Core+Agent 默认 |

---

## E. 与源文档的关系

| 文件 | 职责 |
|---|---|
| [2026-07-12-publish-skill-experience.md](./2026-07-12-publish-skill-experience.md) | 完整复盘：时间线、坑 1–17、模板原文、UAT 口令 |
| 本文 | 提炼后的原则库：通用 / Windows 分离、检查清单、决策表 |

以后发 skill：先过本文 A + C1；若目标是 Windows 原生工作台，再过 B + C2。
