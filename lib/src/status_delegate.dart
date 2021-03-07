/*
    Author: Jayce
    createTime:2020-10
*/

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

///状态布局widgetBuilder
abstract class StatusDelegate {
  Widget buildUnLoadWidget(BuildContext context, [VoidCallback? refreshToken]);

  /// 显示加载中
  Widget buildLoadingWidget(
      BuildContext context, int current, int total, Object? progressData);

  /// 显示加载失败
  /// @param error
  /// @param refreshToken 可以用于widget点击事件重新刷新
  Widget buildFailWidget(BuildContext context, Object error,
      [VoidCallback refreshToken]);

  /// 显示空数据布局
  /// @param refreshToken 可以用于widget点击事件重新刷新
  Widget buildEmptyWidget(BuildContext context, [VoidCallback? refreshToken]);

  /// 有数据的时候，toast提示失败
  /// @param error
  /// @param refreshToken 可以用于widget点击事件重新刷新
  void tipFail(BuildContext context, Object error,
      [VoidCallback? refreshToken]);
}

class SimpleStatusDelegate implements StatusDelegate {
  const SimpleStatusDelegate();

  @override
  Widget buildUnLoadWidget(BuildContext context, [VoidCallback? refreshToken]) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Color(0xFFEEEEEE)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('unload'),
          refreshToken == null
              ? Container()
              : TextButton(
                  child: Text('refresh'),
                  onPressed: refreshToken,
                )
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
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Color(0xFFEEEEEE)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Empty'),
          refreshToken == null
              ? Container()
              : TextButton(
                  child: Text('refresh'),
                  onPressed: refreshToken,
                )
        ],
      ),
    );
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
          refreshToken == null
              ? Container()
              : TextButton(
                  child: Text('refresh'),
                  onPressed: refreshToken,
                )
        ],
      ),
    );
  }

  @override
  void tipFail(BuildContext context, Object error,
      [VoidCallback? refreshToken]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('error$error'),
    ));
  }
}
