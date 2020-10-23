import 'package:example/model/test_data_model.dart';
import 'package:flutter/widgets.dart';
import 'package:load_data/load_data.dart';
import 'package:provider/provider.dart';

import 'entity/book.dart';

class BookTask implements Task<Book> {
  BuildContext context;

  BookTask(this.context);

  @override
  Future<Book> execute(CancelHandle cancelHandle, [progressCallback]) async {
    TestDataModel testDataModel =
        Provider.of<TestDataModel>(context, listen: false);
    switch (testDataModel.data) {
      case TestData.error:
        throw Exception('test exception 11111');
        break;
      case TestData.normal:
      default:
        print('BookTask execute pre');
        for (int i = 0; i < 10; i++) {
          cancelHandle.interruptedWhenCanceled();
          await Future.delayed(Duration(milliseconds: 500));
          if (progressCallback != null) {
            progressCallback(i, 10);
          }
        }
        print('BookTask execute');
        return Book('book', '${DateTime.now().toString()}');
        break;
    }
  }
}
