import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../features/splash/screens/splash_screen.dart';
import '../core/theme/theme_provider.dart';
import '../shared/services/updates/update_view_model.dart';
import '../features/radio/screens/radio_screen.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class ReligiousApp extends StatefulWidget {
  const ReligiousApp({super.key});

  @override
  State<ReligiousApp> createState() => _ReligiousAppState();
}

class _ReligiousAppState extends State<ReligiousApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _listenToOverlay();
  }

  void _listenToOverlay() {
    FlutterOverlayWindow.overlayListener.listen((event) async {
      if (event == "OPEN_RADIO") {
        try {
          const platform = MethodChannel('religious_tasks_app/native_adhan');
          await platform.invokeMethod('bringToForeground');
        } catch (_) {}

        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const RadioScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final hour = DateTime.now().hour;
    final seedColor = themeProvider.getDynamicSeedColor(hour);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: kAppName,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          primary: seedColor,
          secondary: const Color(0xFFE65100),
          surface: const Color(0xFFF5F5F5),
        ),
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000), // OLED Pure Black
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: seedColor,
          primary: seedColor,
          secondary: const Color(0xFFFFB74D),
          surface: const Color(0xFF000000), // OLED Pure Black
        ),
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
      ),
      themeMode: themeProvider.themeMode,
      home: SplashScreen(themeProvider: themeProvider),
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            const GlobalUpdateIndicator(),
          ],
        );
      },
    );
  }
}

class GlobalUpdateIndicator extends StatelessWidget {
  const GlobalUpdateIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateViewModel>(
      builder: (context, updateVM, _) {
        if (!updateVM.isDownloading && !updateVM.isDownloadFinished) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 100,
          left: 20,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                if (updateVM.isDownloadFinished) {
                  updateVM.startUpdate(); // This will trigger install if already downloaded
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("جاري التحميل: ${updateVM.downloadProgress.toInt()}%"),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26, blurRadius: 10, spreadRadius: 2)
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: updateVM.downloadProgress / 100,
                      backgroundColor: Colors.white24,
                      color: updateVM.isDownloadFinished ? Colors.green : Colors.tealAccent,
                      strokeWidth: 4,
                    ),
                    Icon(
                      updateVM.isDownloadFinished ? Icons.install_mobile : Icons.downloading,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
