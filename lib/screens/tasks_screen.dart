import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:adhan/adhan.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../providers/athkar_view_model.dart';
import '../providers/tasks_view_model.dart';
import '../providers/theme_provider.dart';
import '../widgets/task_item_widget.dart';
import '../widgets/calendar_explorer_dialog.dart';

import 'athkar_details_screen.dart';
import 'custom_tasbeeh_screen.dart';
import 'prophet_prayers_screen.dart';
import 'settings_screen.dart';
import 'surah_kahf_screen.dart';
import 'qibla_screen.dart';
import 'khatmah_screen.dart';
import 'halqat_dhikr_screen.dart';

class TasksScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const TasksScreen({super.key, required this.themeProvider});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  Future<void> _handleRefresh(TasksViewModel vm, bool isDark) async {
    vm.refreshRandomContent();
    await vm.refreshLocation();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("تم تحديث البيانات"),
          backgroundColor: isDark ? Colors.tealAccent : Colors.teal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<TasksViewModel>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.bar_chart_rounded,
                            color: Colors.white),
                        onPressed: () =>
                            _showMotivationalStats(context, vm, isDark),
                      ),
                    ],
                    leading: IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: Colors.white),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen())),
                    ),
                    title: Text(
                      "رفيق مسلم",
                      style: GoogleFonts.arefRuqaa(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: Colors.white,
                      ),
                    ),
                    centerTitle: true,
                  ),
                ],
                body: RefreshIndicator(
                  onRefresh: () => _handleRefresh(vm, isDark),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                          child: _buildRingsAndDateHeader(context, vm, isDark)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              if (vm.activeEvent != null) ...[
                                _buildSmartEventBanner(vm.activeEvent!, isDark),
                                const SizedBox(height: 12),
                              ],
                              _buildContextAwareSuggestion(context, vm, isDark),
                              const SizedBox(height: 12),
                              _buildQuickAccessRow(context, vm, isDark),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                          child: _buildDailyInspiration(vm, isDark)),
                      if (vm.prayerTimes != null)
                        SliverToBoxAdapter(
                            child: _buildNextPrayerCountdownCard(vm, isDark)),
                      if (vm.prayerTasks.isNotEmpty) ...[
                        _buildSectionHeader("الصلوات المفروضة", isDark),
                        _buildTasksSliverList(
                            context, vm, vm.prayerTasks, isDark),
                      ],
                      if (vm.otherTasks.isNotEmpty) ...[
                        _buildSectionHeader("السنن والأذكار", isDark),
                        _buildTasksSliverList(
                            context, vm, vm.otherTasks, isDark),
                      ],
                      SliverToBoxAdapter(
                          child: _buildGratitudeSection(context, vm, isDark)),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildRingsAndDateHeader(
      BuildContext context, TasksViewModel vm, bool isDark) {
    final hijriDate = HijriCalendar.now();
    final hijriStr =
        "${hijriDate.hDay} ${hijriDate.longMonthName} ${hijriDate.hYear}";
    final gregorianStr =
        intl.DateFormat('d MMMM yyyy', 'ar').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Rings Section
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        _buildProfessionalClockDialog(context, vm, isDark),
                  );
                },
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: CustomPaint(
                    painter: _RingsPainter(
                      prayersProgress: vm.prayersProgress,
                      athkarProgress: vm.athkarProgress,
                      quranProgress: vm.quranProgress,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            intl.DateFormat('hh:mm')
                                .format(vm.now), // 12-hour format
                            style: GoogleFonts.ibmPlexMono(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 26, // Bigger font
                                shadows: [
                                  Shadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ]),
                          ),
                          Text(
                            intl.DateFormat('a', 'ar').format(vm.now), // AM/PM
                            style: GoogleFonts.cairo(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Date & Location Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("السلام عليكم",
                        style: GoogleFonts.cairo(
                            color: Colors.white70, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: Colors.tealAccent, size: 14),
                          const SizedBox(width: 4),
                          Text(vm.locationName,
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Weather Info Widget
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                vm.weatherInfo['temp'] ?? "",
                                style: GoogleFonts.ibmPlexMono(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.cloud_outlined,
                                  color: Colors.white70, size: 16),
                            ],
                          ),
                          if (vm.weatherInfo['advice'] != null)
                            Text(
                              vm.weatherInfo['advice']!,
                              style: GoogleFonts.cairo(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    InkWell(
                      onTap: () {
                        // Open Calendar
                        showDialog(
                          context: context,
                          builder: (context) =>
                              const CalendarExplorerDialog(initialTab: 0),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(gregorianStr,
                              style: GoogleFonts.glory(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(hijriStr,
                              style: GoogleFonts.arefRuqaa(
                                  color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Next Prayer Countdown (Optional Center Element)
          // If you want a countdown, you'd calculate it from vm.nextPrayerTime
          // For now, let's assume the rings are the main focus as requested.
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildGratitudeSection(
      BuildContext context, TasksViewModel vm, bool isDark) {
    // Pick from VM (randomized on refresh)
    final blessingOfDay = vm.currentBlessing.isEmpty
        ? "نعمة الإسلام" // Fallback if VM init delayed
        : vm.currentBlessing;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)]
              : [const Color(0xFFE0F7FA), const Color(0xFF80DEEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.volunteer_activism,
              size: 40, color: isDark ? Colors.white : Colors.teal[700]),
          const SizedBox(height: 12),
          Text(
            "الحمد لله",
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.teal[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "يا رب لك الحمد كما ينبغي لجلال وجهك وعظيم سلطانك",
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.teal[800],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.white60,
                borderRadius: BorderRadius.circular(12)),
            child: Text(
              "أشكرك يا ربي على $blessingOfDay",
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.teal[900],
              ),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSmartEventBanner(String event, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF5E35B1), // Deep Purple
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
          const SizedBox(height: 4),
          Text(
            event,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContextAwareSuggestion(
      BuildContext context, TasksViewModel vm, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            isDark ? Colors.teal.withValues(alpha: 0.2) : Colors.teal.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleSuggestionTap(context, vm),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.light_mode_outlined, color: Colors.teal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "مقترح لك الآن",
                        style:
                            GoogleFonts.cairo(fontSize: 10, color: Colors.teal),
                      ),
                      Text(
                        vm.suggestedAthkar,
                        style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.teal[900]),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.teal),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSuggestionTap(BuildContext context, TasksViewModel vm) {
    final text = vm.suggestedAthkar;
    if (text == kAthkarMorning) {
      _navigateToAthkar(context, vm, true);
    } else if (text == kAthkarEvening) {
      _navigateToAthkar(context, vm, false);
    } else if (text == "استغفر الله") {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CustomTasbeehScreen()));
    } else if (text == "أذكار النوم") {
      // Navigate to Sleep Athkar Details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AthkarDetailsScreen(
            title: "أذكار النوم",
            isMorning: false, // Use night styling
          ),
        ),
      );
    }
  }

  void _navigateToAthkar(
      BuildContext context, TasksViewModel vm, bool isMorning) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AthkarDetailsScreen(
                title: isMorning ? kAthkarMorning : kAthkarEvening,
                isMorning: isMorning))).then((result) {
      if (result == true) {
        final index = vm.tasks.indexWhere(
            (t) => t.name == (isMorning ? kAthkarMorning : kAthkarEvening));
        if (index != -1) {
          vm.toggleTask(index, completionValue: true);
        }
      }
    });
  }

  Widget _buildQuickAccessRow(
      BuildContext context, TasksViewModel vm, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickAccessItem(
            context,
            "القرآن الكريم",
            Icons.menu_book_rounded,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SurahKahfScreen())),
            isDark,
            Colors.amber,
          ),
          const SizedBox(width: 8),
          _buildQuickAccessItem(
            context,
            "التسبيح",
            Icons.fingerprint,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CustomTasbeehScreen())),
            isDark,
            Colors.purple,
          ),
          const SizedBox(width: 8),
          _buildQuickAccessItem(
            context,
            "القبلة",
            Icons.explore,
            () {
              final coords = vm.prayerTimes?.coordinates ??
                  Coordinates(21.4225, 39.8262); // Fallback to Makkah
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => QiblaScreen(coordinates: coords)));
            },
            isDark,
            Colors.teal,
          ),
          const SizedBox(width: 8),
          _buildQuickAccessItem(
            context,
            "التقويم",
            Icons.calendar_month,
            () => showDialog(
              context: context,
              builder: (context) => const CalendarExplorerDialog(initialTab: 0),
            ),
            isDark,
            Colors.blueGrey,
          ),
          const SizedBox(width: 8),
          _buildQuickAccessItem(
            context,
            "حلقة الذكر",
            Icons.groups,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HalqatDhikrScreen())),
            isDark,
            Colors.green,
          ),
          const SizedBox(width: 8),
          _buildQuickAccessItem(
            context,
            "متابع الختمة",
            Icons.bookmark_added,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const KhatmahScreen())),
            isDark,
            Colors.deepOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessItem(BuildContext context, String label,
      IconData icon, VoidCallback onTap, bool isDark, Color baseColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : baseColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color:
                  isDark ? Colors.white12 : baseColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isDark ? Colors.white : baseColor, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDailyInspiration(TasksViewModel vm, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFE0F2F1), // Teal 50
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.teal.shade100,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                "همسة اليوم",
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.teal[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "\"${vm.dailyInspiration}\"",
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              // Amiri is nice for Arabic quotes
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white : Colors.teal[900],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Row(
          children: [
            Container(
                width: 4,
                height: 20,
                color: Colors.teal,
                margin: const EdgeInsets.only(left: 8)),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSliverList(BuildContext context, TasksViewModel vm,
      List<dynamic> tasks, bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, localIndex) {
            // Need to find global index in vm.tasks to toggle correctly
            // This is a bit inefficient (searching), but lists are small.
            // Better: helper in VM to toggle by object or name.
            // For now, let's find the index in original list.
            final task = tasks[localIndex];
            final globalIndex = vm.tasks.indexOf(task);

            if (globalIndex == -1) return const SizedBox.shrink();

            return TaskItemWidget(
              task: task,
              index: globalIndex, // Pass global index for VM operations
              isDark: isDark,
              now: vm.now,
              prayerTimes: vm.prayerTimes,
              onTap: () => _handleTaskTap(context, vm, globalIndex, task),
              onIncrement: () => vm.incrementCounter(globalIndex),
            );
          },
          childCount: tasks.length,
        ),
      ),
    );
  }

  void _handleTaskTap(
      BuildContext context, TasksViewModel vm, int index, dynamic task) {
    if (task.name == kQuranWird) {
      final isFriday = vm.now.weekday == DateTime.friday;
      if (isFriday) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SurahKahfScreen()));
      } else {
        vm.toggleTask(index);
      }
    } else if (task.name.contains(kAthkarLabel)) {
      final isMorning = task.name.contains(kAthkarMorning);
      final isSleep = task.name.contains(kAthkarSleep);
      final title = isSleep
          ? kAthkarSleep
          : (isMorning ? kAthkarMorning : kAthkarEvening);

      Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      AthkarDetailsScreen(title: title, isMorning: isMorning)))
          .then((_) async {
        // Refresh status on return
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

        vm.toggleTask(index, completionValue: isComplete);
      });
    } else if (task.name.contains(kProphetPrayer)) {
      Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProphetPrayersScreen()))
          .then((_) async {
        final prefs = await SharedPreferences.getInstance();
        final count = prefs.getInt('prophet_prayer_counter') ?? 0;
        // Mark as completed only if target (e.g. 100 or 200) reached?
        // Or if count > 0?
        // Let's assume if user returns, we check if they did meaningful progress.
        // But better: Don't force true.
        // If count == 0, force false.
        // If count > 0, we can leave it or check target.
        // Let's rely on what the screen logic did, or just sync.

        // Fix: If count is 0, uncheck. If count >= task.targetCount, check.
        // Otherwise, leave as is (User might be in progress).
        if (count == 0) {
          vm.toggleTask(index, completionValue: false);
        } else if (count >= (task.targetCount ?? 200)) {
          vm.toggleTask(index, completionValue: true);
        }
      });
    } else if (task.name == kCustomWird) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CustomTasbeehScreen()));
    } else {
      vm.toggleTask(index);
    }
  }

  Widget _buildProfessionalClockDialog(
      BuildContext context, TasksViewModel vm, bool isDark) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: StreamBuilder(
        stream: Stream.periodic(const Duration(seconds: 1)),
        builder: (context, snapshot) {
          final now = DateTime.now();
          final hour = intl.DateFormat('hh', 'ar').format(now);
          final minute = intl.DateFormat('mm', 'ar').format(now);
          final second = intl.DateFormat('ss', 'ar').format(now);
          final amPm = intl.DateFormat('a', 'ar').format(now);

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: isDark
                      ? Colors.tealAccent.withValues(alpha: 0.3)
                      : Colors.teal.shade200,
                  width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "الوقت الآن",
                  style: GoogleFonts.cairo(
                    color: isDark ? Colors.white70 : Colors.teal[800],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                // Digital Clock Row
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDigitBox(hour, isDark),
                      _buildColon(isDark),
                      _buildDigitBox(minute, isDark),
                      _buildColon(isDark),
                      _buildDigitBox(second, isDark, isSeconds: true),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  amPm,
                  style: GoogleFonts.ibmPlexMono(
                    color: isDark ? Colors.tealAccent : Colors.teal[900],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: Text("إغلاق",
                      style: GoogleFonts.cairo(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNextPrayerCountdownCard(TasksViewModel vm, bool isDark) {
    if (vm.nextPrayerTime == null || vm.prayerTimes == null) {
      return const SizedBox.shrink();
    }

    final diff = vm.nextPrayerTime!.difference(vm.now);
    final duration = diff.isNegative ? Duration.zero : diff;

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    // Dynamic Gradient & Icon based on Next Prayer
    var nextPrayer = vm.prayerTimes!.nextPrayer();
    if (nextPrayer == Prayer.none) nextPrayer = Prayer.fajr;

    List<Color> gradientColors;
    IconData timeIcon;

    switch (nextPrayer) {
      case Prayer.fajr:
        gradientColors = [
          const Color(0xFF141E30),
          const Color(0xFF243B55)
        ]; // Deep Night
        timeIcon = Icons.nights_stay_rounded;
        break;
      case Prayer.sunrise:
        gradientColors = [
          const Color(0xFFcc2b5e),
          const Color(0xFF753a88)
        ]; // Purple Sunrise
        timeIcon = Icons.wb_twilight_rounded;
        break;
      case Prayer.dhuhr:
        gradientColors = [
          const Color(0xFF2980B9),
          const Color(0xFF6DD5FA)
        ]; // Blue Sky
        timeIcon = Icons.wb_sunny_rounded;
        break;
      case Prayer.asr:
        gradientColors = [
          const Color(0xFFFF8008),
          const Color(0xFFFFC837)
        ]; // Orange Afternoon
        timeIcon = Icons.wb_sunny_outlined;
        break;
      case Prayer.maghrib:
        gradientColors = [
          const Color(0xFF8E2DE2),
          const Color(0xFF4A00E0)
        ]; // Twilight Purple
        timeIcon = Icons.wb_twilight_sharp;
        break;
      case Prayer.isha:
        gradientColors = [
          const Color(0xFF0F2027),
          const Color(0xFF203A43),
          const Color(0xFF2C5364)
        ]; // Dark Night
        timeIcon = Icons.bedtime_rounded;
        break;
      default:
        gradientColors = [const Color(0xFF141E30), const Color(0xFF243B55)];
        timeIcon = Icons.access_time_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(timeIcon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "الصلاة القادمة",
                        style: GoogleFonts.cairo(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        vm.nextPrayerName,
                        style: GoogleFonts.arefRuqaa(
                          color: Colors.white,
                          fontSize: 24, // Increased font size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("الوقت المتبقي",
                      style: GoogleFonts.cairo(
                          color: Colors.white70, fontSize: 10)),
                  Text(
                    "$hours:$minutes:$seconds",
                    style: GoogleFonts.ibmPlexMono(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          // Progress Bar with custom styling
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("رحلتك اليومية",
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  Text(
                    "${(vm.progress * 100).toInt()}%",
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: vm.progress,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white, // Pure white for contrast
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 6,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDigitBox(String val, bool isDark, {bool isSeconds = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.black45 : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isSeconds
                ? Colors.redAccent.withValues(alpha: 0.5)
                : Colors.blueGrey.withValues(alpha: 0.2)),
      ),
      child: Text(
        val,
        style: GoogleFonts.ibmPlexMono(
          fontSize: isSeconds ? 24 : 32,
          fontWeight: FontWeight.bold,
          color: isSeconds
              ? (isDark ? Colors.redAccent : Colors.red[700])
              : (isDark ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildColon(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        ":",
        style: GoogleFonts.ibmPlexMono(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white38 : Colors.grey[400],
        ),
      ),
    );
  }

  void _showMotivationalStats(
      BuildContext context, TasksViewModel vm, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: isDark ? Colors.amberAccent : Colors.amber, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: Colors.amber, size: 50),
              const SizedBox(height: 16),
              Text(
                "أبطال الاستمرار",
                style: GoogleFonts.arefRuqaa(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              _buildStreakRow(
                  "أذكار الصباح", vm.morningStreak, Colors.orange, isDark),
              const SizedBox(height: 12),
              _buildStreakRow("أذكار المساء", vm.eveningStreak,
                  Colors.purpleAccent, isDark),
              const SizedBox(height: 12),
              _buildStreakRow(
                  "أذكار النوم", vm.sleepStreak, Colors.indigoAccent, isDark),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("استمر يا بطل",
                    style: GoogleFonts.cairo(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakRow(String title, int streak, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: GoogleFonts.cairo(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text("$streak",
                  style: GoogleFonts.ibmPlexMono(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 4),
              const Icon(Icons.local_fire_department,
                  color: Colors.redAccent, size: 18),
            ],
          )
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double prayersProgress;
  final double athkarProgress;
  final double quranProgress;

  _RingsPainter({
    required this.prayersProgress,
    required this.athkarProgress,
    required this.quranProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;
    const strokeWidth = 6.0;

    _drawRing(canvas, center, baseRadius, prayersProgress,
        const Color(0xFFFFD700), strokeWidth);
    _drawRing(canvas, center, baseRadius - 8, athkarProgress,
        const Color(0xFF00E676), strokeWidth);
    _drawRing(canvas, center, baseRadius - 16, quranProgress,
        const Color(0xFF00B0FF), strokeWidth);
  }

  void _drawRing(Canvas canvas, Offset center, double radius, double progress,
      Color color, double width) {
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) {
    return oldDelegate.prayersProgress != prayersProgress ||
        oldDelegate.athkarProgress != athkarProgress ||
        oldDelegate.quranProgress != quranProgress;
  }
}
