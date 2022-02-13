/*
    Author: Jayce
    createTime:2020-10
*/

import 'package:example/model/entity/book.dart';
import 'package:example/view/custom_footers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:load_data/load_data.dart';

class HorizontalListViewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BookList'),
      ),
      body: LoadDataWidget<List<Book>>(
        configCreate: (context, oldConfig) {
          return LoadConfig(
            dataSource: BookListDataSource(),
            dataManager: ListDataManager(),
            dataDelegate: BookListDelegate(),
            refreshAdapter: PullToRefreshAdapter(
                enableRefresh: false,
                footerBuilder: (context) => HListFooter()),
          );
        },
      ),
    );
  }
}

///获取列表数据
class BookListDataSource implements DataSource<List<Book>> {
  int page = 0;

  @override
  Future<List<Book>> refresh(CancelHandle cancelHandle, [progressCallback]) {
    return _load(0, cancelHandle, progressCallback);
  }

  @override
  Future<List<Book>> loadMore(CancelHandle cancelHandle, [progressCallback]) {
    return _load(page + 1, cancelHandle, progressCallback);
  }

  @override
  bool hasMore() {
    return page < 5;
  }

  Future<List<Book>> _load(int page, CancelHandle cancelHandle,
      [progressCallback]) async {
    await Future.delayed(Duration(seconds: 2));
    List<Book> list = List.generate(10,
        (index) => Book('book$page-$index', '${DateTime.now().toString()}'));
    this.page = page;
    return list;
  }
}

///显示列表数据
class BookListDelegate extends SimpleDataDelegate<List<Book>> {
  @override
  Widget buildDataWidget(BuildContext context, List<Book> list) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        Book book = list[index];
        return Container(
          width: 80,
          padding: EdgeInsets.all(4),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${book.name}'),
              Text('${book.content}'),
            ],
          ),
        );
      },
      separatorBuilder: (context, index) => Divider(),
      itemCount: list.length,
    );
  }
}
