import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'task.dart';

class TaskNotifier<DATA> extends ChangeNotifier
    with TaskMixin
    implements SimpleCallback<DATA> {
  SimpleTask<DATA>? _task;
  Object? _error;
  DATA? _data;
  bool _isSuccessful = false;
  bool _isLoading = false;
  bool _hasExecuted = false;

  TaskNotifier([SimpleTask<DATA>? task]) : _task = task;

  void setTask(SimpleTask<DATA> task) {
    _task = task;
  }

  void execute({
    SimpleTask<DATA>? onceTask,
    bool force = false,
  }) {
    var executeTask = onceTask ?? _task;
    if (executeTask == null) {
      throw Exception('TaskNotifier unset a task');
    }
    _executeImp(executeTask, force: force);
  }

  void _executeImp(SimpleTask<DATA> task, {bool force = false}) {
    _hasExecuted = true;
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
    _error = error;
    _isLoading = false;
    _isSuccessful = false;
    notifyListeners();
  }

  @override
  void onPostSuccess(DATA data) {
    _data = data;
    _isLoading = false;
    _isSuccessful = true;
    notifyListeners();
  }

  bool isLoading() {
    return _isLoading;
  }

  bool isSuccessful() {
    return _isSuccessful;
  }

  SimpleTask<DATA>? get task => _task;

  DATA? get data => _data;

  Object? get error => _error;

  Widget when({
    required Widget Function() loading,
    required Widget Function(Object error) error,
    required Widget Function(DATA data) data,
  }) {
    if (!_hasExecuted) {
      execute();
    }
    return TaskListenableBuilder<DATA>(
      loading: loading,
      data: data,
      error: error,
      listenable: this,
    );
  }
}

class TaskListenableBuilder<DATA> extends StatelessWidget {
  final Widget Function() loading;

  final Widget Function(Object error) error;

  final Widget Function(DATA data) data;

  final TaskNotifier<DATA> listenable;

  const TaskListenableBuilder({
    super.key,
    required this.listenable,
    required this.loading,
    required this.error,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, child) {
        if (listenable.isLoading()) {
          return loading();
        }
        if (listenable.isSuccessful()) {
          return data(listenable.data as DATA);
        }
        return error(listenable.error!);
      },
    );
  }
}

class ListenableBuilder extends StatefulWidget {
  final Listenable listenable;

  final Widget? child;

  final TransitionBuilder builder;

  const ListenableBuilder({
    super.key,
    required this.listenable,
    required this.builder,
    this.child,
  });

  @override
  State<StatefulWidget> createState() => _ListenableBuilderState();
}

class _ListenableBuilderState extends State<ListenableBuilder> {
  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(ListenableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenable != widget.listenable) {
      oldWidget.listenable.removeListener(_valueChanged);
      widget.listenable.addListener(_valueChanged);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.child);
  }
}
