# Flutter 测试规范

> 测试不是为了覆盖率数字，是为了让你在改代码时有足够的信心说"我没有破坏已有的行为"。写不对的测试比没有测试更危险，因为它给你虚假的安全感。

---

## 测试的三个层级

```
单元测试（Unit Test）
  测对象：数据模型、Repository、Notifier、工具函数
  不涉及：Widget、Flutter 框架、真实数据库
  运行速度：快（毫秒级）

Widget 测试（Widget Test）
  测对象：单个 Widget 或小型 Widget 树的渲染和交互
  不涉及：真实网络、真实数据库
  运行速度：中（秒级）

集成测试（Integration Test）
  测对象：完整用户链路，从 UI 操作到数据写入
  涉及：真实 Flutter 环境，可能涉及真实数据库
  运行速度：慢（分钟级）
```

三个层级不是可以互相替代的选项，是各自负责不同粒度的验证。不要用集成测试覆盖可以用单元测试验证的逻辑，也不要因为"单元测试覆盖了"就跳过关键路径的集成测试。

---

## 单元测试

### 测什么

```
✓ Domain Model 的计算属性和转换逻辑
✓ Repository 实现的数据转换（DTO -> Domain Model, Entity -> Domain Model）
✓ Notifier 的状态转换逻辑
✓ 纯函数工具方法（日期格式化、文本处理等）
✗ Dart 语言特性本身（不测 final 字段是否赋值成功）
✗ 框架行为（不测 Riverpod 的 watch 是否触发 rebuild）
```

### Repository 测试

Repository 测试用 mock DataSource，验证转换逻辑和错误处理，不验证 SQL 正确性。

```dart
void main() {
  late MockDiaryDao mockDao;
  late DiaryRepositoryImpl repository;

  setUp(() {
    mockDao = MockDiaryDao();
    repository = DiaryRepositoryImpl(dao: mockDao);
  });

  group('fetchByDateRange', () {
    test('返回转换后的 Domain Model 列表', () async {
      when(() => mockDao.getByDateRange(any(), any()))
          .thenAnswer((_) async => [diaryEntityFixture]);

      final result = await repository.fetchByDateRange(start, end);

      expect(result, hasLength(1));
      expect(result.first.id, equals(diaryEntityFixture.id));
      expect(result.first, isA<Diary>());  // 确认返回的是 Domain Model，不是 Entity
    });

    test('DataSource 抛出异常时转换为 AppError', () async {
      when(() => mockDao.getByDateRange(any(), any()))
          .thenThrow(SqliteException(1, 'disk I/O error'));

      expect(
        () => repository.fetchByDateRange(start, end),
        throwsA(isA<StorageError>()),  // 确认转换成了业务异常，不是原始 SqliteException
      );
    });
  });
}
```

### Notifier 测试

Notifier 测试用 `ProviderContainer`，验证状态在各种操作后是否正确。

```dart
void main() {
  late ProviderContainer container;
  late MockDiaryRepository mockRepository;

  setUp(() {
    mockRepository = MockDiaryRepository();
    container = ProviderContainer(overrides: [
      diaryRepositoryProvider.overrideWithValue(mockRepository),
    ]);
    addTearDown(container.dispose);
  });

  test('初始状态为 loading，加载完成后变为数据列表', () async {
    when(() => mockRepository.fetchByDateRange(any(), any()))
        .thenAnswer((_) async => [diaryFixture]);

    final notifier = container.read(diaryListNotifierProvider.notifier);
    
    // 初始是 loading
    expect(
      container.read(diaryListNotifierProvider),
      isA<AsyncLoading>(),
    );

    // 等待加载完成
    await container.read(diaryListNotifierProvider.future);

    expect(
      container.read(diaryListNotifierProvider).value,
      hasLength(1),
    );
  });
}
```

---

## Widget 测试

### 测什么

```
✓ 组件在不同 props 下的渲染结果（空列表 / 有数据 / 加载中 / 错误）
✓ 用户操作是否触发了正确的回调
✓ 边界情况下的 UI（超长文本、空图片、零条记录）
✗ 样式细节（颜色的精确值、像素级对齐）
✗ 动画的中间帧
```

### 叶子组件的测试结构

```dart
void main() {
  group('TimelineCard', () {
    testWidgets('展示日记的内容摘要', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TimelineCard(
            diary: diaryFixture,
            onTap: () {},
          ),
        ),
      );

      expect(find.text(diaryFixture.content.substring(0, 50)), findsOneWidget);
    });

    testWidgets('点击时调用 onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: TimelineCard(
            diary: diaryFixture,
            onTap: () { tapped = true; },
          ),
        ),
      );

      await tester.tap(find.byType(TimelineCard));
      expect(tapped, isTrue);
    });
  });
}
```

### 容器组件的测试结构

容器组件需要 mock Provider：

```dart
void main() {
  group('HomeTimeline', () {
    testWidgets('数据加载中时展示 skeleton', (tester) async {
      final container = ProviderContainer(overrides: [
        diaryListNotifierProvider.overrideWith(() => LoadingDiaryListNotifier()),
      ]);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeTimeline()),
        ),
      );

      expect(find.byType(TimelineSkeleton), findsOneWidget);
      expect(find.byType(TimelineCard), findsNothing);
    });

    testWidgets('筛选结果为空时展示 filteredOut 原因的 EmptyState', (tester) async {
      // 设置：有标签筛选，但没有匹配的日记
      final container = ProviderContainer(overrides: [
        diaryListNotifierProvider.overrideWith(() => EmptyDiaryListNotifier()),
        tagFilterNotifierProvider.overrideWith(() => ActiveTagFilterNotifier()),
      ]);

      await tester.pumpWidget(/* ... */);
      await tester.pump();

      final emptyState = tester.widget<EmptyState>(find.byType(EmptyState));
      expect(emptyState.reason, equals(EmptyReason.filteredOut));
    });
  });
}
```

### 测试 fixture

复用的测试数据放在 `test/fixtures/` 下，不要在每个测试文件里重复定义：

```
test/
├── fixtures/
│   ├── diary_fixture.dart
│   └── tag_fixture.dart
├── unit/
├── widget/
└── integration/
```

```dart
// test/fixtures/diary_fixture.dart
final diaryFixture = Diary(
  id: 'test-diary-1',
  content: '测试日记内容' * 10,  // 足够长，能测试截断逻辑
  createdAt: DateTime(2024, 6, 15, 10, 30),
  tags: [tagFixture],
);
```

---

## 集成测试

### 测什么

集成测试只覆盖最关键的用户链路，不追求全面覆盖：

```
✓ 首次启动，数据正确加载并展示
✓ 创建一条日记，首页时间轴正确更新
✓ 标签筛选，时间轴正确过滤
✓ 热力图点选，时间轴滚动到目标位置
✗ 和单元测试重复的逻辑（不要用集成测试验证 Repository 的转换逻辑）
```

### 集成测试和 Slice 的对应关系

每个功能 Slice 的 Acceptance 条件，应该至少有一条集成测试覆盖。这是从 Slice 到测试的直接映射：

```dart
// Slice acceptance: 用户点击热力图某天，时间轴滚动到当天第一条记录
testWidgets('热力图点选 - 时间轴滚动到目标日期', (tester) async {
  // 准备：首页已加载，有多天的数据
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();

  // 操作：点击热力图某个日期
  await tester.tap(find.byKey(Key('heat_map_cell_2024_06_15')));
  await tester.pumpAndSettle();

  // 验证：时间轴滚动到了 6 月 15 日的分组
  expect(find.text('2024年6月15日'), findsOneWidget);
  // 验证该日期的卡片在可见区域内
  expect(tester.getTopLeft(find.byKey(Key('day_group_2024_06_15'))).dy,
         lessThan(tester.getSize(find.byType(HomeTimeline)).height));
});
```

---

## 测试的命名规范

### 测试描述的写法

```dart
// 正确：描述行为，不描述实现
test('返回转换后的 Domain Model 列表', () {});
test('DataSource 抛出异常时转换为 AppError', () {});
testWidgets('筛选结果为空时展示 filteredOut 原因的 EmptyState', (t) {});

// 错误：描述实现细节
test('调用了 mockDao.getByDateRange 方法', () {});  // 测的是实现，不是行为
test('emptyReason 等于 filteredOut', () {});        // 太技术化，失去产品语义
```

### group 的组织方式

用 `group` 按组件或方法分组，嵌套最多两层：

```dart
group('DiaryRepositoryImpl', () {
  group('fetchByDateRange', () {
    test('有数据时返回列表', () {});
    test('无数据时返回空列表', () {});
    test('DataSource 异常时抛出 StorageError', () {});
  });
  group('save', () {
    test('新记录成功写入', () {});
    test('更新已有记录', () {});
  });
});
```

---

## 什么时候写测试

### 不要等"功能完成后"再写测试

测试应该在实现的同一个工作单元里完成，不是之后的工作。"先实现再补测试"的结果通常是测试永远补不完。

### 修 bug 必须先写失败的测试

```
1. 复现 bug：写一个当前会失败的测试
2. 修复代码：让测试通过
3. 确认没有回归：跑完整测试套件
```

这确保了：1）bug 确实被修复了；2）以后不会回归。

### 优先级

```
高优先级（必须有）：
  Repository 的错误处理路径
  Notifier 的关键状态转换
  容器组件的三种异步状态（loading/error/data）
  Slice Acceptance 条件对应的集成测试

中优先级（应该有）：
  叶子组件的 props 渲染
  边界情况（空数据、超长文本）

低优先级（有时间再写）：
  正常路径下不太可能出问题的纯展示逻辑
```

---

## Mock 管理

### 用 mocktail，不用 mockito

`mocktail` 不需要代码生成，更适合小项目快速迭代：

```dart
import 'package:mocktail/mocktail.dart';

class MockDiaryRepository extends Mock implements DiaryRepository {}
class MockDiaryDao extends Mock implements DiaryDao {}
```

### Mock 放在哪里

```
test/
├── mocks/
│   ├── mock_diary_repository.dart
│   └── mock_diary_dao.dart
```

不要在每个测试文件里重复定义同一个 Mock 类。

---

## 文件目录

```
test/
├── fixtures/           测试数据
│   ├── diary_fixture.dart
│   └── tag_fixture.dart
├── mocks/              Mock 类定义
│   └── mock_repository.dart
├── unit/               单元测试，目录结构镜像 lib/
│   ├── data/
│   │   └── repositories/
│   │       └── diary_repository_test.dart
│   └── providers/
│       └── diary_list_notifier_test.dart
├── widget/             Widget 测试，目录结构镜像 lib/features/
│   └── home/
│       ├── timeline_card_test.dart
│       └── home_timeline_test.dart
└── integration/        集成测试，按用户链路命名
    ├── diary_creation_test.dart
    └── timeline_filter_test.dart
```

---

## 维护规则

```
新增功能        -> 同步写测试，不留"TODO: 补测试"
修改行为        -> 先更新测试（让测试失败），再修改实现（让测试通过）
删除功能        -> 删除对应测试
发现未覆盖的 bug -> 先写失败测试，再修复
测试失败        -> 不允许跳过（skip）失败的测试来继续开发，必须先修
```

`skip` 是测试债务的起点。一旦开始 skip 测试，以后没人会回来修它。
