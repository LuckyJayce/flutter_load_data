/*
    Author: Jayce
    createTime:2020-10
*/
import 'package:flutter/widgets.dart';

import '../load_data_widget.dart';
import '../refresh_adapter.dart';

class NoRefreshAdapter extends RefreshAdapter {
  const NoRefreshAdapter();

  @override
  bool get enableLoadMore => false;

  @override
  bool get enableRefresh => false;

  @override
  void requestLoadMore() {}

  @override
  void requestRefresh() {}

  @override
  void setOnLoadMoreListener(loadMoreFutureCallback) {}

  @override
  void setOnRefreshListener(onRefresh) {}

  @override
  Widget wrapChild(BuildContext context, WidgetStatus status,
      Widget? statusWidget, Widget? contentWidget) {
    if (status == WidgetStatus.normal) {
      return contentWidget!;
    }
    return statusWidget!;
  }

  @override
  void finishLoadMore(
      BuildContext context, bool success, Object? error, bool noMore) {}

  @override
  void finishRefresh(
      BuildContext context, bool success, Object? error, bool noMore) {}
}
