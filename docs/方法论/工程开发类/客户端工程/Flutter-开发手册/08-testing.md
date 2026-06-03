# 测试与验证指南
> 本文回答：在 Flutter 项目中，该写什么测试、怎么组织、如何集成到日常工作流。
> 
> **前置阅读**：无（可与项目开始同步进行）。
> 
> **不解决**：测试框架的完整 API（用官方文档）；CI/CD 和线上构建配置（属于运维）；测试驱动开发（TDD）的深入讨论。

---

## 一、三种测试的分工

Flutter 中的三种测试适用不同场景。理解各自的职责，才能在效率和覆盖率间找到平衡。

### Unit Test（单元测试）

**范围**：纯 Dart 逻辑，不涉及 Flutter Widget 或系统接口。

**适用对象**：
- Domain model 的业务规则（如 `Item` 的 `copyWith`、校验方法）
- Repository 映射逻辑（Row → Model 的转换）
- Provider 的状态计算（如 `filteredItems` 派生逻辑）
- 工具函数（如 date formatter、string parser）

**示例代码**：

```dart
// test/features/entries/domain/diary_entry_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:heat_moment_flutter/features/entries/domain/diary_entry.dart';

void main() {
  group('DiaryEntry', () {
    test('copyWith 更新指定字段', () {
      final entry = DiaryEntry(
        id: '1',
        title: 'Old Title',
        mood: 'happy',
        createdAt: DateTime.now(),
      );

      final updated = entry.copyWith(title: 'New Title');

      expect(updated.title, 'New Title');
      expect(updated.mood, 'happy'); // 其他字段不变
    });

    test('isValid 验证标题不为空', () {
      final validEntry = DiaryEntry(
        id: '1',
        title: 'Valid Title',
        mood: 'happy',
        createdAt: DateTime.now(),
      );

      final invalidEntry = DiaryEntry(
        id: '2',
        title: '', // 空标题
        mood: 'happy',
        createdAt: DateTime.now(),
      );

      expect(validEntry.isValid, true);
      expect(invalidEntry.isValid, false);
    });
  });
}
```

**运行**：
```bash
flutter test test/features/entries/domain/diary_entry_test.dart
```

---

### Widget Test（小部件测试）

**范围**：单个 Widget 的渲染和用户交互，不涉及整个应用流程。

**适用对象**：
- 独立的 UI 组件（如自定义按钮、标签、输入框）
- 单个 Screen 的布局和显示逻辑（如列表项的渲染）
- 用户交互响应（如点击、输入、滚动）

**示例代码**：

```dart
// test/features/entries/presentation/entry_list_item_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heat_moment_flutter/features/entries/domain/diary_entry.dart';
import 'package:heat_moment_flutter/features/entries/presentation/entry_list_item.dart';

void main() {
  group('EntryListItem', () {
    testWidgets('显示 entry 的标题和 mood', (WidgetTester tester) async {
      final entry = DiaryEntry(
        id: '1',
        title: 'Test Entry',
        mood: 'happy',
        createdAt: DateTime(2026, 6, 2),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EntryListItem(entry: entry),
          ),
        ),
      );

      expect(find.text('Test Entry'), findsOneWidget);
      expect(find.text('😊'), findsOneWidget); // mood icon
    });

    testWidgets('点击 item 触发 onTap 回调', (WidgetTester tester) async {
      final entry = DiaryEntry(...);
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EntryListItem(
              entry: entry,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byWidget(EntryListItem));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });
  });
}
```

**运行**：
```bash
flutter test test/features/entries/presentation/entry_list_item_test.dart
```

**关键操作**：
- `tester.pumpWidget()` — 渲染 widget 到测试环境
- `tester.pumpAndSettle()` — 等待所有动画和异步完成
- `find.text()`、`find.byType()` — 查找 widget
- `tester.tap()`、`tester.enterText()` — 模拟用户操作

---

### Integration Test（集成测试）

**范围**：完整用户流程，从启动应用到完成一项任务。

**适用对象**：
- 核心业务路径（如"新建日记 → 添加标签 → 保存"）
- 跨 feature 的流程（如"编辑日记 → 预览 → 返回列表"）
- 导航流（如"主页 → 详情页 → 返回"）

**示例代码**：

```dart
// test_driver/app.dart（应用启动脚本）
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:heat_moment_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  app.main();
}
```

```dart
// integration_test/create_entry_test.dart（测试脚本）
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Create Entry Flow', () {
    testWidgets('用户能创建新日记并保存', (WidgetTester tester) async {
      // 等待应用启动
      await tester.pumpAndSettle();

      // 点击新建按钮
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 输入标题
      await tester.enterText(
        find.byType(TextField).first,
        'My First Entry',
      );

      // 选择心情
      await tester.tap(find.text('😊'));
      await tester.pumpAndSettle();

      // 保存
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // 验证保存成功，返回到列表
      expect(find.text('My First Entry'), findsOneWidget);
    });
  });
}
```

**运行**：
```bash
flutter test integration_test/create_entry_test.dart
```

---

## 二、什么该测、什么不必测

### 优先写（高优先级）

| 对象 | 原因 | 示例 |
|---|---|---|
| Domain 模型的业务规则 | 这是核心逻辑，错了影响大 | Entry 的 mood 验证、时间计算 |
| Repository 映射 | Row → Model 的转换如果错了，UI 展示就错 | `DriftEntryRepository._mapRow()` |
| Provider 派生逻辑 | 计算逻辑（如筛选、排序）容易出 bug | `filteredEntriesProvider` 的过滤条件 |
| 关键用户流 | 确保核心路径可用 | 新建 → 编辑 → 删除 的完整流 |

### 不必写（低优先级）

| 对象 | 原因 |
|---|---|
| Widget 内部细节 | 框架已验证，UI 可视化测试效率更高 |
| Drift 本身 | Drift 是第三方库，已有完整测试 |
| Material/Cupertino 组件 | Flutter 框架已测试 |
| 简单 getter/setter | 直接代码审查就能验证 |
| 异步超时场景 | 成本高，通常不值得（除非关键路径） |

### 折中方案

对于想覆盖但成本高的场景，用更轻量的方式：

| 场景 | 完整测试成本 | 轻量方案 |
|---|---|---|
| 复杂 UI 交互（多步骤、分支多） | Widget Test 行数多，脆弱 | 手工测试 + Snapshot Test（保存 golden 文件） |
| 网络请求 | Integration Test 需要真实服务器 | Unit Test + Mock `http.Client` |
| 权限申请（相册、相机） | Integration Test 需要设备权限 | Mock `ImagePicker`，只测逻辑 |
| 后台任务 | Integration Test 难以控制 | 测试任务的业务逻辑部分，跳过后台框架 |

---

## 三、测试文件组织

**原则**：镜像 `lib/` 的目录结构，在 `test/` 对应位置放测试文件。

```
lib/
├── features/
│   ├── entries/
│   │   ├── domain/
│   │   │   └── diary_entry.dart
│   │   ├── data/
│   │   │   └── entry_repository.dart
│   │   └── presentation/
│   │       └── entry_list_item.dart
│   └── tags/
│       ├── domain/
│       │   └── tag.dart
│       └── data/
│           └── tag_repository.dart
└── core/
    ├── domain/
    │   └── common.dart
    └── database/
        └── app_database.dart

test/
├── features/
│   ├── entries/
│   │   ├── domain/
│   │   │   └── diary_entry_test.dart
│   │   ├── data/
│   │   │   └── entry_repository_test.dart
│   │   └── presentation/
│   │       └── entry_list_item_test.dart
│   └── tags/
│       ├── domain/
│       │   └── tag_test.dart
│       └── data/
│           └── tag_repository_test.dart
└── core/
    ├── domain/
    │   └── common_test.dart
    └── database/
        └── app_database_test.dart

integration_test/
├── create_entry_test.dart
├── edit_entry_test.dart
└── delete_entry_test.dart
```

**命名约定**：
- Unit/Widget Test：`lib/path/to/file.dart` → `test/path/to/file_test.dart`
- Integration Test：`integration_test/[feature]_test.dart`

---

## 四、本地验证工作流

### 日常开发

```bash
# 修改代码后，运行关联的 unit/widget test
flutter test test/features/entries/domain/

# 或运行某个特定测试
flutter test test/features/entries/domain/diary_entry_test.dart

# 全量测试（所有单元测试）
flutter test

# 输出覆盖率报告（可选）
flutter test --coverage
```

### 提交前验证（核心流程）

```bash
# 使用脚本
scripts/flutter-dev.sh verify

# 或手动：analyze + test
flutter analyze
flutter test
```

### 重要改动前的完整验证

```bash
scripts/flutter-dev.sh verify-build

# 包含：analyze + test + iOS build + macOS build
```

### 集成测试（本地测试关键流程）

```bash
# 运行单个集成测试
flutter test integration_test/create_entry_test.dart

# 运行所有集成测试
flutter test integration_test/
```

---

## 五、常用测试骨架代码

### Unit Test 模板

```dart
// test/features/[feature]/domain/[model]_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:heat_moment_flutter/features/[feature]/domain/[model].dart';

void main() {
  group('[ModelName]', () {
    test('description of test', () {
      // Arrange
      final model = [ModelName](
        // 初始化对象
      );

      // Act
      final result = model.someMethod();

      // Assert
      expect(result, expectedValue);
    });

    test('another test', () {
      // Arrange
      // Act
      // Assert
    });
  });
}
```

### Widget Test 模板

```dart
// test/features/[feature]/presentation/[widget]_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heat_moment_flutter/features/[feature]/presentation/[widget].dart';

void main() {
  group('[WidgetName]', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: [WidgetName](
              // props
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('Expected Text'), findsOneWidget);
    });

    testWidgets('responds to user input', (WidgetTester tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: [WidgetName](
              onTap: () => callbackCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byWidget([WidgetName]));
      await tester.pumpAndSettle();

      expect(callbackCalled, true);
    });
  });
}
```

### Repository Unit Test 模板

```dart
// test/features/[feature]/data/[model]_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:heat_moment_flutter/core/database/app_database.dart';
import 'package:heat_moment_flutter/features/[feature]/data/[model]_repository.dart';
import 'package:heat_moment_flutter/features/[feature]/domain/[model].dart';

class Mock[Model]Database extends Mock implements AppDatabase {}

void main() {
  group('[Model]Repository', () {
    late Mock[Model]Database mockDatabase;
    late [Model]Repository repository;

    setUp(() {
      mockDatabase = Mock[Model]Database();
      repository = [Model]Repository(mockDatabase);
    });

    test('watchItems returns stream of items', () async {
      // Mock Drift 的返回值
      when(mockDatabase.select(any).watch()).thenAnswer(
        (_) => Stream.value([
          [Model]Row(...),
        ]),
      );

      // Act
      final stream = repository.watch[Models]();
      final items = await stream.first;

      // Assert
      expect(items, isNotEmpty);
      expect(items.first, isA<[Model]>());
    });
  });
}
```

### Integration Test 模板

```dart
// integration_test/[feature]_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:heat_moment_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('[Feature] Flow', () {
    testWidgets('complete user journey', (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();

      // 用户操作序列
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Input');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // 验证结果
      expect(find.text('Success'), findsOneWidget);
    });
  });
}
```

---

## 六、测试运行与 CI 集成

### 本地运行清单

| 步骤 | 命令 | 检查点 |
|---|---|---|
| 代码分析 | `flutter analyze` | 无 warning 或 error |
| Unit Test | `flutter test test/` | 所有测试绿色 ✓ |
| Widget Test | `flutter test test/` | 所有测试绿色 ✓ |
| 集成测试 | `flutter test integration_test/` | 关键流程通过 ✓ |
| 构建验证 | `scripts/flutter-dev.sh verify-build` | iOS + macOS build 成功 ✓ |

### 常见问题与解决

| 问题 | 原因 | 解决 |
|---|---|---|
| `LateInitializationError` in test | Provider 没有初始化 | 用 ProviderContainer 或 override provider |
| Widget Test timeout | 动画或异步未完成 | 改 `pumpAndSettle()` timeout，或加 `skip: true` 跳过 |
| Mock 不生效 | import 位置错误，或 Mockito 版本问题 | 检查 `package:mockito/mockito.dart`，运行 `flutter clean` |
| Integration Test 卡住 | 网络请求、权限对话框 | Mock 网络层，跳过权限申请（用环境变量或参数） |

---

## 延伸阅读

| 话题 | 参考 |
|---|---|
| 单元测试最佳实践 | [Flutter 官方：Unit testing](https://flutter.dev/docs/testing/unit-testing) |
| Widget Test 详细教程 | [Flutter 官方：Widget testing](https://flutter.dev/docs/testing/widget-testing) |
| 集成测试指南 | [Flutter 官方：Integration testing](https://flutter.dev/docs/testing/integration-testing) |
| Mockito 用法 | [pub.dev: mockito](https://pub.dev/packages/mockito) |
| 覆盖率工具 | [lcov](https://github.com/linux-test-project/lcov) 和 `flutter test --coverage` |

---

*版本：Flutter 3.x · 2026*
