# 发布 Skill 经验总结

日期：2026-07-12 ~ 2026-07-13  
最终身份：

| 项 | 值 |
|---|---|
| Skill 名 | `stark-codex-windows-workbench` |
| 仓库名 | `yuanyuanyuan/stark-codex-windows-workbench` |
| Plugin 名 | `stark-codex-windows-workbench` |
| 默认分支 | `master` |
| 公开入口 | https://github.com/yuanyuanyuan/stark-codex-windows-workbench |
| Agent 安装文档 | https://raw.githubusercontent.com/yuanyuanyuan/stark-codex-windows-workbench/master/docs/install.md |

## 一句话

发布 skill 时，先把**名字、安装、调用、边界、真实效果**五件事对齐；脚本再强，文档身份错了也等于没发布成功。

## 背景与目标

把本地 Windows PowerShell 工作台工程整理成可公开发布、可被 AI Agent 安装与调用的 **Codex Skill**。

公开 MVP 边界：

- 原生 Windows + PowerShell 7+
- 默认 Core + Agent
- 不做 WSL / bash / apt / brew
- 不自动登录
- 不写 secret / MCP 凭据
- 回滚只恢复受管设置，不卸载软件包

## 最终可复用结论

### 1. 身份三件套必须同名

| 角色 | 规则 |
|---|---|
| Skill 名 | 产品身份，用户直接调用的名字 |
| 仓库名 | 分发容器，应与 skill 名一致 |
| Plugin 名 | marketplace 安装名，应与 skill 名一致 |

用户看到的调用入口只有：

```text
stark-codex-windows-workbench
/stark-codex-windows-workbench
```

错误模式：

- Skill 叫 A
- 仓库叫 B
- README 又按“bootstrap installer”写 C

结果：安装命令、plugin 命令、文档口径全部漂移。

### 2. 这是 Skill 包，不是安装器说明书

README 主角必须是 skill：

- 痛点
- 解决什么
- Before / After
- 执行过程与效果
- 真实 UAT
- 安装
- 调用

不要把仓库写成“Windows bootstrap scripts dump”。

### 3. 安装要多通道，且命令必须可复制

至少同时提供 4 类路径：

1. **RedSkill**  
   中文 Agent/商店固定话术。
2. **npx skills add（推荐）**
   ```bash
   npx skills add yuanyuanyuan/stark-codex-windows-workbench
   ```
3. **Codex Plugin CLI**
   ```bash
   codex plugin marketplace add yuanyuanyuan/stark-codex-windows-workbench
   codex plugin add stark-codex-windows-workbench@stark-codex-windows-workbench
   ```
4. **Manual Git Clone**
   ```bash
   git clone https://github.com/yuanyuanyuan/stark-codex-windows-workbench.git %USERPROFILE%\.codex\skills\stark-codex-windows-workbench
   ```

原则：

- README 只展示命令，不讲长篇原理
- 推荐路径放最前
- owner/repo/skill 名逐字一致
- 本地代码必须真的支持这些通道，不能只写文档

### 4. 使用方式只写直接调用

不要写：

- 触发关键词列表
- “当你说 XXX 时会自动……”
- 一堆自然语言示例冒充调用方式

应写成：

```text
stark-codex-windows-workbench
/stark-codex-windows-workbench
```

参数路由放在 skill 内部；README 不承担命令百科。

### 5. 为多宿主补齐最小清单

公开仓库至少保留：

```text
SKILL.md
agents/openai.yaml
package.json
.codex-plugin/plugin.json
.claude-plugin/plugin.json
.claude-plugin/marketplace.json
scripts/
docs/install.md
```

约束：

- `SKILL.md` 的 `name` = skill 调用名
- plugin `name` 与 skill 名保持一致
- homepage / repository 全部指向最终仓库
- 保持**根目录 skill 布局**（`SKILL.md` 在仓库根）
- 不为了某宿主 monorepo 风格强行迁到 `skills/<name>/`，以免破坏已验证的 npx/相对路径

### 6. 必须有 Agent 可执行安装文档

参考 Agent Reach 模式，提供 `docs/install.md`：

人类入口：

```text
帮我安装 stark-codex-windows-workbench：https://raw.githubusercontent.com/yuanyuanyuan/stark-codex-windows-workbench/master/docs/install.md
```

文档主体写给 AI Agent：

- 目标与边界
- 目录规则
- 分步命令
- 安全模式
- 失败处理
- 验收模板

这样不依赖用户先读 README，也能让 Agent 完成 skill 安装与可选工作台配置。

### 7. README 顶部必须先讲价值，再讲安装

最显眼位置固定放：

1. 痛点
2. 这个 skill 解决什么
3. Before / After
4. 执行过程与效果
5. 真实 UAT 安装/配置过程

否则用户只会把仓库当“脚本仓库”，而不是可调用 skill。

### 8. 真实 UAT 比口号重要

至少真实跑通并记录：

- skill 发现（`npx skills add ... --list`）
- skill 安装到用户目录
- skill/plugin 结构校验
- `-WhatIf -Json` 预览（`Changed=false`）
- Apply 的完整流程文档（可同意后执行）
- Status / Verify / Rollback 规则

把真实输出片段写进 README 与 `docs/uat-real-install-configure.md`。

## 本次完整踩坑时间线

### 坑 1：把 README 写成安装器项目

现象：用户一眼判断“这不是 skill”。  
修复：README 以 skill 安装/调用/效果为中心。

### 坑 2：仓库名与 skill 名脱节

现象：先后出现

- `windows-pwsh-agent-workbench`
- `codex-windows-workbench`
- 最终才统一为 `stark-codex-windows-workbench`

修复：skill / repo / plugin 三名合一，并同步 GitHub rename、remote、release 文案。

### 坑 3：使用说明过重

现象：写了触发场景和示例句。  
修复：使用区只保留直接调用。

### 坑 4：安装通道过窄

现象：只写一种安装路径，其他宿主无路可走。  
修复：RedSkill / npx / plugin / clone 四通道并列，并补齐清单文件让通道“结构上真实可用”。

### 坑 5：缺少 Agent 可执行 install.md

现象：用户无法对 Agent 说“按这个链接装”。  
修复：新增 `docs/install.md`，并在 README 中英都挂 raw 入口。

### 坑 6：install.md 审查发现问题后才修运行时

审查并修复：

1. Apply/Rollback 补 `-Confirm:$false`，避免 High ConfirmImpact 卡住 Agent
2. `-EnableSafetyHooks` 真正接入 Apply 与 WhatIf plan
3. WhatIf `Phases` 改为 `Planned` / `NotSelected`，并输出 `Selected`
4. `-AgentClients` 明确为 Codex 探测，不安装/不登录
5. 文档披露 Core 真实影响面与 winget 硬依赖

教训：Agent 安装文档不是说明书补丁，它会反向暴露运行时契约漏洞。

### 坑 7：把 Codex plugin 写成聊天 slash 命令

错误写法：

```text
/plugin marketplace add ...
```

真实报错：

```text
Unrecognized command '/plugin'. Type "/" for a list of supported commands.
```

正确写法：

```bash
codex plugin marketplace add yuanyuanyuan/stark-codex-windows-workbench
codex plugin add stark-codex-windows-workbench@stark-codex-windows-workbench
```

额外注意：

- `/plugin` 不是 Codex 聊天 slash command
- `codex plugin install` 也不存在
- 安装插件用 `codex plugin add`

### 坑 8：只写“能力”，不写“执行效果”

现象：用户不知道调用 skill 后机器会发生什么。  
修复：补执行链路与步骤表：

```text
调用 skill
  -> 预检
  -> WhatIf 预览
  -> 用户确认
  -> Apply Core + Agent
  -> 冒烟验证
  -> Status / Verify / Rollback
```

### 坑 9：UAT 没有落到 README

现象：安装方式看起来像理论方案。  
修复：把真实发现/安装/校验/WhatIf 输出写进 README 与独立 UAT 文档。

### 坑 10：命名改到最后才彻底统一

现象：中途文档与脚本路径仍残留旧名。  
修复：最终统一 `stark-codex-windows-workbench`，并全仓替换身份字段。

## 本地代码对安装通道的真实支持情况

| 通道 | 仓库侧支持 | 实测结果 |
|---|---|---|
| RedSkill | 提供固定安装话术 | 分发取决于商店上架；仓库侧话术齐备 |
| npx skills add | 根 `SKILL.md` 可被 skills CLI 发现 | 通过：Found 1 skill；可装到 `~\.agents\skills\...` |
| Codex Plugin CLI | `.codex-plugin/plugin.json` 等清单齐全 | 清单校验通过；安装走 CLI 不是聊天 `/plugin` |
| Manual clone | 根目录即 skill 目录 | 通过：clone 到 `~\.codex\skills\...` 或 `~\.claude\skills\...` |

布局决策：

- 保持根目录 skill
- 不为 Claude monorepo 风格强行迁目录
- 以 npx 实测通过路径为优先兼容目标

## 发布检查清单

发布前逐项确认：

1. Skill 名、仓库名、plugin 名是否一致
2. README 中英是否都先写痛点 / 解决 / Before-After / 执行效果 / UAT
3. 安装命令是否可直接复制，且覆盖 RedSkill / npx / plugin / clone
4. 使用区是否只有直接调用，没有触发词废话
5. `SKILL.md` frontmatter 是否干净、可发现
6. 是否存在用户名、绝对个人路径、代理、token 等敏感信息
7. contract / structure / plugin 校验是否通过
8. GitHub description 是否按 skill 语义写，而不是 installer 语义
9. 是否存在错误的 `/plugin` 聊天命令
10. Apply/Rollback 文档是否使用 `-Confirm:$false`
11. WhatIf 是否输出 `Selected` / `Phases` / `Actions` / `SafetyHooks`
12. `-AgentClients` 是否被错误宣传成“安装/登录 Codex”
13. 是否提供 raw `docs/install.md` 供 Agent 一句话安装
14. 是否沉淀经验到 `docs/lession-learn/`

## 可复用模板

### 命名

```text
skill name   = <owner-prefix>-<product>
repo name    = <same as skill>
plugin name  = <same as skill>
```

本项目：

```text
stark-codex-windows-workbench
```

### README 顶部骨架

```markdown
## 痛点
## 这个 Skill 解决什么
## Before / After
## 执行过程与效果
## UAT：真实安装与配置过程
## Install
## Use
```

### 安装区最小骨架

```markdown
## Install

### One-line for agents
帮我安装 <skill>：https://raw.githubusercontent.com/<owner>/<repo>/master/docs/install.md

### RedSkill
现在为你安装 Skill，先来检查是否已安装 Red Skill 商店……然后安装 <skill> 技能。

### npx (Recommended)
npx skills add <owner>/<repo>

### Codex Plugin CLI
codex plugin marketplace add <owner>/<repo>
codex plugin add <plugin>@<marketplace>

### Manual (Git Clone)
git clone https://github.com/<owner>/<repo>.git %USERPROFILE%\.codex\skills\<skill>
```

### 使用区最小骨架

```markdown
## Use

```text
<skill>
```

```text
/<skill>
```
```

### Agent install.md 最小骨架

```markdown
## For Humans
一句话安装入口

## For AI Agents
Goal
Execution effects
Boundaries
Install channels
Resolve skill root
Preflight
WhatIf
Confirm
Apply
Verify/Status
Rollback
Acceptance report template
```

## 发布后的建议动作

1. 本地已安装旧名 skill 时，重装到新名目录
2. 用 raw GitHub 链接复核 `docs/install.md` 是否与最新提交一致
3. release note 只保留最终身份，避免旧名继续传播
4. 内部历史文档可保留，但公开入口全部指向最终名

## 最终产物对照

| 产物 | 路径 / 地址 |
|---|---|
| Skill 入口 | `SKILL.md` |
| 英文 README | `README.md` |
| 中文 README | `README.zh-CN.md` |
| Agent 安装文档 | `docs/install.md` |
| 真实 UAT 记录 | `docs/uat-real-install-configure.md` |
| 本经验总结 | `docs/lession-learn/2026-07-12-publish-skill-experience.md` |
| 公开仓库 | https://github.com/yuanyuanyuan/stark-codex-windows-workbench |

## 结束语

这次发布真正难的不是 PowerShell 脚本，而是把一个本地工作台工程，收成一个：

- 名字统一
- 多通道可装
- 可直接调用
- Agent 可按文档执行
- 效果可预览、可验证、可回滚

的公开 skill。

以后再发 skill，直接按本文检查清单走，可以少踩一轮身份与分发坑。
