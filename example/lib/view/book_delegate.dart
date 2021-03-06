import 'package:example/model/entity/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:load_data/load_data.dart';

class MyBookDataWidgetDelegate extends DataDelegate<List<Book>> {
  @override
  Widget build(BuildContext context, List<Book> data) {
    print('MyBookDataWidgetBuilder $data');
    //这里不一定是ListView 可以返回任意Widget，比如：
    // return Text('list:$list');
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, i) {
        print('ListView.builder itemBuilder:$i data:$data');
        Book book = data[i];
        return ListTile(
          title: Text(book.name),
          subtitle: Text(book.content),
        );
      },
    );
  }
}
