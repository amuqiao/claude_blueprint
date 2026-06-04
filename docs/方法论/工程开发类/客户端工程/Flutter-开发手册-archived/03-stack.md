# 技术选型与演进路线
> 回答两个问题：该选哪个工具？复杂度上升时如何升级？
>
> 每条决策树标注 **[DEFAULT]** 表示大多数场景的推荐路线，带 ↓ 触发条件的分支表示何时升级。

---

## 一、状态管理决策树

```
我需要管理什么状态？
│
├─ 实时数据库数据（列表、详情，Drift 项目）
│    [DEFAULT] StreamProvider + Repository.watch()
│    ✓ Drift 写操作自动传播，UI 无需手动刷新
│    ✓ 代码最简洁
│
├─ 异步数据（Future，非 Stream）
│    AsyncNotifierProvider
│    ✓ 自带 loading/error/data 三态
│    ✓ 写后调 ref.invalidateSelf() 刷新
│    ↓ 触发：数据源是网络请求 or 需要手动控制加载时机
│
├─ 复杂同步状态（多个操作方法，有业务逻辑）
│    NotifierProvider
│    ✓ class XxxNotifier extends Notifier<State>
│    ✓ 方法里直接 state = newState
│    ↓ 触发：setState 不够用，需要封装多个操作
│
├─ 简单值状态（bool / int / enum / String）
│    StateProvider<T>
│    ✓ ref.read(p.notifier).state = newValue
│    ↓ 触发：只有一个值，无需方法封装
│
└─ 只读派生值（从其他 Provider 计算得到）
     Provider<T>
     ✓ (ref) => ref.watch(a) + ref.watch(b)
     ✓ 自动在依赖变化时重算
```

**异步三态渲染模板**（AsyncNotifierProvider / StreamProvider 通用）：
```dart
ref.watch(myProvider).when(
  data: (data) => MyWidget(data: data),
  loading: () => const CircularProgressIndicator(),
  error: (err, _) => Text('加载失败：$err'),
)
```

---

## 二、路由选型决策树

```
项目路由需求？
│
├─ 声明式路由 + 深度链接 + URL 参数
│    [DEFAULT] go_router
│    ✓ 官方推荐，Flutter Favorite
│    ✓ context.go('/path') / context.push('/path')
│    ↓ 触发：需要类型安全生成的路由类
│
├─ 需要类型安全路由（大型项目）
│    go_router + go_router_builder（代码生成）
│
└─ 简单小型项目，不需要深度链接
     Navigator.push / Navigator.pop（原生 API）
     ⚠ 无 URL、无深度链接、无法 Web 部署
```

**go_router 核心写法**：

| 操作 | 写法 |
|---|---|
| 跳转（可返回） | `context.push('/items/new')` |
| 跳转（不可返回） | `context.go('/home')` |
| 返回 | `context.pop()` |
| 传参（路径参数） | `context.push('/items/$id')` |
| 读参数 | `state.pathParameters['id']` |

---

## 三、数据层选型决策树

```
数据持久化需求？
│
├─ 结构化本地数据（关系型）
│    [DEFAULT] Drift + Repository 模式
│    ✓ 类型安全，代码生成，响应式 watch()
│    ↓ 触发：需要云端同步
│
├─ 需要云端同步
│    Repository 接口化，本地/远程实现可切换
│    ✓ Provider 层不需要改动，只替换 Repository 实现
│
├─ 简单键值对（设置、开关）
│    shared_preferences
│    ✓ 不需要表结构，读写 5 行代码
│
└─ 跨平台 JSON 文件存储（嵌套对象，无关系查询）
     hive（轻量 NoSQL）
```

---

## 四、核心包选型速查

### 已经是事实标准的包（直接选）

| 包名 | 用途 | 说明 |
|---|---|---|
| `flutter_riverpod` | 状态管理 | Flutter Favorite，2025 主流选择 |
| `go_router` | 声明式路由 | Google 官方维护，Flutter Favorite |
| `drift` + `drift_flutter` | 本地 SQLite ORM | 类型安全，响应式，代码生成 |
| `shared_preferences` | 轻量键值存储 | 官方出品，存设置首选 |
| `intl` | 日期/时间格式化 | 官方出品 |

### UI 增强（按需引入）

| 包名 | 用途 | 引入时机 |
|---|---|---|
| `flutter_animate` | 链式微动画 | 需要淡入、位移等微动画 |
| `photo_view` | 全屏图片预览（支持缩放） | 有图片预览功能 |
| `flutter_image_compress` | 图片压缩 | 用户选图后存本地前压缩 |
| `lottie` | JSON 动画（AE 导出） | 空状态插图、成功动效 |
| `cached_network_image` | 网络图片缓存 + 占位 | 有网络图片加载 |
| `extended_image` | 增强图片库（缓存、保存、裁剪） | 有复杂图片处理或图片编辑需求 |
| `shimmer` | 骨架屏加载动画 | 列表/内容加载时优化 UX |

### 系统能力（按需引入）

| 包名 | 用途 | 引入时机 |
|---|---|---|
| `permission_handler` | iOS/Android 运行时权限 | 使用相册/相机/通知前 |
| `image_picker` | 相册/相机选图 | 有选图功能 |
| `share_plus` | 系统分享面板 | 有分享功能 |
| `path_provider` + `path` | 设备文件路径 | 保存文件到本地 |
| `logger` | 结构化日志 | 替代 print，Debug 调试 |

### 视图组件（按需引入）

| 包名 | 用途 | 引入时机 |
|---|---|---|
| `table_calendar` | 可定制日历/周历 | 有日历视图 |
| `fl_chart` | 折线/柱状/饼图 | 有数据图表 |
| `infinite_scroll_pagination` | 无限分页列表容器 | 有长列表分页、加载更多需求 |
| `pull_to_refresh` | 下拉刷新 | 列表内容需要手动刷新 |

### Dev 依赖

| 包名 | 用途 |
|---|---|
| `build_runner` | 代码生成驱动（Drift、freezed 都需要） |
| `drift_dev` | Drift 代码生成 |
| `flutter_lints` | 官方 lint 规则 |
| `flutter_launcher_icons` | 批量生成 app 图标（上架前） |
| `flutter_native_splash` | 生成原生启动屏（上架前） |

### 按需代码生成

| 包名 | 用途 | 引入时机 |
|---|---|---|
| `freezed_annotation` + `freezed`(dev) | 不可变 data class，自动生成 copyWith/== | domain model 频繁做 copyWith |
| `json_annotation` + `json_serializable`(dev) | 自动生成 fromJson/toJson | 涉及 JSON 序列化 |
| `riverpod_annotation` + `riverpod_generator`(dev) | Riverpod 注解式代码生成 | provider 数量多，手写模板成本高 |

---

## 五、引入优先级（新项目参考）

| 阶段 | 立即引入 | 说明 |
|---|---|---|
| 项目起步 | `flutter_riverpod` + `go_router` + `drift` | 三大骨架，先定好 |
| 数据存储 | `shared_preferences` + `path_provider` + `path` | 设置 + 文件路径 |
| 涉及图片 | `image_picker` + `permission_handler` + `flutter_image_compress` + `photo_view` | 权限在前，压缩在后 |
| 体验优化 | `flutter_animate` + `logger` | 动画 + 调试 |
| 功能扩展 | `share_plus` / `table_calendar` / `fl_chart` | 按功能按需引入 |

---

## 六、快速诊断

### "Provider 选错了" 问题诊断

| 你现在的情况 | 可能选错了 | 应该改成 | 检查点 |
|---|---|---|---|
| 状态是简单的 bool/enum，经常改，不需要实时响应数据库 | `NotifierProvider`（过度设计） | `StateProvider<bool>` | 如果只是"展开/收起"，用 StateProvider |
| 数据来自数据库或网络，想实时刷新 | `FutureProvider`（只读一次） | `StreamProvider`（配 Drift watch）或 `AsyncNotifierProvider` | Drift 总是用 watch()，不用 get() |
| 异步操作（Future），写后希望自动刷新 | `StreamProvider`（期望 Stream）传了 Future | 改为 `AsyncNotifierProvider`，build() 里 await 数据源，写时调 `ref.invalidateSelf()` | 若 Future 不适合转 Stream，用 AsyncNotifier |
| 从多个 Provider 派生计算结果 | 在 Widget build 里直接计算 | `Provider<T>((ref) => ...)` 推导值 | 派生结果应该单独一个 Provider，便于测试和缓存 |

### "版本冲突" 问题诊断

| 错误信息 | 原因 | 修复方向 |
|---|---|---|
| `The version constraint is not satisfied` | pubspec.yaml 中两个包对同一依赖版本的要求冲突 | 优先尝试降级冲突包到稳定版本，或升级到兼容版本；最后才考虑强制版本 |
| `modal_bottom_sheet 2.x / 3.x` 命名冲突 | 已知兼容性问题（见 CLAUDE.md） | 暂不使用该包，用 Flutter 原生 `showModalBottomSheet` 替代 |
| 依赖树变复杂（3+ 层传递依赖） | 引入过多相似功能的包 | 梳理核心包清单（见第四章），删除冗余包；宁可用成熟包组合，也不要引入新的小包 |

---

*版本参考：2026 · Flutter 3.x · 仅列 pub.dev 活跃维护包*
