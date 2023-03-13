import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'task.dart';

class TaskProviderKey<DATA> {
  ChangeNotifierProvider<TaskNotifier<DATA>> provider(
      SimpleTask<DATA> Function(BuildContext context) create,
      {TransitionBuilder? builder,
      Widget? child}) {
    return ChangeNotifierProvider<TaskNotifier<DATA>>(
      builder: builder,
      child: child,
      create: (BuildContext context) {
        var notifier = TaskNotifier<DATA>(create(context));
        notifier.executeTask();
        return notifier;
      },
    );
  }

  Widget when({
    required Widget Function() loading,
    required Widget Function(Object error) error,
    required Widget Function(DATA data) data,
  }) {
    return Consumer<TaskNotifier<DATA>>(
      builder: (context, notifier, child) {
        if (notifier.isLoading()) {
          return loading();
        }
        if (notifier.isSuccessful()) {
          return data(notifier.data as DATA);
        }
        return error(notifier.error!);
      },
    );
  }

  Widget consumer(
      Widget Function(
    BuildContext context,
    TaskNotifier<DATA> notifier,
    Widget? child,
  )
          builder) {
    return Consumer<TaskNotifier<DATA>>(
      builder: builder,
    );
  }

  TaskNotifier<DATA> read(BuildContext context) {
    return Provider.of<TaskNotifier<DATA>>(context, listen: false);
  }

  TaskNotifier<DATA> watch(BuildContext context) {
    return Provider.of<TaskNotifier<DATA>>(context, listen: true);
  }
}

class TaskNotifier<DATA> extends ChangeNotifier
    with TaskMixin
    implements SimpleCallback<DATA> {
  final SimpleTask<DATA> task;
  TaskResult<DATA>? _result;
  bool _isLoading = false;

  TaskNotifier(this.task);

  bool isLoading() {
    return _isLoading;
  }

  void executeTask({bool force = false}) {
    if (force) {
      taskHelper.unsubscribeAll();
      taskHelper.execute(task, this);
    } else {
      if (!isLoading()) {
        taskHelper.execute(task, this);
      }
    }
  }

  @override
  void onStart() {
    _isLoading = true;
    notifyListeners();
  }

  @override
  void onPostFailed(Object error) {
    _result = TaskResult.error(error);
    _isLoading = false;
    notifyListeners();
  }

  @override
  void onPostSuccess(DATA data) {
    _result = TaskResult.success(data);
    _isLoading = false;
    notifyListeners();
  }

  bool isSuccessful() {
    return _result != null && _result!.isSuccessful();
  }

  DATA? get data => _result == null ? null : _result!.data;

  Object? get error => _result == null ? null : _result!.error;
}
