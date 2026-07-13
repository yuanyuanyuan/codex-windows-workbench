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

发布 skill 时，先把**名字、安装、调用、卸载、边界、真实效果**对齐，README 还要按价值优先排序；脚本再强，文档身份错了也等于没发布成功。

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
$stark-codex-windows-workbench
```

错误模式：

- Skill 叫 A
- 仓库叫 B
- README 又按“bootstrap installer”写 C

结果：安装命令、plugin 命令、文档口径全部漂移。

### 2. 这是 Skill 包，不是安装器说明书

README 主角必须是 skill，并且按**价值优先**的阅读结构写：

1. 是干什么的
2. 解决了什么问题
3. 为什么要用
4. 用户场景对比（Before / After）
5. 怎么安装
6. 怎么使用
7. 怎么卸载
8. 执行效果 / 约束 / UAT 证据（细节下沉）

不要把仓库写成“Windows bootstrap scripts dump”。  
不要把 UAT 长证据和执行细节压在安装/使用之前。

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
$stark-codex-windows-workbench
```

参数路由放在 skill 内部；README 不承担命令百科。

### 5. 为多宿主补齐最小清单

公开仓库至少保留：

```text
SKILL.md
agents/openai.yaml
package.json
.codex-plugin/plugin.json
scripts/
docs/install.md
```

约束：

- `SKILL.md` 的 `name` = skill 调用名
- plugin `name` 与 skill 名保持一致
- homepage / repository 全部指向最终仓库
- **不要把 `SKILL.md` 放在仓库根**（skills CLI 对 root skill 只拷 `SKILL.md`，不带 scripts/config）
- 正确布局：`skills/<skill-name>/SKILL.md` + 同级 `scripts/` `config/` `agents/` `references/`

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
| npx skills add | `skills/<name>/SKILL.md` 可被 skills CLI 发现并完整拷贝 skill 目录 | 通过：Found 1 skill；安装目录含 scripts/config |
| Codex Plugin CLI | `.codex-plugin/plugin.json` 等清单齐全 | 清单校验通过；安装走 CLI 不是聊天 `/plugin` |

布局决策：

- 采用 `skills/<name>/` 布局
- root-level `SKILL.md` 会导致 npx skills 只装文档、不装脚本
- 以 npx 实测“安装目录文件齐全”为兼容目标，而不只是“能发现 skill”

## 发布检查清单

发布前逐项确认：

1. Skill 名、仓库名、plugin 名是否一致
2. README 中英是否按价值优先排序：是什么 / 解决什么 / 为什么用 / 场景对比 / 安装 / 使用 / 卸载
2b. 执行效果、约束、UAT 是否放在主操作路径之后，而不是压在安装前面
2c. 是否同时提供卸载步骤（含旧名清理）
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

### README 阅读结构骨架（价值优先）

```markdown
## 这个 Skill 是干什么的
## 解决了什么问题
## 为什么要用
## 用户场景对比（Before / After）
## 安装
## 使用
## 卸载
## 执行过程与效果
## 约束
## UAT 证据
## 包结构
## 许可证
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


## 后续更新经验（2026-07-13 续）

### 坑 11：本地实测与 UAT 文档“看起来不一致”

现象：

- 用户调用后，Agent 读到的是：
  `~\.agents\skills\codex-windows-workbench`
- skill frontmatter 仍是旧名 `codex-windows-workbench`
- 但 WhatIf 流程、Selected=Core+Agent、SafetyHooks=false 与文档一致

结论：

- **行为一致是正常的**
- **名字/路径不一致也正常**
- 原因是本机还装着改名前的旧 skill 副本，仓库改名不会自动更新用户 skill 目录

修复动作：

1. 用新名重装 skill
2. 删除旧目录：
   - `~\.agents\skills\codex-windows-workbench`
   - 以及历史旧名 `windows-pwsh-agent-workbench`
3. README 卸载区必须覆盖旧名清理，避免用户一直跑旧副本

经验：

- UAT 记录的是“某次安装后的状态”，不是“用户机器永远自动同步”
- 公开发布后 rename，必须同步提供**重装 + 卸载旧名**指引
- 判断“测得对不对”时，先核验 skill 实际路径与 `SKILL.md` 的 `name`

### 坑 12：README 只有安装/使用，没有卸载

现象：用户装上旧 skill 后不知道怎么清，继续被旧名劫持。

修复：

中英文 README 增加 `Uninstall / 卸载`：

1. 可选先 `-Rollback` 回滚受管设置
2. 删除 agents/codex skill 目录
3. 清理历史旧名目录
4. 可选移除 Codex plugin 条目
5. 明确卸载**不会**卸载 winget/scoop 包、不会清无关 Profile、不会退出登录

经验：

- 公开 skill 的完整生命周期是：安装 → 使用 → 卸载
- 卸载文档要同时覆盖“当前名”和“历史旧名”

### 坑 13：README 信息都有，但阅读结构不对

现象：痛点、解决、UAT、安装、使用都写了，但顺序像“证据堆叠”，用户不能 30 秒看懂这是什么。

错误倾向：

1. 一上来长 UAT
2. 执行细节压过安装/使用
3. “能做什么”和“是什么/为什么用”混在一起

修复后的主阅读路径：

```text
是什么
  -> 解决什么
  -> 为什么用
  -> 场景对比
  -> 安装
  -> 使用
  -> 卸载
  -> 执行效果 / 约束 / UAT 证据
```

经验：

- README 先卖清价值和操作路径，再放证明材料
- UAT 很重要，但应作为证据区，不应挡住“怎么装/怎么用”
- 中英文 README 必须同步重排，不能一边改、一边旧结构残留

### 坑 14：文档插入时的文件写入事故

现象：用字符串整段替换/正则插入 README 时，一度把正文重复污染，出现 `Test-Path # Stark Codex...` 之类拼接损坏。

修复：

- 立即 `git checkout -- README*.md` 回滚
- 改用“按行定位 heading，再插入 block”的方式重写
- 插入后立刻检查：
  - heading 列表是否唯一
  - 文件行数是否合理
  - 是否出现正文重复片段

经验：

- 对已有长 README 做结构性插入时，优先整文件重写或按行插入
- 避免在复杂正则替换里拼接大段 markdown
- 任何文档结构改动后，先做 heading 扫描再 commit

## README 价值优先检查清单

发布/改版 README 时额外确认：

1. 前 1 屏是否说清：是什么、解决什么、为什么用
2. 场景对比是否紧跟“为什么用”
3. 安装 / 使用 / 卸载是否连在一起，形成完整动作闭环
4. 执行细节、约束、UAT 是否放在动作闭环之后
5. 卸载是否覆盖当前名 + 历史旧名
6. 中英文结构是否镜像一致
7. 用户本地若仍装旧名，文档是否提示重装/清理

## 本地旧副本排查口令

当用户反馈“我测到的和 UAT 不一样”时，先跑：

```powershell
@(
  "$env:USERPROFILE\.agents\skills\stark-codex-windows-workbench"
  "$env:USERPROFILE\.agents\skills\codex-windows-workbench"
  "$env:USERPROFILE\.codex\skills\stark-codex-windows-workbench"
) | ForEach-Object {
  [pscustomobject]@{
    Path = $_
    Exists = Test-Path $_
    SkillName = if (Test-Path (Join-Path $_ 'SKILL.md')) {
      (Select-String -Path (Join-Path $_ 'SKILL.md') -Pattern '^name:\s*(.+)$').Matches.Groups[1].Value
    } else { $null }
  }
}
```

若 `Exists=True` 但 `SkillName` 还是旧名，优先判定为**本地安装残留**，不是 skill 运行时回归。


### 坑 15：安装日志与结果可读性不足

现象：

- WhatIf/Apply 结果偏 JSON，用户不知道“到底会装什么”
- 进度日志在 `-Json` 模式下几乎不可见
- Agent 容易只贴原始 JSON，用户更不敢确认 Apply

修复：

1. 计划动作补充 `Description` / `Category` / `Items`
2. 报告增加结构化 `Impact` 与人类可读 `Summary`
3. 始终打印 `======== Workbench Summary ========`
4. Apply 增加分步 `Steps`（installed/skipped/log path）
5. 路径展示脱敏为 `%USERPROFILE%`
6. `SKILL.md` 要求 Agent 先讲 Summary，再给细节

经验：

- 安全预览不只是 `Changed=false`，还要让用户读得懂影响面
- 日志要同时服务机器解析（JSON）和人类确认（Summary）


### 坑 16：根目录 SKILL.md 导致 npx skills 安装不完整

现象：

```text
npx skills add yuanyuanyuan/stark-codex-windows-workbench
=> .agents/skills/stark-codex-windows-workbench/SKILL.md
=> 没有 scripts/ config/
```

原因：

- skills CLI 对仓库**根目录 skill** 会退化成只安装 `SKILL.md`
- 同级 `scripts/`、`config/` 不会被一起拷贝

修复：

```text
skills/stark-codex-windows-workbench/
  SKILL.md
  scripts/
  config/
  agents/
  references/
```

经验：

- skill 可发现 ≠ skill 可运行
- 验收安装时必须检查 `scripts/Initialize-...ps1` 是否存在，不能只看 `SKILL.md`

## 结束语

这次发布真正难的不是 PowerShell 脚本，而是把一个本地工作台工程，收成一个：

- 名字统一
- 多通道可装
- 可直接调用
- Agent 可按文档执行
- 效果可预览、可验证、可回滚

的公开 skill。

并且 README 要让人在一屏内看懂：

- 是什么
- 解决什么
- 为什么用
- 怎么装 / 怎么用 / 怎么卸

以后再发 skill，直接按本文检查清单走，可以少踩一轮身份、分发和文档结构坑。

## 坑 17：没有回归 UAT 门禁，会重复“源码绿、安装残缺”

现象：

- 源码树 WhatIf 正常
- skill 可被发现
- 但 `npx skills add` 安装后只有 `SKILL.md`
- 因为 UAT 没把“安装产品目录完整性”做成强制门禁

修复（制度化，不只是修一次）：

1. 建立 `docs/uat/`：
   - `REGRESSION-RULES.md`：何时必跑、硬门禁、通过/失败策略
   - `cases/UAT-xxx-*.md`：用例目录
   - `results/TEMPLATE.md`：结果模板
2. 建立可执行 runner：
   - `tests/uat/Invoke-UatRegression.ps1`
3. 每次更新至少跑 Tier A：

```powershell
pwsh -NoLogo -NoProfile -File .\tests\uat\Invoke-UatRegression.ps1
```

4. 打包/发布前再跑 Tier B（网络安装探针）：

```powershell
pwsh -NoLogo -NoProfile -File .\tests\uat\Invoke-UatRegression.ps1 -IncludeNetwork
```

硬门禁必须包含：

- 包布局是 `skills/<name>/`
- 安装产品目录含 scripts/config/agents
- 从 packaged/installed path 跑 WhatIf，而不是只测源码错觉路径
- 默认 Core+Agent、无 WSL-like action
- Summary/Impact 可读
- 文档安装通道正确，且无 chat `/plugin`

规则：

- 发现一次 false-pass，就永久加一条会抓住它的 UAT case
- CI 默认跑 Tier A；真实装包 Apply 永不默认进 CI

