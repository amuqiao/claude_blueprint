# AI 漫剧字幕与配音替换基础扫盲

本文用于把”用 SRT 和 MP4 做 AI 漫剧字幕替换、配音替换、音色相似”这个需求对象化，先建立可讨论的最小内部模型，再进入方案选型。

本文使用 [`主题基础扫盲方法论`](../../方法论/理解类/主题基础扫盲方法论.md) 的思路：先定住对象，再解释它为什么存在、靠什么成立、边界在哪里。

---

## 术语对照表（Glossary）

本文档使用业界标准术语，主要参考配音、字幕、音频后期制作领域的通用规范：

| 中文术语 | 英文术语 | 说明 | 应用场景 |
| --- | --- | --- | --- |
| **配音单元** | **Dubbing Cue** | 配音的最小处理单元，承载文本、时间码、角色和配音 | 数据模型、工作流 |
| 字幕条目 | Subtitle Cue / Subtitle Event | SRT 文件中的一个字幕事件 | 字幕解析 |
| 时间码 | Timecode | 视频中的时间位置标记（如 00:01:23.500） | 时间定位 |
| 入点/出点 | In-point / Out-point | 配音或字幕的开始/结束时间点 | 时间范围 |
| 人声轨 | Vocal Stem | 音源分离后的纯人声音轨 | 音频处理 |
| 音乐轨 | Music Stem | 音源分离后的背景音乐和音效 | 音频处理 |
| 音源分离 | Source Separation | 将混合音频分离为人声、音乐、音效等独立轨道 | 音频处理 |
| 音频闪避 | Ducking | 对白时段自动降低背景音音量的技术 | 混音 |
| 配音提示表 | Cue Sheet | 记录所有配音单元信息的表格 | 项目管理 |
| ADR | Automated Dialogue Replacement | 自动对白替换，后期配音的专业术语 | 后期制作 |
| 口型同步 | Lip-sync / Lip Synchronization | 配音与画面口型对齐 | 视频处理 |
| 创译 | Transcreation | 创造性翻译，保留文化内涵和语气风格 | 本地化 |
| 音色匹配 | Voice Matching | 生成的配音与原音色相似 | TTS/配音 |
| 硬字幕 | Burned-in Subtitle / Open Caption | 烧录进画面的字幕，无法关闭 | 字幕渲染 |
| 软字幕 | Closed Caption | 嵌入视频但可开关的字幕轨 | 字幕渲染 |

**说明**：数据模型中使用 `Segment` 作为类名，但概念上对应 **Dubbing Cue（配音单元）**。

---

## 一句话理解

这个需求不是”翻译一份字幕文件”，而是把原视频里的对白生产链重新走一遍：以 SRT 为时间基准，把文本本地化、生成目标语言配音、替换字幕显示，并让声音尽量与原角色匹配（Voice Matching）。

## 当前需求复述

你现在有两类输入：

- 一段处理过的其他语种 `srt`，可能是英文、法文、日文、韩文、印尼文等。
- 一段 `mp4` 素材，素材本身带字幕和配音。

你希望最终做到：

- 替换视频字幕。
- 替换视频配音。
- 新配音的音色尽量接近原角色。
- 以 `srt` 中的对白段落作为基本处理单元。
- 能处理不同语种导致的分段、时长、语序和表达长度差异。
- 优先考虑第三方实现、开源方案和自研方案之间的组合，而不是一开始只押单一路线。

这个需求所在的业务背景是 AI 漫剧平台。平台不仅要生成结果，还需要服务持续生产，所以后续要考虑任务编排、人工审核、单句重生成、角色音色管理和批量导出。

## 这个问题的真实对象

表面对象是 `srt + mp4`，真实对象是”**ADR 驱动的视频本地化流水线**”（ADR: Automated Dialogue Replacement）。

```text
mp4 原素材
+ srt 时间基准
-> 文本本地化（Localization）
-> 字幕重排
-> 角色音色匹配（Voice Matching）
-> 目标语言配音生成（Dubbing）
-> 音频时长对齐（Spotting）
-> 视频混音和字幕输出（Mixing & Rendering）
-> 人工质检（QA）
```

这里的核心不是某一个模型，而是多个能力之间的协作关系。

| 对象 | 在需求中的作用 | 业界术语 |
| --- | --- | --- |
| `srt` | 对白切片、时间窗和字幕文本的主索引 | Subtitle File |
| `mp4` | 画面、原音轨、背景音、原字幕和成片容器 | Video Asset |
| **Dubbing Cue（配音单元）** | 最小生产单元，承载文本、时间码、角色和配音 | Dubbing Cue / ADR Cue |
| 翻译/本地化 | 把原对白变成目标语言，但要兼顾角色语气和时长 | Localization / Transcreation |
| TTS/音色克隆 | 生成目标语言语音，并尽量保留原角色声音特征 | TTS / Voice Cloning / Voice Matching |
| 音频对齐 | 让生成语音尽量落入原对白时间窗 | Spotting / Timing Alignment |
| 字幕渲染 | 输出软字幕或烧录字幕，必要时遮盖原硬字幕 | Subtitle Rendering |
| 人工审核 | 修正机器无法稳定处理的分段、语气、节奏和错译 | Quality Assurance (QA) |

## 为什么不能只做”翻译 SRT + TTS”

SRT 是字幕时间轴，不是完整的配音剧本（Dubbing Script）。

如果只把每条字幕条目（Subtitle Cue）翻译后直接送进 TTS，会遇到几个稳定问题：

| 问题 | 原因 | 业界术语 |
| --- | --- | --- |
| 目标语音超时 | 不同语言表达长度不同，同一含义在法语、日语、英语里的音节和语速差异很大 | Timing Overflow |
| 分段不自然 | 原 SRT 分段服务字幕阅读，不一定服务配音停顿 | Cue Segmentation |
| 语气丢失 | 字幕文本通常不包含情绪、停顿、重音和角色状态 | Prosody Loss |
| 角色音色漂移 | 多角色对白需要稳定的说话人身份（Speaker Identity），不能每句随机克隆 | Voice Consistency |
| 原背景音损坏 | 直接替换整条音轨会丢失音乐、环境音和音效 | Stem Preservation |
| 硬字幕残留 | 如果原字幕已经烧录进画面（Burned-in），单纯添加新字幕会叠字 | Subtitle Overlap |

所以本需求应被理解为”**ADR 生产工程**”，不是单点模型调用。

## 内部结构

一个可用的 AI 漫剧配音替换系统至少包含 7 层，对应专业 ADR 工作流：

| 层级 | 责任 | 业界术语 | 典型能力 |
| --- | --- | --- | --- |
| 输入解析层 | 读取视频、字幕和音轨 | Media Ingestion | `ffmpeg`、SRT parser、媒体元信息提取 |
| 配音单元建模层 | 把字幕条目转成配音单元 | Cue Sheet Preparation | Dubbing Cue、Speaker、Timecode、Text Version |
| 文本本地化层 | 翻译并改写对白 | Localization / Transcreation | 机器翻译、LLM 改写、Glossary、角色口吻 |
| 音色与角色层 | 维护角色和声音关系 | Voice Casting & Management | Speaker Diarization、Voice Cloning、Voice Library |
| 语音生成层 | 生成目标语言配音音频 | ADR Recording / TTS Generation | TTS、Voice Cloning、Prosody Control |
| 对齐与混音层 | 让音频、字幕、画面对齐 | Spotting & Audio Mixing | Time-stretch、Silence Trim、Ducking、Stem Mixing |
| 审核导出层 | 人工修正并输出成片 | QA & Delivery | 局部预览、Take 重录、字幕导出、视频渲染 |

这 7 层决定了平台的工程形态：后端不是简单接一个 TTS 接口，而是要调度一组可替换的媒体处理和 AI 任务。

## Dubbing Cue（配音单元）作为基本处理单元

以 **Dubbing Cue** 为基本处理单元，意味着系统的主数据结构应该围绕配音单元建立，而不是围绕整段音频或单纯的字幕条目建立。

一个 Dubbing Cue 至少需要抽象成：

| 字段 | 含义 | 业界术语 |
| --- | --- | --- |
| `index` | 原 SRT 序号 | Cue Number |
| `in_point` / `out_point` | 配音的开始/结束时间码 | In-point / Out-point / Timecode |
| `source_text` | 原对白文本 | Source Dialogue |
| `target_text` | 目标语言文本 | Target Dialogue |
| `speaker_id` | 角色或说话人 | Speaker / Character |
| `voice_profile_id` | 目标音色配置 | Voice Casting |
| `generated_audio` | 当前生成的配音片段 | Audio Clip / Take |
| `duration_status` | 是否超时、过短或可接受 | Timing Status |
| `review_status` | 是否已人工确认 | QA Status |

**数据模型说明**：代码中使用 `Segment` 类名，但概念上对应 **Dubbing Cue**。

后续的合并、拆分、重生成（Re-take）、审核（QA）和导出（Delivery），都围绕这个结构进行。

## 关键边界

### Closed Caption 和 Burned-in Subtitle 不是一回事

- **Closed Caption（软字幕）**：如果 mp4 里是软字幕轨，可以直接替换或新增字幕轨。
- **Burned-in Subtitle（硬字幕）**：如果字幕已经烧录在画面里，系统必须选择遮盖、重排、裁切或视频修复。第一版更适合用字幕区域遮罩和重新排版，不建议把视频 inpainting 作为 MVP 必做能力。

### Voice Matching 不等于完全声纹复刻

平台目标应定义为”**Voice Matching（音色匹配）**：角色声音风格接近且稳定”，不是保证声纹（Voiceprint）完全一致。真实声纹复刻涉及授权、合规和伦理风险，也会受原素材干净程度、背景音、人声分离质量影响。

### Dubbing 不等于 Lip-sync

漫剧通常比真人口型同步（Lip-sync）宽松。第一阶段应优先保证字幕、语义、角色音色和节奏可接受；如果后续进入真人短剧或强口型画面，再单独考虑 Lip-sync 技术。

### 全自动不是第一阶段最优目标

配音质量问题通常集中在语气（Prosody）、停顿、错译、专有名词读音、分段和时长。AI 可以生成初稿，但人工审核（QA）工作台应从第一版就进入设计。

## 最小心智模型

可以把这个需求理解成一个”**带 QA 的 ADR 流水线**”：

```text
SRT 提供 Timecode 基准
Localization 提供目标文本
TTS / Voice Cloning 提供配音
Audio Processing 负责 Spotting 和 Mixing
Video Processing 负责 Subtitle Rendering 和 Delivery
QA 负责质量兜底
```

只要这个模型稳定，后续无论接第三方 API、开源模型，还是自研训练，都可以放进同一套工程框架里讨论。

---

## 术语使用建议

在后续文档和代码中：
- **概念讨论**：使用标准术语（Dubbing Cue、Timecode、Voice Matching 等）
- **数据模型**：可使用 `Segment`、`start_time`、`end_time` 等简洁命名，但文档说明对应关系
- **对外沟通**：优先使用业界标准术语，便于与供应商、技术社区对接
