# Shell Service Rules

## 适用边界

这个真源只处理一类脚本：

- 一个项目里有多个服务
- 需要统一管理 `start / stop / restart / status / logs`
- 需要明确 PID、日志、端口冲突和输出行为

如果核心问题是：

- 批量 API 调用脚本 -> 用 `python-script`
- 运维诊断与 `--apply` 子命令 -> 用 `python-ops-cli`

## 最小结构

推荐至少包含这些部分：

1. Shebang + `set -euo pipefail`
2. Header 注释块
3. 路径常量
4. `SERVICES` 数组
5. 颜色常量
6. 服务配置函数
7. 辅助函数
8. `do_start / do_stop / do_restart / do_status / do_logs`
9. 参数派发
10. 主入口

## 配置与逻辑分离

至少把这些放在配置函数里：

- 日志文件路径
- PID 文件路径
- 端口
- URL

核心控制逻辑不要直接写死某个服务的具体信息。

## 命令契约

总控脚本固定支持：

- `start`
- `stop`
- `restart`
- `status`
- `logs`

规则：

- `start / stop / restart / status` 不传服务名时默认处理全部服务
- `logs` 必须显式指定服务
- 传未知服务名时必须报错，不可静默忽略

## 进程控制

最小要求：

- 每个服务一个 PID 文件
- 启动后做存活检测
- 停止时先 SIGTERM，再按需 SIGKILL
- stale PID 自动清理

如果有后台启动：

- 推荐使用 `exec` 替换子 shell，确保 `$!` 对应真实进程

## 端口与日志

如果服务有端口：

- 启动前检查端口冲突
- 发现冲突时明确报错，不允许静默失败

日志至少要明确：

- 日志文件路径
- `logs` 命令的查看方式
- 启动时日志是追加还是覆盖

## 输出规则

输出要适合在终端直接扫读：

- 多服务状态要列对齐
- running 状态应显示 PID 和可访问 URL
- 错误信息要明确到服务名和问题点

## 当前判断

- 这类规则适合稳定放在 `skills/shell-service/`
- archived 的服务管理脚本 prompt 只保留作历史派生物
- 如果未来你再写 `dev.sh` 类脚本，优先维护这里，再决定是否派生新 prompt
