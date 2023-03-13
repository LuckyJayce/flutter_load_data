import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../load_data.dart';

abstract class Datasource<DATA> {
  FutureOr<DATA> load(bool refresh);

  bool hasMore();
}

abstract class DataManager<DATA> {
  Datasource<DATA> datasource;

  DataManager(this.datasource);

  void setData(bool refresh, DATA loadData);

  bool isEmpty();

  DATA getData();

  static DataManager<List<E>> list<E>(Datasource<List<E>> datasource,
      {List<E>? initData}) {
    return ListDataManager(datasource, initData: initData);
  }

  static DataManager refresh<DATA>(Datasource<DATA> datasource,
      {required DATA initData, bool Function(DATA? data)? isEmptyFunc}) {
    return RefreshDataManager<DATA>(
      datasource,
      initData: initData,
      isEmptyFunc: isEmptyFunc,
    );
  }
}

class RefreshDataManager<DATA> extends DataManager<DATA> {
  DATA _data;
  bool Function(DATA? data)? isEmptyFunc;

  RefreshDataManager(Datasource<DATA> datasource,
      {required DATA initData, this.isEmptyFunc})
      : _data = initData,
        super(datasource);

  @override
  DATA getData() {
    return _data;
  }

  @override
  void setData(bool refresh, DATA loadData) {
    this._data = loadData;
  }

  @override
  bool isEmpty() {
    if (isEmptyFunc != null) {
      return isEmptyFunc!(_data);
    }
    return _data == null;
  }
}

class ListDataManager<E> extends DataManager<List<E>> {
  final List<E> _list = [];

  ListDataManager(Datasource<List<E>> datasource, {List<E>? initData})
      : super(datasource) {
    if (initData != null) {
      _list.addAll(initData);
    }
  }

  @override
  List<E> getData() {
    return _list;
  }

  @override
  void setData(bool refresh, List<E> loadData) {
    if (refresh) {
      _list.clear();
    }
    _list.addAll(loadData);
  }

  @override
  bool isEmpty() {
    return _list.isEmpty;
  }
}

class DatasourceProviderKey<DATA> {
  ChangeNotifierProvider<DatasourceNotifier<DATA>> provider(
      DataManager<DATA> Function(BuildContext context) create,
      {TransitionBuilder? builder,
      Widget? child}) {
    return ChangeNotifierProvider<DatasourceNotifier<DATA>>(
      builder: builder,
      child: child,
      create: (BuildContext context) {
        var notifier = DatasourceNotifier<DATA>(
          create(context),
        );
        notifier.refresh();
        return notifier;
      },
    );
  }

  Widget when({
    required Widget Function()? loading,
    required Widget Function(Object error) error,
    required Widget Function(DATA data) data,
  }) {
    return Consumer<DatasourceNotifier<DATA>>(
      builder: (context, notifier, child) {
        if (notifier.isRefreshing()) {
          return loading == null ? const SizedBox() : loading();
        }
        if (notifier.data == null && notifier.error != null) {
          return error(notifier.error!);
        }
        return data(notifier.data);
      },
    );
  }

  Widget consumer(
      Widget Function(
    BuildContext context,
    DatasourceNotifier<DATA> notifier,
    Widget? child,
  )
          builder) {
    return Consumer<DatasourceNotifier<DATA>>(
      builder: builder,
    );
  }

  DatasourceNotifier<DATA> read(BuildContext context) {
    return Provider.of<DatasourceNotifier<DATA>>(context, listen: false);
  }

  DatasourceNotifier<DATA> watch(BuildContext context) {
    return Provider.of<DatasourceNotifier<DATA>>(context, listen: true);
  }

  static DatasourceNotifier<DATA> staticRead<DATA>(BuildContext context) {
    return Provider.of<DatasourceNotifier<DATA>>(context, listen: false);
  }

  static DatasourceNotifier<DATA> staticWatch<DATA>(BuildContext context) {
    return Provider.of<DatasourceNotifier<DATA>>(context, listen: true);
  }
}

class DatasourceNotifier<DATA> extends ChangeNotifier with TaskMixin {
  Object? _error;
  bool _isRefreshing = false;
  bool _isLoadMoreIng = false;
  int? _lastStartRefreshTime;
  int? _lastEndRefreshTime;
  int? _lastStartLoadMoreTime;
  int? _lastEndLoadMoreTime;
  LoadingType _loadingType = LoadingType.auto;
  final DataManager<DATA> _dataManager;
  final SimpleCallbacksProxy<DATA> refreshCallbacks;
  final SimpleCallbacksProxy<DATA> loadMoreCallbacks;

  DatasourceNotifier(DataManager<DATA> dataManager)
      : refreshCallbacks = SimpleCallbacksProxy(),
        loadMoreCallbacks = SimpleCallbacksProxy(),
        _dataManager = dataManager {
    refreshCallbacks.addCallback(SimpleCallback.build<DATA>(
      start: () {
        _lastStartRefreshTime = _currentTime();
        _isRefreshing = true;
        notifyListeners();
      },
      failed: (e) {
        _lastEndRefreshTime = _currentTime();
        _isRefreshing = false;
        _error = e;
        notifyListeners();
      },
      success: (data) {
        _lastEndRefreshTime = _currentTime();
        _isRefreshing = false;
        dataManager.setData(true, data);
        _error = null;
        notifyListeners();
      },
    ));
    loadMoreCallbacks.addCallback(SimpleCallback.build<DATA>(
      start: () {
        _lastStartLoadMoreTime = _currentTime();
        _isLoadMoreIng = true;
        notifyListeners();
      },
      failed: (e) {
        _lastEndLoadMoreTime = _currentTime();
        _isLoadMoreIng = false;
        _error = e;
        notifyListeners();
      },
      success: (data) {
        _lastEndLoadMoreTime = _currentTime();
        _isLoadMoreIng = false;
        dataManager.setData(false, data);
        _error = null;
        notifyListeners();
      },
    ));
  }

  bool isLoading() {
    return _isRefreshing || _isLoadMoreIng;
  }

  bool isRefreshing() => _isRefreshing;

  bool isLoadMoreIng() => _isLoadMoreIng;

  int? get lastStartRefreshTime => _lastStartRefreshTime;

  int? get lastEndRefreshTime => _lastEndRefreshTime;

  int? get lastStartLoadMoreTime => _lastStartLoadMoreTime;

  int? get lastEndLoadMoreTime => _lastEndLoadMoreTime;

  LoadingType get loadingType => _loadingType;

  void addRefreshCallback(SimpleCallback<DATA> callback) {
    refreshCallbacks.addCallback(callback);
  }

  void removeRefreshCallback(SimpleCallback<DATA> callback) {
    refreshCallbacks.removeCallback(callback);
  }

  void addLoadMoreCallback(SimpleCallback<DATA> callback) {
    loadMoreCallbacks.addCallback(callback);
  }

  void removeLoadMoreCallback(SimpleCallback<DATA> callback) {
    loadMoreCallbacks.removeCallback(callback);
  }

  Future<void> refresh({LoadingType loadingType = LoadingType.auto}) async {
    _loadingType = loadingType;
    await taskHelper.execute(
      SimpleTask.build<DATA>(() => _dataManager.datasource.load(true)),
      refreshCallbacks,
    );
  }

  Future<void> loadMore({LoadingType loadingType = LoadingType.auto}) async {
    if (isLoading()) {
      return;
    }
    if (!datasource.hasMore()) {
      return;
    }
    _loadingType = loadingType;
    await taskHelper.execute(
      SimpleTask.build<DATA>(() => _dataManager.datasource.load(false)),
      loadMoreCallbacks,
    );
  }

  int _currentTime() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  DATA get data => _dataManager.getData();

  bool get isEmpty => _dataManager.isEmpty();

  bool get isNotEmpty => !isEmpty;

  Datasource<DATA> get datasource => _dataManager.datasource;

  set datasource(Datasource<DATA> datasource) {
    taskHelper.unsubscribeAll();
    _dataManager.datasource = datasource;
    refresh();
  }

  Object? get error => _error;

  void setData(bool refresh, DATA data) {
    _dataManager.setData(refresh, data);
    notifyListeners();
  }
}

///refresh_widget 刷新控件header显示
///status_widget loading方式显示
///自动判断显示方式
///不显示loading状态
enum LoadingType { refreshWidget, statusWidget, auto, none }
