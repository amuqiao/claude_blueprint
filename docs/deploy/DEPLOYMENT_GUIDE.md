# 配置文件加载指南

## 三种部署方式对比

### 方式 1: Docker Compose 部署（推荐生产环境）

**特点：** 一键启动所有服务（API + Worker + Flower + PostgreSQL + Redis）

#### 使用默认配置（.env）
```bash
docker compose up -d --build
```

#### 指定配置文件（.env.dev）
```bash
ENV_FILE=.env.dev docker compose up -d --build
```

#### 配置加载优先级
```
docker-compose.yml 中的 environment 块（最高优先级）
  ↓ 覆盖
${ENV_FILE} 指定的文件（.env.dev）
  ↓ 如果未指定 ENV_FILE
.env（默认）
```

#### 实际被覆盖的配置
- `DATABASE_URL` → 固定为 `postgres:5432`（容器内网络）
- `REDIS_URL` → 固定为 `redis:6379`（容器内网络）

---

### 方式 2: 本地开发部署（dev.sh）

**特点：** 仅启动 Python 服务（API + Worker + Flower），依赖外部 PostgreSQL/Redis

#### 使用默认配置（.env）
```bash
./dev.sh start
```

#### 指定配置文件（.env.dev）
```bash
ENV_FILE=.env.dev ./dev.sh start
```

#### 配置加载逻辑（dev.sh 第 47-81 行）
```bash
resolve_env_file() {
    if [[ -n "${ENV_FILE:-}" ]]; then
        echo "$ENV_FILE"      # 优先用 ENV_FILE
    else
        echo ".env"           # 默认用 .env
    fi
}
```

#### 依赖的外部服务
```bash
# 需要先启动 PostgreSQL 和 Redis（可用 docker-compose）
docker compose up -d postgres redis

# 然后启动应用服务
./dev.sh start
```

---

### 方式 3: Dockerfile 独立部署（生产环境单容器）

**特点：** 只运行单个服务容器，需要手动指定所有配置

#### 构建镜像
```bash
docker build --target fastapi-prod -t translate-api:latest .
```

#### 方法 A: 使用 --env-file（推荐）
```bash
docker run -d \
  --name translate-api \
  --env-file .env.prod \
  -p 29000:8000 \
  translate-api:latest
```

#### 方法 B: 使用 -e 逐个传递（不推荐）
```bash
docker run -d \
  --name translate-api \
  -e DATABASE_URL=postgresql+asyncpg://... \
  -e REDIS_URL=redis://... \
  -e LLM_API_KEY=sk-xxx \
  -p 29000:8000 \
  translate-api:latest
```

#### 注意事项
⚠️ **必须手动指定所有配置**，因为：
- Dockerfile 不会自动加载 .env 文件
- 需要通过 `--env-file` 或 `-e` 显式传递

---

## 是否需要指定配置文件？

| 部署方式 | 是否必须指定 | 默认行为 | 推荐做法 |
|---------|-------------|---------|---------|
| **Docker Compose** | ❌ 非必须 | 自动加载 `.env` | 生产环境明确指定 `ENV_FILE=.env.prod` |
| **dev.sh 本地开发** | ❌ 非必须 | 自动加载 `.env` | 开发时用 `ENV_FILE=.env.dev` |
| **Dockerfile 独立** | ✅ **必须** | 不加载任何文件 | 必须用 `--env-file` 或 `-e` |

---

## 最佳实践建议

### 开发环境
```bash
# 方式 1: 全容器化开发（数据隔离）
ENV_FILE=.env.dev docker compose up -d

# 方式 2: 混合开发（容器化数据库 + 本地代码热重载）
docker compose up -d postgres redis
ENV_FILE=.env.dev ./dev.sh start
```

### 生产环境
```bash
# 推荐: Docker Compose（编排所有服务）
ENV_FILE=.env.prod docker compose up -d --build

# 可选: 单容器部署（需配合外部数据库）
docker run -d --env-file .env.prod -p 29000:8000 translate-api:latest
```

---

## 配置文件内容差异建议

### .env（默认 / 本地开发）
- `DATABASE_URL`: localhost:5432（本地 PostgreSQL）
- `REDIS_URL`: localhost:6379（本地 Redis）
- `LLM_API_KEY`: 测试 Key
- `VALID_API_KEYS`: test-key-001

### .env.dev（开发服务器 / 团队共享开发环境）
- `DATABASE_URL`: dev-postgres.example.com（远程开发数据库）
- `REDIS_URL`: dev-redis.example.com（远程开发 Redis）
- `LLM_API_KEY`: 开发环境 Key
- `RATE_LIMIT_PER_MINUTE`: 100（放宽限流）

### .env.prod（生产环境）
- `DATABASE_URL`: 生产数据库地址
- `REDIS_URL`: 生产 Redis 地址
- `LLM_API_KEY`: 生产 Key（严格保密）
- `VALID_API_KEYS`: 强随机字符串
- `ALLOWED_ORIGINS`: 生产前端域名

---

## 快速参考

```bash
# 查看当前使用的配置文件
echo $ENV_FILE  # 如果为空，则使用 .env

# 临时指定配置文件（仅当次命令有效）
ENV_FILE=.env.dev docker compose up -d
ENV_FILE=.env.dev ./dev.sh start

# 永久指定配置文件（当前 shell 会话）
export ENV_FILE=.env.dev
docker compose up -d   # 使用 .env.dev
./dev.sh start         # 使用 .env.dev

# 检查配置是否正确
bash scripts/check_env.sh .env.dev
```
