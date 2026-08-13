---
description: 分析复杂流程、数据管线与执行链路时使用的现状还原、节点合同和优化提示词规则
---

# Pipeline 分析提示词规则

这份规则用于把复杂系统先还原成可理解、可验证、可优化的 pipeline，再讨论优化方案。

## 文档职责

本文负责沉淀一套可复用提示词，用于分析复杂项目中的流程、任务链路、数据管线、推理链路、批处理链路、同步/异步工作流或多阶段处理系统。

它不负责绑定某个具体业务、框架、运行机制、日志平台或部署工具。具体项目里的专有名词、工具、命令、服务和实现常量，只能作为证据或示例进入分析，不应进入主规则。

## 核心心智模型

复杂系统分析不要从“怎么优化”开始，而要先回答：

```text
边界是什么 -> 当前怎么流动 -> 每个节点吃什么吐什么 -> 哪些状态和副作用被改变 -> 哪些约束不能破坏 -> 证据显示哪里有问题 -> 哪些优化能在保持合同的前提下发生
```

稳定的分析顺序是：

```text
System Boundary
  -> Current Pipeline
  -> Node Contracts
  -> Data Shape Changes
  -> Execution Model
  -> Observability
  -> Bottleneck / Risk
  -> Optimization Plan
  -> Verification / Rollback
```

如果现状没有梳理清楚，不要直接给优化建议。优化方案必须挂到明确节点、明确合同和明确证据上。

## 适用场景

适用于：

- 一个请求、任务、文件、事件或数据对象会经过多个处理阶段。
- 系统存在下载、解析、转换、远程调用、批处理、并发、持久化、上传、回调、清理等隐性节点。
- 用户想知道“现在到底怎么跑”“慢在哪里”“能不能 batch/并发/下沉/替换”。
- 项目已经调通，但后续重构担心破坏链路，需要先固定现状和节点合同。
- 性能分析、架构演进、复杂 bug 排查、可观测性补强、adapter 化重构前的分析。

不适用于：

- 单函数小修、纯样式调整、简单 API 字段解释。
- 已经有明确根因和修复点的问题。
- 只需要列命令或写快速操作手册的场景。

## 主提示词

后续分析复杂系统时，可直接复制下面的提示词，并把方括号里的内容替换为当前项目材料。

```text
请按“复杂 pipeline 现状还原 + 节点合同 + 优化分析”的方式分析这个系统。

不要直接给优化建议。先把当前系统梳理清楚，再基于证据给优化方案。

分析对象：
[说明要分析的系统、流程、任务、请求、数据管线或模块]

可用材料：
[源码路径、文档、日志、指标、trace、配置、样本输入、运行结果、错误信息。不要假设必须有某种固定工具；有什么就用什么。]

请按以下顺序输出。

1. 系统边界
- 入口是什么？
- 最终输出是什么？
- 当前系统负责什么？
- 外部依赖是什么？
- 哪些结果是业务输出，哪些只是中间产物、调试产物或运行副作用？
- 哪些内容不属于本次分析范围？

2. 当前 pipeline
- 按真实执行顺序列出所有节点。
- 不要只列业务节点，也要包含输入获取、校验、解析、转换、远程调用、序列化、持久化、上传、回调、清理等隐性节点。
- 如果流程不是线性的，请用 DAG 或分支结构表达。
- 标出同步、异步、批处理、并发、远程调用、缓存、常驻对象或资源复用的位置。

3. 节点合同
对每个节点建立合同，至少包含：
- 节点名称
- 节点职责
- 输入格式和示例
- 输出格式和示例
- 中间状态或临时产物
- 副作用
- 下游消费者
- 失败方式
- 必须保持的顺序、对齐、幂等、一致性或资源约束
- 当前已有观测字段
- 缺失的关键观测字段

4. 数据形态变化
列出数据从入口到出口的所有形态转换，例如：
- 请求参数 -> 内部对象
- 外部引用 -> 本地对象
- 文件 -> 分片/帧/块
- 分片/帧/块 -> 张量/批次/中间结构
- 模型或算法输出 -> 业务结构
- 本地结果 -> 持久化结果或外部结果

不要套用这些例子；请根据当前系统真实数据形态命名。

5. 执行模型
对每个节点判断：
- 是否必须串行？为什么？
- 是否可以并发？并发单位是什么？
- 是否可以 batch？batch 维度是什么？
- 是否可以流式处理？边界是什么？
- 是否可以下沉到外部服务？需要保留什么合同？
- 是否适合抽成 adapter？adapter 的输入输出应是什么？
- 当前实现的主要约束是什么？

6. 观测与证据
基于现有材料建立证据表：
- 总耗时或总成本
- 各节点耗时或成本
- 各节点占比
- 输入规模
- 输出规模
- 调用次数
- 单次平均开销
- 未归属耗时
- 失败所在节点

如果证据不足，请明确写“缺少什么证据”，不要用猜测替代证据。

7. 现状结论
先总结当前真实链路，再指出：
- 最大瓶颈
- 最大不确定性
- 最大正确性风险
- 最大维护风险
- 最可能被误判的点

8. 优化方案
按优先级输出：
- 低风险局部优化
- 中风险结构重构
- 高收益架构调整

每个方案必须包含：
- 改什么
- 为什么改
- 影响哪些节点
- 需要保持不变的合同
- 预期收益
- 验证方法
- 回退方式
- 风险边界

9. 输出格式
最终必须包含：
- pipeline 图，使用文字图或 Mermaid
- 节点输入/输出表
- 数据形态转换表
- 执行模型分析表
- 证据与瓶颈表
- 优化优先级表
- 风险与验证清单
```

## 分析维度

### 1. 边界维度

先切边界，避免把相邻系统的问题混成一个问题。

| 维度 | 要回答的问题 |
| --- | --- |
| 入口 | 数据、请求、事件或任务从哪里进入？ |
| 出口 | 最终对调用方或下游交付什么？ |
| 职责 | 当前系统负责哪些转换、判断和副作用？ |
| 外部依赖 | 哪些能力来自别的服务、库、模型、存储、网络或运行环境？ |
| 非目标 | 哪些现象相关但不归当前系统负责？ |

### 2. 节点维度

每个节点都应被当成一个黑盒合同，而不是一句业务描述。

| 维度 | 说明 |
| --- | --- |
| 输入 | 类型、格式、规模、顺序、示例 |
| 输出 | 类型、格式、规模、顺序、示例 |
| 状态 | 内存状态、缓存、锁、常驻对象、上下文 |
| 副作用 | 文件、数据库、网络、外部对象、进度、日志 |
| 失败 | 抛错、返回错误、重试、终态、清理 |
| 约束 | 顺序、对齐、幂等、一致性、资源上限 |
| 观测 | 耗时、计数、大小、shape、状态、错误码 |

### 3. 数据形态维度

复杂系统的很多问题来自数据形态变化没有被显式描述。分析时应追踪：

```text
外部输入
  -> 内部对象
  -> 中间对象
  -> 批次或分片
  -> 算法/模型输入
  -> 算法/模型输出
  -> 业务输出
  -> 持久化或外部交付
```

每次形态变化都要问：

- 是否改变顺序？
- 是否改变长度？
- 是否改变时间轴、坐标系、单位或精度？
- 是否丢弃字段？
- 是否引入默认值？
- 是否需要和另一条数据流对齐？

### 4. 执行模型维度

不要混用 batch、并发和异步。它们回答的是不同问题。

| 概念 | 判断问题 |
| --- | --- |
| 串行 | 后一步是否依赖前一步完整输出？ |
| 并发 | 多个独立单位是否可同时执行？ |
| batch | 多个同构单位是否可合并成一次处理？ |
| 流式 | 是否可边产生边消费，而不是等待全量完成？ |
| 常驻 | 是否有模型、连接、缓存、进程级对象复用？ |
| 远程调用 | 是否存在网络、序列化、网关、认证、排队开销？ |
| adapter | 是否能把实现替换隐藏在稳定输入输出后面？ |

### 5. 观测维度

观测不是“多打日志”，而是让每个节点能回答：

```text
我处理了什么规模的数据？
我用了多久？
我调用了谁几次？
我输出了多少？
我失败在什么合同上？
```

推荐统一字段：

| 字段 | 含义 |
| --- | --- |
| `stage` | 节点名称 |
| `kind` | 节点类型，如 io、parse、compute、model、storage、orchestration |
| `elapsed_ms` | 当前节点耗时 |
| `input` | 输入摘要，不能放大对象或敏感值 |
| `output` | 输出摘要，不能放完整结果 |
| `counters` | 数量、批次数、调用次数 |
| `backend` | 具体实现或适配器后端 |
| `error_type` | 错误类型 |
| `error_message` | 可定位但不泄露敏感信息的错误消息 |

### 6. 优化维度

优化不按“想改哪里”排序，而按证据、收益、风险和合同稳定性排序。

| 优化类型 | 适用信号 | 风险 |
| --- | --- | --- |
| 观测补强 | 不知道时间花在哪里 | 低 |
| 局部并发 | 多个独立单位串行处理 | 中 |
| batch | 多个同构单位重复远程调用或模型调用 | 中 |
| adapter 化 | 实现变化频繁但输入输出可稳定 | 中 |
| 下沉外部服务 | 本地编排有大量可封装计算或后处理 | 中高 |
| 架构拆分/合并 | 跨进程/网络边界成为主成本 | 高 |

## 输出质量检查

分析结果必须通过以下检查：

- 是否先还原现状，再谈优化？
- 是否明确系统边界，而不是把所有相邻问题都放进来？
- 是否列出隐性节点？
- 是否每个节点都有输入、输出和下游消费者？
- 是否明确数据形态变化？
- 是否区分串行、并发、batch、流式和远程调用？
- 是否把证据和推断分开？
- 是否指出缺失证据？
- 是否说明优化需要保持哪些合同不变？
- 是否给出验证和回退方式？

## 禁止倾向

- 不要在没有现状 pipeline 的情况下直接给优化建议。
- 不要把具体项目工具写进通用提示词主干。
- 不要把示例中的节点名当成所有项目都必须有的节点。
- 不要用“可能是网络慢”“可能是 GPU 慢”替代证据表。
- 不要混用不同样本、不同环境、不同口径的耗时。
- 不要把 batch size、并发数、worker 数、远程服务实例数混成同一个概念。
- 不要建议 silent fallback、吞错、自动降级来掩盖合同错误。
- 不要记录密钥、完整敏感 URL、大对象、完整 tensor、完整业务结果。

## Few-shot 正例：用本规则分析一个 ASD worker

下面是示例，不是主规则。它展示如何把一个具体业务流程映射到通用 pipeline 分析框架。

### 用户输入示例

```text
请分析 ASD worker 当前流程，目标是后续做 stage/adapter 重构和性能优化。可参考源码中的 service、detector、pipeline、adapter 和已有 timing 报告。先梳理现状，不要直接给优化结论。
```

### 合格回答示例

#### 1. 系统边界

```text
入口：worker 收到一条任务消息，消息内包含 video/audio 输入引用和检测参数。
出口：返回主动说话人检测 JSON，必要时附带调试视频 URL。
当前系统职责：下载输入、媒体标准化、场景检测、人脸检测、人脸跟踪、裁剪、说话人评分、结果打包、临时目录清理。
外部依赖：输入文件来源、对象存储、媒体工具、模型或模型服务、任务平台。
非目标：上游音画是否语义同步、下游如何消费 scores、模型训练质量。
```

#### 2. 当前 pipeline

```text
message
  -> validate input
  -> create work_dir
  -> download_media
  -> probe_video_duration
  -> prepare_detector
  -> detect_active_speaker
       -> prepare_frames
       -> decode_audio
       -> validate_duration
       -> scene_detect
       -> face_detect
       -> track_faces
       -> crop_tracks
       -> evaluate_network
       -> pack_tracks
       -> overlay_render(optional)
  -> write_artifacts
  -> complete
  -> cleanup
```

#### 3. 节点合同样例

| 节点 | 输入 | 输出 | 下游 | 约束 |
| --- | --- | --- | --- | --- |
| `download_media` | `video_url`、`audio_url` | 本地 video/audio 文件 | duration probe、detector | 下载失败必须暴露；不应把完整带密钥 URL 写入日志 |
| `prepare_frames` | 本地视频文件 | 25 FPS 帧序列、场景代理、帧数 | scene、face、crop | 排序后的第 i 帧必须对应业务 frame i |
| `face_detect` | 帧序列、检测 adapter、batch size | 每帧人脸检测 list | track | 输出 list 长度必须等于输入帧数 |
| `evaluate_network` | crop 文件、评分 adapter | 每条 track 的逐帧 score | pack | score 顺序必须和 track/crop 顺序一致 |

#### 4. 数据形态变化

```text
任务消息
  -> Pydantic input object
  -> URL 引用
  -> 本地 video/audio 文件
  -> canonical frames + audio16k
  -> face detections / scenes
  -> face tracks
  -> crop clips + crop audio
  -> adapter input tensors
  -> score arrays
  -> business JSON
```

关键检查：

- frame index 是否在所有节点中保持同一时间轴。
- track、crop、score 是否一一对应。
- batch 是否只改变执行方式，不改变业务顺序。
- overlay 是否只是调试产物，不影响业务 scores。

#### 5. 执行模型分析

| 节点 | 串行性 | 并发 | batch | adapter 边界 |
| --- | --- | --- | --- | --- |
| `prepare_frames` | 依赖输入文件，整体偏串行 | 可研究流式或分支输出 | 不适用 | media adapter 可替换 |
| `face_detect` | 依赖帧序列 | 预处理可并发 | frame batch | S3FD adapter |
| `crop_tracks` | 每条 track 独立 | track 级并发 | 不典型 | crop implementation 可替换 |
| `evaluate_network` | 依赖 crop 输出 | track/chunk 可分组 | track/chunk batch | LR-ASD adapter |

#### 6. 伪代码表达

```python
def handle_task(message):
    data = validate_input(message)
    with work_dir_for(message.run_id) as work_dir:
        stage("download_media")
        video, audio = download_inputs(data, work_dir)

        stage("probe_video_duration")
        assert_duration_allowed(video, data.max_duration)

        stage("prepare_detector")
        detector = detector_manager.get(data.model)

        stage("detect_active_speaker")
        result = detector.run(video, audio, work_dir, data.detect)

        stage("write_artifacts")
        output = persist_optional_artifacts(result)

        stage("complete")
        return output


def detector_run(video, audio, work_dir, params):
    frames, scene_proxy = stage("prepare_frames", video)
    audio16k = stage("decode_audio", audio)
    stage("validate_duration", frames)

    scenes = stage("scene_detect", scene_proxy)
    faces = stage("face_detect", frames, s3fd_adapter)
    tracks = stage("track_faces", scenes, faces)
    crops = stage("crop_tracks", frames, audio16k, tracks)
    scores = stage("evaluate_network", crops, lrasd_adapter)
    return stage("pack_tracks", tracks, scores, scenes)
```

#### 7. 现状结论示例

```text
当前系统不是一个单一模型调用，而是一条多阶段媒体/模型 pipeline。
后续优化前，必须先保证每个节点都有统一 stage 日志，每个 adapter call 有输入 shape、输出 shape、batch size、backend 和耗时。
优化应优先落在节点边界清晰的位置，例如 face_detect adapter、evaluate_network adapter、crop_tracks 并发，而不是直接重写整条任务链。
```

#### 8. 优化方案示例

| 优先级 | 方案 | 保持不变的合同 | 验证方式 |
| --- | --- | --- | --- |
| 低 | 补齐 stage/adapter timing | 业务 JSON 不变、异常映射不变 | 同样本对比输出和日志 |
| 中 | 把模型调用封装成稳定 adapter | adapter 输入输出 shape 不变 | mock adapter 与真实 adapter 双测 |
| 中 | 对独立 track/chunk 做 batch 或并发 | track/crop/score 顺序不变 | 结果长度、顺序、数值对比 |
| 高 | 将稳定计算节点下沉到外部服务 | 外部服务合同与 adapter 合同一致 | A/B、回退到旧 adapter |

这个 few-shot 的重点不是 ASD 本身，而是展示：先还原现状，再建立节点合同，再判断执行模型，最后才进入优化。
