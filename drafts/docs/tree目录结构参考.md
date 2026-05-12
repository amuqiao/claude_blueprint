> https://github.com/faizkhairi/claude-code-blueprint 完整的注释目录树

```
faizkhairi/claude-code-blueprint/
│
├── CLAUDE.md                          # 全局行为规则主文件（每次会话自动加载）
│                                      # 含三大强制规则：Verify-After-Complete /
│                                      # Diagnose-First / Plan-First
│                                      # 144行，偏长；Stack Rules 节留空由用户填写
│
├── ARCHITECTURE.md                    # 系统设计文档
│                                      # 含：会话生命周期 hook 流程图、11个 agent
│                                      # 的协作关系图、模型分级策略表、双轨记忆架构图
│
├── BENCHMARKS.md                      # 性能基准与成本数据
│                                      # 记录各组件的 token 消耗量，证明"hook 零
│                                      # token、CLAUDE.md 约 2300 token/session"
│
├── CHANGELOG.md                       # 版本变更记录
│
├── CLAUDE.md                          # 同上（根目录，即安装目标文件）
│
├── CODE_OF_CONDUCT.md                 # 社区行为准则（公开仓库标配）
│
├── CONTRIBUTING.md                    # 贡献指南：如何提 PR、测试方法
│
├── CROSS-TOOL-GUIDE.md                # 跨工具迁移指南
│                                      # 将本仓库的概念映射到 Cursor / Codex CLI /
│                                      # Gemini CLI / Windsurf，方便从其他工具迁移的用户
│
├── GETTING-STARTED.md                 # 新手引导文档（30分钟入门）
│                                      # 覆盖：CLI 基础、MCP 服务器、首次 session、
│                                      # 不同背景用户的分级采纳路径
│
├── LICENSE                            # MIT 开源协议
│
├── PRESETS.md                         # 分级安装预设（★ 核心使用入口）
│                                      # Minimal（5min）/ Standard（15min）/
│                                      # Full（30min）/ CI-CD 四档，每档含
│                                      # 文件清单 + settings.json 片段
│                                      # 附各技术栈的 Stack Rules 模板
│
├── README.md                          # 项目主页（含多语言版本链接）
│   ├── README.ja.md                   # 日文版
│   ├── README.ko.md                   # 韩文版
│   └── README.zh.md                   # 简体中文版
│
├── SECURITY.md                        # 安全漏洞报告规范
│
├── SETTINGS-GUIDE.md                  # settings.json 完整字段说明
│                                      # 每个字段的含义、成本影响、
│                                      # CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
│                                      # 实验性多 agent 标志位的使用方法
│
├── TROUBLESHOOTING.md                 # 排障手册
│                                      # 覆盖：hook 不触发、agent 失败、MCP 崩溃、
│                                      # 费用超预期、Windows 路径问题
│
├── WHY.md                             # 设计决策溯源文档（★ 最有价值的文件）
│                                      # 每个组件存在的原因均追溯到一次真实事故
│                                      # 13个"战斗故事"：config保护/PreCompact/
│                                      # 模型分级/worktree隔离/permissionMode/
│                                      # Plan-First/Verify-After-Complete/记忆双轨等
│
├── .gitignore
│
├── .github/                           # GitHub 仓库配置
│   ├── ISSUE_TEMPLATE/                # Issue 模板
│   └── PULL_REQUEST_TEMPLATE.md       # PR 模板
│
├── agents/                            # 11 个 subagent 定义（独立上下文窗口）
│   │                                  # 每个文件含 frontmatter（name/description/
│   │                                  # tools/model/permissionMode）+ system prompt
│   │
│   ├── project-architect.md           # 架构师（Opus）：系统设计、技术选型、迁移规划
│   ├── backend-specialist.md          # 后端专家（Sonnet+Write）：路由、服务、数据库
│   ├── frontend-specialist.md         # 前端专家（Sonnet+Write）：组件、状态、设计思维
│   ├── qa-tester.md                   # 测试工程师（Sonnet+Write）：测试用例、覆盖率
│   ├── code-reviewer.md               # 代码审查（Sonnet+worktree）：新鲜上下文独立审查
│   ├── security-reviewer.md           # 安全审查（Sonnet+worktree+plan）：只读，专查漏洞
│   ├── db-analyst.md                  # 数据库分析（Sonnet+plan）：只读，查询性能分析
│   ├── devops-engineer.md             # DevOps（Sonnet+plan）：只读，部署风险评估
│   ├── verify-plan.md                 # 计划验证（Sonnet+plan）：执行前七点机械检查
│   ├── api-documenter.md              # API 文档（Haiku）：低复杂度，模板化输出
│   └── docs-writer.md                 # 文档撰写（Haiku）：README、变更日志等
│
├── assets/                            # 仓库媒体资源
│   └── walkthrough.gif                # README 中展示的操作演示动图
│
├── examples/                          # 可直接使用的配置示例
│   └── settings-template.json         # 完整 settings.json 模板
│                                      # 含全部 hook 注册、权限规则、路径变量
│                                      # 直接复制后替换用户名即可使用
│
├── hooks/                             # 10 个 shell 脚本（零 token 成本，100% 执行）
│   │                                  # 脚本路径在 settings.json 的 hooks 字段注册
│   │                                  # 触发时机覆盖 Claude Code 的 9 个生命周期事件
│   │
│   ├── protect-config.sh              # PreToolUse/Write|Edit
│   │                                  # 拦截对 .eslintrc/tsconfig/prettier 等配置的修改
│   │                                  # 起因：Claude 通过禁用 lint 规则来"修复"报错
│   │
│   ├── block-git-push.sh              # PreToolUse/Bash
│   │                                  # 检测并拦截 git push 命令
│   │                                  # 起因：自动 push 触发 CI/CD 污染队友分支
│   │
│   ├── notify-file-changed.sh         # PostToolUse/Write|Edit（async）
│   │                                  # 修改源文件后提醒"请验证变更效果"
│   │
│   ├── post-commit-review.sh          # PostToolUse/Bash（检测 git commit）
│   │                                  # commit 后触发代码审查提醒，标注高风险文件
│   │
│   ├── cost-tracker.sh                # Stop 事件
│   │                                  # 每次 session 结束后将 token 用量写入
│   │                                  # ~/.claude/metrics/costs.jsonl
│   │
│   ├── session-checkpoint.sh          # Stop + SessionEnd 双触发
│   │                                  # 写入时间戳面包屑，用于崩溃恢复定位
│   │
│   ├── precompact-state.sh            # PreCompact
│   │                                  # 上下文压缩前将工作状态序列化到磁盘
│   │                                  # 起因：长会话压缩后 Claude 丢失当前计划上下文
│   │
│   ├── session-start.sh               # SessionStart
│   │                                  # 注入工作区上下文，恢复上次 session 状态
│   │
│   ├── stop-security-verify.sh        # Stop（model: sonnet）
│   │                                  # 每次回复结束后做安全审查（SQL注入/硬删除/密钥泄露）
│   │                                  # 起因：用 Haiku 审查时漏过了 SQL 注入模式
│   │
│   └── mcp-fallback.sh                # PostToolUseFailure（mcp__* 匹配）
│                                      # MCP 工具调用失败时注入降级指导提示
│
├── memory-template/                   # 外部记忆系统模板（git 托管，跨 session 持久化）
│   │                                  # 与 Auto-memory（~/.claude/projects/）互补
│   │                                  # Auto-memory 存技术模式，外部记忆存关系型上下文
│   │
│   ├── README.md                      # 初始化指南：如何建立独立的记忆 git 仓库
│   ├── MEMORY.md                      # 记忆索引文件（保持 <100 行，超出则提取到 topic 文件）
│   └── core/
│       ├── session.md                 # 工作记忆：当前计划、修改文件、待验证项
│       ├── preferences.md             # 用户画像：编码风格、沟通偏好、技术选型倾向
│       ├── reminders.md               # 持久任务：跨 session 的待办事项
│       └── decisions.md              # 架构决策日志：技术选型的理由和权衡记录
│
├── rules/                             # 5 个路径作用域规则文件
│   │                                  # 含 paths frontmatter，只在处理匹配文件时加载
│   │                                  # 不匹配时零 token 消耗
│   │
│   ├── session-lifecycle.md           # 全局加载（无 paths）：session 级别的行为规则
│   ├── database-schema.md             # paths: [**/schema.prisma, **/migrations/**]
│   │                                  # 处理数据库文件时加载：迁移规范、字段命名约定
│   ├── api-endpoints.md               # paths: [**/routes/**, **/controllers/**]
│   │                                  # 处理路由文件时加载：接口设计约定
│   ├── frontend-components.md         # paths: [**/*.vue, **/*.tsx, **/*.jsx]
│   │                                  # 处理前端组件时加载：状态管理、渲染规则
│   └── test-files.md                  # paths: [**/*.test.*, **/*.spec.*]
│                                      # 处理测试文件时加载：测试命名、覆盖率要求
│
└── skills/                            # 17 个自然语言触发的工作流
    │                                  # 每个 skill 一个目录，含 SKILL.md 入口文件
    │                                  # Claude 根据 description 自动判断何时加载
    │                                  # 闲置时仅消耗 ~100 token（只加载 description）
    │
    ├── review/                        # 代码审查工作流：自动派发 1-3 个审查 agent
    ├── sprint-plan/                   # 冲刺规划：分解功能到可执行任务
    ├── deploy-check/                  # 部署前检查：环境变量/迁移/依赖/回滚计划
    ├── test-check/                    # 测试覆盖验证：识别未覆盖的关键路径
    ├── load-session/                  # 8 项上下文恢复：session 开始时重建工作状态
    ├── debug-mode/                    # 调试模式：系统化定位根因
    ├── git-commit/                    # 规范 commit：生成符合约定的 commit message
    ├── create-pr/                     # PR 创建：描述、变更列表、测试说明
    ├── create-branch/                 # 分支创建：命名规范、从正确基础分支创建
    ├── update-docs/                   # 文档同步：代码变更后更新相关文档
    ├── check-types/                   # 类型检查：运行 tsc 并解读错误
    ├── check-lint/                    # Lint 检查：运行 linter 并修复可自动修复的问题
    ├── run-tests/                     # 测试执行：运行测试套件并解读失败
    ├── security-scan/                 # 安全扫描：检查依赖漏洞和代码安全问题
    ├── perf-check/                    # 性能检查：识别 N+1 查询和渲染瓶颈
    ├── db-migrate/                    # 数据库迁移：生成、验证、执行迁移
    └── api-document/                  # API 文档生成：从代码提取接口文档
```