import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';

class ProphetPrayersScreen extends StatefulWidget {
  const ProphetPrayersScreen({super.key});

  @override
  State<ProphetPrayersScreen> createState() => _ProphetPrayersScreenState();
}

class _ProphetPrayersScreenState extends State<ProphetPrayersScreen>
    with SingleTickerProviderStateMixin {
  static const int _targetCount = 200;
  int _counter = 0;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadCounter();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

    _controller.forward().then((_) => _controller.reverse());

    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);

    if (mounted) {
      final vm = Provider.of<TasksViewModel>(context, listen: false);
      vm.updateProphetPrayerCount(_counter);
    }

    // Check for milestone stages (50, 100, 150, 200)
    if (_counter == 50 || _counter == 100 || _counter == 150 || _counter == 200) {
      _showMilestoneDialog(_counter);
    }
  }

  void _showMilestoneDialog(int count) {
    HapticFeedback.heavyImpact();

    String title = "";
    String message = "";
    String emoji = "🎉";
    Color themeColor = Colors.teal;

    switch (count) {
      case 50:
        emoji = "✨";
        title = "المرحلة الأولى! (50/200)";
        message =
            "ما شاء الله! أتممت 50 صلاة على النبي ﷺ.\nواصل للوصول إلى المرحلة التالية (100).";
        themeColor = Colors.teal;
        break;
      case 100:
        emoji = "🌟";
        title = "نصف الطريق! (100/200)";
        message =
            "تبارك الله! أتممت 100 صلاة على الحبيب المصطفى ﷺ.\n\"مَنْ صَلَّى عَلَيَّ وَاحِدَةً صَلَّى اللَّهُ عَلَيْهِ عَشْرًا\".";
        themeColor = const Color(0xFF1565C0);
        break;
      case 150:
        emoji = "⚡";
        title = "المرحلة الثالثة! (150/200)";
        message =
            "إنجاز رائع! 150 صلاة على النبي ﷺ.\nلم يتبقَّ سوى 50 صلاة لإتمام الورد اليومي كاملًا!";
        themeColor = Colors.orange.shade800;
        break;
      case 200:
        emoji = "🏆";
        title = "إتمام الورد اليومي! (200/200)";
        message =
            "🎉 مبارك! أتممت 200 صلاة على النبي ﷺ بنجاح.\nجعلها الله في ميزان حسناتك وشفاعةً لك يوم القيامة.";
        themeColor = Colors.amber.shade800;
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor:
              isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : themeColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isDark ? Colors.white70 : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "متابعة الصلاة على النبي",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _reset() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = 0;
    });
    await prefs.setInt('prophet_prayer_counter', 0);
    HapticFeedback.mediumImpact();

    if (mounted) {
      final vm = Provider.of<TasksViewModel>(context, listen: false);
      vm.updateProphetPrayerCount(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1B5E20);
    final secondaryTextColor =
        isDark ? Colors.white70 : const Color(0xFF2E7D32);
    final progressColor =
        isDark ? Colors.amberAccent : const Color(0xFF2E7D32);

    final int remaining = (_targetCount - _counter).clamp(0, _targetCount);
    final double progress = (_counter / _targetCount).clamp(0.0, 1.0);
    final int percent = (progress * 100).toInt();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle:
              isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: primaryTextColor),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: primaryTextColor),
              onPressed: _reset,
              tooltip: "تصفير العداد",
            )
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [
                      Color(0xFF0B2915),
                      Color(0xFF1B5E20),
                    ]
                  : const [
                      Color(0xFFF1F8E9),
                      Color(0xFFDCEDC8),
                      Color(0xFFC8E6C9),
                    ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: -30,
                  right: -30,
                  child: Opacity(
                    opacity: isDark ? 0.08 : 0.12,
                    child: Icon(
                      Icons.mosque,
                      size: 300,
                      color: isDark ? Colors.white : const Color(0xFF2E7D32),
                    ),
                  ),
                ),

                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            "إِنَّ اللَّهَ وَمَلَائِكَتَهُ يُصَلُّونَ عَلَى النَّبِيِّ",
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "اللهم صلِّ وسلم\nعلى نبينا محمد",
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                            shadows: isDark
                                ? const [
                                    Shadow(
                                      blurRadius: 15.0,
                                      color: Colors.black38,
                                      offset: Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // شريط مراحل الوصول
                        _buildMilestoneSteps(isDark),

                        const SizedBox(height: 16),

                        // بطاقة الإحصائيات والمتبقي
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white24
                                  : const Color(0xFFA5D6A7),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.2 : 0.06),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    "تم إنجازه",
                                    "$_counter من $_targetCount",
                                    Icons.check_circle_outline,
                                    isDark,
                                  ),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: isDark
                                        ? Colors.white30
                                        : const Color(0xFFC8E6C9),
                                  ),
                                  _buildStatItem(
                                    "المتبقي",
                                    remaining > 0
                                        ? "$remaining مرة"
                                        : "مكتمل 🎉",
                                    Icons.hourglass_bottom,
                                    isDark,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 10,
                                  backgroundColor: isDark
                                      ? Colors.white24
                                      : const Color(0xFFE8F5E9),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      progressColor),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _counter >= _targetCount
                                    ? "🎉 ما شاء الله! أتممت الورد اليومي بنجاح"
                                    : "نسبة الإنجاز: $percent% • واصل بالضغط على العداد 👇",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : const Color(0xFF1B5E20),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // العداد الكبير مع الحلقة الدائرية للإنجاز
                        GestureDetector(
                          onTap: _increment,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 250,
                                  height: 250,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 8,
                                    backgroundColor: isDark
                                        ? Colors.white24
                                        : const Color(0xFFC8E6C9),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        progressColor),
                                  ),
                                ),
                                Container(
                                  width: 230,
                                  height: 230,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.white,
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white54
                                          : const Color(0xFF81C784),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                            alpha: isDark ? 0.2 : 0.08),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      )
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.touch_app,
                                          size: 36, color: secondaryTextColor),
                                      const SizedBox(height: 4),
                                      Text(
                                        "$_counter",
                                        style: TextStyle(
                                          fontSize: 60,
                                          fontWeight: FontWeight.bold,
                                          color: primaryTextColor,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "من $_targetCount مرة",
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          "اضغط داخل الدائرة للصلاة على النبي",
                          style: TextStyle(
                              color: secondaryTextColor, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneSteps(bool isDark) {
    final milestones = [0, 50, 100, 150, 200];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white24 : const Color(0xFFA5D6A7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "مراحل الوصول اليومية",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF1B5E20),
                ),
              ),
              Text(
                "الهدف: 200",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.amberAccent : Colors.teal.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(milestones.length, (index) {
              final step = milestones[index];
              final isReached = _counter >= step;
              final isLast = index == milestones.length - 1;

              double lineProgress = 0.0;
              if (!isLast) {
                final nextStep = milestones[index + 1];
                if (_counter <= step) {
                  lineProgress = 0.0;
                } else if (_counter >= nextStep) {
                  lineProgress = 1.0;
                } else {
                  lineProgress = (_counter - step) / (nextStep - step);
                }
              }

              return Expanded(
                child: Row(
                  children: [
                    // Node Circle
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isReached
                            ? (isDark ? Colors.amberAccent : Colors.teal)
                            : (isDark ? Colors.white12 : Colors.grey[200]),
                        border: Border.all(
                          color: isReached
                              ? (isDark ? Colors.amber : Colors.teal.shade800)
                              : Colors.grey[400]!,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isReached && step > 0
                            ? Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: isDark ? Colors.black : Colors.white,
                              )
                            : Text(
                                "$step",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isReached
                                      ? (isDark ? Colors.black : Colors.white)
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.grey[700]),
                                ),
                              ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FractionallySizedBox(
                              widthFactor: lineProgress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.amberAccent
                                      : Colors.teal,
                                  borderRadius: BorderRadius.circular(2.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, bool isDark) {
    final iconColor = isDark ? Colors.amberAccent : const Color(0xFFD97706);
    final labelColor = isDark ? Colors.white70 : const Color(0xFF2E7D32);
    final valueColor = isDark ? Colors.white : const Color(0xFF1B5E20);

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: labelColor, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
