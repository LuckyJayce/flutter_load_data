/*
    Author: Jayce
    createTime:2020-10
*/

import 'package:example/model/entity/book.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:load_data/load_data.dart';

class LoadConfigRecreatePage extends StatefulWidget {
  @override
  _LoadConfigRecreatePageState createState() => _LoadConfigRecreatePageState();
}

class _LoadConfigRecreatePageState extends State<LoadConfigRecreatePage> {
  String name = 'ios';
  int i = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BookList'),
      ),
      body: LoadDataWidget<List<Book>>(
        configCreate: (context, oldConfig) {
          return LoadConfig(
            dataSource: BookListDataSource(name),
            dataManager: oldConfig?.dataManager ?? ListDataManager(),
            dataDelegate: oldConfig?.dataDelegate ?? BookListDelegate(),
            refreshAdapter: oldConfig?.refreshAdapter ?? PullToRefreshAdapter(),
          );
        },
        shouldRecreate: (context, config) {
          BookListDataSource bookListDataSource =
              config.dataSource as BookListDataSource;
          return bookListDataSource.name != name;
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            name = '[java ${i++}]';
          });
        },
        child: Text('update\nsource'),
      ),
    );
  }
}

///获取列表数据
class BookListDataSource implements DataSource<List<Book>> {
  int page = 0;
  String name;

  BookListDataSource(this.name);

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
    List<Book> list = List.generate(
        10,
        (index) => Book(
            'book$page-$index', '${DateTime.now().toString()} name:$name'));
    this.page = page;
    return list;
  }
}

///显示列表数据
class BookListDelegate extends DataDelegate<List<Book>> {
  @override
  Widget build(BuildContext context, List<Book> list) {
    return ListView.separated(
      itemBuilder: (context, index) {
        Book book = list[index];
        return ListTile(
          title: Text('${book.name}'),
          subtitle: Text('${book.content}'),
        );
      },
      separatorBuilder: (context, index) => Divider(),
      itemCount: list.length,
    );
  }
}
