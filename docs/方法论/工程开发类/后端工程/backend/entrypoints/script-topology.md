---
description: 后端项目脚本入口、子目录拆分与职责拓扑规则
---

# 脚本拓扑规则

脚本拓扑规则负责约束项目脚本从少量命令演进到多入口、多环境、多验证任务时如何拆分。它只定义脚本结构和调用关系，不替代项目入口契约、部署规则、外部集成保护或具体脚本实现。

## 拆分时机

脚本入口按复杂度渐进演进：

```text
README 命令
  -> scripts/dev.sh
  -> scripts/dev.sh + scripts/verify.sh
  -> scripts/dev.sh + scripts/verify.sh + scripts/deploy.sh
  -> 稳定门面脚本 + 子目录原子脚本 + scripts/lib/
```

不要因为未来可能复杂而提前铺满脚本目录；也不要在脚本已经承担多种职责后继续把所有逻辑塞进单个 `dev.sh`。

## 推荐拓扑

当项目已经有本地服务、验证、部署、工具脚本时，推荐使用以下拓扑：

```text
scripts/
  dev.sh              本地服务生命周期入口
  verify.sh           一次性验证入口
  qa.sh               按环境编排验证入口，可选
  deploy.sh           compose 或部署形态入口
  ops.sh              运行时只读排障入口，可选
  lib/common.sh       shell 公共函数
  dev/                本地服务原子能力
  verify/             验证原子脚本和 fixtures
  deploy/             发布、环境或分支推进脚本
  tools/              可重复辅助工具
  poc/                POC、数据准备或探索脚本
```

目录是否创建取决于真实复杂度。没有对应职责时不要空建目录。

## 门面与原子脚本

门面脚本负责承载稳定入口，原子脚本负责承载单一动作。

| 类型 | 负责 | 不负责 |
| --- | --- | --- |
| 门面脚本 | 路由命令、组合原子脚本、保持入口稳定 | 承载大量业务实现、复制原子脚本细节 |
| 原子脚本 | 启动单个服务、执行单类检查、生成单类 fixture、推进单个固定步骤 | 反向依赖门面脚本、隐式调用 POC 或临时工具 |
| `scripts/lib/` | 公共 shell 函数、路径解析、日志输出工具 | 保存项目业务流程或环境专属策略 |

命令名称、成功标准、状态输出和保护边界由 [`project-entrypoints.md`](project-entrypoints.md) 负责。脚本拓扑只保证这些入口不会散落成多个事实源。

## 职责拆分

常见脚本职责应拆开维护：

| 入口 | 职责 | 不负责 |
| --- | --- | --- |
| `scripts/dev.sh` | 本地服务生命周期门面 | 远端环境、生产发布、一次性业务验证 |
| `scripts/verify.sh` | 测试、smoke、配置检查、依赖连通性检查门面 | 启停完整本地服务栈、环境发布 |
| `scripts/qa.sh` | 按 `local/test/prod` 编排已有验证能力 | 实现测试逻辑、替代 `verify.sh` 原子入口 |
| `scripts/deploy.sh` | compose 或已验收部署形态门面 | 本地开发服务生命周期、生产平台点击操作 |
| `scripts/deploy/*.sh` | 固定分支、固定环境或固定发布链路原子步骤 | 日常 dev 工作流、通用开发入口 |
| `scripts/ops.sh` | Pod、容器或远端运行环境中的只读排障门面，可转发到 Typer CLI | 修复 Job、修改 DB、替代部署或回滚入口、复制 Typer 命令实现 |

同一能力只能有一个事实入口。README、AGENTS.md 和部署文档应链接入口，不重复维护脚本正文。

## 外部规则引用

脚本拓扑遇到以下问题时只引用外部规则，不在本文件重复定义：

- 命令契约、状态输出和危险命令命名：见 [`project-entrypoints.md`](project-entrypoints.md)。
- 运行时只读排障脚本、Pod 内诊断和 Job 生命周期查询：见 [`runtime-troubleshooting.md`](runtime-troubleshooting.md)。
- Python 排障 CLI 的命令实现、输出格式和退出码：见 `../typer/ops-cli.md`。
- 部署形态、Compose 配置顺序和发布后验收：见 `../deployment/service-deployment.md`。
- 生产真实调用、生产写入、跳过 TLS 校验等外部风险保护：见 `../integrations/external-service.md`。

## 拓扑验证

脚本拓扑变更后至少确认：

- 门面脚本引用的原子脚本真实存在。
- 被移动的脚本没有留下第二个事实入口。
- shell 文件通过语法检查。
- README、AGENTS.md 或入口文档仍指向稳定门面，而不是散落的原子脚本。
