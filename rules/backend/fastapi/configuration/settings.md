---
description: FastAPI Pydantic Settings 配置分层、派生配置与启动校验规则
---

# FastAPI 配置规则

FastAPI 配置规则负责应用进程内的 Pydantic Settings 语义：用少量配置表达部署、安全和业务意图，在 Settings 内集中派生实现参数，并在启动阶段完成统一校验。

本文只定义 FastAPI / Pydantic Settings 的字段语义、生命周期、派生方式、启动校验和机器检查。配置文件真源、运行环境注入和覆盖顺序由 `../../deployment/service-deployment.md` 定义；跨框架的配置设计原则由 `../../../configuration-design.md` 定义，本文不重复维护。

## Settings 入口与生命周期

FastAPI 服务必须使用 Pydantic Settings 作为集中配置入口。Pydantic v2 项目应使用 `pydantic-settings` 的 `BaseSettings`；旧版本项目迁移规则时，必须先确认字段校验、模型校验和配置源 API 的等价写法。

Settings 入口必须满足：

- 所有应用运行时配置从一个 settings 对象读取。
- API、Worker、Beat 和脚本任务使用同一套应用配置语义。
- `.env.example` 定义应用配置键集合、必需项和语义模板。
- 密钥和环境差异通过配置注入进入进程，不写入代码、镜像或前端产物。
- 运行形态、脚本专用变量和 SDK 自动读取的环境变量与应用 Settings 字段分开维护，并进入明确允许清单。

Settings 对象应在进程启动时初始化一次。初始化或校验失败必须阻止 API、Worker、Beat 和脚本任务继续启动；不要让入口先开始监听、接单或执行副作用，再在业务路径里发现配置错误。

业务代码应通过 FastAPI dependency、应用级单例或显式参数接收 Settings。不要在每个请求、每个任务、Service、Repository 或工具函数中重新读取 `.env`、重新构造 Settings，或直接访问 `os.environ` 取得应用配置。

## 字段分类

配置设计的目标不是暴露更多变量，而是减少使用者必须理解的变量数量。对外只暴露少量意图变量；存在联动关系的实现参数由 Settings 内部派生。

| 层级 | 性质 | 值的来源 | 是否进入 `.env.example` | 判断标准 |
| --- | --- | --- | --- | --- |
| `env-driven` | 随环境变化，表达部署、安全或业务意图差异 | 进程外注入，例如环境变量、Secret 或 ConfigMap | 必需项必须进入 | 变更它是在表达不同部署环境、租户、安全边界或业务承诺 |
| `tunable constants` | 项目内可调的数值型工程余量，有代码默认值 | 代码默认值，可选由环境变量覆盖 | 默认不要求进入；需要外部调优时才列入 | 变更它是在调整比例、倍数、buffer、margin 或窗口等工程余量 |
| `derived` | 由运行时配置和常量旋钮计算出的最终实现值 | Settings 内部计算，不接受外部输入 | 禁止进入 | 它不能独立决定，只是其他配置关系计算后的实现结果 |

所有 Settings 字段必须显式归类为 `env-driven`、`tunable constants`、`derived` 之一，禁止混用语义。派生结果字段不得出现在 `.env`、`.env.example` 或项目维护的配置模板中。否则维护者会以为它可以被外部独立覆盖，破坏联动语义。

判断边界时，先问这个值代表外部意图还是内部关系。同一个 timeout 值，如果表达调用方愿意等待的最长时间，它属于 `env-driven`；如果表达在主控 timeout 上额外预留多少比例或 buffer，它属于 `tunable constants`；如果是由主控 timeout 和工程余量计算出的最终执行超时，它属于 `derived`。

## 运行时配置

运行时配置只表达环境差异和业务意图，不表达内部实现链路。必需运行时配置必须有稳定 env key，并在 `.env.example` 和项目维护的各类 env 模板中保持同一语义。

运行时配置适合承载：

- 数据库、Redis、对象存储、外部服务 base URL。
- API key、JWT secret、回调密钥等敏感配置。
- 业务意图型主控变量，例如模型调用最长等待时间、单 worker 并发数、最大上传大小。
- 功能开关、环境类型标志、AB 测试标记等会随部署环境变化的开关类输入。

不要让调用方同时配置一组强依赖实现变量。例如不要同时暴露主 timeout、执行 timeout、领取窗口和僵死扫描阈值；应只暴露表达业务承诺的主控变量，其余值由 Settings 按固定关系派生。异步 Job 场景的超时链路和恢复语义由 `../../jobs/async-job.md` 补充。

敏感运行时配置字段必须避免序列化泄漏。应使用 `repr=False`、序列化 `exclude`、Secret 类型或等价方式，确保密钥、token、数据库 URL 等不会出现在 settings 对象字符串表示、`model_dump()`、日志输出或错误上报中。`.env.example`、README、部署说明和测试模板只能放不可用占位符，不放真实、可连接或可调用的密钥。

## 常量旋钮

常量旋钮只用于数值型工程余量，例如比例、倍数、buffer、margin、窗口大小。它们服务派生逻辑，降低实现变量数量，不应被设计成另一组必填运行时配置。

常量旋钮必须满足：

- 有代码默认值。
- 名字体现比例、倍数、buffer、margin 或窗口语义，不命名为最终计算值。
- 注释或文档说明量纲、合理范围和影响对象。
- 默认不要求出现在 `.env.example`；如果需要外部调优，必须说明它影响性能、成本、安全还是恢复速度。

功能开关、环境类型标志、AB 测试标记不属于常量旋钮。如果它们需要按环境变化，应归入运行时配置，并显式进入 `.env.example`。

优先使用“基数 + 旋钮”的设计，让用户配置主控基数，让工程余量留在代码默认值或高级可选配置中。

- `x + n * c`：暴露 `REQUEST_TIMEOUT_S = x` 表达用户愿意等待的基础时间，用 `STEP_BUFFER_S = c` 表达每个阶段、重试次数或队列位置带来的额外 buffer，最终执行超时作为派生配置。
- `x * r`：暴露 `REQUEST_TIMEOUT_S = x` 表达业务主 timeout，用 `EXECUTION_TIMEOUT_RATIO = r` 表达执行层相对主 timeout 的工程余量，最终执行 timeout 作为派生配置。

这些模式的重点是：`x` 是用户意图，`c` 或 `r` 是常量旋钮，`x + n * c` 或 `x * r` 的计算结果是派生配置。这样用户只理解一个主决策，开发者仍保留可控的工程余量。

## `.env.example` 单向真源

`.env.example` 是应用配置键集合、必需项和语义模板的唯一真源。项目中的 `.env`、`.env.*`、测试 env、部署 env 模板、Secret / ConfigMap 模板必须单向依赖 `.env.example`，只能为其中定义的应用配置键提供环境取值，不得新增、改名、拆分或弱化应用配置语义。

如果某个配置键需要新增、改名或删除，必须先更新 `.env.example`、Settings 字段映射和配置机器检查，再同步各类 `.env.*` 或部署模板。任何只出现在 `.env`、`.env.*` 或部署模板中、但没有出现在 `.env.example` 或明确允许清单中的 key，都应被视为未知配置并检查失败。

`.env.example` 不保存真实密钥、真实连接串或可调用凭证，只保存不可用占位符和语义说明。实际环境值属于具体运行环境，不反向定义应用配置语义。

`.env.example` 不约束所有进程环境变量，只约束应用配置键。SDK、HTTP 客户端、运行平台或启动脚本自动读取的环境变量，如果不由 Settings 消费，不应强行加入应用 Settings；但必须进入单独允许清单，并说明 key 名称、消费方、是否可选、影响范围，以及是否允许出现在 `.env`、`.env.*` 或部署模板中。例如 `HTTP_PROXY`、`HTTPS_PROXY`、`NO_PROXY` 这类代理变量可以作为 SDK / HTTP 客户端环境变量列入允许清单，而不是伪装成应用派生配置。

如果项目把代理、证书、SDK 行为或平台开关设计成显式产品能力或稳定部署承诺，应改为可选 `env-driven` 应用配置，并进入 `.env.example`。例如项目主动支持 OpenAI 出站代理时，可以定义可选 `OPENAI_PROXY_URL`；未配置表示不启用代理，代码应显式决定是否传给 client。

## Env Key 映射

Settings 字段和 env key 的映射必须集中、稳定、可机器检查。不要让字段名、alias、`.env.example`、部署模板和测试 fixture 各自维护一套无法比对的配置事实。

映射规则必须满足：

- 每个 `env-driven` 必需字段都有稳定 env key。
- 每个进入 `.env.example` 的应用配置键都能映射到 Settings 字段。
- 可选 `tunable constants` 只有需要外部调优时才暴露 env key，并说明调优影响。
- `derived` 字段没有 env key，也不出现在 Secret、ConfigMap、Compose environment 或测试 env 模板中。
- 运行形态、脚本专用变量和 SDK 自动读取的环境变量不映射到应用 Settings 字段，只能进入单独允许清单。
- 已废弃或已移除的 env key 必须进入拒绝清单，出现时检查失败。

未知 env key 应报错，或进入明确允许清单。不要静默忽略未知键，也不要保留旧 key 到新 key 的 silent fallback。确实需要迁移窗口时，应显式记录旧 key、截止版本和失败提示，并通过机器检查推动移除。

## 派生配置

存在联动关系的最终值必须集中派生，不让用户分别配置。推荐流水线是：读取 `env-driven` 输入 -> 合并 `tunable constants` -> 统一派生 `derived` -> 校验最终 settings 不变量。

典型派生关系：

- 业务主 timeout 派生执行层 soft/hard timeout。
- 单 worker 并发数和接单缓冲倍数派生积压上限。
- callback 单次超时和领取窗口 buffer 派生最终领取窗口。
- stale buffer 派生僵死扫描阈值。

派生配置必须遵守覆盖禁区：

- 派生字段禁止被 env 单独覆盖。
- 派生字段禁止进入 `.env`、`.env.example` 或项目维护的配置模板。
- 如果某个派生值确实需要独立控制，必须把它提升为运行时主控变量，并重新整理其他派生关系。

派生配置优先使用 `@property` 或 Pydantic `@computed_field`，保证每次访问都从当前主控变量重新计算，派生逻辑保持幂等。使用 `@computed_field` 时必须同步检查 `model_dump()`、schema、日志和调试输出的暴露面；包含内部阈值、供应商参数或敏感派生结果的字段应显式排除。若因性能原因使用初始化后字段，必须将 Settings 整体设为不可变，例如 `model_config = ConfigDict(frozen=True)`，避免主控变量被修改后派生值失效。

不要出现“先派生、再允许外部覆盖”的混合模型。混合模型会让代码里的派生逻辑和运行时实际值不一致，排查时无法判断哪个事实源有效。

## 启动校验

非法配置必须在启动或配置加载阶段快速失败。校验分两类：输入校验和派生后断言。

输入校验至少覆盖：

- 必需密钥不能为空。
- 生产环境不能启用不安全默认值。
- 数据库、Redis、对象存储等必需依赖配置必须完整。
- 常量旋钮不能保留无效值，例如负数 ratio、过小 buffer、无意义 margin。
- env key 不能同时出现新旧名称、重复语义或已废弃名称。

派生后断言至少覆盖：

- 超时链路单调递增，例如 hard timeout 必须大于 soft timeout。
- 派生积压上限必须大于 worker 并发数。
- 领取窗口、stale 阈值、callback 超时等派生值必须满足业务顺序。
- 派生后的最终值不能超过平台或依赖服务的硬限制。

派生配置完成后，校验统一放在 `model_validator(mode='after')` 中完成，不使用初始化尾部或外部集中校验函数作为默认方案。断言不得散落到 API route、Service、Worker 或脚本中。不要静默修正非法配置，也不要用 fallback 掩盖配置错误。

## 测试约定

测试中如需覆盖配置，必须显式构造新的 Settings 实例，或通过 FastAPI `dependency_overrides` 替换依赖。禁止在测试中修改全局 settings 对象；也不要 monkey-patch 环境变量后复用同一个已初始化实例。

配置相关测试至少覆盖：

- 必需运行时配置缺失时启动失败。
- 敏感字段不会出现在 repr、`model_dump()`、日志样例或错误输出中。
- 派生字段不能通过 env 单独覆盖。
- 非法常量旋钮或非法派生关系会触发 Settings 校验失败。
- 废弃 env key 和未知 env key 会被拒绝，或只在明确允许清单中通过。

## 配置机器检查

配置规则必须进入验证入口，不能只依赖文档提醒。项目应提供脚本或测试检查：

- Settings 字段清单必须能区分 `env-driven`、`tunable constants` 和 `derived`。
- `.env.example` 中的应用配置键必须能和 Settings 字段对齐。
- `.env`、`.env.*`、部署 env 模板、Secret / ConfigMap 模板中的应用配置键必须是 `.env.example` 的子集。
- 未知配置键必须报错或进入明确允许清单。
- 已废弃或已移除的配置键必须被拒绝，避免 silent fallback。
- 派生字段不得出现在 `.env`、`.env.example` 或项目维护的配置模板中。
- 运行形态、脚本专用变量和 SDK 自动读取的环境变量应单独列入允许清单，不混入应用 Settings 语义。
- `verify.sh check`、测试或 CI 至少有一个入口执行配置检查。

机器检查至少应有明确输入清单：

- Settings 字段清单。
- Settings 字段分类清单。
- Settings 字段到 env key 的映射清单。
- `.env.example`。
- 部署 env 模板、Secret / ConfigMap 模板或 Compose environment 中的应用配置键。
- 运行形态或脚本专用变量允许清单。
- SDK、HTTP 客户端或平台自动读取的环境变量允许清单。
- 废弃键拒绝清单。

这些清单可以由代码反射、结构化配置或测试 fixture 生成，但不能只靠人工阅读文档维护。检查失败时应给出具体 key、来源文件和违反的规则，便于维护者直接修复。

## 配置项变更 checklist

配置项新增、改名或删除时，至少检查：

- [ ] Settings 字段已更新，并正确归类为 `env-driven`、`tunable constants` 或 `derived`。
- [ ] 字段到 env key 的映射清单已同步；新增派生字段没有 env key。
- [ ] 如果修改的是运行时配置必需项，`.env.example` 和所有部署环境 env 模板已同步。
- [ ] 如果新增 SDK、HTTP 客户端或平台自动读取的 env key，已进入允许清单并说明消费方和影响范围。
- [ ] 如果删除或改名配置键，旧 key 已进入废弃键拒绝清单。
- [ ] 派生关系和派生后断言已更新。
- [ ] 机器检查脚本已覆盖新增、改名、删除和派生字段禁区。
- [ ] 相关测试已更新。
