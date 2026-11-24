import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';

class AchievementBadge {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String howToUnlock;
  final int currentProgress;
  final int targetProgress;
  final String unitLabel;
  final IconData icon;
  final Color color;

  const AchievementBadge({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.howToUnlock,
    required this.currentProgress,
    required this.targetProgress,
    required this.unitLabel,
    required this.icon,
    required this.color,
  });

  bool get isUnlocked => currentProgress >= targetProgress;

  double get progressRatio => targetProgress <= 0
      ? 0.0
      : (currentProgress / targetProgress).clamp(0.0, 1.0);
}

List<AchievementBadge> buildAchievementBadges({
  required int totalTasbeeh,
  required int morningStreak,
  required int eveningStreak,
  required int sleepStreak,
}) {
  return [
    AchievementBadge(
      id: 'morning_7',
      title: 'المحافظ',
      subtitle: '7 أيام فجر',
      description: 'وسام المواظبة على أذكار الصباح أسبوعاً متواصلاً.',
      howToUnlock:
          'افتح صفحة أذكار الصباح وأتمم جميع الأذكار يومياً لمدة 7 أيام متتالية دون انقطاع.',
      currentProgress: morningStreak,
      targetProgress: 7,
      unitLabel: 'يوم',
      icon: Icons.wb_twilight_rounded,
      color: Colors.orange,
    ),
    AchievementBadge(
      id: 'tasbeeh_1000',
      title: 'الذاكر',
      subtitle: '1000 تسبيحة',
      description: 'وسام للسان الرطب بذكر الله في المسبحة الإلكترونية.',
      howToUnlock:
          'استخدم المسبحة الإلكترونية (التسبيح الإلكتروني) حتى يصل إجمالي تسبيحاتك إلى 1000 تسبيحة.',
      currentProgress: totalTasbeeh,
      targetProgress: 1000,
      unitLabel: 'تسبيحة',
      icon: Icons.favorite_rounded,
      color: Colors.redAccent,
    ),
    AchievementBadge(
      id: 'evening_3',
      title: 'المثابر',
      subtitle: '3 أيام مساء',
      description: 'بداية قوية للالتزام بتحصين المساء يومياً.',
      howToUnlock:
          'افتح صفحة أذكار المساء وأتمم جميع الأذكار يومياً لمدة 3 أيام متتالية.',
      currentProgress: eveningStreak,
      targetProgress: 3,
      unitLabel: 'يوم',
      icon: Icons.nightlight_round,
      color: Colors.indigo,
    ),
    AchievementBadge(
      id: 'sleep_10',
      title: 'نور الليل',
      subtitle: '10 أيام نوم',
      description: 'وسام من يختم يومه بذكر الله وسورة الملك.',
      howToUnlock:
          'افتح أذكار النوم قبل منامك وأتممها كاملة لمدة 10 أيام متتالية.',
      currentProgress: sleepStreak,
      targetProgress: 10,
      unitLabel: 'يوم',
      icon: Icons.bed_rounded,
      color: Colors.deepPurple,
    ),
    AchievementBadge(
      id: 'tasbeeh_5000',
      title: 'السبّاح',
      subtitle: '5000 تسبيحة',
      description: 'وسام متقدم للمداومين على التسبيح والتهليل.',
      howToUnlock:
          'استمر في استخدام المسبحة الإلكترونية يومياً حتى يبلغ مجموع تسبيحاتك 5000 تسبيحة.',
      currentProgress: totalTasbeeh,
      targetProgress: 5000,
      unitLabel: 'تسبيحة',
      icon: Icons.stars_rounded,
      color: Colors.amber,
    ),
    AchievementBadge(
      id: 'morning_30',
      title: 'المخلص',
      subtitle: '30 يوم فجر',
      description: 'وسام الهمة العالية لإتمام أذكار الصباح شهراً كاملاً.',
      howToUnlock:
          'حافظ على إتمام جميع أذكار الصباح كل يوم لمدة 30 يوماً متتالياً.',
      currentProgress: morningStreak,
      targetProgress: 30,
      unitLabel: 'يوم',
      icon: Icons.mosque_rounded,
      color: Colors.teal,
    ),
    AchievementBadge(
      id: 'tasbeeh_100',
      title: 'بداية الذكر',
      subtitle: '100 تسبيحة',
      description: 'أول خطوة مباركة في طريق المداومة على التسبيح.',
      howToUnlock:
          'افتح المسبحة الإلكترونية وسبّح حتى تصل إلى 100 تسبيحة في إجمالي العدّاد.',
      currentProgress: totalTasbeeh,
      targetProgress: 100,
      unitLabel: 'تسبيحة',
      icon: Icons.fingerprint_rounded,
      color: const Color(0xFF0284C7),
    ),
    AchievementBadge(
      id: 'morning_1',
      title: 'إشراقة الفجر',
      subtitle: 'أول يوم صباح',
      description: 'وسام إتمام أذكار الصباح كاملة لأول مرة.',
      howToUnlock:
          'افتح أذكار الصباح وأتمم جميع أذكارها اليوم لتنال هذا الوسام فوراً.',
      currentProgress: morningStreak,
      targetProgress: 1,
      unitLabel: 'يوم',
      icon: Icons.wb_sunny_rounded,
      color: const Color(0xFFF59E0B),
    ),
    AchievementBadge(
      id: 'sleep_3',
      title: 'طمأنينة المنام',
      subtitle: '3 أيام نوم',
      description: 'وسام السكينة لمن يحافظ على أذكار النوم 3 ليالٍ متتالية.',
      howToUnlock:
          'أتمم جميع أذكار النوم لمدة 3 أيام متتالية قبل النوم.',
      currentProgress: sleepStreak,
      targetProgress: 3,
      unitLabel: 'يوم',
      icon: Icons.nights_stay_rounded,
      color: const Color(0xFF7C3AED),
    ),
    AchievementBadge(
      id: 'evening_7',
      title: 'أنس المساء',
      subtitle: '7 أيام مساء',
      description: 'تحصين أسبوع كامل بأذكار المساء دون انقطاع.',
      howToUnlock:
          'أتمم جميع أذكار المساء يومياً لمدة 7 أيام متتالية.',
      currentProgress: eveningStreak,
      targetProgress: 7,
      unitLabel: 'يوم',
      icon: Icons.shield_moon_rounded,
      color: const Color(0xFF4338CA),
    ),
    AchievementBadge(
      id: 'evening_30',
      title: 'حارس الليل',
      subtitle: '30 يوم مساء',
      description: 'وسام الثبات على أذكار المساء شهراً متواصلاً.',
      howToUnlock:
          'حافظ على إتمام أذكار المساء كاملة كل يوم لمدة 30 يوماً متتالياً.',
      currentProgress: eveningStreak,
      targetProgress: 30,
      unitLabel: 'يوم',
      icon: Icons.auto_awesome_rounded,
      color: const Color(0xFF1D4ED8),
    ),
    AchievementBadge(
      id: 'tasbeeh_10000',
      title: 'سيد التسبيح',
      subtitle: '10000 تسبيحة',
      description: 'أعلى أوسمة التسبيح للذاكرين الله كثيراً.',
      howToUnlock:
          'واصل الذكر في المسبحة الإلكترونية حتى يتجاوز إجمالي تسبيحاتك 10,000 تسبيحة.',
      currentProgress: totalTasbeeh,
      targetProgress: 10000,
      unitLabel: 'تسبيحة',
      icon: Icons.workspace_premium_rounded,
      color: const Color(0xFFD97706),
    ),
  ];
}

void showAchievementDetailsDialog(
  BuildContext context,
  AchievementBadge badge,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final accent = context.primaryColor;
  final shownProgress =
      badge.currentProgress.clamp(0, badge.targetProgress);
  final percent = (badge.progressRatio * 100).round();

  showDialog<void>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: isDark ? const Color(0xFF141A1E) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: badge.color.withValues(alpha: badge.isUnlocked ? 0.16 : 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: badge.color.withValues(alpha: badge.isUnlocked ? 0.6 : 0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  badge.icon,
                  size: 34,
                  color: badge.isUnlocked
                      ? badge.color
                      : badge.color.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: badge.isUnlocked
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge.isUnlocked ? 'وسام مكتسب ✓' : 'قيد التقدم 🔒',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: badge.isUnlocked
                        ? const Color(0xFF10B981)
                        : (isDark ? Colors.amber.shade200 : Colors.amber.shade900),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                badge.title,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تقدّمك الحالي',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                        Text(
                          '$shownProgress / ${badge.targetProgress} ${badge.unitLabel} ($percent%)',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: badge.isUnlocked ? const Color(0xFF10B981) : accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: badge.progressRatio,
                        minHeight: 7,
                        backgroundColor: isDark
                            ? Colors.white10
                            : const Color(0xFFE2E8F0),
                        color: badge.isUnlocked ? const Color(0xFF10B981) : badge.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, size: 18, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'كيف تحصل على هذا الوسام؟',
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : accent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            badge.howToUnlock,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              height: 1.55,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.88)
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'حسناً',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
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

Widget buildAchievementBadgeCard(
  BuildContext context,
  AchievementBadge badge,
  bool isDark,
) {
  return InkWell(
    onTap: () {
      HapticFeedback.selectionClick();
      showAchievementDetailsDialog(context, badge);
    },
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badge.isUnlocked
              ? badge.color
              : Colors.grey.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: badge.isUnlocked ? 1.0 : 0.28,
                  child: Icon(badge.icon, size: 34, color: badge.color),
                ),
                const SizedBox(height: 6),
                Text(
                  badge.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badge.isUnlocked
                        ? (isDark ? Colors.white : Colors.black87)
                        : Colors.grey,
                  ),
                ),
                Text(
                  badge.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 9.5,
                    color: badge.isUnlocked
                        ? (isDark ? Colors.white70 : Colors.black54)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Icon(
              badge.isUnlocked
                  ? Icons.check_circle_rounded
                  : Icons.lock_outline_rounded,
              size: 14,
              color: badge.isUnlocked
                  ? const Color(0xFF10B981)
                  : Colors.grey.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    ),
  );
}

class AchievementsScreen extends StatefulWidget {
  final int totalTasbeeh;
  final int morningStreak;
  final int eveningStreak;
  final int sleepStreak;

  const AchievementsScreen({
    super.key,
    required this.totalTasbeeh,
    required this.morningStreak,
    required this.eveningStreak,
    required this.sleepStreak,
  });

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  int _filterIndex = 0; // 0: الكل, 1: الحاصل عليها, 2: المتبقية

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.primaryColor;
    final allBadges = buildAchievementBadges(
      totalTasbeeh: widget.totalTasbeeh,
      morningStreak: widget.morningStreak,
      eveningStreak: widget.eveningStreak,
      sleepStreak: widget.sleepStreak,
    );
    final unlockedCount = allBadges.where((b) => b.isUnlocked).length;
    final filtered = _filterIndex == 1
        ? allBadges.where((b) => b.isUnlocked).toList()
        : (_filterIndex == 2
            ? allBadges.where((b) => !b.isUnlocked).toList()
            : allBadges);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(
            'أوسمة الإنجاز',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: isDark ? const Color(0xFF0B131E) : accent,
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF0F2027), Color(0xFF203A43)]
                      : [accent, context.primaryDarkColor],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          color: Colors.amber, size: 30),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'حصلت على $unlockedCount من ${allBadges.length} وساماً',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: allBadges.isEmpty
                          ? 0
                          : unlockedCount / allBadges.length,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اضغط على أي وسام لمعرفة تقدمك وطريقة الحصول عليه.',
                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildFilterChip('الكل (${allBadges.length})', 0, accent, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('الحاصل عليها ($unlockedCount)', 1, accent, isDark),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'المتبقية (${allBadges.length - unlockedCount})',
                  2,
                  accent,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    _filterIndex == 1
                        ? 'لم تحصل على أي وسام بعد — ابدأ الآن وستصل قريباً بإذن الله!'
                        : 'ما شاء الله! حصلت على جميع الأوسمة المتاحة 🎉',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, index) => buildAchievementBadgeCard(
                  context,
                  filtered[index],
                  isDark,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index, Color accent, bool isDark) {
    final selected = _filterIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filterIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? accent
                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? accent
                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF334155)),
            ),
          ),
        ),
      ),
    );
  }
}
