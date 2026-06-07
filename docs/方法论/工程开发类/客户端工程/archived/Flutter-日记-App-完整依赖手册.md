# Flutter 日记 App 完整依赖手册

> 基于前序讨论整理，覆盖从架构到上线的全部依赖，每章节说明选型理由与取舍。

---

## 目录

1. [架构基础](#1-架构基础)
2. [导航](#2-导航)
3. [弹窗与底部卡片](#3-弹窗与底部卡片)
4. [数据库与本地存储](#4-数据库与本地存储)
5. [状态管理](#5-状态管理)
6. [代码生成](#6-代码生成)
7. [编辑器](#7-编辑器)
8. [日历与热力图](#8-日历与热力图)
9. [图片](#9-图片)
10. [气泡与时间轴](#10-气泡与时间轴)
11. [图标与表情](#11-图标与表情)
12. [动画](#12-动画)
13. [主题与字体](#13-主题与字体)
14. [图表与统计](#14-图表与统计)
15. [搜索](#15-搜索)
16. [位置与天气](#16-位置与天气)
17. [通知与提醒](#17-通知与提醒)
18. [安全与隐私](#18-安全与隐私)
19. [权限管理](#19-权限管理)
20. [云同步与备份](#20-云同步与备份)
21. [导出与分享](#21-导出与分享)
22. [崩溃监控](#22-崩溃监控)
23. [工具类](#23-工具类)
24. [完整 pubspec.yaml](#24-完整-pubspecyaml)
25. [开发阶段优先级](#25-开发阶段优先级)

---

## 1. 架构基础

日记 App 推荐分四层：

```
Presentation   →   Pages / Widgets / Animations
Application    →   Riverpod Providers / State
Domain         →   Entities / Use Cases
Data           →   Repository / DB / Remote / File
```

这个分层决定了后续所有选包的方向：状态管理用 Riverpod、数据库用 Drift 的响应式流、路由用 go_router 的声明式跳转，三者在各自层内职责清晰不重叠。

---

## 2. 导航

日记 App 的路由场景包括：主页 → 编辑页、设置 Sheet 内左滑子页、深链跳转到某一天日记。

```yaml
go_router: ^13.0.0
```

**为什么选 go_router：** Flutter 官方维护，声明式路由配置，天然支持深链（比如通知点击直跳某条日记）。配合 Sheet 内嵌 Navigator 使用时，`rootNavigator: true` 参数控制层级精准，不会出现三层堆叠的问题。

`auto_route` 类型安全更强但代码生成配置复杂，单人项目性价比不高。`beamer` 维护已趋缓，不建议新项目引入。

---

## 3. 弹窗与底部卡片

日记 App 的核心交互：点击 FAB 弹出新建 Sheet、设置页内左滑子页、编辑时继续弹窗但不超过两层。

```yaml
wolt_modal_sheet: ^0.6.0
```

**为什么选 wolt_modal_sheet：** `modal_bottom_sheet` 与新版 Flutter SDK 有命名冲突且维护不活跃，`wolt_modal_sheet` 是目前社区最活跃的替代方案，支持多页左滑切换、底层缩小堆叠、留缝不触顶，开箱即用。

Sheet 内嵌 Navigator 的左滑导航无需额外依赖，用 Flutter 原生 `Navigator` 嵌套即可实现，详见导航章节。

如果必须使用 `modal_bottom_sheet`，可通过 `dependency_overrides` 锁版本或 `import hide` 隐藏冲突类解决兼容问题。

---

## 4. 数据库与本地存储

日记 App 的存储需求分三类：结构化日记数据、用户偏好配置、敏感信息（PIN/密钥）。三类需求用三个不同的包分层处理。

### 主数据库（日记条目）

```yaml
drift: ^2.19.0
sqlite3_flutter_libs: ^0.5.24   # drift 底层依赖，必须同时引入
```

Drift 是类型安全的 SQLite 封装，支持响应式查询流——日记列表按日期分组、按心情过滤、范围检索这类复杂查询，用 Drift 的 DSL 写起来比手写 SQL 安全得多，查询结果自动以 Stream 形式推送给 Riverpod Provider，UI 无需手动刷新。

### 用户偏好配置

```yaml
shared_preferences: ^2.3.2      # 主题色、字体大小、提醒开关等简单配置
hive_flutter: ^1.1.0            # 稍复杂的本地配置，如标签列表、心情预设
```

`shared_preferences` 处理键值对配置，`hive_flutter` 处理需要序列化的轻量对象，不用为这类数据动用 Drift 建表。

### 敏感信息

```yaml
flutter_secure_storage: ^9.2.2  # PIN 码、加密密钥，写入系统 Keychain/Keystore
```

PIN 码和加密密钥不能存 `shared_preferences`（明文），必须走系统级加密存储。

---

## 5. 状态管理

```yaml
flutter_riverpod: ^2.5.0
riverpod_annotation: ^2.3.5
```

**为什么选 Riverpod：** 编译期类型检查，Provider 之间依赖关系清晰，与 Drift 的响应式 Stream 天然配合——`StreamProvider` 监听数据库查询流，数据变更自动触发 UI 重建，不需要手动 `setState` 或 `notifyListeners`。

`bloc` 结构严格适合大团队，单人项目样板代码过多。`get` 上手快但全局状态耦合严重，日记这类有复杂查询的 App 后期难以维护。

---

## 6. 代码生成

以下包只在开发时使用，不进入生产包体积。

```yaml
dev_dependencies:
  build_runner: ^2.4.11          # 代码生成执行器，所有生成类包的前提
  riverpod_generator: ^2.4.3    # 生成 Riverpod Provider 模板代码
  drift_dev: ^2.19.0            # 生成 Drift 数据库访问代码
  freezed: ^2.5.2               # 生成不可变数据类（日记实体、心情枚举）
  freezed_annotation: ^2.4.4
  json_serializable: ^6.8.0     # 生成 JSON 序列化代码，云同步/导出时用
  json_annotation: ^4.9.0
```

`freezed` 生成的不可变数据类配合 `copyWith` 在日记编辑场景非常实用，修改一个字段不会污染原始数据，Riverpod 的状态比对也更可靠。

---

## 7. 编辑器

日记编辑是核心功能，需要支持图文混排（插入照片）、基本格式化（加粗、列表）。

```yaml
flutter_quill: ^10.8.0
```

**为什么选 flutter_quill：** 生态最成熟，插件体系完善，图片插入、自定义 toolbar、只读/编辑模式切换都有现成方案。`super_editor` 架构更现代但生态尚不完整，`zefyrka` 已停止维护。

如果日记风格极简（纯文本 + 少量 Markdown），可以用 `markdown_editable_textinput` 替代，包体积更小。

---

## 8. 日历与热力图

日记 App 的日历有两个独立场景：主界面日历导航（点击某天查看日记）和统计页面的热力图（直观看全年记录密度）。

```yaml
table_calendar: ^3.1.0           # 主日历，支持事件标记、范围选择、自定义样式
flutter_heatmap_calendar: ^1.0.5 # 统计页热力图，GitHub 贡献墙风格
```

`table_calendar` 是日记 App 的行业标配，心情标记点、有记录的日期高亮、周/月视图切换全部支持，自定义样式的 API 也足够灵活。`flutter_heatmap_calendar` 专职做热力图，和 `table_calendar` 职责不重叠，各司其职。

---

## 9. 图片

图片功能拆成四个子场景：选图、压缩、存储路径、查看展示。

```yaml
# 选图入口
image_picker: ^1.1.0            # 单张拍照/选图，编辑器内插图场景
photo_manager: ^3.3.0           # 批量多选，封面图/照片墙场景

# 压缩（日记图片不压缩会让本地存储迅速膨胀）
flutter_image_compress: ^2.3.0

# 裁剪（设置头像、封面图裁剪）
image_cropper: ^8.0.1

# 查看
photo_view: ^0.15.0             # 全屏查看、双指缩放
flutter_staggered_grid_view: ^0.7.0  # 九宫格/瀑布流展示多张图片

# 云同步场景下的网络图片加载
cached_network_image: ^3.4.0
```

图片压缩是容易被忽视但非常重要的环节。手机相册原图单张 5-10MB，日记记录几个月后本地存储会显著膨胀，建议写入前统一压缩到 800KB 以内。

---

## 10. 气泡与时间轴

时间轴是日记 App 的核心视图，每条日记以对白气泡形式展示，气泡尾（Bubble Tail）指向左侧时间轴节点。

```yaml
bubble: ^1.2.1
```

**为什么选 bubble：** `BubbleNip` 参数支持四个角方向（`leftTop`、`leftBottom`、`rightTop`、`rightBottom`），时间轴节点气泡需要尾巴指向左侧，`chat_bubbles` 只支持左右方向，灵活度不够。`flutter_chat_bubble` 居中，但裁剪风格偏聊天 UI，不如 `bubble` 适合日记时间轴的排版。

```dart
Bubble(
  child: Text('今天的阳光很好'),
  nip: BubbleNip.leftBottom,   // 尾巴指向左下，对准时间轴节点
  nipWidth: 8,
  nipHeight: 10,
  radius: Radius.circular(12),
  color: Colors.white,
);
```

---

## 11. 图标与表情

图标分三个职责：UI 功能图标、自定义品牌 SVG 图标、心情表情选择。

### UI 功能图标

```yaml
phosphor_flutter: ^2.1.0
cupertino_icons: ^1.0.8         # Flutter 默认自带，保留即可
```

`phosphor_flutter` 提供 thin / light / regular / bold / fill / duotone 六种粗细，日记 App 精致风格用 `light` 或 `thin` 档位，视觉细腻。数量约 7000 个，日常 UI 场景完全够用且免费。

```dart
Icon(PhosphorIconsLight.bookOpen),   // 日记
Icon(PhosphorIconsLight.smiley),     // 心情
Icon(PhosphorIconsThin.sun),         // 天气
```

### 自定义 SVG 图标

```yaml
flutter_svg: ^2.0.10
```

设计师交付的品牌图标、特殊心情图标通常是 SVG 格式，`flutter_svg` 负责渲染，支持本地 assets 和网络 URL。

### 心情表情选择器

```yaml
emoji_picker_flutter: ^2.2.0
```

心情选择如果只用图标库的笑脸图标，表达力有限。`emoji_picker_flutter` 提供完整的 Emoji 选择面板，用户可以选择最贴近当下心情的表情，存储为 Unicode 字符，跨平台显示无压力。

动态心情表情（点击后有动画反馈）配合 `lottie` 实现，见动画章节。

---

## 12. 动画

```yaml
flutter_animate: ^4.5.0         # UI 过渡动画，链式 API
lottie: ^3.1.0                  # 心情表情动态动画，播放 Lottie JSON
animations: ^2.0.11             # Material 官方过渡组件，页面切换
shimmer: ^3.0.0                 # 骨架屏，列表加载时的占位效果
```

`flutter_animate` 处理日常 UI 动效（卡片入场、FAB 弹出、心情标签切换），链式写法极简：

```dart
Text('今天心情不错')
  .animate()
  .fadeIn(duration: 300.ms)
  .slideY(begin: 0.1);
```

`lottie` 播放设计师提供的心情动画 JSON 文件，比静态图标更有情感温度，选中某个心情时触发对应动画。`shimmer` 在日记列表首次加载时显示骨架屏，避免白屏突变的割裂感。

---

## 13. 主题与字体

```yaml
google_fonts: ^6.2.1            # 在线加载 Google Fonts，字体切换功能
flex_color_scheme: ^7.3.1       # 主题生成，深色模式自动适配
dynamic_color: ^1.7.0           # Android 12+ Material You 动态取色
```

`flex_color_scheme` 大幅简化主题配置，内置 50+ 套配色方案，深色/浅色模式自动生成，不需要手动维护两套 `ThemeData`。`dynamic_color` 让 Android 用户的主题色跟随壁纸变化，系统级的个性化体验。

---

## 14. 图表与统计

统计页需要展示心情趋势折线图、每周记录频率柱状图、心情分布饼图，以及词云。

```yaml
fl_chart: ^0.68.0               # 折线图、柱状图、饼图
word_cloud: ^0.0.5              # 词云，高频词汇可视化
```

`fl_chart` 是 Flutter 图表库的事实标准，免费无 License 限制，文档完整，动画效果流畅。`syncfusion_flutter_charts` 功能更全但社区版有功能限制，商业使用需要授权，独立开发者不推荐。

---

## 15. 搜索

```yaml
fuse_dart: ^0.3.2               # 模糊搜索，全文检索
rxdart: ^0.28.0                 # 搜索防抖，输入停顿后再触发查询
```

日记搜索需要模糊匹配（打错字也能找到），`fuse_dart` 是 Fuse.js 的 Dart 移植，模糊搜索算法成熟。`rxdart` 的 `debounceTime` 处理输入防抖，避免每次按键都触发数据库查询。

---

## 16. 位置与天气

记录当天位置和天气是日记 App 的常见功能，丰富日记的上下文信息。

```yaml
geolocator: ^12.0.0             # 获取 GPS 经纬度
geocoding: ^3.0.0               # 经纬度转地址名称（如"上海市徐汇区"）
weather: ^3.1.0                 # 调用天气 API，获取当前天气状态
```

三个包组合：打开编辑器时自动获取位置 → `geocoding` 转换为可读地址 → `weather` 拉取当地天气 → 作为日记元数据自动填入，用户无需手动输入。

---

## 17. 通知与提醒

```yaml
flutter_local_notifications: ^17.2.0
timezone: ^0.9.4                # 定时通知必须配合时区处理，否则夏令时会出错
```

每日定时提醒写日记是日记 App 的高频需求，`flutter_local_notifications` 是这个场景的标准方案，稳定且文档完整。`timezone` 是它的必要配套，处理跨时区和夏令时问题。

`awesome_notifications` 样式更丰富（大图、进度条），但对于提醒写日记这个简单场景属于过度引入。

---

## 18. 安全与隐私

日记是高度私密的内容，安全是刚需而非加分项。

```yaml
local_auth: ^2.3.0              # 指纹 / 面容 ID 解锁
flutter_secure_storage: ^9.2.2  # 加密存储 PIN 码和密钥
encrypt: ^5.0.3                 # AES 加密日记内容（可选，高安全需求）
```

`local_auth` 提供生物识别解锁，App 进入前门或设置页进入前验证身份。`flutter_secure_storage` 将 PIN 码写入系统 Keychain（iOS）或 Keystore（Android），不会被其他 App 读取。`encrypt` 用于对日记正文做 AES 加密存储，即使数据库文件被提取也无法直读，适合对隐私要求极高的场景。

---

## 19. 权限管理

```yaml
permission_handler: ^11.3.0     # 统一管理相机、相册、位置、通知权限
device_info_plus: ^10.1.0       # 获取系统版本，Android 13+ 权限策略不同
```

日记 App 需要申请的权限：相机（拍照）、相册读写（选图/保存）、位置（天气和地址）、通知（每日提醒）、生物识别（隐私锁）。`permission_handler` 统一管理，`device_info_plus` 用于区分 Android 版本——Android 13+ 相册权限 API 有变更，需要根据系统版本走不同的申请逻辑。

---

## 20. 云同步与备份

```yaml
supabase_flutter: ^2.5.0        # 云同步首选
connectivity_plus: ^6.0.3       # 同步前检测网络状态，避免无网时同步失败
```

`supabase_flutter` 是开源的 Firebase 替代方案，支持实时数据库、文件存储、用户认证一体化。免费额度对独立开发者够用，数据存储在自己控制的数据库中，隐私可控。

如果倾向 Firebase 生态：

```yaml
firebase_core: ^3.4.0
cloud_firestore: ^5.4.0
firebase_storage: ^12.3.0       # 日记图片云端存储
```

---

## 21. 导出与分享

```yaml
pdf: ^3.11.1                    # 生成 PDF，日记导出为可打印格式
printing: ^5.13.1               # PDF 预览和系统打印
share_plus: ^10.0.0             # 系统分享，分享单条日记到其他 App
archive: ^3.6.1                 # 打包 ZIP，全量备份导出
```

导出是容易被推迟但用户非常在意的功能，建议第三阶段就实现基础版（纯文本分享），PDF 和 ZIP 备份放第四阶段。

---

## 22. 崩溃监控

上线后必备，没有监控就是盲飞。

```yaml
firebase_core: ^3.4.0
firebase_crashlytics: ^4.1.3    # 崩溃自动上报，含堆栈信息
firebase_analytics: ^11.3.3     # 用户行为分析，了解功能使用情况
```

不想用 Firebase 的替代方案：

```yaml
sentry_flutter: ^8.9.0
```

Sentry 开源可自建，隐私更可控，免费额度也足够独立 App 使用。

---

## 23. 工具类

```yaml
intl: ^0.19.0                   # 日期格式化（"三月十五日"/"Mar 15"），国际化基础
uuid: ^4.4.0                    # 生成唯一 ID，每条日记的主键
collection: ^1.18.0             # groupBy 等集合工具，日记按日期分组必用
path: ^1.9.0                    # 文件路径拼接，图片存储路径处理
equatable: ^2.0.5               # 值相等比较，Riverpod 状态比对减少不必要重建
logger: ^2.4.0                  # 分级日志，开发调试用，release 自动关闭
package_info_plus: ^8.1.0       # 获取 App 版本号，关于页面和崩溃日志用
url_launcher: ^6.3.0            # 打开隐私政策、用户协议等外部链接
in_app_review: ^2.0.9           # 引导用户评分，上线稳定后适时触发
```

---

## 24. 完整 pubspec.yaml

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

  # 弹窗
  wolt_modal_sheet: ^0.6.0

  # 状态管理
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.5

  # 数据库
  drift: ^2.19.0
  sqlite3_flutter_libs: ^0.5.24
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.3.2

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

  # 气泡
  bubble: ^1.2.1

  # 图标
  phosphor_flutter: ^2.1.0
  flutter_svg: ^2.0.10
  cupertino_icons: ^1.0.8

  # 心情表情
  emoji_picker_flutter: ^2.2.0

  # 动画
  flutter_animate: ^4.5.0
  lottie: ^3.1.0
  animations: ^2.0.11
  shimmer: ^3.0.0

  # 主题字体
  google_fonts: ^6.2.1
  flex_color_scheme: ^7.3.1
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

  # 权限
  permission_handler: ^11.3.0
  device_info_plus: ^10.1.0

  # 安全
  local_auth: ^2.3.0
  encrypt: ^5.0.3

  # 云同步
  supabase_flutter: ^2.5.0
  connectivity_plus: ^6.0.3

  # 导出分享
  pdf: ^3.11.1
  printing: ^5.13.1
  share_plus: ^10.0.0
  archive: ^3.6.1

  # 崩溃监控
  firebase_core: ^3.4.0
  firebase_crashlytics: ^4.1.3
  firebase_analytics: ^11.3.3

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

## 25. 开发阶段优先级

### 第一阶段：核心可用

> 目标：能写日记、能看日记、数据不丢。

- `drift` + `riverpod` + `go_router` 搭好分层架构
- `flutter_quill` 编辑器基础功能跑通
- `table_calendar` 日历导航接入
- `image_picker` + `flutter_image_compress` + `photo_view` 图片基础流程

### 第二阶段：体验打磨

> 目标：用起来流畅，视觉有品质。

- `wolt_modal_sheet` 弹窗交互体系建立
- `bubble` 时间轴气泡样式
- `flutter_animate` + `lottie` + `shimmer` 动画细节
- `flex_color_scheme` + `google_fonts` 主题深色模式
- `phosphor_flutter` 图标统一替换

### 第三阶段：功能完善

> 目标：功能完整，达到可发布标准。

- `local_auth` + `flutter_secure_storage` 隐私锁
- `flutter_local_notifications` + `timezone` 每日提醒
- `fl_chart` + `flutter_heatmap_calendar` 统计页
- `geolocator` + `geocoding` + `weather` 位置天气
- `share_plus` 基础分享
- `permission_handler` 权限统一梳理

### 第四阶段：上线准备

> 目标：上线无后顾之忧。

- `supabase_flutter` 云同步
- `pdf` + `printing` + `archive` 完整导出
- `firebase_crashlytics` + `firebase_analytics` 监控上线
- `in_app_review` 评分引导
- `fuse_dart` + `rxdart` 全文搜索