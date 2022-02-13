import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HListFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomFooter(builder: (BuildContext context, LoadStatus? mode) {
      if (mode == null) {
        return Container();
      }
      Widget widget;
      switch (mode) {
        case LoadStatus.idle:
          widget = Container();
          break;
        case LoadStatus.canLoading:
          widget = Container();
          break;
        case LoadStatus.loading:
          widget = Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            child: Container(
              child: CircularProgressIndicator(),
              width: 36,
              height: 36,
            ),
          );
          break;
        case LoadStatus.noMore:
          widget = Container();
          break;
        case LoadStatus.failed:
          widget = Center(
            child: Text('error'),
          );
          break;
      }
      return widget;
    });
  }
}
