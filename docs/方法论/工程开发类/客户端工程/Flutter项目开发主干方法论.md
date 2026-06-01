# Flutter 项目开发主干方法论

> 把 Flutter 应用从需求、概念图、旧代码或模糊想法，推进到可运行、可验证、可持续迭代的工程主干。

```text
Flutter 项目开发主干
├── Scope：版本边界
│   └── 先切清当前 Flutter 应用做什么、不做什么，防止概念图和未来能力污染首版
├── Architecture：工程架构
│   └── 明确界面、状态、数据、路由、主题和平台能力的职责边界
├── Flow：交互流程
│   └── 建立页面流转、入口关系、弹层关系和核心用户路径
├── Surface：界面表面
│   └── 把概念图转成页面结构、组件层级、视觉 token 和关键状态
├── Slice：核心切片
│   └── 选择最能代表主链路的垂直模块，用它逼出最小基础设施
├── Model：状态模型
│   └── 区分持久化数据、页面状态、组件状态、派生状态和一次性交互状态
├── Prototype：原型验证
│   └── 在真实运行环境中验证布局、滚动、键盘、弹层和手势
├── Build：模块实现
│   └── 按核心切片逐步实现，保持架构、交互、界面和状态模型一致
├── Verify：运行验证
│   └── 在模拟器、真机或桌面环境中验证主路径、状态流转、截图和必要测试
└── Govern：回写治理
    └── 把本轮实现、问题、约束和下一步清单回写到项目文档
```

## 核心命题

Flutter 项目开发主干方法论处理的不是“Flutter 怎么写代码”，而是“一个 Flutter 应用应该按照什么判断顺序进入开发”。

Flutter 的误区通常不是缺少 `Widget`、命令或插件，而是开发顺序混乱：需求还没收敛就开始画页面，页面还没讲清就开始拆组件，状态归属还没定就接持久化，原型没跑过就进入细节打磨。

这套方法论的任务，是把 Flutter 项目从想法到实现的主干节点定住，让开发者知道当前卡在哪个节点、该产出什么、做到什么程度才适合进入下一步。

它的核心转化是：

```text
模糊 Flutter 应用 -> 边界与结构判断 -> 交互与界面建模 -> 切片与状态收敛 -> 运行验证 -> 工程治理
```

## 方法论节点

这套方法论不是线性任务清单。真实项目中，后续节点暴露问题时，可以回退到前置节点补强；但前置节点没有达到基本质量时，不应靠后续编码兜底。

### Scope：版本边界

先判断当前 Flutter 应用这一版做什么、不做什么。

Flutter 项目经常从概念图、竞品截图、旧原生应用或一句产品想法开始。此时最容易把未来能力、视觉愿望、平台能力和当前版本混在一起，导致首版范围膨胀。

`Scope` 要回答：当前版本验证哪条主链路，哪些页面必须进入，哪些能力明确延后，哪些概念图内容只作为未来方向。

有效的 `Scope` 不追求完整，而追求能支撑第一轮工程判断。范围不清时，不应进入架构或 UI 细节。

### Architecture：工程架构

明确 Flutter 工程的基本分层和状态管理路线。

Flutter 应用不是一组页面文件。`Architecture` 判断代码职责是否有稳定归属：界面、状态、数据、路由、主题和平台能力不应互相兜底。

`Architecture` 的重点不是堆技术栈。技术库只有在影响职责归属、状态路线、数据边界或页面入口时，才进入架构判断。

如果架构还不能回答“页面状态放哪里、数据从哪里来、路由怎么进出、主题如何复用”，就不适合进入大规模实现。

#### 组件复用策略

Flutter 的组件体系类似后端框架的模块化设计。判断组件实现策略时，应遵循“复用优先、按需自定义”原则。

**优先级顺序**：

1. **原生 Material/Cupertino 组件**：Flutter 提供的标准组件（如 `TextField`、`Card`、`BottomSheet`、`AppBar`）
2. **成熟第三方库**：社区维护的专业组件（如日期选择器、图表、动画、下拉刷新）
3. **组合现有组件**：用 `Column`、`Row`、`Stack`、`Container` 等基础组件组合
4. **自定义 Widget**：只在确实需要特殊交互或视觉时才自定义

**判断标准**：

- 原生组件能满足 80% 需求时，优先复用并通过参数微调样式和行为
- 第三方库选择时，优先考虑维护活跃度、文档完善度和社区认可度
- 自定义实现前，先评估维护成本、团队能力和长期演进风险
- 组合现有组件时，保持组件层级清晰，避免过深嵌套

**类比后端开发**：这类似后端不会为了改个字段验证就重写整个 ORM，而是优先使用 FastAPI 的 Pydantic、SQLAlchemy 的内置能力，只在确实需要时才写自定义验证器。

### Flow：交互流程

建立页面流转、入口关系和核心用户路径。

Flutter 开发不能只从静态 UI 图开始。移动端体验由入口、返回、弹层、键盘、滚动、选择器、确认框和刷新关系共同组成。

`Flow` 要判断核心路径是否闭环：用户从哪里进入、如何前进和返回、哪些交互改变状态、异常或空状态如何回到主路径。

如果页面之间的流转还没闭环，直接做 UI 会把实现变成猜测。

### Surface：界面表面

把概念图、草图或旧应用界面转成 Flutter 可以实现的界面结构。

`Surface` 不等于“把图画漂亮”。它要把视觉概念压成可执行对象：页面区块、组件层级、视觉 token、布局约束、交互状态和响应式边界。

对于 Flutter，`Surface` 的重点是判断界面是否已经从截图审美变成可实现结构：组件层级、视觉 token、布局约束、交互状态和响应式边界应能支撑后续实现。

如果界面只停留在截图审美层面，而没有转换成组件和状态，后续实现会不断靠局部 `padding`、固定高度和临时样式补丁推进。

#### 组件选型判断

把视觉概念转成代码前，先判断组件来源和实现策略。

| 视觉需求 | 推荐组件选型 | 后端类比 |
|---------|------------|---------|
| 标准输入框 | `TextField` + 装饰参数 | 用 Pydantic 的 `Field`，而不是自己写验证 |
| 卡片布局 | `Card` + 子组件组合 | 用 `dataclass` 组合，而不是手写字典 |
| 列表展示 | `ListView` 或 `ListView.builder` | 用 ORM 的查询方法，而不是手写 SQL 拼接 |
| 底部弹层 | `showModalBottomSheet` | 用已有中间件，而不是自己写装饰器 |
| 标签页切换 | `TabBar` + `TabBarView` | 用路由分组，而不是手写路径匹配 |
| 标准按钮 | `ElevatedButton` / `TextButton` / `OutlinedButton` | 用框架内置响应对象，而不是自己写封装 |
| 对话框确认 | `showDialog` + `AlertDialog` | 用框架内置异常处理，而不是手写捕获 |
| 特殊交互或视觉 | 自定义 `CustomPaint` 或 `GestureDetector` | 确实需要自定义时才写（如特殊图表、手势识别） |

**判断重点**：

- 标准 UI 模式优先查 Material Design 或 Cupertino 组件库，而不是直接自定义
- 复杂交互优先查第三方库（如 `flutter_slidable`、`flutter_staggered_grid_view`），而不是从零实现
- 只有在原生组件和第三方库都不能满足时，才进入自定义实现
- 自定义组件应保持单一职责，避免变成“万能组件”

**避免过早自定义**：类似后端不会为了改个字段名就重写 ORM，Flutter 也不应为了改个颜色就自定义整个组件。

### Slice：核心切片

选择首个最值得落地的垂直模块。

Flutter 项目不应先把所有基础设施铺满，也不应先做边缘页面。首个切片应该能代表主链路，并逼出真实的最小基础设施。

好的 `Slice` 应能让用户完整走过主链路，并在较小范围内暴露入口、界面、数据、状态和运行验证问题。

例如日记类应用的首个切片通常不是设置页，也不是主题编辑，而是“创建一条记录并在首页看到它”。

### Model：状态模型

区分 Flutter 项目里的不同状态来源。

Flutter 的复杂度经常来自状态混淆，而不是页面数量。持久化数据、页面状态、组件局部状态、派生状态和一次性交互状态如果混在一个地方，后续会很快变得难以维护。

`Model` 要切清哪些状态需要持久化，哪些只属于页面、组件、派生计算或一次性交互，避免把生命周期不同的状态放进同一个容器。

状态模型应服务当前核心切片，不应为了未来所有可能性提前建立庞大抽象。

#### 状态可控性设计

Flutter 状态设计类似后端的数据模型设计。核心是在"可微调"和"整体可控"之间取得平衡。

**设计原则**：

| 原则 | Flutter 实现 | 后端类比 |
|------|-------------|---------|
| 限定可调范围 | 用枚举或常量定义允许值 | Python 的 `Enum` 或 Pydantic 的 `Literal` |
| 全局样式复用 | 用 `Theme` 管理颜色、字体、间距 | FastAPI 的 `Config` 或环境变量 |
| 响应式布局 | 用 `MediaQuery`、`LayoutBuilder`、比例计算 | 后端的配置驱动，而不是硬编码常量 |
| 状态验证 | 用构造函数或工厂方法验证 | Pydantic 的字段验证 |

**示例：心情节点状态设计**

**Flutter 实现**：

```dart
// 枚举限定可选类型
enum MoodType { happy, sad, neutral, excited }

class MoodNode {
  final String id;
  final MoodType type;
  final IconData icon;
  final Color color;

  MoodNode({
    required this.id,
    required this.type,
    required this.icon,
    required this.color,
  });

  // 工厂方法限定可用图标和颜色
  factory MoodNode.fromType(String id, MoodType type) {
    return MoodNode(
      id: id,
      type: type,
      icon: _iconMap[type]!,
      color: _colorMap[type]!,
    );
  }

  static const _iconMap = {
    MoodType.happy: Icons.sentiment_satisfied,
    MoodType.sad: Icons.sentiment_dissatisfied,
    MoodType.neutral: Icons.sentiment_neutral,
    MoodType.excited: Icons.emoji_emotions,
  };

  static const _colorMap = {
    MoodType.happy: Colors.green,
    MoodType.sad: Colors.blue,
    MoodType.neutral: Colors.grey,
    MoodType.excited: Colors.orange,
  };
}
```

**后端类比**（Python）：

```python
from enum import Enum
from pydantic import BaseModel, validator

class MoodType(str, Enum):
    HAPPY = "happy"
    SAD = "sad"
    NEUTRAL = "neutral"
    EXCITED = "excited"

class MoodNode(BaseModel):
    id: str
    type: MoodType
    icon: str
    color: str

    @validator('color')
    def validate_color(cls, v, values):
        allowed = ["green", "blue", "grey", "orange"]
        if v not in allowed:
            raise ValueError(f"颜色必须在 {allowed} 中选择")
        return v
```

**避免硬编码但保持可控**：

| 场景 | ❌ 硬编码 | ✅ 可控设计 |
|------|---------|-----------|
| 尺寸 | `Container(width: 375, height: 50)` | `Container(width: MediaQuery.of(context).size.width * 0.9)` |
| 颜色 | `Color(0xFF123456)` | `Theme.of(context).primaryColor` 或枚举限定 |
| 字体 | `fontSize: 16` | `Theme.of(context).textTheme.bodyLarge?.fontSize` |
| 间距 | `padding: EdgeInsets.all(8)` | `padding: EdgeInsets.all(Theme.of(context).spacing.small)` |

**核心判断**：

- 需要全局复用的样式（颜色、字体、间距），放入 `Theme` 或常量文件
- 需要限定范围的选项（类型、状态、图标），用枚举或工厂方法
- 需要适配不同机型的尺寸，用响应式计算而非固定值
- 需要组件级微调的参数，通过构造函数传入，但限定取值范围

这类似后端设计：数据库连接字符串放配置文件，用户角色用枚举限定，业务规则用验证器保证，临时参数通过函数传入但做边界校验。

### Prototype：原型验证

在 Flutter 中做可交互原型。

Flutter 项目的原型不宜默认停留在静态稿或非目标运行环境中。静态视觉可以沟通方向，但不能验证 Flutter 的布局约束、键盘、滚动、弹层、手势和平台差异。

Flutter 原型可以使用临时入口、调试路由或模拟数据模式。它的目标不是写临时代码，而是在正式接入数据和完整逻辑前，先验证界面和交互是否成立。

原型验证关注真实运行环境中的布局、滚动、键盘、弹层、极限状态和平台差异是否成立，而不是只确认静态画面是否接近设计稿。

如果原型阶段已经暴露交互或布局问题，应回到 `Flow` 或 `Surface` 修正，而不是直接进入正式实现。

### Build：模块实现

按核心切片把设计转成正式代码。

`Build` 不是从零开始想设计，而是把前面节点中已经稳定的架构、流程、界面、状态和原型收敛为生产实现。

实现时应保持分层边界：页面负责组合和展示，状态层负责业务状态，数据层负责读写和转换，路由层负责页面入口，主题层负责复用样式。

如果实现过程中发现设计不成立，应回写前置节点，而不是在代码里隐式修改规则。

#### 硬编码与抽象平衡

Flutter 实现应避免两个极端：硬编码导致无法维护，过度抽象导致无法理解。

**避免硬编码**：

| 场景 | ❌ 硬编码 | ✅ 响应式/配置化 |
|------|---------|---------------|
| 固定宽度 | `Container(width: 375)` | `Container(width: MediaQuery.of(context).size.width * 0.9)` 或 `Container(width: 375.w)` (使用 `flutter_screenutil`) |
| 固定颜色 | `Color(0xFF123456)` | `Theme.of(context).primaryColor` 或 `AppColors.primary` |
| 固定文字 | `Text('标题')` | `Text(AppStrings.title)` 或 `Text(context.l10n.title)` |
| 魔法数字 | `padding: EdgeInsets.all(8)` | `padding: EdgeInsets.all(AppSpacing.small)` |

**避免过度抽象**：

| 场景 | ❌ 过度抽象 | ✅ 适度抽象 |
|------|-----------|-----------|
| 万能组件 | `class UniversalWidget { final Map<String, dynamic> config; ... }` 100+ 个配置参数 | 按职责拆分：`MoodCard`、`UserCard`、`StatCard` 各司其职 |
| 深层嵌套 | `BaseWidget -> ResponsiveWidget -> ConfigurableWidget -> MyWidget` | 最多 2-3 层继承或组合 |
| 过早优化 | 首版就写完整的状态机、缓存、重试、回退 | 先实现核心路径，按需补充边界处理 |

**判断标准**：

```dart
// ✅ 适度抽象：清晰的职责和参数
class MoodCard extends StatelessWidget {
  final MoodNode mood;
  final VoidCallback? onTap;

  const MoodCard({
    Key? key,
    required this.mood,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.medium),
          child: Column(
            children: [
              Icon(mood.icon, color: mood.color, size: 48.sp),
              SizedBox(height: AppSpacing.small),
              Text(mood.type.name, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
```

**后端类比**：

| Flutter 场景 | 后端类比 |
|------------|---------|
| 硬编码固定宽度 | 在代码里硬编码数据库连接字符串 |
| 硬编码颜色值 | 在代码里硬编码 API 密钥 |
| 过度抽象的万能组件 | 写一个"万能"基类，所有逻辑都塞进去，100 个参数 |
| 适度抽象的专用组件 | FastAPI 的依赖注入，只注入需要的服务 |

**核心判断**：

- 会随环境变化的值（尺寸、颜色、文字），用配置或响应式计算
- 会在多处复用的 UI 模式，抽取为组件，但参数应限定在必要范围
- 组件职责应单一，避免一个组件处理所有场景
- 不要为了"以后可能要改"就提前写复杂抽象，按当前切片需求实现即可

实现完成后，应确保：改一个主题配置能影响全局，改一个组件参数不会影响其他组件，改一个页面不会影响其他页面。这类似后端的"修改配置文件不需要改代码，修改一个 API 不会影响其他 API"。

### Verify：运行验证

确认 Flutter 应用在真实运行环境中成立。

Flutter 验证不只包括 `flutter analyze` 和单元测试。客户端体验还必须验证运行设备上的布局、交互、键盘、滚动、图片、动画和状态刷新。

`Verify` 应按风险选择静态检查、测试、真实设备运行、手工路径验证或构建验证。验证重点不是跑完命令，而是确认当前切片在目标环境中成立。

没有真实运行验证的 UI 结果，不应写成“体验已完成”。

### Govern：回写治理

把本轮 Flutter 开发沉淀为项目资产。

Flutter 项目在迭代中会不断出现新规则：组件拆分边界、状态归属、命令入口、平台限制、视觉 token、验证方式、暂缓能力。它们如果只停留在聊天记录和代码里，下一轮开发会重新踩同样的问题。

`Govern` 要判断哪些实现结论、架构规则、命令入口、验证结果、暂缓能力和重复问题需要回写为项目资产。

## 判断标准

Flutter 项目开发主干是否成立，只看一个标准：

**项目是否已经从模糊需求或概念图，进入了可运行、可验证、可继续切片迭代的 Flutter 工程闭环。**

如果团队仍然不知道当前版本做什么、不做什么，说明 `Scope` 没完成。

如果页面可以运行，但状态归属、路由入口、数据读写和主题复用都靠临时写法支撑，说明 `Architecture` 或 `Model` 没完成。

如果 UI 看起来接近概念图，但返回、弹层、键盘、滚动和空状态无法推演，说明 `Flow` 和 `Surface` 没完成。

如果代码已经写了很多，但不能用一个核心切片走通用户路径，说明 `Slice` 和 `Verify` 没完成。

当当前切片的交互、界面、数据、状态和验证都能闭环，并且文档已回写，才适合进入下一轮模块。

## 子方法论拆分判断

这套方法论先提供 Flutter 项目级主干，不一开始拆成大量子方法论。

只有当某个节点在多个 Flutter 项目或多个模块中反复出现，并且已经形成稳定误区、稳定判断动作和稳定完成标准时，才值得拆成子方法论。

拆分时应遵守一个原则：子方法论只处理主干中的一个稳定节点，不反向吞掉整个 Flutter 项目开发主干，也不要提前按节点列表预设子方法论。

如果某篇子文档只是某个项目的经验、某个插件的教程或某个页面的实现步骤，不应升格为子方法论。

## Few-shot Learning 示例组

### 正例：日记应用首版

一个 Flutter 日记应用有概念图、旧原生代码和首版需求。合适做法不是直接照图写页面，而是：

先限定首版主链路，再用一个“创建记录并回到首页可见”的切片，同时验证页面流转、状态归属、数据闭环和运行体验。

在实现时：
- 优先使用 Material 的 `Card`、`TextField`、`FloatingActionButton`，而不是全部自定义
- 用 `Theme` 管理全局颜色和字体，而不是在每个页面写死样式
- 用枚举定义心情类型，用工厂方法限定图标和颜色的对应关系
- 用 `MediaQuery` 或 `flutter_screenutil` 实现响应式布局，而不是固定宽高

这个顺序能防止 UI、状态和数据一起失控，同时保证代码可维护和可扩展。

### 反例：先照概念图堆 UI

一个项目拿到高保真图后，直接开始写页面和组件，但没有定义版本边界、路由关系、状态模型和核心切片。

结果通常是：

```text
页面看起来相似，但点击后不知道去哪里
组件拆得很多，但状态归属混乱
局部样式靠固定尺寸补丁推进
数据接入后大量返工
无法判断当前版本是否完成
```

进一步的实现问题：

```text
为了还原设计稿，写了大量自定义组件，忽略了 Material 已有的标准组件
颜色、尺寸、间距全部硬编码，换个主题或适配新机型时需要全局修改
状态全部放在页面里，导致页面间无法共享数据
没有用枚举限定选项范围，导致出现不合法的状态组合
过度抽象写了一个"万能配置组件"，100 个参数，新人无法理解
```

这说明它不仅跳过了 `Scope`、`Flow`、`Model` 和 `Prototype`，也没有遵循组件复用策略和可控性设计原则。

### 边界例：只有单页 Demo

一个 Flutter Demo 只有一个静态页面，没有真实数据、路由、持久化或多状态交互。

这种场景可以只写简单页面说明和运行命令，不需要完整套用本方法论。只有当 Demo 开始进入多页面、多状态、真实数据或持续迭代时，才需要使用 Flutter 项目开发主干。

## 误用

Flutter 项目开发主干不是 Flutter 教程。

不要逐条讲解 Flutter 常识性工具、组件、状态库、路由库或命令。工具只有在影响分层、状态、验证或边界判断时才进入方法论。

Flutter 项目开发主干也不是固定目录模板。

不同项目可以使用不同目录结构、状态管理库和数据方案。方法论只要求分层和职责清楚，不要求所有项目长成同一个文件树。

Flutter 项目开发主干也不是 UI 优先方法。

UI 很重要，但 Flutter 应用的体验由交互流程、状态模型、平台约束和运行验证共同决定。只画静态 UI，不能替代 `Flow`、`Model` 和 `Prototype`。

Flutter 项目开发主干也不是一次性大设计。

每个节点做到足以支撑下一节点即可。不要为了追求完整性，在首版写出超出当前切片需要的全量架构、全量状态机或全量组件库。

## 适用边界

这套方法适合用于：

```text
从 0 到 1 创建 Flutter 应用
把旧 iOS / Android / Web 应用迁移或重构为 Flutter
基于概念图和需求文档启动 Flutter 项目
Flutter 项目开始出现多页面、多状态、多数据来源
Flutter 项目需要从原型进入可持续工程
```

这套方法不适合用于：

```text
Dart 或 Flutter 基础语法教学
单个 Widget 的 API 解释
一次性静态页面 Demo
插件安装教程
纯后端项目或非 Flutter 客户端项目
已经有成熟工程流程且只需要修一个局部 bug 的项目
```

如果问题只是“不知道某个 Flutter 命令怎么用”，应使用工具能力使用与排错方法论。

如果问题是“项目是否需要统一开发脚本”，应使用项目开发入口设计方法论。

如果问题是“某个主干节点已经反复出现，并且需要单独抽象”，再进入方法论新增范式判断是否新增对应子方法论。
