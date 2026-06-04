# Flutter 开发手册
> 8 篇文档，覆盖 Flutter 项目开发的完整链路：从思维方式、项目启动、故障排查、到架构演进和测试验证。

---

## 完整学习路径

开发 Flutter 项目需要理解的 8 篇文档。**新手建议按顺序阅读前 5 篇**，之后按场景查阅。

### 核心学习路径（新手必读）

| 顺序 | 文档 | 核心问题 | 建议人群 |
|---|---|---|---|
| 1️⃣ **认知层** | [01-thinking.md](01-thinking.md) | Flutter 和命令式开发有什么本质区别？声明式思维怎么理解？ | 所有人 |
| 2️⃣ **启动层** | [00-startup.md](00-startup.md) | 如何从零开始搭建项目骨架？第一个 Feature 怎么做？ | **新手首要** |
| 3️⃣ **架构层** | [02-architecture.md](02-architecture.md) | 代码分几层？数据怎么流动？加新功能要动哪里？ | 中级+新人第二站 |
| 4️⃣ **规范层** | [04-standards.md](04-standards.md) | 导航、交互、状态、组件这类设计判断怎么做？ | 中级 |
| 5️⃣ **实现层** | [05-vibe-coding.md](05-vibe-coding.md) | 用什么 Widget？怎么告诉 AI 写代码？具体怎么用？ | 日常编码 |

### 按需查阅

| 文档 | 用途 | 查阅时机 |
|---|---|---|
| **选型层** | [03-stack.md](03-stack.md) | 不知道用哪个包/技术方案时 |
| **诊断层** | [06-diagnostics.md](06-diagnostics.md) | 遇到常见问题，快速找解决办法和根因分析 |

---

## 内容速览

| 文档 | 主要章节 | 学习深度 | 前置知识 |
|---|---|---|---|
| [01-thinking.md](01-thinking.md) | 声明式 vs 命令式、读链路、写链路、双链路协同 | 入门 | 无（必读） |
| [00-startup.md](00-startup.md) | 环境检查、项目创建、骨架搭建、第一个 Feature、常见坑点 | 手册 | 01-thinking.md |
| [02-architecture.md](02-architecture.md) | 分层结构、数据流主干、新功能开发路径、常见判断 | 中级 | 00-startup.md 完成后 |
| [03-stack.md](03-stack.md) | 核心库清单、选型决策树、版本管理、升级路线 | 中级 | 了解项目当前技术栈 |
| [04-standards.md](04-standards.md) | 导航交互规范、状态管理判断、组件职责、通用模式 | 中级 | 读过 02 架构文档 |
| [05-vibe-coding.md](05-vibe-coding.md) | Widget 速查（正向+反向）、Riverpod/Drift 写法、AI 提示词模板、编码诊断 | 速查 | 具体编码时按需查 |
| [06-diagnostics.md](06-diagnostics.md) | 问题快速诊断树、架构/编码/导航层的故障排查 | 参考 | 遇到常见问题时查阅 |
| [07-roadmap.md](07-roadmap.md) | 项目从 1-5 到 5-15 到 15+ feature 的演进阶段、重构触发信号、增长期操作指南 | 规划 | 项目规模增长时参考 |
| [08-testing.md](08-testing.md) | 单元/Widget/集成测试的分工、测试骨架代码、本地验证工作流 | 工程 | 开发完功能后编写测试 |

---

## 场景导航

### 入门与项目启动（新手必读）
| 场景 | 查阅路径 |
|---|---|
| 零基础，刚接触 Flutter | [01-thinking.md](01-thinking.md) 理解声明式思维 |
| 要从头搭建第一个 Flutter 项目 | [00-startup.md](00-startup.md)（新手首要入口） |
| 项目骨架搭完，要加第二个功能 | [02-architecture.md](02-architecture.md) 第四章 新功能开发路径 |
| 想理解项目为什么这样设计 | [01-thinking.md](01-thinking.md) + [02-architecture.md](02-architecture.md) |

### 日常编码
| 场景 | 查阅路径 |
|---|---|
| 在写 UI，需要选合适的 Widget | [05-vibe-coding.md](05-vibe-coding.md) Part 1 Widget 速查 |
| 在用 Riverpod，需要具体写法示例 | [05-vibe-coding.md](05-vibe-coding.md) Part 2 Riverpod 操作 |
| 在用 Drift，需要查询 / 更新 / 删除写法 | [05-vibe-coding.md](05-vibe-coding.md) Part 2 Drift 操作 |
| 不知道怎么告诉 AI 写代码 | [05-vibe-coding.md](05-vibe-coding.md) 提示词模板 |

### 新功能开发
| 场景 | 查阅路径 |
|---|---|
| 要加一个新功能，不知道要动哪里 | [02-architecture.md](02-architecture.md) 新功能开发路径 |
| 需要判断某个功能应该放在哪一层 | [02-architecture.md](02-architecture.md) 分层结构 |
| 不知道数据怎么流动 | [02-architecture.md](02-architecture.md) 数据流主干 |

### 技术选型与重构
| 场景 | 查阅路径 |
|---|---|
| 不知道用哪个包，或该用哪个 Provider 方式 | [03-stack.md](03-stack.md) 选型决策树 |
| 需要了解当前技术栈和升级路线 | [03-stack.md](03-stack.md) 核心库清单、版本管理 |
| 遇到版本冲突或包兼容性问题 | [03-stack.md](03-stack.md) 版本管理章节 |

### 设计判断与问题排查
| 场景 | 查阅路径 |
|---|---|
| 遇到导航、交互或状态的设计判断问题 | [04-standards.md](04-standards.md) |
| 不确定某个状态该怎么管理 | [04-standards.md](04-standards.md) 三、状态 → 3.1 状态分层 |
| 组件职责不清，不知道怎么拆分 | [04-standards.md](04-standards.md) 四、组件 → 4.2 自定义组件边界 |

### 故障诊断与排查
| 场景 | 查阅路径 |
|---|---|
| **UI 不刷新、数据不同步** | [06-diagnostics.md](06-diagnostics.md) 二、数据与状态问题 |
| **Provider / Riverpod 相关错误** | [06-diagnostics.md](06-diagnostics.md) 三、编码层问题 |
| **Drift 数据库异常** | [06-diagnostics.md](06-diagnostics.md) 三、编码层问题 |
| **页面跳转失败 / 参数问题** | [06-diagnostics.md](06-diagnostics.md) 四、导航与交互问题 |
| **Widget 布局异常 / RenderFlex overflowed** | [06-diagnostics.md](06-diagnostics.md) 五、布局与 UI 问题 |
| **不知道用什么 Widget** | [05-vibe-coding.md](05-vibe-coding.md) 六、按交互效果反向查询 |
| **快速查找问题症状** | [06-diagnostics.md](06-diagnostics.md) 一、问题症状快速定位 |

### 项目扩展与演进
| 场景 | 查阅路径 |
|---|---|
| 项目规模在增长，需要判断何时重构 | [07-roadmap.md](07-roadmap.md) 起步/增长/规模期的判断信号 |
| 多个 feature 之间出现重复代码 | [07-roadmap.md](07-roadmap.md) 三、增长期操作指南 |
| build 时间变长，编译缓慢 | [07-roadmap.md](07-roadmap.md) 四、常见问题与应对 |
| 团队协作 merge conflict 频繁 | [07-roadmap.md](07-roadmap.md) 四、常见问题与应对 |

### 测试与验证
| 场景 | 查阅路径 |
|---|---|
| 需要编写单元测试 | [08-testing.md](08-testing.md) 一、三种测试的分工 + 五、常用测试骨架代码 |
| 需要编写 Widget 测试 | [08-testing.md](08-testing.md) 一、Widget Test（小部件测试）|
| 需要编写集成测试验证关键流程 | [08-testing.md](08-testing.md) 一、Integration Test（集成测试）|
| 不知道什么该测、什么不必测 | [08-testing.md](08-testing.md) 二、什么该测、什么不必测 |
| 本地验证和提交前检查清单 | [08-testing.md](08-testing.md) 四、本地验证工作流 |

---

## 维护规则

| 文档 | 何时更新 |
|---|---|
| 01-thinking.md | Flutter 核心范式发生变化时（很少） |
| 00-startup.md | flutter create 模板或初始化流程变化时 |
| 02-architecture.md | 项目分层方式或数据流模式调整时 |
| 03-stack.md | 引入或替换重要依赖时 |
| 04-standards.md | 实践中发现新的稳定判断规则时 |
| 05-vibe-coding.md | Widget API 更新、项目技术栈升级时；反向索引和编码诊断部分需实时更新 |
| 06-diagnostics.md | 新增常见问题时；各相关文档添加诊断规则后同步补充 |
| 07-roadmap.md | 项目演进阶段的划分、重构信号发生变化时（通常 6+ 个月一次） |
| 08-testing.md | 测试工具/框架版本更新、发现新的测试最佳实践时 |

`archive/` 目录保留历史文档，仅供参考，不作为当前规范。
