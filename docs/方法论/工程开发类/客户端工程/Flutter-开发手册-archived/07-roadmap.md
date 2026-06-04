# 架构演进指南
> 本文回答：当项目从小增长到大时，如何判断何时重构、重构什么、用什么方式。
> 
> **前置阅读**：[02-architecture.md](02-architecture.md)（分层架构）和 [00-startup.md](00-startup.md)（项目骨架）。
> 
> **不解决**：具体重构的代码实现，那属于 [02-architecture.md](02-architecture.md) 和 [05-vibe-coding.md](05-vibe-coding.md) 的范畴；也不涉及运维侧的大规模基础设施问题。

---

## 一、演进全景图

Flutter 项目的规模演进分三个阶段，每个阶段有不同的架构关注点。

### 起步期（1-5 个 feature）

**特征**：
- 所有代码集中在一个项目目录中
- data 和 domain 层可能只在 entries 一个 feature 中完整定义
- 其他 feature 直接消费 entries 的 providers
- core 层很薄，基本是 database + theme + 几个通用工具

**代码体积**：2,000-5,000 行 Dart

**健康信号**：
- ✓ Feature 之间有清晰的边界（按 feature 目录分离）
- ✓ Drift 表定义集中在 core/database/
- ✓ 新增 feature 时，能复用已有的 patterns（Repository + Provider + ConsumerWidget）
- ✓ 单个 feature 内的文件数不超过 30 个

**警告信号**：
- ⚠️ Feature 之间有循环依赖（feature A import 了 feature B，B 又 import A）
- ⚠️ 有公共逻辑散落在多个 feature 中重复出现
- ⚠️ Provider 层开始出现"胶水代码"：为了连接不同 feature 的 providers，加了中间层 Provider
- ⚠️ Drift schema 文件变得很长（超过 300 行），多个无关的表混在一起

**进入增长期的信号**：项目 feature 达到 5 个，或 core 层和 features 的代码行数接近 1:1

---

### 增长期（5-15 个 feature）

**特征**：
- 功能模块趋于稳定，业务领域的边界逐渐清晰
- 多个 feature 共享数据（需要跨 feature 的 domain 模型）
- core 层代码快速增长（更多通用 widget、工具、主题管理）
- Drift 表结构复杂，多个 feature 依赖同一张表

**代码体积**：5,000-20,000 行 Dart

**健康信号**：
- ✓ Feature 仍能独立测试，不依赖其他 feature（除了共享的 domain/data）
- ✓ 新 feature 开发周期稳定在 2-3 天内能跑通骨架
- ✓ build 时间在 30 秒以内

**警告信号与应对**：

| 警告现象 | 原因 | 应对方案 |
|---|---|---|
| 多个 feature 的 domain 模型很相似，代码重复 | 共享逻辑没有沉淀到 core | 新建 `core/domain/` 或 `core/models/`，定义共享的 domain 基类或 mixin |
| Provider 依赖链很深（A 依赖 B 依赖 C 依赖...） | 架构没有清晰分层 | 梳理依赖关系，用中间 Provider 或 `@riverpod` 注解简化链条 |
| Drift 表数量很多（20+ 张），操作变复杂 | 数据库 schema 没有归类 | 考虑按业务模块分组，用注释标记表的从属关系 |
| core/presentation 里的 widget 越来越多 | 通用组件和特定页面组件混在一起 | 在 core/presentation 内部按功能分子目录（如 `core/presentation/common` / `forms` / `layouts`） |
| 同一个 feature 内的文件超过 50 个 | 单个 feature 承载了太多职责 | 考虑把该 feature 拆成两个相关的 feature（如 entries 可拆成 entries 和 tags） |
| 新增依赖时，经常遇到版本冲突 | 依赖层级太深，版本约束互相制约 | 梳理 pubspec.yaml，移除不必要的依赖，或升级到最新稳定版本统一约束 |

**何时进入规模期**：feature 达到 15 个，或代码行数接近 30,000 行

---

### 规模期（15+ 个 feature）

**特征**：
- 业务复杂，feature 数量多，单个开发者难以全盘掌控
- 多个开发者并行开发，merge conflict 频繁
- 编译和测试时间变长
- 状态管理复杂，跨 feature 的数据流多

**代码体积**：20,000+ 行 Dart

**关键关注点**：

| 维度 | 规模期的挑战 | 改善方向 |
|---|---|---|
| **编译速度** | build 时间可能 1-3 分钟 | 考虑把部分 feature 变成可选的编译目标，或分离 debug/release build 配置 |
| **团队协作** | 频繁的代码冲突和 merge 成本高 | 建立清晰的 API 契约（用 sealed class 和接口隔离实现），减少跨 feature 直接依赖 |
| **状态管理** | Provider 图复杂，debug 困难 | 考虑引入中间层 event bus 或 CQRS 模式，降低耦合 |
| **Drift Schema** | 单个 database 文件太大（1000+ 行） | 按业务域拆分 database，每个域一个单独的 sqlite 文件（需要重新设计 appDatabaseProvider） |
| **测试覆盖** | 集成测试变得困难 | 重点保证核心链路的 integration test，其他用 unit / widget test |

**何时考虑架构重构**：
- 新 feature 开发周期变长（超过一周）
- 代码 review 因为理解困难而延期
- 线上问题频出，root cause 难以追踪
- 团队成员 onboard 时间变长（超过一周）

---

## 二、起步期健康检查

第一次搭完项目骨架后，检查以下 5 个指标，确保基础扎实。

### 检查 1：Feature 独立性

**目标**：除了依赖 core 层和共享的 domain/data（如 entries），feature 之间没有循环依赖。

**检查方法**：
```bash
grep -r "import.*features/.*" lib/features/[feature-name]/
```

如果输出包含指向其他 feature 的 import，说明有跨 feature 直接依赖，需要梳理抽象。

**修复方向**：
- 如果 feature A 和 B 共享逻辑，把逻辑提到 core 层
- 如果 A 需要用 B 的数据，通过共享的 Provider 而非直接 import

### 检查 2：Provider 依赖关系

**目标**：不出现"胶水 Provider"（只是为了连接其他两个 Provider）。

**表现**：
```dart
// ❌ 胶水 provider，没有实际逻辑
final glueProvider = Provider((ref) {
  final itemData = ref.watch(entriesProvider);
  final tagData = ref.watch(tagsProvider);
  return (itemData, tagData); // 纯粹的组合，没有业务逻辑
});

// ✓ 合理的组合 provider，有实际转换逻辑
final itemsWithTagsProvider = Provider((ref) {
  final items = ref.watch(itemsProvider);
  final tags = ref.watch(tagsProvider);
  return items.map((item) => item.withTagInfo(tags)).toList(); // 有实际逻辑
});
```

**修复**：如果大量胶水 provider，说明 UI 层的 build 逻辑过复杂，应该把组合逻辑推到 domain 或 data 层。

### 检查 3：core 层划分

**目标**：core 层内部清晰，不混乱。

**标准结构**：
```
core/
├── database/        ← 数据库定义和 provider（不变）
├── presentation/    ← 通用 UI widget
├── theme/           ← 主题和设计 token
├── time/            ← 时间工具（可选，其他工具同理）
└── models/ 或 domain/  ← 共享的数据模型（可选，5 个 feature 时开始需要）
```

如果 core 目录变得无序（文件直接堆在 core/ 下，没有子目录分类），需要重新组织。

### 检查 4：Drift Schema 单一性

**目标**：所有 Drift 表集中在一个 app_database.dart，且内部有注释分组。

**好的做法**：
```dart
@DriftDatabase(tables: [...])
class AppDatabase extends _$AppDatabase {
  // ...
}
```

在表定义部分用注释标记所属业务域：
```dart
// ─ Entry 相关表 ─
class EntryRows extends Table { ... }
class PhotoRows extends Table { ... }

// ─ Tag 相关表 ─
class TagRows extends Table { ... }
```

### 检查 5：Feature 开发时间

**目标**：从"开始新 feature"到"可以运行 demo"的时间稳定在 1-2 天。

**快速评估**：最近新增的 feature 从创建目录到第一次 hot reload 成功，花了多久？
- < 2 小时：骨架非常清晰，新手也能快速上手 ✓
- 2-4 小时：正常
- > 4 小时：说明骨架或文档不够清晰，需要调整

---

## 三、增长期操作指南

当 feature 数达到 5-7 个，开始执行以下优化。

### Step 1：建立共享 Domain Model 层

**何时做**：多个 feature 有相似的数据模型（如 Entry、Tag、Category）。

**方案**：新建 `lib/core/domain/` 或 `lib/core/models/`：

```
core/
├── database/
├── domain/           ← 新建
│   ├── entry.dart        ← 共享的业务模型
│   ├── tag.dart
│   ├── filter.dart       ← 跨 feature 的筛选条件
│   └── common.dart       ← 通用值对象（ID、枚举等）
├── presentation/
└── theme/
```

所有 feature 的 domain model 都基于这里的基类或接口，减少重复。

### Step 2：抽象 Repository 接口

**何时做**：准备支持多个数据源（本地 Drift + 网络 API）或想让 feature 更解耦。

**方案**：
```dart
// core/data/repositories.dart
abstract class ItemRepository {
  Stream<List<Item>> watchItems();
  Future<void> createItem(Item item);
}

// features/entries/data/drift_item_repository.dart
class DriftItemRepository implements ItemRepository { ... }

// 未来可加：
// class ApiItemRepository implements ItemRepository { ... }
```

Provider 注入 Repository 接口而非具体实现，便于切换。

### Step 3：core/presentation 内部分类

**何时做**：core/presentation 的 widget 数超过 5 个。

**方案**：
```
core/presentation/
├── common/           ← 通用 widget（Card、Header、Footer）
├── forms/            ← 表单相关（TextField wrapper、validation）
├── dialogs/          ← 对话框、modal（确认、选择）
├── layouts/          ← 页面布局框架
└── shared_widgets.dart ← 简单组件可直接放这里
```

### Step 4：Drift Schema 梳理与注释

**何时做**：Drift 表数超过 10 张，或表间关系变复杂。

**方案**：
```dart
// core/database/app_database.dart

// ========== Entry 域 ==========
// Entry: 日记条目本体
// Photo: Entry 关联的图片
@DataClassName('EntryRow')
class EntryRows extends Table { ... }

@DataClassName('PhotoRow')
class PhotoRows extends Table { ... }

// ========== Tag 域 ==========
@DataClassName('TagRow')
class TagRows extends Table { ... }

// ========== Relations ==========
// Entry.tagId -> TagRows.id（外键关系标记）
```

---

## 四、常见问题与应对

| 问题 | 出现阶段 | 根因 | 解决方向 |
|---|---|---|---|
| **Feature 之间代码重复多** | 起步期 → 增长期 | 共享逻辑没有沉淀 | 梳理 core 层，建立共享 domain/utils |
| **Provider 依赖链太深** | 增长期 | 没有中间层整合 | 引入中间 Provider 或简化 build 逻辑，用 @riverpod 注解 |
| **Merge conflict 频繁** | 增长期 | 多人编辑同一文件（pubspec.yaml、router.dart、database.dart） | 建立 feature 分支策略，分离 route/database 定义，用 router_builder 代码生成 |
| **Build 时间变长** | 增长期 → 规模期 | 依赖增多，代码生成时间累积 | 优化 pubspec.yaml 依赖，分离 dev/build 配置 |
| **状态管理调试困难** | 增长期 → 规模期 | Provider 图复杂，难以追踪数据流 | 用 Riverpod DevTools，简化 Provider 依赖，考虑中间层 event bus |
| **新人 onboard 时间长** | 规模期 | 项目大，文档不足 | 补充文档（如本手册），建立 onboard checklist，安排 code review 指导 |

---

## 五、重构时的关键原则

当决定重构某个部分时，遵循以下原则：

### 5.1 最小化影响面

**原则**：重构应该是局部的，不应该要求全项目"齐步走"改代码。

**例**：
- ✓ 拆分单个 feature：只影响该 feature 的文件
- ✓ 提升 core 工具：新工具不强制替换旧逻辑，可共存
- ❌ 要求所有 Provider 改用 @riverpod 注解：影响所有 feature

### 5.2 保留向后兼容性

**原则**：新旧方案要能并存至少一个迭代，给人时间迁移。

**例**：
```dart
// 旧写法仍然可用（marked as @deprecated）
@deprecated
final oldItemsProvider = StreamProvider(...);

// 新写法
@riverpod
Stream<List<Item>> items(ItemsRef ref) { ... }
```

### 5.3 通过测试验证安全

**原则**：重构前应该有测试覆盖，重构后测试仍应通过。

如果没有测试，重构前先补充 unit test，再进行重构。

---

## 延伸阅读

| 话题 | 文档 |
|---|---|
| 具体的架构分层实现 | [02-architecture.md](02-architecture.md) |
| Provider 选型和状态管理决策 | [03-stack.md](03-stack.md) |
| 设计规范和交互约束 | [04-standards.md](04-standards.md) |
| 编码实现细节 | [05-vibe-coding.md](05-vibe-coding.md) |

---

*版本：Flutter 3.x · Riverpod 3.x · 2026*
