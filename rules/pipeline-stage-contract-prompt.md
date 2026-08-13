---
description: 设计可编排、可替换、可观测 pipeline 时使用的 stage contract、adapter contract 与观测事件规则
---

# Pipeline Stage Contract 提示词规则

这份规则用于设计或重构复杂流程的 stage contract、adapter contract 和观测事件，让后续替换实现、增加 batch、引入并发、下沉外部服务或调整运行策略时仍然可以对账。

## 文档职责

本文负责沉淀一套可复用提示词，用于回答：

```text
一条 pipeline 的 stage 应该如何定义？
每个 stage 的输入输出、前置条件、后置条件、失败语义如何固定？
哪些实现细节应该抽成 adapter？
日志、指标、trace 如何按同一套字段关联？
如何保证非计算节点也可观测？
如何避免为了“pipeline 化”而过度工程化？
```

本文不负责：

- 还原一个未知系统当前到底怎么运行。
- 判断瓶颈在哪里。
- 给出性能优化优先级。
- 绑定某个业务、框架、云厂商、日志系统、模型服务或部署平台。
- 要求引入 pipeline framework、DAG engine、workflow engine 或复杂运行时。

## 使用时机

适合使用：

- 已经准备给现有流程补统一 stage 合同和观测口径。
- 已经知道哪些步骤属于主流程，但缺少稳定节点边界。
- 即将替换某个实现，例如本地实现换远程服务、同步实现换 batch、单线程换并发。
- 当前只有部分计算节点可观测，下载、转换、上传、回调、清理等节点仍是黑盒。
- 希望先固定合同，再逐步调整实现。

不适合使用：

- 系统现状还不清楚。
- 只是单函数、小模块或一次性脚本。
- 当前只有明确 bug 修复，不涉及 stage 边界和观测口径。
- 没有替换、编排、观测或回归对账需求。

## 核心原则

Stage 是业务流程节点，Adapter 是可替换实现或外部依赖。

```text
Stage 说明：流程现在走到哪一步。
Adapter 说明：这一步具体由谁执行。
```

不要只把算法、模型、计算节点定义为 stage。只要一个步骤会消耗时间、改变数据形态、调用外部依赖、产生副作用、影响结果或影响失败语义，它就应该有 stage contract。

最小可接受目标：

```text
所有关键节点都有统一 stage 事件。
所有外部依赖或可替换实现都有 adapter call 事件。
每次运行最终都有 timing summary。
业务输出合同不因 stage 化而改变。
```

## 主提示词

可直接复制下面的提示词，并替换方括号内容。

```text
请为这个流程设计一套可编排、可替换、可观测的 pipeline contract。

不要重新分析系统现状，不要给性能优化优先级，也不要引入大型框架。重点是定义 stage contract、adapter contract、观测事件、失败语义和渐进落地方式。

设计对象：
[说明要整理的流程、任务、模块或系统]

已知流程节点：
[列出现有或目标流程节点；如果有分支、可选节点、清理节点，也写出来]

必须保持不变的外部合同：
[业务输出、API schema、消息格式、文件格式、数据库写入、回调语义、错误语义等]

可能替换或调整的实现：
[本地/远程、同步/batch、串行/并发、某个库/服务/工具/存储/模型/外部 API]

请输出以下内容：

1. 设计边界
- 这套 pipeline contract 解决什么问题？
- 哪些行为必须保持不变？
- 哪些实现可以替换？
- 哪些节点不应该被搬迁、隐藏或抽象过度？
- 最小落地版本是什么？

2. Stage Contract Matrix
为每个 stage 定义合同。每行至少包含：
- stage_id
- stage kind
- owner
- purpose
- preconditions
- input_summary_schema
- output_summary_schema
- side_effects
- downstream_consumers
- postconditions
- ordering_key / alignment_key
- idempotency
- timeout
- retry_boundary
- failure_behavior
- observability_events

3. Adapter Contract Matrix
为每个可替换实现或外部依赖定义 adapter。每行至少包含：
- adapter_id
- used_by_stage
- backend
- operation
- input contract
- output contract
- timeout
- retry policy
- error mapping
- call-level observability
- replacement constraints

4. Event Schema
设计统一事件格式，至少包含：
- stage completed
- stage failed
- adapter call completed
- adapter call failed
- pipeline timing summary

明确哪些字段必填，哪些字段可选，哪些字段禁止记录。

5. Stage State Machine
定义 stage 状态机：
- pending
- running
- completed
- failed
- skipped

说明 skipped 什么时候允许，failed 是否允许重试，cleanup 如何记录，cleanup 失败是否覆盖原始失败。

6. Error Taxonomy
定义错误分类：
- input_contract_error
- output_contract_error
- dependency_error
- timeout
- resource_exhausted
- consistency_error
- implementation_bug

说明每类错误是否 retryable，是否应暴露给上游，是否应触发 cleanup。

7. Observability Rules
定义日志、指标、trace 的分工：
- 日志记录单次运行事实。
- 指标用于聚合耗时、数量、失败率。
- trace 负责跨服务或跨 adapter 关联。

说明 run_id、trace_id、stage_id、adapter_id、attempt 的关联规则。
说明基数控制、敏感信息处理、采样和大对象摘要规则。

8. Composition Rules
说明这条 pipeline 如何可编排：
- 哪些 stage 必须串行？
- 哪些 stage 可以并发？
- 哪些 stage 可以 batch？
- 哪些 stage 可以流式？
- 替换 adapter 时哪些合同必须不变？
- 如何保证输出顺序、时间轴、ID、索引或分组对齐？

9. Contract Review Checklist
输出 review 清单，用于检查未来改动是否破坏 pipeline contract。

10. Rollout Plan
输出渐进落地步骤。每一步必须说明：
- 改动范围
- 不变合同
- 验证方式
- 回退方式
```

## Stage Contract 设计规则

Stage contract 是设计产物，不只是日志字段表。它应该固定这个节点的行为边界。

| 字段 | 说明 |
| --- | --- |
| `stage_id` | 稳定、可搜索、可聚合的节点名。使用 snake_case，不带实现名。 |
| `kind` | 节点类型，例如 `io`、`parse`、`transform`、`compute`、`model`、`storage`、`orchestration`。 |
| `owner` | 代码或团队责任边界。 |
| `purpose` | 节点存在的业务理由。 |
| `preconditions` | 进入节点前必须满足的条件。 |
| `input_summary_schema` | 输入摘要 schema，只描述规模、shape、count、host、key、配置摘要。 |
| `output_summary_schema` | 输出摘要 schema，只描述规模、shape、count、状态、是否存在。 |
| `side_effects` | 文件、数据库、缓存、网络、消息、状态回写等副作用。 |
| `downstream_consumers` | 直接消费该节点输出的下游节点或系统。 |
| `postconditions` | 节点完成后必须保证的条件。 |
| `ordering_key` | 需要保持顺序时的排序键。 |
| `alignment_key` | 多路数据需要对齐时的 ID、索引、时间戳或分组键。 |
| `idempotency` | 重跑是否安全，重复副作用如何处理。 |
| `timeout` | 节点级超时或必须由 adapter 承担的超时。 |
| `retry_boundary` | 哪些错误可以重试，重试是否会重复副作用。 |
| `failure_behavior` | 失败后是否终止 pipeline、是否 cleanup、是否写终态。 |
| `observability_events` | 该节点必须发出的事件。 |

Stage 命名要求：

```text
使用业务节点名，不使用实现名。
使用稳定动宾或名词短语。
不要把 backend 写进 stage_id。
不要用 step1、process、handle、do_work 这类无法聚合的名称。
```

示例：

```text
好的 stage_id:
  download_inputs
  parse_source
  transform_records
  compute_features
  score_candidates
  persist_result
  notify_completion
  cleanup_workspace

不好的 stage_id:
  step1
  run_model_v2
  call_http_api
  process
  do_stuff
```

## Adapter Contract 设计规则

Adapter contract 固定可替换实现的边界。它不应该泄露业务流程，也不应该吞掉底层错误。

| 字段 | 说明 |
| --- | --- |
| `adapter_id` | 稳定 adapter 名称。 |
| `used_by_stage` | 被哪个 stage 使用。 |
| `backend` | 当前实现，例如 `local`、`http`、`grpc`、`subprocess`、`database`、`object_storage`。 |
| `operation` | 具体操作。 |
| `input_contract` | adapter 接收的结构、shape、count、大小限制。 |
| `output_contract` | adapter 返回的结构、shape、count、顺序语义。 |
| `timeout` | 单次调用超时。 |
| `retry_policy` | 重试次数、退避、哪些错误可重试。 |
| `error_mapping` | 底层错误如何映射到 pipeline error taxonomy。 |
| `call_observability` | 单次调用需要记录的字段。 |
| `replacement_constraints` | 替换 backend 时必须保持的行为。 |

Adapter 替换必须保持：

```text
输入 schema 不变。
输出 schema 不变。
输出顺序不变。
错误分类不变。
幂等语义不变。
超时和重试边界可解释。
```

## Event Schema

### Stage Completed

```json
{
  "event": "pipeline_stage_completed",
  "pipeline": "example_pipeline",
  "run_id": "run-001",
  "trace_id": "trace-001",
  "stage_id": "transform_records",
  "kind": "transform",
  "status": "completed",
  "attempt": 1,
  "elapsed_ms": 248.7,
  "input_summary": {
    "record_count": 1000,
    "schema_version": "v1"
  },
  "output_summary": {
    "record_count": 1000,
    "invalid_count": 0
  },
  "counters": {
    "batch_count": 10
  }
}
```

### Stage Failed

```json
{
  "event": "pipeline_stage_failed",
  "pipeline": "example_pipeline",
  "run_id": "run-001",
  "trace_id": "trace-001",
  "stage_id": "persist_result",
  "kind": "storage",
  "status": "failed",
  "attempt": 1,
  "elapsed_ms": 1200.4,
  "input_summary": {
    "record_count": 1000,
    "target": "primary_store"
  },
  "output_summary": {},
  "error": {
    "category": "dependency_error",
    "type": "DatabaseUnavailable",
    "message": "primary store unavailable",
    "retryable": true
  }
}
```

### Adapter Call Completed

```json
{
  "event": "pipeline_adapter_call_completed",
  "pipeline": "example_pipeline",
  "run_id": "run-001",
  "trace_id": "trace-001",
  "stage_id": "score_candidates",
  "adapter_id": "candidate_scorer",
  "backend": "http",
  "operation": "score_batch",
  "attempt": 1,
  "elapsed_ms": 184.2,
  "input_summary": {
    "batch_size": 32,
    "payload_bytes": 65536,
    "endpoint_host": "scoring.internal"
  },
  "output_summary": {
    "result_count": 32,
    "response_bytes": 8192
  },
  "timeout_ms": 30000
}
```

### Pipeline Timing Summary

```json
{
  "event": "pipeline_timing_summary",
  "pipeline": "example_pipeline",
  "run_id": "run-001",
  "trace_id": "trace-001",
  "status": "completed",
  "total_ms": 617000,
  "stages": {
    "ingest_inputs": 15643,
    "parse_source": 78,
    "transform_records": 21550,
    "compute_features": 2830,
    "score_candidates": 455800,
    "persist_result": 12060,
    "notify_completion": 30,
    "cleanup_workspace": 40
  },
  "counters": {
    "input_count": 2,
    "record_count": 3568,
    "candidate_count": 89,
    "batch_count": 83,
    "adapter_call_count": 306
  },
  "backends": {
    "score_candidates": "http",
    "persist_result": "database"
  }
}
```

## 观测体系设计规则

### 日志、指标、Trace 分工

| 类型 | 职责 | 不应承担 |
| --- | --- | --- |
| 日志 | 单次运行事实、输入输出摘要、失败上下文。 | 长期统计和高基数聚合。 |
| 指标 | stage 耗时分布、失败率、吞吐、调用次数、队列长度。 | 保存完整上下文和大对象。 |
| Trace | 跨服务、跨 adapter、跨异步边界关联。 | 替代业务日志或完整结果存储。 |

关联字段规则：

```text
run_id 标识一次业务运行。
trace_id 标识跨服务追踪。
stage_id 标识 pipeline 节点。
adapter_id 标识可替换实现。
attempt 标识同一 stage 或 adapter 的第几次尝试。
```

### 基数控制

不要把这些字段直接作为指标 label：

```text
完整 URL
用户输入原文
文件路径全量
对象 key 全量
错误 message 全量
动态 ID
shape 之外的大对象内容
```

适合进入指标 label 的字段：

```text
pipeline
stage_id
kind
status
backend
error_category
retryable
```

### 摘要规则

日志应记录摘要，不记录大对象。

```text
记录 count，不记录完整 list。
记录 bytes，不记录完整 body。
记录 host，不记录带签名 URL。
记录 shape，不记录完整 tensor。
记录 schema_version，不记录完整 schema。
记录 key_prefix 或 bucket，不记录完整敏感 object key。
```

## Stage State Machine

推荐状态机：

```text
pending -> running -> completed
pending -> skipped
running -> failed
failed  -> cleanup_requested
cleanup_requested -> cleanup_completed
cleanup_requested -> cleanup_failed
```

规则：

- `skipped` 只能用于明确可选节点，并且必须记录 skip reason。
- `failed` 必须保留原始错误，后续 cleanup 失败不能覆盖原始错误。
- retry 后的 attempt 必须递增。
- stage 级 retry 和 adapter 级 retry 要分开记录。
- 如果 stage 有副作用，必须说明 retry 是否幂等。

## Error Taxonomy

| 分类 | 含义 | 默认 retryable |
| --- | --- | --- |
| `input_contract_error` | 输入不满足 stage 或 adapter 合同。 | 否 |
| `output_contract_error` | 下游收到的输出不满足合同。 | 否 |
| `dependency_error` | 外部依赖不可用或返回错误。 | 视情况 |
| `timeout` | stage 或 adapter 超时。 | 视情况 |
| `resource_exhausted` | 内存、磁盘、连接、配额、并发限制不足。 | 视情况 |
| `consistency_error` | 顺序、对齐、幂等、一致性被破坏。 | 否 |
| `implementation_bug` | 代码 bug、未定义变量、断言失败等。 | 否 |

不允许把所有错误都归为 `internal_error`。错误分类要能指导 retry、告警和回滚。

## Composition Rules

设计可编排 pipeline 时，每个 stage 都要回答：

| 问题 | 必须说明 |
| --- | --- |
| 串行 | 为什么必须等待上游完整输出？ |
| 并发 | 并发单位是什么，如何合并结果？ |
| batch | batch 维度是什么，是否要求同 shape、同 schema、同长度？ |
| 流式 | 是否能边产生边消费，如何处理顺序和失败？ |
| 下沉 | 搬到外部服务后，输入输出合同如何保持？ |
| 替换 | 换 adapter 后，哪些字段、顺序、错误分类不变？ |
| 对齐 | 多路数据按什么键对齐？ |

如果无法清楚回答，就不要先做并发、batch 或下沉。

## Contract Review Checklist

用于 review 后续改动：

- 是否新增、删除或重命名 stage？
- stage_id 是否稳定、可聚合？
- 是否改变了 stage 输入输出合同？
- 是否改变了业务输出合同？
- 是否改变了顺序、对齐、幂等或失败语义？
- 是否新增外部依赖但没有 adapter contract？
- 是否新增 adapter 但没有 call-level 观测？
- 是否所有关键 stage 都有 completed / failed 事件？
- 是否最终 summary 能解释总耗时？
- 是否把大对象或敏感信息写进日志？
- 是否混用了 stage retry 和 adapter retry？
- cleanup 是否可能覆盖原始错误？
- 回滚后旧 adapter 是否还能满足同一输出合同？

## 渐进式落地

推荐最小步骤：

1. 命名所有关键 stage，不改业务逻辑。
2. 为每个 stage 增加 completed / failed 事件。
3. 增加 pipeline timing summary。
4. 为最重或最容易替换的依赖定义 adapter contract。
5. 为 adapter 增加 call-level 事件。
6. 补指标和 trace 关联字段。
7. 固定 contract review checklist。
8. 只有过程式编排开始阻碍维护时，才考虑 stage class、runner 或策略模型。

最小实现形态可以只是函数和统一打点：

```python
def run_pipeline(input_data):
    with stage("ingest_inputs", kind="io", input_summary=...):
        sources = ingest_adapter.fetch(input_data)

    with stage("transform_records", kind="transform", input_summary=...):
        records = transform(sources)

    with stage("score_candidates", kind="compute", input_summary=...):
        scores = scoring_adapter.score_batch(records)

    emit_timing_summary()
    return pack_result(scores)
```

不需要第一步就实现完整 pipeline runtime。

## 禁止事项

- 不要只给计算节点设计 stage contract。
- 不要让下载、转换、持久化、通知、cleanup 继续黑盒。
- 不要用 backend 名称当 stage_id。
- 不要把完整 URL、密钥、大对象、完整 tensor、完整业务结果写进日志。
- 不要让 adapter silent fallback 返回空结果。
- 不要用默认值掩盖 schema、shape、顺序或对齐错误。
- 不要把所有错误吞成一个通用内部错误。
- 不要没有 summary，只留散点 stage 日志。
- 不要在没有明确合同的情况下做并发、batch 或下沉。
- 不要为了“可扩展”提前引入复杂 framework。

## Few-shot 正例：整理一个文档处理任务

下面是示例，不是主规则。它使用通用文档处理任务，避免绑定具体业务。

### 用户输入示例

```text
这个文档处理 job 已经跑通。流程包含 ingest、parse、chunk、embed、rank、persist、notify 和 cleanup。
后续可能把 embed 从本地库替换成远程服务，并对 chunk 做 batch。
请设计 stage contract、adapter contract 和观测事件，不要改业务输出合同。
```

### 合格回答示例

#### Stage Contract Matrix

| stage_id | kind | preconditions | output_summary_schema | postconditions | retry_boundary |
| --- | --- | --- | --- | --- | --- |
| `ingest_inputs` | `io` | source refs valid | `document_count`、`total_bytes` | local refs created | dependency errors retryable |
| `parse_documents` | `parse` | local refs exist | `page_count`、`text_bytes` | parsed text ordered | parse contract errors not retryable |
| `chunk_documents` | `transform` | parsed text ordered | `chunk_count`、`chunk_schema_version` | chunks preserve document order | deterministic retry safe |
| `embed_chunks` | `compute` | chunks available | `embedding_count`、`dimension` | output aligns to chunk_id | adapter timeout retryable |
| `rank_candidates` | `compute` | embeddings available | `candidate_count` | rank order deterministic | implementation errors not retryable |
| `persist_result` | `storage` | result packed | `row_count`、`object_count` | durable result available | idempotency key required |
| `notify_completion` | `orchestration` | durable result available | `notification_sent` | downstream notified | retry with event id |
| `cleanup_workspace` | `orchestration` | terminal state known | `deleted_count` | temp files removed | must not hide original error |

#### Adapter Contract Matrix

| adapter_id | used_by_stage | backend | input contract | output contract | replacement constraints |
| --- | --- | --- | --- | --- | --- |
| `source_fetcher` | `ingest_inputs` | `http` / `storage` | refs、timeout | local refs、bytes | preserve ref order |
| `embedding_provider` | `embed_chunks` | `local` / `remote` | `[B, text]` | `[B, dimension]` | output order aligns to input chunk order |
| `result_store` | `persist_result` | `database` / `object_storage` | packed result、idempotency key | durable ids | duplicate write safe |
| `notifier` | `notify_completion` | `queue` / `http` | event id、result ref | accepted status | event idempotency preserved |

#### Event Schema 示例

```json
{
  "event": "pipeline_stage_completed",
  "pipeline": "document_processing",
  "run_id": "run-001",
  "trace_id": "trace-001",
  "stage_id": "embed_chunks",
  "kind": "compute",
  "status": "completed",
  "attempt": 1,
  "elapsed_ms": 8420.5,
  "input_summary": {
    "chunk_count": 512,
    "batch_size": 32
  },
  "output_summary": {
    "embedding_count": 512,
    "dimension": 1536
  },
  "counters": {
    "batch_count": 16,
    "adapter_call_count": 16
  }
}
```

#### Summary 示例

```json
{
  "event": "pipeline_timing_summary",
  "pipeline": "document_processing",
  "run_id": "run-001",
  "status": "completed",
  "total_ms": 42800,
  "stages": {
    "ingest_inputs": 2400,
    "parse_documents": 6100,
    "chunk_documents": 300,
    "embed_chunks": 8420,
    "rank_candidates": 980,
    "persist_result": 1200,
    "notify_completion": 180,
    "cleanup_workspace": 90
  },
  "counters": {
    "document_count": 4,
    "page_count": 128,
    "chunk_count": 512,
    "embedding_batch_count": 16
  }
}
```

这个 few-shot 的重点是：所有流程节点都有合同，外部实现通过 adapter 替换，观测事件可以解释总耗时和结果规模。
