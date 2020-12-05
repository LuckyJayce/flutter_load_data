/*
    Author: Jayce
    createTime:2020-10
*/

import 'dart:async';
import 'package:flutter/material.dart';
import '../load_data.dart';
import 'data_source.dart';
import 'data_delegate.dart';
import 'task_helper.dart';
import 'refresh/no_refresh_adapter.dart';
import 'refresh_adapter.dart';
import 'status_delegate.dart';

class LoadDataWidget<DATA> extends StatefulWidget {
  final LoadController<DATA> controller;
  final ConfigCreate<DATA> configCreate;
  final ShouldRecreate<DATA> shouldRecreate;

  LoadDataWidget({
    this.controller, //用于外部手动调用refresh，loadMore，addCallback，cancel等功能
    @required this.configCreate, //加载成功数据的widgetBuilder
    this.shouldRecreate, //加载成功数据的widgetBuilder
  });

  @override
  LoadDataWidgetState<DATA> createState() {
    return LoadDataWidgetState<DATA>();
  }
}

class LoadDataWidgetState<DATA> extends State<LoadDataWidget<DATA>> {
  _LoadControllerImp<DATA> _loadControllerImp = _LoadControllerImp<DATA>();
  LoadConfig<DATA> loadConfig;

  @override
  void initState() {
    super.initState();
    loadConfig = widget.configCreate(context, null);
    _loadControllerImp.set(
        context: context,
        dataSource: loadConfig.dataSource,
        dataManager: loadConfig.dataManager,
        statusWidgetDelegate: loadConfig.statusDelegate,
        dataWidgetDelegate: loadConfig.dataDelegate,
        refreshAdapter: loadConfig.refreshAdapter);
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
    if (loadConfig.firstNeedRefresh) {
      _loadControllerImp.refresh();
    }
  }

  @override
  void didUpdateWidget(covariant LoadDataWidget<DATA> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null) {
      widget.controller._setControllerImp(_loadControllerImp);
    }
    if (oldWidget != null && oldWidget.controller != null) {
      oldWidget.controller._setControllerImp(null);
    }
    if (widget.shouldRecreate != null) {
      bool shouldRecreate = widget.shouldRecreate(context, loadConfig);
      if (shouldRecreate) {
        LoadConfig old = loadConfig;
        loadConfig = widget.configCreate(context, old);
        _loadControllerImp.set(
          context: context,
          dataSource: loadConfig.dataSource,
          dataManager: loadConfig.dataManager,
          statusWidgetDelegate: loadConfig.statusDelegate,
          dataWidgetDelegate: loadConfig.dataDelegate,
          refreshAdapter: loadConfig.refreshAdapter,
        );
        if (old.dataSource != loadConfig.dataSource) {
          _loadControllerImp.refresh();
        }
        //TODO
        // else if (old.dataDelegate != loadConfig.dataDelegate)
        //   _loadControllerImp.refreshWrap(status, statusWidget, contentWidget);
        // }
      }
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
  DataDelegate<DATA> dataWidgetDelegate;
  StatusDelegate statusWidgetDelegate;
  DataManager<DATA> dataManager;
  Widget contentWidget;
  Widget statusWidget;
  Widget refreshWidget;
  WidgetBuilder widgetBuilder;
  RefreshAdapter refreshWidgetAdapter;
  BuildContext context;

  WidgetStatus status;

  CallbackList<DATA> refreshCallbackList = CallbackList<DATA>();
  CallbackList<DATA> loadMoreCallbackList = CallbackList<DATA>();

  bool isRefreshing = false;
  bool isLoadMoreIng = false;
  final TaskHelper taskHelper = TaskHelper();

  void set(
      {BuildContext context,
      @required DataSource<DATA> dataSource,
      @required DataManager<DATA> dataManager,
      @required DataDelegate<DATA> dataWidgetDelegate,
      RefreshAdapter refreshAdapter,
      StatusDelegate statusWidgetDelegate}) {
    if (statusWidgetDelegate == null) {
      statusWidgetDelegate = DefaultStatusDelegate();
    }
    if (refreshAdapter == null) {
      refreshAdapter = NoRefreshAdapter();
    }
    this.dataSource = dataSource;
    this.dataManager = dataManager;
    this.dataWidgetDelegate = dataWidgetDelegate;
    this.refreshWidgetAdapter = refreshAdapter;
    this.statusWidgetDelegate = statusWidgetDelegate;

    refreshAdapter.setOnRefreshListener(_refresh);
    refreshAdapter.setOnLoadMoreListener(_loadMore);
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
          if (dataManager.isEmpty()) {
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
        if (dataManager.isEmpty()) {
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
          dataManager.notifyDataChange(data, true);
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
          dataManager.notifyDataChange(data, false);
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
    this.status = status;
    this.statusWidget = statusWidget;
    this.contentWidget = contentWidget;
    if (refreshWidgetAdapter != null) {
      return refreshWidgetAdapter.wrapChild(
          context, status, statusWidget, contentWidget);
    }
    return status == WidgetStatus.normal ? contentWidget : statusWidget;
  }

  bool isUnload() {
    return dataManager.getData() == null;
  }

  void buildInit() {
    if (dataManager.getData() == null) {
      refreshWidget = refreshWrap(WidgetStatus.unload,
          statusWidgetDelegate.buildUnLoadWidget(context, refresh), null);
    } else {
      refreshWidget = refreshWrap(WidgetStatus.normal, null,
          dataWidgetDelegate.build(context, dataManager.getData()));
    }
  }

  void buildErrorWidget(bool isRefresh, Object error) {
    if (dataManager.isEmpty()) {
      refreshWidget = refreshWrap(
          WidgetStatus.fail,
          statusWidgetDelegate.buildFailWidget(context, error, refresh),
          contentWidget);
    } else {
      statusWidgetDelegate.tipFail(context, error, refresh);
    }
  }

  void buildCancelWidget(bool isRefresh) {
    if (isUnload()) {
      refreshWidget = refreshWrap(
          WidgetStatus.unload,
          statusWidgetDelegate.buildUnLoadWidget(context, refresh),
          contentWidget);
    } else if (dataManager.isEmpty()) {
      refreshWidget = refreshWrap(
          WidgetStatus.fail,
          statusWidgetDelegate.buildFailWidget(context, null, refresh),
          contentWidget);
    } else {
      if (contentWidget != null) {
        refreshWidget = refreshWrap(WidgetStatus.normal, null, contentWidget);
      } else {
        refreshWidget = refreshWrap(WidgetStatus.normal, null,
            dataWidgetDelegate.build(context, dataManager.getData()));
      }
    }
  }

  void buildSuccessWidget(bool isRefresh) {
    if (!dataManager.isEmpty()) {
      //数据不为空
      refreshWidget = refreshWrap(WidgetStatus.normal, null,
          dataWidgetDelegate.build(context, dataManager.getData()));
    } else {
      //如果数据为空，显示空数据--------------
      refreshWidget = refreshWrap(
          WidgetStatus.empty,
          statusWidgetDelegate.buildEmptyWidget(context, refresh),
          contentWidget);
    }
  }

  void buildLoadStart(bool isRefresh, bool showLoadingWidget) {
    if (showLoadingWidget) {
      refreshWidget = refreshWrap(
          WidgetStatus.loading,
          statusWidgetDelegate.buildLoadingWidget(context, null, null, null),
          contentWidget);
    } else {
      //数据不为空,但是Widget为空
      if (statusWidget != null) {
        refreshWidget = refreshWrap(WidgetStatus.loading, statusWidget, null);
      } else {
        if (dataManager.getData() == null) {
          refreshWidget = refreshWrap(
              WidgetStatus.unload,
              statusWidgetDelegate.buildUnLoadWidget(context, refresh),
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
          statusWidgetDelegate.buildLoadingWidget(
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

class LoadConfig<DATA> {
  final DataSource<DATA> dataSource;
  final DataManager<DATA> dataManager;
  final DataDelegate<DATA> dataDelegate;
  final StatusDelegate statusDelegate;
  final RefreshAdapter refreshAdapter;
  final bool firstNeedRefresh;

  const LoadConfig(
      {@required this.dataSource,
      @required this.dataManager,
      @required this.dataDelegate,
      this.statusDelegate,
      this.refreshAdapter,
      this.firstNeedRefresh = true});
}

typedef ConfigCreate<DATA> = LoadConfig<DATA> Function(
    BuildContext context, LoadConfig<DATA> oldConfig);

typedef ShouldRecreate<DATA> = bool Function(
    BuildContext context, LoadConfig<DATA> config);
