import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:load_data/load_data.dart';

import 'entity/book.dart';

class TestComputeTask extends Task<int> {
  @override
  Future<int> execute(CancelHandle cancelHandle, [progressCallback]) async {
    int sum = 0;

    // 测试进度
    for (int i = 0; i < 10; i++) {
      cancelHandle.interruptedWhenCanceled();
      if (progressCallback != null) {
        progressCallback(i, 10, 'CTask info $i');
      }
      sum += i;
      await Future.delayed(Duration(milliseconds: 100));
    }

    //执行后台线程任务
    int sum2 = await compute(doLongTimeWork, 100000);

    //一个task 可以通过这个方式组合多个task
    int num = await GetCodeTask().execute(cancelHandle);
    int num2 = await GetNumTask().execute(cancelHandle, (int current, int total,
        [Object progressData]) {
      print(
          'MyBookBackgroundTask2 progress current:$current progressData:$progressData');
      if (progressCallback != null) {
        progressCallback(99, 100, '正在执行GetNumTask..');
      }
    });

    //同时执行3个任务
    print('开始获取books');
    int currentTimeMillis = DateTime.now().millisecondsSinceEpoch;
    Future<Book> bookFuture = GetBookTask('book1').execute(cancelHandle);
    Future<Book> bookFuture2 = GetBookTask('book2').execute(cancelHandle);
    Future<Book> bookFuture3 = GetBookTask('book3').execute(cancelHandle);
    Book book1 = await bookFuture;
    Book book2 = await bookFuture2;
    Book book3 = await bookFuture3;

    print(
        'book1:$book1 book2:$book2  book3:$book3 耗时:${DateTime.now().millisecondsSinceEpoch - currentTimeMillis}毫秒');

    return sum2 + sum + num + num2;
  }

  static int doLongTimeWork(int n) {
    //这里可以处理耗时的任务
    int sum = 0;
    for (int a = 0; a < n; a++) {
      sum += a;
    }
    return sum;
  }
}

class GetCodeTask implements Task<int> {
  @override
  Future<int> execute(CancelHandle cancelHandle, [progressCallback]) async {
    await Future.delayed(Duration(milliseconds: 100));
    return 1000;
  }
}

class GetNumTask implements Task<int> {
  @override
  Future<int> execute(CancelHandle cancelHandle, [progressCallback]) async {
    for (int a = 0; a < 10; a++) {
      cancelHandle.interruptedWhenCanceled();
      if (progressCallback != null) {
        progressCallback(a, 10, 'GetNumTask load in');
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
    return math.Random().nextInt(10000);
  }
}

class GetBookTask implements Task<Book> {
  String name;

  GetBookTask(this.name);

  @override
  Future<Book> execute(CancelHandle cancelHandle, [progressCallback]) async {
    await Future.delayed(Duration(milliseconds: 1000));
    return Book(name, 'content ${DateTime.now().toString()}');
  }
}
