import 'package:example/model/book_list_datasource.dart';
import 'package:example/model/book_list_task.dart';
import 'package:example/model/entity/book.dart';
import 'package:example/model/test_data_model.dart';
import 'package:example/view/book_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:load_data/load_data.dart';
import 'package:provider/provider.dart';

enum RefreshWidgetType { pull_to_refresh, easy_refresh }
enum SourceType { data_source, task }

class RefreshPage extends StatelessWidget {
  final RefreshWidgetType refreshType;
  final SourceType sourceType;
  final LoadController<List<Book>> controller = LoadController();
  final RefreshAdapter refreshAdapter;

  RefreshPage(this.refreshType, this.sourceType)
      : refreshAdapter = refreshType == RefreshWidgetType.pull_to_refresh
            ? PullToRefreshAdapter(enableLoadMore: true, enableRefresh: true)
            : EasyRefreshAdapter(enableLoadMore: true, enableRefresh: true) {
    //测试添加回调并打印
    controller.addRefreshCallback(Callback.build<List<Book>>(onStart: () {
      print('onPreExecute');
    }, onProgress: (current, total, [progressData]) {
      print(
          'onProgressCallback current:$current total:$total progressData:$progressData');
    }, onEnd: (ResultCode code, List<Book> data, Object error) {
      print('onEndCallback code:$code data:$data error:$error');
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(refreshAdapter.runtimeType.toString()),
        actions: <Widget>[
          new IconButton(
            // action button
            icon: new Icon(Icons.refresh),
            onPressed: () {
              controller.refresh();
              // 可以控制loading是通过refresh控件显示还是 StatusWidgetBuilder显示
              // controller.refresh(refreshingType: RefreshingType.refresh_widget);
            },
          ),
          new IconButton(
            // action button
            icon: new Icon(Icons.more_rounded),
            onPressed: () {
              controller.loadMore();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Text('设置加载数据的状态'),
          Consumer<TestDataModel>(builder: (context, dataModel, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FlatButton(
                    color: dataModel.data == TestData.normal
                        ? Colors.blue
                        : Colors.lightBlueAccent,
                    onPressed: () {
                      dataModel.setData(TestData.normal);
                    },
                    child: Text('normal')),
                FlatButton(
                    color: dataModel.data == TestData.empty
                        ? Colors.blue
                        : Colors.lightBlueAccent,
                    onPressed: () {
                      dataModel.setData(TestData.empty);
                    },
                    child: Text('empty')),
                FlatButton(
                    color: dataModel.data == TestData.error
                        ? Colors.blue
                        : Colors.lightBlueAccent,
                    onPressed: () {
                      dataModel.setData(TestData.error);
                    },
                    child: Text('error')),
              ],
            );
          }),
          Divider(height: 1),
          Expanded(
              child: sourceType == SourceType.data_source
                  ? buildByDataSource(context)
                  : buildByTask(context)),
        ],
      ),
    );
  }

  Widget buildByTask(BuildContext context) {
    return LoadDataWidget<List<Book>>(
      controller: controller,
      configCreate: (context, oldConfig) {
        return LoadConfig(
          dataSource: DataSource.buildByTask(MyBookListTask(context)),
          dataDelegate: MyBookDataWidgetDelegate(),
          dataManager: ListDataManager(),
          refreshAdapter: refreshAdapter,
          firstNeedRefresh: true,
        );
      },
    );
  }

  Widget buildByDataSource(BuildContext context) {
    return LoadDataWidget<List<Book>>(
      controller: controller,
      configCreate: (context, oldConfig) {
        return LoadConfig(
          dataSource: MyBookListDataSource(context),
          dataDelegate: MyBookDataWidgetDelegate(),
          dataManager: ListDataManager(),
          refreshAdapter: refreshAdapter,
          firstNeedRefresh: true,
        );
      },
    );
  }
}
