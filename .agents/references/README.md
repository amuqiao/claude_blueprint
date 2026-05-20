# References README

## 当前定位

- `rules/` 是共享规则的唯一真源。
- 本目录只保留共享规则的入口层文件，不再承载长版 guideline。
- `.agents/references/references-index.md` 是共享规则索引真源文件，由脚本从 `rules/` 自动生成。
- 该索引文件的最终表现形式必须与项目内实际使用的索引文件一致，不能混入“真源文件”“同步副本”“复制方式”等维护者说明。

## 推荐引用方式

推荐采用“两层引用”：

1. `claude_blueprint` 维护共享规则正文 `rules/`，并生成索引真源 `.agents/references/references-index.md`。
2. 使用这些共享规则的项目，在自己的仓库内落一份 `.agents/references/references-index.md` 本地副本。
3. 目标项目的 `AGENTS.md` 只要求先读取本仓库内的 `.agents/references/references-index.md`，不要直接引用外部仓库绝对路径。
4. 读取目标项目本地索引后，再按索引中的 `path` 继续展开共享规则正文。

这样做的原因：

- 当前仓库会有一个稳定、可见、可检查的默认上下文入口。
- `AGENTS.md` 更容易表达成“先读本仓库哪个文件”，而不是“跨仓库跳到哪里”。
- 共享规则正文仍只有一套真源，避免把 rule 内容复制到多个仓库。
- 目标项目只同步索引文件，不需要各自手写不同版本的索引头部。
- 对项目使用者来说，只看项目内 `AGENTS.md` 和 `.agents/references/references-index.md` 即可，不应感知真源文件存在。

## 应用示例

### 1. 在共享规则源仓库更新索引

```bash
bash .agents/references/generate-references-index.sh
```

### 2. 在目标项目中同步索引副本

```bash
mkdir -p .agents/references
cp /Users/admin/Downloads/Code/claude_blueprint/.agents/references/references-index.md .agents/references/references-index.md
```

如果本机 `claude_blueprint` 的路径不同，应替换成自己的实际路径。

### 3. 在目标项目 `AGENTS.md` 中声明默认加载方式

```md
## 条件读取规则

- 读取本仓库 `AGENTS.md` 后，必须立即读取 `.agents/references/references-index.md` 的正文内容，而不是只记录该路径。
- 如果 `.agents/references/references-index.md` 未读取、不可读或不存在，必须明确说明，不能声称已完成仓库上下文加载。
```

### 4. HeatMoment 应用示例

`HeatMoment` 当前采用的就是这套方式：

- `AGENTS.md` 先要求读取本仓库 `.agents/references/references-index.md`
- `.agents/references/references-index.md` 直接使用真源索引生成出来的最终使用态正文
- 共享规则更新后，只需要重新同步该索引副本

## 维护规则

- 修改共享规则时，只改 `rules/`，不要在本目录重复维护正文。
- `references-index.md` 不手写；修改 `rules/` 或索引头部模板后运行生成脚本更新。
- 目标项目中的 `.agents/references/references-index.md` 视为同步产物，不建议手写改动；如需项目特有规则，应写在项目自己的 `AGENTS.md` 或本仓库其他文档中。
- 生成脚本产出的 `references-index.md` 必须保持“项目实际使用态”，不能在正文中暴露真源、同步、复制、脚本生成等维护信息。
- 已废弃或已被 `rules/` 吸收的旧 reference 文件统一移动到 `.agents/archived/references/`。
- 新增共享规则时，必须为 rule 文件补充 frontmatter `description`，否则生成脚本会失败。
