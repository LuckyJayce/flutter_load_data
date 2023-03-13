import 'dart:async';

import 'package:flutter/material.dart';
import 'package:load_data/load_data.dart';

final _studentsKey = DatasourceProviderKey<List<Student>>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('home'),
      ),
      body: ListView(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return const DetailScreen();
              }));
            },
            child: const Text('111'),
          ),
        ],
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _studentsKey.provider(
      (context) => DataManager.list(GetStudentsDatasource()),
      builder: (context, child) {
        var notifier = _studentsKey.read(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail'),
            actions: [
              ElevatedButton(
                onPressed: notifier.refresh,
                child: const Text('refresh'),
              ),
              ElevatedButton(
                onPressed: notifier.loadMore,
                child: const Text('loadMore'),
              ),
              ElevatedButton(
                onPressed: () {
                  notifier.setData(true, [Student('set', 1)]);
                },
                child: Text('set'),
              )
            ],
          ),
          body: Column(
            children: [
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      notifier.setData(true, []);
                      notifier.datasource = GetStudentsDatasource();
                    },
                    child: const Text('normal'),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () {
                      notifier.datasource =
                          GetStudentsDatasource(isThrowError: true);
                    },
                    child: const Text('error'),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () {
                      notifier.setData(true, []);
                      notifier.datasource =
                          GetStudentsDatasource(isThrowError: true);
                    },
                    child: const Text('empty error'),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () {
                      notifier.setData(true, []);
                      notifier.datasource = GetStudentsDatasource(
                          isThrowError: false, isEmptyData: true);
                    },
                    child: const Text('empty data'),
                  ),
                ],
              ),
              Expanded(
                child: _studentsKey.buildRefresh(
                  // refreshDelegate: const PullToRefreshDelegate(
                  //   header: WaterDropHeader(),
                  //   enableLoadMore: false,
                  // ),
                  refreshDelegate: const FlutterRefreshDelegate(),
                  data: (data) {
                    if (data.isEmpty) {
                      return const Center(
                        child: Text('没有数据'),
                      );
                    }
                    return ListView.builder(
                      itemBuilder: (context, index) {
                        Student student = data[index];
                        return ListTile(
                          title: Text(student.name),
                        );
                      },
                      itemCount: data.length,
                    );
                  },
                  loading: StatusUtil.loading,
                  error: StatusUtil.error,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StatusUtil {
  static get loading => () {
        return const Center(
          child: CircularProgressIndicator(),
        );
      };

  static get error => (error) {
        return Center(
          child: Text('$error'),
        );
      };

  static get unload => () {
        return const Center(
          child: Text('unload'),
        );
      };
}

class GetStudentsDatasource extends Datasource<List<Student>> {
  int currentPage = 0;
  bool isThrowError;
  bool isEmptyData;

  GetStudentsDatasource({this.isThrowError = false, this.isEmptyData = false});

  @override
  bool hasMore() {
    return currentPage < 5;
  }

  @override
  FutureOr<List<Student>> load(bool refresh) async {
    await Future.delayed(const Duration(seconds: 2));
    if (isThrowError) {
      throw Exception('GetStudentsDatasource error');
    }
    if (isEmptyData) {
      return [];
    }
    print('GetStudentsDatasource load refresh:$refresh');
    int loadPage = refresh ? 0 : currentPage + 1;
    List<Student> students = [];
    for (int i = 0; i < 20; i++) {
      students.add(Student('$loadPage - $i', 11));
    }
    currentPage = loadPage;
    return students;
  }
}

class Student {
  String name;
  int age;

  Student(this.name, this.age);
}
