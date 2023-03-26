import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'datasource_notifier.dart';


class DatasourceProviderKey<DATA> {
  ChangeNotifierProvider<DatasourceNotifier<DATA>> provider(
      DataManager<DATA> Function(BuildContext context) create,
      {TransitionBuilder? builder,
      Widget? child}) {
    return ChangeNotifierProvider<DatasourceNotifier<DATA>>(
      builder: builder,
      child: child,
      create: (BuildContext context) {
        var notifier = DatasourceNotifier<DATA>(
          create(context),
        );
        notifier.refresh();
        return notifier;
      },
    );
  }

  Widget when({
    required Widget Function()? loading,
    required Widget Function(Object error) error,
    required Widget Function(DATA data) data,
  }) {
    return Consumer<DatasourceNotifier<DATA>>(
      builder: (context, notifier, child) {
        if (notifier.isRefreshing()) {
          return loading == null ? const SizedBox() : loading();
        }
        if (notifier.data == null && notifier.error != null) {
          return error(notifier.error!);
        }
        return data(notifier.data);
      },
    );
  }

  Widget consumer(
      Widget Function(
    BuildContext context,
    DatasourceNotifier<DATA> notifier,
    Widget? child,
  )
          builder) {
    return Consumer<DatasourceNotifier<DATA>>(
      builder: builder,
    );
  }

  DatasourceNotifier<DATA> read(BuildContext context) {
    return Provider.of<DatasourceNotifier<DATA>>(context, listen: false);
  }

  DatasourceNotifier<DATA> watch(BuildContext context) {
    return Provider.of<DatasourceNotifier<DATA>>(context, listen: true);
  }

  static DatasourceNotifier<DATA> staticRead<DATA>(BuildContext context) {
    return Provider.of<DatasourceNotifier<DATA>>(context, listen: false);
  }

  static DatasourceNotifier<DATA> staticWatch<DATA>(BuildContext context) {
    return Provider.of<DatasourceNotifier<DATA>>(context, listen: true);
  }
}
