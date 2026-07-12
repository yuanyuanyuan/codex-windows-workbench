# 发布 Skill 经验总结（Codex / Windows）

日期：2026-07-12  
仓库：`yuanyuanyuan/codex-windows-workbench`  
Skill：`codex-windows-workbench`

## 背景

把本地 Windows 工作台工程整理成可公开发布的 Skill 时，最容易犯的错不是脚本本身，而是**产品身份与分发口径不一致**：

- 把“安装脚本仓库”写成 README 主角
- 仓库名、Skill 名、Plugin 名三套名字并行
- 安装方式只写一种，导致用户环境装不上
- 使用方式写成触发词说明，而不是直接调用

## 核心结论

### 1. 先定身份，再定仓库名

- **Skill 名是产品身份**：`codex-windows-workbench`
- **仓库名是分发容器**：应尽量与 Skill 名一致
- 用户看到的调用入口只有 skill 名：
  - `codex-windows-workbench`
  - `/codex-windows-workbench`

错误示例：

- Skill 叫 `codex-windows-workbench`
- 仓库叫 `windows-pwsh-agent-workbench`
- README 又按“bootstrap installer”写

结果是安装命令、plugin 命令、文档口径全部漂移。

### 2. 安装要支持多通道，不绑死单一商店

公开 Skill 至少同时提供 4 类安装路径：

1. **RedSkill**  
   给中文 Agent/商店用户的固定安装话术。
2. **npx skills add（推荐）**  
   ```bash
   npx skills add yuanyuanyuan/codex-windows-workbench
   ```
3. **Plugin Marketplace**  
   ```text
   /plugin marketplace add yuanyuanyuan/codex-windows-workbench
   /plugin install codex-windows-workbench@codex-windows-workbench
   ```
4. **Manual Git Clone**  
   ```bash
   git clone https://github.com/yuanyuanyuan/codex-windows-workbench.git %USERPROFILE%\.codex\skills\codex-windows-workbench
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
codex-windows-workbench
/codex-windows-workbench
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
   `windows-pwsh-agent-workbench` 不是 skill 名，导致安装命令不可直觉。修复：重命名为 `codex-windows-workbench`。
3. **使用说明过重**  
   写了触发场景和示例句，偏离“直接调用”。修复：使用区只保留 skill 名调用。
4. **安装通道过窄**  
   只写 RedSkill 时，npx / plugin / clone 用户无路径。修复：四通道并列。

## 可复用模板

### 命名

```text
skill name   = codex-windows-workbench
repo name    = codex-windows-workbench
plugin name  = codex-windows-workbench
```

### 安装区最小骨架

```markdown
## Install

### RedSkill
...

### npx (Recommended)
npx skills add <owner>/<repo>

### Plugin Marketplace
/plugin marketplace add <owner>/<repo>
/plugin install <plugin>@<plugin>

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
