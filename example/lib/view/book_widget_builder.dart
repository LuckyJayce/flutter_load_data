import 'package:example/model/entity/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:load_data/load_data.dart';

class MyBookDataWidgetDelegate implements DataWidgetDelegate<List<Book>> {
  List<Book> list = [];

  @override
  void notifyDataChange(List<Book> data, bool refresh) {
    if (refresh) {
      list.clear();
    }
    list.addAll(data);
  }

  @override
  bool isEmpty() {
    return list.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    print('MyBookDataWidgetBuilder $list');
    //这里不一定是ListView 可以返回任意Widget，比如：
    // return Text('list:$list');
    return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, i) {
          return ListTile(
            title: Text(list[i].name),
            subtitle: Text(list[i].content),
          );
        });
  }

  @override
  List<Book> getData() {
    return list;
  }
}
