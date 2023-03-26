import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

abstract class SimpleTask<DATA> {
  FutureOr<DATA> execute();

  static SimpleTask<DATA> build<DATA>(FutureOr<DATA> Function() function) {
    return _SimpleTaskImp<DATA>(function);
  }
}

class _SimpleTaskImp<DATA> extends SimpleTask<DATA> {
  FutureOr<DATA> Function() function;

  _SimpleTaskImp(this.function);

  @override
  FutureOr<DATA> execute() {
    return function();
  }
}

abstract class SimpleCallback<DATA> {
  void onStart() {}

  void onPostSuccess(DATA data) {}

  void onPostFailed(Object error) {}

  static SimpleCallback<DATA> build<DATA>({
    VoidCallback? start,
    final void Function(Object error)? failed,
    void Function(DATA data)? success,
  }) {
    return _SimpleCallbackImp<DATA>(
      start: start,
      failed: failed,
      success: success,
    );
  }
}

class SimpleCallbacksProxy<DATA> implements SimpleCallback<DATA> {
  final List<SimpleCallback> _callbacks = [];

  void addCallback(SimpleCallback<DATA> callback) {
    _callbacks.add(callback);
  }

  void removeCallback(SimpleCallback<DATA> callback) {
    _callbacks.remove(callback);
  }

  @override
  void onStart() {
    for (var value in _callbacks) {
      value.onStart();
    }
  }

  @override
  void onPostFailed(Object error) {
    for (var value in _callbacks) {
      value.onPostFailed(error);
    }
  }

  @override
  void onPostSuccess(DATA data) {
    for (var value in _callbacks) {
      value.onPostSuccess(data);
    }
  }
}

class _SimpleCallbackImp<DATA> implements SimpleCallback<DATA> {
  final VoidCallback? start;
  final void Function(Object error)? failed;
  final void Function(DATA data)? success;

  _SimpleCallbackImp({
    this.start,
    this.failed,
    this.success,
  });

  @override
  void onStart() {
    if (start != null) {
      start!();
    }
  }

  @override
  void onPostFailed(Object error) {
    if (failed != null) {
      failed!(error);
    }
  }

  @override
  void onPostSuccess(DATA data) {
    if (success != null) {
      success!(data);
    }
  }
}

class UnsubscribeException implements Exception {
  const UnsubscribeException();
}

class TaskExecutor<DATA> {
  SimpleTask<DATA>? _task;
  SimpleCallback<DATA>? _callback;
  bool _finished = false;

  void unsubscribe() {
    if (!_finished) {
      _callback?.onPostFailed(const UnsubscribeException());
    }
    _callback = null;
  }

  TaskExecutor(SimpleTask<DATA> task, SimpleCallback<DATA>? callback)
      : _task = task,
        _callback = callback;

  Future<DATA> execute() async {
    try {
      _callback?.onStart();
      DATA data = await _task!.execute();
      _callback?.onPostSuccess(data);
      ////执行完释放对象引用
      _callback = null;
      _task = null;
      _finished = true;
      return data;
    } catch (e, strace) {
      if (kDebugMode) {
        print('e:$e strace:$strace');
      }
      _callback?.onPostFailed(e);
      //执行完释放对象引用
      _callback = null;
      _task = null;
      _finished = true;
      return Future.error(e);
    }
  }
}

class TaskHelper {
  final List<TaskExecutor> _taskExecutorList = [];

  Future<DATA> execute<DATA>(SimpleTask<DATA> task,
      [SimpleCallback<DATA>? callback]) async {
    TaskExecutor<DATA> taskExecutor = TaskExecutor<DATA>(task, callback);
    _taskExecutorList.add(taskExecutor);
    Future<DATA> result = taskExecutor.execute();
    _taskExecutorList.remove(taskExecutor);
    return result;
  }

  void unsubscribeAll() {
    List<TaskExecutor> list = List.from(_taskExecutorList);
    for (var value in list) {
      value.unsubscribe();
    }
    list.clear();
  }

  void dispose() {
    unsubscribeAll();
  }
}

mixin TaskStateMixin<T extends StatefulWidget> on State<T> {
  late TaskHelper _taskHelper;

  @override
  void initState() {
    _taskHelper = TaskHelper();
    super.initState();
  }

  TaskHelper get taskHelper => _taskHelper;

  @override
  void dispose() {
    _taskHelper.dispose();
    super.dispose();
  }
}

mixin TaskMixin on ChangeNotifier {
  TaskHelper? _taskHelper;
  bool _isDisposed = false;

  TaskHelper get taskHelper => _taskHelper ??= TaskHelper();

  @override
  void dispose() {
    _isDisposed = true;
    _taskHelper?.dispose();
    super.dispose();
  }

  bool isDisposed() {
    return _isDisposed;
  }
}
