# SwiftUI 示例项目基础扫盲

> 让一个 SwiftUI 示例项目从“几堆文件和工具名”，变成一条可以从 0 到 1 跑通的开发链路。

## 文档职责

本文负责帮助初学者理解一个 SwiftUI App 示例项目从哪里开始、靠什么承载、用什么工具编写和运行，以及一个最小业务项目应该如何组织目录。

**适用读者**：已经知道 SwiftUI 是 Apple 的声明式 UI 框架，但还不清楚如何把 SwiftUI 代码放进一个可运行 iOS App 项目的人。  
**不适用于**：深入讲解 Swift 语法、SwiftUI 控件全集、复杂架构设计、App Store 上架流程或生产级工程自动化。

## 先把对象定住

这里讨论的不是 SwiftUI 语法本身，而是一个“SwiftUI 示例项目”。

一个 SwiftUI 示例项目至少包含三层东西：

```text
SwiftUI 示例项目
├── 代码：Swift / SwiftUI 源码
├── 工程：承载 App 的 .xcodeproj 或等价生成结果
└── 运行：通过 Xcode 或 xcodebuild 编译、调试、安装到模拟器或真机
```

很多新手会把“会写一个 SwiftUI View”误认为“已经会做一个 iOS App”。这中间缺少的是工程承载层：代码必须放进一个能被 Xcode 识别、编译和签名的 App 工程里，才会变成可安装运行的 iOS 应用。

## 从底层到产出的完整链路

可以先用一条纵向链路理解 SwiftUI 示例项目：

```text
【最底层：基础语言】
        Swift 编程语言
              ↓
【上层界面框架】
        SwiftUI（依赖 Swift，写页面）
              ↓
【代码编写层】
        VSCode（纯写 Swift / SwiftUI 源码）
              ↓
【项目承载层（二选一）】
├─ 正式 App 路线：.xcodeproj 标准工程（HeatMoment 主项目）
│   ├─ 手动创建：Xcode 直接新建生成
│   └─ 自动生成：XcodeGen / Tuist 生成 .xcodeproj
│
└─ 工具库路线：Swift Package（仅公共代码，不能跑 App）
              ↓
【构建运行层】
├─ 图形化操作：Xcode 打开 .xcodeproj → 编译 + 调试 + 运行
└─ 命令行校验：xcodebuild 终端编译校验项目
              ↓
【最终产出】
        iOS 可安装运行应用
```

这条链路的关键不是记住所有工具名，而是看清每一层的职责。

## 每一层负责什么

### Swift：基础语言

Swift 是写 iOS App 的主要编程语言。变量、结构体、枚举、函数、闭包、协议、属性包装器等能力都来自 Swift。

SwiftUI 示例代码看起来像是在写界面，但底层仍然是 Swift 代码。看不懂 Swift 的基础语法，就很难真正理解 SwiftUI 示例为什么能工作。

### SwiftUI：界面框架

SwiftUI 是建立在 Swift 之上的 UI 框架。它负责让开发者用声明式方式描述界面：

```swift
struct ContentView: View {
    var body: some View {
        Text("Hello")
    }
}
```

SwiftUI 只解决“界面如何表达和响应状态变化”的问题。它不负责替代工程文件、签名、编译配置、模拟器运行和 App 安装。

### VSCode：代码编写工具

VSCode 可以用来编辑 `.swift` 文件，适合作为轻量代码编辑器。

但 VSCode 本身不是 iOS App 工程系统。只在 VSCode 里写 SwiftUI 源码，并不会自动得到一个可运行 App。最终仍然需要 Xcode 工程或构建工具来承载和编译。

### .xcodeproj：正式 App 工程承载

`.xcodeproj` 是 Xcode 标准工程文件。一个真正可运行的 iOS App，需要有 App target、Bundle Identifier、Info 配置、资源、编译设置和签名配置。

对于 SwiftUI 新手，最稳妥的路线是：

```text
Xcode 新建 App 项目
→ 选择 SwiftUI
→ 得到 .xcodeproj
→ 在生成的工程里逐步添加代码
```

这条路线不优雅，但最直接，能避免一开始就陷入工程生成工具和构建配置。

### XcodeGen / Tuist：自动生成工程

XcodeGen 和 Tuist 可以通过配置文件生成 `.xcodeproj`。它们适合更大项目或团队协作场景，能减少手动维护 Xcode 工程文件的冲突和漂移。

但对第一个 SwiftUI 示例项目来说，它们不是必需入口。新手应先理解 `.xcodeproj` 承载 App 的基本事实，再考虑自动生成。

### Swift Package：工具库路线

Swift Package 适合承载公共代码、工具函数、模型、网络层、算法或可复用组件。

但 Swift Package 本身不是一个完整 iOS App。它不能替代 App 工程，也不会直接产出一个可安装运行的应用。

可以这样判断：

```text
要做一个能运行的 iOS App：用 .xcodeproj / App target
要做一组可复用 Swift 代码：用 Swift Package
```

### Xcode：图形化构建和调试

Xcode 是 iOS App 最核心的开发工具。它负责打开 `.xcodeproj`，选择模拟器或真机，编译代码，运行 App，调试问题，管理资源和签名。

新手阶段应优先用 Xcode 跑通项目，因为它能把工程状态、编译错误、模拟器运行和界面预览放在一个环境里。

### xcodebuild：命令行校验

`xcodebuild` 是 Apple 提供的命令行构建工具。它适合在终端、脚本或 CI 中验证项目能否编译。

例如真实项目中常见的校验方式是：

```bash
xcodebuild -project HeatMoment.xcodeproj -scheme HeatMoment -destination 'platform=iOS Simulator,name=iPhone 16' build
```

新手不需要一开始熟练掌握所有参数，但要知道：Xcode 是图形化入口，`xcodebuild` 是命令行入口，它们面对的是同一个工程。

## HeatMoment 示例项目目录

一个 SwiftUI 日记类示例项目可以命名为 `HeatMomentApp`。它的目录不需要一开始很复杂，但要能让新手看出“入口、界面、业务、数据、工具”之间的边界。

建议目录如下：

```text
HeatMomentApp/
├── App/           # App 入口（HeatMomentApp.swift），程序启动的地方
├── Components/    # 通用 UI 组件（空状态、标签、卡片，全局复用）
├── Features/      # 核心业务模块（首页 Home、编辑页 Editor，主要功能代码）
├── Models/        # 数据模型（日记、心情、标签，SwiftData 本地存储结构）
├── Services/      # 数据操作服务（日记增删改查的逻辑层）
└── Support/       # 工具类（主题、日期格式化、模拟数据）
```

这个结构的目标不是追求“架构完整”，而是让第一个项目从一开始就有清晰边界。

## 每个目录放什么

### App：启动入口

`App/` 放程序入口，例如：

```text
App/
└── HeatMomentApp.swift
```

`HeatMomentApp.swift` 通常包含 `@main`，它是 App 启动的地方。这里负责挂载根视图，也可以接入 SwiftData 的 model container、全局环境对象等。

初学阶段可以把它理解为：

```text
App 入口
→ 创建应用
→ 指定第一个页面
→ 提供必要的全局上下文
```

### Features：主要业务页面

`Features/` 放核心业务模块。对 HeatMoment 来说，可以先从两个模块开始：

```text
Features/
├── Home/
│   └── HomeView.swift
└── Editor/
    └── EditorView.swift
```

`Home` 负责展示日记列表和今日心情概览。`Editor` 负责新增或编辑一条日记。

一个新手项目最怕所有页面都堆在 `ContentView.swift` 里。`Features/` 的作用就是让主要功能按业务含义拆开，而不是按控件类型混在一起。

### Models：数据对象

`Models/` 放业务数据模型，例如：

```text
Models/
├── DiaryEntry.swift
├── Mood.swift
└── Tag.swift
```

这些文件描述项目中的核心对象：一篇日记是什么，心情有哪些状态，标签如何关联。

如果使用 SwiftData，模型里可能出现 `@Model`。但无论是否使用 SwiftData，`Models/` 的职责都是表达业务数据结构，而不是写页面布局。

### Components：通用 UI 组件

`Components/` 放跨多个页面复用的 UI，例如：

```text
Components/
├── EmptyStateView.swift
├── MoodTagView.swift
└── DiaryCardView.swift
```

这里的判断标准是“是否真的被多个地方复用”。如果一个视图只属于首页，就先放在 `Features/Home/` 里，不要过早抽到 `Components/`。

`Components/` 不应该变成所有小视图的垃圾桶。它只放有明确复用价值的界面单元。

### Services：数据操作逻辑

`Services/` 放和数据操作有关的逻辑，例如查询、创建、更新、删除日记。

```text
Services/
└── DiaryService.swift
```

但新手阶段要谨慎使用这一层。SwiftUI 和 SwiftData 已经提供了 `@Query`、`modelContext` 等能力，简单项目可以先直接在 Feature 中使用。

当同一段数据操作开始在多个页面重复出现，或者逻辑明显变复杂，再沉淀到 `Services/` 会更自然。

### Support：辅助工具

`Support/` 放不属于业务核心、但项目会用到的辅助能力：

```text
Support/
├── AppTheme.swift
├── DateFormatter+HeatMoment.swift
└── MockData.swift
```

例如主题颜色、日期格式化、预览用模拟数据，都适合放在这里。

## 推荐的 0-1 创建路径

对第一个 SwiftUI 示例项目，推荐按这个顺序做：

```text
1. 用 Xcode 新建 iOS App，选择 SwiftUI
2. 确认默认项目能在模拟器运行
3. 创建 HeatMomentApp/ 下的 App、Features、Models、Components、Services、Support 目录
4. 把默认 ContentView 改造成 HomeView
5. 新建 DiaryEntry、Mood、Tag 等基础模型
6. 做一个不依赖数据库的静态首页
7. 加入 EditorView，实现新增或编辑界面
8. 再接入 SwiftData 或本地存储
9. 最后用 xcodebuild 做命令行编译校验
```

这里的关键顺序是：先跑起来，再拆结构，再接数据。

如果一开始就设计完整架构、完整数据库、完整服务层，示例项目会很快变成“看起来专业但跑不起来”的空壳。

## 最小可用产物

一个 SwiftUI 示例项目的最小可用产物，不是目录看起来完整，而是能完成一条真实使用路径：

```text
打开 App
→ 看到日记列表或空状态
→ 点击新增
→ 进入编辑页
→ 输入内容和心情
→ 保存
→ 回到首页看到结果
```

只要这条路径跑通，项目就已经从“代码示例”进入“可运行 App”。

## 常见误区

### 误区一：以为 VSCode 可以替代 Xcode

VSCode 可以写代码，但不能完整替代 Xcode 的 iOS App 工程、签名、模拟器和调试能力。新手阶段不要把 VSCode 当成唯一开发入口。

### 误区二：以为 Swift Package 可以直接跑 App

Swift Package 适合公共代码，不适合承载完整 iOS App。App 仍然需要 App target 和工程配置。

### 误区三：一开始就上 XcodeGen 或 Tuist

自动生成工程适合工程复杂度已经出现时使用。第一个示例项目应先理解 Xcode 标准工程，再考虑引入生成工具。

### 误区四：目录越多越专业

目录结构服务理解和维护，不服务表面完整。没有真实职责的目录会增加跳转成本。

### 误区五：过早抽象 Services

对于 SwiftUI + SwiftData 的简单示例，直接在页面中使用 `@Query` 和 `modelContext` 可能更适合教学。等重复逻辑和复杂逻辑出现后，再抽出 `Services`。

## 判断标准

SwiftUI 示例项目基础扫盲是否完成，只看一个标准：

**你是否已经能解释一段 SwiftUI 源码如何从 Swift 语言和 SwiftUI 框架出发，进入 `.xcodeproj` 工程，再通过 Xcode 或 `xcodebuild` 变成一个可安装运行的 iOS App。**

如果只会写 `View`，但不知道项目为什么需要 `.xcodeproj`，扫盲没有完成。

如果已经能分清 Swift、SwiftUI、VSCode、Xcode、`.xcodeproj`、Swift Package、`xcodebuild` 的位置，并能为 HeatMoment 这样的示例项目划分入口、业务、模型、组件、服务和工具目录，基础扫盲已经成立。
