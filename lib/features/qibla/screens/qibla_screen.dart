import 'dart:async';
import 'dart:math' as math;

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:religious_tasks_app/core/services/location_service.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/qibla/services/qibla_geodesic_service.dart';
import 'package:religious_tasks_app/features/qibla/widgets/qibla_interactive_map.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';

class QiblaMath {
  static double normalizeAngle(double angle) =>
      QiblaGeodesicService.normalizeAngle(angle);

  static double shortestSignedDelta(double fromDeg, double toDeg) =>
      QiblaGeodesicService.shortestSignedDelta(fromDeg, toDeg);

  static bool isAligned(double signedDiffDeg, {double toleranceDeg = 4.0}) =>
      QiblaGeodesicService.isAligned(signedDiffDeg, toleranceDeg: toleranceDeg);
}

enum _CompassAccuracyLevel { high, medium, low, unknown }

class QiblaScreen extends StatefulWidget {
  final Coordinates coordinates;
  const QiblaScreen({super.key, required this.coordinates});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with WidgetsBindingObserver {
  Color get _emerald => context.primaryColor;
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldLight = Color(0xFFFDE68A);
  static const double _alignmentToleranceDeg = 4.0;

  static const EventChannel _nativeSensorChannel =
      EventChannel('religious_tasks_app/qibla_sensor');
  static const MethodChannel _nativeControlChannel =
      MethodChannel('religious_tasks_app/qibla_control');

  double? _smoothedHeading;
  double? _continuousHeading;
  double? _fallbackAccuracy;
  int? _nativeAccuracyStatus;
  double? _declinationDeg;
  double? _magneticFieldUt;
  bool _magneticInterference = false;
  bool _isFlat = true;
  bool _wasAligned = false;
  bool _sensorUnavailable = false;
  bool _isRefreshingLocation = false;
  DateTime? _lastHeadingUiUpdate;
  bool _isInitialLoading = true;
  int _validHeadingSamples = 0;
  double? _locationAccuracyMeters;

  late Coordinates _activeCoordinates;
  String? _locationName;

  StreamSubscription<dynamic>? _nativeSubscription;
  StreamSubscription<CompassEvent>? _fallbackSubscription;
  Timer? _sensorTimeout;
  Timer? _initialLoadTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeCoordinates = widget.coordinates;
    _syncLocationFromViewModel();
    _pushLocationToNativeSensor();
    _startCompassListening();
    _initialLoadTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _isInitialLoading) {
        setState(() => _isInitialLoading = false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshGpsLocation();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopCompassListening();
    } else if (state == AppLifecycleState.resumed) {
      _pushLocationToNativeSensor();
      _startCompassListening();
    }
  }

  void _syncLocationFromViewModel() {
    try {
      final vm = Provider.of<TasksViewModel>(context, listen: false);
      final vmCoords = vm.prayerTimes?.coordinates;
      if (vmCoords != null) {
        _activeCoordinates = vmCoords;
      }
      _locationName = vm.locationName;
    } catch (_) {}
  }

  Future<void> _pushLocationToNativeSensor() async {
    try {
      await _nativeControlChannel.invokeMethod<void>('setLocation', {
        'latitude': _activeCoordinates.latitude,
        'longitude': _activeCoordinates.longitude,
        'altitude': 0.0,
      });
    } catch (_) {}
  }

  Future<void> _refreshGpsLocation() async {
    if (_isRefreshingLocation) return;
    setState(() => _isRefreshingLocation = true);

    try {
      final res = await LocationService().getHighAccuracyPosition(
        requestPermission: true,
      );
      if (!mounted) return;
      if (res.position != null) {
        final pos = res.position!;
        final coords = Coordinates(pos.latitude, pos.longitude);
        final name = await LocationService().getLocationName(pos);
        if (!mounted) return;
        setState(() {
          _activeCoordinates = coords;
          _locationName = name;
          _locationAccuracyMeters = pos.accuracy;
        });
        await _pushLocationToNativeSensor();
      } else {
        try {
          final vm = Provider.of<TasksViewModel>(context, listen: false);
          await vm.refreshLocation();
          if (!mounted) return;
          setState(() {
            if (vm.prayerTimes?.coordinates != null) {
              _activeCoordinates = vm.prayerTimes!.coordinates;
            }
            _locationName = vm.locationName;
          });
          await _pushLocationToNativeSensor();
        } catch (_) {}
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshingLocation = false);
        _checkInitialLoadComplete();
      }
    }
  }

  void _startCompassListening() {
    _stopCompassListening();
    _sensorTimeout = Timer(const Duration(seconds: 4), () {
      if (mounted && _smoothedHeading == null) {
        _startFallbackCompass();
      }
    });

    try {
      _nativeSubscription = _nativeSensorChannel.receiveBroadcastStream().listen(
        (dynamic data) {
          if (!mounted || data is! Map) return;
          final trueHeading = (data['trueHeading'] as num?)?.toDouble();
          if (trueHeading == null || trueHeading.isNaN) return;

          _sensorTimeout?.cancel();
          _nativeAccuracyStatus = (data['accuracyStatus'] as num?)?.toInt();
          _declinationDeg = (data['declination'] as num?)?.toDouble();
          _magneticFieldUt = (data['magneticFieldUt'] as num?)?.toDouble();
          _magneticInterference = data['magneticInterference'] == true;
          _isFlat = data['isFlat'] != false;

          _processHeadingSample(trueHeading);
        },
        onError: (_) {
          if (mounted) {
            _sensorTimeout?.cancel();
            _startFallbackCompass();
          }
        },
      );
    } catch (_) {
      _startFallbackCompass();
    }
  }

  void _startFallbackCompass() {
    _fallbackSubscription?.cancel();
    final events = FlutterCompass.events;
    if (events == null) {
      if (mounted) {
        setState(() => _sensorUnavailable = true);
        _checkInitialLoadComplete();
      }
      return;
    }

    _sensorTimeout = Timer(const Duration(seconds: 5), () {
      if (mounted && _smoothedHeading == null) {
        setState(() => _sensorUnavailable = true);
        _checkInitialLoadComplete();
      }
    });

    _fallbackSubscription = events.listen(
      (event) {
        if (!mounted) return;
        final rawHeading = event.heading;
        if (rawHeading == null || rawHeading.isNaN) return;

        _sensorTimeout?.cancel();
        _fallbackAccuracy = event.accuracy;
        _processHeadingSample(rawHeading);
      },
      onError: (_) {
        if (mounted) setState(() => _sensorUnavailable = true);
      },
    );
  }

  void _stopCompassListening() {
    _sensorTimeout?.cancel();
    _nativeSubscription?.cancel();
    _nativeSubscription = null;
    _fallbackSubscription?.cancel();
    _fallbackSubscription = null;
  }

  void _processHeadingSample(double rawHeading) {
    final normalized = QiblaGeodesicService.normalizeAngle(rawHeading);

    double nextSmoothed;
    double nextContinuous;

    if (_smoothedHeading == null || _continuousHeading == null) {
      nextSmoothed = normalized;
      nextContinuous = normalized;
    } else {
      final delta =
          QiblaGeodesicService.shortestSignedDelta(_smoothedHeading!, normalized);
      if (delta.abs() < 0.25) {
        return;
      }
      final alpha = delta.abs() > 25.0 ? 0.35 : 0.20;
      final step = delta * alpha;
      nextSmoothed = QiblaGeodesicService.normalizeAngle(_smoothedHeading! + step);
      nextContinuous = _continuousHeading! + step;
    }

    final qiblaResult = QiblaGeodesicService.calculate(
      _activeCoordinates.latitude,
      _activeCoordinates.longitude,
    );
    final diff = QiblaGeodesicService.shortestSignedDelta(
      nextSmoothed,
      qiblaResult.bearingDeg,
    );
    final reliability = _isHeadingReliable(nextSmoothed);
    final aligned = reliability &&
        QiblaGeodesicService.isAligned(
          diff,
          toleranceDeg: _alignmentToleranceDeg,
        );

    if (aligned && !_wasAligned) {
      HapticFeedback.mediumImpact();
    }
    _wasAligned = aligned;

    _validHeadingSamples++;
    final now = DateTime.now();
    if (_smoothedHeading != null &&
        _lastHeadingUiUpdate != null &&
        now.difference(_lastHeadingUiUpdate!).inMilliseconds < 40) {
      _smoothedHeading = nextSmoothed;
      _continuousHeading = nextContinuous;
      return;
    }
    _lastHeadingUiUpdate = now;
    setState(() {
      _smoothedHeading = nextSmoothed;
      _continuousHeading = nextContinuous;
      _sensorUnavailable = false;
    });
    _checkInitialLoadComplete();
  }

  void _checkInitialLoadComplete() {
    if (!_isInitialLoading || !mounted) return;
    final sensorReady = _validHeadingSamples >= 3 || _sensorUnavailable;
    if (!_isRefreshingLocation && sensorReady) {
      _initialLoadTimer?.cancel();
      setState(() => _isInitialLoading = false);
    }
  }

  _CompassAccuracyLevel _getAccuracyLevel() {
    if (_nativeAccuracyStatus != null) {
      return switch (_nativeAccuracyStatus) {
        3 => _CompassAccuracyLevel.high,
        2 => _CompassAccuracyLevel.medium,
        1 || 0 => _CompassAccuracyLevel.low,
        _ => _CompassAccuracyLevel.unknown,
      };
    }
    final acc = _fallbackAccuracy;
    if (acc == null || acc < 0) return _CompassAccuracyLevel.unknown;
    if (acc <= 18) return _CompassAccuracyLevel.high;
    if (acc <= 35) return _CompassAccuracyLevel.medium;
    return _CompassAccuracyLevel.low;
  }

  bool _isHeadingReliable(double? heading) {
    if (heading == null || _sensorUnavailable || _magneticInterference || !_isFlat) {
      return false;
    }
    final acc = _getAccuracyLevel();
    return acc == _CompassAccuracyLevel.high ||
        acc == _CompassAccuracyLevel.medium;
  }

  bool _isUsingFallbackMeccaCoords() {
    final latDiff = (_activeCoordinates.latitude - 21.4225).abs();
    final lngDiff = (_activeCoordinates.longitude - 39.8262).abs();
    return latDiff < 0.002 && lngDiff < 0.002;
  }

  String _getCompassStatusText(_CompassAccuracyLevel acc, double? heading) {
    if (_isRefreshingLocation) return 'جاري تحديد الموقع';
    if (_sensorUnavailable) return 'تعذر تحديد اتجاه الهاتف بدقة';
    if (_magneticInterference) return 'يوجد تشويش مغناطيسي محتمل';
    if (heading == null) return 'جاري تحديد الموقع';
    if (acc == _CompassAccuracyLevel.low ||
        acc == _CompassAccuracyLevel.unknown) {
      return 'يرجى معايرة البوصلة';
    }
    return 'جاهز لتحديد القبلة';
  }

  void _showCalibrationGuideDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? context.appHeaderBg : const Color(0xFFFFFDF8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: _gold.withValues(alpha: 0.6)),
          ),
          title: Row(
            children: [
              Icon(Icons.explore_rounded, color: isDark ? _goldLight : _emerald),
              const SizedBox(width: 8),
              Text(
                "طريقة استخدام ومعايرة البوصلة",
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.5,
                  color: isDark ? _goldLight : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuideStep(
                "١",
                "أمسك الهاتف بشكل أفقي مستوٍ تماماً (موازياً للأرض).",
              ),
              const SizedBox(height: 10),
              _buildGuideStep(
                "٢",
                "ابتعد عن المعادن والمغناطيس وأغطية الهاتف المغناطيسية.",
              ),
              const SizedBox(height: 10),
              _buildGuideStep(
                "٣",
                "حرّك الهاتف في الهواء على شكل رقم ٨ (♾️) عدة مرات لمعايرة الحساس.",
              ),
              const SizedBox(height: 10),
              _buildGuideStep(
                "٤",
                "أدِر جسمك والهاتف حتى يلتقي مؤشر الكعبة الذهبي مع المؤشر العلوي الثابت.",
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? _gold : _emerald,
                foregroundColor: isDark ? const Color(0xFF041D16) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "فهمت",
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep(String num, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: _gold.withValues(alpha: 0.6)),
          ),
          child: Center(
            child: Text(
              num,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _gold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.cairo(fontSize: 12.5, height: 1.5),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initialLoadTimer?.cancel();
    _stopCompassListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qiblaResult = QiblaGeodesicService.calculate(
      _activeCoordinates.latitude,
      _activeCoordinates.longitude,
    );
    final qiblaDirection = qiblaResult.bearingDeg;
    final heading = _smoothedHeading;
    final continuousHeading = _continuousHeading;
    final accuracyLevel = _getAccuracyLevel();
    final isReliable = _isHeadingReliable(heading);

    final double signedDiff = heading != null
        ? QiblaGeodesicService.shortestSignedDelta(heading, qiblaDirection)
        : 180.0;
    final bool isAligned = isReliable &&
        QiblaGeodesicService.isAligned(
          signedDiff,
          toleranceDeg: _alignmentToleranceDeg,
        );

    final statusText = _getCompassStatusText(accuracyLevel, heading);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.appScaffoldBg,
        appBar: AppBar(
          title: Text(
            "اتجاه القبلة",
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? _goldLight : Colors.white,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? context.appHeaderBg : _emerald,
          foregroundColor: isDark ? _goldLight : Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          actions: [
            IconButton(
              icon: _isRefreshingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location_rounded),
              tooltip: "تحديث الموقع GPS",
              onPressed: _refreshGpsLocation,
            ),
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: "طريقة المعايرة",
              onPressed: () => _showCalibrationGuideDialog(isDark),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: context.appBgGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: _isInitialLoading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: isDark ? _goldLight : _emerald,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'جاري تحديد موقعك واتجاه القبلة بدقة...',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? _goldLight
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'يرجى إمساك الهاتف بشكل أفقي مستوٍ تماماً',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                children: [
                  _buildLocationAndAccuracyHeader(
                    isDark: isDark,
                    qiblaDirection: qiblaDirection,
                    accuracyLevel: accuracyLevel,
                  ),

                  if (_isUsingFallbackMeccaCoords()) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _refreshGpsLocation,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_off_rounded,
                                color: Colors.orange, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "لم يتم تحديد موقعك الدقيق بعد. اضغط هنا لتفعيل GPS.",
                                style: GoogleFonts.cairo(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.orange.shade200
                                      : Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (!_isFlat && heading != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.55)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.screen_lock_rotation_rounded,
                              color: Colors.amber, size: 19),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "يرجى إمساك الهاتف بشكل أفقي مستوٍ تماماً (موازياً للأرض) للحصول على قراءة دقيقة.",
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? _goldLight
                                    : const Color(0xFF78350F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  _buildGuidanceBanner(
                    isDark: isDark,
                    heading: heading,
                    signedDiff: signedDiff,
                    isAligned: isAligned,
                    isReliable: isReliable,
                    qiblaDirection: qiblaDirection,
                  ),

                  const SizedBox(height: 20),

                  _buildCompassWidget(
                    isDark: isDark,
                    continuousHeading: continuousHeading,
                    qiblaDirection: qiblaDirection,
                    isAligned: isAligned,
                  ),

                  const SizedBox(height: 20),

                  if (heading != null)
                    _buildTelemetryRow(
                      isDark: isDark,
                      heading: heading,
                      qiblaDirection: qiblaDirection,
                      signedDiff: signedDiff,
                      isAligned: isAligned,
                    )
                  else if (_sensorUnavailable)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        "تعذر قراءة حساس البوصلة على هذا الجهاز. يمكنك الاعتماد على زاوية القبلة الجغرافية (${QuranTextFormatter.toArabicDigits(qiblaDirection.toStringAsFixed(1))}° من الشمال الحقيقي) والخريطة التفاعلية أدناه.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.orange.shade200
                              : Colors.orange.shade900,
                        ),
                      ),
                    ),

                  const SizedBox(height: 18),

                  QiblaInteractiveMap(
                    latitude: _activeCoordinates.latitude,
                    longitude: _activeCoordinates.longitude,
                    qiblaBearingDeg: qiblaDirection,
                    deviceHeadingDeg: heading,
                    isHeadingReliable: isReliable,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 16),

                  _buildAccuracyPanel(
                    isDark: isDark,
                    qiblaDirection: qiblaDirection,
                    distanceKm: qiblaResult.distanceKm,
                    statusText: statusText,
                    accuracyLevel: accuracyLevel,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationAndAccuracyHeader({
    required bool isDark,
    required double qiblaDirection,
    required _CompassAccuracyLevel accuracyLevel,
  }) {
    final (accLabel, accColor) = _magneticInterference
        ? ("تشويش مغناطيسي", Colors.deepOrange)
        : switch (accuracyLevel) {
            _CompassAccuracyLevel.high => ("دقة عالية", Colors.green),
            _CompassAccuracyLevel.medium => ("دقة متوسطة", Colors.amber.shade700),
            _CompassAccuracyLevel.low => ("معايرة مطلوبة", Colors.deepOrange),
            _CompassAccuracyLevel.unknown => ("جاري الفحص", Colors.blueGrey),
          };

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: context.appCardGradient),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _gold.withValues(alpha: isDark ? 0.45 : 0.65),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: isDark ? _goldLight : _emerald,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    (_locationName != null && _locationName!.isNotEmpty)
                        ? _locationName!
                        : "إحداثياتك الحالية",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: accColor.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                accLabel,
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : accColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuidanceBanner({
    required bool isDark,
    required double? heading,
    required double signedDiff,
    required bool isAligned,
    required bool isReliable,
    required double qiblaDirection,
  }) {
    final IconData icon;
    final String title;
    final String subtitle;
    final Color borderColor;
    final Color accentTextColor;

    if (heading == null) {
      icon = Icons.explore_rounded;
      title =
          "زاوية القبلة: ${QuranTextFormatter.toArabicDigits(qiblaDirection.toStringAsFixed(1))}°";
      subtitle = "وجّه الهاتف أفقياً لبدء التحديد الفوري";
      borderColor = _gold.withValues(alpha: isDark ? 0.45 : 0.65);
      accentTextColor = isDark ? _goldLight : const Color(0xFF0F172A);
    } else if (_magneticInterference) {
      icon = Icons.warning_amber_rounded;
      title = "يوجد تشويش مغناطيسي محتمل";
      subtitle = "ابتعد عن المعادن والمغناطيس أو استخدم الخريطة أدناه";
      borderColor = Colors.deepOrange;
      accentTextColor = isDark ? Colors.orangeAccent : Colors.deepOrange.shade800;
    } else if (!isReliable) {
      icon = Icons.sync_problem_rounded;
      title = "يرجى معايرة البوصلة";
      subtitle = "حرّك الهاتف على شكل رقم 8 (♾️) لتحسين دقة الاتجاه";
      borderColor = Colors.amber;
      accentTextColor = isDark ? _goldLight : const Color(0xFF92400E);
    } else if (isAligned) {
      icon = Icons.check_circle_rounded;
      title = "أنت الآن متجه نحو القبلة 🕋";
      subtitle = "قراءة الحساس موثوقة والاتجاه متطابق ضمن ±٤°";
      borderColor = const Color(0xFF10B981);
      accentTextColor = const Color(0xFF10B981);
    } else {
      final absDiff =
          QuranTextFormatter.toArabicDigits(signedDiff.abs().round().toString());
      final turnRight = signedDiff > 0;
      icon = turnRight
          ? Icons.rotate_right_rounded
          : Icons.rotate_left_rounded;
      title = turnRight
          ? "أدِر الهاتف لليمين $absDiff°"
          : "أدِر الهاتف لليسار $absDiff°";
      subtitle = "حتى يلتقي مؤشر الكعبة مع المثلث العلوي";
      borderColor = _gold.withValues(alpha: 0.65);
      accentTextColor = isDark ? _goldLight : const Color(0xFF92400E);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAligned
              ? (isDark
                  ? const [Color(0xFF0A2E25), Color(0xFF07211A)]
                  : const [Color(0xFFECFDF5), Color(0xFFD1FAE5)])
              : context.appCardGradient,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: isAligned ? 1.8 : 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: (isAligned ? const Color(0xFF10B981) : _gold)
                  .withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentTextColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: accentTextColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyPanel({
    required bool isDark,
    required double qiblaDirection,
    required double distanceKm,
    required String statusText,
    required _CompassAccuracyLevel accuracyLevel,
  }) {
    final locationAccText = _locationAccuracyMeters != null
        ? '±${QuranTextFormatter.toArabicDigits(_locationAccuracyMeters!.round().toString())} متر'
        : 'تقريبي';
    final decText = _declinationDeg != null
        ? 'الشمال الحقيقي (انحراف ${_declinationDeg!.toStringAsFixed(1)}°)'
        : 'الشمال الحقيقي';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: context.appCardGradient),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _gold.withValues(alpha: isDark ? 0.45 : 0.65),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined,
                  size: 18, color: isDark ? _goldLight : _emerald),
              const SizedBox(width: 8),
              Text(
                'بيانات الدقة وحالة البوصلة',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? _goldLight : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            'اتجاه القبلة:',
            '${QuranTextFormatter.toArabicDigits(qiblaDirection.toStringAsFixed(2))}° ($decText)',
            isDark,
          ),
          _buildInfoRow(
            'المسافة للكعبة:',
            '${QuranTextFormatter.toArabicDigits(distanceKm.toStringAsFixed(0))} كم',
            isDark,
          ),
          _buildInfoRow(
            'الموقع الحالي:',
            _locationName ?? 'غير محدد',
            isDark,
          ),
          _buildInfoRow(
            'دقة الموقع التقريبية:',
            locationAccText,
            isDark,
          ),
          _buildInfoRow(
            'حالة البوصلة:',
            statusText,
            isDark,
          ),
          if (_magneticFieldUt != null)
            _buildInfoRow(
              'المجال المغناطيسي:',
              '${_magneticFieldUt!.toStringAsFixed(1)} µT',
              isDark,
            ),
          if (accuracyLevel == _CompassAccuracyLevel.low ||
              accuracyLevel == _CompassAccuracyLevel.unknown ||
              _magneticInterference) ...[
            const SizedBox(height: 8),
            Text(
              '💡 للمعايرة: حرّك الهاتف على شكل رقم 8 (♾️) وابتعد عن أي معادن أو أغطية مغناطيسية.',
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                color: isDark ? _goldLight : const Color(0xFF78350F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassWidget({
    required bool isDark,
    required double? continuousHeading,
    required double qiblaDirection,
    required bool isAligned,
  }) {
    final double dialRad =
        continuousHeading != null ? (-continuousHeading * math.pi / 180.0) : 0.0;
    final double qiblaRad = continuousHeading != null
        ? ((qiblaDirection - continuousHeading) * math.pi / 180.0)
        : (qiblaDirection * math.pi / 180.0);

    return Center(
      child: Column(
        children: [
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: isAligned
                      ? const Color(0xFF10B981)
                      : (isDark ? context.appHeaderBg : _emerald),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isAligned ? const Color(0xFF10B981) : _gold,
                  ),
                ),
                child: Text(
                  "أمام الهاتف",
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 32,
                color: isAligned ? const Color(0xFF10B981) : _gold,
              ),
            ],
          ),
          SizedBox(
            width: 304,
            height: 304,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAligned
                          ? const Color(0xFF10B981)
                          : _gold.withValues(alpha: isDark ? 0.5 : 0.65),
                      width: isAligned ? 3.5 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isAligned ? const Color(0xFF10B981) : _gold)
                            .withValues(alpha: isAligned ? 0.35 : 0.14),
                        blurRadius: isAligned ? 26 : 16,
                        spreadRadius: isAligned ? 4 : 0,
                      ),
                    ],
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: dialRad, end: dialRad),
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.linear,
                  builder: (_, angle, child) {
                    return Transform.rotate(angle: angle, child: child);
                  },
                  child: _buildCompassDial(isDark),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: qiblaRad, end: qiblaRad),
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.linear,
                  builder: (_, angle, child) {
                    return Transform.rotate(angle: angle, child: child);
                  },
                  child: _buildQiblaNeedle(isAligned, isDark),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAligned
                        ? const Color(0xFF10B981)
                        : (isDark ? const Color(0xFF041D16) : _emerald),
                    border: Border.all(color: _gold, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassDial(bool isDark) {
    final dialBg = isDark ? context.appCardGradient.first : const Color(0xFFFFFDF8);
    return Container(
      width: 286,
      height: 286,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dialBg,
      ),
      child: CustomPaint(
        painter: _CompassDialPainter(isDark: isDark),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 26,
              child: _buildCardinalBadge('N', 'ش', Colors.redAccent, isDark),
            ),
            Positioned(
              bottom: 26,
              child: _buildCardinalBadge(
                'S',
                'ج',
                isDark ? Colors.white70 : Colors.black87,
                isDark,
              ),
            ),
            Positioned(
              right: 26,
              child: _buildCardinalBadge(
                'E',
                'ق',
                isDark ? Colors.white70 : Colors.black87,
                isDark,
              ),
            ),
            Positioned(
              left: 26,
              child: _buildCardinalBadge(
                'W',
                'غ',
                isDark ? Colors.white70 : Colors.black87,
                isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardinalBadge(
    String en,
    String ar,
    Color color,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          en,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.0,
            color: color,
          ),
        ),
        Text(
          ar,
          style: GoogleFonts.cairo(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1.1,
            color: color.withValues(alpha: 0.78),
          ),
        ),
      ],
    );
  }

  Widget _buildQiblaNeedle(bool isAligned, bool isDark) {
    final needleColor = isAligned
        ? const Color(0xFF10B981)
        : _gold;

    return SizedBox(
      width: 286,
      height: 286,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(286, 286),
            painter: _QiblaNeedlePainter(
              color: needleColor,
              isAligned: isAligned,
            ),
          ),
          Positioned(
            top: 46,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAligned
                    ? const Color(0xFF065F46)
                    : const Color(0xFF041D16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isAligned ? const Color(0xFF10B981) : _gold,
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6),
                ],
              ),
              child: const Text(
                "🕋",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow({
    required bool isDark,
    required double heading,
    required double qiblaDirection,
    required double signedDiff,
    required bool isAligned,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildTelemetryCard(
            isDark: isDark,
            label: "اتجاه الهاتف",
            value:
                "${QuranTextFormatter.toArabicDigits(heading.toStringAsFixed(0))}°",
            icon: Icons.screen_rotation_alt_rounded,
            color: isDark ? _goldLight : _emerald,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTelemetryCard(
            isDark: isDark,
            label: "زاوية القبلة",
            value:
                "${QuranTextFormatter.toArabicDigits(qiblaDirection.toStringAsFixed(1))}°",
            icon: Icons.mosque_rounded,
            color: _gold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTelemetryCard(
            isDark: isDark,
            label: "الفرق",
            value: isAligned
                ? "٠°"
                : "${QuranTextFormatter.toArabicDigits(signedDiff.abs().round().toString())}°",
            icon: isAligned
                ? Icons.check_circle_rounded
                : Icons.straighten_rounded,
            color: isAligned ? const Color(0xFF10B981) : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryCard({
    required bool isDark,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: context.appCardGradient),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _gold.withValues(alpha: isDark ? 0.45 : 0.65),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10.5,
              color: isDark ? Colors.white60 : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  final bool isDark;

  const _CompassDialPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final innerRingPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius * 0.62, innerRingPaint);
    canvas.drawCircle(center, radius * 0.34, innerRingPaint);

    final crossPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.56),
      Offset(center.dx, center.dy + radius * 0.56),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.56, center.dy),
      Offset(center.dx + radius * 0.56, center.dy),
      crossPaint,
    );

    for (int deg = 0; deg < 360; deg += 5) {
      final isCardinal = deg % 90 == 0;
      final isMajor = deg % 30 == 0;
      final rad = (deg - 90) * math.pi / 180.0;

      final outerR = radius - 6;
      final tickLen = isCardinal ? 14.0 : (isMajor ? 10.0 : 5.5);
      final innerR = outerR - tickLen;

      final tickColor = isCardinal
          ? (deg == 0
              ? Colors.redAccent
              : (isDark ? Colors.white70 : Colors.black87))
          : isMajor
              ? (isDark ? Colors.white54 : Colors.black54)
              : (isDark ? Colors.white24 : Colors.black26);

      final paint = Paint()
        ..color = tickColor
        ..strokeWidth = isCardinal ? 2.6 : (isMajor ? 1.8 : 1.0)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(
          center.dx + innerR * math.cos(rad),
          center.dy + innerR * math.sin(rad),
        ),
        Offset(
          center.dx + outerR * math.cos(rad),
          center.dy + outerR * math.sin(rad),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

class _QiblaNeedlePainter extends CustomPainter {
  final Color color;
  final bool isAligned;

  const _QiblaNeedlePainter({
    required this.color,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final needlePath = Path()
      ..moveTo(cx, 12)
      ..lineTo(cx + 12, cy - 10)
      ..lineTo(cx, cy + 28)
      ..lineTo(cx - 12, cy - 10)
      ..close();

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(needlePath, shadowPaint);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(needlePath, fillPaint);

    final spinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(cx, 16), Offset(cx, cy), spinePaint);
  }

  @override
  bool shouldRepaint(covariant _QiblaNeedlePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isAligned != isAligned;
  }
}
