import 'dart:async';
import 'dart:math' as math;

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';

class QiblaScreen extends StatefulWidget {
  final Coordinates coordinates;
  const QiblaScreen({super.key, required this.coordinates});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? _heading;
  bool _wasAligned = false;
  StreamSubscription<CompassEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _initCompass();
  }

  void _initCompass() {
    _subscription = FlutterCompass.events?.listen((event) {
      if (!mounted) return;

      final heading = event.heading;
      if (heading != null) {
        final qibla = Qibla(widget.coordinates);
        final qiblaDir = qibla.direction;
        final diff = ((qiblaDir - heading + 540) % 360) - 180;
        final isAligned = diff.abs() < 5.0;

        if (isAligned && !_wasAligned) {
          HapticFeedback.heavyImpact();
        }
        _wasAligned = isAligned;

        setState(() {
          _heading = heading;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qibla = Qibla(widget.coordinates);
    final qiblaDirection = qibla.direction; // الزاوية الرياضية الدقيقة للقبلة من الشمال
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double? heading = _heading;
    final double diff = heading != null
        ? (((qiblaDirection - heading + 540) % 360) - 180)
        : 180;
    final bool isAligned = heading != null && diff.abs() < 5.0;

    final primaryColor = isAligned
        ? Colors.greenAccent.shade400
        : (isDark ? Colors.tealAccent : const Color(0xFF0F766E));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0B131E) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            "اتجاه القبلة",
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'ArefRuqaa'),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),

              // بطاقة حالة الاتجاه التفاعلية
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isAligned
                      ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAligned
                        ? Colors.green.shade600
                        : (isDark ? Colors.white10 : Colors.black12),
                    width: isAligned ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isAligned
                          ? Colors.green.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAligned
                          ? Icons.check_circle_rounded
                          : Icons.compass_calibration_rounded,
                      color: isAligned
                          ? (isDark ? Colors.greenAccent : Colors.green.shade800)
                          : primaryColor,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        isAligned
                            ? "أنت الآن بالاتجاه الصحيح للقبلة 🕋"
                            : "زاوية القبلة: ${qiblaDirection.toStringAsFixed(1)}°",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isAligned
                              ? (isDark
                                  ? Colors.greenAccent
                                  : Colors.green.shade900)
                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // البوصلة التفاعلية السلسة
              Center(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // توهج دائم عند التوجه للقبلة
                      if (isAligned)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          width: 310,
                          height: 310,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.4),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),

                      // قرص البوصلة الحقيقي (يدور بسلاسة بعكس اتجاه الهاتف)
                      if (heading != null)
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: -heading * (math.pi / 180),
                          ),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          builder: (context, angle, child) {
                            return Transform.rotate(
                              angle: angle,
                              child: _buildCompassDial(isDark),
                            );
                          },
                        )
                      else
                        _buildCompassDial(isDark),

                      // مؤشر القبلة الكعبة المشرفة (يدور مع الشمال + زاوية القبلة)
                      if (heading != null)
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: (-heading + qiblaDirection) * (math.pi / 180),
                          ),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          builder: (context, angle, child) {
                            return Transform.rotate(
                              angle: angle,
                              child: _buildQiblaPointer(isAligned, isDark),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // زاوية الهاتف وتنبيه المعايرة
              if (heading != null)
                Text(
                  "زاوية الهاتف الحالية: ${heading.toStringAsFixed(1)}°",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white60 : Colors.grey[700],
                  ),
                )
              else
                const Text(
                  "جاري قياس اتجاه البوصلة...",
                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                ),

              const SizedBox(height: 16),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.amber.withValues(alpha: 0.3)
                        : Colors.amber.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "للحصول على أفضل دقة: ضع الهاتف على سطح مستوٍ وحركه على شكل رقم 8 كالتالي ♾️ للعايرة، وابتعد عن الأجهزة المغناطيسية.",
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: isDark
                              ? Colors.amber.shade100
                              : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompassDial(bool isDark) {
    final dialBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey[300]!;

    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dialBg,
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(36, (index) {
            final isMain = index % 9 == 0;
            return Transform.rotate(
              angle: (index * 10) * (math.pi / 180),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: isMain ? 12 : 6,
                  width: isMain ? 3 : 1.5,
                  color: isMain
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.white38 : Colors.black38),
                  margin: const EdgeInsets.only(top: 8),
                ),
              ),
            );
          }),

          Positioned(
            top: 24,
            child: Text(
              'N',
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            child: Text(
              'S',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          Positioned(
            right: 24,
            child: Text(
              'E',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          Positioned(
            left: 24,
            child: Text(
              'W',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaPointer(bool isAligned, bool isDark) {
    final pointerColor = isAligned
        ? Colors.green.shade500
        : (isDark ? Colors.amberAccent : const Color(0xFFD97706));

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.navigation_rounded,
              size: 48,
              color: pointerColor,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: pointerColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                  )
                ],
              ),
              child: const Text(
                'القبلة 🕋',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
