# Flutter 项目分层架构
> 本文回答三个问题：代码分几层、数据怎么流动、加新功能要动哪里。
>
> **前置阅读**：[01-thinking.md](01-thinking.md) — 先建立响应式心智模型再看本文。
>
> **不解决**：具体 Widget 用法 → [05-vibe-coding.md](05-vibe-coding.md)；技术选型 → [03-stack.md](03-stack.md)；UI 判断规则 → [04-standards.md](04-standards.md)。

---

## 一、全局目录结构

```
lib/
├── main.dart              ← 程序入口，启动 Bootstrap
├── app/                   ← 应用层：路由配置、全局初始化
│   ├── app.dart           ← MaterialApp / ProviderScope 根配置
│   ├── bootstrap.dart     ← 数据库初始化、环境准备
│   └── router.dart        ← go_router 路由表（所有页面路径在这里注册）
│
├── core/                  ← 公共基础设施（跨 feature 共享）
│   ├── database/          ← Drift 数据库定义、表结构、Provider
│   ├── theme/             ← 主题系统、色板、视觉 token
│   ├── presentation/      ← 跨 feature 可复用组件
│   └── time/              ← 时间工具（按需添加同类工具目录）
│
└── features/              ← 按功能垂直切分，每个 feature 独立
    └── {feature}/
        ├── data/          ← 数据访问层：Repository + Riverpod Provider
        ├── domain/        ← 领域模型层：数据类型 + 业务规则
        └── presentation/  ← UI 层：Screen + Widget
```

---

## 二、各层职责与边界

### Presentation 层（UI 层）

**职责**：渲染界面、响应用户操作、通过 `ref.watch` 订阅数据。

**可以做**：
- `ref.watch(provider)` 读取状态，自动订阅
- `ref.read(provider)` 在回调里触发操作
- `context.go()` / `context.push()` 导航
- 本地 UI 状态（展开/收起、选中项）用 `StatefulWidget`

**不可以做**：
- 直接操作数据库
- 直接调用 Repository
- 包含业务计算逻辑

### Domain 层（领域模型层）

**职责**：定义数据结构和业务规则，是整个 feature 的核心，纯 Dart，无外部依赖。

**可以做**：
- 定义数据类（`Item`、`Tag`、`Category`）
- 定义查询条件类（`ItemFilter`）
- 包含纯业务计算（不依赖 Flutter 或 Drift）

**不可以做**：
- import Flutter widgets
- import Drift 表结构
- 直接访问数据库

### Data 层（数据访问层）

**职责**：桥接 UI 和数据库，包含 Repository 和 Riverpod Provider。

- **Repository**：封装 Drift 查询，把数据库 Row 映射成 Domain 模型
- **Provider**：把 Repository 的数据源暴露给 UI

**可以做**：
- import domain 模型
- import core/database
- 定义 Riverpod Provider

**不可以做**：
- import Flutter widgets
- 包含 UI 状态逻辑

### Core 层（公共基础设施）

**职责**：跨 feature 共享的能力。

**判断是否该放 core**：两个及以上 feature 需要用 → `core/`；只有一个 feature 用 → 放 feature 内部。

---

## 三、数据流主干

读和写是两条独立的链路（原理见 [01-thinking.md](01-thinking.md)）。

### 读链路（实时订阅）

```
Screen (ref.watch)
  ↓ 订阅
StreamProvider<List<Item>>
  ↓ 依赖
Repository.watchItems(filter)
  ↓
Drift query.watch() → SQLite
  ↑
  └── 数据变化时自动推送 → StreamProvider 推送 → UI 自动重建
```

### 写链路（命令式触发）

```
用户操作
  ↓
ref.read(repositoryProvider).save(data)
  ↓
Repository.save() → Drift 写入 SQLite
  ↓
Drift 自动通知所有 watch() 订阅者 → 读链路触发 → UI 重建
```

写操作完成后**不需要手动 `ref.invalidateSelf()`**——Drift `watch()` 自动传播。

### Provider 依赖链

```
appDatabaseProvider          ← core/database，全局唯一数据库实例
  ↓
{feature}RepositoryProvider  ← 每个 feature 自己的 data/ 目录
  ↓
{feature}Provider(params)    ← UI 订阅这里，StreamProvider 或 FutureProvider
```

---

## 四、新功能开发路径（6 步标准流程）

### Step 1：定义 Domain 模型

```dart
// features/tags/domain/tag.dart
class Tag {
  const Tag({required this.id, required this.name, required this.colorHex});
  final String id;
  final String name;
  final String colorHex;
}
```

### Step 2：定义数据库表结构

在 `core/database/app_database.dart` 里增加表，然后运行代码生成：

```dart
class TagRows extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get colorHex => text()();
  @override
  Set<Column> get primaryKey => {id};
}
```

```bash
dart run build_runner build
```

### Step 3：创建 Repository

```dart
// features/tags/data/tag_repository.dart
class TagRepository {
  TagRepository(this._database);
  final AppDatabase _database;

  Stream<List<Tag>> watchTags() {
    return _database.select(_database.tagRows)
      .watch()
      .map((rows) => rows.map(_mapRow).toList());
  }

  Future<void> insertTag(Tag tag) async {
    await _database.into(_database.tagRows).insert(
      TagRowsCompanion.insert(id: tag.id, name: tag.name, colorHex: tag.colorHex),
    );
  }

  Tag _mapRow(TagRow row) => Tag(id: row.id, name: row.name, colorHex: row.colorHex);
}
```

### Step 4：注册 Provider

```dart
// features/tags/data/tag_providers.dart
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepository(ref.watch(appDatabaseProvider));
});

final tagsProvider = StreamProvider<List<Tag>>((ref) {
  return ref.watch(tagRepositoryProvider).watchTags();
});
```

### Step 5：创建 Screen

```dart
// features/tags/presentation/tags_screen.dart
class TagsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsProvider);
    return tags.when(
      data: (list) => ListView.builder(itemCount: list.length, itemBuilder: ...),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('加载失败'),
    );
  }
}
```

### Step 6：注册路由

```dart
// app/router.dart
GoRoute(
  path: '/tags',
  builder: (context, state) => const TagsScreen(),
),
```

---

## 五、常见判断

**这段逻辑放 domain 还是 data？**
不依赖数据库和 Flutter → domain。需要读写数据库 → data（Repository）。

**这个 Provider 放 feature 的 data/ 还是 core/?**
只有一个 feature 用 → feature 内部。两个及以上 feature 用 → `core/`。

**StreamProvider 还是 FutureProvider？**
需要实时响应数据库变化 → `StreamProvider`（配合 Drift `watch()`）。
一次性读取（初始化配置）→ `FutureProvider`。

**写操作后需要手动刷新列表吗？**
不需要。Drift `watch()` 是响应式的，任何写操作自动通知所有订阅者。

---

## 六、快速诊断

> 完整诊断见 [06-diagnostics.md](06-diagnostics.md)，本节为就地速查摘要。

### "UI 不刷新" 问题诊断

| 症状 | 最可能的原因 | 检查清单 |
|---|---|---|
| 数据库有更新，但 UI 没变化 | Repository 用错了 `get()` 而非 `watch()` | 改 Repository 方法为 `Stream<List<T>> watch()`，在 Drift 查询后加 `.watch()` |
| 同上 | Provider 用错了 `FutureProvider` 而非 `StreamProvider` | 改 Provider 为 `StreamProvider<List<T>>`，依赖 Repository 的 watch 方法 |
| 页面显示旧数据，写操作后未更新 | 在回调里用了 `ref.read()` 但没有后续刷新逻辑 | 用 `ref.watch()` 订阅 Provider，写完后让 Drift watch() 自动推送（不需要手动 ref.invalidateSelf()) |
| 列表显示但新增项不出现 | Drift 写操作后忘记 await | 确认 `await _database.into(...).insert(...)` 已完成，再等待 watch() 通知 |

### "数据不同步" 问题诊断

| 症状 | 最可能的原因 | 检查清单 |
|---|---|---|
| 两个 Screen 看到的数据版本不一致 | Provider 被多次创建（family 参数变化导致重建） | 检查 Provider 是否用了 `.family`，如有参数变化，Riverpod 会新建 Provider 实例，旧订阅得不到更新 |
| Provider 值变化时，依赖它的其他 Provider 没有重算 | Provider 间依赖链条断了，或者中间层用了 StateProvider（无法自动传播） | 确认完整的依赖链：Database → Repository → Provider → UI；链条中不应有 StateProvider 承接 watch 的流 |

### "代码放错层" 问题诊断

| 症状 | 常见错位方式 | 修复 |
|---|---|---|
| presentation 里直接调用了数据库或 Drift | UI 层违规访问 Database | 把数据库操作移到 Repository，Repository 注入到 Provider，UI 只读 Provider |
| domain 类 import 了 Flutter widgets | 业务模型被 UI 框架污染 | domain 应该是纯 Dart（`import 'dart:...'` 和自定义包），删除所有 Flutter 相关 import |
| 业务计算逻辑放在 data/repository 里 | 领域逻辑不纯净，难以复用和测试 | 新增 domain 目录，把纯业务逻辑（不涉及数据库/UI）移到 domain，Repository 只负责读写映射 |

---

*基准：Flutter 3.x · Riverpod 3.x · go_router 17.x · Drift 2.x · 2026*
