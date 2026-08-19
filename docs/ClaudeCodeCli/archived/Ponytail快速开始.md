# Ponytail 快速开始

> 本文负责把 Ponytail 从“一个插件仓库”还原成新手能直接执行的上手路径：它解决什么问题、安装后如何生效、不同 agent host 该选哪条安装路线，以及如何验证它真的在工作。

## 文档定位

这是一份快速开始文档，适合第一次接触 Ponytail、只想先把它装起来并知道如何使用的人。

本文不负责展开 benchmark 方法，也不负责逐条解释 Ponytail 内部规则。需要源码、完整说明和指标来源时，回到原仓库 README 和 zread 页面继续阅读。

资料来源：

- zread 页面：`https://zread.ai/DietrichGebert/ponytail/2-quick-start`
- GitHub 仓库：`https://github.com/DietrichGebert/ponytail`

## 一句话理解

Ponytail 是一套给 AI coding agent 使用的“少写但不偷懒”规则和插件：它让 agent 在写代码前先判断能不能跳过、复用现有实现、使用标准库或平台原生能力，最后才写最小必要实现。

## 核心心智模型

Ponytail 不是让 agent 盲目压缩代码，而是把“先理解、再少写”的判断顺序固定下来。

```text
用户提出代码任务
  |
  v
agent 先读相关代码和真实调用路径
  |
  v
按 Ponytail 阶梯判断
  |
  +-- 不需要存在？          -> 不写
  +-- 代码库已有？          -> 复用
  +-- 标准库能做？          -> 用标准库
  +-- 平台原生能做？        -> 用原生能力
  +-- 已安装依赖能做？      -> 用现有依赖
  +-- 一行能解决？          -> 写一行
  +-- 以上都不满足？        -> 写最小可工作的实现
```

这条阶梯的边界很重要：

| Ponytail 会减少什么 | Ponytail 不会砍掉什么 |
|---|---|
| 不必要的抽象 | 信任边界校验 |
| 重复实现 | 数据丢失处理 |
| 额外依赖 | 安全要求 |
| 过早封装 | 可访问性要求 |
| 为未来猜测写的代码 | 必要验证 |

## 快速开始路径

先按你正在使用的 agent host 选择安装路线。

```text
我用什么工具？
  |
  +-- Codex CLI / Codex desktop
  |     -> 安装 Codex plugin
  |
  +-- Claude Code
  |     -> 安装 Claude plugin
  |
  +-- Gemini / Antigravity / OpenCode / Copilot CLI / Pi / Swival / OpenClaw
  |     -> 使用对应 host 的插件或 skill 安装方式
  |
  +-- Cursor / Windsurf / Cline / Kiro / Zed / Aider / Copilot editor
        -> 复制对应规则文件，作为 instruction-only 模式使用
```

如果只是想先在 Codex 里试用，直接看下一节。

## Codex 安装

前置要求：`node` 需要能在非交互 shell 的 `PATH` 中找到。Ponytail 的 Claude Code 和 Codex 插件会运行几个很小的 Node.js 生命周期 hook；如果找不到 `node`，rules/skills 仍可用，但自动激活和模式跟踪不会正常工作。

在终端执行：

```bash
codex plugin marketplace add DietrichGebert/ponytail
codex
```

进入 Codex 后：

1. 打开 `/plugins`。
2. 选择 Ponytail marketplace。
3. 安装 Ponytail。
4. 打开 `/hooks`。
5. 审阅并信任 Ponytail 带来的生命周期 hooks。
6. 新开一个 thread，让规则从新会话开始生效。

`/hooks` 打开的是 Codex 的 hook 审阅界面。安装后可能看到类似下面的提示：

```text
Hooks
Lifecycle hooks from config and enabled plugins.

⚠ 3 hooks need review before they can run.

Event                 Installed   Active      Review      Description
PreToolUse            0           0           0           Before a tool executes
PermissionRequest     0           0           0           When permission is requested
PostToolUse           0           0           0           After a tool executes
PreCompact            0           0           0           Before context compaction
PostCompact           0           0           0           After context compaction
SessionStart          1           0           1           When a new session starts
UserPromptSubmit      1           0           1           When the user submits a prompt
SubagentStart         1           0           1           When a subagent is created
SubagentStop          0           0           0           Right before a subagent ends its turn
Stop                  0           0           0           Right before Codex ends its turn

Press t to trust all; enter to review hooks; esc to close
```

只看 `Review` 大于 `0` 的行。上面这个例子里，真正需要处理的是 `SessionStart`、`UserPromptSubmit`、`SubagentStart` 这 3 个；其他行都是 `0`，不用管。

Ponytail `4.8.3` 在 Codex 中通常会带来这 3 个待审 hooks：

| Hook | 用途 |
|---|---|
| `SessionStart` | 新会话或恢复会话时加载 Ponytail 模式 |
| `UserPromptSubmit` | 识别 `/ponytail`、`@ponytail` 等模式切换输入 |
| `SubagentStart` | 创建 subagent 时继续注入 Ponytail 规则 |

如果不确定这些待审 hook 是否来自 Ponytail，按 `Enter` 逐个看来源或命令；看到 `ponytail`、`ponytail-activate.js`、`ponytail-mode-tracker.js`、`ponytail-subagent.js` 就是 Ponytail 的。确认无误后，按 `t` 信任全部；如果看到不认识的来源，按 `Esc` 退出，先不要信任。

信任完成后，`Review` 这一列应该不再显示待审数量。然后新开 thread 或重启 Codex，让 `SessionStart` hook 从新会话开始加载 Ponytail。

Codex desktop app 走同一套安装结果。安装后重启桌面应用，它会加载插件。

安装后的结构可以理解成：

```text
Codex
  |
  +-- plugin marketplace
  |     |
  |     +-- Ponytail plugin
  |
  +-- hooks
  |     |
  |     +-- 会话开始 / 模式切换时注入规则
  |
  +-- skills / commands
        |
        +-- @ponytail-review
        +-- @ponytail-audit
        +-- @ponytail-debt
        +-- @ponytail-gain
        +-- @ponytail-help
```

首次使用时，可以直接在新 thread 里发送：

```text
@ponytail full
```

或者在任务里直接写：

```text
用 ponytail 模式实现这个改动。
```

如果想临时关闭：

```text
@ponytail off
```

## Claude Code 安装

Claude Code 需要把 marketplace 添加和插件安装分成两条消息发送：

```text
/plugin marketplace add DietrichGebert/ponytail
```

```text
/plugin install ponytail@ponytail
```

Claude desktop app 没有 `/plugin` 命令，需要从 UI 安装：进入 Customize，通过 personal plugins 的添加入口创建 marketplace，然后从仓库添加。

## 其他 host 速查

| Host | 快速安装方式 | 备注 |
|---|---|---|
| GitHub Copilot CLI | `copilot plugin marketplace add DietrichGebert/ponytail` 后执行 `copilot plugin install ponytail@ponytail` | 交互 session 也可用 `/plugin marketplace add ...` 和 `/plugin install ...` |
| Pi agent harness | `pi install git:github.com/DietrichGebert/ponytail` | 走 Pi 的安装入口 |
| OpenCode | 在 `opencode.json` 加 `{ "plugin": ["@dietrichgebert/ponytail"] }` | 也可以指向本地 checkout 的 `.opencode/plugins/ponytail.mjs` |
| Gemini CLI | `gemini extensions install https://github.com/DietrichGebert/ponytail` | 会加载规则并注册 `/ponytail` 命令 |
| Antigravity CLI | `agy plugin install https://github.com/DietrichGebert/ponytail` | Antigravity 会把命令转成 skills |
| CodeWhale | 从仓库根目录运行，或复制 `AGENTS.md` 到项目根目录 | 免插件，读规则文件 |
| Swival | `swival skills add --global https://github.com/DietrichGebert/ponytail` 后按需 `swival skills add ponytail` | 可项目级或全局激活 |
| OpenClaw | `clawhub install ponytail` | 相关 review、audit、debt、gain、help skill 可分别安装 |

## 规则文件模式

有些工具不走插件，而是读取项目里的规则文件。可以把它理解成“没有 hook 和命令菜单，但规则仍会被 agent 读到”。

```text
插件模式
  = 规则文件 + 自动激活 + 模式命令 + hooks

规则文件模式
  = 只把 Ponytail 的写代码规则放进 agent 上下文
```

常见映射：

| 工具 | 使用的规则入口 |
|---|---|
| Cursor | `.cursor/rules/` |
| Windsurf | `.windsurf/rules/` |
| Cline | `.clinerules` |
| GitHub Copilot editor | `.github/copilot-instructions.md` |
| Kiro | `.kiro/steering/` |
| Codex extension for VS Code | `AGENTS.md` |
| 通用 instruction-only 场景 | 复制仓库内对应规则文件 |

如果你只需要“让 agent 少过度设计”，规则文件模式通常已经够用；如果你还需要模式切换、审查命令和 hook 提示，用插件模式。

## 常用命令

安装后，Ponytail 提供几类命令。不同 host 的触发方式略有差异：Claude Code 和 OpenCode 等通常用 `/`，Codex 中这些能力作为 skill 使用，调用时用 `@`。

| 命令 | 作用 |
|---|---|
| `/ponytail [lite \| full \| ultra \| off]` | 设置强度，或关闭 Ponytail；不带参数时查看当前模式 |
| `/ponytail-review` | review 当前 diff，找出过度工程化内容 |
| `/ponytail-audit` | 审计整个仓库中的过度工程化，不只看当前 diff |
| `/ponytail-debt` | 收集用 `ponytail:` 标记延期处理的技术债 |
| `/ponytail-gain` | 查看 benchmark 影响数据 |
| `/ponytail-help` | 查看命令速查 |

Codex 中的对应调用可以这样理解：

```text
/ponytail-review   -> 其他支持 slash command 的 host
@ponytail-review   -> Codex skill 调用方式
```

## 模式选择

Ponytail 默认模式是 `full`。可以按任务强度调整：

| 模式 | 适合场景 |
|---|---|
| `lite` | 只想轻度提醒 agent 少写无用代码 |
| `full` | 日常默认模式 |
| `ultra` | 代码库过度抽象严重，需要更强约束 |
| `off` | 临时关闭 Ponytail |

也可以为每个新会话设置默认模式：

```bash
PONYTAIL_DEFAULT_MODE=full
```

或者写入配置文件：

```json
{
  "defaultMode": "full"
}
```

配置文件位置：

| 系统 | 路径 |
|---|---|
| macOS / Linux | `~/.config/ponytail/config.json` |
| Windows | `%APPDATA%\ponytail\config.json` |

## 安装后如何验证

最小验证不是看插件列表，而是发一个容易过度设计的小任务，观察 agent 是否先复用平台能力。

可以用这个测试：

```text
请实现一个日期选择输入。
```

期望倾向：

```html
<input type="date">
```

如果 agent 直接引入日期选择库、写包装组件、加样式系统和时区抽象，说明 Ponytail 没有生效，或当前模式太弱。

更完整的验证链路：

```text
插件已安装
  -> /hooks 中 Ponytail hooks 已信任，Review 列没有待审数量
  -> 新 thread 已开启
  -> 当前模式不是 off
  -> 小任务输出明显更少但不牺牲必要质量
```

如果验证失败，按这个顺序排查：

1. `/plugins` 里 Ponytail 是否已安装并启用。
2. `/hooks` 里是否还有 Ponytail hooks 待 review。
3. `node` 是否能在非交互 shell 中运行。
4. 是否已经新开 thread 或重启 Codex。
5. 当前模式是否被切到 `off`。

## 卸载

| Host | 卸载方式 |
|---|---|
| Claude Code | `/plugin remove ponytail` |
| Codex | `codex plugin remove ponytail` |
| Pi agent | `pi uninstall ponytail` |
| Cursor / Windsurf / Cline 等规则文件模式 | 删除复制过去的规则文件 |

插件卸载会删除插件自身文件，但 Ponytail 可能还留下少量状态，例如模式标记、`~/.config/ponytail/config.json`，以及曾写入的 status line 配置。

如果需要清理这些状态，先从 Ponytail checkout 或已安装插件目录中运行：

```bash
node scripts/uninstall.js
```

再执行 host 自己的插件卸载命令。顺序不能反过来，因为先卸载插件会把清理脚本一起删掉；如果已经先卸载了插件，就从 GitHub 仓库重新 clone 一份 Ponytail，再在 clone 里运行同一个清理脚本。

Codex 的完整卸载顺序是：

```bash
node scripts/uninstall.js
codex plugin remove ponytail
```

卸载后可以打开 `/plugins` 确认 Ponytail 不在已安装列表里，再打开 `/hooks` 确认没有 Ponytail 来源的待审或 active hooks。

## 新手使用建议

先不要把 Ponytail 当成“压缩代码工具”。它更像一个写代码前的刹车：

```text
先确认问题真实存在
再确认已有系统没有现成解法
再确认平台和标准库不能解决
最后才写新代码
```

日常使用时，最重要的是保留这条边界：少写不等于少验证，少抽象不等于少安全处理。Ponytail 要减少的是无必要复杂度，不是工程质量。
