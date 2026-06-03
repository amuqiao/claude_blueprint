# Flutter 学习与协作资料

本文维护 `HeatMomentFlutter` 重构过程中可用的 Codex skills、社区 skills 和外部参考项目。它是学习与协作资料，不承担重构方案决策职责。

## 1. 官方 Flutter skills

`skills.sh` 已有 Flutter 官方来源的 skills。新建 `HeatMomentFlutter/` 前，优先从官方 `flutter/skills` 安装项目骨架阶段会马上用到的 skill。

安装入口：

```bash
npx skills add flutter/skills
```

当前 CLI 会进入多选界面。新建项目阶段建议先选下面 5 个：

```text
flutter-apply-architecture-best-practices
flutter-build-responsive-layout
flutter-fix-layout-issues
flutter-setup-declarative-routing
flutter-add-widget-test
```

官方 skill 选择建议：

| skill | ★ | 新建项目推荐安装 | 推荐理由 |
| --- | --- | --- | --- |
| `flutter-apply-architecture-best-practices` | ★★★ | 是 | 最适合项目起步阶段使用，用来约束分层、依赖方向、页面职责和测试边界，避免一开始写成难维护的混合结构。 |
| `flutter-setup-declarative-routing` | ★★★ | 是 | `HeatMoment` 需要首页、编辑页、统计页、标签页、设置页等稳定页面关系，项目骨架阶段应尽早确定 `go_router` 这类声明式路由。 |
| `flutter-build-responsive-layout` | ★★★ | 是 | 日记卡片、热力图、图片网格、筛选区域都依赖稳定布局，早装可以帮助 Codex 在实现页面时考虑不同屏幕尺寸。 |
| `flutter-fix-layout-issues` | ★★★ | 是 | Flutter UI 常见风险是 overflow、滚动嵌套、约束冲突和小屏错位；这个 skill 适合伴随每轮 UI 调整使用。 |
| `flutter-add-widget-test` | ★★☆ | 是 | 首版可以先用 Widget Test 保护关键组件和页面状态，成本低于集成测试，也更适合 MVP 阶段持续迭代。 |
| `flutter-implement-json-serialization` | ★★☆ | 暂缓 | 后续如果使用 `freezed`、`json_serializable` 或导入导出数据时会用到；项目刚创建时本地数据库 schema 更优先。 |
| `flutter-add-integration-test` | ★★☆ | 暂缓 | 等主链路“新建记录 -> 首页展示 -> 统计回看”跑通后再安装，过早写集成测试会拖慢骨架调整。 |
| `flutter-add-widget-preview` | ★☆☆ | 暂缓 | 适合组件库成熟后预览卡片、chip、热力图等组件；项目初期页面结构还不稳定，收益不如 Widget Test。 |
| `flutter-setup-localization` | ★☆☆ | 暂缓 | 多语言不属于当前 MVP，先不要引入 `flutter_localizations` 和 `intl` 增加维护面。 |
| `flutter-use-http-package` | ★☆☆ | 暂缓 | `HeatMoment` MVP 以本地数据为主，不需要一开始引入 HTTP 能力；后续接云同步或后端 API 时再安装。 |

结论：新建 `HeatMomentFlutter/` 时，先安装 `架构 + 路由 + 响应式布局 + 布局修复 + Widget 测试` 五类官方 skill。其他 skill 等具体需求出现后再装，避免把项目启动阶段变成工具堆叠。

## 2. 可选社区 skills

社区 skill 可以作为补充，但不要替代官方文档和仓库规则。

| skill | 安装命令 | 使用建议 |
| --- | --- | --- |
| `flutter-dev` | `npx skills add https://github.com/bogdanustyak/flutter-expert-skill --skill flutter-dev` | 通用 Flutter / Dart 开发建议，可作为官方 skill 的补充。 |
| `flutter-clean-arch` | `npx skills add https://github.com/duckyman-ai/agent-skills --skill flutter-clean-arch` | 只在需要明确 `Clean Architecture + Riverpod` 模板时使用，避免过度套模板。 |
| `flutter-riverpod-expert` | `npx skills add https://github.com/juparave/dotfiles --skill flutter-riverpod-expert` | 只在 Riverpod provider、缓存、测试、重建性能问题变复杂时使用。 |
| `flutter-testing` | `npx skills add https://github.com/madteacher/mad-agents-skills --skill flutter-testing` | 当官方测试 skill 不够细时再补充。 |
| `flutter-navigation` | `npx skills add https://github.com/madteacher/mad-agents-skills --skill flutter-navigation` | 当 `go_router`、深链、嵌套路由变复杂时再补充。 |

## 3. 推荐高 star 参考项目

以下项目不建议直接复制目录结构，而是作为 Codex 生成代码前的参考样本。

截至 `2026-05-25` 核对，优先参考这些项目：

| 项目 | 当前量级 / 状态 | 方向 | 参考价值 |
| --- | --- | --- | --- |
| `flutter/samples` | 约 `19.1k` stars | 官方样例集合 | 官方维护的 Flutter 示例，包含 `compass_app` 等架构样例，适合作为 API 和推荐写法参考。 |
| `flutter/gallery` | 约 `6.6k` stars，已于 `2024-06-13` 归档 | 官方 UI 展示 | 可参考 Material / Cupertino 组件展示方式，但因为已归档，不适合作为新项目架构基线。 |
| `Solido/awesome-flutter` | 约 `58.1k` stars | Flutter 资源索引 | 高星 Flutter 资源总入口，适合找 UI、动画、导航、数据、工具库。 |
| `AppFlowy-IO/AppFlowy` | 约 `70.3k` stars | 大型 Flutter 应用 | 适合观察大型 Flutter 应用如何组织模块、跨平台、复杂编辑器和长期维护。 |
| `ionicfirebaseapp/getwidget` | 约 `4.7k` 至 `4.8k` stars | Flutter UI Kit | 可作为组件覆盖面参考；`HeatMoment` 应优先自建轻量设计系统，不建议一开始依赖大型 UI Kit。 |
| `fluttercandies/extended_image` | 图片交互能力突出 | 图片浏览、缩放、裁剪、滑动退出 | 后续处理图片浏览和相册体验时可参考能力边界；引入前要确认当前 Flutter stable 兼容性。 |
| `fluttercandies/flutter_smart_dialog` | 约 `1.2k` stars | Toast、Loading、Dialog | 可参考弹窗交互封装；`HeatMoment` 的基础弹窗优先用 Flutter 原生能力。 |
| `Uuttssaavv/flutter-clean-architecture-riverpod` | 社区架构示例 | `Clean Architecture + Riverpod` | 适合理解 feature-first、repository、notifier 的组合方式，但不要机械复制。 |

筛选开源项目时，不只看 star：

- 看最近维护时间。
- 看 issue 和 PR 是否活跃。
- 看是否适配当前 Flutter stable。
- 看是否有测试。
- 看目录是否清晰，而不是只看 UI 是否漂亮。
- 看依赖是否可控，避免把整个 App 绑死到模板。

## 4. 使用方式

这些资料的使用原则：

- 先以 `docs/HeatMoment-Flutter-重构方案.md` 的工程决策为准。
- skills 用于提升 Codex 协作质量，不用于替代项目方案。
- 参考项目用于学习架构、组件和交互，不直接复制目录或依赖组合。
- 当资料内容开始影响工程决策时，应回到重构方案中更新决策摘要。
