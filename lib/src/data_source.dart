/*
    Author: Jayce
    createTime:2020-10
*/

import 'task.dart';

///数据源，用于加载列表数据
abstract class DataSource<DATA> {
  ///刷新 触发加载刷新的数据，一般用于加载下拉刷新加载第一页数据
  ///cancelHandle 借鉴于dio类库的设计, 外部通过cancelHandle.cancel()取消，里面则可以通过cancelHandle.isCanceled()判断，或者通过cancelHandle.interruptedWhenCanceled()当被取消是抛出取消异常终止方法执行
  ///progressCallback，可能为空使用前判空，用于通知外部进度
  ///Future<DATA> 返回数据的Future
  Future<DATA> refresh(CancelHandle cancelHandle,
      [ProgressCallback progressCallback]);

  ///加载更多 触发加载刷新的数据，一般用于列表加载下一页数据
  Future<DATA> loadMore(CancelHandle cancelHandle,
      [ProgressCallback progressCallback]);

  ///是否有更多数据，是否有下一页数据
  bool hasMore();

  static DataSource<DATA> buildByTask<DATA>(Task<DATA> task) {
    return _TaskDataSource<DATA>(task);
  }
}

class _TaskDataSource<DATA> implements DataSource<DATA> {
  Task<DATA> task;

  _TaskDataSource(this.task);

  @override
  bool hasMore() {
    return false;
  }

  @override
  Future<DATA> loadMore(CancelHandle cancelHandle, [progressCallback]) {
    return null;
  }

  @override
  Future<DATA> refresh(CancelHandle cancelHandle, [progressCallback]) {
    return task.execute(cancelHandle, progressCallback);
  }
}
