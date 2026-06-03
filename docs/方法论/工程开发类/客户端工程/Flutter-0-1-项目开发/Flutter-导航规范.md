# Flutter 导航规范

> 导航规范解决的是页面之间的合约问题：谁能跳到哪里、跳过去时带什么参数、跳回来时发生什么。这些合约不写清楚，页面耦合就会通过路由参数悄悄扩散。

---

## 技术选型

导航使用 GoRouter。选型依据在 Tech Decision 文档里。本文只描述在 GoRouter 框架下的具体约定，不重复 GoRouter 的 API 文档。

---

## 路由定义

### 集中定义，不分散

所有路由定义集中在 `lib/core/router/app_router.dart`，不在各个页面里分散定义。

```dart
// lib/core/router/app_router.dart

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.list,
    routes: [
      GoRoute(
        path: Routes.list,
        builder: (context, state) => const ListScreen(),
      ),
      GoRoute(
        path: Routes.itemEditor,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return ItemEditorScreen(itemId: id);  // id 为 null 表示新建
        },
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
```

### 路由名称常量

路由路径统一定义在 `lib/core/router/routes.dart`，不要在代码里写裸字符串：

```dart
// lib/core/router/routes.dart

abstract class Routes {
  static const list = '/';
  static const itemEditor = '/item-editor';
  static const itemEditorWithId = '/item-editor/:id';
  static const settings = '/settings';
}
```

```dart
// 正确：用常量
context.go(Routes.list);
context.push(Routes.itemEditor);

// 错误：裸字符串
context.go('/');
context.push('/item-editor');
```

---

## 跳转方式

GoRouter 有 `go`、`push`、`replace` 三种跳转，选择依据是导航语义，不是习惯：

```
go       替换整个导航栈，用于底部导航栏切换 tab、登录后跳列表页
push     叠加到当前栈，用于进入详情页、打开编辑页
replace  替换当前页，用于登录页跳列表页后不想让用户回退到登录页
```

判断规则：

```
用户完成了一个任务，不应该回退到上一个状态    -> go 或 replace
用户在探索，可能要回退                       -> push
```

错误的典型案例：用 `go` 打开编辑页，保存后用户按返回按钮直接回到了根路由，丢失了打开编辑页前的页面状态。

---

## 参数传递

### 路径参数 vs 查询参数

```
路径参数（/item-editor/:id）   用于标识资源，是 URL 的一部分，会出现在导航历史里
查询参数（/item-editor?mode=new）  用于影响展示的可选参数，不是资源标识
```

具体约定：

```
记录 ID        -> 路径参数    /item-editor/item-123
编辑页初始模式  -> 查询参数    /item-editor?mode=template
```

### 参数类型安全

GoRouter 的 `pathParameters` 和 `queryParameters` 都是 `String` 类型。转换和校验在路由配置里做，不在 Screen 里做：

```dart
// 正确：在路由配置里转换
GoRoute(
  path: Routes.itemEditorWithId,
  builder: (context, state) {
    final id = state.pathParameters['id'];
    // id 为 null 时 ItemEditorScreen 视为新建模式
    return ItemEditorScreen(itemId: id);
  },
),

// 错误：在 Screen 里解析路由参数
class ItemEditorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final id = GoRouterState.of(context).pathParameters['id'];  // 不要这样做
  }
}
```

Screen 只接收已经转换好的强类型参数，不从 `GoRouterState` 里读原始字符串。

### 不用路由传递复杂对象

```dart
// 错误：通过路由 extra 传对象
context.push(Routes.itemEditor, extra: itemObject);

// 正确：只传 ID，Screen 里通过 Provider 加载
context.push('/item-editor/${item.id}');
```

通过路由传递对象有两个问题：一是 URL 无法被分享或还原；二是 app 进入后台再回来时 extra 对象会丢失。只传 ID，目标页面通过 ID 加载数据。

---

## 返回值

GoRouter 的 `push` 可以等待返回值：

```dart
// 打开编辑页，等待结果
final result = await context.push<bool>(Routes.itemEditor);
if (result == true) {
  // 用户保存了，刷新列表
  ref.invalidate(itemListNotifierProvider);
}
```

返回值只传语义信号（保存了 / 取消了），不传修改后的对象。修改后的数据通过 Provider 刷新获取，不通过返回值传递。

---

## 嵌套路由

如果页面内有 tab 切换（如列表页内的不同视图），优先用 Widget 状态管理，不用路由嵌套。只有以下情况使用嵌套路由：

```
URL 需要反映当前 tab 状态（用于分享或外部跳转）
不同 tab 有独立的导航栈
```

如果只是简单的 tab 切换且不需要 URL 追踪，用 `IndexedStack` 或 `TabBarView`，不要引入 `ShellRoute`。

---

## 页面跳转的发起位置

```
用户点击触发的跳转    -> 在 Widget 的 onTap 回调里调用 context.go / push
业务逻辑触发的跳转    -> 在 Notifier 里通过 ref 获取 router，或用全局 navigatorKey
```

Screen 和 Section 可以直接调用 `context.go/push`。叶子组件（Card / Cell / Chip）不直接跳转，通过 `onTap` 回调把事件传给父组件，由父组件决定是否跳转。

```dart
// 正确：叶子组件通过回调
ItemCard(
  item: item,
  onTap: () => context.push('/item-editor/${item.id}'),
)

// 错误：叶子组件内部跳转
class ItemCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/item-editor/${item.id}'),  // 叶子组件不应该知道路由
    );
  }
}
```

---

## 深链接

如果需要支持深链接，在 GoRouter 配置里声明，不要在代码里手动解析 URL：

```dart
GoRouter(
  initialLocation: Routes.list,
  routes: [...],
  // 深链接由 GoRouter 自动处理，只需要确保路由路径和 URL Scheme 对应
)
```

深链接的参数处理规则和普通跳转一致：只传 ID，页面自己加载数据。

---

## 维护规则

```
新增页面        -> 在 routes.dart 添加路径常量，在 app_router.dart 添加 GoRoute
删除页面        -> 同步删除 routes.dart 里的常量和 app_router.dart 里的路由
修改路由路径    -> 全局搜索旧路径，一次性更新所有使用处
新增路由参数    -> 在 app_router.dart 里做类型转换，Screen 的构造函数加对应参数
```
