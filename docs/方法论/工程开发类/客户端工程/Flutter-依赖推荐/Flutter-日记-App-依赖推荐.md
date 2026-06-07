# Flutter 日记 App — 项目依赖推荐

> 从《Flutter 通用完整依赖手册》中为本项目选出的主线方案。
> 每项标注从手册中选择该方案的原因，以及在什么情况下需要切换分支。

---

## 项目画像

| 维度 | 当前定位 |
|------|------|
| 规模 | `solo` 单人独立开发 |
| 平台 | iOS 优先，兼顾 Android |
| 风格 | 精致，接近 iOS 原生质感 |
| 核心交互 | 时间轴 + 背景下沉 Sheet + 气泡节点 |
| 隐私要求 | 高（日记为私密内容） |

---

## 依赖主线一览

### 导航

| 选用 | 版本 | 选择理由 | 切换条件 |
|------|------|------|------|
| `go_router` | ^13.0.0 | 官方维护，声明式，深链支持，Sheet 内嵌 Navigator 配合稳定 | 路由超过 50 条且需要类型安全 → 切 `auto_route` |

---

### 弹窗与底部卡片

| 选用 | 版本 | 选择理由 | 切换条件 |
|------|------|------|------|
| `wolt_modal_sheet` | ^0.6.0 | 背景缩小堆叠 + 多页横向导航 + 下滑关闭，开箱即用，维护活跃 | 若官方 `showCupertinoSheet` 稳定且背景动画支持完整 → 可切回官方 |

> **本项目核心交互**：Sheet 弹出时主页缩小下沉仍可见，这正是 `wolt_modal_sheet` 的 `CupertinoScaffold` 设计目标。Sheet 内进入子设置页用嵌套 Navigator + `CupertinoPageRoute` 实现横向滑入，无需额外依赖。

---

### 状态管理

| 选用 | 版本 | 选择理由 | 切换条件 |
|------|------|------|------|
| `flutter_riverpod` | ^2.5.0 | 类型安全，与 Drift 响应式流天然配合，solo 项目灵活够用 | 多人协作且需要严格规范 → 切 `bloc` |
| `riverpod_annotation` | ^2.3.5 | 配套代码生成，减少模板代码 | 同上 |

---

### 数据库与本地存储

| 层级 | 选用 | 版本 | 选择理由 | 切换条件 |
|------|------|------|------|------|
| 主数据（日记条目） | `drift` | ^2.19.0 | 日期范围查询、心情过滤等复杂查询，类型安全 + 响应式 Stream | 数据结构极简只需 key-value → 切 `isar` |
| 底层依赖 | `sqlite3_flutter_libs` | ^0.5.24 | drift 必须配套，不可省略 | — |
| 用户偏好 | `shared_preferences` | ^2.3.2 | 主题、提醒开关等键值配置，轻量够用 | 配置项有复杂对象 → 补充 `hive_flutter` |
| 敏感信息 | `flutter_secure_storage` | ^9.2.2 | PIN 码、加密密钥写入系统 Keychain/Keystore | 无替代，这是唯一标准解 |

---

### 代码生成（dev_dependencies）

| 选用 | 版本 | 用途 |
|------|------|------|
| `build_runner` | ^2.4.11 | 所有生成的前置执行器 |
| `riverpod_generator` | ^2.4.3 | 生成 Provider 模板 |
| `drift_dev` | ^2.19.0 | 生成数据库访问代码 |
| `freezed` | ^2.5.2 | 生成不可变日记实体、心情枚举 |
| `freezed_annotation` | ^2.4.4 | freezed 注解配套 |
| `json_serializable` | ^6.8.0 | 云同步 / 导出时 JSON 序列化 |
| `json_annotation` | ^4.9.0 | json_serializable 注解配套 |

---

### 编辑器

| 选用 | 版本 | 选择理由 | 切换条件 |
|------|------|------|------|
| `flutter_quill` | ^10.8.0 | 图文混排、格式化、只读/编辑模式切换，生态最成熟 | 日记确定只需纯文本 → 切 `markdown_editable_textinput`，包体积更小 |

---

### 日历与热力图

| 选用 | 版本 | 选择理由 | 切换条件 |
|------|------|------|------|
| `table_calendar` | ^3.1.0 | 主日历：心情标记、有记录日期高亮、周/月视图，日记 App 行业标配 | 只需日期选择弹窗 → 切 `calendar_date_picker2` |
| `flutter_heatmap_calendar` | ^1.0.5 | 统计页热力图，与 table_calendar 职责不重叠各司其职 | 不做统计功能 → 可不引入 |

---

### 图片

| 子场景 | 选用 | 版本 | 选择理由 |
|------|------|------|------|
| 单张选图 | `image_picker` | ^1.1.0 | 编辑器内插图，拍照/相册标准方案 |
| 批量选图 | `photo_manager` | ^3.3.0 | 封面图、照片墙多选场景 |
| 压缩 | `flutter_image_compress` | ^2.3.0 | 写入前压缩至 800KB，防存储膨胀 |
| 裁剪 | `image_cropper` | ^8.0.1 | 头像、封面裁剪 |
| 全屏查看 | `photo_view` | ^0.15.0 | 双指缩放全屏查看 |
| 网格展示 | `flutter_staggered_grid_view` | ^0.7.0 | 瀑布流/九宫格展示多图 |
| 网络图片 | `cached_network_image` | ^3.4.0 | 云同步开启后网络图片缓存 |

---

### 气泡与时间轴

| 选用 | 版本 | 选择理由 | 切换条件 |
|------|------|------|------|
| `bubble` | ^1.2.1 | 气泡尾方向四角可控，时间轴节点指向左侧需要 `BubbleNip.leftBottom` | 改用卡片式时间轴不需要气泡 → 可移除 |

---

### 图标与表情

| 用途 | 选用 | 版本 | 选择理由 |
|------|------|------|------|
| UI 功能图标 | `phosphor_flutter` | ^2.1.0 | thin/light 档位适合精致日记风格，7000+ 图标免费 |
| 系统默认图标 | `cupertino_icons` | ^1.0.8 | Flutter 默认自带，保留 |
| 自定义 SVG | `flutter_svg` | ^2.0.10 | 设计师交付的品牌/心情 SVG 图标渲染 |
| 心情表情选择 | `emoji_picker_flutter` | ^2.2.0 | 完整 Emoji 面板，存为 Unicode 跨平台无压力 |

---

### 动画

| 选用 | 版本 | 选择理由 | 切换条件 |
|------|------|------|------|
| `flutter_animate` | ^4.5.0 | 链式 API 处理日常 UI 动效（卡片入场、FAB、标签切换） | — |
| `lottie` | ^3.1.0 | 播放心情表情动画 JSON，比静态图标有情感温度 | 不做动态心情表情 → 可不引入 |
| `animations` | ^2.0.11 | Material 官方页面过渡动画，开箱即用 | — |
| `shimmer` | ^3.0.0 | 列表加载骨架屏，避免白屏突变 | — |

---

### 主题与字体

| 选用 | 版本 | 选择理由 | 切换条件 |
|------|------|------|------|
| `flex_color_scheme` | ^7.3.1 | 内置 50+ 配色，深色模式自动生成，不需要手动维护两套 ThemeData | 有专属设计系统 → 用 Flutter 原生 ThemeExtension |
| `google_fonts` | ^6.2.1 | 在线加载 Google Fonts，支持字体切换功能 | 隐私要求高或需离线 → 改用本地字体文件 |
| `dynamic_color` | ^1.7.0 | Android 12+ Material You 动态取色 | 只做 iOS → 可不引入 |

---

### 图表与统计

| 选用 | 版本 | 选择理由 | 切换条件 |
|------|------|------|------|
| `fl_chart` | ^0.68.0 | 心情折线图、记录频率柱状图、心情分布饼图，免费无限制 | 不做统计页 → 可不引入 |
| `word_cloud` | ^0.0.5 | 日记高频词汇可视化 | 不做词云 → 可不引入 |

---

### 搜索

| 选用 | 版本 | 选择理由 | 切换条件 |
|------|------|------|------|
| `fuse_dart` | ^0.3.2 | 模糊搜索，打错字也能找到 | 日记量大（1000 条以上）→ 切 Drift FTS5 全文索引 |
| `rxdart` | ^0.28.0 | 搜索防抖，输入停顿后再触发查询 | — |

---

### 位置与天气

| 选用 | 版本 | 选择理由 | 切换条件 |
|------|------|------|------|
| `geolocator` | ^12.0.0 | 获取 GPS 经纬度 | — |
| `geocoding` | ^3.0.0 | 经纬度转可读地址 | — |
| `weather` | ^3.1.0 | 调用 OpenWeatherMap 获取天气，自动填入日记元数据 | 不做位置天气功能 → 三包均可不引入 |

---

### 通知与提醒

| 选用 | 版本 | 选择理由 | 切换条件 |
|------|------|------|------|
| `flutter_local_notifications` | ^17.2.0 | 每日定时提醒写日记，稳定文档完整 | 需要远程推送 → 补充 `firebase_messaging` |
| `timezone` | ^0.9.4 | 定时通知处理时区和夏令时，必要配套 | — |

---

### 安全与隐私

| 选用 | 版本 | 选择理由 | 切换条件 |
|------|------|------|------|
| `local_auth` | ^2.3.0 | 指纹/面容 ID 解锁，日记隐私保护刚需 | — |
| `flutter_secure_storage` | ^9.2.2 | PIN 码和密钥写入系统加密存储 | — |
| `encrypt` | ^5.0.3 | AES 加密日记正文，数据库被提取也无法直读 | 隐私要求一般 → 可暂不引入，第四阶段补充 |

---

### 权限管理

| 选用 | 版本 | 选择理由 |
|------|------|------|
| `permission_handler` | ^11.3.0 | 相机、相册、位置、通知、生物识别权限统一管理 |
| `device_info_plus` | ^10.1.0 | Android 13+ 相册权限 API 有变更，按系统版本走不同逻辑 |

---

### 云同步

| 选用 | 版本 | 选择路线 | 切换条件 |
|------|------|------|------|
| `supabase_flutter` | ^2.5.0 | 路线一：Supabase — 开源可控，免费额度够用，一体化后端 | 已有 Firebase 生态 → 切路线二 Firebase |
| `connectivity_plus` | ^6.0.3 | 同步前检测网络状态 | — |

---

### 导出与分享

| 选用 | 版本 | 阶段 | 选择理由 |
|------|------|------|------|
| `share_plus` | ^10.0.0 | 第三阶段 | 系统分享单条日记，最基础的分享能力 |
| `pdf` + `printing` | ^3.11.1 / ^5.13.1 | 第四阶段 | 导出为可打印 PDF |
| `archive` | ^3.6.1 | 第四阶段 | 全量备份打包 ZIP |
| `screenshot` | — | 可选 | 将日记卡片截图为图片分享，视觉感更好 |

---

### 崩溃监控

| 选用 | 版本 | 选择路线 | 切换条件 |
|------|------|------|------|
| `sentry_flutter` | ^8.9.0 | 路线二：Sentry — 开源可自建，数据不经 Google，与日记 App 隐私定位一致 | 已用 Firebase 全家桶 → 切 `firebase_crashlytics` |

---

### 工具类

| 选用 | 版本 | 说明 |
|------|------|------|
| `intl` | ^0.19.0 | 日期格式化，"三月十五日"/"Mar 15"，必备 |
| `uuid` | ^4.4.0 | 每条日记的唯一 ID |
| `collection` | ^1.18.0 | `groupBy` 日记按日期分组必用 |
| `path` | ^1.9.0 | 图片存储路径拼接 |
| `path_provider` | ^2.1.3 | 获取本地文件目录 |
| `equatable` | ^2.0.5 | 状态值比较，减少不必要 UI 重建 |
| `logger` | ^2.4.0 | 开发期分级日志 |
| `package_info_plus` | ^8.1.0 | 关于页面版本号 |
| `url_launcher` | ^6.3.0 | 隐私政策、用户协议等外部链接 |
| `in_app_review` | ^2.0.9 | 上线稳定后引导评分 |

---

## 完整 pubspec.yaml

```yaml
name: diary_app
description: A personal diary app.

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter

  # 导航
  go_router: ^13.0.0

  # 弹窗（背景下沉堆叠 Sheet）
  wolt_modal_sheet: ^0.6.0

  # 状态管理
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.5

  # 数据库
  drift: ^2.19.0
  sqlite3_flutter_libs: ^0.5.24
  shared_preferences: ^2.3.2
  flutter_secure_storage: ^9.2.2

  # 文件路径
  path_provider: ^2.1.3
  path: ^1.9.0

  # 图片
  image_picker: ^1.1.0
  photo_manager: ^3.3.0
  flutter_image_compress: ^2.3.0
  image_cropper: ^8.0.1
  photo_view: ^0.15.0
  flutter_staggered_grid_view: ^0.7.0
  cached_network_image: ^3.4.0

  # 编辑器
  flutter_quill: ^10.8.0

  # 日历与热力图
  table_calendar: ^3.1.0
  flutter_heatmap_calendar: ^1.0.5

  # 时间轴气泡
  bubble: ^1.2.1

  # 图标与表情
  phosphor_flutter: ^2.1.0
  flutter_svg: ^2.0.10
  cupertino_icons: ^1.0.8
  emoji_picker_flutter: ^2.2.0

  # 动画
  flutter_animate: ^4.5.0
  lottie: ^3.1.0
  animations: ^2.0.11
  shimmer: ^3.0.0

  # 主题字体
  flex_color_scheme: ^7.3.1
  google_fonts: ^6.2.1
  dynamic_color: ^1.7.0

  # 图表
  fl_chart: ^0.68.0
  word_cloud: ^0.0.5

  # 搜索
  fuse_dart: ^0.3.2
  rxdart: ^0.28.0

  # 位置天气
  geolocator: ^12.0.0
  geocoding: ^3.0.0
  weather: ^3.1.0

  # 通知
  flutter_local_notifications: ^17.2.0
  timezone: ^0.9.4

  # 安全
  local_auth: ^2.3.0
  encrypt: ^5.0.3

  # 权限
  permission_handler: ^11.3.0
  device_info_plus: ^10.1.0

  # 云同步
  supabase_flutter: ^2.5.0
  connectivity_plus: ^6.0.3

  # 导出分享
  pdf: ^3.11.1
  printing: ^5.13.1
  share_plus: ^10.0.0
  archive: ^3.6.1

  # 崩溃监控
  sentry_flutter: ^8.9.0

  # 工具
  intl: ^0.19.0
  uuid: ^4.4.0
  collection: ^1.18.0
  equatable: ^2.0.5
  logger: ^2.4.0
  package_info_plus: ^8.1.0
  url_launcher: ^6.3.0
  in_app_review: ^2.0.9
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.11
  riverpod_generator: ^2.4.3
  drift_dev: ^2.19.0
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  flutter_launcher_icons: ^0.13.1
```

---

## 开发阶段优先级

### 第一阶段 — 核心可用

> 目标：能写日记、能看日记、数据不丢。

- `drift` + `flutter_riverpod` + `go_router` 搭好分层架构
- `flutter_quill` 编辑器基础功能
- `table_calendar` 日历导航
- `image_picker` + `flutter_image_compress` + `photo_view` 图片基础流程

### 第二阶段 — 体验打磨

> 目标：用起来流畅，视觉有品质。

- `wolt_modal_sheet` 弹窗体系（背景下沉 + Sheet 内横向导航）
- `bubble` 时间轴气泡样式
- `flutter_animate` + `lottie` + `shimmer` 动画细节
- `flex_color_scheme` + `google_fonts` 主题深色模式
- `phosphor_flutter` 图标统一

### 第三阶段 — 功能完善

> 目标：功能完整，达到可发布标准。

- `local_auth` + `flutter_secure_storage` 隐私锁
- `flutter_local_notifications` + `timezone` 每日提醒
- `fl_chart` + `flutter_heatmap_calendar` 统计页
- `geolocator` + `geocoding` + `weather` 位置天气
- `share_plus` 基础分享
- `permission_handler` 权限统一梳理
- `fuse_dart` + `rxdart` 全文搜索

### 第四阶段 — 上线准备

> 目标：上线无后顾之忧。

- `supabase_flutter` 云同步
- `pdf` + `printing` + `archive` 完整导出
- `sentry_flutter` 崩溃监控上线
- `encrypt` AES 加密加固
- `in_app_review` 评分引导
