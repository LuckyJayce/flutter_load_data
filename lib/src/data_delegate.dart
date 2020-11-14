/*
    Author: Jayce
    createTime:2020-10
*/

import 'package:flutter/widgets.dart';

///数据加载成功显示的WidgetBuilder
abstract class DataDelegate<DATA> {
  ///获取数据成功后 通过这个方法更新数据
  ///data DataSource或者task方法的数据，
  ///refresh 是否是通过DataSource refresh方法返回的，false 表示通过loadMore返回的数据
  void notifyDataChange(DATA data, bool refresh);

  ///创建显示数据的Widget
  Widget build(BuildContext context);

  ///是否为空，LoadDataWidget 获取数据成功后，通过这个判断通过StatusWidgetBuilder的empty还是显示DataWidgetBuilder的数据Widget
  bool isEmpty();

  ///提供外部最终的data
  DATA getData();

  static DataDelegate<DATA> simple<DATA>(
      Widget Function(BuildContext context, DATA data) builder) {
    return SimpleDataDelegate.simple<DATA>(builder);
  }
}

///只有刷新没有加载更多的DataWidgetBuilder
abstract class SimpleDataDelegate<DATA> extends DataDelegate<DATA> {
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
  void notifyDataChange(data, bool refresh) {
    this.data = data;
  }

  static SimpleDataDelegate<DATA> simple<DATA>(
      Widget Function(BuildContext context, DATA data) builder) {
    return _SimpleDataWidgetDelegateF<DATA>(builder);
  }
}

class _SimpleDataWidgetDelegateF<DATA> extends SimpleDataDelegate<DATA> {
  Widget Function(BuildContext context, DATA data) builder;

  _SimpleDataWidgetDelegateF(this.builder);

  @override
  Widget build(BuildContext context) {
    return builder(context, getData());
  }
}
