/*
    Author: Jayce
    createTime:2020-10
*/

import 'package:flutter/widgets.dart';

import 'load_data_widget.dart';

///刷新控件适配器
abstract class RefreshAdapter {
  const RefreshAdapter();

  Widget wrapChild(BuildContext context, WidgetStatus status,
      Widget? statusWidget, Widget? contentWidget);

  void requestRefresh();

  void requestLoadMore();

  void setOnRefreshListener(VoidCallback onRefresh);

  void setOnLoadMoreListener(VoidCallback loadMoreFutureCallback);

  void finishRefresh(
      BuildContext context, bool success, Object? error, bool noMore);

  void finishLoadMore(
      BuildContext context, bool success, Object? error, bool noMore);

  bool get enableLoadMore;

  bool get enableRefresh;
}
