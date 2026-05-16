# Source Map

这个 skill 只负责路由。  
方法论真源在当前仓库的 `prompts/meta/`。

## Canonical Source Paths

- `prompts/meta/项目成型方法论_prompt.md`
  适用：项目从想法到起盘、项目骨架建立、首个核心模块选择

- `prompts/meta/功能模块成型方法论_prompt.md`
  适用：模块归位、模块接入、模块设计、模块验证与回写

- `prompts/meta/基础设施演进方法论_prompt.md`
  适用：当前基础设施是否该保持轻量、是否值得升级、如何留演进缝

- `prompts/meta/需求与版本演进方法论_prompt.md`
  适用：新需求进入系统、当前版本边界、优先级、切片与版本收敛

- `prompts/meta/文档成型规则_prompt.md`
  适用：任何输出物的结构、表达、可视化与沉淀方式

- `prompts/meta/README.md`
  适用：需要先建立 5 份方法论文档之间的整体心智模型时

## 使用规则

1. 先判断当前问题属于哪一层
2. 再读取对应的 canonical source
3. 不要一次性加载所有方法论文档
4. 永远优先选择最小充分的方法论路径

## 缺失处理

如果当前工作区没有 `prompts/meta/`：

- 先明确说明真源缺失
- 仅保守输出：
  - 当前层次
  - 当前阶段
  - 当前最主要问题
  - 建议最小下一步
- 不要伪造完整方法论内容
