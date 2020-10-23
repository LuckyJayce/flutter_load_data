/*
    Author: Jayce
    createTime:2020-10
*/

import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';

import '../load_data_widget.dart';
import '../refresh_widget_adapter.dart';

//适配 https://github.com/xuelongqy/flutter_easyrefresh 刷新控件
class EasyRefreshWidgetAdapter implements RefreshWidgetAdapter {
  VoidCallback onRefresh;
  VoidCallback onLoadMore;
  EasyRefreshController _controller = EasyRefreshController();
  bool enableLoadMore;
  bool enableRefresh;

  EasyRefreshWidgetAdapter(
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
      _controller.callLoad();
    });
  }

  @override
  void requestRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.callRefresh();
    });
  }

  @override
  Widget wrapChild(BuildContext context, WidgetStatus status,
      Widget statusWidget, Widget contentWidget) {
    bool enableLoadMore = this.enableLoadMore && status == WidgetStatus.normal;
    return EasyRefresh(
      //定制header。如果想全局设置header可以通过  EasyRefresh.defaultHeader = MaterialHeader();设置，或者新类也可以继承重写该方法
      // header: MaterialHeader(),
      onRefresh: enableRefresh ? onRefresh : null,
      onLoad: enableLoadMore ? onLoadMore : null,
      emptyWidget: statusWidget,
      child: contentWidget != null ? contentWidget : Container(),
      controller: _controller,
    );
  }

  @override
  void finishLoadMore(
      BuildContext context, bool success, Object error, bool noMore) {
    _controller.finishLoad(success: success, noMore: noMore);
  }

  @override
  void finishRefresh(
      BuildContext context, bool success, Object error, bool noMore) {
    //该方法参数noMore是没有更多数据不需要加载更多
    //EasyRefresh的noMore是不能继续刷新的意思
    _controller.finishRefresh(success: success);
  }
}
