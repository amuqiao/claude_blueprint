# Plugin Install Plan

用途：记录这套 blueprint 推荐的 Claude Code Plugin 安装计划。

约定：
- 这里记录的是“推荐安装计划”，不是 `~/.claude/plugins/` 的运行时镜像。
- `~/.claude/plugins/` 仍由 Claude Code 自动管理，不通过 `deploy-to-claude.sh` 直接覆盖。
- 修改本文件后，运行 `bash scripts/show-plugin-install-commands.sh` 展示需要在 Claude TUI 中执行的命令。
- 默认只输出 `Core` 主线 Plugin。
- 如需带上增强层，使用 `bash scripts/show-plugin-install-commands.sh --extended` 或 `bash scripts/show-plugin-install-commands.sh --all`。
- 如需只查看实验层，使用 `bash scripts/show-plugin-install-commands.sh --experimental-only`。

维护格式：
- 这份文件会被 `scripts/show-plugin-install-commands.sh` 按 Markdown 标题和列表格式直接解析，不是随意写的说明文。
- `## Marketplaces`、`## Core Plugins`、`## Extended Plugins`、`## Experimental Plugins`、`## Notes` 这些二级标题名应保持不变。
- 插件和市场条目必须使用单层列表，且插件/市场值写在反引号里，例如 `- \`name@marketplace\``。
- `## Notes` 使用普通列表即可，脚本会原样提取并显示中文说明。
- 如果只是补充某个插件或分层说明，优先改 `## Notes`，不要改脚本。
- 如果要改标题名、层级结构或条目语法，必须同步修改 `scripts/show-plugin-install-commands.sh`。

## Marketplaces

- `claude-plugins-official`
- `MarioGiancini/ralph-loop-setup`

## Core Plugins

- `superpowers@claude-plugins-official`
- `ralph-loop-setup@MarioGiancini/ralph-loop-setup`

## Extended Plugins

- `code-simplifier@claude-plugins-official`

## Experimental Plugins

## Notes

- `superpowers`：需求澄清、规划和执行流程增强。
- `ralph-loop-setup`：提供循环执行和 Stop Hook 拦截能力。
- `code-simplifier`：以独立 agent 方式整理已完成代码，适合在主流程稳定后再补装。
- `Core`：建议所有使用这套 blueprint 的环境默认安装。
- `Extended`：主流程稳定后再按需追加，提升局部效率。
- `Experimental`：仍在观察收益和稳定性，不进入默认主线。
