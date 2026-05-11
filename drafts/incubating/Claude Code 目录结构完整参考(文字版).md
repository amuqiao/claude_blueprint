好，现在我有了足够准确的官方文档依据，来输出两个版本。先输出文字 tree，再输出 HTML 可视化。

---

## 一、文字 tree 格式（官方准确版）

```
# ────────────────────────────────────────────────
# 系统级目录  ~/.claude/
# 适用于当前用户的所有项目，个人私有，不提交 git
# ────────────────────────────────────────────────

~/.claude/
├── CLAUDE.md                        # 【官方确认】全局个人指令，每次会话自动加载；
│                                    # 放跨项目的个人偏好、工具习惯等
├── settings.json                    # 【官方确认】全局设置：权限规则、hooks、环境变量、
│                                    # 默认模型等；作用于所有项目
│
├── rules/                           # 【官方确认】全局模块化指令目录；按主题拆分 CLAUDE.md；
│   ├── preferences.md               # 支持递归子目录；无 paths frontmatter 则全局加载；
│   └── workflows.md                 # 有 paths frontmatter 则按文件路径条件加载
│
├── commands/                        # 【官方确认】全局自定义斜杠命令；
│   └── my-command.md                # 文件名（去掉.md）即命令名 → /my-command
│                                    # 本质是单文件 skill，与 skills/ 共用机制
│
├── skills/                          # 【官方确认】全局可复用工作流；每个 skill 是一个目录；
│   └── create-pr/                   # 支持符号链接；跨所有项目可用
│       └── SKILL.md                 # 入口文件；frontmatter 含 name/description/
│                                    # allowed-tools/model 等字段
│
├── agents/                          # 【官方确认】全局子智能体定义；
│   └── code-reviewer.md             # 每个有独立 system prompt、工具权限、可指定模型
│
├── agent-memory/                    # 【官方确认】子智能体持久记忆目录
│   └── <agent-name>/                # 与 agents/*.md 中 name 字段对应
│
├── output-styles/                   # 【官方确认】自定义系统提示词片段；注入 system prompt；
│   └── terse.md                     # 控制回复风格，如"只输出代码"
│
├── keybindings.json                 # 【官方确认】自定义键盘快捷键
│
├── plugins/                         # 【官方确认】插件安装数据；由 claude plugins add 管理；
│   ├── installed_plugins.json       # 勿手动编辑
│   ├── known_marketplaces.json
│   └── cache/                       # 插件缓存文件
│
└── projects/                        # 【官方确认】Claude Code 运行时自动写入，勿手动编辑
    └── <project-hash>/              # 每个项目一个目录，由 git repo 路径派生
        └── memory/                  # Auto memory 存储目录（需 v2.1.59+）
            ├── MEMORY.md            # 索引文件；每次会话加载前 200 行或 25KB
            ├── debugging.md         # Claude 自动创建的主题记忆文件（示例）
            └── ...                  # 其他 Claude 自动生成的主题文件


# 注：~/.claude.json（注意：是文件不是目录）
# 【官方确认】存放 OAuth token、用户级 MCP 服务器配置、
# per-project 已授权工具状态等；自动生成，勿手动编辑
# 路径：~/.claude.json（家目录下，不在 .claude/ 内）


# ────────────────────────────────────────────────
# 组织管理员级（Managed，最高优先级，IT 部署）
# ────────────────────────────────────────────────
# macOS:   /Library/Application Support/ClaudeCode/
# Linux:   /etc/claude-code/
# Windows: C:\Program Files\ClaudeCode\
#
# 【官方确认】该目录下：
#   CLAUDE.md              # 组织级指令，所有用户强制加载，不可被排除
#   managed-settings.json  # 组织级权限配置，优先级最高，不可被用户覆盖
#   managed-mcp.json       # 组织级 MCP 服务器配置
#   managed-settings.d/    # 【官方确认】drop-in 分片目录；*.json 按字母序合并
#       10-security.json
#       20-telemetry.json


# ────────────────────────────────────────────────
# 项目级目录  your-project/
# 随代码库提交，团队共享
# ────────────────────────────────────────────────

your-project/
├── CLAUDE.md                        # 【官方确认】项目指令；每次会话自动加载；
│                                    # 也可放在 .claude/CLAUDE.md（二选一）；
│                                    # 建议不超过 200 行；/init 可自动生成初稿
│
├── CLAUDE.local.md                  # 【官方确认】个人私有项目偏好；
│                                    # 与 CLAUDE.md 同时加载（追加在其后）；
│                                    # 需手动创建并加入 .gitignore；不提交
│
├── .mcp.json                        # 【官方确认】团队共享的 MCP 服务器配置；
│                                    # 必须放项目根目录；提交 git
│
├── .worktreeinclude                 # 【官方确认】列出需复制到新 worktree 的
│                                    # gitignored 文件（如 .env）
│
└── .claude/                         # Claude Code 项目配置中心
    │
    ├── CLAUDE.md                    # 【官方确认】项目指令的替代位置
    │                                # （与根目录 CLAUDE.md 二选一，效果相同）
    │
    ├── settings.json                # 【官方确认】项目级设置：权限、hooks 注册、
    │                                # 环境变量、模型默认值；提交 git，团队共享
    │
    ├── settings.local.json          # 【官方确认】个人权限覆盖；自动 gitignored；
    │                                # 不提交；仅本机生效
    │
    ├── rules/                       # 【官方确认】项目模块化指令；CLAUDE.md 过长时拆分；
    │   ├── code-style.md            # 支持 YAML frontmatter 的 paths 字段实现路径匹配；
    │   ├── testing.md               # 支持递归子目录；支持符号链接
    │   └── api-conventions.md       # 无 paths → 全局加载；有 paths → 按匹配文件加载
    │
    ├── commands/                    # 【官方确认】项目斜杠命令；
    │   ├── review.md                # 文件名（去掉.md）即命令名 → /review
    │   ├── fix-issue.md             # 本质是单文件 skill，与 skills/ 共用同一机制；
    │   └── deploy.md                # 现有 commands/ 文件继续有效，无需迁移
    │
    ├── skills/                      # 【官方确认】项目可复用工作流；
    │   └── security-review/         # 每个 skill 是一个目录；
    │       ├── SKILL.md             # 入口；frontmatter 含 name/description/
    │       │                        # allowed-tools/model 等字段
    │       └── DETAILED_GUIDE.md    # 支持文件；在 SKILL.md 中用 @引用；
    │                                # 这是 skills 与 commands 的核心区别：
    │                                # skills 可打包多个配套文件
    │
    ├── agents/                      # 【官方确认】项目子智能体；
    │   ├── code-reviewer.md         # 每个有独立上下文窗口、system prompt、
    │   └── security-auditor.md      # 工具集，可指定使用的模型
    │
    ├── agent-memory/                # 【官方确认】子智能体持久记忆；
    │   └── <agent-name>/            # 与 agents/*.md 的 name 字段对应
    │
    └── output-styles/               # 【官方确认】自定义输出风格片段；
        └── terse.md                 # 注入 system prompt；控制回复格式


# ════════════════════════════════════════════════
# ⚠️  以下内容官方文档中有明确描述，但实现细节
#     可能随版本更新变化，附注说明
# ════════════════════════════════════════════════
#
# 1. hooks 配置方式（官方确认）：
#    hooks 不是一个独立目录，而是写在 settings.json 的 "hooks" 字段中。
#    shell 脚本文件本身可放任意位置，在 settings.json 中用绝对或相对路径引用。
#    支持事件：PreToolUse / PostToolUse / Notification / Stop /
#              PreCompact / InstructionsLoaded 等（详见官方 hooks 文档）
#
# 2. plugins/ 目录（官方确认仅在系统级 ~/.claude/plugins/ 存在）：
#    项目级 .claude/ 下没有独立的 plugins/ 目录。
#    插件通过 settings.json 的 plugins 字段配置，作用范围 user 或 project。
#
# 3. statusline（官方确认存在此功能，配置在 settings.json 中）：
#    不是一个独立文件，而是 settings.json 内的配置项。
#
# 4. Auto memory（需 Claude Code v2.1.59+）：
#    默认开启；路径固定为 ~/.claude/projects/<hash>/memory/；
#    <hash> 由 git repo 路径派生，同一 repo 的所有 worktree 共享同一目录。
```

---