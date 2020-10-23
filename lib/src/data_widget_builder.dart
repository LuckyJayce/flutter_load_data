/*
    Author: Jayce
    createTime:2020-10
*/

import 'package:flutter/widgets.dart';

///数据加载成功显示的WidgetBuilder
abstract class DataWidgetBuilder<DATA> {
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

  static DataWidgetBuilder<DATA> simple<DATA>(
      Widget Function(BuildContext context, DATA data) builder) {
    return SimpleDataWidgetBuilder.simple<DATA>(builder);
  }
}

///只有刷新没有加载更多的DataWidgetBuilder
abstract class SimpleDataWidgetBuilder<DATA> extends DataWidgetBuilder<DATA> {
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

  static SimpleDataWidgetBuilder<DATA> simple<DATA>(
      Widget Function(BuildContext context, DATA data) builder) {
    return _SimpleDataWidgetBuilderF<DATA>(builder);
  }
}

class _SimpleDataWidgetBuilderF<DATA> extends SimpleDataWidgetBuilder<DATA> {
  Widget Function(BuildContext context, DATA data) builder;

  _SimpleDataWidgetBuilderF(this.builder);

  @override
  Widget build(BuildContext context) {
    return builder(context, getData());
  }
}
