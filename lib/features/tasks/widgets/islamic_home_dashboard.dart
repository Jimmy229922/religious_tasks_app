import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' as intl;

import 'package:religious_tasks_app/core/constants/app_constants.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/widgets/calendar_explorer_dialog.dart';
import 'package:religious_tasks_app/features/athkar/models/athkar_time_helper.dart';
import 'package:religious_tasks_app/features/athkar/screens/athkar_details_screen.dart';
import 'package:religious_tasks_app/features/happiness_jar/screens/happiness_jar_screen.dart';
import 'package:religious_tasks_app/features/prayers/screens/prayer_details_screen.dart';
import 'package:religious_tasks_app/features/quran/screens/quran_index_screen.dart';
import 'package:religious_tasks_app/features/settings/screens/settings_screen.dart';
import 'package:religious_tasks_app/features/tasks/models/task_item.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';
import 'package:religious_tasks_app/features/tasks/widgets/clock_dialog.dart';

class IslamicHomeDashboard extends StatefulWidget {
  final TasksViewModel vm;
  final ThemeProvider themeProvider;
  final bool isDark;
  final VoidCallback onOpenServicesTab;
  final void Function(TaskItem task) onOpenPrayerDetails;
  final void Function(TaskItem task) onTogglePrayerCompletion;
  final Widget? bottomWidget;

  const IslamicHomeDashboard({
    super.key,
    required this.vm,
    required this.themeProvider,
    required this.isDark,
    required this.onOpenServicesTab,
    required this.onOpenPrayerDetails,
    required this.onTogglePrayerCompletion,
    this.bottomWidget,
  });

  @override
  State<IslamicHomeDashboard> createState() => _IslamicHomeDashboardState();
}

class _IslamicHomeDashboardState extends State<IslamicHomeDashboard> {
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldLight = Color(0xFFFDE68A);
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  DateTime? _prayerDateTime(TaskItem task, PrayerTimes? times) {
    if (times == null) return null;
    if (task.name.contains(kPrayerFajr)) return times.fajr;
    if (task.name.contains(kPrayerDhuhr)) return times.dhuhr;
    if (task.name.contains(kPrayerAsr)) return times.asr;
    if (task.name.contains(kPrayerMaghrib)) return times.maghrib;
    if (task.name.contains(kPrayerIsha)) return times.isha;
    return null;
  }

  String _formatCountdownArabic(DateTime? target) {
    if (target == null) return 'جاري الحساب...';
    final diff = target.difference(_now);
    final safe = diff.isNegative ? Duration.zero : diff;
    final h = safe.inHours;
    final m = safe.inMinutes % 60;
    final s = safe.inSeconds % 60;
    if (h > 0) {
      return 'بعد $h ساعة و $m دقيقة و $s ثانية';
    }
    return 'بعد $m دقيقة و $s ثانية';
  }

  String _shortCountdown(TaskItem task) {
    final dt = _prayerDateTime(task, widget.vm.prayerTimes);
    if (dt == null) return '--:--:--';
    final target = dt.isBefore(_now) ? dt.add(const Duration(days: 1)) : dt;
    final diff = target.difference(_now);
    final safe = diff.isNegative ? Duration.zero : diff;
    final h = safe.inHours.toString().padLeft(2, '0');
    final m = (safe.inMinutes % 60).toString().padLeft(2, '0');
    final s = (safe.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final isDark = widget.isDark;
    final accent = context.primaryColor;
    final hijri = HijriCalendar.now();
    final hijriStr = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} هـ';
    final timeStr = intl.DateFormat('hh:mm a', 'ar').format(_now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDomeHeader(context, isDark, accent),
        const SizedBox(height: 10),
        _buildLocationDateBar(context, vm, isDark, accent, timeStr, hijriStr),
        const SizedBox(height: 12),
        _buildNextPrayerHeroCard(context, vm, isDark, accent),
        const SizedBox(height: 14),
        if (vm.prayerTasks.isNotEmpty) ...[
          _buildSectionOrnamentHeader('مواقيت الصلاة', isDark, accent),
          const SizedBox(height: 10),
          _buildArchedPrayersRow(context, vm, isDark, accent),
          const SizedBox(height: 16),
        ],
        _buildSpotlightThreeCards(context, isDark, accent),
        const SizedBox(height: 12),
        _buildMoreServicesButton(context, isDark, accent),
        if (widget.bottomWidget != null) ...[
          const SizedBox(height: 14),
          widget.bottomWidget!,
        ],
      ],
    );
  }

  Widget _buildDomeHeader(BuildContext context, bool isDark, Color accent) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _SeamlessIslamicArchPainter(
                  isDark: isDark,
                  gold: _gold,
                  goldLight: _goldLight,
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 50,
            child: _buildHangingLantern(isDark, height: 66),
          ),
          Positioned(
            top: 20,
            left: 50,
            child: _buildHangingLantern(isDark, height: 66),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCircleIconBtn(
                  icon: Icons.settings_outlined,
                  tooltip: 'الإعدادات',
                  isDark: isDark,
                  accent: accent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _gold.withValues(alpha: isDark ? 0.8 : 0.9),
                              width: 1.6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _gold.withValues(
                                    alpha: isDark ? 0.25 : 0.22),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              isDark
                                  ? 'assets/icon/app_icon_dark.jpg'
                                  : 'assets/icon/app_icon_light.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          kAppName,
                          style: GoogleFonts.arefRuqaa(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            color: isDark ? _goldLight : const Color(0xFF0F3D3E),
                            shadows: isDark
                                ? [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildCircleIconBtn(
                  icon: isDark
                      ? Icons.wb_sunny_rounded
                      : Icons.nights_stay_rounded,
                  tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
                  isDark: isDark,
                  accent: accent,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.themeProvider.toggleTheme(!isDark);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHangingLantern(bool isDark, {double height = 66}) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(32, height),
        painter: _LanternPainter(
          gold: _gold,
          glow: isDark ? _goldLight : const Color(0xFFF59E0B),
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildCircleIconBtn({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.9),
            border: Border.all(
              color: _gold.withValues(alpha: isDark ? 0.45 : 0.6),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? _goldLight : accent,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDateBar(
    BuildContext context,
    TasksViewModel vm,
    bool isDark,
    Color accent,
    String timeStr,
    String hijriStr,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.appCardGradient,
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _gold.withValues(alpha: isDark ? 0.5 : 0.7),
          width: 1.2,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  vm.refreshLocation();
                },
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: isDark ? _goldLight : accent,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        vm.locationName,
                        maxLines: 3,
                        softWrap: true,
                        textAlign: TextAlign.start,
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          height: 1.35,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: isDark ? _goldLight : const Color(0xFF78350F),
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(
              color: _gold.withValues(alpha: 0.45),
              thickness: 1,
              width: 16,
            ),
            Expanded(
              child: InkWell(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const CalendarExplorerDialog(initialTab: 0),
                ),
                onLongPress: () => showDialog(
                  context: context,
                  builder: (_) =>
                      ProfessionalClockDialog(vm: vm, isDark: isDark),
                ),
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeStr,
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? _goldLight : context.primaryDarkColor,
                            ),
                          ),
                          Text(
                            hijriStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 17,
                      color: isDark ? _goldLight : const Color(0xFF78350F),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextPrayerHeroCard(
    BuildContext context,
    TasksViewModel vm,
    bool isDark,
    Color accent,
  ) {
    final nextName =
        vm.nextPrayerName.isNotEmpty ? vm.nextPrayerName : 'الفجر';
    final countdownText = _formatCountdownArabic(vm.nextPrayerTime);

    return InkWell(
      onTap: () {
        if (vm.nextPrayerName.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PrayerDetailsScreen(
                prayerName: vm.nextPrayerName,
                prayerTime: vm.nextPrayerTime,
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 138,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _gold.withValues(alpha: isDark ? 0.7 : 0.85),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: isDark ? 0.16 : 0.24),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          image: DecorationImage(
            image: AssetImage(
              isDark
                  ? 'assets/images/prayer_hero_dark.png'
                  : 'assets/images/prayer_hero_light.png',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.5),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.1),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.45),
                      Colors.white.withValues(alpha: 0.05),
                    ],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mosque_rounded,
                    size: 16,
                    color: isDark ? _goldLight : const Color(0xFF78350F),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'الصلاة القادمة',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? _goldLight : const Color(0xFF78350F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                nextName,
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.65),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hourglass_bottom_rounded,
                      size: 13.5,
                      color: isDark ? _goldLight : const Color(0xFFB45309),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      countdownText,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? _goldLight : const Color(0xFF78350F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionOrnamentHeader(String title, bool isDark, Color accent) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: _gold.withValues(alpha: 0.45),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mosque_rounded,
                size: 16,
                color: isDark ? _goldLight : accent,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? _goldLight : context.primaryDarkColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Divider(
            color: _gold.withValues(alpha: 0.45),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildArchedPrayersRow(
    BuildContext context,
    TasksViewModel vm,
    bool isDark,
    Color accent,
  ) {
    return Row(
      children: List.generate(vm.prayerTasks.length, (i) {
        final task = vm.prayerTasks[i];
        final isNext = vm.nextPrayerName.isNotEmpty &&
            task.name.contains(vm.nextPrayerName);
        final done = task.isCompleted;
        final dt = _prayerDateTime(task, vm.prayerTimes);
        final timeLabel =
            dt != null ? intl.DateFormat('hh:mm', 'ar').format(dt) : '--:--';
        final shortName = task.name.replaceFirst('صلاة ', '').trim();
        final countdown = _shortCountdown(task);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i == vm.prayerTasks.length - 1 ? 0 : 5,
            ),
            child: InkWell(
              onTap: () => widget.onOpenPrayerDetails(task),
              onLongPress: () {
                HapticFeedback.mediumImpact();
                widget.onTogglePrayerCompletion(task);
              },
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
                bottom: Radius.circular(14),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
                decoration: BoxDecoration(
                  gradient: isNext
                      ? LinearGradient(
                          colors: isDark
                              ? const [Color(0xFF92400E), Color(0xFFD4AF37)]
                              : const [Color(0xFFFDE68A), Color(0xFFE5B84B)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : LinearGradient(
                          colors: isDark
                              ? const [Color(0xFF0F2120), Color(0xFF0B161C)]
                              : const [Color(0xFFFFFDF8), Color(0xFFF9F2E1)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                    bottom: Radius.circular(14),
                  ),
                  border: Border.all(
                    color: isNext
                        ? _gold
                        : (done
                            ? const Color(0xFF10B981)
                            : _gold.withValues(alpha: isDark ? 0.35 : 0.5)),
                    width: isNext ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      done ? Icons.check_circle_rounded : Icons.mosque_rounded,
                      size: 15,
                      color: done
                          ? const Color(0xFF10B981)
                          : (isNext
                              ? (isDark ? Colors.white : const Color(0xFF78350F))
                              : (isDark ? _goldLight : accent)),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        shortName,
                        maxLines: 1,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isNext
                              ? (isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A))
                              : (isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        timeLabel,
                        maxLines: 1,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isNext
                              ? (isDark
                                  ? Colors.white
                                  : const Color(0xFF451A03))
                              : (isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          countdown,
                          maxLines: 1,
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isNext
                                ? (isDark
                                    ? _goldLight
                                    : const Color(0xFF78350F))
                                : (isDark
                                    ? _goldLight.withValues(alpha: 0.85)
                                    : const Color(0xFFB45309)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSpotlightThreeCards(
    BuildContext context,
    bool isDark,
    Color accent,
  ) {
    final isMorning = AthkarTimeHelper.isMorningWindow(_now);
    return Row(
      children: [
        Expanded(
          child: _buildGoldFeatureTile(
            context: context,
            title: 'القرآن الكريم',
            icon: Icons.menu_book_rounded,
            iconColor: isDark ? _goldLight : accent,
            imageAsset: isDark
                ? 'assets/images/quran_icon_dark.jpg'
                : 'assets/images/quran_icon_light.jpg',
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuranIndexScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildGoldFeatureTile(
            context: context,
            title: 'أذكار الصباح\nوالمساء',
            icon: isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
            iconColor: const Color(0xFFF59E0B),
            imageAsset: isDark
                ? 'assets/images/athkar_icon_dark.jpg'
                : 'assets/images/athkar_icon_light.jpg',
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AthkarDetailsScreen(
                  title: isMorning ? kAthkarMorning : kAthkarEvening,
                  isMorning: isMorning,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildGoldFeatureTile(
            context: context,
            title: 'برطمان\nالسعادة',
            icon: Icons.card_giftcard_rounded,
            iconColor: const Color(0xFFD97706),
            imageAsset: isDark
                ? 'assets/images/happiness_jar.jpg'
                : 'assets/images/happiness_jar_light.jpg',
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HappinessJarScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoldFeatureTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
    String? imageAsset,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 136,
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: context.appCardGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _gold.withValues(alpha: isDark ? 0.45 : 0.65),
            width: 1.2,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 8,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                child: imageAsset != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          imageAsset,
                          fit: BoxFit.contain,
                          cacheWidth: 360,
                        ),
                      )
                    : Center(
                        child: Icon(icon, size: 42, color: iconColor),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      height: 1.15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreServicesButton(
    BuildContext context,
    bool isDark,
    Color accent,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onOpenServicesTab();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFFFFDF7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _gold.withValues(alpha: isDark ? 0.35 : 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grid_view_rounded,
              size: 18,
              color: isDark ? _goldLight : accent,
            ),
            const SizedBox(width: 8),
            Text(
              'والمزيد من الخدمات والخصائص...',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? _goldLight : context.primaryDarkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeamlessIslamicArchPainter extends CustomPainter {
  final bool isDark;
  final Color gold;
  final Color goldLight;

  const _SeamlessIslamicArchPainter({
    required this.isDark,
    required this.gold,
    required this.goldLight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final outerArch = Path()
      ..moveTo(w * 0.08, h * 0.96)
      ..cubicTo(w * 0.08, h * 0.42, w * 0.28, h * 0.22, w * 0.5, h * 0.03)
      ..cubicTo(w * 0.72, h * 0.22, w * 0.92, h * 0.42, w * 0.92, h * 0.96);

    final innerArch = Path()
      ..moveTo(w * 0.13, h * 0.94)
      ..cubicTo(w * 0.13, h * 0.45, w * 0.31, h * 0.26, w * 0.5, h * 0.09)
      ..cubicTo(w * 0.69, h * 0.26, w * 0.87, h * 0.45, w * 0.87, h * 0.94);

    canvas.save();
    final spandrelClip = Path()
      ..addRect(Rect.fromLTWH(0, 0, w, h * 0.78))
      ..addPath(
        Path()
          ..moveTo(w * 0.08, h)
          ..cubicTo(w * 0.08, h * 0.42, w * 0.28, h * 0.22, w * 0.5, h * 0.03)
          ..cubicTo(w * 0.72, h * 0.22, w * 0.92, h * 0.42, w * 0.92, h)
          ..close(),
        Offset.zero,
      )
      ..fillType = PathFillType.evenOdd;
    canvas.clipPath(spandrelClip);

    final arabesquePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          gold.withValues(alpha: isDark ? 0.16 : 0.22),
          gold.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.78))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.95;

    const step = 20.0;
    for (double x = 0; x <= w + step; x += step) {
      for (double y = 0; y <= h * 0.78; y += step) {
        final diamond = Path()
          ..moveTo(x, y - 6.5)
          ..lineTo(x + 6.5, y)
          ..lineTo(x, y + 6.5)
          ..lineTo(x - 6.5, y)
          ..close();
        canvas.drawPath(diamond, arabesquePaint);
      }
    }
    canvas.restore();

    final archFadeShader = LinearGradient(
      colors: [
        goldLight.withValues(alpha: isDark ? 0.95 : 0.85),
        gold.withValues(alpha: isDark ? 0.8 : 0.75),
        gold.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.58, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final glowPaint = Paint()
      ..color = gold.withValues(alpha: isDark ? 0.18 : 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(outerArch, glowPaint);

    final outerStroke = Paint()
      ..shader = archFadeShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(outerArch, outerStroke);

    final innerStroke = Paint()
      ..shader = archFadeShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(innerArch, innerStroke);
  }

  @override
  bool shouldRepaint(covariant _SeamlessIslamicArchPainter oldDelegate) =>
      oldDelegate.isDark != isDark ||
      oldDelegate.gold != gold ||
      oldDelegate.goldLight != goldLight;
}

class _LanternPainter extends CustomPainter {
  final Color gold;
  final Color glow;
  final bool isDark;

  const _LanternPainter({
    required this.gold,
    required this.glow,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    const goldDeep = Color(0xFF92400E);
    const goldBright = Color(0xFFFEF3C7);

    final chainPaint = Paint()
      ..color = gold.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;
    for (double y = 0; y < h * 0.2; y += 4.2) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, y + 2), width: 2.2, height: 3.4),
        chainPaint,
      );
    }

    canvas.drawCircle(
      Offset(cx, h * 0.225),
      2.8,
      chainPaint..strokeWidth = 1.4,
    );

    final outerGlow = Paint()
      ..color = glow.withValues(alpha: isDark ? 0.3 : 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawCircle(Offset(cx, h * 0.57), w * 0.44, outerGlow);

    final domePath = Path()
      ..moveTo(cx, h * 0.25)
      ..quadraticBezierTo(cx + w * 0.24, h * 0.3, cx + w * 0.28, h * 0.39)
      ..lineTo(cx - w * 0.28, h * 0.39)
      ..quadraticBezierTo(cx - w * 0.24, h * 0.3, cx, h * 0.25)
      ..close();
    final domeShader = LinearGradient(
      colors: [goldBright, gold, goldDeep],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(cx - w * 0.28, h * 0.25, w * 0.56, h * 0.14));
    canvas.drawPath(domePath, Paint()..shader = domeShader);

    final collarRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - w * 0.33, h * 0.385, w * 0.66, h * 0.04),
      const Radius.circular(2),
    );
    canvas.drawRRect(collarRect, Paint()..shader = domeShader);

    final leftFacet = Path()
      ..moveTo(cx - w * 0.3, h * 0.425)
      ..lineTo(cx - w * 0.15, h * 0.425)
      ..lineTo(cx - w * 0.12, h * 0.74)
      ..lineTo(cx - w * 0.22, h * 0.74)
      ..close();
    final rightFacet = Path()
      ..moveTo(cx + w * 0.15, h * 0.425)
      ..lineTo(cx + w * 0.3, h * 0.425)
      ..lineTo(cx + w * 0.22, h * 0.74)
      ..lineTo(cx + w * 0.12, h * 0.74)
      ..close();
    final centerFacet = Path()
      ..moveTo(cx - w * 0.15, h * 0.425)
      ..lineTo(cx + w * 0.15, h * 0.425)
      ..lineTo(cx + w * 0.12, h * 0.74)
      ..lineTo(cx - w * 0.12, h * 0.74)
      ..close();

    final sideGlassPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          glow.withValues(alpha: 0.75),
          gold.withValues(alpha: 0.65),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(cx - w * 0.3, h * 0.42, w * 0.6, h * 0.32));
    canvas.drawPath(leftFacet, sideGlassPaint);
    canvas.drawPath(rightFacet, sideGlassPaint);

    final centerGlassPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.15),
        radius: 0.85,
        colors: [
          Colors.white,
          goldBright,
          glow,
        ],
      ).createShader(Rect.fromLTWH(cx - w * 0.15, h * 0.42, w * 0.3, h * 0.32));
    canvas.drawPath(centerFacet, centerGlassPaint);

    final flamePath = Path()
      ..moveTo(cx, h * 0.5)
      ..quadraticBezierTo(cx + 2.6, h * 0.58, cx, h * 0.64)
      ..quadraticBezierTo(cx - 2.6, h * 0.58, cx, h * 0.5)
      ..close();
    canvas.drawPath(
      flamePath,
      Paint()..color = const Color(0xFFFFFBEB),
    );

    final framePaint = Paint()
      ..color = goldDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawPath(leftFacet, framePaint);
    canvas.drawPath(rightFacet, framePaint);
    canvas.drawPath(centerFacet, framePaint..color = gold);

    final innerArch = Path()
      ..moveTo(cx - w * 0.11, h * 0.72)
      ..lineTo(cx - w * 0.11, h * 0.54)
      ..quadraticBezierTo(cx, h * 0.44, cx + w * 0.11, h * 0.54)
      ..lineTo(cx + w * 0.11, h * 0.72);
    canvas.drawPath(
      innerArch,
      Paint()
        ..color = goldDeep.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.95,
    );

    final baseRect1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - w * 0.25, h * 0.74, w * 0.5, h * 0.04),
      const Radius.circular(2),
    );
    final baseRect2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - w * 0.19, h * 0.78, w * 0.38, h * 0.04),
      const Radius.circular(2),
    );
    canvas.drawRRect(baseRect1, Paint()..shader = domeShader);
    canvas.drawRRect(baseRect2, Paint()..shader = domeShader);

    final finialPath = Path()
      ..moveTo(cx - w * 0.09, h * 0.82)
      ..lineTo(cx + w * 0.09, h * 0.82)
      ..lineTo(cx, h * 0.96)
      ..close();
    canvas.drawPath(finialPath, Paint()..color = gold);
    canvas.drawCircle(Offset(cx, h * 0.97), 1.6, Paint()..color = goldBright);
  }

  @override
  bool shouldRepaint(covariant _LanternPainter oldDelegate) =>
      oldDelegate.gold != gold ||
      oldDelegate.glow != glow ||
      oldDelegate.isDark != isDark;
}
