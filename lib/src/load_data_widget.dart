import 'dart:async';
import 'package:flutter/material.dart';
import 'data_source.dart';
import 'data_widget_builder.dart';
import 'task.dart';
import 'task_helper.dart';
import 'refresh/no_refresh_adapter.dart';
import 'refresh_widget_adapter.dart';
import 'status_widget_builder.dart';

class LoadDataWidget<DATA> extends StatefulWidget {
  final DataSource<DATA> dataSource;
  final DataWidgetBuilder<DATA> dataWidgetBuilder;
  final RefreshWidgetAdapter refreshWidgetAdapter;
  final LoadController<DATA> controller;
  final bool firstNeedRefresh;
  final StatusWidgetBuilder statusWidgetBuilder;

  @override
  LoadDataWidgetState<DATA> createState() {
    return LoadDataWidgetState<DATA>();
  }

  LoadDataWidget.buildByDataSource({
    @required this.dataSource, //加载数据的dataSource
    @required this.dataWidgetBuilder, //加载成功数据的widgetBuilder
    this.controller, //用于外部手动调用refresh，loadMore，addCallback，cancel等功能
    this.statusWidgetBuilder, //根据加载创建unload,loading,fail,empty等布局，如果不传默认使用DefaultStatusWidgetBuilder
    this.firstNeedRefresh = true, //当布局加载的时候是否自动调用刷新加载数据
    this.refreshWidgetAdapter, //刷新控件适配器，如果不传默认不带有刷新功能
  });

  LoadDataWidget.buildByTask({
    @required Task<DATA> task, //加载数据的task，相比于dataSource只有刷新没有加载更多的功能
    @required this.dataWidgetBuilder, //加载成功数据的widgetBuilder
    this.controller, //用于外部手动调用refresh，loadMore，addCallback，cancel等功能
    this.statusWidgetBuilder, //根据加载创建unload,loading,fail,empty等布局，如果不传默认使用DefaultStatusWidgetBuilder
    this.firstNeedRefresh = true, //当布局加载的时候是否自动调用刷新加载数据
    this.refreshWidgetAdapter, //刷新控件适配器，如果不传默认不带有刷新功能
  }) : this.dataSource = DataSource.buildByTask<DATA>(task);
}

class LoadDataWidgetState<DATA> extends State<LoadDataWidget<DATA>> {
  _LoadControllerImp<DATA> _loadControllerImp = _LoadControllerImp<DATA>();

  @override
  void initState() {
    super.initState();
    _loadControllerImp.set(
        context: context,
        dataSource: widget.dataSource,
        statusWidgetBuilder: widget.statusWidgetBuilder,
        dataWidgetBuilder: widget.dataWidgetBuilder,
        refreshWidgetAdapter: widget.refreshWidgetAdapter);
    if (widget.controller != null) {
      widget.controller._setControllerImp(_loadControllerImp);
    }

    Callback<DATA> callback = Callback.build<DATA>(onStart: () {
      setState(() {});
    }, onProgress: (int count, int total, [Object progressData]) {
      setState(() {});
    }, onEnd: (ResultCode code, DATA data, Object error) {
      setState(() {});
    });
    _loadControllerImp.addRefreshCallback(callback);
    _loadControllerImp.addLoadMoreCallback(callback);
    if (widget.firstNeedRefresh) {
      _loadControllerImp.refresh();
    }
  }

  @override
  void didUpdateWidget(covariant LoadDataWidget<DATA> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadControllerImp.set(
        context: context,
        dataSource: widget.dataSource,
        statusWidgetBuilder: widget.statusWidgetBuilder,
        dataWidgetBuilder: widget.dataWidgetBuilder,
        refreshWidgetAdapter: widget.refreshWidgetAdapter);
    if (widget.controller != null) {
      widget.controller._setControllerImp(_loadControllerImp);
    }
    if (oldWidget != null && oldWidget.controller != null) {
      oldWidget.controller._setControllerImp(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loadControllerImp.getWidget();
  }

  @override
  void dispose() {
    _loadControllerImp.dispose();
    super.dispose();
  }
}

///statusWidgetBuilder 布局创建的状态
///unload 未加载状态
///loading 状态
///fail 加载失败状态
///empty 数据为空，通过DataWidgetBuilder.isEmpty()判断
///正常显示数据
enum WidgetStatus {
  unload,
  loading,
  fail,
  empty,
  normal,
}

///refresh_widget 刷新控件header显示
///status_widget statusWidgetBuilder的loading方式显示
///自动判断显示方式
///不显示loading状态
enum RefreshingType { refresh_widget, status_widget, auto, none }

class LoadController<DATA> {
  _LoadControllerImp<DATA> _loadControllerImp;
  List<Callback<DATA>> refreshCallbacks = List<Callback<DATA>>();
  List<Callback<DATA>> loadMoreCallbacks = List<Callback<DATA>>();

  void _setControllerImp(_LoadControllerImp<DATA> loadControllerImp) {
    this._loadControllerImp = loadControllerImp;
    if (_loadControllerImp != null) {
      _loadControllerImp.refreshCallbackList.callbacks.addAll(refreshCallbacks);
      refreshCallbacks.clear();
    }
  }

  void refresh({RefreshingType refreshingType = RefreshingType.auto}) {
    _loadControllerImp?.refresh(refreshingType: refreshingType);
  }

  void loadMore({RefreshingType refreshingType = RefreshingType.auto}) {
    _loadControllerImp?.loadMore(refreshingType: refreshingType);
  }

  void addRefreshCallback(Callback<DATA> callback) {
    if (_loadControllerImp == null) {
      refreshCallbacks.add(callback);
    }
    _loadControllerImp?.addRefreshCallback(callback);
  }

  void removeRefreshCallback(Callback<DATA> callback) {
    if (_loadControllerImp == null) {
      refreshCallbacks.remove(callback);
    }
    _loadControllerImp?.removeRefreshCallback(callback);
  }

  void addLoadMoreCallback(Callback<DATA> callback) {
    if (_loadControllerImp == null) {
      loadMoreCallbacks.add(callback);
    }
    _loadControllerImp?.addLoadMoreCallback(callback);
  }

  void removeLoadMoreCallback(Callback<DATA> callback) {
    if (_loadControllerImp == null) {
      loadMoreCallbacks.remove(callback);
    }
    _loadControllerImp?.removeLoadMoreCallback(callback);
  }

  void cancel() {
    _loadControllerImp?.cancel();
  }

  bool isLoading() {
    return _loadControllerImp?.isLoading();
  }
}

class _LoadControllerImp<DATA> {
  DataSource<DATA> dataSource;
  DataWidgetBuilder<DATA> dataWidgetBuilder;
  StatusWidgetBuilder statusWidgetBuilder;
  Widget contentWidget;
  Widget statusWidget;
  Widget refreshWidget;
  WidgetBuilder widgetBuilder;
  RefreshWidgetAdapter refreshWidgetAdapter;
  BuildContext context;

  CallbackList<DATA> refreshCallbackList = CallbackList<DATA>();
  CallbackList<DATA> loadMoreCallbackList = CallbackList<DATA>();

  bool isRefreshing = false;
  bool isLoadMoreIng = false;
  final TaskHelper taskHelper = TaskHelper();

  void set(
      {BuildContext context,
      @required DataSource<DATA> dataSource,
      @required DataWidgetBuilder<DATA> dataWidgetBuilder,
      RefreshWidgetAdapter refreshWidgetAdapter,
      StatusWidgetBuilder statusWidgetBuilder}) {
    if (statusWidgetBuilder == null) {
      statusWidgetBuilder = DefaultStatusWidgetBuilder();
    }
    if (refreshWidgetAdapter == null) {
      refreshWidgetAdapter = NoRefreshAdapter();
    }
    this.dataSource = dataSource;
    this.dataWidgetBuilder = dataWidgetBuilder;
    this.refreshWidgetAdapter = refreshWidgetAdapter;
    this.statusWidgetBuilder = statusWidgetBuilder;

    refreshWidgetAdapter.setOnRefreshListener(_refresh);
    refreshWidgetAdapter.setOnLoadMoreListener(_loadMore);
  }

  Widget getWidget() {
    if (refreshWidget == null) {
      buildInit();
    }
    return refreshWidget;
  }

  ///refreshingType 用于控制是刷新控件header显示还是，statusWidget的loading显示。或者不显示
  void refresh({RefreshingType refreshingType = RefreshingType.auto}) {
    switch (refreshingType) {
      case RefreshingType.refresh_widget:
        refreshWidgetAdapter.requestRefresh();
        break;
      case RefreshingType.status_widget:
        _refresh(showLoadingWidget: true);
        break;
      case RefreshingType.auto:
        if (refreshWidgetAdapter != null &&
            refreshWidgetAdapter.enableRefresh) {
          if (dataWidgetBuilder.isEmpty()) {
            _refresh(showLoadingWidget: true);
          } else {
            refreshWidgetAdapter.requestRefresh();
          }
        } else {
          _refresh(showLoadingWidget: true);
        }
        break;
      case RefreshingType.none:
        _refresh(showLoadingWidget: false);
        break;
    }
  }

  void loadMore({RefreshingType refreshingType = RefreshingType.auto}) {
    switch (refreshingType) {
      case RefreshingType.refresh_widget:
        refreshWidgetAdapter.requestLoadMore();
        break;
      case RefreshingType.status_widget:
        _loadMore(showLoadingWidget: true);
        break;
      case RefreshingType.auto:
        if (dataWidgetBuilder.isEmpty()) {
          _loadMore(showLoadingWidget: true);
        } else {
          refreshWidgetAdapter.requestLoadMore();
        }
        break;
      case RefreshingType.none:
        _loadMore(showLoadingWidget: false);
        break;
    }
  }

  Future<void> _refresh({bool showLoadingWidget = false}) {
    Completer completer = new Completer();
    taskHelper.cancelAll();
    isRefreshing = true;

    Callback<DATA> callback = Callback.build<DATA>(onStart: () {
      //start -------
      buildLoadStart(true, showLoadingWidget);
      refreshCallbackList.onStart();
    }, onProgress: (int current, int total, [Object progressData]) {
      //progress ------
      buildProgress(true, showLoadingWidget, current, total, progressData);
      refreshCallbackList.onProgress(current, total, progressData);
    }, onEnd: (ResultCode code, DATA data, Object error) {
      //end ----------
      switch (code) {
        case ResultCode.success:
          //通知更新数据
          dataWidgetBuilder.notifyDataChange(data, true);
          buildSuccessWidget(true);
          break;
        case ResultCode.fail:
          buildErrorWidget(true, error);
          break;
        case ResultCode.cancel:
          buildCancelWidget(true);
          break;
      }
      refreshWidgetAdapter.finishRefresh(
          context, code == ResultCode.success, error, !dataSource.hasMore());
      isRefreshing = false;
      //通知监听更新
      refreshCallbackList.onEnd(code, data, error);
      completer.complete();
    });
    taskHelper.executeByFunction<DATA>(dataSource.refresh, callback: callback);
    return completer.future;
  }

  Future<void> _loadMore({bool showLoadingWidget = false}) {
    Completer completer = new Completer();
    if (isLoading()) {
      refreshWidgetAdapter.finishLoadMore(
          context, true, null, !dataSource.hasMore());
      completer.complete();
      return completer.future;
    }
    if (!dataSource.hasMore()) {
      refreshWidgetAdapter.finishLoadMore(
          context, true, null, !dataSource.hasMore());
      completer.complete();
      return completer.future;
    }
    taskHelper.cancelAll();
    isLoadMoreIng = true;

    Callback<DATA> callback = Callback.build<DATA>(onStart: () {
      //start -------
      buildLoadStart(false, showLoadingWidget);
      loadMoreCallbackList.onStart();
    }, onProgress: (int current, int total, [Object progressData]) {
      //progress ------
      buildProgress(false, showLoadingWidget, current, total, progressData);
      loadMoreCallbackList.onProgress(current, total, progressData);
    }, onEnd: (ResultCode code, DATA data, Object error) {
      //end ----------
      switch (code) {
        case ResultCode.success:
          //通知更新数据
          dataWidgetBuilder.notifyDataChange(data, false);
          buildSuccessWidget(false);
          break;
        case ResultCode.fail:
          buildErrorWidget(false, error);
          break;
        case ResultCode.cancel:
          buildCancelWidget(false);
          break;
      }
      refreshWidgetAdapter.finishLoadMore(
          context, code == ResultCode.success, error, !dataSource.hasMore());
      isLoadMoreIng = false;
      loadMoreCallbackList.onEnd(code, data, error);
      completer.complete();
    });
    taskHelper.executeByFunction<DATA>(dataSource.loadMore, callback: callback);
    return completer.future;
  }

  Widget refreshWrap(
      WidgetStatus status, Widget statusWidget, Widget contentWidget) {
    this.statusWidget = statusWidget;
    this.contentWidget = contentWidget;
    if (refreshWidgetAdapter != null) {
      return refreshWidgetAdapter.wrapChild(
          context, status, statusWidget, contentWidget);
    }
    return status == WidgetStatus.normal ? contentWidget : statusWidget;
  }

  bool isUnload() {
    return dataWidgetBuilder.getData() == null;
  }

  void buildInit() {
    if (dataWidgetBuilder.getData() == null) {
      refreshWidget = refreshWrap(WidgetStatus.unload,
          statusWidgetBuilder.buildUnLoadWidget(context, refresh), null);
    } else {
      refreshWidget = refreshWrap(
          WidgetStatus.normal, null, dataWidgetBuilder.build(context));
    }
  }

  void buildErrorWidget(bool isRefresh, Object error) {
    if (dataWidgetBuilder.isEmpty()) {
      refreshWidget = refreshWrap(
          WidgetStatus.fail,
          statusWidgetBuilder.buildFailWidget(context, error, refresh),
          contentWidget);
    } else {
      statusWidgetBuilder.tipFail(context, error, refresh);
    }
  }

  void buildCancelWidget(bool isRefresh) {
    if (isUnload()) {
      refreshWidget = refreshWrap(
          WidgetStatus.unload,
          statusWidgetBuilder.buildUnLoadWidget(context, refresh),
          contentWidget);
    } else if (dataWidgetBuilder.isEmpty()) {
      refreshWidget = refreshWrap(
          WidgetStatus.fail,
          statusWidgetBuilder.buildFailWidget(context, null, refresh),
          contentWidget);
    } else {
      if (contentWidget != null) {
        refreshWidget = refreshWrap(WidgetStatus.normal, null, contentWidget);
      } else {
        refreshWidget = refreshWrap(
            WidgetStatus.normal, null, dataWidgetBuilder.build(context));
      }
    }
  }

  void buildSuccessWidget(bool isRefresh) {
    if (!dataWidgetBuilder.isEmpty()) {
      //数据不为空
      refreshWidget = refreshWrap(
          WidgetStatus.normal, null, dataWidgetBuilder.build(context));
    } else {
      //如果数据为空，显示空数据--------------
      refreshWidget = refreshWrap(
          WidgetStatus.empty,
          statusWidgetBuilder.buildEmptyWidget(context, refresh),
          contentWidget);
    }
  }

  void buildLoadStart(bool isRefresh, bool showLoadingWidget) {
    if (showLoadingWidget) {
      refreshWidget = refreshWrap(
          WidgetStatus.loading,
          statusWidgetBuilder.buildLoadingWidget(context, null, null, null),
          contentWidget);
    } else {
      //数据不为空,但是Widget为空
      if (statusWidget != null) {
        refreshWidget = refreshWrap(WidgetStatus.loading, statusWidget, null);
      } else {
        if (dataWidgetBuilder.getData() == null) {
          refreshWidget = refreshWrap(
              WidgetStatus.unload,
              statusWidgetBuilder.buildUnLoadWidget(context, refresh),
              contentWidget);
        } else {
          refreshWidget = refreshWrap(WidgetStatus.normal, null, contentWidget);
        }
      }
    }
  }

  void buildProgress(bool isRefresh, bool showLoadingWidget, int current, total,
      Object progressData) {
    if (showLoadingWidget) {
      refreshWidget = refreshWrap(
          WidgetStatus.loading,
          statusWidgetBuilder.buildLoadingWidget(
              context, current, total, progressData),
          contentWidget);
    }
  }

  void addRefreshCallback(Callback<DATA> callback) {
    refreshCallbackList.addCallback(callback);
  }

  void removeRefreshCallback(Callback<DATA> callback) {
    refreshCallbackList.removeCallback(callback);
  }

  void addLoadMoreCallback(Callback<DATA> callback) {
    loadMoreCallbackList.addCallback(callback);
  }

  void removeLoadMoreCallback(Callback<DATA> callback) {
    loadMoreCallbackList.removeCallback(callback);
  }

  void cancel() {
    taskHelper.cancelAll();
  }

  void dispose() {
    cancel();
  }

  bool isLoading() {
    return isRefreshing && isLoadMoreIng;
  }
}
