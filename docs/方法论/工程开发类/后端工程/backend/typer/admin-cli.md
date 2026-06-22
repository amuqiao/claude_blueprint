---
description: Typer 受控管理 CLI、写入动作、Job 创建与修复入口规则
---

# Typer 受控管理 CLI 规则

本规则定义 Typer 在只读排障之外承载受控写入、Job 创建、重试、补偿、callback 重放或 canary 的边界。默认运行时排障命令仍读取 `ops-cli.md`，本规则只适用于项目明确需要管理入口的场景。

## 适用边界

适用场景：

- 需要通过 CLI 创建真实 Job 或触发 canary。
- 需要手动重试、补偿投递、callback 重放或外部写回重放。
- 需要在测试、预发或生产环境执行带副作用的管理动作。
- 需要 CI 或运维平台消费稳定 JSON 输出和退出码。

不适用场景：

- 只读查询、timeline、health、env、version。
- 临时本地脚本。
- 未经审批的生产修复动作。

## 命令分层

Typer CLI 至少分为两个命令域：

| 域 | 默认副作用 | 示例 |
| --- | --- | --- |
| `ops` | 只读 | `ops job show`、`ops job timeline`、`ops health` |
| `admin` 或 `manage` | 显式写入或真实调用 | `admin job create`、`admin job retry`、`admin callback replay` |

写入命令不得混入默认 `ops` 域。命令名必须表达副作用，例如 `create`、`retry`、`replay`、`repair`、`canary`，不要用 `inspect`、`check`、`sync` 隐藏真实写入。

## 复用服务契约

CLI 创建 Job 或触发业务能力时，必须复用同一套服务层和注册表：

```text
Typer command
  -> Settings
  -> command input schema
  -> service / use case
  -> handler registry
  -> Job create flow / repository / publisher
```

禁止：

- Typer command 直接拼 SQL 创建或修改 Job。
- Typer command 绕过 handler registry 直接调用某个模型供应商。
- CLI 维护一套不同于 HTTP 的 `job_type`、错误码或 schema。
- CLI 为了方便读取另一套临时 `.env` 或直接访问 `os.environ`。

如果 CLI 和 HTTP 的输入形态不同，应定义 CLI command input schema，并明确它如何映射到同一个 operation 或 service use case。

## 写入保护

所有写入类命令必须声明：

- 目标环境和允许环境。
- 是否真实调用模型、写数据库、写对象存储、写第三方系统或发送 callback。
- 幂等键或重复执行保护。
- 审计事件和日志字段。
- 失败后的终态、错误码和退出码。
- 是否需要 `--confirm`、`--dry-run` 或审批工单号。

生产环境中，真实调用模型、创建 Job、补偿投递、callback 重放和第三方写回必须显式 opt-in。不得让生产写入动作成为无参数默认行为。

## 重试与补偿

重试、补偿和重放不是普通 Job 状态机的隐式 fallback。项目支持这些动作时，必须先定义 runbook 或管理命令契约。

至少明确：

- 允许处理哪些状态，例如 orphan queued、未确认发布、callback failed。
- 不允许覆盖 `succeeded` 或 `failed` 业务终态，除非项目有独立人工修复模型。
- 如何使用 CAS、行锁或唯一约束防止重复补偿。
- 补偿动作产生哪些生命周期事件。
- Typer 输出如何区分“已补偿”“无需补偿”“证据冲突”“依赖不可达”。

当状态权威与旁证冲突时，管理命令必须失败并输出冲突证据，不得自动选择一个事实源继续写入。

## 输出与退出码

管理命令必须支持 `--format json`。JSON 输出至少包含：

- `operation_id` 或命令 id。
- `request_id` 或 `trace_id`；没有 HTTP 请求时也应生成命令级追踪 id。
- 目标对象，例如 `job_id`、`job_type`、`callback_event_id`。
- `dry_run`、`changed`、`status`。
- 错误码、子错误码和 `retryable`。
- 审计事件 id 或 lifecycle event id。

退出码可以复用 `ops-cli.md` 的只读退出码，并为写入场景增加项目约定；但必须稳定，不得把证据缺失、状态冲突或部分成功都压成 `0`。

## 验收要求

新增或修改管理命令至少验证：

- `--help` 输出副作用、环境限制和必要参数。
- `--dry-run` 不写 DB、不投递消息、不调用模型、不发送 callback。
- 生产环境缺少显式确认时失败。
- 重复执行使用幂等键或 CAS 保护。
- 状态权威与旁证冲突时失败。
- JSON 输出字段和退出码稳定。
