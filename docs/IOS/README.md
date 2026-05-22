# iOS 文档索引

> 本目录负责沉淀 iOS App、SwiftUI 和 Apple 平台开发相关的学习与方法论文档。

## 文档职责

本文是 `docs/IOS/` 的目录入口，负责说明本目录有哪些文档、分别解决什么问题，以及不同阅读目标应该从哪里开始。

**适用读者**：想系统理解本目录 iOS / SwiftUI 文档关系的人。  
**不适用于**：替代具体文档讲解 SwiftUI、Xcode 工程、App 上架或产品 0-1 流程。

## 阅读路径

如果你从一个 App 想法开始，推荐按这条顺序读：

```text
iOS App 0-1 工作流
-> iOS App 从 0 到上架
-> SwiftUI 基础扫盲
-> SwiftUI 示例项目基础扫盲
-> SwiftUI 认知坐标
```

这条路径先解决“做什么”，再解决“如何进入 iOS 开发生态”，最后补 SwiftUI 对象、工程承载和技术判断。

如果你已经知道自己要读什么，可以直接按问题进入：

| 你现在的问题 | 推荐阅读 |
|--------------|----------|
| 有 App 想法，但不知道如何拆 MVP 和推进第一版 | [iOS App 0-1 工作流](ios-app-0-1-workflow.md) |
| 想了解 iOS 从准备、开发、测试到上架的完整路线 | [iOS App 从 0 到上架：新手完整指南](ios-app-development-guide.md) |
| 不清楚 SwiftUI 是什么、和 Swift / iOS / UIKit 的边界是什么 | [SwiftUI 基础扫盲](swiftui-basic-literacy.md) |
| 会写一些 SwiftUI，但不知道项目如何被 Xcode 承载并运行 | [SwiftUI 示例项目基础扫盲](swiftui-sample-project-basic-literacy.md) |
| 已经理解 SwiftUI 基础，想形成更高层的技术判断 | [SwiftUI 认知坐标](swiftui-cognitive-coordinate.md) |

## 文档索引

### 产品与流程

- [iOS App 0-1 工作流](ios-app-0-1-workflow.md)  
  定义从想法到 MVP 开发闭环的阶段、输入、输出、最小可用产物和进入下一步条件。

- [iOS App 从 0 到上架：新手完整指南](ios-app-development-guide.md)  
  帮助新手建立 iOS 开发、测试、TestFlight、提交审核和上架维护的整体路线。

### SwiftUI 学习

- [SwiftUI 基础扫盲](swiftui-basic-literacy.md)  
  解释 SwiftUI 是什么、为什么存在、核心结构是什么，以及它和相邻概念的边界。

- [SwiftUI 示例项目基础扫盲](swiftui-sample-project-basic-literacy.md)  
  解释 SwiftUI 示例项目如何从源码进入 `.xcodeproj`，再通过 Xcode 或 `xcodebuild` 编译运行。

- [SwiftUI 认知坐标](swiftui-cognitive-coordinate.md)  
  把 SwiftUI 放入 Apple UI 开发、声明式 UI 范式和跨平台前端生态中理解。

## 维护规则

- 新增 iOS / SwiftUI 文档时，优先使用英文小写加连字符命名。
- 新文档必须在本文补充索引，并说明它和现有文档的边界。
- 不把草稿、问答式临时判断和正式文档长期混放在本目录根部。
- 仓库内链接使用相对路径，避免绝对路径导致迁移后失效。
- 若某篇文档只是在解释另一篇文档的局部细节，优先考虑合并或在主文档中链接，不新增平行入口。
