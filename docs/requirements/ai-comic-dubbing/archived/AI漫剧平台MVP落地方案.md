# AI 漫剧平台 MVP 落地方案

> 把 9 节点 ADR 方法论转化为可运行的 FastAPI 后端系统，支持多 provider 切换、人工干预、成本控制和质量监控。

**文档职责**：本文定义 MVP 阶段的后端架构、数据模型、API 设计、Provider 抽象、成本控制、数据安全和运维监控的完整实施方案。

**不负责**：前端 UI 设计、具体 provider 的模型调参、模型训练流程。

**适用读者**：后端开发、系统架构师、DevOps、项目管理。

**前置阅读**：
- [AI 漫剧本地化流水线方法论](./AI漫剧本地化流水线方法论.md) - 理解 9 节点流程
- [AI 配音替换技术坐标与方案选型](./AI配音替换技术坐标与方案选型.md) - 理解技术选型和 provider 策略

---

## 架构设计

### 技术栈

| 层级 | 技术选型 | 说明 |
| --- | --- | --- |
| **Web 框架** | FastAPI | 异步、类型安全、自动 API 文档 |
| **ORM** | SQLAlchemy 2.0 | 支持异步、类型提示、关系建模 |
| **数据库** | PostgreSQL | 稳定、支持 JSON 字段、事务完整 |
| **任务队列** | Celery + Redis | 异步任务编排、长时任务处理 |
| **缓存** | Redis | Session、任务状态、临时数据 |
| **对象存储** | MinIO / S3 | 视频、音频、字幕文件存储 |
| **日志** | structlog + Loki | 结构化日志、集中收集 |
| **监控** | Prometheus + Grafana | 指标监控、可视化 |
| **实时通信** | WebSocket (FastAPI) | 任务进度推送、状态更新 |

### 分层架构

```text
┌─────────────────────────────────────────────────────┐
│  API 层 (FastAPI Router)                            │
│  - RESTful API: CRUD、任务提交、状态查询             │
│  - WebSocket: 实时进度推送                           │
│  - 鉴权: JWT Token                                  │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  Service 层 (Business Logic)                        │
│  - ProjectService: 项目管理                          │
│  - SegmentService: 配音单元管理                      │
│  - WorkflowService: 9节点流程编排                    │
│  - ExportService: 导出与版本管理                     │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  Provider 层 (能力抽象)                              │
│  - TTSProvider: ElevenLabs, CosyVoice, OpenAI TTS   │
│  - TranslationProvider: Claude, GPT-4o, DeepL       │
│  - ASRProvider: WhisperX, Whisper                   │
│  - SourceSeparationProvider: Demucs, UVR5           │
│  - 统一错误处理、重试、熔断、降级                     │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  Data 层 (ORM + Storage)                            │
│  - SQLAlchemy Models: Project, Segment, Speaker...  │
│  - Storage: MinIO / S3                              │
│  - Cache: Redis                                     │
└─────────────────────────────────────────────────────┘
```

### 任务编排

使用 Celery 编排长时任务，支持：
- 异步执行（上传、处理、导出）
- 任务状态追踪（pending / running / success / failed）
- 失败重试与错误处理
- 任务优先级（高优先级任务先执行）
- 进度回调（通过 WebSocket 推送给前端）

```python
# 典型任务流
upload_video.delay(project_id, video_file)
  → ingest_task.delay(project_id)
  → segmentation_task.delay(project_id)
  → localization_task.delay(project_id)  # 可跳过（如已翻译）
  → speaker_binding_task.delay(project_id)
  → tts_generation_task.delay(project_id)
  → alignment_task.delay(project_id)
  → audio_mix_task.delay(project_id)
  → subtitle_render_task.delay(project_id)
  → export_task.delay(project_id)
```

---

## 数据模型设计

### 核心实体关系

```text
Project (项目)
  ├─ Segment (配音单元) *
  │   └─ GeneratedAudio (生成音频) *
  ├─ Speaker (角色) *
  │   └─ VoiceProfile (音色配置)
  ├─ Job (任务) *
  ├─ ExportVersion (导出版本) *
  └─ PronunciationDict (发音词典) *

ProviderCallLog (调用日志) - 独立表
```

### 1. Project（项目）

```python
class Project(Base):
    __tablename__ = "projects"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid4()))
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)

    # 输入文件
    video_file_path = Column(String(512), nullable=False)  # S3/MinIO 路径
    subtitle_file_path = Column(String(512), nullable=False)  # 原 SRT 路径

    # 语言配置
    source_language = Column(String(10), nullable=False)  # "zh", "en", "ja"...
    target_languages = Column(JSON, nullable=False)  # ["en", "fr", "ko"]
    is_translated = Column(Boolean, default=False)  # SRT 是否已是目标语言

    # 媒体元信息
    video_duration_ms = Column(Integer, nullable=True)
    video_resolution = Column(String(20), nullable=True)  # "1920x1080"
    video_fps = Column(Float, nullable=True)
    audio_sample_rate = Column(Integer, nullable=True)
    audio_channels = Column(Integer, nullable=True)

    # 字幕类型
    subtitle_type = Column(String(20), nullable=True)  # "soft" / "burned_in"
    subtitle_region = Column(JSON, nullable=True)  # 硬字幕区域 {"x": 0, "y": 800, "w": 1920, "h": 80}

    # 状态
    status = Column(String(20), default="created")  # created / processing / completed / failed
    current_node = Column(String(50), nullable=True)  # 当前处理节点
    progress = Column(Float, default=0.0)  # 0.0 - 1.0

    # 时间
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # 关系
    segments = relationship("Segment", back_populates="project", cascade="all, delete-orphan")
    speakers = relationship("Speaker", back_populates="project", cascade="all, delete-orphan")
    jobs = relationship("Job", back_populates="project", cascade="all, delete-orphan")
    export_versions = relationship("ExportVersion", back_populates="project")
```

### 2. Segment（配音单元 / Dubbing Cue）

```python
class Segment(Base):
    __tablename__ = "segments"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid4()))
    project_id = Column(String(36), ForeignKey("projects.id"), nullable=False)

    # 来源
    source_index = Column(Integer, nullable=False)  # 原 SRT 序号
    merge_group = Column(String(36), nullable=True)  # 合并组 ID
    split_from = Column(Integer, nullable=True)  # 若从某条 SRT 拆分

    # 时间
    start_time_ms = Column(Integer, nullable=False)
    end_time_ms = Column(Integer, nullable=False)
    duration_ms = Column(Integer, nullable=False)

    # 文本
    source_text = Column(Text, nullable=False)
    target_text = Column(Text, nullable=True)  # 翻译后文本

    # 角色与音色
    speaker_id = Column(String(36), ForeignKey("speakers.id"), nullable=True)
    voice_profile_id = Column(String(36), ForeignKey("voice_profiles.id"), nullable=True)

    # 状态
    duration_status = Column(String(20), default="pending")  # ok / tight / overflow / severe_overflow
    generation_status = Column(String(20), default="pending")  # pending / success / failed / timeout
    review_status = Column(String(20), default="pending")  # pending / approved / rejected

    # 标记
    locked = Column(Boolean, default=False)  # 人工锁定，不被批量操作覆盖
    overlap = Column(Boolean, default=False)  # 与相邻段时间重叠
    length_warning = Column(Boolean, default=False)  # 预估目标语言可能超时

    # 音效
    audio_effect = Column(String(50), nullable=True)  # "robot" / "echo" / "phone" / null
    effect_parameters = Column(JSON, nullable=True)

    # 时间
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # 关系
    project = relationship("Project", back_populates="segments")
    speaker = relationship("Speaker", back_populates="segments")
    voice_profile = relationship("VoiceProfile")
    generated_audios = relationship("GeneratedAudio", back_populates="segment", cascade="all, delete-orphan")
```

### 3. GeneratedAudio（生成音频）

```python
class GeneratedAudio(Base):
    __tablename__ = "generated_audios"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid4()))
    segment_id = Column(String(36), ForeignKey("segments.id"), nullable=False)

    # 音频文件
    audio_file_path = Column(String(512), nullable=False)  # S3/MinIO 路径
    actual_duration_ms = Column(Integer, nullable=False)

    # Provider 信息
    provider_name = Column(String(50), nullable=False)  # "elevenlabs" / "cosyvoice"
    provider_model = Column(String(100), nullable=True)  # "eleven_multilingual_v2"

    # 参数
    generation_parameters = Column(JSON, nullable=True)  # 语速、情绪等

    # Take 管理（支持多次生成）
    take_number = Column(Integer, default=1)  # 第几次生成
    is_active = Column(Boolean, default=True)  # 当前激活的 take

    # 成本
    cost_usd = Column(Float, nullable=True)

    # 时间
    created_at = Column(DateTime, default=datetime.utcnow)

    # 关系
    segment = relationship("Segment", back_populates="generated_audios")
```

### 4. Speaker（角色）

```python
class Speaker(Base):
    __tablename__ = "speakers"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid4()))
    project_id = Column(String(36), ForeignKey("projects.id"), nullable=False)

    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)  # 角色描述（如"女性、年轻、活泼"）

    # 参考音频（用于音色克隆）
    reference_audio_path = Column(String(512), nullable=True)

    # 自动识别
    diarization_cluster_id = Column(String(50), nullable=True)  # pyannote 聚类 ID

    created_at = Column(DateTime, default=datetime.utcnow)

    # 关系
    project = relationship("Project", back_populates="speakers")
    segments = relationship("Segment", back_populates="speaker")
    voice_profiles = relationship("VoiceProfile", back_populates="speaker")
```

### 5. VoiceProfile（音色配置）

```python
class VoiceProfile(Base):
    __tablename__ = "voice_profiles"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid4()))
    speaker_id = Column(String(36), ForeignKey("speakers.id"), nullable=False)

    # Provider 配置
    provider_name = Column(String(50), nullable=False)  # "elevenlabs" / "cosyvoice"
    voice_id = Column(String(100), nullable=True)  # provider 的 voice_id（如 ElevenLabs 音色库 ID）

    # 克隆参数
    clone_reference_audio_path = Column(String(512), nullable=True)  # 用于克隆的参考音频
    clone_parameters = Column(JSON, nullable=True)

    # 生成参数
    default_speed = Column(Float, default=1.0)  # 0.8 - 1.3
    default_emotion = Column(String(50), nullable=True)  # "neutral" / "excited" / "angry"

    # 多语言支持
    target_language = Column(String(10), nullable=True)  # 若 voice profile 绑定特定语言

    created_at = Column(DateTime, default=datetime.utcnow)

    # 关系
    speaker = relationship("Speaker", back_populates="voice_profiles")
```

### 6. Job（任务）

```python
class Job(Base):
    __tablename__ = "jobs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid4()))
    project_id = Column(String(36), ForeignKey("projects.id"), nullable=False)

    # 任务类型
    job_type = Column(String(50), nullable=False)  # "ingest" / "tts_generation" / "export"...

    # Celery 任务 ID
    celery_task_id = Column(String(100), nullable=True)

    # 状态
    status = Column(String(20), default="pending")  # pending / running / success / failed / cancelled
    progress = Column(Float, default=0.0)  # 0.0 - 1.0

    # 错误
    error_message = Column(Text, nullable=True)

    # 断点续传
    checkpoint = Column(JSON, nullable=True)  # {"completed": ["seg_1", "seg_2"]}

    # 时间
    created_at = Column(DateTime, default=datetime.utcnow)
    started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)

    # 关系
    project = relationship("Project", back_populates="jobs")
```

### 7. ExportVersion（导出版本）

```python
class ExportVersion(Base):
    __tablename__ = "export_versions"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid4()))
    project_id = Column(String(36), ForeignKey("projects.id"), nullable=False)

    version_number = Column(Integer, nullable=False)  # 1, 2, 3...
    target_language = Column(String(10), nullable=False)

    # 导出文件
    video_file_path = Column(String(512), nullable=False)
    subtitle_file_path = Column(String(512), nullable=True)  # 独立 SRT
    audio_file_path = Column(String(512), nullable=True)  # 独立音轨

    # 配置
    subtitle_embed_type = Column(String(20), nullable=False)  # "soft" / "burned_in" / "both"

    # 报告
    report = Column(JSON, nullable=True)  # 统计信息、成本、耗时

    created_at = Column(DateTime, default=datetime.utcnow)

    # 关系
    project = relationship("Project", back_populates="export_versions")
```

### 8. ProviderCallLog（调用日志）

```python
class ProviderCallLog(Base):
    __tablename__ = "provider_call_logs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid4()))

    # 关联
    project_id = Column(String(36), nullable=False)
    segment_id = Column(String(36), nullable=True)
    node = Column(String(50), nullable=False)  # "tts_generation" / "localization"...

    # Provider 信息
    provider_name = Column(String(50), nullable=False)
    provider_model = Column(String(100), nullable=True)

    # 调用详情
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime, nullable=True)
    duration_ms = Column(Integer, nullable=True)

    # 状态
    status = Column(String(20), nullable=False)  # success / failed / timeout / retried
    retry_count = Column(Integer, default=0)
    error_message = Column(Text, nullable=True)

    # 成本
    cost_usd = Column(Float, nullable=True)

    # 参数
    request_parameters = Column(JSON, nullable=True)
    response_metadata = Column(JSON, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
```

### 9. PronunciationDict（发音词典）

```python
class PronunciationDict(Base):
    __tablename__ = "pronunciation_dicts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid4()))
    project_id = Column(String(36), ForeignKey("projects.id"), nullable=False)

    term = Column(String(100), nullable=False)  # "鸣人"
    target_language = Column(String(10), nullable=False)  # "en"
    pronunciation = Column(String(200), nullable=False)  # "Naruto" 或 IPA "nɑːruːtoʊ"

    # Provider 特定
    provider = Column(String(50), nullable=True)  # 适用的 provider，null 表示通用

    created_at = Column(DateTime, default=datetime.utcnow)
```

---

## Provider 抽象层

### 设计原则

1. **统一接口**：所有同类 provider 实现统一接口
2. **可替换**：支持运行时切换 provider
3. **错误处理**：统一重试、熔断、降级策略
4. **成本追踪**：每次调用记录成本和耗时
5. **配置驱动**：provider 配置从数据库/配置文件读取

### 1. TTSProvider 接口

```python
from abc import ABC, abstractmethod
from typing import Optional

class TTSProvider(ABC):
    """TTS Provider 抽象接口"""

    @abstractmethod
    async def generate(
        self,
        text: str,
        voice_profile: VoiceProfile,
        target_language: str,
        parameters: Optional[dict] = None
    ) -> TTSResult:
        """
        生成配音

        Args:
            text: 目标语言文本
            voice_profile: 音色配置
            target_language: 目标语言代码
            parameters: 可选参数（语速、情绪等）

        Returns:
            TTSResult(audio_path, duration_ms, cost_usd)
        """
        pass

    @abstractmethod
    async def clone_voice(
        self,
        reference_audio_path: str,
        voice_name: str,
        parameters: Optional[dict] = None
    ) -> VoiceCloneResult:
        """
        克隆音色

        Returns:
            VoiceCloneResult(voice_id, metadata)
        """
        pass

    @abstractmethod
    def estimate_cost(self, text: str, target_language: str) -> float:
        """估算成本（USD）"""
        pass
```

#### 实现示例：ElevenLabsProvider

```python
class ElevenLabsProvider(TTSProvider):
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.client = ElevenLabs(api_key=api_key)

    async def generate(
        self,
        text: str,
        voice_profile: VoiceProfile,
        target_language: str,
        parameters: Optional[dict] = None
    ) -> TTSResult:
        try:
            # 调用 ElevenLabs API
            audio = await self.client.generate(
                text=text,
                voice=voice_profile.voice_id,
                model="eleven_multilingual_v2",
                voice_settings=VoiceSettings(
                    stability=0.5,
                    similarity_boost=0.75,
                    speed=parameters.get("speed", 1.0) if parameters else 1.0
                )
            )

            # 保存音频到 S3
            audio_path = await save_to_storage(audio, f"audio/{uuid4()}.mp3")

            # 计算时长
            duration_ms = await get_audio_duration(audio_path)

            # 估算成本（ElevenLabs 按字符计费）
            cost_usd = len(text) * 0.0003  # 示例价格

            return TTSResult(
                audio_path=audio_path,
                duration_ms=duration_ms,
                cost_usd=cost_usd
            )
        except Exception as e:
            raise ProviderError(f"ElevenLabs generation failed: {str(e)}")

    def estimate_cost(self, text: str, target_language: str) -> float:
        return len(text) * 0.0003
```

### 2. TranslationProvider 接口

```python
class TranslationProvider(ABC):
    """翻译 Provider 抽象接口"""

    @abstractmethod
    async def translate(
        self,
        text: str,
        source_language: str,
        target_language: str,
        context: Optional[dict] = None
    ) -> TranslationResult:
        """
        翻译文本

        Args:
            text: 源文本
            source_language: 源语言
            target_language: 目标语言
            context: 上下文（角色口吻、术语表、前后文等）

        Returns:
            TranslationResult(translated_text, cost_usd)
        """
        pass
```

### 3. Provider 统一错误处理

```python
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type
)

class ProviderError(Exception):
    """Provider 调用错误"""
    pass

class ProviderWrapper:
    """Provider 包装器，统一处理重试、熔断、日志"""

    def __init__(self, provider: TTSProvider, circuit_breaker: CircuitBreaker):
        self.provider = provider
        self.circuit_breaker = circuit_breaker

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=30),
        retry=retry_if_exception_type((NetworkError, TimeoutError))
    )
    async def generate_with_retry(
        self,
        segment: Segment,
        voice_profile: VoiceProfile,
        parameters: dict
    ) -> TTSResult:
        """带重试的生成"""

        # 检查熔断器
        if not self.circuit_breaker.allow_request():
            raise CircuitBreakerOpenError(f"Provider {self.provider.__class__.__name__} is circuit broken")

        start_time = datetime.utcnow()

        try:
            result = await self.provider.generate(
                text=segment.target_text,
                voice_profile=voice_profile,
                target_language=segment.project.target_languages[0],
                parameters=parameters
            )

            # 记录成功
            self.circuit_breaker.record_success()

            # 记录日志
            await self._log_call(
                segment=segment,
                start_time=start_time,
                end_time=datetime.utcnow(),
                status="success",
                cost_usd=result.cost_usd
            )

            return result

        except Exception as e:
            # 记录失败
            self.circuit_breaker.record_failure()

            await self._log_call(
                segment=segment,
                start_time=start_time,
                end_time=datetime.utcnow(),
                status="failed",
                error_message=str(e)
            )

            raise

    async def _log_call(self, segment: Segment, start_time, end_time, status, **kwargs):
        """记录 provider 调用日志"""
        log = ProviderCallLog(
            project_id=segment.project_id,
            segment_id=segment.id,
            node="tts_generation",
            provider_name=self.provider.__class__.__name__,
            start_time=start_time,
            end_time=end_time,
            duration_ms=int((end_time - start_time).total_seconds() * 1000),
            status=status,
            **kwargs
        )
        await db.add(log)
        await db.commit()
```

### 4. 熔断器实现

```python
from datetime import datetime, timedelta

class CircuitBreaker:
    """熔断器"""

    def __init__(
        self,
        failure_threshold: float = 0.5,  # 失败率阈值
        recovery_timeout: int = 1800,  # 恢复超时（秒）
        min_requests: int = 10  # 最小请求数
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.min_requests = min_requests

        self.state = "closed"  # closed / open / half_open
        self.failure_count = 0
        self.success_count = 0
        self.last_failure_time = None

    def allow_request(self) -> bool:
        """是否允许请求"""
        if self.state == "closed":
            return True

        if self.state == "open":
            # 检查是否可以进入半开状态
            if self.last_failure_time and \
               datetime.utcnow() - self.last_failure_time > timedelta(seconds=self.recovery_timeout):
                self.state = "half_open"
                return True
            return False

        # half_open 状态允许少量请求
        return True

    def record_success(self):
        """记录成功"""
        self.success_count += 1

        if self.state == "half_open":
            # 半开状态下连续成功，恢复到关闭状态
            if self.success_count >= 5:
                self.state = "closed"
                self.failure_count = 0
                self.success_count = 0

    def record_failure(self):
        """记录失败"""
        self.failure_count += 1
        self.last_failure_time = datetime.utcnow()

        total_requests = self.failure_count + self.success_count

        if total_requests >= self.min_requests:
            failure_rate = self.failure_count / total_requests

            if failure_rate >= self.failure_threshold:
                self.state = "open"
```

---

## API 设计

### RESTful API 规范

**Base URL**: `/api/v1`

**通用响应格式**:
```json
{
  "code": 0,
  "message": "success",
  "data": {...}
}
```

**错误响应**:
```json
{
  "code": 4001,
  "message": "Segment not found",
  "data": null
}
```

### 1. 项目管理 API

#### POST /projects - 创建项目

```python
@router.post("/projects")
async def create_project(
    name: str = Form(...),
    description: str = Form(None),
    video_file: UploadFile = File(...),
    subtitle_file: UploadFile = File(...),
    source_language: str = Form(...),
    target_languages: List[str] = Form(...),
    is_translated: bool = Form(False),
    current_user: User = Depends(get_current_user)
) -> ProjectResponse:
    """
    创建项目并上传文件

    - **name**: 项目名称
    - **video_file**: MP4 视频文件
    - **subtitle_file**: SRT 字幕文件
    - **source_language**: 源语言（如 "zh", "en", "ja"）
    - **target_languages**: 目标语言列表（如 ["en", "fr"]）
    - **is_translated**: SRT 是否已是目标语言
    """

    # 保存文件到 S3/MinIO
    video_path = await storage.upload(video_file, f"videos/{uuid4()}.mp4")
    subtitle_path = await storage.upload(subtitle_file, f"subtitles/{uuid4()}.srt")

    # 创建项目
    project = Project(
        name=name,
        description=description,
        video_file_path=video_path,
        subtitle_file_path=subtitle_path,
        source_language=source_language,
        target_languages=target_languages,
        is_translated=is_translated,
        status="created"
    )
    db.add(project)
    await db.commit()

    # 异步启动 ingest 任务
    ingest_task.delay(project.id)

    return ProjectResponse(
        code=0,
        message="Project created",
        data=project
    )
```

#### GET /projects/{project_id} - 获取项目详情

```python
@router.get("/projects/{project_id}")
async def get_project(
    project_id: str,
    current_user: User = Depends(get_current_user)
) -> ProjectResponse:
    """获取项目详情，包括所有 segments 和 speakers"""

    project = await db.get(Project, project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    return ProjectResponse(
        code=0,
        message="success",
        data={
            "project": project,
            "segments": project.segments,
            "speakers": project.speakers,
            "jobs": project.jobs[-5:]  # 最近 5 个任务
        }
    )
```

#### GET /projects - 列出项目

```python
@router.get("/projects")
async def list_projects(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    status: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user)
) -> ProjectListResponse:
    """列出项目（分页）"""

    query = select(Project).where(Project.user_id == current_user.id)

    if status:
        query = query.where(Project.status == status)

    query = query.order_by(Project.created_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)

    projects = await db.execute(query)
    total = await db.scalar(select(func.count(Project.id)))

    return ProjectListResponse(
        code=0,
        message="success",
        data={
            "projects": projects.scalars().all(),
            "total": total,
            "page": page,
            "page_size": page_size
        }
    )
```

### 2. Segment（配音单元）管理 API

#### GET /projects/{project_id}/segments - 列出所有配音单元

```python
@router.get("/projects/{project_id}/segments")
async def list_segments(
    project_id: str,
    status: Optional[str] = Query(None),
    speaker_id: Optional[str] = Query(None)
) -> SegmentListResponse:
    """
    列出项目的所有配音单元

    - **status**: 筛选状态（如 "overflow", "failed"）
    - **speaker_id**: 筛选角色
    """

    query = select(Segment).where(Segment.project_id == project_id)

    if status:
        query = query.where(Segment.duration_status == status)

    if speaker_id:
        query = query.where(Segment.speaker_id == speaker_id)

    query = query.order_by(Segment.start_time_ms)

    segments = await db.execute(query)

    return SegmentListResponse(
        code=0,
        message="success",
        data=segments.scalars().all()
    )
```

#### PATCH /segments/{segment_id} - 更新配音单元

```python
@router.patch("/segments/{segment_id}")
async def update_segment(
    segment_id: str,
    update_data: SegmentUpdateRequest
) -> SegmentResponse:
    """
    更新配音单元（人工干预）

    支持修改：
    - target_text: 目标语言文本
    - start_time_ms / end_time_ms: 时间窗
    - speaker_id: 角色
    - locked: 锁定状态
    - review_status: 审核状态
    """

    segment = await db.get(Segment, segment_id)
    if not segment:
        raise HTTPException(status_code=404, detail="Segment not found")

    # 更新字段
    for field, value in update_data.dict(exclude_unset=True).items():
        setattr(segment, field, value)

    # 如果修改了 target_text，标记需要重新生成
    if "target_text" in update_data.dict(exclude_unset=True):
        segment.generation_status = "pending"

    await db.commit()

    return SegmentResponse(
        code=0,
        message="Segment updated",
        data=segment
    )
```

#### POST /segments/{segment_id}/regenerate - 重新生成配音

```python
@router.post("/segments/{segment_id}/regenerate")
async def regenerate_segment(
    segment_id: str,
    provider_name: Optional[str] = None,
    parameters: Optional[dict] = None
) -> JobResponse:
    """
    重新生成单条配音单元的配音

    - **provider_name**: 可选，指定 provider（如 "elevenlabs", "cosyvoice"）
    - **parameters**: 可选参数（如 {"speed": 1.2, "emotion": "excited"}）
    """

    segment = await db.get(Segment, segment_id)
    if not segment:
        raise HTTPException(status_code=404, detail="Segment not found")

    # 创建任务
    job = Job(
        project_id=segment.project_id,
        job_type="regenerate_segment",
        status="pending"
    )
    db.add(job)
    await db.commit()

    # 异步执行
    regenerate_segment_task.delay(
        segment_id=segment_id,
        job_id=job.id,
        provider_name=provider_name,
        parameters=parameters
    )

    return JobResponse(
        code=0,
        message="Regeneration started",
        data=job
    )
```

#### POST /segments/merge - 合并配音单元

```python
@router.post("/segments/merge")
async def merge_segments(
    segment_ids: List[str]
) -> SegmentResponse:
    """
    合并多个相邻配音单元

    - 保留第一条的 source_index
    - 合并 source_text 和 target_text
    - 时间窗取第一条的 start_time 和最后一条的 end_time
    """

    segments = await db.execute(
        select(Segment)
        .where(Segment.id.in_(segment_ids))
        .order_by(Segment.start_time_ms)
    )
    segments = segments.scalars().all()

    if len(segments) < 2:
        raise HTTPException(status_code=400, detail="Need at least 2 segments to merge")

    # 创建合并后的 segment
    merge_group_id = str(uuid4())
    merged = Segment(
        project_id=segments[0].project_id,
        source_index=segments[0].source_index,
        merge_group=merge_group_id,
        start_time_ms=segments[0].start_time_ms,
        end_time_ms=segments[-1].end_time_ms,
        duration_ms=segments[-1].end_time_ms - segments[0].start_time_ms,
        source_text=" ".join([s.source_text for s in segments]),
        target_text=" ".join([s.target_text for s in segments if s.target_text]),
        speaker_id=segments[0].speaker_id
    )
    db.add(merged)

    # 删除原 segments
    for seg in segments:
        await db.delete(seg)

    await db.commit()

    return SegmentResponse(
        code=0,
        message="Segments merged",
        data=merged
    )
```

### 3. Speaker（角色）管理 API

#### POST /projects/{project_id}/speakers - 创建角色

```python
@router.post("/projects/{project_id}/speakers")
async def create_speaker(
    project_id: str,
    name: str,
    description: Optional[str] = None,
    reference_audio: Optional[UploadFile] = File(None)
) -> SpeakerResponse:
    """
    创建角色

    - **name**: 角色名称
    - **description**: 角色描述（如"女性、年轻、活泼"）
    - **reference_audio**: 可选，参考音频（用于音色克隆）
    """

    reference_audio_path = None
    if reference_audio:
        reference_audio_path = await storage.upload(
            reference_audio,
            f"references/{uuid4()}.wav"
        )

    speaker = Speaker(
        project_id=project_id,
        name=name,
        description=description,
        reference_audio_path=reference_audio_path
    )
    db.add(speaker)
    await db.commit()

    return SpeakerResponse(
        code=0,
        message="Speaker created",
        data=speaker
    )
```

#### POST /speakers/{speaker_id}/voice-profiles - 创建音色配置

```python
@router.post("/speakers/{speaker_id}/voice-profiles")
async def create_voice_profile(
    speaker_id: str,
    provider_name: str,
    voice_id: Optional[str] = None,
    clone_reference_audio: Optional[UploadFile] = File(None),
    target_language: Optional[str] = None,
    parameters: Optional[dict] = None
) -> VoiceProfileResponse:
    """
    为角色创建音色配置

    - **provider_name**: provider 名称（如 "elevenlabs"）
    - **voice_id**: 可选，provider 的音色库 ID
    - **clone_reference_audio**: 可选，用于克隆的参考音频
    - **target_language**: 可选，绑定特定语言
    - **parameters**: 可选参数（如 {"default_speed": 1.1}）
    """

    clone_audio_path = None
    if clone_reference_audio:
        clone_audio_path = await storage.upload(
            clone_reference_audio,
            f"clones/{uuid4()}.wav"
        )

    voice_profile = VoiceProfile(
        speaker_id=speaker_id,
        provider_name=provider_name,
        voice_id=voice_id,
        clone_reference_audio_path=clone_audio_path,
        target_language=target_language,
        default_speed=parameters.get("default_speed", 1.0) if parameters else 1.0,
        default_emotion=parameters.get("default_emotion") if parameters else None
    )
    db.add(voice_profile)
    await db.commit()

    return VoiceProfileResponse(
        code=0,
        message="Voice profile created",
        data=voice_profile
    )
```

### 4. 任务管理 API

#### GET /jobs/{job_id} - 获取任务状态

```python
@router.get("/jobs/{job_id}")
async def get_job(job_id: str) -> JobResponse:
    """获取任务状态"""

    job = await db.get(Job, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    return JobResponse(
        code=0,
        message="success",
        data=job
    )
```

#### POST /jobs/{job_id}/cancel - 取消任务

```python
@router.post("/jobs/{job_id}/cancel")
async def cancel_job(job_id: str) -> JobResponse:
    """取消运行中的任务"""

    job = await db.get(Job, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    if job.status in ["success", "failed", "cancelled"]:
        raise HTTPException(status_code=400, detail="Job already finished")

    # 取消 Celery 任务
    if job.celery_task_id:
        celery_app.control.revoke(job.celery_task_id, terminate=True)

    job.status = "cancelled"
    await db.commit()

    return JobResponse(
        code=0,
        message="Job cancelled",
        data=job
    )
```

### 5. 导出 API

#### POST /projects/{project_id}/export - 导出成片

```python
@router.post("/projects/{project_id}/export")
async def export_project(
    project_id: str,
    target_language: str,
    subtitle_embed_type: str = "soft",  # soft / burned_in / both
    include_separate_audio: bool = False,
    include_separate_subtitle: bool = True
) -> ExportResponse:
    """
    导出成片

    - **target_language**: 目标语言
    - **subtitle_embed_type**: 字幕嵌入方式（soft/burned_in/both）
    - **include_separate_audio**: 是否导出独立音轨
    - **include_separate_subtitle**: 是否导出独立 SRT
    """

    project = await db.get(Project, project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    # 检查是否所有 segment 都已审核
    pending_segments = await db.scalar(
        select(func.count(Segment.id))
        .where(Segment.project_id == project_id)
        .where(Segment.review_status == "pending")
    )

    if pending_segments > 0:
        # 可以警告，但不强制阻止导出
        pass

    # 创建任务
    job = Job(
        project_id=project_id,
        job_type="export",
        status="pending"
    )
    db.add(job)
    await db.commit()

    # 异步执行导出
    export_task.delay(
        project_id=project_id,
        job_id=job.id,
        target_language=target_language,
        subtitle_embed_type=subtitle_embed_type,
        include_separate_audio=include_separate_audio,
        include_separate_subtitle=include_separate_subtitle
    )

    return ExportResponse(
        code=0,
        message="Export started",
        data=job
    )
```

#### GET /projects/{project_id}/exports - 列出导出版本

```python
@router.get("/projects/{project_id}/exports")
async def list_exports(project_id: str) -> ExportListResponse:
    """列出项目的所有导出版本"""

    exports = await db.execute(
        select(ExportVersion)
        .where(ExportVersion.project_id == project_id)
        .order_by(ExportVersion.created_at.desc())
    )

    return ExportListResponse(
        code=0,
        message="success",
        data=exports.scalars().all()
    )
```

### 6. WebSocket 实时推送

```python
from fastapi import WebSocket

@app.websocket("/ws/projects/{project_id}")
async def project_websocket(websocket: WebSocket, project_id: str):
    """
    项目实时状态推送

    推送内容：
    - 任务进度更新
    - Segment 状态变化
    - 错误告警
    """
    await websocket.accept()

    # 订阅 Redis channel
    channel = f"project:{project_id}"
    pubsub = redis.pubsub()
    await pubsub.subscribe(channel)

    try:
        async for message in pubsub.listen():
            if message["type"] == "message":
                data = json.loads(message["data"])
                await websocket.send_json(data)
    except WebSocketDisconnect:
        await pubsub.unsubscribe(channel)
```

---

## 成本控制

### 成本计算模型

```python
class CostCalculator:
    """成本计算器"""

    # Provider 单价（USD）
    PRICING = {
        "elevenlabs": {
            "tts": 0.0003,  # per character
            "voice_clone": 1.0  # per clone
        },
        "openai": {
            "tts": 0.000015,  # per character
            "gpt4o": 0.00001,  # per token (output)
        },
        "claude": {
            "opus_4_7": 0.000075  # per token (output)
        },
        "deepl": {
            "translation": 0.00002  # per character
        },
        "cosyvoice": {
            "tts": 0.0,  # 自部署，GPU 成本单独计算
            "gpu_hour": 1.5  # GPU 实例小时成本
        }
    }

    @staticmethod
    def estimate_tts_cost(provider_name: str, text: str) -> float:
        """估算 TTS 成本"""
        if provider_name == "elevenlabs":
            return len(text) * CostCalculator.PRICING["elevenlabs"]["tts"]
        elif provider_name == "openai":
            return len(text) * CostCalculator.PRICING["openai"]["tts"]
        elif provider_name == "cosyvoice":
            # 自部署按 GPU 时间估算
            estimated_seconds = len(text) / 10  # 假设 10 字/秒
            gpu_hours = estimated_seconds / 3600
            return gpu_hours * CostCalculator.PRICING["cosyvoice"]["gpu_hour"]
        else:
            return 0.0

    @staticmethod
    def estimate_translation_cost(provider_name: str, text: str) -> float:
        """估算翻译成本"""
        if provider_name in ["gpt4o", "claude"]:
            # LLM 按 token 计费，粗略估算 1 字 = 1.5 token
            tokens = len(text) * 1.5
            if provider_name == "gpt4o":
                return tokens * CostCalculator.PRICING["openai"]["gpt4o"]
            else:
                return tokens * CostCalculator.PRICING["claude"]["opus_4_7"]
        elif provider_name == "deepl":
            return len(text) * CostCalculator.PRICING["deepl"]["translation"]
        else:
            return 0.0

    @staticmethod
    async def estimate_project_cost(project_id: str) -> dict:
        """估算整个项目成本"""
        segments = await db.execute(
            select(Segment).where(Segment.project_id == project_id)
        )
        segments = segments.scalars().all()

        total_tts_cost = 0.0
        total_translation_cost = 0.0

        for seg in segments:
            # TTS 成本
            if seg.voice_profile and seg.target_text:
                provider_name = seg.voice_profile.provider_name
                total_tts_cost += CostCalculator.estimate_tts_cost(
                    provider_name,
                    seg.target_text
                )

            # 翻译成本（假设使用 Claude）
            if seg.source_text:
                total_translation_cost += CostCalculator.estimate_translation_cost(
                    "claude",
                    seg.source_text
                )

        return {
            "tts_cost_usd": round(total_tts_cost, 4),
            "translation_cost_usd": round(total_translation_cost, 4),
            "total_cost_usd": round(total_tts_cost + total_translation_cost, 4),
            "segment_count": len(segments)
        }
```

### 预算控制

```python
class BudgetControl:
    """预算控制"""

    @staticmethod
    async def check_budget(project_id: str, max_budget_usd: float) -> bool:
        """检查预算是否超限"""

        # 计算已花费成本
        spent = await db.scalar(
            select(func.sum(ProviderCallLog.cost_usd))
            .where(ProviderCallLog.project_id == project_id)
        ) or 0.0

        # 估算剩余成本
        estimated = await CostCalculator.estimate_project_cost(project_id)

        total_estimated = spent + estimated["total_cost_usd"]

        if total_estimated > max_budget_usd:
            # 触发告警
            await send_budget_alert(project_id, total_estimated, max_budget_usd)
            return False

        return True

    @staticmethod
    async def suggest_cost_optimization(project_id: str) -> dict:
        """成本优化建议"""

        # 分析 provider 调用日志
        logs = await db.execute(
            select(ProviderCallLog)
            .where(ProviderCallLog.project_id == project_id)
        )
        logs = logs.scalars().all()

        suggestions = []

        # 统计各 provider 成本
        provider_costs = {}
        for log in logs:
            provider_costs[log.provider_name] = provider_costs.get(log.provider_name, 0) + (log.cost_usd or 0)

        # 建议切换到更便宜的 provider
        if "elevenlabs" in provider_costs and provider_costs["elevenlabs"] > 10:
            suggestions.append({
                "type": "switch_provider",
                "message": "Consider switching from ElevenLabs to CosyVoice for TTS to reduce cost",
                "potential_saving_usd": provider_costs["elevenlabs"] * 0.7
            })

        return {
            "current_cost_usd": sum(provider_costs.values()),
            "suggestions": suggestions
        }
```

---

## 数据安全与合规

### 数据加密

```python
from cryptography.fernet import Fernet

class DataEncryption:
    """数据加密"""

    def __init__(self, encryption_key: str):
        self.cipher = Fernet(encryption_key.encode())

    def encrypt_file(self, file_path: str) -> str:
        """加密文件"""
        with open(file_path, "rb") as f:
            data = f.read()

        encrypted_data = self.cipher.encrypt(data)

        encrypted_path = f"{file_path}.enc"
        with open(encrypted_path, "wb") as f:
            f.write(encrypted_data)

        return encrypted_path

    def decrypt_file(self, encrypted_path: str) -> str:
        """解密文件"""
        with open(encrypted_path, "rb") as f:
            encrypted_data = f.read()

        data = self.cipher.decrypt(encrypted_data)

        decrypted_path = encrypted_path.replace(".enc", "")
        with open(decrypted_path, "wb") as f:
            f.write(data)

        return decrypted_path
```

### 访问控制

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> User:
    """获取当前用户（JWT 验证）"""
    token = credentials.credentials

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expired"
        )
    except jwt.JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )

    return user

async def check_project_permission(
    project_id: str,
    current_user: User = Depends(get_current_user)
):
    """检查项目权限"""
    project = await db.get(Project, project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    if project.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Permission denied")

    return project
```

### GDPR / 数据删除

```python
@router.delete("/projects/{project_id}")
async def delete_project(
    project_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    删除项目及其所有数据（符合 GDPR 要求）

    删除内容：
    - 项目记录
    - 所有 segments、speakers、voice profiles
    - 所有上传文件（视频、音频、字幕）
    - 所有 provider 调用日志
    - 所有导出版本
    """

    project = await check_project_permission(project_id, current_user)

    # 删除文件
    files_to_delete = [
        project.video_file_path,
        project.subtitle_file_path
    ]

    # 收集所有相关文件
    for seg in project.segments:
        for audio in seg.generated_audios:
            files_to_delete.append(audio.audio_file_path)

    for speaker in project.speakers:
        if speaker.reference_audio_path:
            files_to_delete.append(speaker.reference_audio_path)
        for vp in speaker.voice_profiles:
            if vp.clone_reference_audio_path:
                files_to_delete.append(vp.clone_reference_audio_path)

    for export in project.export_versions:
        files_to_delete.extend([
            export.video_file_path,
            export.subtitle_file_path,
            export.audio_file_path
        ])

    # 删除存储文件
    for file_path in files_to_delete:
        if file_path:
            await storage.delete(file_path)

    # 删除数据库记录（cascade 会自动删除相关记录）
    await db.delete(project)

    # 删除 provider 调用日志
    await db.execute(
        delete(ProviderCallLog).where(ProviderCallLog.project_id == project_id)
    )

    await db.commit()

    return {"code": 0, "message": "Project deleted"}
```

### 审计日志

```python
class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid4()))
    user_id = Column(String(36), nullable=False)
    action = Column(String(100), nullable=False)  # "create_project" / "update_segment"
    resource_type = Column(String(50), nullable=False)  # "project" / "segment"
    resource_id = Column(String(36), nullable=False)
    details = Column(JSON, nullable=True)
    ip_address = Column(String(50), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

async def log_audit(
    user: User,
    action: str,
    resource_type: str,
    resource_id: str,
    details: dict = None,
    request: Request = None
):
    """记录审计日志"""
    log = AuditLog(
        user_id=user.id,
        action=action,
        resource_type=resource_type,
        resource_id=resource_id,
        details=details,
        ip_address=request.client.host if request else None
    )
    db.add(log)
    await db.commit()
```

---

## 测试验收清单

### 功能测试

#### Node 1: Ingest

- [ ] 正常上传 MP4 + SRT
- [ ] 检测视频元信息（时长、分辨率、帧率）
- [ ] 检测音频元信息（采样率、声道数）
- [ ] SRT 校验（时间越界、重叠、空文本、乱序）
- [ ] 编码检测与转换（非 UTF-8）
- [ ] 软字幕 vs 硬字幕检测
- [ ] 硬字幕区域估计

#### Node 2: Segmentation

- [ ] SRT 转 Segment 建模
- [ ] 时间窗计算正确
- [ ] 合并相邻 segments
- [ ] 拆分单条 segment
- [ ] 检测重叠对话
- [ ] 检测静音段

#### Node 3: Localization

- [ ] 单条翻译（多 provider）
- [ ] 批量翻译
- [ ] 术语表替换
- [ ] 角色口吻注入
- [ ] 时长预警
- [ ] 已翻译 SRT 跳过翻译

#### Node 4: Speaker Binding

- [ ] 自动说话人识别（pyannote）
- [ ] 人工创建角色
- [ ] 人工绑定 segment → speaker
- [ ] 音色克隆（ElevenLabs）
- [ ] 音色库选择
- [ ] 人声分离提取参考音频

#### Node 5: TTS Generation

- [ ] 单条生成（ElevenLabs）
- [ ] 单条生成（CosyVoice）
- [ ] 批量生成
- [ ] 重新生成（Re-take）
- [ ] 语速调整
- [ ] 情绪参数
- [ ] 专有名词音素标注
- [ ] 生成失败重试

#### Node 6: Alignment

- [ ] 时长差异检测（ok/tight/overflow/severe_overflow）
- [ ] Time-stretch（librosa）
- [ ] 静默填充
- [ ] 超时标记
- [ ] 退回修改文本

#### Node 7: Audio Mix

- [ ] 音源分离（Demucs）
- [ ] 保留背景音 + 替换人声
- [ ] 音频闪避（Ducking）
- [ ] 响度归一化
- [ ] 静音段保留原音轨

#### Node 8: Subtitle Render

- [ ] 软字幕嵌入
- [ ] 硬字幕遮罩 + 渲染
- [ ] 字幕样式配置
- [ ] 动态字号
- [ ] 独立 SRT 导出

#### Node 9: Export

- [ ] 导出前检查（failed/pending/overflow）
- [ ] 视频合成
- [ ] 版本管理（不覆盖历史）
- [ ] 处理报告生成
- [ ] 成本统计

### 性能测试

| 测试项 | 目标 | 说明 |
| --- | --- | --- |
| **并发创建项目** | 支持 10 并发 | 同时上传 10 个项目 |
| **单 segment TTS 响应时延** | P95 <30s | ElevenLabs API 调用 |
| **批量 TTS（100 segments）** | 完成时间 <15min | 并行处理 |
| **导出 10 分钟视频** | 完成时间 <5min | 包含混音、字幕渲染 |
| **数据库查询性能** | 列出 1000 segments <500ms | 需要索引优化 |

### 质量测试

| 测试项 | 目标 | 说明 |
| --- | --- | --- |
| **TTS 主观质量（MOS）** | ≥4.0 | 5 分制，人工评分 |
| **音色相似度** | ≥0.7 | Resemblyzer cosine similarity |
| **翻译准确率** | ≥95% | 人工评估，样本 100 条 |
| **时长对齐成功率** | ≥90% | 实际时长在时间窗 ±20% 内 |
| **音源分离质量（SDR）** | ≥10dB | Signal-to-Distortion Ratio |

### 兼容性测试

| 测试项 | 覆盖范围 |
| --- | --- |
| **视频格式** | MP4（H.264/H.265）、MOV、AVI |
| **音频编码** | AAC、MP3、PCM |
| **字幕格式** | SRT、ASS、VTT |
| **字幕编码** | UTF-8、GBK、Shift-JIS |
| **语言覆盖** | 英、法、日、韩、中、西、印尼、泰 |
| **Provider** | ElevenLabs、CosyVoice、OpenAI TTS、Demucs、WhisperX |

---

## 运维与监控

### 日志体系

```python
import structlog

logger = structlog.get_logger()

# 结构化日志示例
logger.info(
    "segment_generated",
    project_id=project_id,
    segment_id=segment_id,
    provider="elevenlabs",
    duration_ms=duration_ms,
    cost_usd=cost_usd
)
```

### 监控指标（Prometheus）

#### 业务指标

```python
from prometheus_client import Counter, Histogram, Gauge

# TTS 生成次数
tts_generation_total = Counter(
    "tts_generation_total",
    "Total TTS generations",
    ["provider", "status"]
)

# TTS 生成时延
tts_generation_duration = Histogram(
    "tts_generation_duration_seconds",
    "TTS generation duration",
    ["provider"]
)

# 活跃项目数
active_projects = Gauge(
    "active_projects",
    "Number of active projects"
)

# Provider 调用成本
provider_cost_total = Counter(
    "provider_cost_total_usd",
    "Total provider cost in USD",
    ["provider", "node"]
)

# 使用示例
tts_generation_total.labels(provider="elevenlabs", status="success").inc()
tts_generation_duration.labels(provider="elevenlabs").observe(5.2)
provider_cost_total.labels(provider="elevenlabs", node="tts_generation").inc(0.15)
```

#### 系统指标

- CPU 使用率
- 内存使用率
- 磁盘使用率
- 数据库连接池状态
- Celery worker 队列长度
- Redis 连接数

### 告警规则

```yaml
# Prometheus 告警规则示例
groups:
  - name: ai_dubbing_alerts
    rules:
      # TTS 失败率过高
      - alert: HighTTSFailureRate
        expr: |
          rate(tts_generation_total{status="failed"}[5m]) /
          rate(tts_generation_total[5m]) > 0.3
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High TTS failure rate (>30%)"
          description: "Provider {{ $labels.provider }} failure rate is {{ $value }}"

      # Provider 成本超预算
      - alert: ProviderCostExceeded
        expr: provider_cost_total_usd > 100
        for: 1h
        labels:
          severity: critical
        annotations:
          summary: "Provider cost exceeded $100/hour"
          description: "Provider {{ $labels.provider }} cost is ${{ $value }}"

      # Celery 队列积压
      - alert: CeleryQueueBacklog
        expr: celery_queue_length > 100
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Celery queue backlog (>100 tasks)"
```

### 健康检查

```python
@router.get("/health")
async def health_check():
    """健康检查端点"""

    checks = {
        "database": await check_database(),
        "redis": await check_redis(),
        "storage": await check_storage(),
        "celery": await check_celery()
    }

    all_healthy = all(checks.values())
    status_code = 200 if all_healthy else 503

    return JSONResponse(
        status_code=status_code,
        content={
            "status": "healthy" if all_healthy else "unhealthy",
            "checks": checks,
            "timestamp": datetime.utcnow().isoformat()
        }
    )

async def check_database() -> bool:
    """检查数据库连接"""
    try:
        await db.execute(select(1))
        return True
    except Exception:
        return False

async def check_redis() -> bool:
    """检查 Redis 连接"""
    try:
        await redis.ping()
        return True
    except Exception:
        return False

async def check_storage() -> bool:
    """检查对象存储"""
    try:
        await storage.list_buckets()
        return True
    except Exception:
        return False

async def check_celery() -> bool:
    """检查 Celery worker"""
    try:
        stats = celery_app.control.inspect().stats()
        return bool(stats)
    except Exception:
        return False
```

---

## 部署方案

### Docker Compose 示例

```yaml
version: '3.8'

services:
  # FastAPI 后端
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:pass@postgres:5432/dubbing
      - REDIS_URL=redis://redis:6379/0
      - MINIO_ENDPOINT=minio:9000
    depends_on:
      - postgres
      - redis
      - minio
    volumes:
      - ./logs:/app/logs

  # Celery worker
  worker:
    build: .
    command: celery -A app.celery worker --loglevel=info --concurrency=4
    environment:
      - DATABASE_URL=postgresql://user:pass@postgres:5432/dubbing
      - REDIS_URL=redis://redis:6379/0
      - MINIO_ENDPOINT=minio:9000
    depends_on:
      - postgres
      - redis
      - minio
    volumes:
      - ./logs:/app/logs

  # PostgreSQL
  postgres:
    image: postgres:15
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=dubbing
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  # Redis
  redis:
    image: redis:7
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  # MinIO（对象存储）
  minio:
    image: minio/minio
    command: server /data --console-address ":9001"
    environment:
      - MINIO_ROOT_USER=minioadmin
      - MINIO_ROOT_PASSWORD=minioadmin
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - minio_data:/data

  # Prometheus
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus

  # Grafana
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana

volumes:
  postgres_data:
  redis_data:
  minio_data:
  prometheus_data:
  grafana_data:
```

---

## 下一步演进

### V1 功能

- 开源 provider 完整接入（CosyVoice、OpenVoice、WhisperX、Demucs）
- 质量评分系统（MOS、音色相似度自动评估）
- A/B 测试框架（对比不同 provider 效果）
- 批量任务优化（并行处理、资源调度）

### V2 功能

- 自动说话人识别优化（多说话人场景）
- 字幕模板库（不同风格的字幕排版）
- 音效库管理（robot、echo、phone 等）
- 长视频优化（分段处理、增量更新）

### V3 功能

- 音色库管理（角色音色沉淀与复用）
- 分段优化算法（自动识别合并/拆分点）
- 多语言字幕同时导出
- 成本优化建议引擎

### V4 功能

- 基于平台数据微调 TTS 模型
- 自研翻译模型（针对漫剧领域）
- Lip-sync 能力（真人短剧支持）
- 实时预览与协作编辑

---

## 附录

### Provider 配置示例

```yaml
# config/providers.yaml
providers:
  tts:
    elevenlabs:
      api_key: ${ELEVENLABS_API_KEY}
      model: eleven_multilingual_v2
      priority: 1
      enabled: true
      cost_per_char: 0.0003

    cosyvoice:
      api_url: http://cosyvoice:8000
      priority: 2
      enabled: true
      cost_per_char: 0.0

    openai:
      api_key: ${OPENAI_API_KEY}
      model: tts-1-hd
      priority: 3
      enabled: true
      cost_per_char: 0.000015

  translation:
    claude:
      api_key: ${ANTHROPIC_API_KEY}
      model: claude-opus-4-7
      priority: 1
      enabled: true

    deepl:
      api_key: ${DEEPL_API_KEY}
      priority: 2
      enabled: true

  asr:
    whisperx:
      model: large-v3
      device: cuda
      priority: 1
      enabled: true

  source_separation:
    demucs:
      model: htdemucs
      device: cuda
      priority: 1
      enabled: true
```

### 数据库索引建议

```sql
-- segments 表
CREATE INDEX idx_segments_project_id ON segments(project_id);
CREATE INDEX idx_segments_speaker_id ON segments(speaker_id);
CREATE INDEX idx_segments_status ON segments(generation_status);
CREATE INDEX idx_segments_time ON segments(start_time_ms, end_time_ms);

-- provider_call_logs 表
CREATE INDEX idx_provider_logs_project_id ON provider_call_logs(project_id);
CREATE INDEX idx_provider_logs_segment_id ON provider_call_logs(segment_id);
CREATE INDEX idx_provider_logs_provider ON provider_call_logs(provider_name);
CREATE INDEX idx_provider_logs_time ON provider_call_logs(created_at);

-- jobs 表
CREATE INDEX idx_jobs_project_id ON jobs(project_id);
CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_type ON jobs(job_type);
```

---

**文档版本**: 1.0
**最后更新**: 2026-06-02
**维护者**: AI 漫剧平台开发团队
