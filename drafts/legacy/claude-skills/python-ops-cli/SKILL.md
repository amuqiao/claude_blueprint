---
name: python-ops-cli
description: 新建运维诊断 CLI 工具时调用；为现有工具新增子命令时对照。识别方法：需要跨层读取数据（DB、Redis、进程等组合），有只读诊断和可选写入两类操作，以子命令形式组织。触发词：运维脚本、诊断工具、诊断 CLI、fix-stuck、inspect、dry-run
---

# Python 运维 CLI 规范

> **文档职责**：定义跨项目可复用的 Python 运维诊断 CLI 工具标准，覆盖模块结构、子命令契约、数据访问分层、输出与变更控制规范；不含具体业务逻辑或项目特定的表名、服务地址。
> **适用场景**：新建运维诊断脚本前；为现有工具新增子命令或数据源时评审合规性；向 Claude 描述脚本需求前澄清标准。
> **目标读者**：全栈项目开发者及 Claude CLI；具备 Python 中级水平，了解 asyncio 基础与 argparse 用法。
> **维护规范**：新增子命令模式或数据访问模式时更新对应章节；项目特定的表名、Redis key、进程名等不写入本规范，在各脚本的常量区定义。

---

## 0. 与其他规范的边界

| 规范 | 适用场景 | 核心关切 |
|------|---------|---------|
| `shell服务管理规范.md` | `dev.sh` 类 Bash 脚本 | 进程生命周期（start/stop/restart） |
| `python脚本编写规范.md` | 批量 API 调用脚本 | Job 并发、重试、文件输出 |
| **本规范** | 运维诊断 CLI 工具 | 数据诊断、跨层查询、安全变更 |

**识别方法**：满足以下全部条件时适用本规范：
- 需要跨层读取数据（DB、消息队列、进程状态、日志等任意组合）
- 有"只读诊断"和"可选写入"两类操作
- 以子命令形式组织，每个子命令独立完整

---

## 1. 设计原则

| 原则 | 含义 |
|------|------|
| Hub-Spoke 结构 | 一个脚本文件是 Hub，每个子命令是 Spoke；Spoke 之间不互相调用 |
| 写操作默认安全 | 所有变更子命令默认 dry-run，需显式 `--apply` 才写入；读操作无此限制 |
| 数据分层访问 | DB 异步（独立连接）、外部服务同步、进程信息通过 subprocess；三者互不越界 |
| 项目根目录运行 | 脚本始终从项目根目录执行；`sys.path` 注入在模块顶部完成，对调用方透明 |
| 终端输出即文档 | 不生成报告文件；所有输出直接打印到终端，格式即时可读 |

---

## 2. 文件结构

模块内节顺序固定，不可调换：

1. 模块文档字符串（见 §3）
2. 标准库 import（按字母序）
3. 第三方库 import（按字母序）
4. `PROJECT_ROOT` 常量 + `sys.path` 注入
5. 项目内部 import（`from app.xxx import ...`）
6. 颜色常量（TTY 检测后赋值）
7. 项目常量（PID 文件路径、默认阈值等）
8. Dataclass 定义
9. 基础设施函数（数据库连接、外部服务客户端）
10. 工具函数（纯计算，无 I/O）
11. 数据访问函数（DB 查询、Redis 查询、进程信息）
12. 富化函数（跨数据源合并，无 I/O 副作用）
13. 子命令函数（`cmd_xxx` 或 `_cmd_xxx` 异步版）
14. `main()`
15. `if __name__ == '__main__': main()`

---

## 3. 模块文档字符串

必须包含以下各节，顺序固定：

| 节 | 内容 |
|----|------|
| 功能 | 工具做什么、列出所有子命令及一句话说明 |
| 依赖 | 所用第三方包（仅非标准库） |
| 运行方式 | 含完整命令（包括 `--project` 参数）和每条命令的注释说明 |

运行方式节固定格式（从项目根目录执行）：

```text
运行方式（在项目根目录执行）:

  # 注释说明
  uv run --project <dir> python scripts/<name>.py <subcmd> [选项]

  # 各子命令详细参数
  uv run --project <dir> python scripts/<name>.py <subcmd> --help
```

---

## 4. 运行上下文

### 路径与环境

脚本放在项目级 `scripts/` 目录，从**项目根目录**执行：

```bash
uv run --project <backend_dir> python scripts/<name>.py <subcmd>
```

`--project <backend_dir>` 的作用：指定包含依赖的子目录虚拟环境，使脚本可访问后端的 DB、Redis 等包，而不依赖项目根的环境。

### sys.path 注入

```python
PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "<backend_dir>"))

from app.core.config import settings  # noqa: E402
```

- `PROJECT_ROOT` 指向项目根目录（脚本所在 `scripts/` 的父目录）
- `sys.path` 注入必须在项目内部 import 之前完成
- `noqa: E402` 注释注明注入是注入顺序依赖，不是代码质量问题

---

## 5. 子命令契约

### argparse 结构

```python
parser = argparse.ArgumentParser(prog='<name>.py', description='...')
sub = parser.add_subparsers(dest='cmd', required=True)

# 只读子命令：无额外参数限制
sub.add_parser('inspect', help='...')

# 带参数的只读子命令
p = sub.add_parser('stuck', help='...')
p.add_argument('--min-age', type=int, default=30, metavar='MINUTES')

# 变更子命令：必须有 --apply 开关
p = sub.add_parser('fix-stuck', help='...')
p.add_argument('--apply', action='store_true', help='真正写入（不加则 dry-run）')
```

### 子命令命名约定

| 类型 | 命名 | 示例 |
|------|------|------|
| 列出 / 概览 | 名词 | `workers`、`queue` |
| 诊断单对象 | `inspect` | `inspect <id>` |
| 诊断批量 | 形容词 | `stuck`、`stale` |
| 变更 | `fix-` 前缀 | `fix-stuck`、`fix-stale` |

---

## 6. 数据访问分层

### DB（异步，独立连接）

每个 DB 函数独立创建并销毁连接，避免跨函数共享连接生命周期。以下示例基于 SQLAlchemy + asyncpg，其他异步 DB 库替换对应客户端，连接隔离原则不变：

```python
async def query_xxx(...) -> list[XxxRecord]:
    engine = create_async_engine(settings.DATABASE_URL, poolclass=NullPool)
    try:
        async with async_sessionmaker(engine, expire_on_commit=False)() as db:
            rows = (await db.execute(text("..."), {...})).fetchall()
    finally:
        await engine.dispose()
    return [...]
```

**规则**：
- 每个 DB 函数独立创建并销毁连接（无连接池，避免跨调用泄漏）
- 只用参数化查询加具名参数，不在此层做字符串拼接或业务判断
- 返回值为 dataclass 列表，不返回 ORM 对象或裸数据行

### 外部服务（同步）

```python
def get_redis() -> redis.Redis:
    return redis.from_url(settings.REDIS_URL, decode_responses=True)
```

- 客户端在函数内按需创建，不持有模块级实例
- `decode_responses=True` 统一返回字符串，避免 bytes 处理

### 进程信息（subprocess）

```python
result = subprocess.run(['ps', 'ax', '-o', 'pid=,ppid=,etime=,command='],
                        capture_output=True, text=True)
```

- 只读，不调用会修改进程状态的命令
- 进程 kill 等变更操作打印命令提示，由用户手动执行（不在脚本内自动执行）

### 富化（跨源合并）

```python
def enrich_with_redis(items: list[XxxRecord], r: redis.Redis) -> None:
    """从 Redis 拉取补充信息，原地写入 items。"""
    for item in items:
        meta = fetch_meta(r, item.external_id)
        if meta:
            item.external_status = meta.get('status')
```

- 富化函数无 I/O 副作用，只做数据合并
- 参数为已查询的 dataclass 列表，不再访问 DB

---

## 7. 变更控制

所有写入 DB 或外部服务的子命令遵循以下规则：

**默认 dry-run**：不加 `--apply` 时，打印将要执行的操作，不写入任何数据。

```python
async def _cmd_fix_xxx(items: list[XxxRecord], apply: bool) -> None:
    if not apply:
        print(f"\n{BOLD}[DRY RUN]  将被修改的记录：{RESET}\n")
        for item in items:
            print(f"  {item.id}  [{item.status}] → failed")
        print(f"\n{YELLOW}加 --apply 写入 DB。{RESET}")
        return

    # 真正写入
    engine = create_async_engine(settings.DATABASE_URL, poolclass=NullPool)
    try:
        async with async_sessionmaker(engine, expire_on_commit=False)() as db:
            for item in items:
                await db.execute(text("UPDATE ..."), {...})
                print(f"  {GREEN}✓{RESET} {item.id}")
            await db.commit()
    finally:
        await engine.dispose()
```

**规则**：
- dry-run 和 apply 共用同一个入口函数，`apply` 参数控制分支，不写两套逻辑
- dry-run 输出必须包含 `[DRY RUN]` 标记，与正常输出可区分
- `--apply` 写入完成后打印 `✓` 逐条确认，不只打印"完成"

---

## 8. 输出规范

### 颜色

```python
if sys.stdout.isatty():
    RED = '\033[0;31m'; GREEN = '\033[0;32m'; YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'; BOLD  = '\033[1m';  DIM    = '\033[2m'; RESET = '\033[0m'
else:
    RED = GREEN = YELLOW = BLUE = BOLD = DIM = RESET = ''
```

| 语义 | 颜色 |
|------|------|
| 成功 / 正常状态 | 绿色 |
| 警告 / 待确认 | 黄色 |
| 错误 / 异常状态 | 红色 |
| 信息 / 路径 / 链接 | 蓝色 |
| 辅助信息（ID、时间等） | DIM |
| 标题 / 强调 | BOLD |

### 只读子命令输出结构

```text
\n{BOLD}标题  （筛选条件说明）{RESET}\n

  {对象 ID}
    字段 1：值
    字段 2：值
    根因（如有）：{RED}错误描述{RESET}

{YELLOW}提示下一步操作（如有）{RESET}
```

### 变更子命令输出结构

dry-run：
```text
\n{BOLD}[DRY RUN]  将要执行的操作：{RESET}\n

  {对象 ID}  [{当前状态}] → {目标状态}
    原因：...

{YELLOW}加 --apply 写入 DB。{RESET}
```

apply：
```text
\n{BOLD}标记 N 条记录…{RESET}\n

  {GREEN}✓{RESET} {对象 ID}

{GREEN}完成。{RESET}
```

---

## 9. 错误处理

| 场景 | 处理方式 |
|------|---------|
| 查询对象不存在 | 打印 `{RED}未找到 <id>{RESET}`，`sys.exit(1)` |
| 外部服务连接失败 | 异常穿透到 `main()`，不捕获；让堆栈告诉用户哪里出错 |
| DB 写入失败 | 异常穿透；事务自动回滚 |
| 参数校验失败 | 由 argparse 处理，不自行捕获 |

---

## 10. 自检清单

**结构**
- [ ] 文件内节顺序与 §2 一致
- [ ] 文档字符串包含：功能 / 依赖 / 运行方式（含 `--project` 参数和注释）
- [ ] `sys.path` 注入在项目内部 import 之前

**子命令**
- [ ] 每个子命令有独立 `--help`
- [ ] 变更子命令均有 `--apply` 开关，不加时为 dry-run
- [ ] 变更子命令的 dry-run 输出含 `[DRY RUN]` 标记

**数据访问**
- [ ] DB 函数独立创建并销毁连接，不跨函数共享连接生命周期
- [ ] DB 函数只返回 dataclass，不返回 ORM 对象或裸 Row
- [ ] 富化函数无 DB / 外部服务调用，只做数据合并
- [ ] 进程变更操作（如 kill）只打印命令，不自动执行

**输出**
- [ ] 颜色通过 `sys.stdout.isatty()` 动态启用
- [ ] 只读输出无 `[DRY RUN]` 标记
- [ ] apply 写入逐条打印 `✓` 确认
