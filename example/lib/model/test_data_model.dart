import 'package:flutter/widgets.dart';

enum TestData {
  error,
  empty,
  normal,
}

class TestDataModel extends ChangeNotifier {
  TestData data = TestData.normal;

  void setData(TestData data) {
    this.data = data;
    notifyListeners();
  }
}
