# Flutter 错误处理规范

> 错误处理规范解决的核心问题只有一个：当某件事出错时，用户应该看到什么，代码应该做什么。这两个问题如果没有统一的答案，整个 app 的错误行为就会是随机的。

---

## 错误的两种性质

所有错误在处理之前先判断性质：

```
可恢复错误    用户或系统可以采取行动来恢复
              例：网络断开（重试）、查询无结果（清除筛选）、写入失败（重试）

不可恢复错误  无法在当前会话内解决
              例：数据库损坏、应用状态完全不一致
```

可恢复错误必须给用户提供恢复路径。不可恢复错误记录日志，引导用户重启或联系支持。

---

## 错误分类

所有业务层面的错误用 `AppError` 的子类表示，定义在 `lib/core/errors/app_error.dart`：

```dart
sealed class AppError implements Exception {
  const AppError();
}

// 数据不存在
class NotFoundError extends AppError {
  const NotFoundError({required this.resourceType, this.id});
  final String resourceType;
  final String? id;
}

// 存储操作失败（数据库读写错误）
class StorageError extends AppError {
  const StorageError({required this.message, this.cause});
  final String message;
  final Object? cause;
}

// 网络请求失败（如果有网络层）
class NetworkError extends AppError {
  const NetworkError({this.statusCode, this.message});
  final int? statusCode;
  final String? message;
}

// 业务规则冲突（数据不满足约束，但不是技术错误）
class ValidationError extends AppError {
  const ValidationError({required this.field, required this.reason});
  final String field;
  final String reason;
}

// 操作被用户权限拒绝
class PermissionError extends AppError {
  const PermissionError({required this.action});
  final String action;
}
```

### 什么时候新增错误类型

出现以下情况时新增一个 `AppError` 子类：

```
需要在 UI 层区别对待这种错误   -> 新增子类
和已有错误类型的处理方式不同   -> 新增子类
只是消息文字不同              -> 不新增，用已有类型传不同 message
```

不要用 `AppError(message: '...')` 这种泛型写法传递所有错误。具体的子类让 `switch` 穷举检查变得可能。

---

## 各层的错误职责

### DataSource 层

DataSource 层抛出平台原始异常，不做转换：

```dart
// Drift DAO 自然抛出 SqliteException，不需要捕获
Future<List<DiaryEntity>> getAll() => select(diaryTable).get();
```

DataSource 不应该 try-catch 再重新 throw，让异常自然向上传播到 Repository。

### Repository 层

Repository 层是唯一做异常转换的地方。捕获平台异常，转换为 `AppError`：

```dart
@override
Future<List<Diary>> fetchAll() async {
  try {
    final entities = await _dao.getAll();
    return entities.map(_toModel).toList();
  } on SqliteException catch (e) {
    throw StorageError(message: '读取日记失败', cause: e);
  }
}

@override
Future<Diary?> fetchById(String id) async {
  try {
    final entity = await _dao.getById(id);
    if (entity == null) return null;    // 不存在返回 null，不 throw NotFoundError
    return _toModel(entity);
  } on SqliteException catch (e) {
    throw StorageError(message: '读取日记 $id 失败', cause: e);
  }
}
```

Repository 的转换原则：

```
查询结果为空      -> return null 或 return []，不 throw
写入 / 更新失败   -> throw StorageError
数据完整性违反    -> throw ValidationError
```

Repository 之后，`SqliteException`、`DioException` 等平台类型不应该出现在任何地方。

### Notifier 层

Notifier 层用 `AsyncValue.guard` 捕获 `AppError`，暴露给 UI：

```dart
@riverpod
class DiaryListNotifier extends _$DiaryListNotifier {
  @override
  Future<List<Diary>> build() => _fetch();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<Diary>> _fetch() {
    return ref.read(diaryRepositoryProvider).fetchAll();
  }
}
```

Notifier 不需要手动 try-catch，`AsyncValue.guard` 会捕获所有异常并放入 `AsyncError`。

---

## UI 层的错误展示

### 规则

```
AsyncError        -> 展示 ErrorView，提供重试按钮
ValidationError   -> 展示内联表单错误，不用全屏错误页
NotFoundError     -> 展示 EmptyState，不用错误样式
```

不要在 UI 层 switch AppError 子类然后拼装文案。文案策略统一放在 `ErrorView` 组件和 `AppErrorMessage` 工具类里。

### ErrorView 组件

`shared/widgets/error_view.dart` 是唯一处理 `AppError` 展示的地方：

```dart
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
  });

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final message = AppErrorMessage.from(error);
    return Column(
      children: [
        Text(message.title),
        Text(message.description),
        if (message.isRetryable && onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('重试')),
      ],
    );
  }
}
```

`AppErrorMessage` 负责把 `AppError` 转成用户可读的文案：

```dart
class AppErrorMessage {
  const AppErrorMessage({
    required this.title,
    required this.description,
    required this.isRetryable,
  });

  factory AppErrorMessage.from(Object error) {
    return switch (error) {
      StorageError()    => const AppErrorMessage(
          title: '读取失败',
          description: '数据暂时无法访问，请稍后重试',
          isRetryable: true,
        ),
      NetworkError()    => const AppErrorMessage(
          title: '网络错误',
          description: '请检查网络连接后重试',
          isRetryable: true,
        ),
      ValidationError() => const AppErrorMessage(
          title: '数据格式有误',
          description: '请检查输入内容',
          isRetryable: false,
        ),
      _                 => const AppErrorMessage(
          title: '出现了问题',
          description: '请重试，或重启应用',
          isRetryable: true,
        ),
    };
  }
  
  final String title;
  final String description;
  final bool isRetryable;
}
```

### 在页面里使用

```dart
return switch (state) {
  AsyncData(:final value) => HomeTimeline(diaries: value),
  AsyncLoading()          => const TimelineSkeleton(),
  AsyncError(:final error) => ErrorView(
      error: error,
      onRetry: () => ref.invalidate(diaryListNotifierProvider),
    ),
};
```

---

## 全局未捕获异常

`main.dart` 里注册全局异常处理，防止未捕获异常导致白屏：

```dart
void main() {
  FlutterError.onError = (details) {
    // 记录日志
    debugPrint('Flutter error: ${details.exception}');
    debugPrint(details.stack.toString());
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrint(stack.toString());
    return true;
  };

  runApp(const ProviderScope(child: MyApp()));
}
```

全局处理的作用是兜底，不是替代各层的错误处理。出现了全局错误说明某一层的错误处理有遗漏，要回去补。

---

## 错误日志

目前阶段用 `debugPrint`。当需要上报时，统一通过 `core/errors/error_reporter.dart` 中的接口调用，不要把上报逻辑散在各处。

```dart
abstract class ErrorReporter {
  void report(AppError error, {StackTrace? stack});
}
```

切换上报服务（Sentry / Firebase Crashlytics）只需要换 `ErrorReporter` 的实现，不需要改其他代码。

---

## 禁止的错误处理模式

```
在 Widget 里 try-catch Repository 调用    -> Widget 不直接调用 Repository
用 print 记录异常然后 return null          -> 异常被吞掉，调用方不知道发生了错误
catch (e) { } 空 catch                   -> 绝对禁止
UI 层 switch SqliteException / DioException -> 平台异常不应该出现在 UI 层
对同一个错误在多个地方展示不同文案          -> 文案统一在 AppErrorMessage 里
```

---

## 维护规则

```
新增错误场景      -> 先判断是否需要新 AppError 子类，再更新 AppErrorMessage
错误文案调整      -> 只改 AppErrorMessage，不改各处的 ErrorView 调用
Repository 新方法  -> 检查所有可能的失败路径，确保都 throw 了合适的 AppError
```
