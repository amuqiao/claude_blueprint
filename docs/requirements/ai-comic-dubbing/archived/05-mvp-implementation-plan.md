# AI 漫剧配音本地化 - MVP 实施计划

> **文档定位**: MVP 执行蓝图，明确做什么、怎么做、何时完成
>
> **目标读者**: 开发团队、项目经理、测试人员
>
> **核心问题**: MVP 范围是什么? 分几步? 验收标准是什么?

---

## 一、MVP 目标定义

### 1.1 MVP 成功标准

**一句话目标**: 用 4 周时间，验证 1 集 10 分钟漫剧可以用 AI 完成多语言配音本地化，质量可接受，成本可控。

**定量目标**:
- ✅ 处理 **1 集漫剧** (10 分钟，150 条配音单元)
- ✅ 翻译 **1 种目标语言** (英语)
- ✅ 翻译质量: 人工评分 **≥4.0/5**
- ✅ 配音质量: MOS **≥4.0/5**
- ✅ 时长对齐: **90%** segment 在时间窗内
- ✅ 单集处理时间: **<30 分钟** (自动处理)
- ✅ 人工审核时间: **<30 分钟**
- ✅ 单集成本: **<$5** (运营成本)

---

### 1.2 MVP 范围

#### 必须做 (P0)

| 功能 | 说明 | 验收标准 |
|------|------|----------|
| **上传视频 + 字幕** | 支持 MP4 + SRT 上传 | 解析成功率 100% |
| **视频元信息提取** | 时长、分辨率、帧率、音轨 | ffprobe 提取准确 |
| **SRT 解析** | 解析为配音单元 (Segment) | 时间戳、文本正确 |
| **文本翻译** | 中文 → 英文 | Claude Opus 4.7 |
| **配音生成** | 生成英文配音 | ElevenLabs API |
| **音视频合成** | 混音、字幕渲染、导出 MP4 | 可播放、无音画不同步 |
| **人工审核界面** | 列表展示配音单元、预览、修改、重生成 | 可单句修改 + 重生成 |

#### 可以延后 (V1)

| 功能 | 延后原因 | 计划阶段 |
|------|----------|----------|
| 自动说话人识别 | MVP 人工标注即可 | V1 |
| 音源分离 | MVP 简单混音即可 | V1 |
| 硬字幕遮盖 | MVP 只支持软字幕 | V1 |
| 批量处理 | MVP 单集验证 | V1 |
| 多语言同时处理 | MVP 单语言验证 | V1 |
| 成本统计 | MVP 手工记录 | V1 |
| A/B 测试 | MVP 不对比 Provider | V2 |

#### 明确不做 (Out of Scope)

| 功能 | 不做原因 |
|------|----------|
| Lip-sync (口型同步) | 漫剧不需要 |
| 从零生成 SRT | 假设 SRT 已有 |
| 实时配音 | 离线处理即可 |
| 移动端 | Web 优先 |
| 多租户 | MVP 单用户 |

---

## 二、技术架构

### 2.1 整体架构

```text
┌─────────────────────────────────────────────────────┐
│  前端 (React + Tailwind)                            │
│  - 项目管理                                          │
│  - 审核工作台 (Segment 列表、预览、编辑)              │
└─────────────────────────────────────────────────────┘
                        ↓ HTTP API
┌─────────────────────────────────────────────────────┐
│  后端 (FastAPI)                                      │
│  - RESTful API                                      │
│  - WebSocket (任务进度推送)                          │
│  - 鉴权 (JWT)                                       │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  Service 层 (Business Logic)                        │
│  - ProjectService                                   │
│  - SegmentService                                   │
│  - WorkflowService (5 节点编排)                     │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  Provider 层 (能力抽象)                              │
│  - TranslationProvider (Claude)                     │
│  - TTSProvider (ElevenLabs)                         │
│  - VideoProvider (ffmpeg)                           │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  Data 层                                             │
│  - PostgreSQL (项目、Segment、任务)                 │
│  - MinIO/S3 (视频、音频、字幕)                       │
│  - Redis (Celery 队列、缓存)                        │
└─────────────────────────────────────────────────────┘
```

---

### 2.2 技术栈

| 层级 | 技术选型 | 版本 |
|------|----------|------|
| **后端** | FastAPI | 0.115+ |
| **任务队列** | Celery | 5.4+ |
| **数据库** | PostgreSQL | 15+ |
| **缓存/队列** | Redis | 7+ |
| **存储** | MinIO (本地) / S3 (生产) | - |
| **前端** | React + TypeScript | 18+ |
| **UI 组件** | Tailwind CSS + shadcn/ui | - |
| **视频处理** | ffmpeg | 6.0+ |
| **翻译 API** | Claude Opus 4.7 | - |
| **TTS API** | ElevenLabs | - |

---

## 三、5 节点实现方案

### Node 1: 输入理解 (Ingest & Parse)

**目标**: 解析 mp4 + srt, 提取元信息, 建立 Segment 数据模型

#### 实现步骤

1. **上传文件**
   ```python
   POST /api/v1/projects
   - video_file: MP4 上传
   - subtitle_file: SRT 上传
   - source_language: "zh"
   - target_languages: ["en"]
   ```

2. **视频元信息提取** (ffprobe)
   ```bash
   ffprobe -v quiet -print_format json -show_format -show_streams video.mp4
   ```
   提取: 时长、分辨率、帧率、音轨采样率

3. **SRT 解析** (pysrt)
   ```python
   import pysrt
   subs = pysrt.open('subtitle.srt')
   for sub in subs:
       segment = Segment(
           start_time_ms=sub.start.ordinal,
           end_time_ms=sub.end.ordinal,
           source_text=sub.text
       )
   ```

4. **数据入库**
   - 创建 Project 记录
   - 创建 Segment 记录 (每条 SRT → 1 个 Segment)

#### 验收标准
- ✅ 支持标准 MP4 (H.264) + UTF-8 SRT
- ✅ 元信息提取准确
- ✅ Segment 数量 = SRT 条目数
- ✅ 时间戳无偏差

---

### Node 2: 文本本地化 (Localization)

**目标**: 翻译 Segment.source_text → target_text

#### 实现步骤

1. **调用 Claude API**
   ```python
   import anthropic
   
   client = anthropic.Anthropic(api_key=CLAUDE_API_KEY)
   
   message = client.messages.create(
       model="claude-opus-4-7",
       max_tokens=1024,
       messages=[{
           "role": "user",
           "content": f"Translate the following Chinese dialogue to English:\n\n{source_text}"
       }]
   )
   
   target_text = message.content[0].text
   ```

2. **批量处理** (可选优化)
   - 按时间窗分组 (每批 10-20 条)
   - 提供上下文给 LLM

3. **更新 Segment**
   ```python
   segment.target_text = target_text
   segment.save()
   ```

#### 验收标准
- ✅ 翻译准确率 ≥95% (人工抽检 20 条)
- ✅ 处理时间 <5 分钟 (150 条)
- ✅ 成本 <$1 (单集)

---

### Node 3: 配音生成 (Voice Generation)

**目标**: 生成英文配音音频

#### 实现步骤

1. **调用 ElevenLabs API**
   ```python
   from elevenlabs import ElevenLabs
   
   client = ElevenLabs(api_key=ELEVENLABS_API_KEY)
   
   audio = client.generate(
       text=segment.target_text,
       voice="Adam",  # 或自定义音色
       model="eleven_multilingual_v2"
   )
   
   # 保存到 S3
   audio_path = save_to_s3(audio, f"audio/{segment.id}.mp3")
   ```

2. **时长检测**
   ```python
   actual_duration_ms = get_audio_duration(audio_path)
   segment.actual_duration_ms = actual_duration_ms
   ```

3. **时长对齐检测**
   ```python
   if actual_duration_ms > segment.duration_ms * 1.2:
       segment.duration_status = "overflow"
   elif actual_duration_ms > segment.duration_ms * 1.05:
       segment.duration_status = "tight"
   else:
       segment.duration_status = "ok"
   ```

#### 验收标准
- ✅ 生成成功率 ≥95%
- ✅ 音色相似度 ≥0.7 (Resemblyzer)
- ✅ MOS ≥4.0 (人工评分)
- ✅ 时长对齐率 ≥90% (ok + tight)

---

### Node 4: 音视频合成 (Media Composition)

**目标**: 混音 + 字幕渲染 + 导出 MP4

#### 实现步骤

1. **提取原音轨**
   ```bash
   ffmpeg -i video.mp4 -vn -acodec copy original_audio.aac
   ```

2. **简单混音** (MVP 方案: 降低原音 + 叠加配音)
   ```bash
   # 降低原音轨 -12dB
   ffmpeg -i original_audio.aac -filter:a "volume=-12dB" bg_audio.aac
   
   # 合并配音片段
   ffmpeg -f concat -i audio_list.txt -c copy dialogue.mp3
   
   # 混音
   ffmpeg -i bg_audio.aac -i dialogue.mp3 -filter_complex amix=inputs=2 mixed_audio.mp3
   ```

3. **嵌入字幕** (软字幕)
   ```bash
   ffmpeg -i video.mp4 -i target.srt -c copy -c:s mov_text output.mp4
   ```

4. **合成最终视频**
   ```bash
   ffmpeg -i video.mp4 -i mixed_audio.mp3 -i target.srt \
          -map 0:v -map 1:a -map 2:s \
          -c:v copy -c:a aac -c:s mov_text \
          output.mp4
   ```

#### 验收标准
- ✅ 视频可播放
- ✅ 无音画不同步
- ✅ 字幕显示正常
- ✅ 背景音保留 (虽有原对白残留, MVP 可接受)

---

### Node 5: 质量保证 (QA & Iteration)

**目标**: 人工审核、修正、重生成

#### 实现步骤

1. **审核界面**
   ```text
   Segment 列表:
   ┌───────────────────────────────────────────────────────┐
   | ID | Time        | Source Text | Target Text | Status |
   |----|-------------|-------------|-------------|--------|
   | 1  | 00:00:10.5  | 你好        | Hello       | ok     |
   | 2  | 00:00:15.2  | 再见        | Goodbye     | tight  |
   | 3  | 00:00:20.1  | 很长的文本... | Very long... | overflow |
   └───────────────────────────────────────────────────────┘
   
   操作:
   - 点击播放单条音频
   - 编辑 target_text
   - 点击"重生成"
   ```

2. **单句重生成**
   ```python
   PATCH /api/v1/segments/{segment_id}
   {
       "target_text": "修改后的文本"
   }
   
   POST /api/v1/segments/{segment_id}/regenerate
   ```

3. **状态筛选**
   ```python
   GET /api/v1/segments?status=overflow
   GET /api/v1/segments?status=failed
   ```

#### 验收标准
- ✅ 可逐句预览
- ✅ 可修改文本并重生成
- ✅ 可按状态筛选
- ✅ 单句重生成 <10 秒

---

## 四、开发计划

### 4.1 里程碑

| 里程碑 | 时间 | 交付物 | 验收标准 |
|--------|------|--------|----------|
| **M1: 基础架构** | Week 1 | 后端骨架 + Node 1 | 可上传视频、解析 SRT |
| **M2: 翻译 + 配音** | Week 2 | Node 2 + Node 3 | 可生成配音片段 |
| **M3: 合成 + 审核** | Week 3 | Node 4 + Node 5 | 可导出成片 + 审核界面 |
| **M4: 测试验收** | Week 4 | 端到端测试 | 处理 1 集漫剧, 质量达标 |

---

### 4.2 Week 1: 基础架构 + Node 1

#### 任务分解

| 任务 | 负责人 | 工作量 | 依赖 |
|------|--------|--------|------|
| 搭建 FastAPI 后端 | 后端 A | 1 天 | - |
| 搭建 PostgreSQL + Redis | 后端 A | 0.5 天 | - |
| 搭建 MinIO (本地存储) | 后端 A | 0.5 天 | - |
| 实现视频上传 API | 后端 A | 1 天 | 存储 |
| 实现 ffprobe 元信息提取 | 后端 B | 1 天 | - |
| 实现 SRT 解析 | 后端 B | 1 天 | - |
| 实现 Segment 数据模型 | 后端 B | 1 天 | - |
| **总计** | - | **6 人天** | - |

#### 验收清单
- [ ] 可上传 MP4 + SRT
- [ ] 提取视频元信息 (时长、分辨率、帧率)
- [ ] 解析 SRT 为 Segment 列表
- [ ] Segment 数据入库

---

### 4.3 Week 2: 翻译 + 配音

#### 任务分解

| 任务 | 负责人 | 工作量 | 依赖 |
|------|--------|--------|------|
| 集成 Claude API | 后端 A | 1 天 | - |
| 实现翻译 Service | 后端 A | 1 天 | Claude API |
| 实现批量翻译 | 后端 A | 0.5 天 | 翻译 Service |
| 集成 ElevenLabs API | 后端 B | 1 天 | - |
| 实现 TTS Service | 后端 B | 1 天 | ElevenLabs API |
| 实现时长对齐检测 | 后端 B | 0.5 天 | TTS Service |
| 实现 Celery 任务编排 | 后端 A | 1 天 | - |
| **总计** | - | **6 人天** | - |

#### 验收清单
- [ ] 可调用 Claude 翻译
- [ ] 可调用 ElevenLabs TTS
- [ ] 可检测时长对齐状态 (ok/tight/overflow)
- [ ] 任务异步执行 (Celery)

---

### 4.4 Week 3: 合成 + 审核

#### 任务分解

| 任务 | 负责人 | 工作量 | 依赖 |
|------|--------|--------|------|
| 实现 ffmpeg 混音 | 后端 A | 1 天 | - |
| 实现字幕渲染 | 后端 A | 1 天 | - |
| 实现视频导出 | 后端 A | 0.5 天 | 混音 + 字幕 |
| 实现审核 API | 后端 B | 1 天 | - |
| 实现单句重生成 | 后端 B | 0.5 天 | TTS Service |
| 前端: Segment 列表页 | 前端 | 2 天 | API |
| 前端: 编辑 + 预览 | 前端 | 1 天 | API |
| **总计** | - | **7 人天** | - |

#### 验收清单
- [ ] 可混音 + 字幕渲染
- [ ] 可导出 MP4
- [ ] 审核界面可用 (列表、预览、编辑)
- [ ] 可单句重生成

---

### 4.5 Week 4: 测试验收

#### 任务分解

| 任务 | 负责人 | 工作量 |
|------|--------|--------|
| 端到端测试 (1 集漫剧) | 测试 | 2 天 |
| 质量评分 (MOS, 翻译准确率) | 测试 | 1 天 |
| 成本统计 | 后端 | 0.5 天 |
| Bug 修复 | 全员 | 1.5 天 |
| 文档整理 | PM | 0.5 天 |
| **总计** | - | **5.5 人天** |

#### 验收清单
- [ ] 处理 1 集 10 分钟漫剧
- [ ] 翻译质量 ≥4.0/5
- [ ] 配音质量 (MOS) ≥4.0/5
- [ ] 时长对齐率 ≥90%
- [ ] 单集成本 <$5
- [ ] 处理时间 <1 小时 (自动 + 人工)

---

## 五、数据模型

### 5.1 核心实体

```python
# Project (项目)
class Project:
    id: str
    name: str
    video_file_path: str  # S3 路径
    subtitle_file_path: str
    source_language: str  # "zh"
    target_languages: List[str]  # ["en"]
    status: str  # created / processing / completed
    created_at: datetime

# Segment (配音单元)
class Segment:
    id: str
    project_id: str
    source_index: int  # 原 SRT 序号
    start_time_ms: int
    end_time_ms: int
    duration_ms: int
    source_text: str
    target_text: str
    speaker_id: str  # MVP 可为空
    voice_profile_id: str  # MVP 使用默认音色
    actual_duration_ms: int  # 生成音频实际时长
    duration_status: str  # ok / tight / overflow
    generation_status: str  # pending / success / failed
    review_status: str  # pending / approved
    audio_file_path: str  # 生成音频路径

# Job (任务)
class Job:
    id: str
    project_id: str
    job_type: str  # translate / tts / export
    status: str  # pending / running / success / failed
    progress: float  # 0.0 - 1.0
    created_at: datetime
```

---

## 六、API 设计

### 6.1 项目管理

```python
# 创建项目
POST /api/v1/projects
FormData:
  - video_file: MP4
  - subtitle_file: SRT
  - source_language: "zh"
  - target_languages: ["en"]

Response:
{
  "id": "proj_123",
  "name": "漫剧第1集",
  "status": "created"
}

# 获取项目详情
GET /api/v1/projects/{project_id}

Response:
{
  "project": {...},
  "segments": [...],
  "jobs": [...]
}
```

---

### 6.2 Segment 管理

```python
# 列出 Segment
GET /api/v1/projects/{project_id}/segments?status=overflow

Response:
{
  "segments": [
    {
      "id": "seg_1",
      "start_time_ms": 10500,
      "end_time_ms": 15200,
      "source_text": "你好",
      "target_text": "Hello",
      "duration_status": "ok",
      "generation_status": "success"
    }
  ]
}

# 更新 Segment
PATCH /api/v1/segments/{segment_id}
{
  "target_text": "修改后的文本"
}

# 重新生成配音
POST /api/v1/segments/{segment_id}/regenerate
```

---

### 6.3 导出

```python
# 导出成片
POST /api/v1/projects/{project_id}/export
{
  "target_language": "en",
  "subtitle_embed_type": "soft"
}

Response:
{
  "job_id": "job_456",
  "status": "pending"
}

# 查询任务状态
GET /api/v1/jobs/{job_id}

Response:
{
  "id": "job_456",
  "status": "running",
  "progress": 0.6
}
```

---

## 七、测试验收

### 7.1 功能测试

| 测试项 | 验收标准 | 负责人 |
|--------|----------|--------|
| 上传视频 + 字幕 | 成功率 100% | 测试 |
| 解析 SRT | 时间戳准确, 文本完整 | 测试 |
| 翻译 | 准确率 ≥95% (抽检 20 条) | 测试 |
| TTS 生成 | 成功率 ≥95% | 测试 |
| 时长对齐 | 对齐率 ≥90% | 测试 |
| 混音 | 无音画不同步 | 测试 |
| 字幕渲染 | 显示正常 | 测试 |
| 审核界面 | 可预览、编辑、重生成 | 测试 |

---

### 7.2 质量测试

| 测试项 | 目标 | 测试方式 |
|--------|------|----------|
| **翻译质量** | ≥4.0/5 | 人工评分 (5 分制) |
| **配音质量 (MOS)** | ≥4.0/5 | 人工评分 (5 分制) |
| **音色相似度** | ≥0.7 | Resemblyzer cosine similarity |
| **时长对齐率** | ≥90% | (ok + tight) / total |

---

### 7.3 性能测试

| 测试项 | 目标 | 实际 |
|--------|------|------|
| 单集处理时间 | <30 分钟 | - |
| 人工审核时间 | <30 分钟 | - |
| 单句重生成 | <10 秒 | - |

---

### 7.4 成本测试

| 测试项 | 目标 | 实际 |
|--------|------|------|
| 单集运营成本 | <$5 | - |
| 翻译成本 | <$1 | - |
| TTS 成本 | <$2 | - |

---

## 八、风险与缓解

### 8.1 技术风险

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| ElevenLabs API 不稳定 | 生成失败 | 实现重试机制 (3 次) |
| 时长超时严重 | 大量 overflow | 调整 Prompt, 提示缩短文本 |
| 音质失真 | MOS <4.0 | 降低 time-stretch 比例 |
| ffmpeg 合成失败 | 无法导出 | 检查编码格式、分辨率 |

---

### 8.2 资源风险

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 开发人员不足 | 延期 | 优先 P0 功能, 延后 V1 |
| API 配额不足 | 无法测试 | 提前充值、申请配额 |
| GPU 资源不足 | 部署困难 | MVP 全用 API, 不自部署 |

---

## 九、交付清单

### 9.1 代码交付

- [ ] 后端代码 (FastAPI + Celery)
- [ ] 前端代码 (React)
- [ ] 数据库 Schema (PostgreSQL)
- [ ] Docker Compose 配置
- [ ] README (部署说明)

---

### 9.2 文档交付

- [ ] API 文档 (OpenAPI)
- [ ] 部署文档
- [ ] 测试报告
- [ ] 成本分析报告

---

### 9.3 测试数据

- [ ] 测试视频 (1 集 10 分钟)
- [ ] 测试 SRT
- [ ] 质量评分表
- [ ] 成本统计表

---

## 十、后续演进

### V1 (MVP 后 1-2 个月)

- [ ] 音源分离 (Demucs)
- [ ] 批量处理 (10 集+)
- [ ] 多语言同时处理
- [ ] 成本统计看板
- [ ] 硬字幕遮盖

---

### V2 (3-6 个月)

- [ ] 自动说话人识别
- [ ] A/B 测试框架
- [ ] 开源 Provider 评测 (CosyVoice)
- [ ] 质量评分系统

---

**文档版本**: 1.0  
**最后更新**: 2026-06-03  
**维护者**: 王桥  
**项目启动日期**: TBD
