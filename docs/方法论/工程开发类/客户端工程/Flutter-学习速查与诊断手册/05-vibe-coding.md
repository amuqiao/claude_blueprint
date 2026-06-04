# Vibe Coding 速查
> 分两部分：**Part 1** 是通用 Flutter Widget 词汇（任何项目通用）；**Part 2** 是项目技术栈速查（go_router / Riverpod 3.x / Drift，含项目专属写法）。

---

# Part 1：通用 Flutter Widget 词汇

> 格式：你想说的 → Flutter 专业说法 → 给 AI 的描述方式

---

## 一、布局（Layout）

| 你想说的 | Flutter 专业说法 | 给 AI 的描述方式 |
|---|---|---|
| 垂直排列几个元素 | `Column` | "用 Column 垂直排列，mainAxisAlignment 居中" |
| 水平排列几个元素 | `Row` | "用 Row 水平排列，crossAxisAlignment 对齐到顶部" |
| 叠加元素（绝对定位） | `Stack` + `Positioned` | "用 Stack 叠加，Positioned 定位到右下角" |
| 元素间距 | `SizedBox` / `mainAxisSpacing` | "两个元素之间加 SizedBox(height: 16)" |
| 内边距 | `Padding` / `EdgeInsets` | "给容器加 EdgeInsets.symmetric(horizontal: 16, vertical: 8)" |
| 外边距 | `Container(margin: ...)` | "Container 的 margin 设置为 EdgeInsets.only(bottom: 12)" |
| 填满剩余空间 | `Expanded` / `Flexible` | "用 Expanded 让这个元素撑满剩余宽度" |
| 元素比例分配 | `Flexible(flex: n)` | "两列按 1:2 比例分配，用 flex: 1 和 flex: 2" |
| 居中 | `Center` | "整个内容用 Center 包裹" |
| 对齐方式 | `Align` + `Alignment.xxx` | "用 Align(alignment: Alignment.bottomRight)" |
| 自动换行排列 | `Wrap` | "Wrap(spacing: 8, runSpacing: 4) 自动换行" |
| 网格布局 | `GridView` | "用 GridView.count，每行 2 列，crossAxisSpacing: 12" |
| 可滚动列表 | `ListView` | "用 ListView.builder 动态渲染列表项" |
| 页面主体结构 | `Scaffold` | "Scaffold 包含 appBar、body、floatingActionButton" |

---

## 二、尺寸与约束（Sizing & Constraints）

| 你想说的 | Flutter 专业说法 | 给 AI 的描述方式 |
|---|---|---|
| 宽度撑满父容器 | `double.infinity` | "Container 的 width 设为 double.infinity" |
| 高度固定 | `SizedBox(height: n)` | "SizedBox(height: 200) 固定高度" |
| 最小/最大宽度 | `ConstrainedBox` + `BoxConstraints` | "ConstrainedBox 限制最大宽度为 400" |
| 按屏幕比例取宽高 | `MediaQuery.of(context).size` | "宽度取 MediaQuery.of(context).size.width * 0.8" |
| 子元素高度对齐 | `IntrinsicHeight` | "用 IntrinsicHeight 让子元素高度一致" |
| 宽高比固定 | `AspectRatio` | "AspectRatio(aspectRatio: 16/9) 保持比例" |
| 安全区域（刘海/底栏） | `SafeArea` | "body 外面套一层 SafeArea" |

---

## 三、样式与装饰（Styling & Decoration）

| 你想说的 | Flutter 专业说法 | 给 AI 的描述方式 |
|---|---|---|
| 背景色 / 圆角 / 阴影 | `Container(decoration: BoxDecoration(...))` | "BoxDecoration 设置 color、borderRadius: BorderRadius.circular(12)、boxShadow" |
| 圆形裁剪 | `CircleAvatar` / `ClipOval` | "用 ClipOval 把图片裁成圆形" |
| 圆角裁剪 | `ClipRRect` | "ClipRRect(borderRadius: BorderRadius.circular(8)) 圆角裁剪" |
| 渐变背景 | `LinearGradient` / `RadialGradient` | "BoxDecoration 的 gradient 用 LinearGradient，从顶部到底部" |
| 文字样式 | `TextStyle` | "TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600])" |
| 文字行数限制 | `maxLines` + `overflow` | "Text 设置 maxLines: 2, overflow: TextOverflow.ellipsis" |
| 图标 | `Icon(Icons.xxx)` | "Icon(Icons.edit, size: 20, color: Colors.blue)" |
| 透明度 | `Opacity` / `withOpacity` | "用 Opacity(opacity: 0.5) 或 color.withOpacity(0.3)" |

---

## 四、图片与媒体（Images & Media）

| 你想说的 | Flutter 专业说法 | 给 AI 的描述方式 |
|---|---|---|
| 显示本地图片 | `Image.asset('assets/...')` | "用 Image.asset 加载 assets 目录图片，fit: BoxFit.cover 填满" |
| 显示网络图片 | `Image.network(url)` | "用 Image.network 显示远程图片，加 loadingBuilder 显示加载中占位" |
| 图片填充模式 | `BoxFit.cover / contain / fill` | "BoxFit.cover 裁剪填满容器，BoxFit.contain 完整显示不裁剪" |
| 缓存网络图片 | `CachedNetworkImage` | "用 CachedNetworkImage 包装网络图片，placeholder 传骨架屏 widget" |
| 图片加载失败兜底 | `errorBuilder` | "Image.network 加 errorBuilder 参数，返回占位图或 Icon" |
| 从相册选图 | `image_picker` 包 | "ImagePicker().pickImage(source: ImageSource.gallery)，返回 XFile" |
| 多图选择 | `pickMultiImage()` | "ImagePicker().pickMultiImage() 返回 List\<XFile\>" |
| 全屏图片预览（可缩放） | `photo_view` 包 | "PhotoView(imageProvider: FileImage(File(path))) 全屏查看，支持双指缩放" |
| 多图全屏滑动浏览 | `PhotoViewGallery` | "PhotoViewGallery.builder 传 itemCount 和 builder，PageController 控制当前页" |
| 相册权限申请 | `permission_handler` 包 | "调用 image_picker 前先 await Permission.photos.request()，status.isGranted 判断是否通过" |

---

## 五、交互与手势（Gestures & Interaction）

| 你想说的 | Flutter 专业说法 | 给 AI 的描述方式 |
|---|---|---|
| 点击事件 | `GestureDetector(onTap: ...)` / `InkWell` | "用 InkWell 包裹，onTap 触发回调，有水波纹效果" |
| 长按 | `GestureDetector(onLongPress: ...)` | "GestureDetector 的 onLongPress 触发删除确认" |
| 滑动删除 | `Dismissible` | "列表项用 Dismissible 包裹，支持左滑删除" |
| 拖动排序 | `ReorderableListView` | "用 ReorderableListView 实现拖动排序" |
| 下拉刷新 | `RefreshIndicator` | "ListView 外包 RefreshIndicator，onRefresh 回调" |
| 滚动监听 | `ScrollController` | "ScrollController 监听滚动位置，控制 FAB 显示隐藏" |
| 开关/切换 | `Switch` / `CupertinoSwitch` | "用 Switch 绑定 bool 状态，onChanged 更新状态" |

---

## 六、表单与输入（Forms & Input）

| 你想说的 | Flutter 专业说法 | 给 AI 的描述方式 |
|---|---|---|
| 单个输入框 | `TextField` + `TextEditingController` | "TextField 加 controller 和 onChanged 回调" |
| 表单整体管理 | `Form` + `GlobalKey<FormState>` | "Form 包裹所有输入项，GlobalKey\<FormState\> 统一触发校验" |
| 字段校验 | `TextFormField(validator: ...)` | "validator 返回 null 表示通过，返回字符串则显示报错文案" |
| 校验并提交 | `_formKey.currentState!.validate()` | "点击提交时调用 validate()，全部通过再执行 save()" |
| 光标焦点控制 | `FocusNode` | "FocusNode 绑定到 TextField，手动调用 requestFocus() 或 unfocus()" |
| 点空白处收键盘 | `GestureDetector` + `FocusScope` | "页面最外层 GestureDetector(onTap: () => FocusScope.of(context).unfocus())" |
| 键盘类型 | `keyboardType: TextInputType.xxx` | "TextInputType.emailAddress / number / phone 切换键盘布局" |
| 密码输入框 | `obscureText: true` | "TextField 加 obscureText: true 隐藏输入，配合 IconButton 切换显示" |
| 提交动作键 | `textInputAction` | "TextInputAction.next 跳下一个输入框，TextInputAction.done 关闭键盘" |
| 键盘弹出遮挡处理 | `resizeToAvoidBottomInset` | "Scaffold 的 resizeToAvoidBottomInset: true 防止键盘遮挡输入框" |

---

## 七、导航与路由（Navigation & Routing）

> **使用 go_router 的项目**，页面跳转写法查 [Part 2 第一章](#一页面导航go_router)，本章保留 Flutter 原生 API 供跨项目参考。

| 你想说的 | Flutter 原生写法 | 给 AI 的描述方式 |
|---|---|---|
| 跳转到新页面 | `Navigator.push` | "Navigator.push(context, MaterialPageRoute(builder: ...))" |
| 返回上一页 | `Navigator.pop` | "Navigator.pop(context) 返回，可携带返回值" |
| 替换当前页面 | `Navigator.pushReplacement` | "pushReplacement 跳转后不能返回" |
| 底部 Tab 导航 | `BottomNavigationBar` | "Scaffold 的 bottomNavigationBar 用 BottomNavigationBar" |
| 侧边抽屉 | `Drawer` | "Scaffold 的 drawer 属性，ListTile 作为菜单项" |
| 弹出底部面板 | `showModalBottomSheet` | "showModalBottomSheet 弹出，设置 isScrollControlled: true 可全屏" |
| 弹出对话框 | `showDialog` + `AlertDialog` | "showDialog 弹出 AlertDialog，actions 放确认/取消按钮" |
| 顶部通知条 | `ScaffoldMessenger.showSnackBar` | "showSnackBar 显示提示条，duration 设为 2 秒" |

---

## 八、状态管理（State Management）

| 你想说的 | Flutter 专业说法 | 给 AI 的描述方式 |
|---|---|---|
| 局部状态（简单） | `StatefulWidget` + `setState` | "用 StatefulWidget，setState 触发重建" |
| 全局状态 | `Riverpod` `ref.watch` | "ConsumerWidget 里用 ref.watch(xxxProvider) 订阅状态" |
| 异步数据展示 | `FutureBuilder` | "FutureBuilder 根据 future 状态显示 loading/data/error 三态" |
| 流式数据展示 | `StreamBuilder` | "StreamBuilder 监听数据流，实时更新 UI" |
| 条件渲染 | `if (condition) Widget()` | "在 Column children 里用 if 条件决定是否渲染某个 widget" |
| 列表动态渲染 | `ListView.builder` / `.map().toList()` | "用 items.map((e) => Card(...)).toList() 动态生成列表" |

---

## 九、动画与过渡（Animation & Transitions）

| 你想说的 | Flutter 专业说法 | 给 AI 的描述方式 |
|---|---|---|
| 简单属性动画 | `AnimatedContainer` | "AnimatedContainer 设置 duration: Duration(milliseconds: 300)" |
| 两个 widget 间切换 | `AnimatedSwitcher` | "用 AnimatedSwitcher 在两个 widget 间做淡入淡出" |
| 透明度动画 | `AnimatedOpacity` | "AnimatedOpacity 在显示/隐藏时做渐变" |
| 位移动画 | `AnimatedPositioned` / `SlideTransition` | "SlideTransition 从底部滑入" |
| Hero 共享动画 | `Hero(tag: ...)` | "列表页和详情页的图片加相同 tag 的 Hero widget" |
| 链式微动画（推荐） | `flutter_animate` 包 | "widget.animate().fadeIn(duration: 300.ms).slideY(begin: 0.1) 链式添加，无需 AnimationController" |
| 列表错位入场动画 | `.animate(delay: n.ms)` | "ListView 每个 item 加 .animate(delay: (index * 50).ms).fadeIn().slideX() 实现依次入场" |

---

## 十、主题与颜色（Theme & Color）

| 你想说的 | Flutter 专业说法 | 给 AI 的描述方式 |
|---|---|---|
| 读取主题色 | `Theme.of(context).colorScheme` | "用 colorScheme.primary 读取主色，colorScheme.surface 读卡片背景色" |
| 读取文字样式 | `Theme.of(context).textTheme` | "textTheme.bodyLarge / titleMedium / labelSmall 读语义化文字样式" |
| 适配深色模式 | `Theme.of(context).brightness` | "brightness == Brightness.dark 时用深色资源或反色" |
| 语义色配对 | `colorScheme.surface / onSurface` | "surface 是容器背景，onSurface 是其上文字/图标前景色，成对使用" |
| 全局设定主色 | `ThemeData(colorSchemeSeed: ...)` | "MaterialApp 的 theme 传 ThemeData，colorSchemeSeed 设种子色自动派生整套色板" |
| 动态切换主题模式 | `ThemeMode` + Riverpod | "将 ThemeMode 存 Provider，ThemeMode.light / dark / system 切换" |

---

## 十一、iOS 原生风格（Cupertino Components）

| 你想说的 | Flutter 专业说法 | 给 AI 的描述方式 |
|---|---|---|
| iOS 风格按钮 | `CupertinoButton` | "CupertinoButton(child: Text(...), onPressed: ...)，filled 构造函数有填充背景" |
| iOS 风格弹窗 | `showCupertinoDialog` + `CupertinoAlertDialog` | "CupertinoAlertDialog 的 actions 放 CupertinoDialogAction" |
| iOS 底部操作菜单 | `showCupertinoModalPopup` + `CupertinoActionSheet` | "actions 列表放操作项，cancelButton 单独放取消，自带取消手势" |
| iOS 风格导航栏 | `CupertinoNavigationBar` | "middle 放标题 Text，trailing 放右侧按钮，leading 放返回或自定义" |
| 大标题折叠导航 | `CupertinoSliverNavigationBar` | "放在 CustomScrollView 的 slivers 第一位，largeTitle 传标题文字" |
| iOS 风格开关 | `CupertinoSwitch` | "CupertinoSwitch(value: _on, onChanged: (v) => setState(() => _on = v))" |
| iOS 底部弹出页 | `CupertinoPageRoute` | "Navigator.push 传 CupertinoPageRoute，有 iOS 原生右滑返回动画" |
| 判断当前平台 | `defaultTargetPlatform` | "defaultTargetPlatform == TargetPlatform.iOS 判断是否 iOS，按需切换组件" |

---

## 十二、Widget 生命周期（Widget Lifecycle）

| 生命周期钩子 | 触发时机 | 典型用途 |
|---|---|---|
| `initState()` | Widget 首次插入树 | 初始化 Controller、首次加载数据、注册监听 |
| `dispose()` | Widget 从树移除 | 释放 Controller、取消定时器、防内存泄漏 |
| `didChangeDependencies()` | 依赖的 InheritedWidget 变化 | 首次能安全使用 `context` 读取 Theme/Provider |
| `didUpdateWidget(old)` | 父组件传入参数变化 | 对比 old/new 参数，按需重新初始化 |
| `mounted` 属性 | Widget 是否还在树上 | 异步回调中加 `if (!mounted) return` 防崩溃 |

```dart
@override
void initState() {
  super.initState();
  _controller = TextEditingController();
}

@override
void dispose() {
  _controller.dispose(); // 必须释放，否则内存泄漏
  super.dispose();
}
```

---

## 十三、Sliver 与复杂滚动（Sliver & Advanced Scroll）

| 你想说的 | Flutter 专业说法 | 给 AI 的描述方式 |
|---|---|---|
| 混合滚动容器 | `CustomScrollView` | "CustomScrollView 的 slivers 数组里混合多种 Sliver 组件" |
| 滚动时收起的导航栏 | `SliverAppBar` | "SliverAppBar 加 expandedHeight、pinned: true 固定收起后的小导航" |
| Sliver 版列表 | `SliverList` | "SliverList(delegate: SliverChildBuilderDelegate((ctx, i) => ...)) 代替 ListView" |
| Sliver 版网格 | `SliverGrid` | "SliverGrid.count(crossAxisCount: 2) 代替 GridView，可与 SliverList 共存" |
| Sliver 版内边距 | `SliverPadding` | "SliverPadding(padding: EdgeInsets.all(16), sliver: SliverList(...)) 给 Sliver 加 padding" |
| 固定在顶部的区块 | `SliverPersistentHeader` | "delegate 实现 build/maxExtent/minExtent，滚动时钉在顶部" |

---

## 十四、常用组件速查（Widget Reference）

| 组件 | 用途 | 关键参数 |
|---|---|---|
| `Card` | 卡片容器，自带阴影 | `elevation`, `shape`, `margin` |
| `ListTile` | 列表项，图标+标题+副标题 | `leading`, `title`, `subtitle`, `trailing`, `onTap` |
| `Chip` | 标签/徽章 | `label`, `avatar`, `onDeleted` |
| `AppBar` | 顶部导航栏 | `title`, `actions`, `leading`, `backgroundColor` |
| `FloatingActionButton` | 悬浮按钮（FAB） | `onPressed`, `child`, `mini: true` |
| `TabBar` + `TabBarView` | 顶部 Tab 切换 | 配合 `DefaultTabController` 使用 |
| `Divider` | 分割线 | `height`, `thickness`, `color` |
| `Spacer` | 弹性空白（撑开空间） | 在 Row/Column 里用，相当于 flex: 1 的空白 |
| `SingleChildScrollView` | 单个可滚动容器 | 防止 Column 内容超出屏幕 |

---

## 十五、常见组合模式（Common Widget Patterns）

| UI 模式 | 标准组合 | 给 AI 的描述方式 |
|---|---|---|
| 图片 + 标题 + 副标题卡片 | `Card` > `Column` > `Image` + `ListTile` | "Card 里 Column 排 Image（高度固定）和 ListTile（title/subtitle）" |
| 头像 + 姓名 + 操作按钮一行 | `Row` > `CircleAvatar` + `Expanded(Text)` + `IconButton` | "Row 里 CircleAvatar 头像，Expanded 包文字撑开，尾部 IconButton" |
| 标签云（自动换行） | `Wrap` > `Chip` | "Wrap(spacing: 8, runSpacing: 4) 包多个 Chip，自动换行" |
| 搜索框 | `TextField` + `InputDecoration` | "InputDecoration 加 hintText 和 prefixIcon: Icon(Icons.search)，border 用 OutlineInputBorder" |
| 加载/空/数据 三态 | `when()` / `FutureBuilder` | "StreamProvider/AsyncNotifierProvider 的 .when(data:, loading:, error:) 展示三态" |
| 底部固定按钮 | `Scaffold(bottomNavigationBar: ...)` | "bottomNavigationBar 传 SafeArea > Padding > ElevatedButton，避免被底部安全区遮挡" |
| 右下角悬浮按钮 | `Scaffold(floatingActionButton: ...)` | "floatingActionButton: FloatingActionButton(onPressed: ..., child: Icon(Icons.add))" |

---

## 十六、AI 描述模板（Prompt Templates）

### 布局问题
```
"[组件名] 里的 [子组件] 需要 [对齐方式/间距/尺寸]，
目前用的是 [现有属性]，希望改成 [目标效果]"
```

### 交互问题
```
"点击 [组件] 后需要 [动作]，
当前状态是 [State 变量]，
触发后应该 [状态变化/页面跳转/弹窗]"
```

### 样式问题
```
"[组件] 的 [decoration/style] 需要：
- 背景色：[颜色]
- 圆角：[数值]
- 阴影：[elevation 或 boxShadow]
- 内边距：[EdgeInsets 描述]"
```

### 提问时带上这些上下文

1. **当前 Widget 树**：贴出 `build()` 方法相关部分
2. **问题描述**：用"左/右/顶部/底部/中央"描述位置，用"溢出/被遮住/间距太大/没对齐"描述现象
3. **父容器约束**：说明父组件是 `Column` / `Row` / `Stack` / `Scaffold body`
4. **错误信息**：有报错直接贴，尤其是 `RenderFlex overflowed` 等

---

## 十七、调试与错误（Debug & Errors）

| 报错 | 原因 | 解决方向 |
|---|---|---|
| `RenderFlex overflowed` | Row/Column 子元素超出父容器 | 用 `Expanded`、`Flexible`、`SingleChildScrollView` 包裹 |
| `Null check operator used on a null value` | 变量未初始化就使用 | 检查 `initState` 是否赋值，或加空值判断 |
| `setState() called after dispose()` | 异步回调时 widget 已销毁 | 加 `if (mounted) setState(...)` 判断 |
| `A RenderBox was given an infinite size` | 无限宽/高的约束传递 | 给 ListView 加 `shrinkWrap: true` 或固定父容器尺寸 |
| `Vertical viewport was given unbounded height` | ListView 嵌套在 Column 里没有高度约束 | ListView 加 `shrinkWrap: true` + `physics: NeverScrollableScrollPhysics()`，或 `Expanded` 包裹 |
| `LateInitializationError` | `late` 变量未赋值就读取 | 检查 `initState` 是否赋值，或改为可空类型 + `??` 默认值 |
| `type 'Null' is not a subtype of type 'X'` | 可空变量未判断就使用 | 加 `!` 断言，或用 `if (x != null)` / `x?.method()` |
| `setState() or markNeedsBuild() called during build` | build 方法执行时触发了状态变更 | 把状态更新移到 `addPostFrameCallback` 或事件回调里 |
| `Hero widget ... has no matching hero` | Hero tag 在两个页面不一致 | 检查两个页面 Hero 的 tag 值是否完全相同（包括类型） |

---

---

# Part 2：项目技术栈速查

> **HeatMoment 专属**。go_router + Riverpod 3.x + Drift 的具体写法。
>
> 路由配置在 `lib/app/router.dart`，数据库定义在 `lib/core/database/`。

---

## 一、页面导航（go_router）

### 基本跳转

| 你想做的 | 写法 | 给 AI 的描述方式 |
|---|---|---|
| 跳转到新页面（可返回） | `context.push('/path')` | "用 context.push('/items/new') 跳转，用户可以点返回键回来" |
| 跳转并替换当前页（不可返回） | `context.go('/path')` | "用 context.go('/home') 跳转，返回键不会回到当前页" |
| 返回上一页 | `context.pop()` | "context.pop() 返回，需要传返回值时用 context.pop(result)" |
| 带参数跳转 | `context.push('/items/$id')` | "用 context.push('/items/${item.id}') 传路由参数" |
| 按名称跳转 | `context.goNamed('name')` | "context.goNamed('detail', pathParameters: {'id': id}) 按路由名称跳转" |

### 接收参数

```dart
GoRoute(
  path: '/items/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return ItemDetailPage(id: id);
  },
)
```

### 弹出类交互（不走路由）

| 你想做的 | 写法 |
|---|---|
| 底部弹出面板 | `showModalBottomSheet(context, builder: ...)` |
| 弹出对话框 | `showCupertinoDialog(context, builder: ...)` |
| 底部消息条 | `ScaffoldMessenger.of(context).showSnackBar(...)` |

---

## 二、状态管理（Riverpod 3.x）

### Widget 里读取状态

```dart
// ConsumerWidget（替代 StatelessWidget）
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);  // 订阅，变化自动重建
    return ...;
  }
}
```

### ref 三种用法

| 用法 | 场景 | 给 AI 的描述方式 |
|---|---|---|
| `ref.watch(provider)` | build 方法内读取状态 | "在 build 里用 ref.watch(xxxProvider) 订阅状态" |
| `ref.read(provider)` | 事件回调中一次性读取 | "在按钮 onTap 里用 ref.read(xxxProvider) 读当前值" |
| `ref.read(provider.notifier)` | 触发状态变更 | "用 ref.read(xxxProvider.notifier).method() 调用 notifier 方法" |

### Provider 类型选择（详细决策树见 [03-stack.md](03-stack.md)）

| Provider 类型 | 适用场景 | 给 AI 的描述方式 |
|---|---|---|
| `StreamProvider` | Drift 实时数据（项目主要模式） | "StreamProvider 包装 Repository.watch()，Drift 写操作自动传播" |
| `StateProvider` | 简单值（bool、enum） | "StateProvider\<bool\>，改值用 ref.read(p.notifier).state = true" |
| `NotifierProvider` | 复杂同步状态，多个方法 | "class XxxNotifier extends Notifier\<State\>，state = newState" |
| `AsyncNotifierProvider` | 异步数据 + 手动控制刷新 | "build() 里 await 数据，写后 ref.invalidateSelf()" |

---

## 三、本地数据（Drift）

> **项目使用 StreamProvider + Repository.watch() 模式**。Drift `watch()` 返回 Stream，写操作自动通知所有订阅者，不需要手动 `ref.invalidateSelf()`。

### 读操作

| 你想做的 | 写法 | 给 AI 的描述方式 |
|---|---|---|
| 实时监听列表（推荐） | `Repository.watchItems()` | "Repository 里用 Drift watch()，StreamProvider 包装，UI 自动响应变化" |
| 一次性查询 | `select(table).get()` | "用 get() 代替 watch()，返回 Future，一次性读取" |
| 按条件查询 | `..where((t) => t.field.equals(val))` | "加 where 过滤，例如 where((t) => t.date.equals(today))" |

### 写操作（写完后 UI 自动刷新，无需手动触发）

| 你想做的 | 写法 | 给 AI 的描述方式 |
|---|---|---|
| 插入记录 | `into(table).insert(Companion(...))` | "用 into(table).insert(XxxCompanion.insert(...)) 插入新记录" |
| 更新记录 | `(update(table)..where(...)).write(companion)` | "update 加 where 定位，write 传修改后的 Companion 对象" |
| 删除记录 | `(delete(table)..where(...)).go()` | "delete 加 where 定位要删除的行，调用 go() 执行" |

### 完整 Repository + Provider 模式

```dart
// 1. Repository（data 层）
class ItemRepository {
  ItemRepository(this._db);
  final AppDatabase _db;

  Stream<List<Item>> watchItems() =>
    _db.select(_db.itemRows).watch().map((rows) => rows.map(_map).toList());

  Future<void> insert(ItemsCompanion entry) =>
    _db.into(_db.itemRows).insert(entry);
}

// 2. Provider（data 层）
final itemRepositoryProvider = Provider<ItemRepository>((ref) =>
  ItemRepository(ref.watch(appDatabaseProvider)));

final itemsProvider = StreamProvider<List<Item>>((ref) =>
  ref.watch(itemRepositoryProvider).watchItems());

// 3. UI（presentation 层）
ref.watch(itemsProvider).when(
  data: (items) => ListView.builder(...),
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('加载失败'),
)
```

### 何时用 AsyncNotifierProvider + invalidateSelf()

```dart
// 当数据源是 Future（非 Stream）时，或需要手动控制刷新时机
class ItemsNotifier extends AsyncNotifier<List<Item>> {
  @override
  Future<List<Item>> build() async {
    return ref.read(itemRepositoryProvider).fetchItems();
  }

  Future<void> delete(String id) async {
    await ref.read(itemRepositoryProvider).deleteItem(id);
    ref.invalidateSelf();  // 手动触发重新加载
  }
}
```

### 轻量设置存储（shared_preferences）

```dart
// 主题模式等简单设置，不放 Drift 表
final prefs = await SharedPreferences.getInstance();
final isDark = prefs.getBool('darkMode') ?? false;
await prefs.setBool('darkMode', true);
```

---

## 四、系统能力

### 权限申请（permission_handler）

| 场景 | 写法 | 给 AI 的描述方式 |
|---|---|---|
| 申请相册权限 | `await Permission.photos.request()` | "调用 image_picker 前先 await Permission.photos.request()，判断 status.isGranted" |
| 永久拒绝后引导 | `openAppSettings()` | "status.isPermanentlyDenied 时调用 openAppSettings() 打开系统设置" |

### 分享（share_plus）

| 场景 | 写法 |
|---|---|
| 分享文字 | `Share.share('text')` |
| 分享图片 | `Share.shareXFiles([XFile(path)], text: '描述')` |

### 文件路径（path_provider）

```dart
// 获取 app 私有文档目录（存图片用这个）
final dir = await getApplicationDocumentsDirectory();
final filePath = path.join(dir.path, '$uuid.jpg');
```

---

## 五、常见开发模式

### 图片存储完整流程

```
用户选图（image_picker）
  → 申请权限（permission_handler）
  → 压缩图片（flutter_image_compress，质量 80%）
  → 保存到 app 文档目录（path_provider + path，uuid 命名）
  → 把文件路径字符串存入 Drift 表的 imagePath 字段
  → Drift watch() 自动通知 → StreamProvider → UI 自动刷新
```

---

## 六、按交互效果反向查询（我想实现 X）

> 如果你知道交互效果但不知道用什么 Widget，可用本章反向查询。若没找到，回到 Part 1 的目录 (一-十六) 按类别查找。

| 我想实现... | 对应 Widget/方案 | 查阅 Part 1 章节 |
|---|---|---|
| **显示列表，支持删除** | `Dismissible` 包裹 ListView item | 五、交互与手势 |
| **点击列表项跳转** | `ListTile(onTap: ...)` + go_router | 七、导航与路由 |
| **全屏图片预览和缩放** | `PhotoView` / `PhotoViewGallery` | 四、图片与媒体 |
| **底部弹出选择菜单** | `showModalBottomSheet` | 七、导航与路由 |
| **弹出确认对话框** | `showDialog` + `AlertDialog` | 七、导航与路由 |
| **顶部通知条（Toast 效果）** | `ScaffoldMessenger.showSnackBar` | 七、导航与路由 |
| **标签/徽章** | `Chip` | 十四、常用组件速查 |
| **下拉刷新列表** | `RefreshIndicator` 包装 ListView | 五、交互与手势 |
| **拖动排序** | `ReorderableListView` | 五、交互与手势 |
| **顶部固定标题，下面内容可滚动** | `SliverAppBar` + `CustomScrollView` | 十三、Sliver 与复杂滚动 |
| **大标题折叠效果（iOS 风格）** | `CupertinoSliverNavigationBar` | 十一、iOS 原生风格 |
| **固定在顶部不滚动的区块** | `SliverPersistentHeader` | 十三、Sliver 与复杂滚动 |
| **渐变背景** | `LinearGradient` / `RadialGradient` | 三、样式与装饰 |
| **圆形头像** | `CircleAvatar` / `ClipOval` | 三、样式与装饰 |
| **淡入淡出动画** | `AnimatedSwitcher` / `flutter_animate` | 九、动画与过渡 |
| **列表每项错位入场** | `.animate(delay: n.ms).fadeIn().slideX()` | 九、动画与过渡 |
| **深色/浅色模式适配** | `Theme.of(context).brightness` | 十、主题与颜色 |
| **按屏幕宽度调整布局** | `MediaQuery.of(context).size.width` | 二、尺寸与约束 |
| **键盘弹出时表单不被遮挡** | `Scaffold(resizeToAvoidBottomInset: true)` | 六、表单与输入 |
| **密码框显示/隐藏按钮** | `TextField(obscureText: true)` + `IconButton` | 六、表单与输入 |

---

## 七、编码问题诊断

> 完整诊断见 [06-diagnostics.md](06-diagnostics.md)，本节为就地速查摘要。

### Riverpod 常见错误

| 错误现象 | 原因 | 修复 |
|---|---|---|
| `ProviderContainer was already initialized` | Provider 在不同地方被重复初始化 | 确保 `ProviderScope` 只在 `main()` → `runApp()` 时初始化一次，不在其他地方重复创建 |
| `ref.watch()` 在 `onTap` 回调里使用导致 crash | watch 只能在 build 方法内调用，不能在事件回调里 | 回调里用 `ref.read()`，build 里用 `ref.watch()`（见 Part 2 三、ref 三种用法）|
| Provider 变化了，但依赖它的 Widget 没有重建 | Widget 没有订阅 Provider（用的是 StatelessWidget，没用 ConsumerWidget） | 改为 `ConsumerWidget`，在 build 里调 `ref.watch(provider)` |
| 写操作完成后，StreamProvider 还是显示 loading 状态 | Riverpod 在等待后续的数据流事件，但 Stream 没有新数据来 | 确认 Drift write 操作后是否会自动 emit 新数据；若是，等待 watch() 推送；若否，用 `AsyncNotifierProvider` + `ref.invalidateSelf()` 手动刷新 |

### Drift 常见错误

| 错误现象 | 原因 | 修复 |
|---|---|---|
| `DatabaseException: no such table` | 数据库表定义和实际 schema 不一致 | 运行 `flutter pub run build_runner clean && build_runner build`，重新生成 app_database.g.dart |
| `LateInitializationError: Field '_database' not initialized` | AppDatabase 在 Riverpod Provider 里未初始化 | 确保 `appDatabaseProvider` 正确创建了 `AppDatabase()` 实例，且 `ref.onDispose(database.close)` 已添加 |
| 插入记录后，watch() 没有推送新数据 | Drift 没有感知到表的变化 | 确认：1) insert 的表在 watch() 监听范围内；2) insert 操作已 await；3) 没有用原生 SQL（Drift 只能追踪 Drift API 操作） |
| 批量删除或更新后，UI 只刷新了一部分 | write 操作没有 await，UI 在写完成前就已订阅了 | 所有数据库操作都要 `await`，确保完全写入后再让 watch() 推送 |

### go_router 常见错误

| 错误现象 | 原因 | 修复 |
|---|---|---|
| `GoRoute path '/xxx' is malformed` | 路由路径语法错误 | 检查 path 是否包含不合法字符；动态参数用 `:name` 格式（如 `/items/:id`）|
| 传了参数但 `state.pathParameters['xxx']` 为 null | 路由路径定义和 context.push 时传的参数不一致 | 确保 push 时的 URL 包含参数值（如 `context.push('/items/$id')`），且 GoRoute 定义包含 `:id` |
| 返回上一页时，前一页的滚动位置/状态丢失 | go_router 默认不保存滚动状态 | 用 `context.push()` 而非 `context.go()`（push 会保留返回历史，go 会替换），或在 State 里存滚动位置 |

---

*版本：Flutter 3.x · Riverpod 3.x · go_router 17.x · Drift 2.x · 2026*
