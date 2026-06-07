# Flutter 通用完整依赖手册

> 生态全景视角，不绑定具体项目。每个功能域标注：**默认主线** + **可枚举分支**。
> 三个维度同时标注，方便按需选择：
>
> - 📦 **场景路线**：同一功能的不同技术路线（如 Firebase vs Supabase）
> - 👤 **规模**：`solo` 单人独立 / `team` 小团队 / `enterprise` 企业级
> - 🎯 **深度**：`base` 基础够用 / `pro` 进阶完整 / `expert` 专业级

---

## 目录

1. [导航](#1-导航)
2. [弹窗与底部卡片](#2-弹窗与底部卡片)
3. [状态管理](#3-状态管理)
4. [数据库与本地存储](#4-数据库与本地存储)
5. [代码生成](#5-代码生成)
6. [网络请求](#6-网络请求)
7. [编辑器](#7-编辑器)
8. [日历与时间](#8-日历与时间)
9. [图片](#9-图片)
10. [图标与表情](#10-图标与表情)
11. [动画](#11-动画)
12. [主题与字体](#12-主题与字体)
13. [图表与数据可视化](#13-图表与数据可视化)
14. [搜索](#14-搜索)
15. [地图与位置](#15-地图与位置)
16. [通知与提醒](#16-通知与提醒)
17. [安全与隐私](#17-安全与隐私)
18. [权限管理](#18-权限管理)
19. [云同步与后端](#19-云同步与后端)
20. [导出与分享](#20-导出与分享)
21. [崩溃监控与分析](#21-崩溃监控与分析)
22. [支付](#22-支付)
23. [工具类](#23-工具类)

---

## 1. 导航

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `go_router` | ^13.0.0 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| 类型安全路线 | `auto_route` | team / enterprise | pro | 代码生成，编译期路由类型检查，适合路由多且复杂的项目 |
| 嵌套路由路线 | `beamer` | team | pro | 嵌套路由支持好，但维护已趋缓，新项目慎用 |
| 轻量无配置路线 | `get` (GetX) | solo | base | 0 配置上手，但与状态管理强耦合，不推荐单独用于路由 |

> **选型提示**：`go_router` 是官方维护的现阶段最优解，覆盖 solo 到 team 规模。企业级项目若路由非常复杂（100+ 路由、多租户）才考虑 `auto_route`。

---

## 2. 弹窗与底部卡片

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `wolt_modal_sheet` | ^0.6.0 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| 背景缩放堆叠路线 | `modal_bottom_sheet` (jamesblasco) | solo | pro | 专为 iOS 背景下沉卡片效果设计，但与新 SDK 有兼容问题，维护不活跃 |
| 底层物理拖拽路线 | `sheet` (rlch) | team | expert | 只管拖拽物理行为，背景动画需自己组合，灵活度最高 |
| 快速弹窗路线 | `awesome_dialog` | solo | base | 内置多种动画弹窗样式，适合不需要自定义的快速场景 |
| 自适应弹窗路线 | `adaptive_dialog` | solo / team | base | 自动在 iOS/Android 显示对应原生风格对话框 |

> **选型提示**：`wolt_modal_sheet` 是目前背景缩放 + 多页导航支持最完整且活跃维护的方案。纯弹窗提示用 `adaptive_dialog`，不需要引重型 sheet 包。

---

## 3. 状态管理

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `flutter_riverpod` + `riverpod_annotation` | ^2.5.0 / ^2.3.5 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| 严格分层路线 | `bloc` + `flutter_bloc` | team / enterprise | pro | 强制 Event→State 单向数据流，大团队协作边界清晰 |
| 响应式路线 | `mobx` + `flutter_mobx` | solo / team | pro | 适合有 MobX/React 背景的开发者，细粒度响应式 |
| 轻量路线 | `provider` | solo | base | 官方推荐的最轻量方案，简单 App 够用 |
| 全家桶路线 | `get` (GetX) | solo | base | 路由+状态+依赖注入一体，上手极快但耦合重，不推荐复杂项目 |
| 信号响应路线 | `signals_flutter` | solo / team | pro | 细粒度信号响应，Preact Signals 思路，新兴但活跃 |

> **选型提示**：Riverpod 2.x 编译期类型安全 + 与响应式数据库（Drift/Isar）天然配合，是当前社区主流。`bloc` 适合多人协作需要统一规范的场景。

---

## 4. 数据库与本地存储

存储需求通常分三层，建议分层用不同的包：

### 4a. 结构化主数据

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `drift` + `sqlite3_flutter_libs` | ^2.19.0 / ^0.5.24 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| NoSQL 轻量路线 | `isar` | solo | base | 查询简单时极快极简，但复杂关系查询不如 Drift |
| 高性能路线 | `objectbox` | team / enterprise | pro | 性能最强，包体积大，适合数据量大的场景 |
| 手写 SQL 路线 | `sqflite` | solo / team | pro | 灵活但需手写 SQL，无响应式流，适合有 SQL 经验者 |
| 纯 Dart 路线 | `sembast` | solo | base | 纯 Dart NoSQL，无原生依赖，适合轻量 App 或 Flutter Web |

### 4b. 用户偏好配置

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `shared_preferences` | ^2.3.2 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| 对象序列化路线 | `hive_flutter` | solo | base | 轻量对象存储，比 shared_preferences 支持更复杂的数据结构 |
| 类型安全路线 | `get_storage` | solo | base | GetX 生态配套，简单键值，无需 async |

### 4c. 敏感信息

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `flutter_secure_storage` | ^9.2.2 | solo / team / enterprise | base |

> 无替代分支。PIN 码、密钥等敏感信息必须走系统级加密（iOS Keychain / Android Keystore），这个包是标准唯一解。

---

## 5. 代码生成

> 以下均为 `dev_dependencies`，不进入生产包体积。

**默认主线**

| 包名 | 版本 | 用途 |
|------|------|------|
| `build_runner` | ^2.4.11 | 所有代码生成的执行器，前置依赖 |
| `riverpod_generator` | ^2.4.3 | 生成 Riverpod Provider 模板 |
| `drift_dev` | ^2.19.0 | 生成 Drift 数据库访问代码 |
| `freezed` + `freezed_annotation` | ^2.5.2 / ^2.4.4 | 生成不可变数据类 + copyWith |
| `json_serializable` + `json_annotation` | ^6.8.0 / ^4.9.0 | 生成 JSON 序列化代码 |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| 路由代码生成 | `auto_route_generator` | team | pro | 配合 auto_route 使用 |
| 数据类替代路线 | `dart_mappable` | team | pro | freezed 的替代，支持多态序列化更完整 |

---

## 6. 网络请求

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `dio` | ^5.7.0 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| 轻量路线 | `http` | solo | base | Flutter 官方出品，无拦截器，简单请求够用 |
| 类型安全 REST 路线 | `retrofit` + `retrofit_generator` | team / enterprise | pro | 类似 Retrofit，注解生成 API 类，类型安全 |
| GraphQL 路线 | `graphql_flutter` | team / enterprise | pro | GraphQL 客户端，配合 HasuraI/GraphQL 后端 |
| 实时通信路线 | `web_socket_channel` | team | pro | WebSocket，实时数据推送场景 |

---

## 7. 编辑器

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `flutter_quill` | ^10.8.0 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| 现代架构路线 | `super_editor` | team / enterprise | pro | 架构更现代可扩展，生态尚不完整，适合定制需求强的场景 |
| 轻量 Markdown 路线 | `markdown_editable_textinput` | solo | base | 纯文本 + 少量 Markdown，包体积小 |
| 纯展示路线 | `flutter_markdown` | solo / team | base | 只渲染 Markdown，不可编辑，适合展示页 |
| 代码编辑路线 | `code_text_field` | team | pro | 带语法高亮的代码输入框 |

---

## 8. 日历与时间

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `table_calendar` | ^3.1.0 | solo / team | base |
| `flutter_heatmap_calendar` | ^1.0.5 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| 轻量日期选择路线 | `calendar_date_picker2` | solo | base | 只需日期选择弹窗，不需要完整日历视图 |
| 企业日程路线 | `syncfusion_flutter_calendar` | enterprise | expert | 周/日/议程视图，但有 License 限制 |
| 时间轴路线 | `timeline_tile` | solo / team | base | 专做时间轴 UI，竖向/横向均支持 |
| 日期格式化 | `intl` | solo / team / enterprise | base | 日期格式化国际化，几乎所有项目必备 |

---

## 9. 图片

### 9a. 选图

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `image_picker` | ^1.1.0 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| 批量多选路线 | `photo_manager` | solo / team | pro | 相册管理、批量选图，权限处理完善 |
| 自定义 UI 路线 | `wechat_assets_picker` | solo / team | pro | 仿微信图片选择器，UI 完整开箱即用 |

### 9b. 处理

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `flutter_image_compress` | ^2.3.0 | solo / team | base |
| `image_cropper` | ^8.0.1 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| 纯 Dart 处理路线 | `image` | solo | base | 纯 Dart 图片处理，无原生依赖，适合 Flutter Web |
| 高级编辑路线 | `extended_image` | team | pro | 裁剪、滤镜、手势一体，功能最全 |

### 9c. 展示

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `photo_view` | ^0.15.0 | solo / team | base |
| `cached_network_image` | ^3.4.0 | solo / team | base |
| `flutter_staggered_grid_view` | ^0.7.0 | solo / team | base |

---

## 10. 图标与表情

### 10a. 图标字体

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `phosphor_flutter` | ^2.1.0 | solo / team | base |
| `cupertino_icons` | ^1.0.8 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| 数量优先路线 | `material_design_icons_flutter` | solo / team | base | ~7000 图标，Material 风格 |
| 聚合路线 | `icons_plus` | solo / team | base | 聚合多个图标库，~25000 图标，一包搞定但包体积大 |
| 线条风格路线 | `line_icons` | solo | base | 细腻线条风，数量少（~538）但质量统一 |
| 设计师友好路线 | `lucide_icons_flutter` | solo / team | base | Lucide 图标，设计师常用，简洁一致 |

### 10b. SVG 图标

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `flutter_svg` | ^2.0.10 | solo / team | base |

### 10c. 表情选择

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `emoji_picker_flutter` | ^2.2.0 | solo / team | base |

---

## 11. 动画

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `flutter_animate` | ^4.5.0 | solo / team | base |
| `lottie` | ^3.1.0 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| 状态机动画路线 | `rive` | team / enterprise | pro | 交互式状态机动画，比 Lottie 可交互性强，文件更大 |
| Material 过渡路线 | `animations` | solo / team | base | 官方 Material 页面过渡动画，开箱即用 |
| 骨架屏路线 | `shimmer` | solo / team | base | 列表加载骨架屏效果 |
| 视差滚动路线 | `parallax_rain` / 自定义 | solo | pro | 视差滚动通常建议自己用 CustomScrollView 实现 |

---

## 12. 主题与字体

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `flex_color_scheme` | ^7.3.1 | solo / team | base |
| `google_fonts` | ^6.2.1 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| Material You 路线 | `dynamic_color` | solo / team | base | Android 12+ 动态取色，跟随壁纸变化主题色 |
| 本地字体路线 | — | solo / team | base | 将字体文件放入 assets/fonts，无需第三方包，隐私更好 |
| 自定义设计系统路线 | `theme_extensions` (Flutter 内置) | team / enterprise | pro | 用 Flutter 原生 ThemeExtension 扩展设计 Token |

---

## 13. 图表与数据可视化

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `fl_chart` | ^0.68.0 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| 企业图表路线 | `syncfusion_flutter_charts` | enterprise | expert | 功能最全，商业授权，有免费社区版限制 |
| 声明式路线 | `graphic` | team | pro | 声明式语法，灵活但学习曲线高 |
| 词云路线 | `word_cloud` | solo / team | base | 词频词云可视化 |
| 简单图表路线 | `charts_flutter` (Google) | solo | base | Google 出品但已停止维护，新项目不推荐 |

---

## 14. 搜索

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `fuse_dart` | ^0.3.2 | solo / team | base |
| `rxdart` | ^0.28.0 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| 全文索引路线 | SQLite FTS5 via Drift | team | pro | Drift 内置 FTS5 全文搜索，比 fuse_dart 更快，适合大量文本 |
| 服务端搜索路线 | `algolia` / `meilisearch` SDK | enterprise | expert | 云端全文搜索，适合内容量大且需要排名的场景 |

---

## 15. 地图与位置

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `geolocator` | ^12.0.0 | solo / team | base |
| `geocoding` | ^3.0.0 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| Google Maps 路线 | `google_maps_flutter` | solo / team | pro | 交互式地图，需要 API Key，有使用费用 |
| 开源地图路线 | `flutter_map` + `latlong2` | solo / team | pro | 基于 OpenStreetMap，免费无限制 |
| 天气路线 | `weather` | solo / team | base | 调用 OpenWeatherMap API 获取天气 |

---

## 16. 通知与提醒

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `flutter_local_notifications` | ^17.2.0 | solo / team | base |
| `timezone` | ^0.9.4 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| 富媒体通知路线 | `awesome_notifications` | solo / team | pro | 大图、进度条、按钮通知，样式更丰富 |
| 推送通知路线 | `firebase_messaging` | team / enterprise | pro | 远程推送，需要 Firebase 后端 |
| 推送替代路线 | `supabase` Realtime | team | pro | 配合 Supabase 后端实现实时推送 |

---

## 17. 安全与隐私

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `local_auth` | ^2.3.0 | solo / team | base |
| `flutter_secure_storage` | ^9.2.2 | solo / team / enterprise | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| 数据加密路线 | `encrypt` | team / enterprise | pro | AES 加密存储内容，数据库文件被提取也无法直读 |
| 防截图路线 | `flutter_windowmanager` | solo / team | pro | 禁止截图和录屏，适合高隐私场景 |
| 证书绑定路线 | `dio_pinning` / 手动实现 | enterprise | expert | HTTPS 证书绑定，防中间人攻击 |

---

## 18. 权限管理

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `permission_handler` | ^11.3.0 | solo / team | base |
| `device_info_plus` | ^10.1.0 | solo / team | base |

> 无显著替代分支。`permission_handler` 是 Flutter 权限管理的事实标准。`device_info_plus` 用于区分 Android 版本（13+ 权限 API 有变化）。

---

## 19. 云同步与后端

### 路线一：Supabase（默认推荐）

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `supabase_flutter` | ^2.5.0 | solo / team | base |
| `connectivity_plus` | ^6.0.3 | solo / team | base |

适合独立开发者：开源可控、免费额度充足、一体化（数据库 + 文件存储 + 认证 + 实时）、隐私友好。

### 路线二：Firebase

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `firebase_core` | ^3.4.0 | solo / team / enterprise | base |
| `cloud_firestore` | ^5.4.0 | solo / team / enterprise | base |
| `firebase_storage` | ^12.3.0 | solo / team / enterprise | base |
| `firebase_auth` | ^5.3.0 | solo / team / enterprise | base |

适合已有 Google 生态或需要快速起步的场景，但费用随规模增长快。

### 路线三：纯本地（无云同步）

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `drift` (本地) | — | solo | base |
| `archive` (手动备份) | ^3.6.1 | solo | base |

适合隐私至上、不需要多设备同步的场景，用户数据完全在本地。

### 路线四：自建后端

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `dio` + 自建 API | — | team / enterprise | expert |
| `pocketbase` Flutter SDK | — | solo / team | pro |

---

## 20. 导出与分享

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `share_plus` | ^10.0.0 | solo / team | base |
| `pdf` + `printing` | ^3.11.1 / ^5.13.1 | solo / team | pro |
| `archive` | ^3.6.1 | solo / team | pro |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| Word 导出路线 | `docx_template` | team | pro | 生成 .docx 文件，适合需要 Word 格式导出的场景 |
| 截图路线 | `screenshot` | solo / team | base | 将 Widget 截图为图片，分享日记卡片图 |
| 二维码路线 | `qr_flutter` | solo / team | base | 生成二维码分享链接 |

---

## 21. 崩溃监控与分析

### 路线一：Firebase（默认）

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `firebase_crashlytics` | ^4.1.3 | solo / team / enterprise | base |
| `firebase_analytics` | ^11.3.3 | solo / team / enterprise | base |

### 路线二：Sentry（隐私优先）

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `sentry_flutter` | ^8.9.0 | solo / team / enterprise | base |

开源可自建，数据不经过 Google，隐私更可控，免费额度对独立 App 够用。

### 路线三：轻量路线

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `logger` | ^2.4.0 | solo | base |

仅做本地日志，无远程上报，适合早期开发阶段。

---

## 22. 支付

**默认主线**

| 包名 | 版本 | 规模 | 深度 |
|------|------|------|------|
| `in_app_purchase` | ^3.2.0 | solo / team | base |

**分支**

| 场景路线 | 包名 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| 订阅管理路线 | `purchases_flutter` (RevenueCat) | solo / team | pro | 订阅逻辑封装完整，跨平台收据校验，独立开发者强推 |
| 第三方支付路线 | `stripe_flutter` | team / enterprise | pro | Stripe 支付，适合非 App Store 内购场景（Web/企业） |

> **选型提示**：App 内订阅强烈推荐 RevenueCat（`purchases_flutter`），避免自己处理收据校验和订阅状态管理的复杂逻辑。

---

## 23. 工具类

| 包名 | 版本 | 规模 | 深度 | 说明 |
|------|------|------|------|------|
| `intl` | ^0.19.0 | solo / team / enterprise | base | 日期格式化、国际化基础，几乎必备 |
| `uuid` | ^4.4.0 | solo / team | base | 生成唯一 ID |
| `collection` | ^1.18.0 | solo / team | base | `groupBy`、`sorted` 等集合扩展工具 |
| `path` | ^1.9.0 | solo / team | base | 文件路径拼接 |
| `path_provider` | ^2.1.3 | solo / team | base | 获取本地文件目录 |
| `equatable` | ^2.0.5 | solo / team | base | 值相等比较，减少不必要的 UI 重建 |
| `logger` | ^2.4.0 | solo / team | base | 分级日志，release 自动关闭 |
| `package_info_plus` | ^8.1.0 | solo / team | base | 获取 App 版本号 |
| `url_launcher` | ^6.3.0 | solo / team | base | 打开外部链接 |
| `in_app_review` | ^2.0.9 | solo / team | base | 引导用户评分 |
| `connectivity_plus` | ^6.0.3 | solo / team | base | 网络状态检测 |
| `device_info_plus` | ^10.1.0 | solo / team | base | 获取设备信息 |
| `flutter_launcher_icons` | ^0.13.1 | solo / team | base | 生成 App 启动图标（dev_dependency） |
| `very_good_analysis` | ^6.0.0 | team / enterprise | pro | 严格 lint 规则集，代码质量控制 |
