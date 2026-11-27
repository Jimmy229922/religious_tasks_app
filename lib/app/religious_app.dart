import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../features/splash/screens/splash_screen.dart';
import '../core/theme/theme_provider.dart';
import '../features/radio/screens/radio_screen.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

class ReligiousApp extends StatefulWidget {
  const ReligiousApp({super.key});

  @override
  State<ReligiousApp> createState() => _ReligiousAppState();
}

class _ReligiousAppState extends State<ReligiousApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<dynamic>? _overlaySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToOverlay();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enableHighRefreshRate();
    });
  }

  Future<void> _enableHighRefreshRate() async {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Provider.of<ThemeProvider>(context, listen: false).refreshPrayerPhase();
      _enableHighRefreshRate();
    }
  }

  void _listenToOverlay() {
    _overlaySubscription =
        FlutterOverlayWindow.overlayListener.listen((event) async {
      if (event == "OPEN_RADIO") {
        try {
          const platform = MethodChannel('religious_tasks_app/native_adhan');
          await platform.invokeMethod('bringToForeground');
        } catch (_) {}

        if (!mounted) return;

        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const RadioScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overlaySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final hour = DateTime.now().hour;
    final lightSeed = themeProvider.getDynamicSeedColor(hour, isDark: false);
    final darkSeed = themeProvider.getDynamicSeedColor(hour, isDark: true);

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
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: lightSeed,
          brightness: Brightness.light,
          primary: lightSeed,
          secondary: const Color(0xFFE65100),
          surface: const Color(0xFFFFFFFF),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE2E8F0),
          thickness: 1,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF1F5F9),
          selectedColor: lightSeed,
          labelStyle: GoogleFonts.cairo(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
          secondaryLabelStyle: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF0F172A),
          contentTextStyle: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black87,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: themeProvider.useOledBlack
            ? const Color(0xFF000000)
            : const Color(0xFF0B131E),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: darkSeed,
          primary: darkSeed,
          secondary: const Color(0xFFFFB74D),
          surface: themeProvider.useOledBlack
              ? const Color(0xFF141414)
              : const Color(0xFF131D2B),
        ),
        cardTheme: CardThemeData(
          color: themeProvider.useOledBlack
              ? const Color(0xFF161616)
              : const Color(0xFF172231),
          surfaceTintColor: Colors.transparent,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: themeProvider.useOledBlack
              ? const Color(0xFF1E1E1E)
              : const Color(0xFF1A2636),
          surfaceTintColor: Colors.transparent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
      ),
      themeMode: themeProvider.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 800),
      themeAnimationCurve: Curves.easeInOut,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(themeProvider.textScaleFactor),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: SplashScreen(themeProvider: themeProvider),
    );
  }
}
