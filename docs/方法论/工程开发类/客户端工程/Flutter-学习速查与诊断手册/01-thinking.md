# Flutter 技术栈心智模型
> 在学具体 API 之前，先建立思维方式。本文回答：Flutter 和命令式开发有什么本质区别？

---

## 一、核心范式：UI = f(state)

命令式思维（Android View / UIKit）：
```
button.setColor(blue)      ← 我去找到按钮，命令它变色
label.setText("hello")     ← 我去找到标签，命令它改文字
```

Flutter 的思维：
```
state = { color: blue, text: "hello" }
↓
Widget build() { return ... }   ← UI 根据 state 重新计算
```

**关键差异**：Flutter 里你不修改 UI，你修改状态，UI 自己重算。

状态变了 → 对应的 Widget 重新 `build()` → 新界面。不需要"找到那个 Widget 然后改它"。

---

## 二、两条数据链路

Flutter 的数据流分读和写两条链路，不是同一条。

**读链路（订阅式，被动的）**
```
Screen (ref.watch)
  ↓ 订阅
StreamProvider / AsyncNotifierProvider
  ↓ 依赖
Repository.watch() → Drift → SQLite
  ↑
  └── 数据变化时自动推送 → UI 自动重建
```

**写链路（命令式，主动的）**
```
用户操作
  ↓
Screen (ref.read notifier / repository)
  ↓
Repository.write() → Drift 写入 SQLite
  ↓
Drift 自动通知所有 watch() 订阅者 → 读链路触发 → UI 重建
```

写操作完成后不需要手动刷新 UI——Drift 的 `watch()` 是响应式的，写入自动通知。

---

## 三、Widget 是轻量描述，不是 View 对象

命令式框架里，View 是重量级对象，创建成本高，要复用。

Flutter 的 Widget 是轻量的"描述"，`build()` 每次都重新创建 Widget 树，开销极小。

**组合优于继承**：Flutter 推荐嵌套 Widget 来扩展 UI，不推荐继承自定义。

```dart
// Flutter 风格：组合
Container(
  decoration: BoxDecoration(borderRadius: ...),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text('hello'),
  ),
)

// 不推荐：继承 Container 然后改样式
```

---

## 四、Flutter 自己绘制像素

Flutter 不使用系统 UI 组件（UIButton、UILabel）。它通过 Skia/Impeller 引擎在 Canvas 上自己绘制每一个像素。

这意味着：
- **Cupertino / Material** 是 Flutter 内置的设计语言实现，不是系统原生组件
- 同一套代码在 iOS / Android / macOS / Web 渲染结果高度一致
- 但也意味着无法直接复用系统的无障碍支持，需要手动添加 `Semantics`

---

## 五、Python 后端开发者类比

| Flutter | Python / FastAPI 类比 |
|---|---|
| `main.dart` + `app/bootstrap.dart` | 应用启动 + 环境初始化 |
| `app/router.dart`（go_router） | FastAPI 路由注册（`app.include_router`） |
| `core/database/`（Drift） | SQLAlchemy 数据库连接 + Base 模型定义 |
| `features/{f}/domain/`（数据类） | Pydantic 模型 + 业务规则 |
| `features/{f}/data/`（Repository + Provider） | Service 层 + Repository 层 |
| `features/{f}/presentation/`（Screen + Widget） | 路由 handler + 模板渲染 |
| `StreamProvider` + `ref.watch` | 类比 WebSocket 推送：数据变化自动推到客户端 |
| `ref.read(notifier).method()` | 类比 POST 请求：主动触发写操作 |

**核心不同**：FastAPI 是请求-响应模型，链路处理完就结束。Flutter 的 UI 始终活着，用响应式订阅替代轮询，数据变化自动推送。

---

*延伸阅读：架构分层 → [02-architecture.md](02-architecture.md) · 技术选型 → [03-stack.md](03-stack.md)*
