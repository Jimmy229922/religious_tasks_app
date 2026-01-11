import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/religious_app.dart';
import 'services/notifications_service.dart';
import 'services/storage_service.dart';
import 'providers/theme_provider.dart';
import 'providers/athkar_view_model.dart';
import 'providers/tasks_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await initializeDateFormatting('ar', null);
  HijriCalendar.setLocal('ar');
  await NotificationManager().init();
  await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AthkarViewModel()),
        ChangeNotifierProvider(create: (_) => TasksViewModel()),
      ],
      child: const ReligiousApp(),
    ),
  );
}
