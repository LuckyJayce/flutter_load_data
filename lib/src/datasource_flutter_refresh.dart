import 'package:flutter/material.dart';

import 'datasource_provider.dart';
import 'datasource_refresh_adapter.dart';

class FlutterRefreshDelegate implements RefreshDelegate {
  final bool enableLoadMore;
  final bool enableRefresh;

  const FlutterRefreshDelegate({
    this.enableLoadMore = true,
    this.enableRefresh = true,
  });

  @override
  Widget build<DATA>({
    required Widget Function() loading,
    required Widget Function(Object error) error,
    required Widget Function(DATA data) data,
  }) {
    return _FlutterRefresh<DATA>(
      delegate: this,
      loading: loading,
      error: error,
      data: data,
    );
  }
}

class _FlutterRefresh<DATA> extends StatefulWidget {
  final FlutterRefreshDelegate delegate;
  final Widget Function() loading;
  final Widget Function(Object error) error;
  final Widget Function(DATA data) data;

  const _FlutterRefresh({
    super.key,
    required this.delegate,
    required this.loading,
    required this.error,
    required this.data,
  });

  @override
  State<_FlutterRefresh<DATA>> createState() => _FlutterRefreshState<DATA>();
}

class _FlutterRefreshState<DATA> extends State<_FlutterRefresh<DATA>>
    with ContentBuilder<DATA, _FlutterRefresh<DATA>> {
  @override
  _PullToRefreshControllerAdapter refreshAdapter =
      _PullToRefreshControllerAdapter();

  @override
  Widget build(BuildContext context) {
    var delegate = widget.delegate;
    var notifier = DatasourceProviderKey.staticWatch<DATA>(context);
    bool canLoadMoreInCurrentStatus =
        !notifier.isRefreshing() && notifier.data != null;
    bool enableLoadMore = delegate.enableLoadMore && canLoadMoreInCurrentStatus;
    return RefreshLoadMoreWidget(
      key: refreshAdapter.refreshKey,
      enableLoadMore: enableLoadMore,
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
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
  var refreshKey = GlobalKey<RefreshLoadMoreWidgetState>();

  @override
  void finishLoadMore(
      BuildContext context, bool success, Object? error, bool noMore) {
    refreshKey.currentState?.finishLoadMore();
  }

  @override
  void finishRefresh(
      BuildContext context, bool success, Object? error, bool noMore) {}

  @override
  void showLoadMoreIng() {
    refreshKey.currentState?.showLoadMore();
  }

  @override
  void showRefreshing() {
    refreshKey.currentState?.showRefresh();
  }
}

class RefreshLoadMoreWidget extends StatefulWidget {
  final RefreshCallback onRefresh;
  final RefreshCallback onLoadMore;
  final Widget child;
  final RefreshIndicatorTriggerMode? triggerMode;
  final bool enableLoadMore;
  final Widget? footer;

  const RefreshLoadMoreWidget(
      {required this.onRefresh,
      required this.child,
      this.triggerMode,
      this.footer,
      required this.onLoadMore,
      required this.enableLoadMore,
      Key? key})
      : super(key: key);

  @override
  State<RefreshLoadMoreWidget> createState() => RefreshLoadMoreWidgetState();
}

class RefreshLoadMoreWidgetState extends State<RefreshLoadMoreWidget> {
  bool _isLoadMoreIng = false;
  var refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scroll) {
        if (widget.enableLoadMore) {
          if (_isBottom(scroll)) {
            if (!_isLoadMoreIng) {
              loadMore();
            }
            return true;
          }
        }
        return false;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: RefreshIndicator(
              key: refreshKey,
              // 定制header。如果想全局配置默认的header通过 RefreshConfiguration配置（按照InheritedWidget的用法配置），或者新类也可以继承重写该方法
              onRefresh: widget.onRefresh,
              child: widget.child,
            ),
          ),
          Visibility(
            visible: _isLoadMoreIng,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: widget.footer ?? const Text('Loading..'),
            ),
          )
        ],
      ),
    );
  }

  void showRefresh() {
    refreshKey.currentState?.show();
  }

  Future<void> loadMore() async {
    showLoadMore();
    await widget.onLoadMore();
    finishLoadMore();
  }

  void showLoadMore() {
    _isLoadMoreIng = true;
    setState(() {});
  }

  void finishLoadMore() {
    _isLoadMoreIng = false;
    setState(() {});
  }

  bool _isBottom(ScrollNotification notification) {
    return ((notification.metrics.axisDirection == AxisDirection.up &&
            notification.metrics.extentBefore == 0.0) ||
        (notification.metrics.axisDirection == AxisDirection.down &&
            notification.metrics.extentAfter < 60.0));
  }
}
