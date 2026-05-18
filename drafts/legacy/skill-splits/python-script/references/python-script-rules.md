# Python Script Rules

## 适用边界

这个真源只处理一类脚本：

- 输入是一批任务
- 核心操作是调用外部 API
- 最终为每个任务生成文件产物
- 难点集中在并发、重试、日志、报告和输出目录管理

如果核心问题是：

- 服务 start / stop / restart -> 用 `shell-service`
- 运维诊断 CLI、子命令、`--apply` -> 用 `python-ops-cli`

## 最小结构

推荐至少包含这些层次：

1. 模块文档字符串
2. `Config`
3. `Task`
4. `Job`
5. `Result`
6. 工具函数
7. `call_one`
8. `retry_call`
9. `build_job_list`
10. `write_report`
11. `_dry_run`
12. `main`

## 数据结构边界

- `Config`：运行参数和全局配置
- `Task`：用户意图或业务任务
- `Job`：单次 API 调用的完整上下文
- `Result`：单次调用的结果快照

规则：

- 层间优先传 dataclass，不传散装参数
- 一个参数只在一个层级定义，不做多层覆盖链
- `Job` 应足够表达单次调用与保存上下文

## 函数职责边界

- `call_one`：只做单次 API 调用和结果保存
- `retry_call`：只做重试和退避
- `build_job_list`：只做任务展开
- `write_report`：只做报告写出
- `main`：只做初始化、校验和编排

不要：

- 在 `call_one` 中塞重试逻辑
- 在 `main()` 中混入完整业务处理
- 在 `write_report` 中修改执行结果

## 并发规则

如果需要并发：

- 先完整构建 `jobs`
- 再进入 executor
- 某个 job 失败时，记录失败结果，但不阻断全部任务

优先目标：

- 并发策略清楚
- 失败后的继续策略清楚
- 最终统计和报告能复盘成功 / 失败情况

## 超时与重试

超时和重试都作用于单个 job，不作用于整个 task。

推荐做法：

- 在 `call_one` 处设置单次调用超时
- 在 `retry_call` 处统一处理可重试错误
- 对不可重试错误直接抛出

不要：

- 把 task 级失败和 job 级失败混在一起
- 把所有异常都吞掉

## 日志、输出与 dry-run

至少要明确：

- 输出目录放在哪
- 日志放在哪
- 报告是否生成
- `--dry-run` 做什么，不做什么

`--dry-run` 的最低要求：

- 不调 API
- 不写文件
- 打印配置摘要和 job 展开结果

## 当前判断

- 这类规则适合稳定放在 `skills/python-script/`
- archived 的批量脚本 prompt 只保留作历史派生物
- 如果未来你再写同类脚本，优先维护这里，再决定是否派生新 prompt
