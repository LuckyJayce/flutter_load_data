/*
    Author: Jayce
    createTime:2020-10
*/

import 'dart:async';
import 'package:flutter/material.dart';
import 'data_source.dart';
import 'data_delegate.dart';
import 'task.dart';
import 'task_helper.dart';
import 'refresh/no_refresh_adapter.dart';
import 'refresh_adapter.dart';

class LoadDataWidget<DATA> extends StatefulWidget {
  final LoadController<DATA>? controller;
  final ConfigCreate<DATA> configCreate;
  final ShouldRecreate<DATA>? shouldRecreate;

  LoadDataWidget({
    this.controller, //用于外部手动调用refresh，loadMore，addCallback，cancel等功能
    required this.configCreate, //加载成功数据的widgetBuilder
    this.shouldRecreate, //加载成功数据的widgetBuilder
  });

  @override
  LoadDataWidgetState<DATA> createState() {
    return LoadDataWidgetState<DATA>();
  }
}

class LoadDataWidgetState<DATA> extends State<LoadDataWidget<DATA>> {
  _LoadControllerImp<DATA> _loadControllerImp = _LoadControllerImp<DATA>();
  late LoadConfig<DATA> loadConfig;

  TaskStatus taskStatus = TaskStatus.un_load;
  late int current;
  late int total;
  Object? error;
  ResultCode? resultCode;
  Object? progressData;
  Widget? contentWidget;

  @override
  void initState() {
    super.initState();
    loadConfig = widget.configCreate(context, null);
    loadConfig.dataDelegate.init();
    _loadControllerImp.set(
      context: context,
      loadConfig: loadConfig,
      setStateCall: () {
        setState(() {});
      },
    );
    if (widget.controller != null) {
      widget.controller!._setControllerImp(_loadControllerImp);
    }
    Callback<DATA> callback = Callback.build<DATA>(onStart: () {
      setState(() {
        taskStatus = TaskStatus.start;
        current = -1;
        total = -1;
      });
    }, onProgress: (int current, int total, [Object? progressData]) {
      setState(() {
        this.current = current;
        this.total = total;
        this.progressData = progressData;
        this.taskStatus = TaskStatus.progress;
      });
    }, onPost: (ResultCode code, DATA? data, Object? error) {
      setState(() {
        this.error = error;
        this.resultCode = code;
        this.taskStatus = TaskStatus.end;
      });
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
    if (oldWidget.controller != widget.controller) {
      if (widget.controller != null) {
        widget.controller!._setControllerImp(_loadControllerImp);
      }
      if (oldWidget.controller != null) {
        oldWidget.controller!._setControllerImp(null);
      }
    }
    if (widget.shouldRecreate != null) {
      bool shouldRecreate = widget.shouldRecreate!(context, loadConfig);
      if (shouldRecreate) {
        LoadConfig? old = loadConfig;
        loadConfig = widget.configCreate(context, old as LoadConfig<DATA>?);
        if (loadConfig.dataDelegate != old.dataDelegate) {
          old.dataDelegate.dispose();
          loadConfig.dataDelegate.init();
        }
        _loadControllerImp.set(
          context: context,
          loadConfig: loadConfig,
          setStateCall: () {
            setState(() {});
          },
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
    Widget? widget;
    bool isRefresh = _loadControllerImp.isRefreshing;
    bool showLoadingWidget = _loadControllerImp.showLoadingWidget;
    switch (taskStatus) {
      case TaskStatus.un_load:
        widget = buildInit();
        break;
      case TaskStatus.start:
        widget = buildLoadStart(isRefresh, showLoadingWidget);
        break;
      case TaskStatus.progress:
        widget = buildProgress(
            isRefresh, showLoadingWidget, current, total, progressData);
        break;
      case TaskStatus.end:
        switch (resultCode!) {
          case ResultCode.success:
            widget = buildSuccessWidget();
            break;
          case ResultCode.fail:
            widget = buildErrorWidget(error!);
            break;
          case ResultCode.cancel:
            widget = buildCancelWidget();
            break;
        }
        break;
    }
    if (widget == null) {
      widget = buildInit();
    }
    return widget;
  }

  @override
  void dispose() {
    _loadControllerImp.dispose();
    loadConfig.dataDelegate.dispose();
    super.dispose();
  }

  Widget buildInit() {
    if (loadConfig.dataManager.getData() == null) {
      return refreshWrap(
          WidgetStatus.unload,
          loadConfig.dataDelegate.buildUnLoadWidget(context,
              loadConfig.dataManager.getData(), _loadControllerImp.refresh));
    }
    return refreshWrap(WidgetStatus.normal, null);
  }

  Widget? buildErrorWidget(Object error) {
    if (loadConfig.dataManager.isEmpty()) {
      return refreshWrap(
          WidgetStatus.fail,
          loadConfig.dataDelegate
              .buildFailWidget(context, error, _loadControllerImp.refresh));
    }
    return null;
  }

  Widget? buildCancelWidget() {
    if (isUnload()) {
      return refreshWrap(
          WidgetStatus.unload,
          loadConfig.dataDelegate.buildUnLoadWidget(context,
              loadConfig.dataManager.getData(), _loadControllerImp.refresh));
    }
    if (loadConfig.dataManager.isEmpty()) {
      return refreshWrap(
          WidgetStatus.empty,
          loadConfig.dataDelegate
              .buildEmptyWidget(context, _loadControllerImp.refresh));
    }
    return null;
  }

  bool isUnload() {
    return loadConfig.dataManager.getData() == null;
  }

  Widget? buildSuccessWidget() {
    if (!loadConfig.dataManager.isEmpty()) {
      contentWidget = loadConfig.dataDelegate
          .buildDataWidget(context, loadConfig.dataManager.getData());
      //数据不为空
      return refreshWrap(WidgetStatus.normal, null);
    }
    contentWidget = Container();
    //如果数据为空，显示空数据--------------
    return refreshWrap(
        WidgetStatus.empty,
        loadConfig.dataDelegate
            .buildEmptyWidget(context, _loadControllerImp.refresh));
  }

  Widget? buildLoadStart(bool isRefresh, bool showLoadingWidget) {
    if (showLoadingWidget) {
      return refreshWrap(WidgetStatus.loading,
          loadConfig.dataDelegate.buildLoadingWidget(context, -1, -1, null));
    }
    return null;
  }

  Widget? buildProgress(bool isRefresh, bool showLoadingWidget, int current,
      total, Object? progressData) {
    if (showLoadingWidget) {
      return refreshWrap(
          WidgetStatus.loading,
          loadConfig.dataDelegate
              .buildLoadingWidget(context, current, total, progressData));
    }
    return null;
  }

  Widget refreshWrap(WidgetStatus status, Widget? statusWidget) {
    if (contentWidget == null && loadConfig.dataManager.getData() != null) {
      contentWidget = loadConfig.dataDelegate
          .buildDataWidget(context, loadConfig.dataManager.getData());
    }
    return loadConfig.refreshAdapter
        .wrapChild(context, status, statusWidget, contentWidget);
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
  _LoadControllerImp<DATA>? _loadControllerImp;
  List<Callback<DATA>> refreshCallbacks = [];
  List<Callback<DATA>> loadMoreCallbacks = [];

  void _setControllerImp(_LoadControllerImp<DATA>? loadControllerImp) {
    this._loadControllerImp = loadControllerImp;
    if (loadControllerImp != null) {
      loadControllerImp.refreshCallbackList.callbacks.addAll(refreshCallbacks);
      refreshCallbacks.clear();
    }
  }

  void rebuild() {
    _loadControllerImp?.rebuild();
  }

  DATA? getData() {
    return _loadControllerImp?.loadConfig.dataManager.getData();
  }

  DataManager<DATA>? getDataManager() {
    return _loadControllerImp?.loadConfig.dataManager;
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
    return _loadControllerImp?.isLoading() ?? false;
  }
}

class _LoadControllerImp<DATA> {
  late BuildContext context;
  late LoadConfig<DATA> loadConfig;
  late VoidCallback setStateCall;

  Widget? contentWidget;
  Widget? statusWidget;
  Widget? refreshWidget;
  WidgetStatus? status;

  CallbackList<DATA> refreshCallbackList = CallbackList<DATA>();
  CallbackList<DATA> loadMoreCallbackList = CallbackList<DATA>();

  bool isRefreshing = false;
  bool isLoadMoreIng = false;
  bool showLoadingWidget = false;
  bool hasLoaded = false;
  final TaskHelper taskHelper = TaskHelper();

  void set({context, loadConfig, setStateCall}) {
    this.loadConfig = loadConfig;
    this.context = context;
    loadConfig.refreshAdapter.setOnRefreshListener(_refresh);
    loadConfig.refreshAdapter.setOnLoadMoreListener(_loadMore);
    this.setStateCall = setStateCall;
  }

  void rebuild() {
    if (status != WidgetStatus.loading) {
      setStateCall();
    }
  }

  ///refreshingType 用于控制是刷新控件header显示还是，statusWidget的loading显示。或者不显示
  void refresh({RefreshingType refreshingType = RefreshingType.auto}) {
    switch (refreshingType) {
      case RefreshingType.refresh_widget:
        loadConfig.refreshAdapter.requestRefresh();
        break;
      case RefreshingType.status_widget:
        _refresh(showLoadingWidget: true);
        break;
      case RefreshingType.auto:
        if (loadConfig.refreshAdapter.enableRefresh) {
          if (loadConfig.dataManager.isEmpty()) {
            _refresh(showLoadingWidget: true);
          } else {
            loadConfig.refreshAdapter.requestRefresh();
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
        loadConfig.refreshAdapter.requestLoadMore();
        break;
      case RefreshingType.status_widget:
        _loadMore(showLoadingWidget: true);
        break;
      case RefreshingType.auto:
        if (loadConfig.dataManager.isEmpty()) {
          _loadMore(showLoadingWidget: true);
        } else {
          loadConfig.refreshAdapter.requestLoadMore();
        }
        break;
      case RefreshingType.none:
        _loadMore(showLoadingWidget: false);
        break;
    }
  }

  Future<void> _refresh({bool showLoadingWidget = false}) {
    this.showLoadingWidget = showLoadingWidget;
    Completer completer = new Completer();

    taskHelper.cancelAll();
    isRefreshing = true;

    Callback<DATA> callback = Callback.build<DATA>(onStart: () {
      refreshCallbackList.onStart();
    }, onProgress: (int current, int total, [Object? progressData]) {
      refreshCallbackList.onProgress(current, total, progressData);
    }, onPostSuccess: (data) {
      hasLoaded = true;
      //通知更新数据
      if (data != null) {
        loadConfig.dataManager.notifyDataChange(true, data);
      }
      refreshCallbackList.onPostSuccess(data);
    }, onPostFail: (error) {
      if (!loadConfig.dataManager.isEmpty()) {
        loadConfig.dataDelegate.tipFailInfo(context, error!, refresh);
      }
      refreshCallbackList.onPostFail(error);
    }, onPostCancel: () {
      refreshCallbackList.onPostCancel();
    }, onPost: (ResultCode code, DATA? data, Object? error) {
      loadConfig.refreshAdapter.finishRefresh(context,
          code == ResultCode.success, error, !loadConfig.dataSource.hasMore());
      isRefreshing = false;
      completer.complete();
    });
    taskHelper.executeByFunction<DATA>(loadConfig.dataSource.refresh, callback);
    return completer.future;
  }

  Future<void> _loadMore({bool showLoadingWidget = false}) {
    this.showLoadingWidget = showLoadingWidget;
    Completer completer = new Completer();
    if (isLoading()) {
      loadConfig.refreshAdapter.finishLoadMore(
          context, true, null, !loadConfig.dataSource.hasMore());
      completer.complete();
      return completer.future;
    }
    if (!loadConfig.dataSource.hasMore()) {
      loadConfig.refreshAdapter.finishLoadMore(
          context, true, null, !loadConfig.dataSource.hasMore());
      completer.complete();
      return completer.future;
    }
    taskHelper.cancelAll();
    isLoadMoreIng = true;

    Callback<DATA> callback = Callback.build<DATA>(
      onStart: () {
        loadMoreCallbackList.onStart();
      },
      onProgress: (int current, int total, [Object? progressData]) {
        loadMoreCallbackList.onProgress(current, total, progressData);
      },
      onPostSuccess: (data) {
        loadConfig.dataManager.notifyDataChange(false, data);
        loadMoreCallbackList.onPostSuccess(data);
      },
      onPostFail: (error) {
        if (!loadConfig.dataManager.isEmpty()) {
          loadConfig.dataDelegate.tipFailInfo(context, error!, refresh);
        }
        loadMoreCallbackList.onPostFail(error);
      },
      onPostCancel: () {
        loadMoreCallbackList.onPostCancel();
      },
      onPost: (ResultCode code, DATA? data, Object? error) {
        loadConfig.refreshAdapter.finishLoadMore(
            context,
            code == ResultCode.success,
            error,
            !loadConfig.dataSource.hasMore());
        isLoadMoreIng = false;
        completer.complete();
      },
    );
    taskHelper.executeByFunction<DATA>(
        loadConfig.dataSource.loadMore, callback);
    return completer.future;
  }

  bool isUnload() {
    return !hasLoaded;
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
  final RefreshAdapter refreshAdapter;
  final bool firstNeedRefresh;

  LoadConfig(
      {required this.dataSource,
      required this.dataManager,
      required this.dataDelegate,
      this.refreshAdapter = const NoRefreshAdapter(),
      this.firstNeedRefresh = true});

  LoadConfig.task(
      {required Task<DATA> task,
      required this.dataManager,
      required this.dataDelegate,
      this.refreshAdapter = const NoRefreshAdapter(),
      this.firstNeedRefresh = true})
      : this.dataSource = DataSource.buildByTask(task);

  LoadConfig.future(
      {required Future<DATA> future,
      required this.dataManager,
      required this.dataDelegate,
      this.refreshAdapter = const NoRefreshAdapter(),
      this.firstNeedRefresh = true})
      : this.dataSource = DataSource.buildByTask(Task.buildByFuture(future));
}

typedef ConfigCreate<DATA> = LoadConfig<DATA> Function(
    BuildContext context, LoadConfig<DATA>? oldConfig);

typedef ShouldRecreate<DATA> = bool Function(
    BuildContext context, LoadConfig<DATA> config);
