import 'package:example/pages/append_data_page.dart';

import 'load_config_recreate_page.dart';
import 'no_refresh_page.dart';
import 'abstract_demos_page.dart';
import 'refresh_page.dart';
import 'simple_refresh_page.dart';

class HomePage extends AbstractDemosPage {
  HomePage()
      : super('HomePage', {
          '/SimpleRefreshPage': (context) => SimpleRefreshPage(),
          '/pull_to_refresh_widget with dataSource': (context) => RefreshPage(
              RefreshWidgetType.pull_to_refresh, SourceType.data_source),
          '/pull_to_refresh_widget with task': (context) =>
              RefreshPage(RefreshWidgetType.pull_to_refresh, SourceType.task),
          '/easy_refresh_widget with dataSource': (context) => RefreshPage(
              RefreshWidgetType.easy_refresh, SourceType.data_source),
          '/easy_refresh_widget with task': (context) =>
              RefreshPage(RefreshWidgetType.easy_refresh, SourceType.task),
          '/no refresh widget': (context) => NoRefreshPage(),
          '/LoadConfigRecreatePage': (context) => LoadConfigRecreatePage(),
          '/AppendDataRefreshPage': (context) => AppendDataRefreshPage(),
        });
}
