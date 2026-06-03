# Flutter 项目目录结构规范

> 目录结构是代码的地图。地图的作用不是告诉你每条路怎么走，而是让你在不熟悉的地方快速找到方向。

---

## 顶层结构

本文给的是长期维护 Flutter 项目的默认主线结构，不是所有项目必须一次性完整创建的固定模板。目录只在有真实职责时创建，不为了“看起来完整”提前创建空目录。

```
flutter_app/
├── lib/
│   ├── core/              跨 feature 的基础设施
│   ├── data/              跨 feature 的数据层
│   ├── features/          按功能域划分的业务代码
│   ├── shared/            跨 feature 复用的 UI 组件
│   └── main.dart          应用入口
├── test/
│   ├── fixtures/
│   ├── mocks/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── assets/
│   ├── images/
│   └── fonts/
├── docs/                  项目文档放这里
└── pubspec.yaml
```

标准主线下，`lib/` 只保留四类顶级目录：`core`、`data`、`features`、`shared`。如果项目规模较小，可以按下面的裁剪规则少建目录；但不要把业务文件直接散放在 `lib/` 根目录，也不要创建 `utils/`、`helpers/`、`common/` 这类名称模糊的目录。

---

## 默认主线与可枚举分支

目录结构的核心不是“必须长这样”，而是让职责和依赖方向稳定。新项目先判断自己属于哪种分支，再决定创建哪些目录。

### 默认主线：长期维护的分层项目

适用条件：

```
有多个页面或 feature
有本地数据库或远程 API
有明确状态管理
预计会长期维护
需要文档和测试同步演进
```

使用完整主线：

```
lib/
├── core/
├── data/
├── features/
├── shared/
└── main.dart
```

### 分支 A：小型工具或原型项目

适用条件：单页面或少量页面，没有复杂数据层，主要目标是快速验证。

可以裁剪为：

```
lib/
├── features/
│   └── main/
└── main.dart
```

后续出现路由、主题、错误处理等跨 feature 基础设施时，再补 `core/`。

### 分支 B：暂无持久化或远程数据

适用条件：数据来自内存状态、简单配置或静态资源，没有 Repository / DataSource。

可以暂时不创建 `lib/data/`。当出现本地数据库、远程 API、缓存策略或模型转换时，再引入 `data/`。

### 分支 C：暂无跨 feature 复用组件

适用条件：组件只在单个 feature 内使用。

可以暂时不创建 `lib/shared/`。当同一个 Widget 被第二个 feature 使用时，再移动到 `shared/widgets/`。

### 分支 D：文档沉淀刚开始

适用条件：项目刚启动，还没有功能 Slice 或组件架构文档。

`docs/` 可以先只保留：

```
docs/
├── README.md
└── tech-decisions/
    └── tech-decision.md
```

当开始写功能设计时再创建 `slices/`；当开始写页面组件架构文档时再创建 `architecture/pages/`。

### 不可裁剪的规则

无论选择哪种分支，以下规则不能裁剪：

```
业务代码不要直接堆在 lib/ 根目录
UI 不直接访问数据库、API 或底层 DataSource
core/ 不依赖 features/
跨 feature 复用代码不能藏在某个 feature 下面
文档结构一旦开始使用，就要和代码变更同步维护
```

---

## docs/ — 项目文档目录

`docs/` 放的是具体项目自己的决策、设计和验收文档，不是方法论规范的复制品。

方法论规范负责“怎么写”，项目文档负责“这个项目实际决定了什么”。标准主线下，项目文档推荐使用以下结构：

```
docs/
├── README.md
├── tech-decisions/
│   └── tech-decision.md
├── slices/
│   ├── features/
│   ├── design-principles/
│   └── verification/
└── architecture/
    └── pages/
```

各目录职责：

```
README.md             项目文档入口，说明当前项目有哪些文档、从哪里开始读
tech-decisions/       阶段 0 技术选型记录，由 Tech Decision 模板派生
slices/features/      功能 Slice，描述产品功能、交互、状态和验收条件
slices/design-principles/ 设计原则 Slice，描述跨功能语义边界和关系
slices/verification/  验证 Slice，描述跨 Slice 的验收链路和一致性检查
architecture/pages/   页面级组件架构文档，对应组件架构文档写作规范
```

0-1 早期不要提前创建没有使用场景的目录。CI、发布、线上问题回流、性能基线等文档，等触发条件成立后再补。

---

## core/ — 基础设施

`core/` 放的是和业务无关、但整个项目都需要的基础设施。判断标准：如果把这个文件复制到另一个 Flutter 项目，不需要任何修改就能用，它就属于 `core/`。

```
lib/core/
├── errors/
│   ├── app_error.dart          业务异常类定义
│   └── error_handler.dart      全局错误处理逻辑
├── router/
│   ├── app_router.dart         GoRouter 配置入口
│   └── routes.dart             路由名称常量
├── theme/
│   ├── app_theme.dart          ThemeData 配置
│   ├── app_colors.dart         颜色常量
│   ├── app_spacing.dart        间距常量
│   └── app_text_styles.dart    文字样式
├── extensions/
│   ├── datetime_ext.dart       DateTime 扩展方法
│   └── string_ext.dart         String 扩展方法
└── providers/
    └── core_providers.dart     核心基础 Provider（如当前用户、设备信息）
```

`core/` 里的文件不能 import `features/` 里的任何文件。依赖只能是单向的：`features/` 依赖 `core/`，反过来不行。

---

## features/ — 业务功能域

`features/` 按产品功能域划分，每个子目录对应一个 Slice 或一组相关 Slice。

```
lib/features/
├── list/
├── item_editor/
├── settings/
└── onboarding/
```

### 每个 feature 的内部结构

```
lib/features/list/
├── screens/
│   └── list_screen.dart
├── widgets/
│   ├── index_section.dart
│   ├── item_list_section.dart
│   ├── category_filter_bar.dart
│   ├── item_card.dart
│   └── category_chip.dart
├── providers/
│   ├── item_list_notifier.dart
│   └── category_filter_notifier.dart
└── list_providers.dart         这个 feature 的 Provider 对外暴露点（可选）
```

三个子目录分别对应页面、组件和 Provider；如果这个 feature 需要统一对外暴露 Provider，可以额外保留一个 `{feature}_providers.dart` 文件：

```
screens/     页面层，对应路由
widgets/     容器层和叶子层都放这里，用命名区分
providers/   这个 feature 的 Notifier 和 Provider
{feature}_providers.dart  Provider 对外暴露点（可选文件，不是子目录）
```

### feature 之间的依赖规则

```
feature A 的 Widget  不能 import  feature B 的 Widget
feature A 的 Provider 可以 watch  feature B 的 Provider（通过接口）
```

如果两个 feature 的 Widget 需要共享某个组件，把那个组件移到 `shared/widgets/`，不要跨 feature 直接 import。

---

## features/ 之外的数据层

数据层不属于某个单一 feature，放在 `features/` 之外单独管理。

```
lib/
├── data/
│   ├── models/
│   │   ├── domain/
│   │   │   ├── item.dart
│   │   │   └── category.dart
│   │   ├── entities/
│   │   │   ├── item_entity.dart
│   │   │   └── category_entity.dart
│   │   └── dtos/              如果有网络层
│   ├── repositories/
│   │   ├── item_repository.dart        接口
│   │   └── impl/
│   │       └── item_repository_impl.dart
│   └── local/
│       ├── app_database.dart
│       ├── tables/
│       │   ├── item_table.dart
│       │   └── category_table.dart
│       └── daos/
│           ├── item_dao.dart
│           └── category_dao.dart
```

数据层的文件只被 `features/` 里的 Provider 引用，不被 Widget 直接引用。

---

## shared/ — 跨 feature 的 UI 组件

```
lib/shared/
└── widgets/
    ├── empty_state.dart
    ├── error_view.dart
    ├── loading_skeleton.dart
    └── avatar.dart
```

进入 `shared/widgets/` 的门槛只有一条：这个组件被两个或更多 feature 使用。只被一个 feature 用的组件放在那个 feature 的 `widgets/` 目录下，不要提前移到 `shared/`。

`shared/` 里的组件不能 import `features/` 的代码，不能 watch 业务 Provider。

---

## 文件命名规则

所有文件名用 snake_case，和 Dart 规范一致。

```
类型            命名模式                    示例
Screen          {name}_screen.dart          list_screen.dart
Widget（容器）   {name}_{type}.dart          item_list_section.dart
Widget（叶子）   {name}_{type}.dart          item_card.dart
Notifier        {name}_notifier.dart        item_list_notifier.dart
Repository接口   {name}_repository.dart      item_repository.dart
Repository实现   {name}_repository_impl.dart item_repository_impl.dart
DAO             {name}_dao.dart             item_dao.dart
Table           {name}_table.dart           item_table.dart
Domain Model    {name}.dart                 item.dart
Entity          {name}_entity.dart          item_entity.dart
DTO             {name}_dto.dart             item_dto.dart
扩展方法         {type}_ext.dart             datetime_ext.dart
```

命名用领域语言，不用技术后缀堆叠。`item.dart` 比 `item_model.dart` 好，`item_entity.dart` 用 `_entity` 后缀是因为需要和 `item.dart`（Domain Model）区分。

---

## 禁止创建的目录

```
utils/          太宽泛，不知道放什么，最终变成垃圾桶
helpers/        同上
common/         同上
base/           抽象基类不需要单独目录，放在对应层级的目录里
models/         放在 data/models/ 下，不要在顶层建
```

如果发现自己在创建这些目录，停下来，重新想这个文件属于哪个 feature 或哪个层级。

---

## 完整目录示例

```
lib/
├── core/
│   ├── errors/
│   │   └── app_error.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   └── routes.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   ├── app_spacing.dart
│   │   └── app_text_styles.dart
│   └── extensions/
│       └── datetime_ext.dart
├── data/
│   ├── models/
│   │   ├── domain/
│   │   │   ├── item.dart
│   │   │   └── category.dart
│   │   └── entities/
│   │       ├── item_entity.dart
│   │       └── category_entity.dart
│   ├── repositories/
│   │   ├── item_repository.dart
│   │   └── impl/
│   │       └── item_repository_impl.dart
│   └── local/
│       ├── app_database.dart
│       ├── tables/
│       │   └── item_table.dart
│       └── daos/
│           └── item_dao.dart
├── features/
│   ├── list/
│   │   ├── screens/
│   │   │   └── list_screen.dart
│   │   ├── widgets/
│   │   │   ├── index_section.dart
│   │   │   ├── item_list_section.dart
│   │   │   ├── category_filter_bar.dart
│   │   │   ├── item_card.dart
│   │   │   └── category_chip.dart
│   │   └── providers/
│   │       ├── item_list_notifier.dart
│   │       └── category_filter_notifier.dart
│   └── item_editor/
│       ├── screens/
│       │   └── item_editor_screen.dart
│       ├── widgets/
│       │   └── content_input.dart
│       └── providers/
│           └── item_editor_notifier.dart
├── shared/
│   └── widgets/
│       ├── empty_state.dart
│       └── error_view.dart
└── main.dart
```

---

## 维护规则

```
新增 feature      在 features/ 下建对应目录，按标准结构初始化
Widget 被第二个 feature 引用  立即移到 shared/widgets/，更新两处 import
发现 utils/ 目录  把里面的文件归类到正确位置，删除 utils/ 目录
文件命名不符合规范  在同次 PR 里重命名，不要攒着
```
