import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'datasource_provider.dart';
import 'datasource_refresh_adapter.dart';

class PullToRefreshDelegate implements RefreshDelegate {
  final bool enableLoadMore;
  final bool enableRefresh;

  final Widget? footer;
  final Widget? header;

  const PullToRefreshDelegate({
    this.enableLoadMore = true,
    this.enableRefresh = true,
    this.footer,
    this.header,
  });

  @override
  Widget build<DATA>({
    required Widget Function() loading,
    required Widget Function(Object error) error,
    required Widget Function(DATA data) data,
  }) {
    return _PullToRefresh<DATA>(
      delegate: this,
      loading: loading,
      error: error,
      data: data,
    );
  }
}

class _PullToRefresh<DATA> extends StatefulWidget {
  final PullToRefreshDelegate delegate;
  final Widget Function() loading;
  final Widget Function(Object error) error;
  final Widget Function(DATA data) data;

  const _PullToRefresh({
    super.key,
    required this.delegate,
    required this.loading,
    required this.error,
    required this.data,
  });

  @override
  State<_PullToRefresh<DATA>> createState() => _PullToRefreshState<DATA>();
}

class _PullToRefreshState<DATA> extends State<_PullToRefresh<DATA>>
    with ContentBuilder<DATA, _PullToRefresh<DATA>> {
  @override
  _PullToRefreshControllerAdapter refreshAdapter =
      _PullToRefreshControllerAdapter();

  @override
  Widget build(BuildContext context) {
    var delegate = widget.delegate;
    var notifier = DatasourceProviderKey.staticWatch<DATA>(context);
    bool canLoadMoreInCurrentStatus =
        !notifier.isRefreshing() && notifier.data != null;
    bool enableLoadMore =
        widget.delegate.enableLoadMore && canLoadMoreInCurrentStatus;
    return SmartRefresher(
      // 定制header。如果想全局配置默认的header通过 RefreshConfiguration配置（按照InheritedWidget的用法配置），或者新类也可以继承重写该方法
      header: delegate.header,
      footer: delegate.footer,
      enablePullDown: delegate.enableRefresh,
      enablePullUp: enableLoadMore,
      onRefresh: notifier.refresh,
      onLoading: notifier.loadMore,
      controller: refreshAdapter._controller,
      child: buildChild(
        context: context,
        notifier: notifier,
        loading: widget.loading,
        data: widget.data,
        error: widget.error,
      ),
    );
  }
}

class _PullToRefreshControllerAdapter implements RefreshControllerAdapter {
  final RefreshController _controller =
      RefreshController(initialRefresh: false);

  @override
  void finishLoadMore(
      BuildContext context, bool success, Object? error, bool noMore) {
    if (noMore) {
      _controller.loadNoData();
    } else if (success) {
      _controller.loadComplete();
    } else {
      _controller.loadFailed();
    }
  }

  @override
  void finishRefresh(
      BuildContext context, bool success, Object? error, bool noMore) {
    if (_controller.isRefresh) {
      if (success) {
        _controller.refreshCompleted();
      } else {
        _controller.refreshFailed();
      }
      if (noMore) {
        _controller.loadNoData();
      } else {
        _controller.loadComplete();
      }
    }
  }

  @override
  void showLoadMoreIng() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.requestLoading();
    });
  }

  @override
  void showRefreshing() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.requestRefresh();
    });
  }
}
