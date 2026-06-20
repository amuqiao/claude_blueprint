---
description: 后端运行时排障脚本、Pod 内诊断入口与只读排查规则
---

# 运行时排障脚本规则

运行时排障脚本负责把线上或测试环境中的常见排查动作收敛成稳定命令，让维护者进入 K8s Pod shell、容器 shell 或等价运行环境后，可以快速查询状态、还原链路和定位下一步证据。它不是平台操作手册，也不是修复入口。

## 适用边界

当服务存在以下任一情况时，应提供运行时排障脚本：

- 有异步 Job、Worker、scheduler、队列、回调或长链路业务流程。
- 需要按业务 id、`job_id`、`request_id` 或 `trace_id` 串联 API、Worker、DB、日志和外部调用。
- 线上排障需要频繁进入 Pod shell 执行重复查询。
- 维护者需要在不阅读源码的情况下判断当前任务、接口或业务流程卡在哪一层。

运行时排障脚本默认假设维护者已经进入目标运行环境。它不负责说明如何登录 K8s 控制台、如何选择 namespace、如何进入 Pod，也不替代部署、发布、回滚或平台权限文档。

## 只读诊断面

排障脚本默认必须是只读诊断面，只提供 `inspect`、`list`、`show`、`timeline`、`health`、`env`、`version` 等查询动作。

默认禁止：

- 修改 DB 状态、重试 Job、补偿投递、删除消息或重放 callback。
- 创建真实业务任务、调用模型、写第三方系统或写对象存储。
- 依赖当前 Pod 本地文件作为状态权威。
- 在查询失败时静默降级为部分结果。

确实需要修复动作时，必须建立单独的修复入口或 runbook，并显式声明审批、确认、审计、目标范围和回滚方式。修复动作不得隐藏在默认排障命令中。

## 命令契约

排障脚本应提供稳定命令，而不是让维护者临时拼 SQL、grep 日志或读取源码。

异步 Job 服务至少提供：

```text
ops job list --status <status> --since <duration> --limit <n>
ops job show --job-id <id>
ops job timeline --job-id <id>
```

按业务复杂度可增加：

```text
ops job inspect --job-id <id>
ops flow inspect --request-id <id>
ops flow inspect --trace-id <id>
ops health
ops env
ops version
```

命令必须说明执行位置、输入参数、默认时间窗、默认 limit、输出格式和退出码。真实调用、写入检查、canary、重试、补偿和 callback 重放不属于默认运行时排障入口；如项目确实需要这些动作，必须放入独立验证或修复入口，并遵守外部集成规则的环境保护要求。

## 查询边界

所有查询必须有界：

- `list` 类命令必须支持时间窗、状态筛选、分页或 limit。
- 日志和 trace 查询必须输出检索条件和时间窗，不默认全量扫描。
- 单个 `job_id`、业务 id、`request_id` 或 `trace_id` 查询不到时应明确报错。
- DB、K8s API、日志平台或 trace 平台不可达时，必须标明证据缺失来源。

不要把“没有查到旁证”解释为“系统没有异常”。证据缺失应作为排障结果的一部分输出。

## 状态权威与旁证

对异步 Job 服务，DB 或等价持久化记录中的 Job 状态是权威事实；K8s、日志、trace、执行器、broker 和 Pod 本地信息只能作为过程旁证。

排障输出必须区分：

| 类型 | 示例 | 作用 |
| --- | --- | --- |
| 权威状态 | DB 当前 `status`、终态、更新时间、错误分类 | 判断业务状态 |
| 过程证据 | 状态迁移事件、心跳、重试、领取记录 | 还原生命周期 |
| 运行环境证据 | Pod、worker id、镜像版本、restart count | 判断运行位置和版本 |
| 可观测证据 | `request_id`、`trace_id`、日志查询条件 | 跳转到日志和 trace |

当 DB 与日志、trace、队列或 Pod 证据冲突时，脚本应报告状态不一致，不要替维护者静默选择一个事实源。

## Job 生命周期排查

`job timeline` 应尽量还原以下阶段：

- API 接收请求并创建 Job。
- Job 入库和投递消息。
- Worker 领取任务并进入 running。
- 业务处理阶段、心跳、重试和外部调用摘要。
- 结果持久化、callback 或终态副作用。
- `succeeded`、`failed` 等项目已定义终态。

如果项目只有 Job 当前行，没有状态迁移事件表或审计记录，脚本应明确说明生命周期证据不足。不要用猜测补全缺失阶段。

## 输出字段

排障输出字段必须来自对应能力的事实源，不在排障脚本中重新定义业务语义。通用输出至少包含查询对象、查询时间窗、执行环境和证据完整性；FastAPI 请求追踪字段读取 `../fastapi/observability/logging.md`，异步 Job 字段读取 `../jobs/async-job.md`，多 `job_type` 和执行计划字段读取 `../jobs/workflow-handler.md`。Python 排障 CLI 的 Typer 实现规则读取 `../typer/ops-cli.md`。

按能力适用时，输出可包含：

| 能力 | 字段来源 | 典型字段 |
| --- | --- | --- |
| 通用运行环境 | 部署和入口规则 | 服务名、环境、Pod 或实例、镜像版本、查询时间窗 |
| 请求追踪 | 可观测规则 | `request_id`、`trace_id`、路径、状态码、耗时 |
| 异步 Job | Job 状态规则 | `job_id`、`status`、创建时间、更新时间、错误分类 |
| 多 workflow | Workflow Handler 规则 | `job_type`、执行计划、work item、结果引用 |
| 幂等或外部调用 | Job 和外部集成规则 | `client_request_id`、外部目标摘要、回调状态 |

默认输出应脱敏，不展示密钥、token、完整请求体、隐私文本、完整供应商响应或大文件内容。需要进一步查看敏感信息时，应走单独授权入口。

脚本应支持人读和机读两种输出，例如 `table` 和 `json`。`json` 输出应保持字段稳定，便于后续接入 CI、AI 分析或运维平台。Python 项目的 `ops` 命令默认由 Typer 实现；shell 脚本可以作为门面，但不复制业务查询逻辑。

## K8s 运行环境

Pod 内排障脚本不得要求 cluster-admin 权限。需要读取 K8s 信息时，应使用当前 namespace 和当前 workload 范围内的最小只读权限，并清楚说明没有权限时哪些证据不可用。

脚本可以读取：

- 当前 namespace、Pod、container 和 service account。
- 当前 workload 下 Pod restart count、image tag、owner workload。
- 当前进程环境中的非敏感配置摘要。

默认禁止读取 Kubernetes Secret、完整 ConfigMap、跨 namespace 资源和集群级资源。需要这些信息时，应通过平台 runbook 或独立授权流程处理，不应由 Pod 内排障脚本直接读取。

脚本不应把当前 Pod 当成完整系统视角。异步 Job 可能跨 Pod、跨重启、跨版本流转；跨 Pod 排查应以 `job_id`、`request_id`、`trace_id`、`worker_id` 为锚点。

## 与可观测性的关系

运行时排障脚本消费可观测信号，不定义日志规则本身。FastAPI 服务的日志、请求追踪和排障信号由 `../fastapi/observability/logging.md` 定义。

脚本应输出可直接复制到日志或 trace 平台的查询条件：

- 关键 id。
- 时间窗。
- 服务名、Pod、worker 或 handler。
- 失败分类或事件名。

业务关键阶段应有稳定事件名，便于脚本和日志平台对齐。脚本不得依赖脆弱的自然语言日志 grep 作为唯一证据。

## 验证要求

新增或修改运行时排障脚本时，至少验证：

- 无参数或 `help` 输出命令说明。
- `list` 类命令有默认时间窗和 limit。
- 单个不存在的 `job_id` 会失败并给出明确原因。
- DB、K8s 或日志依赖不可达时不会 silent fallback。
- 生产环境默认只读；写入类、真实调用类或修复类命令不在默认排障入口中出现。
- shell 脚本通过语法检查；Python 或其他语言脚本通过最小单元测试或 smoke 测试。
