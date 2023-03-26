import 'package:flutter/material.dart';

import '../load_data.dart';
import 'datasource_notifier.dart';

extension RefreshExtension<DATA> on DatasourceProviderKey<DATA> {
  Widget buildRefresh({
    required RefreshDelegate refreshDelegate,
    required Widget Function() loading,
    required Widget Function(Object error) error,
    required Widget Function(DATA data) data,
  }) {
    return refreshDelegate.build<DATA>(
      loading: loading,
      error: error,
      data: data,
    );
  }
}

abstract class RefreshDelegate {
  Widget build<DATA>({
    required Widget Function() loading,
    required Widget Function(Object error) error,
    required Widget Function(DATA data) data,
  });
}

abstract class RefreshControllerAdapter {
  const RefreshControllerAdapter();

  void showRefreshing();

  void showLoadMoreIng();

  void finishRefresh(
      BuildContext context, bool success, Object? error, bool noMore);

  void finishLoadMore(
      BuildContext context, bool success, Object? error, bool noMore);
}

mixin ContentBuilder<DATA, T extends StatefulWidget> on State<T> {
  late Widget Function() loading;
  late Widget Function(Object error) error;
  late Widget Function(DATA data) data;

  late SimpleCallback<DATA> loadMoreCallback;
  late SimpleCallback<DATA> refreshCallback;

  late DatasourceNotifier<DATA> notifier;

  RefreshControllerAdapter get refreshAdapter;

  @override
  void initState() {
    notifier = DatasourceProviderKey.staticRead<DATA>(context);
    notifier
        .addRefreshCallback(refreshCallback = SimpleCallback.build(start: () {
      switch (notifier.loadingType) {
        case LoadingType.refreshWidget:
          refreshAdapter.showRefreshing();
          break;
        case LoadingType.statusWidget:
          break;
        case LoadingType.auto:
          if (notifier.isNotEmpty) {
            refreshAdapter.showRefreshing();
          }
          break;
        case LoadingType.none:
          break;
      }
    }, failed: (error) {
      refreshAdapter.finishRefresh(
          context, false, error, !notifier.datasource.hasMore());
    }, success: (data) {
      refreshAdapter.finishRefresh(
          context, true, null, !notifier.datasource.hasMore());
    }));
    notifier
        .addLoadMoreCallback(loadMoreCallback = SimpleCallback.build(start: () {
      switch (notifier.loadingType) {
        case LoadingType.refreshWidget:
          refreshAdapter.showLoadMoreIng();
          break;
        case LoadingType.statusWidget:
          break;
        case LoadingType.auto:
          if (notifier.isNotEmpty) {
            refreshAdapter.showLoadMoreIng();
          }
          break;
        case LoadingType.none:
          break;
      }
    }, failed: (error) {
      refreshAdapter.finishLoadMore(
          context, false, error, !notifier.datasource.hasMore());
    }, success: (data) {
      refreshAdapter.finishLoadMore(
          context, true, null, !notifier.datasource.hasMore());
    }));
    super.initState();
  }

  @override
  void dispose() {
    notifier.removeRefreshCallback(refreshCallback);
    notifier.removeLoadMoreCallback(loadMoreCallback);
    super.dispose();
  }

  Widget buildChild({
    required BuildContext context,
    required DatasourceNotifier<DATA> notifier,
    required Widget Function() loading,
    required Widget Function(Object error) error,
    required Widget Function(DATA data) data,
  }) {
    this.loading = loading;
    this.error = error;
    this.data = data;
    if (notifier.isRefreshing()) {
      return _buildRefreshStatusWidget(notifier, context);
    }
    if (notifier.isLoadMoreIng()) {
      return _buildLoadMoreStatusWidget(notifier, context);
    }
    return _buildFinishedWidget(notifier, context);
  }

  Widget _buildRefreshStatusWidget(
      DatasourceNotifier<DATA> notifier, BuildContext context) {
    switch (notifier.loadingType) {
      case LoadingType.refreshWidget:
        return _buildFinishedWidget(notifier, context);
      case LoadingType.statusWidget:
        return loading();
      case LoadingType.auto:
        if (notifier.isEmpty) {
          return loading();
        } else {
          return _buildFinishedWidget(notifier, context);
        }
      case LoadingType.none:
        return _buildFinishedWidget(notifier, context);
    }
  }

  Widget _buildLoadMoreStatusWidget(
      DatasourceNotifier<DATA> notifier, BuildContext context) {
    switch (notifier.loadingType) {
      case LoadingType.refreshWidget:
        return _buildFinishedWidget(notifier, context);
      case LoadingType.statusWidget:
        return loading();
      case LoadingType.auto:
        if (notifier.isEmpty) {
          return loading();
        } else {
          return _buildFinishedWidget(notifier, context);
        }
      case LoadingType.none:
        return _buildFinishedWidget(notifier, context);
    }
  }

  Widget _buildFinishedWidget(
      DatasourceNotifier<DATA> notifier, BuildContext context) {
    if (notifier.isNotEmpty) {
      return data(notifier.data);
    }
    if (notifier.error != null) {
      return error(notifier.error!);
    }
    return data(notifier.data);
  }
}
