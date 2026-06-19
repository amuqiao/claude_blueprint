---
description: GitLab CI test/master 镜像构建与 Dockerfile 职责规则
---

# GitLab CI 镜像构建规则

本规则只约束采用固定 GitLab CI 模板发布测试分支和主干分支的后端服务，是 `service-deployment.md` 的条件扩展。它不约束本地 dev 分支开发，也不要求本地开发 Dockerfile 按同一模式组织。

## 适用边界

适用场景：

- 项目使用 GitLab CI 构建镜像。
- CI 模板固定由 `.gitlab-ci.yml` include 维护。
- `Dockerfile` 用作代码镜像构建入口。
- `Dockerfile_OS` 用作运行环境镜像构建入口。
- test/master 或等价发布分支通过 CI 构建并推送镜像。

不适用场景：

- 本地 dev 分支开发容器。
- docker compose 本地依赖环境。
- 临时调试 Dockerfile。
- 不使用该 CI 模板的项目。
- 生产平台运行参数、K8s Deployment 或 Kuboard 操作说明。

## 固定文件职责

| 文件 | 职责 | 维护边界 |
| --- | --- | --- |
| `.gitlab-ci.yml` | 引入固定 CI 模板和少量 CI 变量 | 不承载本地开发命令，不复制 CI 模板逻辑 |
| `Dockerfile` | 构建代码镜像，把项目内容交给运行环境容器或初始化流程 | 不安装 Python、系统包或运行时依赖 |
| `Dockerfile_OS` | 构建低频变化的运行环境镜像 | 只在 Python 版本、系统依赖、基础依赖或包管理方式变化时更新 |

`Dockerfile` 和 `Dockerfile_OS` 是发布链路约定，不是本地开发镜像模板。需要本地容器化开发时，应单独使用 compose、dev Dockerfile 或开发脚本说明，避免修改发布链路文件。

## 参考示例

以下示例来自 `cms-story-tagger` 的固定发布链路，用于说明三类文件的职责边界。复制到新项目时，应保留职责结构，再按项目实际调整镜像地址、CI 变量和依赖声明。

`.gitlab-ci.yml`：

```yaml
include:
  - project: 'ci-base/ci-runner'
    ref: py-ci
    file: '/py-ci.yaml'
variables:
  dingtoken: "..."
```

`Dockerfile`：

```dockerfile
FROM alpine:latest
COPY . /tmp/
```

`Dockerfile_OS`：

```dockerfile
FROM cms-images-sz-registry-vpc.cn-shenzhen.cr.aliyuncs.com/os/python:3.13.11
ENV UV_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
WORKDIR /root
COPY pyproject.toml /root/
RUN pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple uv
RUN uv pip install . --system
```

## `.gitlab-ci.yml` 规则

使用固定模板时，`.gitlab-ci.yml` 应尽量短，只保留 include 和必要变量。

维护规则：

- 不在项目内复制 `py-ci.yaml` 的构建逻辑。
- 不为本地 dev 分支添加 CI 专用分支逻辑。
- 变量只放 CI 模板确实需要的项目级参数。
- 密钥类变量优先使用 GitLab CI 变量或平台密钥；确需写入文件时必须明确它不是业务运行密钥。

## `Dockerfile` 规则

发布链路中的 `Dockerfile` 默认是代码镜像入口。

维护规则：

- 不安装 Python、uv、pip、系统包或业务运行依赖。
- 不写入真实环境变量、API Key、数据库密码或通知 token。
- 不把本地缓存、虚拟环境、构建产物和临时文件复制进镜像。
- 通过 `.dockerignore` 控制构建上下文。
- 不为了本地 dev 调试改动这个发布用 Dockerfile。

## `Dockerfile_OS` 规则

`Dockerfile_OS` 承载运行环境镜像，典型职责包括：

- 固定 Python 基础镜像。
- 配置依赖安装源。
- 安装 uv 或等价包管理工具。
- 只复制依赖声明文件。
- 安装项目运行依赖到运行环境。

维护规则：

- 只有运行时、系统依赖、基础 Python 依赖或包管理方式变化时，才更新 `Dockerfile_OS`。
- 构建源地址可以通过 `ENV`、`ARG` 或 CI 变量维护，但不要散落到多个脚本。
- 更新后必须单独触发运行环境镜像构建，并确认工作容器镜像版本是否需要同步调整。
- 不把业务代码、环境密钥、本地缓存或开发工具链塞进运行环境镜像。

## 分支边界

本规则服务 test/master 发布链路。默认判断：

- dev 分支本地开发不应修改发布用 `Dockerfile` / `Dockerfile_OS`。
- 业务代码变更通常只影响代码镜像。
- 运行环境变化才影响 `Dockerfile_OS`。
- 同一提交同时改业务代码和运行环境时，应先确认发布顺序。

如果项目确实需要本地开发 Dockerfile，应另建清晰命名的本地开发入口，并在 README 或开发入口脚本中说明，不要复用发布链路文件承担本地开发职责。
