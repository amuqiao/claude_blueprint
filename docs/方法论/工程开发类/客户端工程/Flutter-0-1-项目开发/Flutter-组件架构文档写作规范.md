# Flutter 组件架构文档写作规范

> 组件架构文档不是代码的文字版，而是在写代码之前，把组件边界、职责归属和状态流向锁定成可以对齐的共识。

---

## 什么是组件架构文档

组件架构文档是阶段 2 的交付物。它的读者是"要写这个页面的人"，目的只有一个：让写代码的人在动手之前就知道该拆几个组件、每个组件负责什么、状态从哪里来。

一份合格的组件架构文档应该能直接回答四个问题：

```
这个页面拆成哪些组件？
每个组件的输入和输出边界在哪里？
状态在哪里产生、流向哪里？
数据、交互、绘制三类职责分别由谁承担？
```

如果一份文档回答不了这四个问题，它还不是组件架构文档，只是页面草图。

---

## 和 Slice 的关系

组件架构文档是 Slice 的下游。Slice 描述产品要什么，组件架构文档描述代码怎么切。

```
Slice           描述用户体验、状态、验收条件    不涉及 Widget
组件架构文档    描述 Widget 树、职责边界、状态流向   不涉及实现细节
代码            实现                              不重复文档里已决定的事
```

Slice 里出现的每一个产品状态，在组件架构文档里都应该能找到对应的"这个状态由谁拥有、谁读取"。如果找不到，说明组件架构文档还没写完。

---

## 文档结构

```
Page Overview      这个页面是什么，对应哪份 Slice
Component Tree     完整的组件层级，含职责说明
Responsibility Split  数据、交互、绘制三类职责归属
State Ownership    每个状态由谁拥有，谁读，谁写
Data Flow          数据从 Repository 到 UI 的完整路径
Boundary Rules     哪些事情跨组件不能做
Open Questions     尚未决定的事项，不要用猜测填充
```

---

## Component Tree

### 写法

用缩进表示层级，每个组件后面紧跟一句话职责说明。职责说明只写这个组件"负责什么"，不写"怎么实现"。

```
ListScreen                        页面入口，组装所有 section，持有页面级导航逻辑
├── IndexSection                索引区域，展示年度状态分布，处理日期点选事件
│   └── IndexCell               单个日期格子，展示颜色深度，触发点选回调
├── CategoryFilterBar                  分类筛选栏，展示可选分类列表，持有当前选中状态
│   └── CategoryChip                   单个分类，展示选中/未选中状态，触发切换回调
└── ItemListSection                  列表容器，按天分组展示记录列表，响应定位指令
    ├── DayGroup                  单天分组，展示日期标题和当天的记录列表
    │   └── ItemCard          单条记录卡片，展示摘要信息，触发详情跳转
    └── EmptyState                空状态占位，当筛选结果为空时展示
```

### 三个层级的命名约定

```
Screen     页面级，对应一个路由，持有页面生命周期
Section    功能区块，对应一个产品功能区域
Card / Cell / Chip   叶子组件，只接收数据，通过回调向上通知
```

命名用 PascalCase，不要缩写。`IndexCell` 比 `ICell` 好，三个月后你还认识前者。

---

## Responsibility Split

组件架构文档必须显式写清楚三类职责的归属。这里的“三类职责”是概念分类，不是三个完全平行的目录或文件。

```text
数据/业务状态  -> Controller / Notifier / Provider，通常不是 Widget
交互逻辑       -> StatefulWidget / ConsumerStatefulWidget，持有局部交互状态
视觉呈现       -> StatelessWidget / ConsumerWidget，接收数据并绘制
```

这个规则来自时间轴日记组件分析里的核心判断：[时间轴日记组件设计分析](../references/时间轴日记组件设计分析.md)。

写法示例：

```text
HomeController
  职责重心：数据/业务状态
  负责：当前筛选、时间锚点、可见数据
  不负责：滚动定位、气泡样式

HomeTimelineViewport
  职责重心：交互逻辑
  负责：ScrollController、滚动定位、用户滚动反馈
  注意：它是 StatefulWidget，必须通过 build() 渲染自己的子树，但主要变化原因仍然是交互规则

TimelineBubble
  职责重心：视觉呈现
  负责：气泡形态、颜色 token、图片网格、文本排版
  不负责：筛选状态、滚动位置、数据查询
```

判断归属时不要机械看“有没有 `build()`”。Flutter 里的交互组件通常也必须渲染自己，关键要看这个类的主要变化原因：数据规则变化、交互规则变化，还是视觉样式变化。

### 什么时候拆，什么时候不拆

拆的判断依据只有两条：

```
1. 这个部分有独立的状态生命周期   -> 拆
2. 这个部分会在多个地方复用      -> 拆
```

只是"看起来比较复杂"不是拆的理由。组件数量越少，状态流向越清晰。

---

## State Ownership

### 写法

列出 Slice 里出现的所有产品状态，逐一说明归属。

```
状态                    Owner               读取方              写入触发
当前选中的分类列表       CategoryFilterBar        ItemListSection        CategoryChip 点击
索引点选的目标日期     ListScreen          ItemListSection        IndexCell 点击
列表滚动位置          ItemListSection（内部）  ItemListSection        系统 / 定位指令
记录列表数据            ItemListProvider   ItemListSection        Repository 返回
```

### 三条规则

**状态尽量下沉。** 一个状态如果只被一个组件用到，就放在那个组件里，不要提升到父级。提升是有代价的，每一次提升都意味着父组件要多了解子组件的内部事务。

**共享状态只提升到最近公共祖先。** 如果 A 和 B 都要读同一个状态，提升到 A 和 B 的最近公共父节点，而不是提升到页面根节点。

**Provider 不是垃圾桶。** 不要因为"以后可能会用到"就把状态放进 Provider。没有明确使用方的状态不应该进 Provider。

---

## Data Flow

### 写法

从数据源出发，按层级写清楚数据经过哪些节点到达 UI。

```
ItemRepository
  └── fetchByDateRange(start, end) -> List<Item>
        └── ItemListNotifier（Riverpod AsyncNotifier）
              ├── 监听 selectedCategories 变化，触发重新 fetch
              └── 暴露 AsyncValue<List<Item>>
                    └── ItemListSection
                          └── DayGroup（按日期分组后传入）
                                └── ItemCard（单条记录）
```

### 错误状态要写进来

Data Flow 必须包含 loading / error / empty 三种非正常状态由谁处理：

```
AsyncValue.loading   -> ItemListSection 展示 skeleton
AsyncValue.error     -> ItemListSection 展示错误提示，提供重试入口
AsyncValue.data([])  -> EmptyState 组件，区分"真空"和"筛选为空"两种文案
```

如果没有写错误状态的归属，开发时大概率会出现"错误状态随便处理"或者多个组件都在处理同一个错误的情况。

---

## Boundary Rules

这一节写的是"哪些事情禁止跨组件做"。负面约束比正面描述更重要，因为违反约束的代码往往不会在 code review 时被发现，只会在三个月后引发莫名 bug。

常见的边界规则：

```
Controller / Notifier 不 import Flutter UI，不调用 BuildContext
  -> 数据层完全独立，不能反向依赖 Widget 树

交互型 StatefulWidget 不直接做业务查询
  -> 交互层可以管理 ScrollController、AnimationController、FocusNode，不直接调用 Repository

叶子组件（Card / Cell / Chip）不直接读取 Provider
  -> 所有数据通过父组件传入，叶子只持有 UI 逻辑

叶子组件不持有业务状态
  -> 选中状态、加载状态由父组件或 Provider 持有，叶子只反映，不决定

Section 组件不直接调用 Repository
  -> 数据操作只通过 Provider/Notifier 进行，Section 只和 Provider 通信

页面组件（Screen）不持有列表数据
  -> Screen 只负责组装，数据在对应 Provider 里，Screen 通过 ref.watch 取
```

每个项目可以根据实际情况增减，但必须在这里写明，不能靠口头约定。

---

## Open Questions

写文档时遇到的未决问题放在这里，不要用猜测填充文档正文。

格式：

```
[ ] 问题描述
    背景：为什么这是个问题
    待决定：需要谁来决定，或者等什么条件解决
```

示例：

```
[ ] ItemCard 的图片是懒加载还是预加载？
    背景：列表可能有大量图片，预加载影响内存，懒加载影响滚动体验
    待决定：等性能测试数据，由负责性能的人决定
```

Open Questions 不是缺陷，是诚实。文档里有未决问题比文档里有错误的假设要好得多。

---

## 文件命名和目录

```
architecture/
├── list-screen.md
├── item-editor-screen.md
└── settings-screen.md
```

命名规则：用页面名，`{screen-name}-screen.md`。

---

## 维护规则

```
Slice 的产品状态变了    -> 先更新组件架构文档的 State Ownership，再改代码
组件拆分方式变了        -> 更新 Component Tree，同步 Boundary Rules 是否受影响
新增组件               -> 在 Component Tree 里加入，明确职责说明，不留空白
```

不要在代码里做了组件拆分决定，然后回来补文档。文档是决策的前置，不是实现的注脚。
