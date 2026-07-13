# 发布 Skill 经验总结（Codex / Windows）

日期：2026-07-12  
仓库：`yuanyuanyuan/stark-codex-windows-workbench`  
Skill：`stark-codex-windows-workbench`

## 背景

把本地 Windows 工作台工程整理成可公开发布的 Skill 时，最容易犯的错不是脚本本身，而是**产品身份与分发口径不一致**：

- 把“安装脚本仓库”写成 README 主角
- 仓库名、Skill 名、Plugin 名三套名字并行
- 安装方式只写一种，导致用户环境装不上
- 使用方式写成触发词说明，而不是直接调用

## 核心结论

### 1. 先定身份，再定仓库名

- **Skill 名是产品身份**：`stark-codex-windows-workbench`
- **仓库名是分发容器**：应尽量与 Skill 名一致
- 用户看到的调用入口只有 skill 名：
  - `stark-codex-windows-workbench`
  - `/stark-codex-windows-workbench`

错误示例：

- Skill 叫 `stark-codex-windows-workbench`
- 仓库叫 `windows-pwsh-agent-workbench`
- README 又按“bootstrap installer”写

结果是安装命令、plugin 命令、文档口径全部漂移。

### 2. 安装要支持多通道，不绑死单一商店

公开 Skill 至少同时提供 4 类安装路径：

1. **RedSkill**  
   给中文 Agent/商店用户的固定安装话术。
2. **npx skills add（推荐）**  
   ```bash
   npx skills add yuanyuanyuan/stark-codex-windows-workbench
   ```
3. **Plugin Marketplace**  
   ```text
   codex plugin marketplace add yuanyuanyuan/stark-codex-windows-workbench
   codex plugin add stark-codex-windows-workbench@stark-codex-windows-workbench
   ```
4. **Manual Git Clone**  
   ```bash
   git clone https://github.com/yuanyuanyuan/stark-codex-windows-workbench.git %USERPROFILE%\.codex\skills\stark-codex-windows-workbench
   ```

原则：

- README 只展示命令，不讲长篇原理
- 推荐路径放最前（本项目推荐 `npx skills add`）
- 仓库 URL、owner/repo、skill 名必须逐字一致

### 3. 使用方式只写直接调用

不要写：

- 触发关键词列表
- “当你说 XXX 时会自动……”
- 一堆自然语言示例冒充调用方式

应写成：

```text
stark-codex-windows-workbench
/stark-codex-windows-workbench
```

需要参数时，再在 skill 内部路由；README 不承担命令百科。

### 4. 为多宿主补齐最小清单文件

为了同时兼容 skill 安装器与 plugin marketplace，公开仓库至少保留：

```text
SKILL.md
agents/openai.yaml
package.json
.codex-plugin/plugin.json
.claude-plugin/plugin.json
```

约束：

- `SKILL.md` 的 `name` = skill 调用名
- plugin `name` 与 skill 名保持一致，避免 `@marketplace` 安装时二次映射
- `package.json` / plugin homepage / repository 全部指向最终仓库名

### 5. 公开 MVP 边界必须写死

本项目公开版边界：

- Windows + PowerShell 7+
- 默认 Core + Agent
- 不做 WSL / bash / apt / brew
- 不自动登录
- 不写 secret / MCP 凭据
- 回滚只恢复受管设置，不卸载软件包

边界写进 README 与 `SKILL.md`，比事后解释事故便宜。

## 发布检查清单

发布前逐项确认：

1. Skill 名、仓库名、plugin 名是否一致
2. README 中英安装命令是否可直接复制
3. 是否同时覆盖 RedSkill / npx / plugin / clone
4. 使用区是否只有直接调用，没有触发词废话
5. `SKILL.md` frontmatter 是否只有必要字段且描述可发现
6. 是否存在用户名、绝对个人路径、代理、token 等敏感信息
7. CI / contract 测试是否通过
8. GitHub 仓库 description 是否按 skill 语义写，而不是 installer 语义
9. 旧仓库名是否完成 rename，并同步 remote / README / release 文案
10. 是否沉淀本次发布经验到 `docs/lession-learn/`

## 本次实际踩坑

1. **先按安装器项目写 README**  
   用户一眼判断“这不是 skill”。修复：README 以 skill 安装/调用为中心。
2. **仓库名与 skill 名脱节**  
   `windows-pwsh-agent-workbench` 不是 skill 名，导致安装命令不可直觉。修复：重命名为 `stark-codex-windows-workbench`。
3. **使用说明过重**  
   写了触发场景和示例句，偏离“直接调用”。修复：使用区只保留 skill 名调用。
4. **安装通道过窄**  
   只写 RedSkill 时，npx / plugin / clone 用户无路径。修复：四通道并列。

## 可复用模板

### 命名

```text
skill name   = stark-codex-windows-workbench
repo name    = stark-codex-windows-workbench
plugin name  = stark-codex-windows-workbench
```

### 安装区最小骨架

```markdown
## Install

### RedSkill
...

### npx (Recommended)
npx skills add <owner>/<repo>

### Plugin Marketplace
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

## 一句话

发布 skill 时，先把**名字、安装、调用**三件事对齐；脚本再强，文档身份错了也等于没发布成功。

## 安装通道实测（2026-07-13）

在本机对当前根 `SKILL.md` 布局做了验证：

1. **npx skills add（通过）**
   - `npx skills add yuanyuanyuan/stark-codex-windows-workbench --list` → Found 1 skill: `stark-codex-windows-workbench`
   - `npx skills add . -g -y -s stark-codex-windows-workbench -a codex --copy` → 安装到 `~\.agents\skills\stark-codex-windows-workbench`
2. **Manual clone（通过）**
   - 根目录直接是 skill 目录：`SKILL.md` + `scripts/` + `agents/`
3. **Plugin Marketplace（清单已补齐）**
   - `.codex-plugin/plugin.json` 通过 `validate_plugin.py`
   - `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` 对齐 marketplace 源仓库结构
4. **RedSkill（仍为商店分发通道）**
   - 仓库侧提供安装话术；是否上架取决于 RedSkill 商店，不由仓库结构单独保证

布局决策：

- 保持**根目录 skill**（Codex skill-creator 默认）
- 不为了 Claude monorepo 风格强行迁到 `skills/<name>/`，避免破坏 `npx` 已验证路径与现有脚本相对路径

## Agent 可执行安装文档（2026-07-13）

新增 `docs/install.md`，模式参考 Agent Reach：

- 人类入口一句话：
  `帮我安装 stark-codex-windows-workbench：https://raw.githubusercontent.com/yuanyuanyuan/stark-codex-windows-workbench/master/docs/install.md`
- 文档主体写给 AI Agent：目标、边界、目录规则、分步命令、安全模式、失败处理、验收模板
- README 中英都挂上 raw install.md 入口
- 这样不依赖用户先读 README，也能让 Agent 按文档完成 skill 安装与可选工作台配置

## install.md 审查修复（2026-07-13）

审查发现并修复：

1. Apply/Rollback 文档补 `-Confirm:$false`，避免 High ConfirmImpact 卡住 Agent
2. `-EnableSafetyHooks` 接入 Apply 与 WhatIf plan
3. WhatIf `Phases` 改为 `Planned` / `NotSelected`，并输出 `Selected`
4. `-AgentClients` 明确为 Codex 探测，不安装/不登录
5. 文档披露 Core 真实影响面与 winget 硬依赖
6. README 顶部增加痛点、解决什么、Before/After


## Plugin 安装命令纠错（2026-07-13）

错误：README 写成聊天斜杠命令 `/plugin marketplace add ...`，Codex 会报：
`Unrecognized command '/plugin'`

正确：使用终端 CLI：

```bash
codex plugin marketplace add yuanyuanyuan/stark-codex-windows-workbench
codex plugin add stark-codex-windows-workbench@stark-codex-windows-workbench
```

注意：
- `/plugin` 不是 Codex 聊天 slash command
- `codex plugin install` 也不存在；安装插件用 `codex plugin add`

