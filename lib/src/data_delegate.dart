/*
    Author: Jayce
    createTime:2020-10
*/

import 'package:flutter/widgets.dart';

///数据加载成功显示的WidgetBuilder
abstract class DataDelegate<DATA> {
  ///创建显示数据的Widget
  Widget build(BuildContext context, DATA data);

  static DataDelegate<DATA> builder<DATA>(
      Widget Function(BuildContext context, DATA data) function) {
    return _SimpleDataDelegateImp<DATA>(function);
  }
}

class _SimpleDataDelegateImp<DATA> extends DataDelegate<DATA> {
  Widget Function(BuildContext context, DATA data) function;

  _SimpleDataDelegateImp(this.function);

  @override
  Widget build(BuildContext context, DATA data) {
    return function(context, data);
  }
}

abstract class DataManager<DATA> {
  ///获取数据成功后 通过这个方法更新数据
  ///data DataSource或者task方法的数据，
  ///refresh 是否是通过DataSource refresh方法返回的，false 表示通过loadMore返回的数据
  void notifyDataChange(DATA data, bool refresh);

  ///是否为空，LoadDataWidget 获取数据成功后，通过这个判断通过StatusWidgetBuilder的empty还是显示DataWidgetBuilder的数据Widget
  bool isEmpty();

  ///提供外部最终的data
  DATA getData();
}

class SimpleDataManager<DATA> extends DataManager<DATA> {
  DATA data;

  @override
  DATA getData() {
    return data;
  }

  @override
  bool isEmpty() {
    return data == null;
  }

  @override
  void notifyDataChange(DATA data, bool refresh) {
    this.data = data;
  }
}

class ListDataManager<E> extends DataManager<List<E>> {
  List<E> list = [];

  @override
  List<E> getData() {
    return list;
  }

  @override
  bool isEmpty() {
    return list.isEmpty;
  }

  @override
  void notifyDataChange(List<E> data, bool refresh) {
    if (refresh) {
      this.list.clear();
    }
    this.list.addAll(data);
  }
}
