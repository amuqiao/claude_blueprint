# Flutter 数据层设计规范

> 数据层是 UI 和存储之间的合约。合约写清楚了，UI 层不需要知道数据从哪来；合约模糊了，UI 层会开始做数据层的事。

---

## 数据层的边界

数据层由三部分组成，每一层只和相邻层通信：

```
UI 层（Widget / Provider）
      ↕  只通过 Repository 接口通信
Repository 层（接口 + 实现）
      ↕  只通过 DataSource 接口通信
DataSource 层（本地 / 远程）
```

Repository 是 UI 层和存储层之间的缓冲。UI 层不知道数据是从 Drift 来的还是从 API 来的，Repository 决定从哪里取、什么时候缓存、什么时候过期。

---

## 数据模型

### 三种模型，三个用途

```
Entity        数据库存储模型，和表结构对应，由 Drift 生成或手写
DTO           网络传输模型，和 API 响应结构对应，只做 JSON 序列化
Domain Model  业务模型，UI 层使用，和产品概念对应
```

不要让同一个类同时承担多个角色。一个既负责 JSON 解析又被 Widget 直接使用的类，迟早会因为 API 字段变更导致 UI 层改动。

### 转换方向

```
DTO -> Domain Model     在 Repository 里转换，UI 层只见 Domain Model
Entity -> Domain Model  在 Repository 里转换，UI 层只见 Domain Model
```

转换逻辑写在 Repository 里，不写在模型类的构造函数里。构造函数不做业务逻辑。

### 命名约定

```
Entity        {Name}Entity      DiaryEntity, TagEntity
DTO           {Name}DTO         DiaryDTO, UserProfileDTO
Domain Model  直接用领域名称    Diary, Tag, UserProfile
```

Domain Model 用最简单的名字，因为它是 UI 层最常见到的类型，越简洁越好。

### Domain Model 的写法

Domain Model 用 `@freezed` 或手写不可变类。不可变是强制要求，可变的 Domain Model 会导致 Provider 无法可靠地触发 rebuild。

```dart
// 正确：不可变
@freezed
class Diary with _$Diary {
  const factory Diary({
    required String id,
    required String content,
    required DateTime createdAt,
    required List<Tag> tags,
  }) = _Diary;
}

// 错误：可变字段
class Diary {
  String id;
  String content;  // 可变，会导致 Provider watch 失效
}
```

---

## Repository

### 接口和实现分离

每个 Repository 必须有接口和实现两个文件：

```
lib/data/repositories/
├── diary_repository.dart          接口
└── impl/
    └── diary_repository_impl.dart 实现
```

接口只写方法签名，不写实现逻辑。实现类不对外暴露，只通过接口使用。

```dart
// 接口
abstract class DiaryRepository {
  Future<List<Diary>> fetchByDateRange(DateTime start, DateTime end);
  Future<Diary> fetchById(String id);
  Future<void> save(Diary diary);
  Future<void> delete(String id);
  Stream<List<Diary>> watchAll();
}
```

### 方法命名约定

```
fetch{Name}       单次读取，返回 Future
watch{Name}       持续监听，返回 Stream
save              新建或更新（upsert 语义）
delete            删除
```

不要用 `get`、`load`、`retrieve`，这些词含义模糊。`fetch` 明确表示"去取一次"，`watch` 明确表示"持续监听"。

### Repository 不做的事

```
不持有 UI 状态（loading, selected, expanded 等）
不直接被 Widget 调用    -> Widget 只通过 Provider/Notifier 访问 Repository
不处理导航              -> 路由逻辑在 UI 层
不格式化展示数据        -> 日期格式化、文本截断在 UI 层
```

Repository 的职责是数据的 CRUD 和缓存策略，仅此而已。

---

## Provider / Notifier

### 命名约定

```
AsyncNotifier     {Name}ListNotifier   DiaryListNotifier
Notifier          {Name}Notifier       TagFilterNotifier
Provider          {name}Provider       currentUserProvider
```

### 状态类型选择

```
AsyncNotifier    管理需要异步加载的列表或详情数据
Notifier         管理纯 UI 状态（筛选条件、选中项、展开收起）
StateProvider    管理简单的单值状态（当前 tab 索引等）
```

不要用 `AsyncNotifier` 管理纯 UI 状态，也不要用 `StateProvider` 管理复杂的业务状态。选错类型会导致 rebuild 粒度不对，要么刷新太多，要么刷新不够。

### AsyncNotifier 的标准结构

```dart
@riverpod
class DiaryListNotifier extends _$DiaryListNotifier {
  @override
  Future<List<Diary>> build() async {
    // build 只做初始加载
    return _fetch();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<Diary>> _fetch() {
    final filter = ref.watch(tagFilterNotifierProvider);
    return ref.read(diaryRepositoryProvider).fetchByDateRange(
      filter.startDate,
      filter.endDate,
    );
  }
}
```

`build` 方法只做初始加载。刷新、重试等操作写成独立方法，不要在 `build` 里加分支处理。

### 依赖关系

Notifier 之间的依赖通过 `ref.watch` 声明，不要通过构造函数传入，也不要通过全局变量访问。

```dart
// 正确：通过 ref.watch 声明依赖
final filter = ref.watch(tagFilterNotifierProvider);

// 错误：通过构造函数注入
class DiaryListNotifier extends _$DiaryListNotifier {
  DiaryListNotifier(this._filter);  // 不要这样做
  final TagFilter _filter;
}
```

---

## 错误处理

### 错误分层

```
DataSource 层    抛出原始异常（SqliteException, DioException 等）
Repository 层    捕获原始异常，转换为业务异常
Notifier 层      用 AsyncValue.guard 捕获，暴露给 UI
UI 层            根据 AsyncValue.error 展示对应提示
```

`AppError` 及其子类的完整定义在 **Flutter-错误处理规范** 里，本文不重复。数据层只需要知道以下使用约定：

```
Repository 捕获 SqliteException / DioException，throw 对应的 AppError 子类
UI 层只处理 AppError 的子类，平台原始异常不应出现在 UI 层
```

如果 UI 层出现了 `SqliteException` 或 `DioException`，说明 Repository 层没有做好转换。

### 什么时候 throw，什么时候 return null

```
数据不存在（查询结果为空）   -> return null 或 return []，不 throw
操作失败（写入失败、网络断开）-> throw AppError，让上层决定如何处理
```

不要用异常表示"没有数据"，这会让调用方必须用 try-catch 处理正常的空结果。

---

## 本地数据库（Drift）

### 文件结构

```
lib/data/local/
├── app_database.dart       数据库入口，@DriftDatabase 注解
├── tables/
│   ├── diary_table.dart    表定义
│   └── tag_table.dart
└── daos/
    ├── diary_dao.dart      数据访问对象
    └── tag_dao.dart
```

### DAO 的职责

DAO 只做 SQL 操作，不做业务逻辑。DAO 的方法返回 Entity，不返回 Domain Model。转换在 Repository 里做。

```dart
// 正确：DAO 返回 Entity
Future<List<DiaryEntity>> getByDateRange(DateTime start, DateTime end);

// 错误：DAO 返回 Domain Model（绕过了 Repository 的转换职责）
Future<List<Diary>> getByDateRange(DateTime start, DateTime end);
```

### Migration

每次改表结构必须写 migration，不要用 `destroyEverythingAndMigrate`（即使在开发阶段）。养成写 migration 的习惯，否则上线后第一次改表就会出问题。

```dart
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.addColumn(diaryTable, diaryTable.mood);
    }
  },
);
```

---

## 文件目录

```
lib/
├── data/
│   ├── models/
│   │   ├── domain/         Domain Model（Diary, Tag 等）
│   │   ├── entities/       数据库 Entity
│   │   └── dtos/           网络 DTO
│   ├── repositories/
│   │   ├── diary_repository.dart
│   │   └── impl/
│   │       └── diary_repository_impl.dart
│   ├── local/
│   │   ├── app_database.dart
│   │   ├── tables/
│   │   └── daos/
│   └── remote/             如果有网络层
│       ├── api_client.dart
│       └── endpoints/
└── features/
    └── home/
        └── providers/      Notifier 放在各自的 feature 目录下
            ├── diary_list_notifier.dart
            └── tag_filter_notifier.dart
```

Notifier 文件的完整目录组织见 **Flutter-项目目录结构规范**，`providers/` 属于各 feature 内部，不放在 `lib/` 顶层。

---

## 维护规则

```
产品状态新增        -> 先更新 Domain Model，再更新 Repository 接口，最后更新 Notifier
表结构变更          -> 必须写 migration，同步更新 Entity 和 Repository 实现
Repository 接口变更  -> 检查所有调用方（Notifier），全部同步更新，不留废弃方法
```

数据层的变更影响面最大，改之前先确认所有上游（Notifier）和下游（DataSource）都清楚这次改动的范围。
