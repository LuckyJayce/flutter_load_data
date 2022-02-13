/*
    Author: Jayce
    createTime:2020-10
*/

import 'package:flutter/material.dart';

///数据加载成功显示的WidgetBuilder
abstract class DataDelegate<DATA> {
  void init() {}

  Widget buildUnLoadWidget(BuildContext context, DATA data,
      [VoidCallback? refreshToken]);

  Widget buildLoadingWidget(
      BuildContext context, int current, int total, Object? progressData);

  Widget buildFailWidget(BuildContext context, Object error,
      [VoidCallback? refreshToken]);

  void tipFailInfo(BuildContext context, Object error,
      [VoidCallback? refreshToken]);

  Widget buildEmptyWidget(BuildContext context, [VoidCallback? refreshToken]);

  ///创建显示数据的Widget
  Widget buildDataWidget(BuildContext context, DATA data);

  void dispose() {}
}

abstract class SimpleDataDelegate<DATA> extends DataDelegate<DATA> {
  Widget buildUnLoadWidget(BuildContext context, DATA data,
      [VoidCallback? refreshToken]) {
    return Container();
  }

  @override
  Widget buildFailWidget(BuildContext context, Object error,
      [VoidCallback? refreshToken]) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Color(0xFFDDDDDD)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('error:$error'),
          SizedBox(height: 24),
          _buildRefreshButton(refreshToken),
        ],
      ),
    );
  }

  @override
  Widget buildLoadingWidget(
      BuildContext context, int current, int total, Object? progressData) {
    String text;
    if (total > 0) {
      double progress = current * 100 / total;
      if (progressData != null) {
        text = '$progress% $progressData';
      } else {
        text = '$progress%';
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              backgroundColor: Colors.blueAccent.shade700,
            ),
            Container(
              height: 24,
            ),
            Text(text)
          ],
        ),
      );
    }
    return Center(
      child: CircularProgressIndicator(
        backgroundColor: Colors.blueAccent.shade700,
      ),
    );
  }

  @override
  Widget buildEmptyWidget(BuildContext context, [VoidCallback? refreshToken]) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Color(0xFFEEEEEE)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Empty'),
          SizedBox(height: 24),
          _buildRefreshButton(refreshToken),
        ],
      ),
    );
  }

  @override
  void tipFailInfo(BuildContext context, Object error,
      [VoidCallback? refreshToken]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('error$error'),
    ));
  }

  Widget _buildRefreshButton(VoidCallback? refreshToken) {
    return refreshToken == null
        ? Container()
        : Container(
            color: Colors.blue,
            height: 42,
            child: TextButton(
              child: Text(
                'refresh',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: refreshToken,
            ),
          );
  }

  static DataDelegate<DATA> builder<DATA>(
      Widget Function(BuildContext context, DATA data) function) {
    return _SimpleDataDelegateImp<DATA>(function);
  }
}

class _SimpleDataDelegateImp<DATA> extends SimpleDataDelegate<DATA> {
  Widget Function(BuildContext context, DATA data) function;

  _SimpleDataDelegateImp(this.function);

  @override
  Widget buildDataWidget(BuildContext context, DATA data) {
    return function(context, data);
  }
}

abstract class DataManager<DATA> {
  ///获取数据成功后 通过这个方法更新数据
  ///data DataSource或者task方法的数据，
  ///refresh 是否是通过DataSource refresh方法返回的，false 表示通过loadMore返回的数据
  void notifyDataChange(bool refresh, DATA data);

  bool isEmpty();

  ///提供外部最终的data
  DATA getData();
}

class RefreshDataManager<DATA> extends DataManager<DATA> {
  DATA data;
  bool Function(DATA data)? isEmptyFunc;

  RefreshDataManager(this.data, {this.isEmptyFunc});

  @override
  DATA getData() {
    return data;
  }

  @override
  void notifyDataChange(bool refresh, DATA data) {
    this.data = data;
  }

  @override
  bool isEmpty() {
    if (isEmptyFunc != null) {
      return isEmptyFunc!(data);
    }
    return data == null;
  }
}

class ListDataManager<E> extends DataManager<List<E>> {
  List<E> list = [];

  ListDataManager({List<E>? initData}) {
    if (initData != null) {
      list.addAll(initData);
    }
  }

  @override
  List<E> getData() {
    return list;
  }

  @override
  void notifyDataChange(bool refresh, List<E> data) {
    if (refresh) {
      this.list.clear();
    }
    this.list.addAll(data);
  }

  @override
  bool isEmpty() {
    return list.isEmpty;
  }
}
