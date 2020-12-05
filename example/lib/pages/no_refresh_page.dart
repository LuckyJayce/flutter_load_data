import 'package:example/model/test_compute_task.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:load_data/load_data.dart';

//演示没有下拉刷新，并且非list的demo
class NoRefreshPage extends StatelessWidget {
  final LoadController<int> controller = LoadController<int>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NoRefreshPage'),
      ),
      body: Column(
        children: [
          FlatButton(
              color: Colors.blue,
              onPressed: () {
                controller.refresh();
              },
              child: Text('执行')),
          FlatButton(
              color: Colors.blue,
              onPressed: () {
                controller.cancel();
              },
              child: Text('cancel')),
          Expanded(
            child: LoadDataWidget<int>(
              controller: controller,
              configCreate: (context, oldConfig) {
                return LoadConfig<int>(
                  dataSource: DataSource.buildByTask(TestComputeTask()),
                  dataDelegate: TestComputeDelegate(),
                  dataManager: SimpleDataManager(),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class TestComputeDelegate extends DataDelegate<int> {
  @override
  Widget build(BuildContext context, int data) {
    return Center(
      child: Text('$data'),
    );
  }
}
