---
name: shell-service
description: "服务生命周期管理脚本真源 skill。适用于编写或评审统一管理多个服务的 `dev.sh` / `service.sh` 类 Bash 脚本；当核心问题是 start、stop、restart、status、logs、PID、端口冲突和服务输出时使用。"
---

# Shell Service Skill

这是一个**服务生命周期管理脚本真源 skill**。  
它不在正文里重复展开全部 Bash 规范细节。

它主要负责：

- 统一多服务总控脚本的结构
- 固定 `start / stop / restart / status / logs` 的命令契约
- 统一 PID、端口冲突、日志和输出格式的基本规则
- 约束“配置与逻辑分离”的组织方式

## Canonical Source

这个 skill 的服务管理真源在：

- [`references/shell-service-rules.md`](references/shell-service-rules.md)

默认只读取这一份 reference。  
如果 reference 缺失：

- 明确说明当前缺少服务管理真源
- 仅保守遵守“单一入口、稳定命令契约、清楚 PID 与日志、失败即报错”的原则

## 标准使用方式

这个 skill 的默认动作顺序是：

1. 先判断当前是不是多服务生命周期管理脚本场景
2. 读取 `references/shell-service-rules.md`
3. 先输出服务配置方式和命令契约
4. 再进入 PID、端口、日志和实现细节
5. 优先保证总控脚本稳定，不为单个服务额外造入口

## 什么时候使用

当问题主要是**怎么用一个 Bash 脚本统一管理多个服务的生命周期**时，使用这个 skill。

### 必须使用

- 新建 `dev.sh` / `service.sh` 类总控脚本
- 为现有总控脚本新增服务
- 评审命令契约、PID 管理、端口冲突处理是否清楚

### 推荐使用

- 项目里有多个本地服务要统一启动和关闭
- 需要稳定的 `status` 和 `logs` 输出
- 需要对 stale PID、端口冲突和日志路径做统一处理

### 不适合使用

- 单纯写一个一次性 Bash 命令
- 纯 Python 运维 CLI
- 纯后端服务实现任务

## 输出契约

默认先输出：

```text
当前脚本类型：
服务列表：
建议命令契约：
建议 PID / 端口 / 日志策略：
建议最小产物：
```

只有在这一步明确后，才继续展开实现。

## 最小判断规则

- 如果一个项目里有多个服务 -> 优先做一个总控脚本
- 如果命令是生命周期管理 -> 固定 `start / stop / restart / status / logs`
- 如果有端口服务 -> 启动前检查冲突
- 如果有 PID 文件 -> 需要 stale PID 清理和停止顺序

## 重要边界

- 这是服务生命周期脚本真源，不是运维诊断真源
- 不要为每个服务单独造一套入口
- 不要把服务配置硬编码进核心控制逻辑
- 永远优先命令稳定、输出可扫、失败可见
