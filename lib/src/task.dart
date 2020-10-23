/*
    Author: Jayce
    createTime:2020-10
*/

import 'dart:async';

abstract class Task<DATA> {
  ///加载数据的方法
  ///cancelHandle 借鉴于dio类库的设计, 外部通过cancelHandle.cancel()取消，里面则可以通过cancelHandle.isCanceled()判断，或者通过cancelHandle.interruptedWhenCanceled()当被取消是抛出取消异常终止方法执行
  ///progressCallback，可能为空使用前判空，用于通知外部进度
  ///Future<DATA> 返回数据的Future
  Future<DATA> execute(CancelHandle cancelHandle,
      [ProgressCallback progressCallback]);

  static Task<DATA> buildByFunction<DATA>(TaskFunction<DATA> function) {
    return _TaskF<DATA>(function);
  }

  static Task<DATA> buildByFuture<DATA>(Future<DATA> future) {
    return _TaskFuture<DATA>(future);
  }
}

class _TaskFuture<DATA> implements Task<DATA> {
  Future<DATA> future;

  _TaskFuture(this.future);

  @override
  Future<DATA> execute(CancelHandle cancelHandle,
      [ProgressCallback progressCallback]) {
    return future;
  }
}

class _TaskF<DATA> implements Task<DATA> {
  TaskFunction<DATA> task;

  _TaskF(this.task);

  @override
  Future<DATA> execute(CancelHandle cancelHandle,
      [ProgressCallback progressCallback]) {
    return task(cancelHandle, progressCallback);
  }
}

typedef ProgressCallback = void Function(int current, int total,
    [Object progressData]);

///用于取消的句柄，借鉴于dio CancelToken
class CancelHandle {
  CancelHandle() {
    _completer = Completer();
  }

  Completer _completer;

  CancelException _cancelException;

  ///当被取消是抛出取消异常终止方法执行，用该方法注释资源释放等问题
  void interruptedWhenCanceled() {
    if (isCancelled) {
      throw _cancelException;
    }
  }

  ///判断是否被取消，可以用于循环判断
  static bool isCancel(Object e) {
    return e is CancelException;
  }

  /// whether cancelled
  bool get isCancelled => _cancelException != null;

  /// When cancelled, this future will be resolved. 可以通过
  Future<void> get whenCancel => _completer.future;

  /// Cancel the request
  void cancel() {
    this._cancelException = CancelException();
    _completer.complete(_cancelException);
  }
}

class CancelException implements Exception {}

typedef TaskFunction<DATA> = Future<DATA> Function(CancelHandle cancelHandle,
    [ProgressCallback progressCallback]);
