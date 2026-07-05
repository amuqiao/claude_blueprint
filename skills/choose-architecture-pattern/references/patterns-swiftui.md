# SwiftUI / iOS 原生 成熟模式

引擎第 4 步识别出 SwiftUI / Swift / iOS / macOS 原生 / property wrapper / Swift Concurrency / SwiftData·Core Data / CloudKit 信号后加载本包。使用方式：先在下方按问题维度找匹配的"需求信号"行，取出"成熟模式"列（含 canonical name）；再回到 SKILL.md 第 5-8 步——先命名（业界叫法 + 可搜索关键词），再枚举候选、与真实场景约束对比、分析失败模式，最后给出推荐 + 保留可枚举候选。本包是地图，不是规则——只有场景需要时才采用对应模式。

与跨端区分：React Native / Flutter 走 `patterns-flutter.md`。本包只针对**原生 SwiftUI**——它的状态所有权模型、导航模型、并发模型都与跨端框架不同，不要用 Flutter 包的模式硬套。iOS 后台执行限制两包都涉及，可交叉参考。服务端幂等/重试/迁移实现见 `patterns-python-backend.md`。

---

## 架构范式选型 (App architecture paradigm)

选原生 SwiftUI 的整体架构范式时，这是「命名 + 枚举候选」最该发力的地方。三个主流候选：

| 需求信号（用户的话） | 真实工程问题 | 成熟模式 |
|---|---|---|
| 中小型 app，想用官方推荐、低门槛的方式组织状态 | 视图与业务逻辑边界、依赖注入、可测试性缺约束 | MVVM + @Observable — iOS 17+ 用 `@Observable` 宏做 view model（细粒度依赖追踪，取代 ObservableObject/@Published）；view 持有 model 用 `@State`，跨层传递用 `@Environment`；官方文档默认范式，适合大多数 app；无强约束的单向数据流，团队大时需自行约定副作用边界 |
| 大型 app，要严格单向数据流、可测试、可组合、时间旅行调试 | 状态变更路径要可追踪、可测试、模块可组合，避免逻辑散落 | TCA (The Composable Architecture, Point-Free) — Reducer + Store + Effect 的单向数据流，依赖注入/副作用/测试一等公民；活跃维护、社区大；学习曲线陡、样板多、有运行时开销，小 app 不值得，引入前评估团队接受度 |
| iOS 16 及更早，或已有大量 ObservableObject 代码 | 无法用 iOS 17 Observation，需要 Combine 驱动的可观察对象 | MVVM + ObservableObject/@Published (Combine) — 传统范式，`@StateObject`/`@ObservedObject` 订阅；坑在刷新粒度粗（任一 @Published 变更刷新整个订阅树）；iOS 17+ 新代码优先迁移到 `@Observable` |

- 命名提示：用户描述「像 Redux 那样单向数据流、状态集中可测试」→ 在 SwiftUI 生态通常指 **TCA**；描述「官方那套 @State/view model」→ 指 **@Observable-based MVVM**。可搜索关键词：`swift composable architecture`、`swiftui @Observable macro`、`observation framework`、`unidirectional data flow swiftui`。
- iOS 17+ 新项目默认 `@Observable` MVVM；只有当"可组合 + 严格可测 + 大团队协作"三者都成立时，TCA 的样板成本才被收益覆盖。
- 不要把 `@Observable`（Observation 宏）和 `ObservableObject`（Combine 协议）混用在同一条数据流里——两者依赖追踪机制不同，混用会产生刷新时机难以推理的 bug。

---

## 状态管理与所有权 (State ownership & data flow)

property wrapper 的选择本质是"谁拥有这份 source of truth、谁的生命周期决定它何时被创建/销毁"，用错会导致状态被意外重建或不刷新。

| 需求信号（用户的话） | 真实工程问题 | 成熟模式 |
|---|---|---|
| view 里的一个开关/输入框状态 | view 私有、值类型、随 view 生命周期 | `@State` — view 私有 source of truth（值类型或 iOS 17+ 的 @Observable 引用）；只在拥有它的 view 里用，不要把应共享的状态锁死在单个 view |
| 子 view 要读写父 view 的状态 | 传递可变引用而非拷贝 | `@Binding` — 传递对上游 source of truth 的可写引用；子 view 不拥有、不负责生命周期 |
| view 要拥有一个引用类型 model 的生命周期 | 引用类型对象需随 view 创建一次、不随重绘重建 | `@StateObject`（Combine）/ `@State` 持有 `@Observable`（iOS 17+）— 由该 view 拥有并只创建一次；父传子的对象绝不能用 `@StateObject` 重新包裹 |
| 对象由外部创建并传进来，view 只观察不拥有 | 不负责生命周期，只订阅变化 | `@ObservedObject`（Combine）/ `let` + `@Bindable`（Observation）— 引用外部拥有的对象；用 `@StateObject` 会导致对象被错误重建、状态丢失 |
| 深层子 view 要访问全局/跨多层的依赖 | 避免逐层 prop drilling | `@Environment` / `@EnvironmentObject` — 沿 view 树注入依赖（主题、路由、会话、DI 容器）；iOS 17+ 用 `@Environment` + `@Observable`，旧代码用 `@EnvironmentObject` |
| 页面很多，要 value-based 导航、深链、可恢复页面栈 | 声明式导航栈、deep link 解析、状态恢复 | `NavigationStack` + `NavigationPath` — 用 `navigationDestination(for:)` 做类型驱动的 value-based navigation；把 path 提到可观察 model 里集中管理，支持深链与恢复；不要用已废弃的 `NavigationView` 写新代码 |
| app 切后台再回来，滚动位置/草稿丢了 | 场景级 UI 状态在进程重启后恢复 | `@SceneStorage`（UI 状态，如选中 tab、草稿）/ `@AppStorage`（用户偏好，映射 UserDefaults）— 只存 UI/偏好，业务数据由持久化层恢复 |

- 记忆锚点：**谁 new 出来的，谁用 `@StateObject`/`@State`；被传进来的，用 `@ObservedObject`/`@Bindable`**。这条错了是 SwiftUI 最高频的状态 bug。
- iOS 17+ 迁移映射：`ObservableObject`→`@Observable`；`@StateObject`→`@State`；`@ObservedObject`→直接 `let`（需双向绑定时用 `@Bindable`）；`@EnvironmentObject`→`@Environment`。
- 导航 path 应放进可观察的路由 model（配合上面的架构范式），而不是散落在各 view 的 `@State`，否则深链和"返回到指定层级"难以实现。

---

## 离线与持久化 (Offline & persistence)

| 需求信号（用户的话） | 真实工程问题 | 成熟模式 |
|---|---|---|
| 要存关系型/对象图数据，iOS 17+ 新项目 | 类型安全的本地持久化 + 与 SwiftUI 声明式集成 | SwiftData (`@Model` + `@Query`) — iOS 17+ 官方 ORM，`@Query` 直接驱动 view 刷新；迁移用 `SchemaMigrationPlan`；较新，复杂迁移/细粒度并发控制不如 Core Data 成熟，重度场景先验证 |
| 已有大型数据层，或需要 SwiftData 尚不支持的高级特性 | 成熟的对象图持久化、复杂迁移、精细并发 | Core Data (`NSManagedObjectContext`) — 成熟稳定，支持后台 context、批量操作、复杂 merge policy；样板多、与 SwiftUI 集成不如 SwiftData 顺滑；两者可共存迁移 |
| 数据要跨用户设备同步，用苹果生态 | 免自建后端的端到端同步 | CloudKit — `NSPersistentCloudKitContainer`（Core Data）或 SwiftData 的 CloudKit 集成；同步为最终一致，冲突默认按 server LWW；跨非苹果平台无法用，隐私/配额受 iCloud 约束 |
| 只存偏好/token/小配置 | 轻量 KV 与安全存储分离 | `@AppStorage`/UserDefaults 存非敏感偏好；**凭据/token/密钥必须用 Keychain**（Keychain Services，或 KeychainAccess 等封装库）；不要把 token 放 UserDefaults |
| 两台设备改了同一条数据，谁算数 | 多端/离线同步的冲突解决 | LWW（CloudKit 默认，server 时间戳）→ 丢更新代价低时够用；代价高时改用 Core Data 自定义 `mergePolicy` 或服务端权威版本 + base version 校验（见 `patterns-python-backend.md`） |

- SwiftData vs Core Data 不是优劣是场景：iOS 17+ 新项目、模型不太复杂 → SwiftData；已有 Core Data 资产或需要其高级能力 → Core Data。两者底层同源，可渐进迁移。
- Keychain 是系统级安全存储，与 UserDefaults 底层完全不同；敏感数据绝不能混用。生物识别门禁用 `LocalAuthentication`（Face ID/Touch ID）配合 Keychain 的 access control。
- CloudKit 同步是"尽力而为的最终一致"，不保证即时；任何需要即时一致的场景（支付、协作）不要只靠 CloudKit。

---

## 数据写入与一致性 (Mutations & consistency)

| 需求信号（用户的话） | 真实工程问题 | 成熟模式 |
|---|---|---|
| 点按钮 UI 要立刻响应，不等网络 | 弱网写入延迟拖慢 UI | 乐观更新 (Optimistic Update) — 先改本地 @Observable/SwiftData 状态，后台异步提交；必须配套回滚：失败后还原并提示用户；无离线队列时不要做乐观更新 |
| 没网时操作不能丢，联网后自动同步 | 离线写入意图在进程被杀后丢失 | Outbox-on-Device — 写入意图先持久化（SwiftData/Core Data 存"待发队列"），重连后按序重放；每条记录带幂等 key，重放由服务端去重；用 `actor` 封装队列保证并发安全 |
| API 超时/500 要不要重试？会不会重复提交 | 弱网重试的幂等性 | 幂等键 + 客户端去重 (Idempotency Key) — 写请求带客户端生成的 idempotency key，服务端对相同 key 返回缓存结果；重试策略见下方并发节；服务端实现见 `patterns-python-backend.md` |
| 服务端 API 升级，老版本 app 崩溃 | 客户端/服务端版本错配 | 强制升级闸门 (Force Upgrade Gate) — 服务端返回 min_version，启动时检查并弹强制升级页；配合可远程配置阈值，避免为改阈值发版 |
| 解码服务端 JSON 时字段缺失/类型变化就崩 | 契约脆弱，容错差 | Codable 契约 + 容错解码 — 用 `Codable` 定义契约，可选字段用 optional，不做静默兜底但要在解码失败时暴露清晰错误；契约演进用 expand-contract（见 `patterns-python-backend.md`） |

- 乐观更新解决 UI 响应性，Outbox 解决离线持久性——弱网 app 两者互补，都需要。
- Outbox 每条记录应含：操作类型、目标实体 ID、payload、幂等 key、创建时间、重试次数、状态（pending/in-flight/done/failed）。用 `actor` 序列化访问，避免多任务并发重放同一条。
- 非幂等操作（如创建订单）不能盲目重试原请求，必须先落 Outbox 再重放。

---

## 并发与生命周期 (Swift Concurrency & lifecycle)

Swift Concurrency（async/await、actor、结构化并发）是原生 SwiftUI 与跨端最大的不同点之一，坑集中在"任务生命周期"和"隔离域"。

| 需求信号（用户的话） | 真实工程问题 | 成熟模式 |
|---|---|---|
| view 出现时拉数据，view 消失要自动取消 | 任务生命周期与 view 绑定，避免过期任务写已消失的 UI | `.task { }` / `.task(id:)` modifier — 随 view 生命周期自动创建/取消；依赖变化用 `.task(id:)` 让旧任务自动取消重启；不要用 `onAppear { Task { } }` 手动管理，易漏取消 |
| 后台线程算完要更新 UI，偶发崩溃/警告 | UI 更新必须在主线程，跨隔离域数据竞争 | `@MainActor` 隔离 — view model / UI 更新标注 `@MainActor`；耗时工作用 `await` 切到后台，回来自动跳主线程；不要手动 `DispatchQueue.main.async` 与 async/await 混用 |
| 多个任务共享可变状态，偶发数据竞争 | 可变状态跨并发访问的数据竞争 | `actor` — 用 actor 封装共享可变状态（如 Outbox、缓存），编译期保证串行访问；Swift 6 严格并发检查会强制暴露未隔离的可变状态 |
| 要并发发多个请求再汇总，任一失败要整体取消 | 结构化并发 + 取消传播 | `async let` / `TaskGroup` — 结构化并发让子任务随父作用域取消；避免裸 `Task {}` 脱离结构导致取消/错误无法传播 |
| 后台定期同步，app 不在前台也要跑 | iOS 后台执行受系统严格限制 | `BGTaskScheduler`（`BGAppRefreshTask` 短时刷新 / `BGProcessingTask` 长任务可要求联网充电）— 触发时机由系统决定、不保证准时；必须配合"前台 `scenePhase` 变 active 时补偿同步" |
| app 切前后台要保存/恢复、重连 | 场景生命周期事件处理 | `@Environment(\.scenePhase)` — 监听 `.active/.inactive/.background`；进入 background 存关键状态，回到 active 触发重连与补偿同步；不要在 background 依赖网络调用一定完成 |

- `.task(id:)` 的自动取消是防"过期响应写错 UI"竞态的首选，优于手动持有 `Task` 句柄再 cancel。
- iOS 后台执行：`BGAppRefreshTask` 时限仅数十秒且不保证触发；`BGProcessingTask` 可运行数分钟但仍不保证准时。任何"可靠后台同步"都必须设计前台补偿同步兜底——与 `patterns-flutter.md` 的 iOS 结论一致。
- 迁移到 Swift 6 语言模式会开启严格并发检查：提前用 `@MainActor` 标注 UI 层、用 `actor` 封装共享状态、避免非 `Sendable` 类型跨隔离域传递，可大幅减少后期数据竞争告警。

---

## 反模式提示

以下是 SwiftUI / iOS 原生特有的反模式，通用推理类反模式见 `anti-patterns.md`；服务端重试/幂等/迁移实现见 `patterns-python-backend.md`；跨端移动反模式见 `patterns-flutter.md`。

- **`@StateObject` / `@ObservedObject` 用反。** 父传子的对象用 `@StateObject` 重新包裹会被错误重建、丢失状态；view 自己创建的对象用 `@ObservedObject` 会随重绘反复重建。修复方向：谁拥有生命周期谁用 `@StateObject`/`@State`，被注入的用 `@ObservedObject`/`@Bindable`。
- **在非主线程更新 UI / 隔离域混用。** 后台任务直接改 UI 状态，偶发崩溃或"发布更改在视图更新期间"告警。修复方向：UI 层标 `@MainActor`，async/await 让回主线程自动化，不要与 `DispatchQueue` 手动混用。
- **`onAppear { Task {} }` 不取消。** view 消失后任务仍在跑，回来写已失效的 UI，产生竞态或崩溃。修复方向：改用 `.task` / `.task(id:)`，让任务随 view 生命周期自动取消。
- **ObservableObject 刷新粒度过粗。** 一个 `@Published` 变更导致整棵订阅树重绘，列表卡顿。修复方向：iOS 17+ 迁移到 `@Observable`（按实际读取的属性做细粒度依赖追踪），或拆分 model 缩小订阅面。
- **依赖 iOS 后台任务做可靠定时同步。** `BGTaskScheduler` 触发时机由系统决定、不保证准时。修复方向：后台同步作"尽力而为"补充，`scenePhase` 回到 active 时必须补偿同步。
- **导航状态散落在各 view 的 `@State`。** deep link、"返回到指定层级"、状态恢复都难以实现。修复方向：用 `NavigationStack` + 提到可观察路由 model 里的 `NavigationPath` 集中管理。
- **凭据存 UserDefaults / `@AppStorage`。** token/密钥明文可读，安全风险。修复方向：一律用 Keychain，敏感操作配合 `LocalAuthentication` 门禁。
