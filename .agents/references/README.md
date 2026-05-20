# References README

## 当前定位

- `rules/` 是共享规则的唯一真源。
- 本目录只保留共享规则的入口层文件，不再承载长版 guideline。
- 项目级 `AGENTS.md` 通过本目录中的 `references-index.md` 读取共享规则清单，再全量加载 `rules/`。

## 目录分工

- `README.md`：解释本目录定位和维护方式。
- `references-index.md`：共享规则加载清单，由脚本生成。
- `generate-references-index.sh`：从 `rules/` 全量生成 `references-index.md`。

## 维护规则

- 修改共享规则时，只改 `rules/`，不要在本目录重复维护正文。
- `references-index.md` 不手写；修改 `rules/` 后运行生成脚本更新。
- 已废弃或已被 `rules/` 吸收的旧 reference 文件统一移动到 `.agents/archived/references/`。
- 新增共享规则时，必须为 rule 文件补充 frontmatter `description`，否则生成脚本会失败。
