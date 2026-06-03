# 快速诊断指南
> 遇到常见问题时，用本文快速定位根因和解决方案。涵盖架构、选型、规范、编码四个层面的问题诊断。
> 
> **适用场景**：项目运行时出现异常、UI 不按预期行为、编译或运行时错误。
> 
> **使用方式**：按"症状"查找对应的诊断树，每条建议都指向具体文档章节，便于深入阅读。

---

## 一、问题症状快速定位

遇到问题时，先用这个表快速判断属于哪个层面，然后跳转到对应诊断部分。

### 症状索引

| 症状 | 第一感觉是什么问题 | 跳转诊断 |
|---|---|---|
| **UI 不刷新 / 显示旧数据** | 状态管理问题 | [二、数据与状态问题](#二数据与状态问题) |
| **数据库操作异常 / 表不存在** | 数据层问题 | [二、数据与状态问题](#二数据与状态问题) |
| **某个 Feature 的数据和另一个 Feature 看到的不一致** | 状态同步问题 | [二、数据与状态问题](#二数据与状态问题) |
| **编译失败 / ProviderException** | Provider 初始化问题 | [三、编码层问题](#三编码层问题) |
| **页面跳转失败 / 路由参数错误** | 导航问题 | [四、导航与交互问题](#四导航与交互问题) |
| **Sheet / Dialog 关闭后底层页面异常** | 导航结构问题 | [四、导航与交互问题](#四导航与交互问题) |
| **Widget 布局溢出 / 尺寸异常** | 布局约束问题 | [五、布局与 UI 问题](#五布局与-ui-问题) |
| **依赖包冲突 / 版本错误** | 技术栈选型问题 | [六、技术栈问题](#六技术栈问题) |
| **多个同级按钮 / 操作流程不清** | 设计规范问题 | [七、设计与规范问题](#七设计与规范问题) |

---

## 二、数据与状态问题

### 2.1 "UI 不刷新 / 显示旧数据"

**症状：** 数据库有变化，但页面没有重新渲染，或显示的是过时数据。

**诊断流程：**

```
UI 不刷新？
│
├─ Repository 用的是 watch() 吗？
│  ├─ YES → 下一步
│  └─ NO → 改为 watch()
│          说明：get() 是一次性读取，不监听更新；watch() 返回 Stream，实时推送
│          参考：[02-architecture.md 三、数据流主干](02-architecture.md#三数据流主干)
│
├─ Provider 的类型对吗？
│  ├─ StreamProvider（推荐） → 下一步
│  ├─ FutureProvider → ❌ 改为 StreamProvider
│  │   说明：FutureProvider 只读一次，不适合 Drift
│  └─ AsyncNotifierProvider → 下一步
│      说明：用 AsyncNotifier 时，需要手动 ref.invalidateSelf() 触发刷新
│      参考：[03-stack.md 一、状态管理决策树](03-stack.md#一状态管理决策树)
│
├─ Widget 用 ConsumerWidget 吗？
│  ├─ YES → 下一步
│  └─ NO → 改为 ConsumerWidget
│     说明：普通 StatelessWidget 没有 ref，无法订阅 Provider
│
├─ 用了 ref.watch() 吗？
│  ├─ YES → 下一步
│  └─ NO → 改为 ref.watch(provider)
│     说明：ref.read() 只读一次，不会自动重建；ref.watch() 才能自动订阅和重建
│     参考：[05-vibe-coding.md Part 2 二、状态管理](05-vibe-coding.md#二状态管理riverpod-3x)
│
└─ Drift write 操作完成了吗？
   ├─ YES → 应该生效了，检查是否 await
   └─ NO → 加 await，确保写完成后再让 watch() 推送
```

**相关文档：**
- [02-architecture.md](02-architecture.md)（三、数据流主干：读写链路模型）
- [02-architecture.md](02-architecture.md)（六、快速诊断 - UI 不刷新）
- [05-vibe-coding.md](05-vibe-coding.md)（Part 2 二、状态管理）

---

### 2.2 "数据库异常 / 表不存在"

**症状：** `DatabaseException: no such table` 或其他数据库错误。

**诊断流程：**

```
数据库异常？
│
├─ app_database.g.dart 存在吗？
│  ├─ NO → 运行：flutter pub run build_runner build
│  │     说明：Drift 代码生成产物缺失，需要重新生成
│  └─ YES → 下一步
│
├─ 表在 @DriftDatabase(tables: [...]) 里注册了吗？
│  ├─ NO → 补上，然后重新 build_runner build
│  │     示例：@DriftDatabase(tables: [EntryRows, TagRows])
│  └─ YES → 下一步
│
├─ 改过表结构（新增/删除字段）吗？
│  ├─ YES → 增加 @DriftDatabase 里的 schemaVersion，然后 build_runner build
│  │     示例：从 int get schemaVersion => 1; 改为 => 2;
│  │     说明：Drift 需要 schemaVersion 的递增来识别 schema 变化
│  └─ NO → 下一步
│
└─ 清理过缓存吗？
   └─ 运行：flutter pub run build_runner clean
      然后：flutter pub run build_runner build
```

**相关文档：**
- [00-startup.md 4.4 数据库初始化](00-startup.md#44-数据库初始化drift)
- [05-vibe-coding.md Part 2 三、本地数据](05-vibe-coding.md#三本地数据drift)

---

### 2.3 "数据不同步 / 多个页面看到不同版本"

**症状：** 一个 Feature 更新了数据，另一个 Feature 的页面没有及时看到最新值。

**诊断流程：**

```
数据不同步？
│
├─ 两个页面都订阅的是同一个 Provider 实例吗？
│  ├─ NO（例如用了 .family，参数变化导致新建 Provider）
│  │  → 检查 Provider 是否应该用 .family，或改为固定参数
│  │    说明：.family(param) 会为不同参数创建不同 Provider 实例
│  └─ YES → 下一步
│
├─ Provider 依赖链完整吗？
│  ├─ 路径：Database → Repository → Provider → UI
│  └─ 其中是否有 StateProvider 插在数据流中间？
│     ├─ YES → ❌ 移除，用纯数据 Provider 或 NotifierProvider
│     │     说明：StateProvider 中断了响应式传播
│     └─ NO → 下一步
│
└─ 是否有多个 Repository 实例？
   └─ appDatabaseProvider 应该返回唯一实例
      verify：repositories 都依赖 appDatabaseProvider 吗？
```

**相关文档：**
- [02-architecture.md](02-architecture.md)（三、数据流主干 - Provider 依赖链）
- [02-architecture.md](02-architecture.md)（六、快速诊断 - 数据不同步）

---

## 三、编码层问题

### 3.1 "编译失败 / Provider 相关异常"

**症状：** `ProviderNotFoundException`, `StateError: Future not completed` 或其他 Provider 错误。

**诊断流程：**

```
Provider 异常？
│
├─ ProviderScope 有没有包在应用根部？
│  ├─ NO → 改 bootstrap.dart：
│  │     runApp(const ProviderScope(child: HeatMomentFlutterApp()));
│  │     说明：ProviderScope 是 Riverpod 的根容器
│  └─ YES → 下一步
│
├─ 引用的 Provider 有没有定义？
│  ├─ NO → 检查 import 路径，或补上 Provider 定义
│  │     参考：[05-vibe-coding.md Part 2 二、ref 三种用法](05-vibe-coding.md#ref-三种用法)
│  └─ YES → 下一步
│
├─ Provider 间是否有循环依赖？
│  ├─ 例如：providerA 依赖 providerB，providerB 又依赖 providerA
│  │     → 打破循环，引入中间 Provider 或重新设计依赖关系
│  └─ 下一步
│
└─ 是否在 onTap 等回调里用了 ref.watch()？
   ├─ YES → ❌ 改为 ref.read()
   │     说明：watch 只能在 build 方法内调用
   │     参考：[05-vibe-coding.md 七、编码问题诊断 - Riverpod 常见错误](05-vibe-coding.md#riverpod-常见错误)
   └─ NO → 问题可能在其他层，检查编译错误日志
```

---

### 3.2 "Drift 相关异常"

**症状：** `LateInitializationError`, `DatabaseException` 或数据库操作失败。

**诊断流程：**

```
Drift 异常？
│
├─ app_database.dart 定义完整吗？
│  ├─ 检查：@DriftDatabase(tables: [...]) 是否列出了所有表
│  └─ 检查：int get schemaVersion 是否定义
│
├─ 代码生成产物齐全吗？
│  ├─ NO → 运行 flutter pub run build_runner build
│  └─ YES → 下一步
│
├─ appDatabaseProvider 初始化正确吗？
│  ├─ 参考：[00-startup.md 4.4](00-startup.md#44-数据库初始化drift)
│  └─ 确认：final database = AppDatabase(); 并 ref.onDispose(database.close);
│
└─ 执行数据库操作时是否 await？
   ├─ 例如：await _database.into(_database.itemRows).insert(...);
   └─ 所有 write 操作都需要 await
      参考：[05-vibe-coding.md 七、编码问题诊断 - Drift 常见错误](05-vibe-coding.md#drift-常见错误)
```

---

### 3.3 "Widget 构建失败"

**症状：** `RenderFlex overflowed`, `A RenderBox was given an infinite size` 等布局错误。

**诊断流程：**

```
布局异常？
│
├─ 报错是 RenderFlex overflowed？
│  ├─ YES → 用 Expanded/Flexible 包裹子 Widget，或用 SingleChildScrollView
│  │     参考：[05-vibe-coding.md 一、布局](05-vibe-coding.md#一布局layout)
│  └─ NO → 下一步
│
├─ 报错是 unbounded height？
│  ├─ YES → ListView 加 shrinkWrap: true，或外层 Expanded
│  │     参考：[05-vibe-coding.md 一、布局](05-vibe-coding.md#一布局layout)
│  └─ NO → 检查父容器约束
│
└─ 使用了 Hero animation 吗？
   ├─ YES → 检查两个 Hero 的 tag 是否完全相同（包括类型）
   └─ 不相同 tag 的 Hero 会找不到匹配对象
      参考：[05-vibe-coding.md 十七、调试与错误](05-vibe-coding.md#十七调试与错误)
```

**相关文档：**
- [05-vibe-coding.md Part 1 十七、调试与错误](05-vibe-coding.md#十七调试与错误)

---

## 四、导航与交互问题

### 4.1 "页面跳转失败 / 参数丢失"

**症状：** `GoRoute path is malformed` 或跳转后拿不到参数。

**诊断流程：**

```
路由问题？
│
├─ GoRoute 的 path 定义合法吗？
│  ├─ 动态参数用 :name 格式吗？例如 /items/:id
│  └─ 检查是否有不合法字符（如空格、特殊符号）
│
├─ 跳转时的 URL 包含参数吗？
│  ├─ 例如：context.push('/items/$id') 而非 context.push('/items')
│  └─ URL 中的参数值必须匹配 path 定义中的 :name
│
├─ state.pathParameters['xxx'] 读的时候有 ! 吗？
│  ├─ YES → 确保参数必然存在
│  └─ NO → 可能为 null，改为 ['xxx'] ?? 'default'
│
└─ 用的是 context.go() 还是 context.push()？
   ├─ go()：跳转后不能返回（Navigator 栈被替换）
   └─ push()：跳转后可以返回（Navigator 栈被保留）
      参考：[05-vibe-coding.md Part 2 一、页面导航](05-vibe-coding.md#一页面导航go_router)
```

**相关文档：**
- [05-vibe-coding.md Part 2 一、页面导航（go_router）](05-vibe-coding.md#一页面导航go_router)
- [05-vibe-coding.md 七、编码问题诊断 - go_router 常见错误](05-vibe-coding.md#go_router-常见错误)

---

### 4.2 "Sheet 打开后底层异常"

**症状：** Sheet 打开后，底层页面的导航栏消失、数据丢失或界面变了。

**诊断流程：**

```
Sheet 异常？
│
├─ Sheet 内部做了导航决策吗？
│  ├─ YES → ❌ Sheet 应该只完成本地任务（选择、输入、确认）
│  │     改为：选择完成后 dismiss，回到原页面上下文继续
│  │     参考：[04-standards.md 一、导航 - 1.2 Sheet 不承接主导航](04-standards.md#12-sheet-不承接主导航)
│  └─ NO → 下一步
│
├─ Sheet 关闭时有带回选择结果吗？
│  ├─ NO → 用 Navigator.pop(context, result) 返回选择值
│  │     或在 Page State 里暂存选择，Sheet dismiss 后读取
│  └─ YES → 下一步
│
└─ 打开 Sheet 前的页面状态有保存吗？
   └─ 检查：列表滚动位置、筛选条件、选中项等
      应该存在 Page State（StatefulWidget 或 NotifierProvider），不应该丢失
      参考：[04-standards.md 三、状态 - 3.1 状态分层](04-standards.md#31-状态分层)
```

**相关文档：**
- [04-standards.md 一、导航 - 1.2 Sheet 不承接主导航](04-standards.md#12-sheet-不承接主导航)
- [04-standards.md 三、状态 - 3.1 状态分层](04-standards.md#31-状态分层)

---

## 五、布局与 UI 问题

### 5.1 "Widget 选错了"

**症状：** 想实现某个交互效果，但不知道用什么 Widget。

**诊断：** 用反向索引快速查询。

**查询方法：** 打开 [05-vibe-coding.md 六、按交互效果反向查询](05-vibe-coding.md#六按交互效果反向查询我想实现-x)，按效果名称查找对应 Widget。

**例如：**
- 想"全屏图片预览和缩放" → `PhotoView`
- 想"下拉刷新" → `RefreshIndicator`
- 想"左滑删除列表项" → `Dismissible`

---

## 六、技术栈问题

### 6.1 "依赖包冲突 / 版本错误"

**症状：** `The version constraint is not satisfied` 或依赖解析失败。

**诊断流程：**

```
版本冲突？
│
├─ 报错显示哪两个包冲突了？
│  └─ 记下包名和版本需求
│
├─ 尝试降级其中一个包到稳定版本
│  └─ 修改 pubspec.yaml，运行 flutter pub get
│
├─ 如果仍然冲突，查看已知不兼容列表
│  └─ 参考：[03-stack.md 四、核心包选型速查](03-stack.md#四核心包选型速查)
│     已知问题：modal_bottom_sheet 2.x/3.x 有命名冲突
│
└─ 最后手段：指定精确版本
   └─ 将 ^ 改为 = 锁定版本，但可能导致其他包无法兼容
      参考：[03-stack.md](03-stack.md)（六、快速诊断 - 版本冲突）
```

**相关文档：**
- [03-stack.md 四、核心包选型速查 - 已知不兼容包](03-stack.md#四核心包选型速查)
- [03-stack.md 六、快速诊断 - 版本冲突](03-stack.md#版本冲突-问题诊断)

---

## 七、设计与规范问题

### 7.1 "多个按钮 / 交互不清"

**症状：** 同一屏有多个相似权重的按钮，用户不知道点哪个；或操作流程混乱。

**诊断流程：**

```
交互不清？
│
├─ 当前屏幕状态是什么？
│  ├─ 首次空状态 → 主动作：新建第一条内容，不显示全局 FAB
│  ├─ 正常列表 → 主动作：全局 FAB 新建，列表项操作为次级
│  ├─ 筛选无结果 → 主动作：清除筛选，FAB 可保留为次级
│  └─ 加载失败 → 主动作：重试，不引导创建
│
├─ 是否为每个状态指定了唯一的主动作（primary CTA）？
│  ├─ NO → 改为：每个状态一个视觉最强的按钮
│  └─ YES → 下一步
│
└─ 用户是否能看出当前在筛选状态？
   ├─ NO → 加 active chip / tag 显示筛选条件
   │     参考：[04-standards.md 二、交互 - 2.2 筛选状态必须外显](04-standards.md#22-筛选状态必须外显)
   └─ YES → 通过
```

**相关文档：**
- [04-standards.md 二、交互 - 2.1 单屏单主动作](04-standards.md#21-单屏单主动作)
- [04-standards.md 二、交互 - 2.2 筛选状态必须外显](04-standards.md#22-筛选状态必须外显)
- [04-standards.md 五、快速诊断 - 交互不清](04-standards.md#交互不清-问题诊断)

---

## 延伸阅读

| 问题类型 | 深入文档 |
|---|---|
| 完整的数据流和分层理解 | [02-architecture.md](02-architecture.md) |
| 技术选型和复杂度处理 | [03-stack.md](03-stack.md) |
| UI 设计判断和规范 | [04-standards.md](04-standards.md) |
| 具体 Widget 和 API 用法 | [05-vibe-coding.md](05-vibe-coding.md) |
| 从零开始搭项目 | [00-startup.md](00-startup.md) |

---

*版本：Flutter 3.x · Riverpod 3.x · go_router 17.x · Drift 2.x · 2026*
