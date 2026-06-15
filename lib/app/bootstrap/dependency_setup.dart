import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_provider.dart';
import '../../features/athkar/providers/athkar_view_model.dart';
import '../../features/tasbeeh/providers/tasbeeh_view_model.dart';
import '../../features/tasks/providers/tasks_view_model.dart';

Widget buildAppProviders({
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => AthkarViewModel()),
      ChangeNotifierProvider(create: (_) => TasksViewModel()),
      ChangeNotifierProvider(create: (_) => TasbeehViewModel()),
    ],
    child: child,
  );
}
