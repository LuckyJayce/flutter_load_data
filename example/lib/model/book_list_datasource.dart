import 'package:flutter/widgets.dart';
import 'package:load_data/load_data.dart';
import 'package:provider/provider.dart';

import 'entity/book.dart';
import 'test_data_model.dart';

class MyBookListDataSource implements DataSource<List<Book>> {
  int page = 0;
  BuildContext context;

  MyBookListDataSource(this.context);

  @override
  bool hasMore() {
    return page < 3;
  }

  Future<List<Book>> load(int page, CancelHandle cancelHandle,
      [progressCallback]) async {
    TestDataModel testDataModel =
        Provider.of<TestDataModel>(context, listen: false);

    //模拟progress
    for (int a = 0; a < 10; a++) {
      //判断是否取消，取消这里抛出异常
      cancelHandle.interruptedWhenCanceled();
      //通知progress
      if (progressCallback != null) {
        progressCallback(a, 10, 'test data:$a');
      }
      //延时200毫秒
      await Future.delayed(Duration(milliseconds: 100));
    }

    switch (testDataModel.data) {
      case TestData.error:
        return Future.delayed(
            Duration(seconds: 1), throw Exception('test error 1111111111'));
        break;
      case TestData.empty:
        this.page = page;
        return [];
        break;
      case TestData.normal:
      default:
        List<Book> books = [];
        for (int a = 0; a < 10; a++) {
          books.add(
              Book('name:$page-$a', 'dataSource content:${DateTime.now()}'));
        }
        this.page = page;
        return books;
        break;
    }
  }

  @override
  Future<List<Book>> loadMore(CancelHandle cancelHandle, [progressCallback]) {
    print('loadMore page:${page + 1}');
    return load(page + 1, cancelHandle, progressCallback);
  }

  @override
  Future<List<Book>> refresh(CancelHandle cancelHandle, [progressCallback]) {
    print('refresh page:0');
    return load(0, cancelHandle, progressCallback);
  }
}
