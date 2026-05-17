# iOS App 从 0 到上架：新手完整指南

## 文档职责

帮助完全没有 iOS 开发经验的新手，从搭建环境开始，经历开发、测试、直到将 App 成功上架 App Store，建立清晰的整体路径认知。

**适用读者**：有一定编程基础，但没接触过 iOS 开发的新手  
**不适用于**：需要深入学习 Swift 语法、架构设计或复杂功能实现的场景

---

## 整体路径

在进入细节之前，先建立全局认知。iOS 开发上架分为五个阶段：

```
准备阶段 → 开发阶段 → 测试阶段 → 提交审核 → 上架维护
```

每个阶段都有前置条件，不能跳过。理解这条主线，后面的每一步才不会迷失。

---

## 阶段一：准备

### 你需要什么

| 必要条件 | 说明 |
|----------|------|
| Mac 电脑 | iOS 开发只能在 macOS 上进行，无法用 Windows |
| Apple ID | 注册开发者账号的前提 |
| Apple 开发者账号 | 年费 $99，上架 App Store 必须有 |
| Xcode | Apple 官方 IDE，免费，在 Mac App Store 下载 |

> **新手常见误区**：免费的 Apple ID 可以在真机上运行自己的 App，但无法上架 App Store，也无法分发给他人测试（TestFlight 除外的场景）。付费开发者账号是上架的硬性前提。

### 注册开发者账号

1. 前往 [developer.apple.com](https://developer.apple.com)
2. 登录你的 Apple ID
3. 加入 Apple Developer Program，完成付款（$99/年）
4. 等待审核通过（通常几分钟到 24 小时）

### 安装 Xcode

从 Mac App Store 搜索并安装 Xcode。注意：Xcode 体积较大（约 15GB），建议提前准备好磁盘空间和网络环境。

---

## 阶段二：开发

### 选择开发语言

iOS 开发支持两种语言：

| 语言 | 特点 | 推荐场景 |
|------|------|----------|
| Swift | Apple 官方推荐，现代语法，文档资源丰富 | 新手首选 |
| Objective-C | 老语言，仍被大量老项目使用 | 维护老项目时接触 |

**新手建议直接学 Swift**，这是 Apple 当前重点维护的方向。

### 选择 UI 框架

| 框架 | 特点 |
|------|------|
| SwiftUI | 声明式 UI，代码量少，Apple 主推方向 |
| UIKit | 命令式 UI，成熟稳定，学习资料极多 |

两者可以混用。新手建议从 **SwiftUI** 开始，更直观，实时预览方便调试。

### 创建第一个项目

1. 打开 Xcode → `File` → `New` → `Project`
2. 选择 `App` 模板
3. 填写项目信息：
   - **Product Name**：你的 App 名称
   - **Bundle Identifier**：唯一标识符，格式如 `com.yourname.appname`
   - **Interface**：选 SwiftUI
   - **Language**：选 Swift
4. 点击 Next，选择保存位置

### 项目结构概览

```
YourApp/
├── YourAppApp.swift     ← App 入口
├── ContentView.swift    ← 主界面（从这里开始写 UI）
├── Assets.xcassets/     ← 图片、图标等资源
└── Info.plist           ← App 配置信息
```

新手只需先关注 `ContentView.swift`，这是你写界面的地方。

### 在真机上运行

1. 用 USB 连接 iPhone 到 Mac
2. 在 Xcode 顶部选择你的设备（而非模拟器）
3. 第一次运行需要在 iPhone 上信任开发者：`设置 → 通用 → VPN与设备管理`
4. 点击运行按钮（▶）

---

## 阶段三：测试

### 模拟器 vs 真机

- **模拟器**：快速调试 UI，无需真机，但无法测试相机、传感器等硬件功能
- **真机**：接近真实用户体验，必须在上架前充分测试

### TestFlight（外部测试）

TestFlight 是 Apple 官方的 Beta 测试平台，可以邀请最多 10,000 名外部测试用户。

流程：
1. 在 App Store Connect 上传构建版本
2. 填写测试信息，提交审核（通常 1 天内）
3. 审核通过后，生成邀请链接发给测试者
4. 测试者安装 TestFlight App，用链接加入测试

---

## 阶段四：提交审核

### 上架前准备清单

在提交之前，以下内容必须准备好：

**App 资料**
- App 名称（最多 30 字符）
- 副标题（最多 30 字符）
- 描述（最多 4000 字符）
- 关键词（最多 100 字符，影响搜索排名）
- 隐私政策链接（必须有，即使 App 不收集数据）

**视觉素材**
- App 图标：1024×1024 px，PNG，无透明背景
- 截图：按设备尺寸分别提供（至少需要 iPhone 6.5 英寸截图）

**技术配置**
- 版本号（如 `1.0.0`）
- 构建号（Build Number，每次提交需递增）
- 选择年龄分级

### 打包并上传

1. Xcode 顶部选择 `Any iOS Device`（不是具体设备）
2. 菜单 `Product` → `Archive`
3. 在弹出的 Organizer 中点击 `Distribute App`
4. 选择 `App Store Connect` → 按默认设置继续
5. 上传完成后，前往 App Store Connect 查看构建版本

### 提交审核

1. 登录 [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. 进入你的 App → `App Store` 标签页
3. 填写完所有资料后，点击右上角 `提交以供审核`

**审核时间**：通常 1-3 个工作日，也可能更长。审核期间不要修改 App 信息。

### 常见被拒原因

| 原因 | 说明 |
|------|------|
| 功能不完整 | 有占位内容或明显 Bug |
| 缺少隐私政策 | 即使不收集数据也需要 |
| 描述与实际功能不符 | 审核员会实际使用你的 App |
| 崩溃 | 上架前务必充分测试 |
| 设计质量过低 | App 需要有基本的使用体验 |

---

## 阶段五：上架后

App 审核通过后，你可以选择立即发布或手动选择发布时间。

上架后需要持续关注：
- **用户反馈**：App Store Connect 可以查看评分和评论
- **崩溃报告**：Xcode 的 Organizer 有崩溃数据
- **版本更新**：修复 Bug 或新增功能时，重复阶段四的流程提交新版本

---

## 学习资源

| 资源 | 说明 |
|------|------|
| [Apple 官方教程](https://developer.apple.com/tutorials/swiftui) | SwiftUI 入门，质量高，免费 |
| [100 Days of SwiftUI](https://www.hackingwithswift.com/100/swiftui) | 系统学习路径，适合新手 |
| [WWDC 视频](https://developer.apple.com/videos/) | Apple 每年发布，深入了解新特性 |
| [Swift 官方文档](https://docs.swift.org/swift-book/) | 语言规范参考 |

---

## 常见问题

**Q：没有 Mac 能开发 iOS App 吗？**  
不行。iOS 开发必须在 macOS 上进行，Xcode 只有 Mac 版本。

**Q：$99 的开发者费用是一次性的吗？**  
不是，是每年续费。停止续费后你的 App 会从 App Store 下架。

**Q：App 审核被拒后怎么办？**  
仔细阅读被拒原因，针对性修改后重新提交即可。Apple 会在邮件和 App Store Connect 中说明具体原因。

**Q：SwiftUI 和 UIKit 必须二选一吗？**  
不是，可以在同一个项目中混用。SwiftUI 视图可以嵌入 UIKit，反之亦然。
