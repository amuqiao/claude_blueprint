# FastAPI 后端 Prompt

适用场景：
- 新建一个 FastAPI 后端项目
- 为现有项目补一套清晰的 FastAPI 工程起盘方案
- 评审已有 FastAPI 后端结构是否合理

## 起盘版

```text
请帮我为这个项目整理一份“FastAPI 后端起盘方案”。

要求：
1. 统一按 FastAPI + uv 的工程方式组织，不要混用多套 Python 包管理和运行方式。
2. 至少说明这些内容：
   - 为什么适合用 FastAPI
   - 为什么统一用 uv
   - 推荐目录结构
   - 当前采用 4 层还是 5 层
   - 本地开发启动方式
3. 如果是默认 4 层，请明确：
   - api
   - services
   - repositories
   - core / integrations
   各自负责什么，不负责什么。
4. 如果已经出现 service 变胖、规则复用、状态机复杂等信号，再说明是否应该升级到 5 层。
5. 不要展开具体业务接口和字段设计；这一步只做工程起盘和架构定盘。

项目背景如下：
【把项目背景、技术栈约束、已有目录和目标贴在这里】
```

## 架构评审版

```text
请帮我评审这份 FastAPI 后端架构方案或当前工程结构。

重点检查：
1. 是否明确统一使用 uv，而不是混用 pip / poetry / venv。
2. 路由层、服务层、数据访问层是否边界清晰。
3. API 路由层是否直接写了业务逻辑或数据库操作。
4. repositories 是否只做数据访问，而不是承载业务流程判断。
5. 配置、日志、中间件、外部服务接入是否放在合适位置。
6. 当前结构是否仍适合 4 层，还是已经应该升级到 5 层。

输出要求：
1. 先给总体判断。
2. 再列高优先级问题。
3. 再列中优先级问题。
4. 最后给补强建议。

请优先指出结构性问题，不要停留在措辞或命名层面。

待评审内容如下：
【把目录、方案、代码片段或架构说明贴在这里】
```

## 工程约定速查

### 基本约定

- 依赖与元信息以 `pyproject.toml` 为准
- 新增依赖优先 `uv add`
- 同步环境优先 `uv sync`
- 运行服务、脚本、测试优先 `uv run`

### 推荐启动方式

```bash
uv run uvicorn app.main:app --reload
```

如果项目有统一脚本：
- 可以保留脚本入口
- 但脚本内部仍应围绕 `uv run` 组织

### 默认 4 层结构

```text
app/
├── main.py
├── api/
├── services/
├── repositories/
├── schemas/
├── models/
├── core/
└── integrations/
```

### 4 层职责

- `api/`：接收请求、校验参数、委托服务层
- `services/`：业务流程编排
- `repositories/`：封装数据库访问
- `core/` / `integrations/`：配置、日志、外部依赖与基础设施

### 升级为 5 层的信号

- `services/` 明显变胖
- 业务规则重复复用
- 状态机、权限、计费等核心规则不再适合混在 service 中

### 常用命令风格

```bash
uv sync
uv run uvicorn app.main:app --reload
uv run pytest
uv run python scripts/seed_demo.py
```
