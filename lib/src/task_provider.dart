import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'task.dart';
import 'task_notifier.dart';

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
        notifier.execute();
        return notifier;
      },
    );
  }

  Widget when({
    required Widget Function() loading,
    required Widget Function(Object error) error,
    required Widget Function(DATA data) data,
  }) {
    return Builder(builder: (context) {
      return TaskListenableBuilder(
        listenable: read(context),
        loading: loading,
        error: error,
        data: data,
      );
    });
    //
    // return Consumer<TaskNotifier<DATA>>(
    //   builder: (context, notifier, child) {
    //     if (notifier.isLoading()) {
    //       return loading();
    //     }
    //     if (notifier.isSuccessful()) {
    //       return data(notifier.data as DATA);
    //     }
    //     return error(notifier.error!);
    //   },
    // );
  }

  Widget consumer(
    Widget Function(
      BuildContext context,
      TaskNotifier<DATA> notifier,
      Widget? child,
    )
        builder,
    Widget? child,
  ) {
    return Consumer<TaskNotifier<DATA>>(
      builder: builder,
      child: child,
    );
  }

  TaskNotifier<DATA> read(BuildContext context) {
    return Provider.of<TaskNotifier<DATA>>(context, listen: false);
  }

  TaskNotifier<DATA> watch(BuildContext context) {
    return Provider.of<TaskNotifier<DATA>>(context, listen: true);
  }
}
