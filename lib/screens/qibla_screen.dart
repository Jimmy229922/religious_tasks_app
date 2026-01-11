import 'dart:async';
import 'dart:math' as math;

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

class QiblaScreen extends StatefulWidget {
  final Coordinates coordinates;
  const QiblaScreen({super.key, required this.coordinates});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? _heading;
  StreamSubscription<CompassEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = FlutterCompass.events?.listen((event) {
      if (mounted) {
        setState(() {
          _heading = event.heading;
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
    // حساب اتجاه القبلة
    final qibla = Qibla(widget.coordinates);
    final qiblaDirection = qibla.direction; // الزاوية من الشمال
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("اتجاه القبلة")),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "اتجاه القبلة: ${qiblaDirection.toStringAsFixed(1)}°",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_heading == null)
                const Text("جاري معايرة البوصلة...",
                    style: TextStyle(color: Colors.red))
              else
                Text(
                  "زاوية الجوال: ${_heading!.toStringAsFixed(1)}°",
                  style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.grey[700]),
                ),
              const SizedBox(height: 50),

              // البوصلة
              SizedBox(
                width: 300,
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // قرص البوصلة (الشمال يدور ليكون في اتجاه الشمال الحقيقي)
                    // إذا كان heading 0، الشمال في الأعلى. إذا heading 90 (شرق)، الشمال يجب أن يكون يساراً (-90).
                    if (_heading != null)
                      Transform.rotate(
                        angle: -_heading! * (math.pi / 180),
                        child: Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.white,
                              border: Border.fromBorderSide(BorderSide(
                                  color:
                                      isDark ? Colors.white24 : Colors.black12,
                                  width: 2)),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.5)
                                      : const Color(0x0D000000),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                )
                              ]),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // تدريج البوصلة (صورة أو رسم بسيط)
                              ...List.generate(12, (index) {
                                return Transform.rotate(
                                  angle: (index * 30) * (math.pi / 180),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      height: 10,
                                      width: 2,
                                      color: index % 3 == 0
                                          ? (isDark
                                              ? Colors.white
                                              : Colors.black)
                                          : (isDark
                                              ? Colors.white54
                                              : Colors.black54),
                                      margin: const EdgeInsets.only(top: 10),
                                    ),
                                  ),
                                );
                              }),

                              // أيقونة البوصلة الأساسية (يمكن استبدالها برسمة مخصصة)
                              // Icon(Icons.explore,
                              //     size: 300, color: Colors.blueGrey.withOpacity(0.2)),

                              // حرف N
                              Positioned(
                                top: 25,
                                child: Text('N',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                        shadows: [
                                          Shadow(
                                              blurRadius: 2,
                                              color: Colors.black
                                                  .withValues(alpha: 0.3))
                                        ])),
                              ),
                              Positioned(
                                bottom: 25,
                                child: Text('S',
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24)),
                              ),
                              Positioned(
                                right: 25,
                                child: Text('E',
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24)),
                              ),
                              Positioned(
                                left: 25,
                                child: Text('W',
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24)),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // سهم القبلة (نحتاج أن يشير للقبلة بالنسبة للشمال)
                    // إذا كانت القبلة 135 درجة، والسهم مثبت على القرص،
                    // فإذا دورنا القرص ليتجه للشمال، يمكننا رسم سهم ثابت على القرص عند الزاوية 135.
                    if (_heading != null)
                      Transform.rotate(
                        // ندور هذا السهم مع قرص البوصلة، ولكن نضيف له زاوية القبلة
                        angle: (-_heading! + qiblaDirection) * (math.pi / 180),
                        child: const Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on,
                                    size: 40,
                                    color: Color(0xFF1E5128)), // لون التطبيق
                                Text('القبلة',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E5128)))
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF333333)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: isDark ? Colors.orange[900]! : Colors.orange,
                      width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color:
                            isDark ? Colors.orangeAccent : Colors.orange[800]),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "ضع هاتفك على سطح مستوٍ وابتعد عن المعادن والمغناطيس للحصول على دقة أفضل.",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
