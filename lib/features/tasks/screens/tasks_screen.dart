import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:religious_tasks_app/core/constants/app_constants.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/features/athkar/models/athkar_time_helper.dart';
import 'package:religious_tasks_app/features/athkar/providers/athkar_view_model.dart';
import '../models/task_item.dart';
import '../providers/tasks_view_model.dart';
import '../widgets/daily_inspiration_card.dart';
import '../widgets/header_section.dart';
import '../widgets/prayers_timeline_section.dart';
import '../widgets/quick_access_section.dart';
import '../widgets/task_item_widget.dart';

import '../../athkar/screens/athkar_details_screen.dart';
import '../../athkar/screens/prophet_prayers_screen.dart';
import '../../athkar/screens/qiyam_layl_screen.dart';
import '../../athkar/screens/surah_kahf_screen.dart';
import '../../happiness_jar/screens/happiness_jar_screen.dart';
import '../../prayers/screens/prayer_details_screen.dart';
import '../../quran/screens/khatmah_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../statistics/screens/statistics_screen.dart';
import '../../tasbeeh/screens/custom_tasbeeh_screen.dart';

class TasksScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const TasksScreen({super.key, required this.themeProvider});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  static const double _maxContentWidth = 1040.0;

  bool _showRemainingSunnahOnly = false;
  int _bottomInsightTab = 0; // 0: آية وهمسة اليوم, 1: واحة الشكر والامتنان

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFridaySurahKahfReminder();
    });
  }

  Future<void> _checkFridaySurahKahfReminder() async {
    if (!mounted || DateTime.now().weekday != DateTime.friday) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString(SurahKahfScreen.fridayDismissedDateKey);
      if (savedDate == SurahKahfScreen.todayDateKey()) return;
      if (!mounted) return;
      await _showFridaySurahKahfDialog(prefs);
    } catch (_) {}
  }

  Future<void> _showFridaySurahKahfDialog(SharedPreferences prefs) async {
    bool dontShowAgain = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.primaryColor;
    const gold = Color(0xFFD4AF37);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                  side: BorderSide(
                    color: gold.withValues(alpha: isDark ? 0.45 : 0.6),
                    width: 1.2,
                  ),
                ),
                backgroundColor:
                    isDark ? const Color(0xFF131D2B) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent, context.primaryDarkColor],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: isDark ? 0.18 : 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: gold.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          "جمعة مباركة ✨",
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "لا تنسَ قراءة سورة الكهف اليوم",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 17.5,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "«مَنْ قَرَأَ سُورَةَ الْكَهْفِ فِي يَوْمِ الْجُمُعَةِ أَضَاءَ لَهُ مِنَ النُّورِ مَا بَيْنَ الْجُمُعَتَيْنِ»",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 16,
                          height: 1.65,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setDialogState(() {
                            dontShowAgain = !dontShowAgain;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 9),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: dontShowAgain
                                  ? accent.withValues(alpha: 0.6)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: dontShowAgain
                                      ? accent
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: dontShowAgain
                                        ? accent
                                        : (isDark
                                            ? Colors.white54
                                            : const Color(0xFF94A3B8)),
                                    width: 1.8,
                                  ),
                                ),
                                child: dontShowAgain
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "عدم إظهار هذا التذكير مجدداً هذه الجمعة",
                                  style: GoogleFonts.cairo(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                if (dontShowAgain) {
                                  await prefs.setString(
                                    SurahKahfScreen.fridayDismissedDateKey,
                                    SurahKahfScreen.todayDateKey(),
                                  );
                                }
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white24
                                      : const Color(0xFFCBD5E1),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                "إلغاء",
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SurahKahfScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.auto_stories_rounded,
                                size: 18,
                              ),
                              label: Text(
                                "اقرأ الآن",
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _horizontalInset(double availableWidth) {
    final basePad = availableWidth < 360 ? 12.0 : 16.0;
    if (availableWidth <= _maxContentWidth + (basePad * 2)) {
      return basePad;
    }
    return (availableWidth - _maxContentWidth) / 2;
  }

  void _syncAthkarTaskCompletion(
    TasksViewModel vm,
    String taskName,
    bool isComplete,
  ) {
    if (!isComplete) return;
    final idx = vm.tasks.indexWhere((t) => t.name == taskName);
    if (idx != -1 && !vm.tasks[idx].isCompleted) {
      vm.toggleTask(idx, completionValue: true);
    }
  }

  Future<void> _handleRefresh(TasksViewModel vm) async {
    HapticFeedback.selectionClick();
    final athkarVm = Provider.of<AthkarViewModel>(context, listen: false);
    await Future.wait([
      vm.refreshAll(),
      athkarVm.loadDailyData(),
    ]);
    if (!mounted) return;
    _syncAthkarTaskCompletion(
      vm,
      kAthkarMorning,
      athkarVm.data.morning.isComplete,
    );
    _syncAthkarTaskCompletion(
      vm,
      kAthkarEvening,
      athkarVm.data.evening.isComplete,
    );
    _syncAthkarTaskCompletion(
      vm,
      kAthkarSleep,
      athkarVm.data.sleep.isComplete,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "تم تحديث كافة البيانات والمواقيت ✓",
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final iconColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Consumer<TasksViewModel>(
            builder: (context, vm, child) {
              final allSunnah = vm.otherTasks;
              final displayedSunnah = _showRemainingSunnahOnly
                  ? allSunnah.where((t) => !t.isCompleted).toList()
                  : allSunnah;

              return RefreshIndicator(
                onRefresh: () => _handleRefresh(vm),
                child: LayoutBuilder(
                  builder: (context, viewportConstraints) {
                    final screenWidth = viewportConstraints.maxWidth;
                    final hPad = _horizontalInset(screenWidth);
                    final isWide = screenWidth >= 720;

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverAppBar(
                          floating: true,
                          pinned: true,
                          backgroundColor: backgroundColor,
                          surfaceTintColor: Colors.transparent,
                          systemOverlayStyle: isDark
                              ? SystemUiOverlayStyle.light
                              : SystemUiOverlayStyle.dark,
                          elevation: 0,
                          leadingWidth: 56,
                          leading: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 10,
                              top: 6,
                              bottom: 6,
                            ),
                            child: _buildAppBarPillButton(
                              tooltip: "الإعدادات",
                              icon: Icons.settings_outlined,
                              iconColor: iconColor,
                              isDark: isDark,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              ),
                            ),
                          ),
                          actions: [
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                end: 10,
                                top: 6,
                                bottom: 6,
                              ),
                              child: _buildAppBarPillButton(
                                tooltip: "الإحصائيات",
                                icon: Icons.bar_chart_rounded,
                                iconColor: iconColor,
                                isDark: isDark,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StatisticsScreen(
                                      morningStreak: vm.morningStreak,
                                      eveningStreak: vm.eveningStreak,
                                      sleepStreak: vm.sleepStreak,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          title: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              kAppName,
                              style: GoogleFonts.arefRuqaa(
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                                color: iconColor,
                              ),
                            ),
                          ),
                          centerTitle: true,
                        ),

                        // 1. Unified Hero Dashboard
                        SliverToBoxAdapter(
                          child: RepaintBoundary(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
                              child: HeaderSection(vm: vm, isDark: isDark),
                            ),
                          ),
                        ),

                        // 2. Interactive Obligatory Prayers Strip right beneath Hero
                        if (vm.prayerTasks.isNotEmpty)
                          SliverToBoxAdapter(
                            child: RepaintBoundary(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                                child: _buildFramedSectionContainer(
                                  isDark: isDark,
                                  isNarrow: screenWidth < 360,
                                  header: _buildSectionHeaderRow(
                                    title: "الصلوات المفروضة",
                                    icon: Icons.mosque_rounded,
                                    trailingText:
                                        "${vm.prayerTasks.where((t) => t.isCompleted).length}/${vm.prayerTasks.length}",
                                    isDark: isDark,
                                  ),
                                  child: PrayersTimelineSection(
                                    vm: vm,
                                    prayerTasks: vm.prayerTasks,
                                    isDark: isDark,
                                    onOpenDetails: (task) {
                                      final idx = vm.tasks.indexOf(task);
                                      if (idx != -1) {
                                        _handleTaskTap(context, vm, idx, task);
                                      }
                                    },
                                    onToggleCompletion: (task) {
                                      final idx = vm.tasks.indexOf(task);
                                      if (idx != -1) {
                                        vm.toggleTask(idx);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // 3. Smart Event + Priority Context Suggestion
                        SliverToBoxAdapter(
                          child: RepaintBoundary(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                              child: _buildSuggestionArea(
                                context: context,
                                vm: vm,
                                isDark: isDark,
                                textScale: textScale,
                              ),
                            ),
                          ),
                        ),

                        // 4. Harmonized Quick Access Hub
                        SliverToBoxAdapter(
                          child: RepaintBoundary(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                              child: _buildFramedSectionContainer(
                                isDark: isDark,
                                isNarrow: screenWidth < 360,
                                header: _buildSectionHeaderRow(
                                  title: "الوصول السريع",
                                  icon: Icons.apps_rounded,
                                  isDark: isDark,
                                ),
                                child: QuickAccessSection(
                                  vm: vm,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 5. Interactive Sunnah & Athkar Cards with Filter Pill
                        if (allSunnah.isNotEmpty)
                          SliverToBoxAdapter(
                            child: RepaintBoundary(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                                child: _buildFramedSectionContainer(
                                  isDark: isDark,
                                  isNarrow: screenWidth < 360,
                                  header: _buildSunnahHeaderWidget(
                                    allTasks: allSunnah,
                                    isDark: isDark,
                                  ),
                                  child: displayedSunnah.isEmpty
                                      ? _buildAllSunnahDoneBanner(isDark)
                                      : _buildSunnahGridWidget(
                                          context: context,
                                          vm: vm,
                                          tasks: displayedSunnah,
                                          isDark: isDark,
                                          textScale: textScale,
                                        ),
                                ),
                              ),
                            ),
                          ),

                        // 6. Compact Bottom Switcher (Daily Inspiration | Gratitude Oasis) or Side-by-Side on Tablet
                        SliverToBoxAdapter(
                          child: RepaintBoundary(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                              child: _buildBottomInsightsArea(
                                context: context,
                                vm: vm,
                                isDark: isDark,
                                textScale: textScale,
                                isWide: isWide,
                              ),
                            ),
                          ),
                        ),

                        // 7. Earned Badges
                        if (vm.earnedBadges.isNotEmpty)
                          SliverToBoxAdapter(
                            child: RepaintBoundary(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                                child: _buildFramedSectionContainer(
                                  isDark: isDark,
                                  isNarrow: screenWidth < 360,
                                  header: _buildSectionHeaderRow(
                                    title: "أوسمتك المستحقة",
                                    icon: Icons.emoji_events_rounded,
                                    trailingText: "${vm.earnedBadges.length}",
                                    isDark: isDark,
                                  ),
                                  child: _buildBadgesSection(vm, isDark),
                                ),
                              ),
                            ),
                          ),

                        const SliverToBoxAdapter(child: SizedBox(height: 52)),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarPillButton({
    required String tooltip,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF172231)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : context.primaryColor.withValues(alpha: 0.24),
          width: 1.25,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: iconColor, size: 21),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildFramedSectionContainer({
    required bool isDark,
    required bool isNarrow,
    required Widget header,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(isNarrow ? 12 : 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101926) : const Color(0xFFFAFCFE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : const Color(0xFFCBD5E1),
          width: 1.35,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.035),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSunnahHeaderWidget({
    required List<TaskItem> allTasks,
    required bool isDark,
  }) {
    final accent = isDark ? const Color(0xFF2DD4BF) : context.primaryColor;
    final completed = allTasks.where((t) => t.isCompleted).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final stackFilter = constraints.maxWidth < 310 || textScale >= 1.2;

        final titleRow = Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accent.withValues(alpha: isDark ? 0.34 : 0.25),
                ),
              ),
              child: Icon(Icons.spa_rounded, size: 17, color: accent),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                "السنن والأذكار",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: accent.withValues(alpha: isDark ? 0.36 : 0.28),
                ),
              ),
              child: Text(
                "$completed/${allTasks.length}",
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
          ],
        );

        final filterPill = Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF172231) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : const Color(0xFFCBD5E1),
              width: 1.25,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterPill(
                label: "الكل",
                selected: !_showRemainingSunnahOnly,
                isDark: isDark,
                accent: accent,
                onTap: () => setState(() => _showRemainingSunnahOnly = false),
              ),
              _buildFilterPill(
                label: "المتبقي",
                selected: _showRemainingSunnahOnly,
                isDark: isDark,
                accent: accent,
                onTap: () => setState(() => _showRemainingSunnahOnly = true),
              ),
            ],
          ),
        );

        if (stackFilter) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleRow,
              const SizedBox(height: 8),
              filterPill,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: titleRow),
            const SizedBox(width: 8),
            filterPill,
          ],
        );
      },
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool selected,
    required bool isDark,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? context.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildAllSunnahDoneBanner(bool isDark) {
    final accent = isDark ? const Color(0xFF2DD4BF) : context.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172231) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.45 : 0.38),
          width: 1.35,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.verified_rounded, color: accent, size: 32),
          const SizedBox(height: 8),
          Text(
            "ما شاء الله! أتممت جميع السنن والأذكار اليوم 🎉",
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _showRemainingSunnahOnly = false),
            child: Text(
              "عرض جميع المهام",
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInsightsArea({
    required BuildContext context,
    required TasksViewModel vm,
    required bool isDark,
    required double textScale,
    required bool isWide,
  }) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DailyInspirationCard(vm: vm, isDark: isDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildGratitudeSection(context, vm, isDark, textScale),
          ),
        ],
      );
    }

    final accent = isDark ? const Color(0xFF2DD4BF) : context.primaryColor;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF172231) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.16)
                  : const Color(0xFFCBD5E1),
              width: 1.3,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildBottomTabButton(
                  label: "آية وهمسة اليوم",
                  icon: Icons.menu_book_rounded,
                  selected: _bottomInsightTab == 0,
                  isDark: isDark,
                  accent: accent,
                  onTap: () => setState(() => _bottomInsightTab = 0),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildBottomTabButton(
                  label: "واحة الشكر",
                  icon: Icons.volunteer_activism_rounded,
                  selected: _bottomInsightTab == 1,
                  isDark: isDark,
                  accent: accent,
                  onTap: () => setState(() => _bottomInsightTab = 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: _bottomInsightTab == 0
              ? KeyedSubtree(
                  key: const ValueKey('daily_inspiration_tab'),
                  child: DailyInspirationCard(vm: vm, isDark: isDark),
                )
              : KeyedSubtree(
                  key: const ValueKey('gratitude_oasis_tab'),
                  child: _buildGratitudeSection(context, vm, isDark, textScale),
                ),
        ),
      ],
    );
  }

  Widget _buildBottomTabButton({
    required String label,
    required IconData icon,
    required bool selected,
    required bool isDark,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? context.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionArea({
    required BuildContext context,
    required TasksViewModel vm,
    required bool isDark,
    required double textScale,
  }) {
    final activeEvent = vm.activeEvent;
    if (activeEvent == null) {
      return _buildContextAwareSuggestion(context, vm, isDark);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520 || textScale >= 1.2) {
          return Column(
            children: [
              _buildSmartEventBanner(activeEvent, isDark),
              const SizedBox(height: 10),
              _buildContextAwareSuggestion(context, vm, isDark),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: _buildSmartEventBanner(activeEvent, isDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: _buildContextAwareSuggestion(context, vm, isDark),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSunnahGridWidget({
    required BuildContext context,
    required TasksViewModel vm,
    required List<TaskItem> tasks,
    required bool isDark,
    required double textScale,
  }) {
    Widget buildCard(TaskItem task, int localIndex) {
      return TaskItemWidget(
        task: task,
        index: localIndex,
        isDark: isDark,
        now: vm.now,
        prayerTimes: vm.prayerTimes,
        prayerTimesTomorrow: vm.tomorrowPrayerTimes,
        compactGridCard: true,
        onTap: () {
          final globalIndex = vm.tasks.indexOf(task);
          if (globalIndex != -1) {
            _handleTaskTap(context, vm, globalIndex, task);
          }
        },
        onToggle: () {
          final globalIndex = vm.tasks.indexOf(task);
          if (globalIndex != -1) {
            vm.toggleTask(globalIndex);
          }
        },
        onIncrement: () {
          final globalIndex = vm.tasks.indexOf(task);
          if (globalIndex != -1) {
            vm.incrementCounter(globalIndex);
          }
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns;
        if (constraints.maxWidth < 305 || textScale >= 1.25) {
          columns = 1;
        } else if (constraints.maxWidth >= 660) {
          columns = 3;
        } else {
          columns = 2;
        }

        if (columns == 1) {
          return Column(
            children: [
              for (int idx = 0; idx < tasks.length; idx++) ...[
                TaskItemWidget(
                  task: tasks[idx],
                  index: idx,
                  isDark: isDark,
                  now: vm.now,
                  prayerTimes: vm.prayerTimes,
                  prayerTimesTomorrow: vm.tomorrowPrayerTimes,
                  compactGridCard: false,
                  onTap: () {
                    final globalIndex = vm.tasks.indexOf(tasks[idx]);
                    if (globalIndex != -1) {
                      _handleTaskTap(context, vm, globalIndex, tasks[idx]);
                    }
                  },
                  onToggle: () {
                    final globalIndex = vm.tasks.indexOf(tasks[idx]);
                    if (globalIndex != -1) {
                      vm.toggleTask(globalIndex);
                    }
                  },
                  onIncrement: () {
                    final globalIndex = vm.tasks.indexOf(tasks[idx]);
                    if (globalIndex != -1) {
                      vm.incrementCounter(globalIndex);
                    }
                  },
                ),
                if (idx < tasks.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        final rowCount = (tasks.length / columns).ceil();
        return Column(
          children: [
            for (int rowIndex = 0; rowIndex < rowCount; rowIndex++) ...[
              Builder(
                builder: (context) {
                  final start = rowIndex * columns;
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int col = 0; col < columns; col++) ...[
                          Expanded(
                            child: (start + col) < tasks.length
                                ? buildCard(tasks[start + col], start + col)
                                : const SizedBox.shrink(),
                          ),
                          if (col < columns - 1) const SizedBox(width: 10),
                        ],
                      ],
                    ),
                  );
                },
              ),
              if (rowIndex < rowCount - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBadgesSection(TasksViewModel vm, bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: vm.earnedBadges.map((badgeId) {
        String title = "";
        IconData icon = Icons.star_rounded;
        Color color = Colors.amber;

        if (badgeId == 'dhikr_1000') {
          title = "الذاكر الـ 1000";
          icon = Icons.emoji_events_rounded;
        } else if (badgeId == 'streak_morning_7') {
          title = "سبعيني الصباح";
          icon = Icons.wb_sunny_rounded;
          color = Colors.orange;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF172231) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.50 : 0.45),
              width: 1.3,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGratitudeSection(
    BuildContext context,
    TasksViewModel vm,
    bool isDark,
    double textScale,
  ) {
    final blessingOfDay =
        vm.currentBlessing.isEmpty ? "نعمة الإسلام والهداية" : vm.currentBlessing;
    final accent = isDark ? const Color(0xFF2DD4BF) : context.primaryColor;
    const gold = Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0F292E), Color(0xFF162231)]
              : const [Color(0xFFECFDF5), Color(0xFFF0FDFA)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.50 : 0.36),
          width: 1.45,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrowHeader =
              constraints.maxWidth < 330 || textScale >= 1.25;
          final sideBySideButtons =
              constraints.maxWidth >= 460 && textScale < 1.2;

          final countChip = Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: gold.withValues(alpha: 0.58),
                width: 1.15,
              ),
            ),
            child: Text(
              "${vm.gratitudeCount} حمداً",
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.amberAccent : const Color(0xFFB45309),
              ),
            ),
          );

          final praiseBtn = ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              vm.incrementGratitude();
            },
            icon: const Icon(Icons.favorite_rounded, size: 18),
            label: Text(
              "قل: الحمد لله 🤲",
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );

          final jarBtn = OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HappinessJarScreen(),
              ),
            ),
            icon: const Icon(Icons.card_giftcard_rounded, size: 18, color: gold),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "افتح برطمان السعادة 💛",
                style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.amberAccent : const Color(0xFFB45309),
                ),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              side: BorderSide(
                color: gold.withValues(alpha: 0.72),
                width: 1.35,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );

          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.volunteer_activism_rounded,
                      size: 22,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "واحة الشكر والامتنان",
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ",
                          style: GoogleFonts.amiri(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isNarrowHeader) ...[
                    const SizedBox(width: 8),
                    countChip,
                  ],
                ],
              ),
              if (isNarrowHeader) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: countChip,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                "يا رب لك الحمد كما ينبغي لجلال وجهك وعظيم سلطانك",
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  fontSize: 17.5,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.92)
                      : const Color(0xFF134E4A),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.26)
                      : Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.34 : 0.28),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "نعمة نتذكرها الآن:",
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "أشكرك يا ربي على $blessingOfDay",
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: "تغيير النعمة",
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        vm.cycleBlessing();
                      },
                      icon: Icon(Icons.refresh_rounded, color: accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (sideBySideButtons)
                Row(
                  children: [
                    Expanded(child: praiseBtn),
                    const SizedBox(width: 10),
                    Expanded(child: jarBtn),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    praiseBtn,
                    const SizedBox(height: 8),
                    jarBtn,
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSmartEventBanner(String event, bool isDark) {
    final accent = isDark ? const Color(0xFF2DD4BF) : context.primaryColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132230) : const Color(0xFFF0FDF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.40 : 0.32),
          width: 1.3,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.stars_rounded,
            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFD97706),
            size: 19,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              event,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextAwareSuggestion(
      BuildContext context, TasksViewModel vm, bool isDark) {
    final suggestion = vm.activeContextSuggestion;
    final accent = isDark ? const Color(0xFF2DD4BF) : context.primaryColor;
    final badgeAccent = suggestion.accentColor;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172231) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? accent.withValues(alpha: 0.42)
              : const Color(0xFFCBD5E1),
          width: 1.35,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _handleSuggestionTap(context, vm, suggestion),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                final compact = constraints.maxWidth < 310 || textScale >= 1.25;

                final openBadge = Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "افتح",
                        style: GoogleFonts.cairo(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ],
                  ),
                );

                final cycleButton = IconButton(
                  tooltip: "عرض اقتراح آخر",
                  visualDensity: VisualDensity.compact,
                  onPressed: vm.cycleContextSuggestion,
                  icon: Icon(
                    Icons.autorenew_rounded,
                    size: 18,
                    color: isDark ? Colors.white70 : accent,
                  ),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: badgeAccent.withValues(
                                alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: badgeAccent.withValues(
                                  alpha: isDark ? 0.34 : 0.24),
                            ),
                          ),
                          child: Icon(
                            suggestion.icon,
                            color: isDark ? Colors.white : badgeAccent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(
                                      alpha: isDark ? 0.2 : 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: accent.withValues(
                                        alpha: isDark ? 0.32 : 0.22),
                                  ),
                                ),
                                child: Text(
                                  "مقترح لك الآن • ${suggestion.categoryLabel}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: accent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  suggestion.title,
                                  maxLines: 1,
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                suggestion.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 4),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              cycleButton,
                              openBadge,
                            ],
                          ),
                        ],
                      ],
                    ),
                    if (compact) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          cycleButton,
                          const SizedBox(width: 6),
                          openBadge,
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleSuggestionTap(
    BuildContext context,
    TasksViewModel vm,
    ContextSuggestion suggestion,
  ) {
    switch (suggestion.action) {
      case ContextSuggestionAction.prayer:
        final prayerName = suggestion.prayerName ?? suggestion.title;
        final taskIndex = vm.tasks.indexWhere((t) =>
            t.name == prayerName ||
            t.name.contains(prayerName.replaceFirst('صلاة ', '')));
        final isCompleted =
            taskIndex != -1 ? vm.tasks[taskIndex].isCompleted : false;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PrayerDetailsScreen(
              prayerName: prayerName,
              prayerTime: suggestion.prayerTime,
              isCompleted: isCompleted,
              onToggleCompletion: () {
                if (taskIndex != -1) {
                  vm.toggleTask(taskIndex);
                }
              },
            ),
          ),
        );
      case ContextSuggestionAction.morningAthkar:
        _navigateToAthkar(context, vm, true);
      case ContextSuggestionAction.eveningAthkar:
        _navigateToAthkar(context, vm, false);
      case ContextSuggestionAction.sleepAthkar:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AthkarDetailsScreen(
              title: kAthkarSleep,
              isMorning: false,
            ),
          ),
        ).then((_) async {
          if (!context.mounted) return;
          final athkarVM =
              Provider.of<AthkarViewModel>(context, listen: false);
          await athkarVM.loadDailyData();
          final idx = vm.tasks.indexWhere((t) => t.name == kAthkarSleep);
          if (idx != -1 && athkarVM.data.sleep.isComplete) {
            vm.toggleTask(idx, completionValue: true);
          }
        });
      case ContextSuggestionAction.qiyam:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QiyamLaylScreen()),
        );
      case ContextSuggestionAction.surahKahf:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SurahKahfScreen()),
        );
      case ContextSuggestionAction.khatmah:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KhatmahScreen()),
        );
      case ContextSuggestionAction.tasbeeh:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomTasbeehScreen()),
        );
      case ContextSuggestionAction.prophetPrayer:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProphetPrayersScreen()),
        ).then((_) async {
          if (!context.mounted) return;
          final prefs = await SharedPreferences.getInstance();
          final count = prefs.getInt('prophet_prayer_counter') ?? 0;
          final idx = vm.tasks.indexWhere((t) => t.name == kProphetPrayer);
          if (idx != -1) {
            vm.toggleTask(idx, completionValue: count >= 100);
          }
        });
      case ContextSuggestionAction.happinessJar:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HappinessJarScreen()),
        );
    }
  }

  void _navigateToAthkar(
      BuildContext context, TasksViewModel vm, bool isMorning) {
    final now = DateTime.now();
    final isActive = isMorning
        ? AthkarTimeHelper.isMorningWindow(now)
        : AthkarTimeHelper.isEveningWindow(now);

    if (isActive) {
      _openAthkarScreen(context, vm, isMorning);
    } else {
      AthkarTimeHelper.showInactiveTimeDialog(
        context: context,
        isMorning: isMorning,
        onProceedAnyway: () => _openAthkarScreen(context, vm, isMorning),
        onSwitchToActive: () => _openAthkarScreen(context, vm, !isMorning),
      );
    }
  }

  void _openAthkarScreen(
      BuildContext context, TasksViewModel vm, bool isMorning) {
    final title = isMorning ? kAthkarMorning : kAthkarEvening;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AthkarDetailsScreen(
          title: title,
          isMorning: isMorning,
        ),
      ),
    ).then((_) async {
      if (!context.mounted) return;
      final athkarVM = Provider.of<AthkarViewModel>(context, listen: false);
      await athkarVM.loadDailyData();
      final isComplete = isMorning
          ? athkarVM.data.morning.isComplete
          : athkarVM.data.evening.isComplete;
      final index = vm.tasks.indexWhere((t) => t.name == title);
      if (index != -1) {
        vm.toggleTask(index, completionValue: isComplete);
      }
    });
  }

  Widget _buildSectionHeaderRow({
    required String title,
    required IconData icon,
    required bool isDark,
    String? trailingText,
  }) {
    final accent = isDark ? const Color(0xFF2DD4BF) : context.primaryColor;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.34 : 0.25),
            ),
          ),
          child: Icon(icon, size: 17, color: accent),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
        if (trailingText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: accent.withValues(alpha: isDark ? 0.36 : 0.28),
              ),
            ),
            child: Text(
              trailingText,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ),
      ],
    );
  }

  void _handleTaskTap(
      BuildContext context, TasksViewModel vm, int index, dynamic task) {
    if (task.name == kPrayerFajr ||
        task.name == kPrayerDhuhr ||
        task.name == kPrayerAsr ||
        task.name == kPrayerMaghrib ||
        task.name == kPrayerIsha ||
        task.name.contains('الفجر') ||
        task.name.contains('الظهر') ||
        task.name.contains('العصر') ||
        task.name.contains('المغرب') ||
        task.name.contains('العشاء')) {
      DateTime? pTime;
      if (vm.prayerTimes != null) {
        if (task.name.contains(kPrayerFajr)) {
          pTime = vm.prayerTimes!.fajr;
        } else if (task.name.contains(kPrayerDhuhr)) {
          pTime = vm.prayerTimes!.dhuhr;
        } else if (task.name.contains(kPrayerAsr)) {
          pTime = vm.prayerTimes!.asr;
        } else if (task.name.contains(kPrayerMaghrib)) {
          pTime = vm.prayerTimes!.maghrib;
        } else if (task.name.contains(kPrayerIsha)) {
          pTime = vm.prayerTimes!.isha;
        }
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrayerDetailsScreen(
            prayerName: task.name,
            prayerTime: pTime,
            isCompleted: task.isCompleted,
            onToggleCompletion: () => vm.toggleTask(index),
          ),
        ),
      );
    } else if (task.name == kQuranWird) {
      vm.toggleTask(index);
    } else if (task.name.contains(kAthkarLabel)) {
      final isMorning = task.name.contains(kAthkarMorning);
      final isSleep = task.name.contains(kAthkarSleep);
      final title = isSleep
          ? kAthkarSleep
          : (isMorning ? kAthkarMorning : kAthkarEvening);

      final now = DateTime.now();
      final isActive = isSleep ||
          (isMorning
              ? AthkarTimeHelper.isMorningWindow(now)
              : AthkarTimeHelper.isEveningWindow(now));

      if (isActive) {
        _openAthkarDetailsAndSync(context, vm, title, isMorning, isSleep);
      } else {
        AthkarTimeHelper.showInactiveTimeDialog(
          context: context,
          isMorning: isMorning,
          onProceedAnyway: () => _openAthkarDetailsAndSync(
              context, vm, title, isMorning, isSleep),
          onSwitchToActive: () => _openAthkarDetailsAndSync(context, vm,
              isMorning ? kAthkarEvening : kAthkarMorning, !isMorning, false),
        );
      }
    } else if (task.name.contains(kProphetPrayer)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProphetPrayersScreen()),
      ).then((_) async {
        final prefs = await SharedPreferences.getInstance();
        final count = prefs.getInt('prophet_prayer_counter') ?? 0;
        vm.updateProphetPrayerCount(count);
      });
    } else if (task.name == kCustomWird) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CustomTasbeehScreen()),
      );
    } else if (task.name.contains(kPrayerQiyam) || task.name.contains('قيام')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QiyamLaylScreen()),
      );
    } else {
      vm.toggleTask(index);
    }
  }

  void _openAthkarDetailsAndSync(BuildContext context, TasksViewModel vm,
      String title, bool isMorning, bool isSleep) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AthkarDetailsScreen(title: title, isMorning: isMorning),
      ),
    ).then((_) async {
      if (!context.mounted) return;
      final athkarVM = Provider.of<AthkarViewModel>(context, listen: false);
      await athkarVM.loadDailyData();

      bool isComplete = false;
      if (isSleep) {
        isComplete = athkarVM.data.sleep.isComplete;
      } else if (isMorning) {
        isComplete = athkarVM.data.morning.isComplete;
      } else {
        isComplete = athkarVM.data.evening.isComplete;
      }

      final taskIndex = vm.tasks.indexWhere((t) => t.name == title);
      if (taskIndex != -1) {
        vm.toggleTask(taskIndex, completionValue: isComplete);
      }
    });
  }
}
