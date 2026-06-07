# 客户端工程方法论

> 本目录存放客户端应用开发相关的方法论；当前主要承载 Flutter 应用从需求、交互、界面、状态到运行验证的工程主干。

## 文档分类

### 正式方法论

- [`Flutter项目开发主干方法论.md`](Flutter项目开发主干方法论.md)
  用于把 Flutter 应用从需求、概念图、旧代码或模糊想法，推进到可运行、可验证、可持续迭代的工程主干。

- [`Flutter项目质检方法论.md`](Flutter项目质检方法论.md)
  用于判断 Flutter 项目的架构、状态、组件和代码组织是否支撑持续迭代。

- [`Flutter-0-1-项目开发/`](Flutter-0-1-项目开发/)
  用于承接 Flutter App 从想法、边界判断、首个核心链路到可运行可验收 MVP 的正式规范体系。

### 参考手册

- [`Flutter-学习速查与诊断手册/`](Flutter-学习速查与诊断手册/)
  用于学习 Flutter 心智模型、日常编码速查、常见问题诊断和 MVP 后演进参考；它不作为正式项目开发主线。

### 依赖推荐

- [`Flutter-依赖推荐/Flutter-通用完整依赖手册.md`](Flutter-依赖推荐/Flutter-通用完整依赖手册.md)
  用于记录 Flutter App 从架构到上线的通用依赖组合、取舍和阶段优先级。

- [`Flutter-依赖推荐/Flutter-日记-App-依赖推荐.md`](Flutter-依赖推荐/Flutter-日记-App-依赖推荐.md)
  用于记录日记 App 场景下不同能力的第三方依赖候选和推荐。

### 归档资料

- [`archived/Flutter-日记-App-第三方依赖推荐.md`](archived/Flutter-日记-App-第三方依赖推荐.md)
  旧版日记 App 第三方依赖推荐，保留作历史参考，不作为当前入口。

- [`archived/Flutter-日记-App-完整依赖手册.md`](archived/Flutter-日记-App-完整依赖手册.md)
  旧版日记 App 完整依赖手册，保留作历史参考，不作为当前入口。

### 学习与协作

- [`flutter-learning-resources.md`](flutter-learning-resources.md)
  用于维护 Flutter 学习资料、Codex skills、社区 skills 和参考项目。

## 维护边界

客户端工程方法论负责处理客户端应用的版本边界、架构、交互流程、界面表面、状态模型、原型验证、运行验证和回写治理。

它不作为新服务架构龙骨的挂载范式；当项目对象是 Flutter 客户端应用或 Flutter 子工程时，应直接使用本目录下的方法论。

本层目录通过 README 做轻量分类治理。正式方法论、依赖推荐、学习手册、参考分析和归档资料应保持入口清晰；新增或迁移文档后，需要同步更新本 README。
