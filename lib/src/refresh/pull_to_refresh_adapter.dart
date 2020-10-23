import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../load_data_widget.dart';
import '../refresh_widget_adapter.dart';

//适配 https://github.com/peng8350/flutter_pulltorefresh 刷新控件
class PullToRefreshWidgetAdapter implements RefreshWidgetAdapter {
  VoidCallback onRefresh;
  VoidCallback onLoadMore;
  RefreshController _controller = RefreshController(initialRefresh: false);
  bool enableLoadMore;
  bool enableRefresh;

  PullToRefreshWidgetAdapter(
      {this.enableLoadMore = true, this.enableRefresh = true});

  @override
  void setOnRefreshListener(VoidCallback onRefresh) {
    this.onRefresh = onRefresh;
  }

  @override
  void setOnLoadMoreListener(VoidCallback onLoadMore) {
    this.onLoadMore = onLoadMore;
  }

  @override
  void requestLoadMore() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.requestLoading();
    });
  }

  @override
  void requestRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.requestRefresh();
    });
  }

  @override
  Widget wrapChild(BuildContext context, WidgetStatus status,
      Widget statusWidget, Widget contentWidget) {
    bool enableLoadMore = this.enableLoadMore && status == WidgetStatus.normal;
    return SmartRefresher(
      // 定制header。如果想全局配置默认的header通过 RefreshConfiguration配置（按照InheritedWidget的用法配置），或者新类也可以继承重写该方法
      // header: WaterDropHeader(),
      enablePullDown: enableRefresh,
      enablePullUp: enableLoadMore,
      onRefresh: onRefresh,
      onLoading: onLoadMore,
      child: status == WidgetStatus.normal ? contentWidget : statusWidget,
      controller: _controller,
    );
  }

  @override
  void finishRefresh(
      BuildContext context, bool success, Object error, bool noMore) {
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
  void finishLoadMore(
      BuildContext context, bool success, Object error, bool noMore) {
    if (noMore) {
      _controller.loadNoData();
    } else if (success) {
      _controller.loadComplete();
    } else {
      _controller.loadFailed();
    }
  }
}
