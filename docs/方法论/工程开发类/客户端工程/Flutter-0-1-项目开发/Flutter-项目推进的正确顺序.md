# Flutter 项目推进的正确顺序

> 本文描述的是 Flutter App 从 MVP 边界确定后，到首个可运行、可验证版本之间的内部推进步骤。

这里的“阶段 0 / 阶段 1 / 阶段 2 ...”是 **MVP 开发主线内部步骤**，不是 `0-1 / 1-100` 的项目阶段划分。进入本文之前，如果还不确定当前问题属于项目起盘、版本收敛、功能模块、基础设施还是治理回写，先读 `Flutter-项目开发调度范式.md`。

```
阶段 0：技术选型
-> 状态管理选哪个（Riverpod / Bloc / Provider）
-> 本地数据库选哪个（Drift / Isar / Hive）
-> 导航方案（GoRouter / Navigator 2.0）
-> 图片/资源缓存（cached_network_image / flutter_cache_manager）
-> 选定后写进 Tech Decision 文档，不要边做边换

阶段 1：写 Slice 设计文档
-> 交互语义
-> 状态矩阵
-> 验收条件

阶段 2：写组件架构文档
-> 每个页面的组件树
-> 每个组件的职责边界
-> 状态流向图
-> 这一步完成前不要开始写 Widget

阶段 3：实现核心数据层
-> 数据模型
-> Repository
-> Provider/Bloc
-> 先跑通数据，不碰 UI

阶段 4：实现 UI 层
-> 从叶子组件开始（ItemCard）
-> 再组装容器组件（ItemListSection）
-> 最后接入页面层（ListScreen）

阶段 5：验收
-> 对照 Slice 验收条件逐条检查
-> 跑集成测试
```

---

## 关于第三方依赖

Flutter 生态有几个选型会直接影响组件架构，需要在阶段 0 锁定：

| 类别 | 影响 | 建议 | 如果选错了代价是什么 |
|------|------|------|------|
| 状态管理 | 决定状态如何在组件间流动 | Riverpod，和 Flutter 架构契合度高 | 换选型 = 重写所有 Provider 和页面状态层 |
| 本地数据库 | 决定数据层接口形态 | Drift（类型安全，适合复杂查询） | 换数据库 = 重写所有 Repository 和 migration |
| 导航 | 决定页面组件边界 | GoRouter | 换导航 = 重构所有页面入口和参数传递 |
| 滚动定位 | 直接影响列表实现方案 | scrollable_positioned_list 或原生 GlobalKey | 换方案 = 重构列表组件结构 |
| 图片/资源缓存 | 决定图片组件、占位状态和缓存清理方式 | cached_network_image / flutter_cache_manager | 换缓存方案 = 重构图片展示组件和资源生命周期管理 |
