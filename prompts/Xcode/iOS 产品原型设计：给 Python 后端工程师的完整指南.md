# iOS 产品原型设计：给 Python 后端工程师的完整指南

## 先建立心智模型

你的核心诉求不是"画图"，而是：

> **生成对 AI 有参考价值的结构化描述，让 AI 能据此写出真实可运行的 SwiftUI 代码**

你在 Web 开发中用 HTML 做到了这件事，因为 HTML 本身就是 UI 的结构化语言，AI 可以直接"读懂"它的层级、组件和交互意图。

现在的问题是：**iOS / SwiftUI 领域有没有等价物？**

答案是：**有，而且不止一种。**

---

## 核心类比

```
你熟悉的路径：
  画 HTML → AI 读 HTML 结构 → AI 写前端代码

iOS 等价路径：
  写 SwiftUI 伪代码 / DSL 描述 → AI 读结构 → AI 写 SwiftUI 代码
```

关键认知：**AI 参考的不是图片，而是结构。** 能表达结构的，都是有效输入。

---

## 可用方案全景

```
表达方式
├── 直接用代码表达（最高价值）
│   ├── SwiftUI 伪代码          ← 最推荐，门槛低，价值最高
│   └── 真实 SwiftUI 代码       ← 你熟练后自然过渡到这里
│
├── 结构化文本描述（次选）
│   ├── Markdown 组件树描述     ← 0 门槛，AI 理解良好
│   └── JSON / YAML 结构描述   ← 适合数据驱动页面
│
└── 可视化原型工具（参考价值最低）
    ├── Figma                   ← 产品设计用，AI 读不了结构
    ├── Sketch                  ← 同上
    └── 截图 / 手绘              ← 基本无结构参考价值
```

---

## 方案详解

### 方案一：SwiftUI 伪代码（最推荐）

**为什么适合你：** 语法极像 Python + HTML 的混合体，声明式、缩进清晰，你能快速上手写"结构草稿"，不需要代码真正能运行。

**示例：设计一个用户个人页**

```swift
// ProfileView 个人主页
VStack {
    // 顶部头像区
    HStack {
        Avatar(size: 64)
        VStack(alignment: .leading) {
            Text("用户名")       // 主标题
            Text("个人简介...")  // 副标题，灰色小字
        }
    }

    Divider()

    // 数据统计行
    HStack {
        StatItem(label: "关注", count: 128)
        StatItem(label: "粉丝", count: 3200)
        StatItem(label: "获赞", count: 9999)
    }

    // 内容列表
    List {
        ForEach(posts) { post in
            PostCard(title: post.title, date: post.date)
        }
    }

    // 底部编辑按钮
    Button("编辑资料") { }
        .style(.primary, fullWidth: true)
}
```

AI 拿到这份伪代码，能直接理解：层级结构、组件类型、内容语义、交互意图。**参考价值等同于你的 HTML。**

---

### 方案二：Markdown 组件树描述（0 门槛入门）

不想写任何代码时，用结构化 Markdown 描述页面，AI 同样能高质量理解。

```markdown
## 页面：首页 HomeView

**布局：** 纵向滚动，NavigationStack 包裹

### 顶部导航栏
- 左侧：App Logo
- 右侧：消息图标（有未读红点）

### Banner 轮播区
- 全宽横向滚动
- 每张卡片：封面图 + 标题 + 标签

### 分类 Tab
- 横向可滚动
- 选中项高亮下划线
- 选项：推荐 / 热门 / 关注 / 最新

### 内容列表
- 卡片式列表，懒加载
- 每张卡片包含：
  - 封面图（左）
  - 标题 + 摘要 + 作者 + 时间（右）
  - 底部：点赞数 / 评论数 / 收藏按钮

### 底部 TabBar
- 首页 / 发现 / 发布（中间凸起大按钮）/ 消息 / 我的
```

---

### 方案三：JSON / YAML 结构描述（适合数据驱动场景）

如果你的页面是数据驱动的（列表、表单、配置页），用你最熟悉的 JSON / YAML 描述，AI 理解同样精准。

```yaml
page: UserSettingsView
title: 设置
style: grouped-list

sections:
  - title: 账号
    items:
      - label: 头像
        type: image-picker
      - label: 用户名
        type: text-field
        placeholder: 请输入用户名
      - label: 手机号
        type: display-only
        value: "138****8888"

  - title: 通知
    items:
      - label: 推送通知
        type: toggle
        default: true
      - label: 邮件通知
        type: toggle
        default: false

  - title: 其他
    items:
      - label: 清除缓存
        type: button
        style: destructive
      - label: 退出登录
        type: button
        style: destructive
```

---

## 三种方案对比

| 维度 | SwiftUI 伪代码 | Markdown 描述 | JSON/YAML |
|------|--------------|-------------|-----------|
| 学习门槛 | 低（声明式，像 HTML） | 零 | 零（你本来就会） |
| AI 参考价值 | ★★★★★ | ★★★★☆ | ★★★★☆ |
| 表达交互逻辑 | ✅ 强 | ⚠️ 弱 | ⚠️ 弱 |
| 表达层级结构 | ✅ 强 | ✅ 强 | ✅ 强 |
| 表达视觉样式 | ✅ 较强 | ⚠️ 中 | ⚠️ 中 |
| 适合场景 | 所有页面 | 快速草稿 | 表单/列表页 |

---

## 给你的实践建议

你是 Python 后端 + HTML 前端背景，建议这样起步：

**第一周：** 用 Markdown 描述法写 2～3 个页面结构，感受 AI 的理解质量

**第二周：** 切换到 SwiftUI 伪代码，参考上面的示例格式，不要求能运行，只求结构清晰

**第三周起：** AI 生成的代码你开始能看懂、能微调，自然就过渡到直接读写真实 SwiftUI 代码

> SwiftUI 的声明式语法对有 HTML 经验的人非常友好，上手速度会远快于你的预期。