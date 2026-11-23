import 'dart:async';
import 'dart:math' as math;

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:religious_tasks_app/core/services/location_service.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';

class QiblaMath {
  static double normalizeAngle(double angle) {
    final normalized = ((angle % 360.0) + 360.0) % 360.0;
    return normalized == 360.0 ? 0.0 : normalized;
  }

  /// Returns the shortest signed angular difference in [-180, 180)
  /// Positive means clockwise (turn right), negative means counter-clockwise (turn left).
  static double shortestSignedDelta(double fromDeg, double toDeg) {
    return ((toDeg - fromDeg + 540.0) % 360.0) - 180.0;
  }

  static bool isAligned(double signedDiffDeg, {double toleranceDeg = 4.0}) {
    return signedDiffDeg.abs() <= toleranceDeg;
  }
}

enum _CompassAccuracyLevel { high, medium, low, unknown }

class QiblaScreen extends StatefulWidget {
  final Coordinates coordinates;
  const QiblaScreen({super.key, required this.coordinates});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  static const Color _emerald = Color(0xFF0F766E);
  static const Color _gold = Color(0xFFD4AF37);
  static const double _alignmentToleranceDeg = 4.0;

  double? _smoothedHeading;
  double? _continuousHeading;
  double? _accuracyValue;
  bool _wasAligned = false;
  bool _sensorUnavailable = false;
  bool _isRefreshingLocation = false;

  late Coordinates _activeCoordinates;
  String? _locationName;

  StreamSubscription<CompassEvent>? _subscription;
  Timer? _sensorTimeout;

  @override
  void initState() {
    super.initState();
    _activeCoordinates = widget.coordinates;
    _syncLocationFromViewModel();
    _initCompass();
  }

  void _syncLocationFromViewModel() {
    try {
      final vm = Provider.of<TasksViewModel>(context, listen: false);
      final vmCoords = vm.prayerTimes?.coordinates;
      if (vmCoords != null) {
        _activeCoordinates = vmCoords;
      }
      _locationName = vm.locationName;
    } catch (_) {
      // Standalone usage without TasksViewModel in widget tree
    }
  }

  Future<void> _refreshGpsLocation() async {
    if (_isRefreshingLocation) return;
    setState(() => _isRefreshingLocation = true);

    try {
      TasksViewModel? vm;
      try {
        vm = Provider.of<TasksViewModel>(context, listen: false);
      } catch (_) {}

      if (vm != null) {
        await vm.refreshLocation();
        if (!mounted) return;
        setState(() {
          if (vm!.prayerTimes?.coordinates != null) {
            _activeCoordinates = vm.prayerTimes!.coordinates;
          }
          _locationName = vm.locationName;
        });
      } else {
        final res = await LocationService().getCurrentPosition(
          requestPermission: true,
        );
        if (!mounted) return;
        if (res.position != null) {
          final coords = Coordinates(
            res.position!.latitude,
            res.position!.longitude,
          );
          final name = await LocationService().getLocationName(res.position!);
          if (!mounted) return;
          setState(() {
            _activeCoordinates = coords;
            _locationName = name;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshingLocation = false);
      }
    }
  }

  void _initCompass() {
    final events = FlutterCompass.events;
    if (events == null) {
      _sensorUnavailable = true;
      return;
    }

    _sensorTimeout = Timer(const Duration(seconds: 5), () {
      if (mounted && _smoothedHeading == null) {
        setState(() => _sensorUnavailable = true);
      }
    });

    _subscription = events.listen((event) {
      if (!mounted) return;
      final rawHeading = event.heading;
      if (rawHeading == null || rawHeading.isNaN) return;

      _sensorTimeout?.cancel();
      final normalized = QiblaMath.normalizeAngle(rawHeading);

      double nextSmoothed;
      double nextContinuous;

      if (_smoothedHeading == null || _continuousHeading == null) {
        nextSmoothed = normalized;
        nextContinuous = normalized;
      } else {
        final delta =
            QiblaMath.shortestSignedDelta(_smoothedHeading!, normalized);
        // Deadband to eliminate tiny stationary sensor jitter
        if (delta.abs() < 0.25 && event.accuracy == _accuracyValue) {
          return;
        }
        // Adaptive smoothing: faster response on large turns, steadier near target
        final alpha = delta.abs() > 25.0 ? 0.35 : 0.20;
        final step = delta * alpha;
        nextSmoothed = QiblaMath.normalizeAngle(_smoothedHeading! + step);
        nextContinuous = _continuousHeading! + step;
      }

      final qiblaDir = Qibla(_activeCoordinates).direction;
      final diff = QiblaMath.shortestSignedDelta(nextSmoothed, qiblaDir);
      final aligned = QiblaMath.isAligned(
        diff,
        toleranceDeg: _alignmentToleranceDeg,
      );

      if (aligned && !_wasAligned) {
        HapticFeedback.mediumImpact();
      }
      _wasAligned = aligned;

      setState(() {
        _smoothedHeading = nextSmoothed;
        _continuousHeading = nextContinuous;
        _accuracyValue = event.accuracy;
        _sensorUnavailable = false;
      });
    });
  }

  _CompassAccuracyLevel _getAccuracyLevel() {
    final acc = _accuracyValue;
    if (acc == null || acc < 0) return _CompassAccuracyLevel.unknown;
    if (acc <= 18) return _CompassAccuracyLevel.high;
    if (acc <= 35) return _CompassAccuracyLevel.medium;
    return _CompassAccuracyLevel.low;
  }

  bool _isUsingFallbackMeccaCoords() {
    final latDiff = (_activeCoordinates.latitude - 21.4225).abs();
    final lngDiff = (_activeCoordinates.longitude - 39.8262).abs();
    return latDiff < 0.002 && lngDiff < 0.002;
  }

  void _showCalibrationGuideDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF162130) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.explore_rounded, color: _emerald),
              const SizedBox(width: 8),
              Text(
                "طريقة استخدام البوصلة",
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
                "إذا كانت الدقة منخفضة، حرّك الهاتف في الهواء على شكل رقم ٨ (♾️) عدة مرات.",
              ),
              const SizedBox(height: 10),
              _buildGuideStep(
                "٤",
                "أدِر جسمك والهاتف حتى يلتقي مؤشر الكعبة الذهبي مع المؤشر العلوي الثابت وتضيء الشاشة باللون الأخضر.",
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: _emerald,
                foregroundColor: Colors.white,
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
            color: _emerald.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              num,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _emerald,
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
    _sensorTimeout?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qiblaDirection = Qibla(_activeCoordinates).direction;
    final heading = _smoothedHeading;
    final continuousHeading = _continuousHeading;

    final double signedDiff = heading != null
        ? QiblaMath.shortestSignedDelta(heading, qiblaDirection)
        : 180.0;
    final bool isAligned = heading != null &&
        QiblaMath.isAligned(
          signedDiff,
          toleranceDeg: _alignmentToleranceDeg,
        );

    final accuracyLevel = _getAccuracyLevel();
    final needsCalibration = accuracyLevel == _CompassAccuracyLevel.low ||
        accuracyLevel == _CompassAccuracyLevel.unknown;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0B131E) : const Color(0xFFF3F8F6),
        appBar: AppBar(
          title: Text(
            "اتجاه القبلة",
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF0B131E) : _emerald,
          foregroundColor: Colors.white,
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
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              children: [
                // Location + Qibla Bearing + Accuracy Pill Row
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
                              "لم يتم تحديد موقعك الدقيق بعد. اضغط هنا لتفعيل الموقع (GPS) لحساب زاوية القبلة بدقة.",
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

                const SizedBox(height: 12),

                // Live Directional Guidance Banner
                _buildGuidanceBanner(
                  isDark: isDark,
                  heading: heading,
                  signedDiff: signedDiff,
                  isAligned: isAligned,
                  qiblaDirection: qiblaDirection,
                ),

                const SizedBox(height: 22),

                // Interactive Precision Compass
                _buildCompassWidget(
                  isDark: isDark,
                  continuousHeading: continuousHeading,
                  qiblaDirection: qiblaDirection,
                  isAligned: isAligned,
                ),

                const SizedBox(height: 22),

                // Telemetry Row (Phone Heading + Difference to Qibla)
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
                      "تعذر قراءة حساس البوصلة المغناطيسية على هذا الجهاز. يمكنك الاعتماد على زاوية القبلة الدقيقة (${QuranTextFormatter.toArabicDigits(qiblaDirection.toStringAsFixed(1))}° من الشمال).",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.orange.shade200
                            : Colors.orange.shade900,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _emerald,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "جاري قراءة حساس البوصلة...",
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : _emerald,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 14),

                // Calibration Notice Card
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: needsCalibration && heading != null
                        ? Colors.amber.withValues(alpha: isDark ? 0.14 : 0.18)
                        : (isDark ? const Color(0xFF172231) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: needsCalibration && heading != null
                          ? Colors.amber.withValues(alpha: 0.6)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : _emerald.withValues(alpha: 0.14)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        needsCalibration && heading != null
                            ? Icons.warning_amber_rounded
                            : Icons.tips_and_updates_rounded,
                        color: isDark
                            ? Colors.amberAccent
                            : Colors.amber.shade800,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          needsCalibration && heading != null
                              ? "دقة الحساس منخفضة حالياً: حرّك الهاتف على شكل رقم 8 (♾️) لمعايرة البوصلة وابتعد عن المعادن."
                              : "لأفضل دقة: ضع الهاتف أفقياً بموازاة الأرض وأدِره حتى ينطبق مؤشر الكعبة مع المثلث العلوي الثابت.",
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            height: 1.4,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.85)
                                : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
    final (accLabel, accColor) = switch (accuracyLevel) {
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
              color: isDark ? const Color(0xFF172231) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : _emerald.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: _emerald, size: 17),
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
            border: Border.all(color: accColor.withValues(alpha: 0.45)),
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
    required double qiblaDirection,
  }) {
    final IconData icon;
    final String title;
    final String subtitle;
    final Color borderColor;
    final Color bgColor;
    final Color accentTextColor;

    if (heading == null) {
      icon = Icons.explore_rounded;
      title =
          "زاوية القبلة: ${QuranTextFormatter.toArabicDigits(qiblaDirection.toStringAsFixed(1))}°";
      subtitle = "وجّه الهاتف أفقياً لبدء التحديد الفوري";
      borderColor = isDark ? Colors.white12 : _emerald.withValues(alpha: 0.2);
      bgColor = isDark ? const Color(0xFF172231) : Colors.white;
      accentTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    } else if (isAligned) {
      icon = Icons.check_circle_rounded;
      title = "أنت الآن متجه نحو القبلة 🕋";
      subtitle = "الاتجاه صحيح ومطابق تماماً";
      borderColor = Colors.green.shade500;
      bgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
      accentTextColor = isDark ? Colors.greenAccent : Colors.green.shade900;
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
      borderColor = _gold.withValues(alpha: 0.55);
      bgColor = isDark ? const Color(0xFF172231) : Colors.white;
      accentTextColor = isDark ? Colors.amberAccent : const Color(0xFF92400E);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: isAligned ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAligned ? Colors.green : Colors.black)
                .withValues(alpha: isAligned ? 0.22 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: (isAligned ? Colors.green : _gold).withValues(alpha: 0.16),
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
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: accentTextColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    color: isAligned
                        ? accentTextColor.withValues(alpha: 0.9)
                        : (isDark ? Colors.white60 : Colors.grey.shade600),
                  ),
                ),
              ],
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
          // Fixed Top Reference Notch ("أمام الهاتف")
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: isAligned
                      ? Colors.green
                      : (isDark ? const Color(0xFF1E293B) : _emerald),
                  borderRadius: BorderRadius.circular(10),
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
                color: isAligned ? Colors.greenAccent.shade400 : _gold,
              ),
            ],
          ),

          SizedBox(
            width: 304,
            height: 304,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Alignment Glow Ring
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAligned
                          ? Colors.green.withValues(alpha: 0.85)
                          : _gold.withValues(alpha: isDark ? 0.35 : 0.45),
                      width: isAligned ? 3.5 : 2,
                    ),
                    boxShadow: isAligned
                        ? [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.35),
                              blurRadius: 28,
                              spreadRadius: 6,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.35 : 0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                ),

                // Smoothly Rotating Compass Dial (North stays locked to Earth's North)
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: dialRad, end: dialRad),
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.linear,
                  builder: (_, angle, child) {
                    return Transform.rotate(angle: angle, child: child);
                  },
                  child: _buildCompassDial(isDark),
                ),

                // Smoothly Rotating True-0°-Centered Qibla Needle
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: qiblaRad, end: qiblaRad),
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.linear,
                  builder: (_, angle, child) {
                    return Transform.rotate(angle: angle, child: child);
                  },
                  child: _buildQiblaNeedle(isAligned, isDark),
                ),

                // Center Pivot Cap
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAligned
                        ? Colors.green
                        : (isDark ? const Color(0xFF0F172A) : _emerald),
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
    final dialBg = isDark ? const Color(0xFF131E2D) : Colors.white;
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
        ? (isDark ? Colors.greenAccent.shade400 : Colors.green.shade600)
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
          // Kaaba Emblem aligned cleanly along top center (0 deg)
          Positioned(
            top: 46,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAligned ? Colors.green.shade700 : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isAligned ? Colors.greenAccent : _gold,
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
            color: _emerald,
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
            color: isAligned ? Colors.green : Colors.orange,
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
        color: isDark ? const Color(0xFF172231) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : color.withValues(alpha: 0.2),
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
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10.5,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
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

    // Inner decorative circle
    final innerRingPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF0F766E))
          .withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius * 0.62, innerRingPaint);
    canvas.drawCircle(center, radius * 0.34, innerRingPaint);

    // Subtle crosshairs
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

    // 72 Degree Ticks (every 5 degrees)
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

    // Sharp forward Qibla pointer pointing straight UP (0 degrees)
    final needlePath = Path()
      ..moveTo(cx, 12) // Tip right near outer bezel
      ..lineTo(cx + 12, cy - 10)
      ..lineTo(cx, cy + 28) // Counterweight tail
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

    // Subtle center spine highlight
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
