# Flutter UI 组件规范

> UI 组件规范解决的不是"能不能跑"，而是"三个月后另一个人（或者你自己）看到这段代码，能不能在五分钟内搞清楚它在做什么"。

---

## 组件分层

UI 层按三个层级组织，每一层有明确的职责边界：

```
页面层（Screen）
  持有页面生命周期，处理路由参数，组装 Section
  不持有业务数据，不直接写 Repository

容器层（Section / Timeline / Bar）
  持有区块级交互逻辑，读取 Provider，处理用户操作
  可以 watch Provider，可以调用 Notifier 方法
  不做 UI 细节决策（颜色、间距由子组件自己决定）

叶子层（Card / Cell / Chip / Button）
  只接收数据，通过回调通知父组件
  不 watch Provider，不直接访问业务状态
  可以持有纯 UI 状态（hover, pressed, expanded）
```

这三层的核心区别在于：谁能读 Provider。

```
Screen    可以 watch，但通常只 watch 导航相关的状态
Section   可以 watch，这是主要的数据消费层
Card/Cell  不可以 watch，只接收 props
```

---

## 命名规范

### 文件命名

```
页面层      {name}_screen.dart        home_screen.dart
容器层      {name}_{type}.dart        home_timeline.dart, tag_filter_bar.dart
叶子层      {name}_{type}.dart        timeline_card.dart, tag_chip.dart
```

全部用 snake_case，和 Dart 文件命名惯例一致。

### 类命名

```
页面层      {Name}Screen              HomeScreen
容器层      {Name}{Type}              HomeTimeline, TagFilterBar
叶子层      {Name}{Type}              TimelineCard, TagChip
```

类名和文件名保持一一对应。`home_screen.dart` 里只有 `HomeScreen`。

### 什么时候叫 Card，什么时候叫 Cell，什么时候叫 Tile

```
Card     有内容密度，通常带阴影或边框，代表一个独立的信息单元   TimelineCard
Cell     列表或网格中的最小单元，通常是同类重复项              HeatMapCell
Chip     可选择的标签或过滤器，有选中/未选中状态               TagChip
Tile     带图标或头像的列表项，通常是 ListTile 风格            ContactTile
Item     泛指列表中的一条，当上面几个都不合适时用              SearchResultItem
```

不要用 `Widget` 作为后缀（`DiaryWidget` 很模糊），也不要用 `View`（Flutter 不是 iOS）。

---

## 叶子组件写法

### 只接收数据，不读 Provider

```dart
// 正确：通过构造函数接收数据
class TimelineCard extends StatelessWidget {
  const TimelineCard({
    super.key,
    required this.diary,
    required this.onTap,
  });

  final Diary diary;
  final VoidCallback onTap;
}

// 错误：直接读 Provider
class TimelineCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diary = ref.watch(diaryProvider(id));  // 不要这样做
  }
}
```

### 回调命名

```
onTap             点击整个组件
onLongPress       长按
on{Action}        其他用户操作，用动词     onDelete, onShare, onExpand
```

回调参数如果需要传值，用具体类型，不要用 `dynamic`：

```dart
final void Function(String id) onDelete;   // 正确
final Function onDelete;                    // 错误，调用方不知道要传什么
```

### const 构造函数

叶子组件尽量用 `const` 构造函数。这不是风格问题，是性能问题：`const` 组件在父组件重建时不会重建。

```dart
const TimelineCard({super.key, required this.diary, required this.onTap});
```

只要所有字段都是 final 且类型支持 const，就应该加 `const`。

---

## 样式管理

### 设计 Token

颜色、间距、字体大小统一放在 `lib/core/theme/` 下，不要在组件里硬编码数值。

```
lib/core/theme/
├── app_theme.dart       ThemeData 配置入口
├── app_colors.dart      颜色常量
├── app_spacing.dart     间距常量
└── app_text_styles.dart 文字样式
```

### 颜色的取用方式

```dart
// 正确：从 Theme 取，支持深色模式
color: Theme.of(context).colorScheme.primary

// 正确：从语义化常量取
color: AppColors.textSecondary

// 错误：硬编码颜色值
color: const Color(0xFF666666)  // 深色模式下看不见
```

只有一种情况允许硬编码颜色：热力图这类"颜色本身就是数据"的场景，比如根据打卡频率计算颜色深度。这种情况在组件注释里说明原因。

### 间距

```dart
// 正确：使用间距常量
padding: const EdgeInsets.all(AppSpacing.md)

// 错误：魔法数字
padding: const EdgeInsets.all(16)
```

间距常量定义：

```dart
abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}
```

---

## 状态管理在 UI 层的边界

### 哪些状态放在 Widget 里，哪些放在 Provider 里

```
放在 Widget（setState / ValueNotifier）：
  动画状态             展开/收起、hover 效果
  焦点状态             输入框是否聚焦
  临时 UI 状态         Tooltip 是否显示

放在 Provider（Riverpod Notifier）：
  业务数据             日记列表、标签列表
  跨组件共享的 UI 状态  当前选中的标签、热力图点选的日期
  需要持久化的状态      用户偏好设置
```

判断标准：如果这个状态在组件销毁后还有意义，就放 Provider。如果这个状态只对当前组件的渲染有意义，就放 Widget。

### ConsumerWidget vs StatefulWidget + ConsumerStatefulWidget

```
只需要读 Provider，不需要本地状态     -> ConsumerWidget
需要本地状态（动画、焦点），也需要读 Provider  -> ConsumerStatefulWidget
不需要读 Provider                    -> StatelessWidget / StatefulWidget
```

不要把所有组件都改成 `ConsumerWidget`，只有真正需要读 Provider 的组件才用。

---

## 加载状态和错误状态

### 加载状态不能是空白

每个从 Provider 读取异步数据的容器组件，必须处理三种状态：

```dart
final state = ref.watch(diaryListNotifierProvider);

return switch (state) {
  AsyncData(:final value) => HomeTimeline(diaries: value),
  AsyncLoading()          => const TimelineSkeleton(),
  AsyncError(:final error) => ErrorView(
      error: error,
      onRetry: () => ref.invalidate(diaryListNotifierProvider),
    ),
};
```

`TimelineSkeleton` 的形状要和真实内容一致，高度和卡片数量要接近真实值，不要用全屏 loading spinner。

### 空状态要区分原因

```dart
if (diaries.isEmpty) {
  return EmptyState(
    reason: filter.isActive
        ? EmptyReason.filteredOut   // "没有匹配的记录，试试清除筛选条件"
        : EmptyReason.noContent,    // "还没有日记，开始记录吧"
  );
}
```

同一个空列表，"筛选结果为空"和"真的没有内容"的文案和操作完全不同，不能用同一个提示。

---

## Widget 测试友好性

### 关键组件加 Key

会被测试定位的组件加语义化 Key：

```dart
// 组件里
ElevatedButton(
  key: const Key('submit_button'),
  onPressed: onSubmit,
  child: const Text('提交'),
)

// 测试里
await tester.tap(find.byKey(const Key('submit_button')));
```

不要给所有组件加 Key，只给测试需要定位的组件加。

### 避免在 build 方法里做业务计算

```dart
// 错误：build 里做日期格式化
Text(DateFormat('yyyy-MM-dd').format(diary.createdAt))

// 正确：计算逻辑移到外面，build 只做 UI 组装
final formattedDate = _formatDate(diary.createdAt);
Text(formattedDate)
```

build 方法越纯粹，Widget 测试越容易写。

---

## 文件目录

```
lib/
├── features/
│   ├── home/
│   │   ├── screens/
│   │   │   └── home_screen.dart
│   │   ├── widgets/
│   │   │   ├── heat_map_section.dart
│   │   │   ├── home_timeline.dart
│   │   │   ├── tag_filter_bar.dart
│   │   │   ├── timeline_card.dart
│   │   │   └── tag_chip.dart
│   │   └── home_providers.dart     这个 feature 的 Provider
│   └── editor/
│       ├── screens/
│       └── widgets/
└── shared/
    └── widgets/                    跨 feature 复用的组件
        ├── empty_state.dart
        └── error_view.dart
```

跨 feature 使用的组件放 `shared/widgets/`，只在单个 feature 内使用的放对应 feature 的 `widgets/` 目录下。不要在 feature A 的目录里放 feature B 会用到的组件。

---

## 维护规则

```
新增组件         -> 先确认层级（Screen/Section/叶子），按命名规范建文件，在组件架构文档里登记
修改组件接口     -> 更新所有调用方，不留废弃参数
样式改动         -> 改 Theme 或 Token，不改个别组件的硬编码值
发现硬编码颜色   -> 立即替换为 Token，不要"先跑起来以后再说"
```
