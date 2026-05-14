# Docker Compose 数据持久化方式详解

> Docker 容器默认是无状态的——容器删除后，其内部数据也随之消失。数据持久化就是解决这个问题的关键机制。

---

## 一、为什么需要数据持久化？

容器内部使用的是**可写层（Writable Layer）**，该层与容器生命周期绑定：

- 容器停止 → 数据保留
- 容器删除 → 数据**永久丢失**
- 容器重建 → 从镜像重新开始

因此，数据库文件、用户上传内容、配置文件、日志等**重要数据必须存储在容器外部**。

---

## 二、三种核心持久化方式

### 🔵 方式一：Named Volumes（命名卷）

**最推荐的方式**，由 Docker 完全管理，与主机路径解耦。

```yaml
version: "3.8"

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret
    volumes:
      - pgdata:/var/lib/postgresql/data  # 挂载命名卷

volumes:
  pgdata:  # 声明命名卷（Docker 自动管理存储位置）
```

**常用操作：**
```bash
# 查看所有卷
docker volume ls

# 查看卷详情（包括存储路径）
docker volume inspect pgdata

# 删除卷（危险！数据会丢失）
docker volume rm pgdata

# 清理未使用的卷
docker volume prune
```

**✅ 优点：**
- Docker 统一管理，跨平台一致
- 支持卷驱动（NFS、S3、Ceph 等）
- 性能最优（尤其在 Docker Desktop for Mac/Windows）
- 易于备份和迁移

**❌ 缺点：**
- 不能直接在主机文件系统中浏览内容（需通过 Docker 命令访问）

---

### 🟠 方式二：Bind Mounts（绑定挂载）

将**主机上的具体目录或文件**直接映射到容器内。

```yaml
version: "3.8"

services:
  nginx:
    image: nginx:latest
    volumes:
      - ./html:/usr/share/nginx/html          # 相对路径：项目目录下的 html/ 文件夹
      - /etc/nginx/nginx.conf:/etc/nginx/nginx.conf  # 绝对路径：主机上的具体文件
      - ./logs:/var/log/nginx                  # 日志目录

  app:
    image: node:18
    working_dir: /app
    volumes:
      - .:/app                    # 将整个项目目录挂载（开发常用）
      - /app/node_modules         # 排除 node_modules（匿名卷覆盖）
    command: npm run dev
```

**✅ 优点：**
- 主机与容器实时同步，**开发调试最方便**
- 可直接用 IDE、编辑器修改文件
- 路径直观透明

**❌ 缺点：**
- 路径与主机强绑定，跨平台可能出现问题（路径分隔符、权限差异）
- 在 Mac/Windows 上 I/O 性能较差（文件系统虚拟化开销）

> **💡 常见场景：** 开发环境热重载、配置文件注入、日志收集

---

### 🟡 方式三：tmpfs Mounts（内存挂载）

数据存储在**内存**中，容器停止后数据立即消失（非持久化）。

```yaml
version: "3.8"

services:
  app:
    image: myapp:latest
    tmpfs:
      - /tmp                    # 简写形式
      - /run/cache:size=100m    # 限制内存大小
    # 或者使用 volumes 语法
    volumes:
      - type: tmpfs
        target: /tmp
        tmpfs:
          size: 52428800  # 50MB（单位：字节）
```

**✅ 优点：**
- 极高的读写性能（纯内存操作）
- 不写入磁盘，适合存储敏感中间数据
- 自动清理，无需手动删除

**❌ 缺点：**
- 容器停止或重启后数据消失（不是真正的持久化）
- 受内存容量限制

> **💡 常见场景：** 临时缓存、Session 数据、敏感信息中间处理

---

## 三、三种方式横向对比

| 特性 | Named Volume | Bind Mount | tmpfs |
|------|-------------|------------|-------|
| **数据持久** | ✅ 是 | ✅ 是 | ❌ 否 |
| **主机可见** | 需通过 Docker 命令 | ✅ 直接访问 | ❌ 仅内存 |
| **跨平台** | ✅ 最好 | ⚠️ 路径差异 | ✅ 好 |
| **性能** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐（Mac 较低）| ⭐⭐⭐⭐⭐ |
| **适合生产** | ✅ 推荐 | ⚠️ 慎用 | 仅临时数据 |
| **适合开发** | ✅ 可用 | ✅ 最方便 | 特定场景 |
| **备份难度** | 简单（volume 命令）| 简单（cp 命令）| 不适用 |

---

## 四、高级用法

### 1. 只读挂载（Read-Only）

```yaml
services:
  app:
    volumes:
      - ./config:/app/config:ro  # 末尾加 :ro，容器内不可修改
```

### 2. 多容器共享同一个卷

```yaml
services:
  writer:
    image: producer:latest
    volumes:
      - shared-data:/data

  reader:
    image: consumer:latest
    volumes:
      - shared-data:/data:ro  # 消费者只读

volumes:
  shared-data:
```

### 3. 使用外部（已存在的）卷

```yaml
volumes:
  existing-volume:
    external: true  # 使用 Docker 外部已创建的卷，不会随 docker-compose down 删除
```

### 4. 使用第三方卷驱动（生产环境）

```yaml
volumes:
  nfs-data:
    driver: local
    driver_opts:
      type: nfs
      o: addr=192.168.1.100,rw
      device: ":/path/to/nfs/share"
```

---

## 五、数据备份与恢复

### 备份 Named Volume

```bash
# 备份：将卷数据打包为 tar 文件
docker run --rm \
  -v pgdata:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/pgdata-backup.tar.gz -C /data .

# 恢复：将 tar 文件还原到卷
docker run --rm \
  -v pgdata:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/pgdata-backup.tar.gz -C /data
```

---

## 六、选型建议

```
需要持久化数据？
├─ 是
│  ├─ 是开发环境，需要实时编辑文件？ → Bind Mount
│  └─ 是生产环境或不需要直接访问？   → Named Volume
└─ 否（只需要高性能临时存储）         → tmpfs
```

**一句话总结：**
- 🔵 **Named Volume** → 生产数据库、持久化状态（首选）
- 🟠 **Bind Mount** → 开发热重载、配置文件注入
- 🟡 **tmpfs** → 临时缓存、敏感中间数据

---

*参考文档：[Docker 官方文档 - Volumes](https://docs.docker.com/storage/volumes/)*