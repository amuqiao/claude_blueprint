# Flutter 日记 App 第三方依赖推荐

## 弹窗 / 底部卡片

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `modal_bottom_sheet` | ^3.0.0 | 底层缩小堆叠效果，iOS 质感最强 |
| `wolt_modal_sheet` | ^0.6.0 | 维护活跃，多页左滑，兼容性好 |
| `awesome_dialog` | ^3.2.0 | 内置多种动画弹窗，快速使用 |

**最推荐：`wolt_modal_sheet`** — 兼容性强，支持多页导航，替代 `modal_bottom_sheet` 的最佳选择。

---

## 导航

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `go_router` | ^13.0.0 | Flutter 官方推荐，声明式路由，深链支持 |
| `auto_route` | ^8.0.0 | 代码生成，类型安全，适合大型项目 |
| `beamer` | ^1.5.0 | 嵌套路由支持好，但维护趋缓 |

**最推荐：`go_router`** — 官方出品，文档完整，Sheet 内嵌 Navigator 配合使用最顺畅。

---

## 日历 / 日期选择

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `table_calendar` | ^3.1.0 | 功能最全，支持热力图标记、事件点、范围选择 |
| `calendar_date_picker2` | ^1.1.0 | 轻量，样式接近原生，适合日期选择弹窗 |
| `syncfusion_flutter_calendar` | ^26.0.0 | 企业级功能，但有 License 限制 |
| `flutter_heatmap_calendar` | ^1.0.5 | 专门做热力图日历，GitHub 贡献墙风格 |

**最推荐：`table_calendar`** — 日记 app 标配，热力图 + 事件标记 + 自定义样式全覆盖。

---

## 图片处理 / 选择

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `image_picker` | ^1.1.0 | 官方出品，拍照/相册选图标准方案 |
| `photo_manager` | ^3.3.0 | 批量选图、相册管理，权限处理完善 |
| `flutter_image_compress` | ^2.3.0 | 图片压缩，避免日记图片占用过大存储 |
| `cached_network_image` | ^3.4.0 | 图片缓存加载，云同步场景必备 |
| `photo_view` | ^0.15.0 | 图片全屏查看、双指缩放 |

**最推荐组合：`image_picker` + `flutter_image_compress` + `photo_view`** — 选图、压缩、查看三件套，日记图片场景全覆盖。

---

## 图片展示 / 九宫格

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `flutter_staggered_grid_view` | ^0.7.0 | 瀑布流 / 不规则网格，照片墙效果 |
| `image_grid` | ^0.0.3 | 轻量九宫格，快速集成 |
| `extended_image` | ^8.3.0 | 功能最强，支持裁剪、滤镜、手势 |

**最推荐：`flutter_staggered_grid_view`** — 日记图片展示瀑布流效果，视觉层次感强。

---

## 富文本编辑器

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `flutter_quill` | ^10.8.0 | 功能最全，支持图文混排、格式化 |
| `super_editor` | ^0.3.0 | 现代架构，可扩展性强，适合长文 |
| `markdown_editable_textinput` | ^2.0.0 | Markdown 输入，轻量适合简单日记 |
| `zefyrka` | ^1.0.0 | 轻量富文本，维护趋缓 |

**最推荐：`flutter_quill`** — 日记场景图文混排需求，生态最成熟，插件多。

---

## 气泡 / 对白组件

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `bubble` | ^1.2.1 | 尾巴方向四角可选，时间轴场景最灵活 |
| `chat_bubbles` | ^1.6.1 | 样式丰富，开箱即用 |
| `flutter_chat_bubble` | ^2.0.2 | 6 种 Clipper 形状，裁剪风格多样 |

**最推荐：`bubble`** — 时间轴节点气泡，尾巴指向自由控制。

---

## 本地存储 / 数据库

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `drift` | ^2.19.0 | 类型安全 SQLite，响应式查询，日记复杂查询首选 |
| `isar` | ^3.1.0 | 极快 NoSQL，查询简单，适合轻量日记 |
| `hive_flutter` | ^1.1.0 | 轻量 key-value，简单场景够用 |
| `sqflite` | ^2.3.3 | 底层 SQLite，灵活但需手写 SQL |
| `objectbox` | ^4.0.0 | 性能最强，但包体积大 |

**最推荐：`drift`** — 日记有日期范围查询、心情过滤等复杂需求，类型安全 + 响应式最适合。

---

## 状态管理

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `riverpod` | ^2.5.0 | 类型安全，编译期检查，Flutter 社区当前最主流 |
| `bloc` | ^8.1.0 | 结构严格，适合大团队协作 |
| `get` | ^4.6.6 | 上手快，但架构耦合重 |
| `mobx` | ^2.3.0 | 响应式，适合有 MobX 背景的开发者 |

**最推荐：`riverpod`** — 日记 app 单人或小团队开发，灵活且类型安全，与 `drift` 响应式流天然配合。

---

## 动画

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `lottie` | ^3.1.0 | 播放 Lottie JSON 动画，心情表情动效必备 |
| `flutter_animate` | ^4.5.0 | 链式动画 API，极简写法 |
| `rive` | ^0.13.0 | 交互式动画，状态机驱动，适合复杂心情图标 |
| `animations` | ^2.0.11 | Material 官方动画组件，过渡动画开箱即用 |

**最推荐：`flutter_animate` + `lottie`** — `flutter_animate` 处理 UI 过渡，`lottie` 播放心情表情动画，组合性价比最高。

---

## 图标 / 表情

Flutter 图标依赖主要分两类：图标字体包和 SVG 图标包。日记 app 还需要单独考虑心情表情、标签和动态心情表达。

### 图标字体包

| 包名 | 版本 | 图标数量 | 推荐理由 |
|------|------|------|------|
| `cupertino_icons` | ^1.0.8 | ~1300 | Flutter 默认自带，iOS 风格 |
| `flutter_launcher_icons` | ^0.13.1 | — | 生成 App 启动图标，非 UI 图标 |
| `font_awesome_flutter` | ^10.7.0 | ~1600 | Font Awesome 全套，覆盖面广 |
| `material_design_icons_flutter` | ^7.0.7296 | ~7000 | MDI 图标库，数量最多 |
| `line_icons` | ^2.0.3 | ~538 | 线条风格，细腻适合日记 app |
| `phosphor_flutter` | ^2.1.0 | ~7000 | 6 种粗细风格，设计感强 |
| `icons_plus` | ^5.0.0 | ~25000 | 聚合多个图标库，一包搞定 |

**最推荐：`phosphor_flutter`** — 支持 thin / light / regular / bold / fill / duotone 六种粗细，日记 app 精致风格用 thin / light 档位视觉效果最好，且完全免费。

```dart
Icon(PhosphorIconsLight.book),
Icon(PhosphorIconsRegular.heart),
Icon(PhosphorIconsThin.sun),
```

### SVG 图标包

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `flutter_svg` | ^2.0.10 | 渲染 SVG 文件，加载本地 / 网络 SVG 图标 |
| `lucide_icons_flutter` | ^1.0.4 | Lucide 图标库，简洁一致，设计师常用 |

### 表情 / 心情图标专项

日记 app 心情表情用普通图标库往往不够用，推荐：

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `emoji_picker_flutter` | ^2.2.0 | 完整 Emoji 选择器，心情标签场景 |
| `lottie` | ^3.1.0 | 动态心情表情动画，比静态图标更生动 |

**最推荐组合：`phosphor_flutter` + `flutter_svg` + `emoji_picker_flutter`** — `phosphor_flutter` 处理所有 UI 功能图标，`flutter_svg` 加载设计师交付的自定义品牌图标，`emoji_picker_flutter` 专门处理心情 / 标签选择，三者职责不重叠。

---

## 图表 / 数据可视化

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `fl_chart` | ^0.68.0 | 最主流，折线/柱状/饼图，心情趋势图首选 |
| `syncfusion_flutter_charts` | ^26.0.0 | 功能最全，有 License 限制 |
| `graphic` | ^2.3.0 | 声明式语法，灵活但学习曲线高 |

**最推荐：`fl_chart`** — 心情折线图、周期统计柱状图，文档完善，免费无限制。

---

## 权限管理

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `permission_handler` | ^11.3.0 | 标准方案，相机/相册/通知权限统一管理 |
| `device_info_plus` | ^10.1.0 | 获取设备信息，权限策略按系统版本区分 |

**最推荐：`permission_handler`** — 日记 app 涉及相机、相册、通知多个权限，一个包全搞定。

---

## 通知 / 提醒

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `flutter_local_notifications` | ^17.2.0 | 本地通知标准方案，定时提醒写日记 |
| `awesome_notifications` | ^0.9.3 | 样式更丰富，支持进度条、大图通知 |

**最推荐：`flutter_local_notifications`** — 每日定时提醒写日记，稳定可靠，文档最完整。

---

## 云同步 / 备份

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `firebase_core` + `cloud_firestore` | ^3.4.0 | 实时同步，快速起步 |
| `supabase_flutter` | ^2.5.0 | 开源 Firebase 替代，自建也可以 |
| `googleapis` | ^13.2.0 | Google Drive 备份，用户数据自持 |

**最推荐：`supabase_flutter`** — 开源可控，价格友好，支持离线优先同步，适合独立开发者。

---

## 安全 / 隐私锁

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `local_auth` | ^2.3.0 | 指纹 / 面容 ID 解锁，日记隐私保护标配 |
| `flutter_secure_storage` | ^9.2.2 | 加密本地存储，密码/密钥安全存储 |

**最推荐：`local_auth` + `flutter_secure_storage`** — 生物识别 + 加密存储，隐私日记双重保险。

---

## 工具类

| 包名 | 版本 | 推荐理由 |
|------|------|------|
| `intl` | ^0.19.0 | 日期格式化，多语言，日记时间显示必备 |
| `uuid` | ^4.4.0 | 生成唯一 ID，日记条目标识 |
| `share_plus` | ^10.0.0 | 分享日记内容到其他 app |
| `path_provider` | ^2.1.3 | 获取本地文件路径，图片存储必备 |
| `connectivity_plus` | ^6.0.3 | 网络状态检测，云同步前判断 |
| `package_info_plus` | ^8.1.0 | 获取 app 版本号，关于页面用 |

---

## 整体推荐技术栈汇总

```yaml
dependencies:
  # 导航
  go_router: ^13.0.0

  # 弹窗
  wolt_modal_sheet: ^0.6.0

  # 状态管理
  flutter_riverpod: ^2.5.0

  # 数据库
  drift: ^2.19.0

  # 日历
  table_calendar: ^3.1.0
  flutter_heatmap_calendar: ^1.0.5

  # 图片
  image_picker: ^1.1.0
  flutter_image_compress: ^2.3.0
  photo_view: ^0.15.0
  flutter_staggered_grid_view: ^0.7.0

  # 编辑器
  flutter_quill: ^10.8.0

  # 气泡
  bubble: ^1.2.1

  # 动画
  flutter_animate: ^4.5.0
  lottie: ^3.1.0

  # 图标 / 表情
  phosphor_flutter: ^2.1.0
  flutter_svg: ^2.0.10
  emoji_picker_flutter: ^2.2.0

  # 图表
  fl_chart: ^0.68.0

  # 通知
  flutter_local_notifications: ^17.2.0

  # 安全
  local_auth: ^2.3.0
  flutter_secure_storage: ^9.2.2

  # 云同步
  supabase_flutter: ^2.5.0

  # 权限
  permission_handler: ^11.3.0

  # 工具
  intl: ^0.19.0
  uuid: ^4.4.0
  share_plus: ^10.0.0
  path_provider: ^2.1.3
  connectivity_plus: ^6.0.3
```
