import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProphetPrayersScreen extends StatefulWidget {
  const ProphetPrayersScreen({super.key});

  @override
  State<ProphetPrayersScreen> createState() => _ProphetPrayersScreenState();
}

class _ProphetPrayersScreenState extends State<ProphetPrayersScreen>
    with SingleTickerProviderStateMixin {
  int _counter = 0;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadCounter();
    _controller = AnimationController(
      // جعل المدة أقصر قليلاً لتفاعل أسرع
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = prefs.getInt('prophet_prayer_counter') ?? 0;
    });
  }

  Future<void> _saveCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('prophet_prayer_counter', _counter);
  }

  void _increment() {
    setState(() {
      _counter++;
    });
    _saveCounter();

    // تشغيل الأنيميشن
    _controller.forward().then((_) => _controller.reverse());

    // تشغيل الاهتزاز والصوت الخفيف
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  void _reset() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = 0;
    });
    await prefs.setInt('prophet_prayer_counter', 0);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _reset,
              tooltip: "تصفير العداد",
            )
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1B5E20), // أخضر غامق
                Color(0xFF4CAF50), // أخضر فاتح
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // زخرفة خلفية خفيفة
                const Positioned(
                  bottom: -30,
                  right: -30,
                  child: Opacity(
                    opacity: 0.1,
                    child:
                        Icon(Icons.mosque, size: 300, color: Colors.white),
                  ),
                ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "إِنَّ اللَّهَ وَمَلَائِكَتَهُ يُصَلُّونَ عَلَى النَّبِيِّ",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      "اللهم صلِّ وسلم\nعلى نبينا محمد",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        shadows: [
                          Shadow(
                            blurRadius: 15.0,
                            color: Colors.black38,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 50),

                    // العداد الكبير - التفاعل فقط على الدائرة
                    GestureDetector(
                      onTap: _increment,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                            border: Border.all(color: Colors.white54, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 30,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.touch_app,
                                  size: 45, color: Colors.white70),
                              const SizedBox(height: 10),
                              Text(
                                "$_counter",
                                style: const TextStyle(
                                  fontSize: 70,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              const Text(
                                "مرة",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    const Text(
                      "اضغط على الدائرة للصلاة على النبي",
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),

                    const Spacer(flex: 2),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------- صفحة الأذكار التفصيلية الاحترافية --------------------
