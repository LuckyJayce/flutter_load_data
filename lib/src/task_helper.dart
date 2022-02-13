/*
    Author: Jayce
    createTime:2020-10
*/

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'task.dart';

enum ResultCode { success, fail, cancel }

abstract class Callback<DATA> {
  void onStart();

  void onProgress(int current, int total, [Object? progressData]);

  void onPostSuccess(DATA data);

  void onPostFail(Object error);

  void onPostCancel();

  static Callback<DATA> build<DATA>(
      {VoidCallback? onStart,
      ProgressCallback? onProgress,
      DataCallback<DATA>? onPostSuccess,
      DataCallback? onPostFail,
      VoidCallback? onPostCancel,
      void Function(ResultCode code, DATA? data, Object? error)? onPost}) {
    return _CallbackFunction<DATA>(
        onStart, onProgress, onPostSuccess, onPostFail, onPostCancel, onPost);
  }
}

class TaskHelper {
  List<CancelHandle> cancelHandleList = [];

  Future<TaskResult<DATA>> executeByFuture<DATA>(Future<DATA> future,
      [Callback<DATA>? callback, CancelHandle? cancelHandle]) {
    return execute(Task.buildByFuture(future), callback, cancelHandle);
  }

  Future<TaskResult<DATA>> executeByFunction<DATA>(
      TaskFunction<DATA> taskFunction,
      [Callback<DATA>? callback,
      CancelHandle? cancelHandle]) {
    return execute(Task.buildByFunction(taskFunction), callback, cancelHandle);
  }

  Future<TaskResult<DATA>> execute<DATA>(Task<DATA> task,
      [Callback<DATA>? callback, CancelHandle? cancelHandle]) {
    Completer<TaskResult<DATA>> completer = Completer();
    if (cancelHandle == null) {
      cancelHandle = new CancelHandle();
    }
    cancelHandleList.add(cancelHandle);
    Callback<DATA> removeHandleCallback = Callback.build<DATA>(
      onPost: (code, data, error) {
        cancelHandleList.remove(cancelHandle);
        completer.complete(TaskResult(code, data, error));
      },
    );
    TaskExecutor.execute(task,
        cancelHandle: cancelHandle,
        callback: callback,
        callback2: removeHandleCallback);
    return completer.future;
  }

  void cancelAll() {
    if (cancelHandleList.isNotEmpty) {
      List<CancelHandle> listCopy = List.from(cancelHandleList);
      for (var value in listCopy) {
        value.cancel();
      }
      cancelHandleList.clear();
    }
  }

  void dispose() {
    cancelAll();
  }
}

class TaskExecutor {
  static void executeByFuture<DATA>(Future<DATA> future,
      {Callback<DATA>? callback,
      Callback<DATA>? callback2,
      Callback<DATA>? callback3}) {
    execute(Task.buildByFuture(future),
        callback: callback, callback2: callback2, callback3: callback3);
  }

  static void executeByFunction<DATA>(TaskFunction<DATA> taskFunction,
      {CancelHandle? cancelHandle,
      Callback<DATA>? callback,
      Callback<DATA>? callback2,
      Callback<DATA>? callback3}) {
    execute(Task.buildByFunction(taskFunction),
        cancelHandle: cancelHandle,
        callback: callback,
        callback2: callback2,
        callback3: callback3);
  }

  static void execute<DATA>(Task<DATA> task,
      {CancelHandle? cancelHandle,
      Callback<DATA>? callback,
      Callback<DATA>? callback2,
      Callback<DATA>? callback3}) {
    CancelHandle cancelHandleNew = cancelHandle ?? new CancelHandle();
    _OnceCallback proxy = _OnceCallback(callback, callback2, callback3);
    proxy.onStart();
    cancelHandleNew.whenCancel.then((value) {
      proxy.onPostCancel();
    });
    try {
      Future<DATA> future = task.execute(cancelHandleNew, proxy.onProgress);
      future.then((data) {
        if (!cancelHandleNew.isCancelled) {
          proxy.onPostSuccess(data);
        } else {
          proxy.onPostCancel();
        }
      }).catchError((error, stack) {
        debugPrint('$error\n$stack');
        if (!cancelHandleNew.isCancelled) {
          proxy.onPostFail(error);
        } else {
          proxy.onPostCancel();
        }
      });
    } catch (error, stack) {
      debugPrint('$error\n$stack');
      proxy.onPostFail(error);
    }
  }
}

class _OnceCallback<DATA> extends Callback<DATA> {
  Callback<DATA>? callback;
  Callback<DATA>? callback2;
  Callback<DATA>? callback3;
  bool isPosted = false;

  _OnceCallback(this.callback, this.callback2, this.callback3);

  @override
  void onStart() {
    if (!isPosted) {
      callback?.onStart();
      callback2?.onStart();
      callback3?.onStart();
    }
  }

  @override
  void onProgress(int count, int total, [Object? progressData]) {
    if (!isPosted) {
      callback?.onProgress(count, total, progressData);
      callback2?.onProgress(count, total, progressData);
      callback3?.onProgress(count, total, progressData);
    }
  }

  @override
  void onPostCancel() {
    if (!isPosted) {
      callback?.onPostCancel();
      callback2?.onPostCancel();
      callback3?.onPostCancel();
    }
    _release();
  }

  @override
  void onPostFail(Object error) {
    if (!isPosted) {
      callback?.onPostFail(error);
      callback2?.onPostFail(error);
      callback3?.onPostFail(error);
    }
    _release();
  }

  @override
  void onPostSuccess(DATA data) {
    if (!isPosted) {
      callback?.onPostSuccess(data);
      callback2?.onPostSuccess(data);
      callback3?.onPostSuccess(data);
    }
    _release();
  }

  void _release() {
    callback = null;
    callback2 = null;
    callback3 = null;
    isPosted = true;
  }
}

class CallbackList<DATA> implements Callback<DATA> {
  List<Callback<DATA>> callbacks = [];

  void addCallback(Callback<DATA> callback) {
    callbacks.add(callback);
  }

  void removeCallback(Callback<DATA> callback) {
    callbacks.remove(callback);
  }

  @mustCallSuper
  @override
  void onStart() {
    for (var value in callbacks) {
      value.onStart();
    }
  }

  @mustCallSuper
  @override
  void onProgress(int current, int total, [Object? progressData]) {
    for (var value in callbacks) {
      value.onProgress(current, total, progressData);
    }
  }

  @mustCallSuper
  @override
  void onPostCancel() {
    for (var value in callbacks) {
      value.onPostCancel();
    }
  }

  @mustCallSuper
  @override
  void onPostFail(Object error) {
    for (var value in callbacks) {
      value.onPostFail(error);
    }
  }

  @mustCallSuper
  @override
  void onPostSuccess(DATA data) {
    for (var value in callbacks) {
      value.onPostSuccess(data);
    }
  }
}

class _CallbackFunction<DATA> extends Callback<DATA> {
  VoidCallback? _onStart;
  ProgressCallback? _onProgress;
  VoidCallback? _postCancel;
  DataCallback<DATA>? _postSuccess;
  DataCallback? _postFail;
  void Function(ResultCode code, DATA? data, Object? error)? _onPost;

  _CallbackFunction(this._onStart, this._onProgress, this._postSuccess,
      this._postFail, this._postCancel, this._onPost);

  @override
  void onStart() {
    if (_onStart != null) {
      _onStart!();
    }
  }

  @override
  void onProgress(int count, int total, [Object? progressData]) {
    if (_onProgress != null) {
      _onProgress!(count, total, progressData);
    }
  }

  @override
  void onPostCancel() {
    if (_postCancel != null) {
      _postCancel!();
    }
    if (_onPost != null) {
      _onPost!(ResultCode.cancel, null, null);
    }
  }

  @override
  void onPostFail(Object error) {
    if (_postFail != null) {
      _postFail!(error);
    }
    if (_onPost != null) {
      _onPost!(ResultCode.fail, null, error);
    }
  }

  @override
  void onPostSuccess(DATA data) {
    if (_postFail != null) {
      _postSuccess!(data);
    }
    if (_onPost != null) {
      _onPost!(ResultCode.success, data, null);
    }
  }
}

class SingleRunningTaskHelper {
  List<_TaskEntity> taskEntities = [];
  _TaskEntity? currentEntity;

  int get taskSize => taskEntities.length;

  void execute<DATA>(Task<DATA> task,
      {Callback<DATA>? callback, CancelHandle? cancelHandle}) {
    if (cancelHandle == null) {
      cancelHandle = CancelHandle();
    }
    taskEntities.add(_TaskEntity(task, callback, cancelHandle));
    _executeImp();
  }

  void _executeImp() {
    _TaskEntity? local = currentEntity;
    if (local == null && taskEntities.isNotEmpty) {
      Callback changeStatusCallback =
          Callback.build(onPost: (code, data, error) {
        currentEntity = null;
        //执行完继续执行下一个
        _executeImp();
      });
      //先进先出
      local = currentEntity = taskEntities.removeAt(0);
      TaskExecutor.execute(local.task,
          cancelHandle: local.cancelHandle,
          callback: local.callback,
          callback2: changeStatusCallback);
    }
  }

  void cancelAll() {
    taskEntities.clear();
    _TaskEntity? local = currentEntity;
    if (local != null) {
      local.cancelHandle.cancel();
      currentEntity = null;
    }
  }

  void dispose() {
    cancelAll();
  }
}

class _TaskEntity<DATA> {
  Task<DATA> task;
  Callback<DATA>? callback;
  CancelHandle cancelHandle;

  _TaskEntity(this.task, this.callback, this.cancelHandle);
}

class TaskResult<DATA> {
  final ResultCode code;
  final Object? error;
  final DATA? data;

  const TaskResult(this.code, this.data, this.error);

  bool isSuccessful() {
    return code == ResultCode.success;
  }

  bool isFailed() {
    return code == ResultCode.fail;
  }

  bool isCanceled() {
    return code == ResultCode.cancel;
  }

  @override
  String toString() {
    return 'TaskResult{code: $code, error: $error, data: $data}';
  }
}

enum TaskStatus {
  un_load,
  start,
  progress,
  end,
}

typedef DataCallback<DATA> = void Function(DATA data);
