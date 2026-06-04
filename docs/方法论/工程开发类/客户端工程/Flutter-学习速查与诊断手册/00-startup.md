# 0-1 项目启动指南
> 本文回答：如何从 `flutter create` 零开始搭建一个完整的 Flutter 项目骨架，让第一个 Feature 可运行。
> 
> **前置知识**：安装了 Flutter SDK（3.12+）、Xcode（iOS/macOS）、有 Dart 基础。
> 
> **不解决**：UI 设计、代码细节、IDE 配置、签名上架。UI 和架构设计见 [02-architecture.md](02-architecture.md)；编码写法见 [05-vibe-coding.md](05-vibe-coding.md)。

---

## 0. 环境检查

在创建项目前，确保开发环境已准备好。

```bash
flutter doctor
```

输出应显示：
- Flutter SDK ✓
- Xcode ✓（iOS/macOS 开发）
- iOS deployment target ✓（14.0+）
- macOS deployment target ✓（11.0+）

如果有缺失，根据提示安装或修复。

---

## 1. 创建项目

```bash
flutter create heat_moment_flutter
cd heat_moment_flutter
```

这会生成一个包含默认计数器 App 的项目。删除不需要的部分：

```bash
# 删除默认代码（保留 pubspec.yaml 和目录结构）
rm lib/main.dart lib/main_production.dart lib/main_staging.dart
mkdir -p lib/{app,core/{database,theme,presentation},features}
```

---

## 2. 配置依赖（pubspec.yaml）

用以下内容替换 `pubspec.yaml` 的 `dependencies` 和 `dev_dependencies` 部分：

**dependencies：**
```yaml
flutter:
  sdk: flutter

cupertino_icons: ^1.0.8
go_router: ^17.2.3            # 声明式路由
flutter_riverpod: ^3.3.1      # 状态管理
drift: ^2.33.0                # 本地数据库 ORM
drift_flutter: ^0.3.0
path_provider: ^2.1.5         # 文件路径
path: ^1.9.1
image_picker: ^1.2.2          # 相册/相机
uuid: ^4.5.3                  # UUID 生成
intl: ^0.20.2                 # 国际化/日期格式
```

**dev_dependencies：**
```yaml
flutter_test:
  sdk: flutter

flutter_lints: ^6.0.0
build_runner: ^2.15.0         # 代码生成入口
drift_dev: ^2.33.0            # Drift 代码生成
```

然后安装依赖：

```bash
flutter pub get
```

---

## 3. MVP 目录树

这是项目启动后的目标目录结构。**标注说明**：
- `← 手写`：你需要创建的文件
- `← 代码生成`：运行 `flutter pub run build_runner build` 后自动生成
- `← 保留`：不改动的默认文件

```
heat_moment_flutter/
├── lib/
│   ├── main.dart                        ← 手写，3 行
│   ├── app/
│   │   ├── app.dart                     ← 手写，MaterialApp 配置
│   │   ├── bootstrap.dart               ← 手写，初始化入口
│   │   └── router.dart                  ← 手写，go_router 路由表
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart        ← 手写，Drift 表定义
│   │   │   ├── app_database.g.dart      ← 代码生成，不手改
│   │   │   └── database_providers.dart  ← 手写，AppDatabase Provider
│   │   ├── theme/
│   │   │   └── app_theme.dart           ← 手写，主题配置（最简）
│   │   └── presentation/                ← 通用 UI 组件，目前为空
│   └── features/
│       └── notes/                       ← 示例 feature，按业务替换名称
│           ├── domain/
│           │   └── note.dart            ← 手写，数据类
│           ├── data/
│           │   ├── note_repository.dart ← 手写，Repository
│           │   └── note_providers.dart  ← 手写，Riverpod Provider
│           └── presentation/
│               └── notes_screen.dart    ← 手写，ConsumerWidget
├── pubspec.yaml                         ← 已修改
└── ios/, macos/, android/               ← 保留（原生平台代码）
```

---

## 4. 搭建骨架

### 4.1 应用启动入口（main.dart + bootstrap.dart + app.dart）

**lib/main.dart**（3 行）：

```dart
import 'app/bootstrap.dart';

void main() {
  bootstrap();
}
```

**lib/app/bootstrap.dart**（初始化）：

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  // 可在此处添加其他初始化：数据库迁移、权限申请等

  runApp(const ProviderScope(child: HeatMomentFlutterApp()));
}
```

**lib/app/app.dart**（MaterialApp 配置）：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class HeatMomentFlutterApp extends ConsumerWidget {
  const HeatMomentFlutterApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Heat Moment',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
```

### 4.2 路由配置（router.dart）

**lib/app/router.dart**（起步，包含一个空路由）：

```dart
import 'package:go_router/go_router.dart';

import '../features/notes/presentation/notes_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const NotesScreen(),
    ),
  ],
);
```

之后每添加一个 Feature 时，在这里新增对应的 GoRoute。

### 4.3 主题配置（最简）

**lib/core/theme/app_theme.dart**：

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.blue,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: Colors.blue,
    );
  }
}
```

### 4.4 数据库初始化（Drift）

**lib/core/database/app_database.dart**（表定义）：

```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// 示例表：Note
@DataClassName('NoteRow')
class NoteRows extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// 数据库类（所有表都注册在这里）
@DriftDatabase(tables: [NoteRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'heat_moment'));

  @override
  int get schemaVersion => 1;
}
```

**lib/core/database/database_providers.dart**（Riverpod Provider）：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
```

**代码生成（必须！）**：

修改 Drift 表定义后，必须运行：

```bash
flutter pub run build_runner build
```

这会在 `app_database.dart` 同级生成 `app_database.g.dart`（自动生成的代码，不手改）。

如果出现文件冲突，用 `build_runner clean` 后重新 `build`。

---

## 5. 第一个 Feature（完整骨架）

这里用 `notes` 作示例 feature。实际项目中替换为你的业务名称。

### 5.1 domain 层（数据模型）

**lib/features/notes/domain/note.dart**：

```dart
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 5.2 data 层（Repository + Provider）

**lib/features/notes/data/note_repository.dart**：

```dart
import '../domain/note.dart';
import '../../../core/database/app_database.dart';

class NoteRepository {
  NoteRepository(this._database);
  final AppDatabase _database;

  // 实时监听所有 note
  Stream<List<Note>> watchNotes() {
    return _database.select(_database.noteRows)
      .watch()
      .map((rows) => rows.map(_mapRow).toList());
  }

  // 插入 note
  Future<void> createNote(Note note) async {
    await _database.into(_database.noteRows).insert(
      NoteRowsCompanion(
        id: Value(note.id),
        title: Value(note.title),
        content: Value(note.content),
        createdAt: Value(note.createdAt),
        updatedAt: Value(note.updatedAt),
      ),
    );
  }

  Note _mapRow(NoteRow row) {
    return Note(
      id: row.id,
      title: row.title,
      content: row.content,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
```

**lib/features/notes/data/note_providers.dart**：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/note.dart';
import 'note_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(ref.watch(appDatabaseProvider));
});

final notesProvider = StreamProvider<List<Note>>((ref) {
  return ref.watch(noteRepositoryProvider).watchNotes();
});
```

### 5.3 presentation 层（UI）

**lib/features/notes/presentation/notes_screen.dart**：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/note_providers.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: notes.when(
        data: (list) => list.isEmpty
          ? const Center(child: Text('No notes yet'))
          : ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final note = list[index];
              return ListTile(
                title: Text(note.title),
                subtitle: Text(note.content),
              );
            },
          ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
```

### 5.4 注册路由

你已经在 `router.dart` 中添加了 `NotesScreen` 的路由，现在可以测试了。

---

## 6. 验证项目

### 第一步：验证静态分析和构建

```bash
scripts/flutter-dev.sh verify
```

这会运行 `analyze` 和 `test`。如果出现编译错误，按提示修复。

### 第二步：本地运行

**iOS：**
```bash
scripts/flutter-dev.sh run-ios
```

**macOS：**
```bash
scripts/flutter-dev.sh run-macos
```

脚本会自动启动模拟器并运行应用。应该看到空的 `NotesScreen`（"No notes yet"）。

### 第三步：Hot Reload 验证

应用运行后，在终端输入 `r` 按 Enter，应该看到热重载成功。修改 `NotesScreen` 的标题文案，再按 `r`，看是否生效。

---

## 7. 常见坑点

### 7.1 Drift 代码生成失败

**症状**：`app_database.g.dart` 未生成，或生成后编译仍报错。

**排查**：
1. 确认 `part 'app_database.g.dart';` 在 `app_database.dart` 顶部
2. 确认没有手改 `app_database.g.dart`（这是生成文件，修改会被覆盖）
3. 运行 `flutter pub run build_runner clean && flutter pub run build_runner build`

### 7.2 Provider 初始化报错

**症状**：`ProviderNotFoundException` 或 `FutureOr cast failed`。

**排查**：
1. 确认 `appDatabaseProvider` 在 `database_providers.dart` 中注册
2. 确认所有 Provider 的 import 路径正确
3. 确认没有循环依赖（A Provider 依赖 B，B 又依赖 A）

### 7.3 路由参数问题

**症状**：`GoRoute` 里的 `pathParameters['xxx']` 为 null 或报类型错误。

**排查**：
1. 确认路由路径包含 `:xxx`（如 `/notes/:noteId`）
2. 确认 `context.push` 时传的 URL 包含参数值（如 `context.push('/notes/$id')`）
3. 阅读 [05-vibe-coding.md Part 2 第一章](05-vibe-coding.md#一页面导航go_router) 的路由写法

### 7.4 UI 不刷新

**症状**：数据库更新后，UI 没有重新渲染。

**诊断**：
- 确认 Repository 用的是 `watch()` 而非 `get()`（见 [02-architecture.md 三、数据流主干](02-architecture.md#三数据流主干)）
- 确认 Provider 是 `StreamProvider` 而非 `FutureProvider`
- 确认 Widget 用的是 `ConsumerWidget` 并调用了 `ref.watch(provider)`

### 7.5 Hot Reload 改了代码但没有生效

**症状**：修改了代码，hot reload（按 `r`）后，应用没有显示新内容；有时需要 hot restart（按 `R`）才生效。

**何时需要 Hot Restart 而非 Hot Reload：**
- 改了 `const` 值（const 在编译时固化，reload 不会重新计算）
- 改了 `initState()` 或 `init` 方法内的逻辑（状态初始化不会再运行）
- 改了 Provider 的定义或 Riverpod 配置
- 改了 Drift 表结构或 Database 类定义
- 改了 main.dart 或 bootstrap.dart

**何时只需 Hot Reload：**
- 改了 UI 布局、样式、文本内容
- 改了 build 方法内的逻辑
- 改了 Repository 方法或一般业务逻辑

理解区别：**Hot Reload 只重新执行 build 树，不重新初始化应用。** 初始化类代码改了，必须 Restart。

### 7.6 代码生成每次都要手动运行

**症状**：改了 Drift 表定义或其他用 `build_runner` 生成的代码，每次都得手动运行 `flutter pub run build_runner build`，效率低且容易忘。

**解决方案**：在开发阶段使用 `watch` 模式：

```bash
flutter pub run build_runner watch
```

此命令会持续监听源文件变化，一旦 `app_database.dart`、`@DataClassName` 等标记文件被修改，自动重新生成代码，无需手动。

**使用场景**：
- 开发新 Feature 时，如果涉及 Drift 表或 domain model，启动 watch 模式
- watch 会占用一个终端窗口，新建另一个窗口运行 `flutter run`
- 保存编辑器中的文件，watch 会自动重新生成，app 会热重载
- 需要停止时按 Ctrl+C

**注意**：`build_runner watch` 有时会报文件冲突，遇到时运行 `flutter pub run build_runner clean && build_runner watch` 重新开始。

---

## 延伸

新项目骨架搭完后的后续步骤：

| 任务 | 文档 |
|---|---|
| 加第二个 Feature，学习标准流程 | [02-architecture.md 四、新功能开发路径](02-architecture.md#四新功能开发路径6-步标准流程) |
| 设计导航、交互和状态管理判断 | [04-standards.md](04-standards.md) |
| 具体 Widget 写法和 Riverpod 操作 | [05-vibe-coding.md](05-vibe-coding.md) |
| 技术栈升级和复杂度处理 | [03-stack.md](03-stack.md) |
