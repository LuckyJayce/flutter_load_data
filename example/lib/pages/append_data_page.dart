/*
    Author: Jayce
    createTime:2020-10
*/

import 'package:example/model/entity/book.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:load_data/load_data.dart';

import 'simple_refresh_page.dart';

class AppendDataRefreshPage extends StatelessWidget {
  final LoadController<List<Book>> controller = LoadController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BookList'),
      ),
      body: LoadDataWidget<List<Book>>(
        controller: controller,
        configCreate: (context, oldConfig) {
          return LoadConfig(
            dataSource: BookListDataSource(),
            dataManager: MyListDataManager(),
            dataDelegate: BookListDelegate(),
            refreshAdapter: PullToRefreshAdapter(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Text('add'),
        onPressed: () {
          MyListDataManager<Book> manager =
              controller.getDataManager() as MyListDataManager<Book>;
          manager
              .addTop(Book('1111', '${DateTime.now().millisecondsSinceEpoch}'));
          controller.rebuild();
        },
      ),
    );
  }
}

class MyListDataManager<E> extends DataManager<List<E>> {
  List<E> topList = [];
  List<E> result = [];

  void addTop(E e) {
    topList.insert(0, e);
    result.insert(0, e);
  }

  @override
  List<E> getData() {
    return result;
  }

  @override
  bool isEmpty() {
    return result.isEmpty;
  }

  @override
  void notifyDataChange(List<E> data, bool refresh) {
    if (refresh) {
      result.clear();
      result.addAll(topList);
    }
    this.result.addAll(data);
  }
}
