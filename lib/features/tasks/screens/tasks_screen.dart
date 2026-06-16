import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:religious_tasks_app/core/constants/app_constants.dart';
import 'package:religious_tasks_app/features/athkar/providers/athkar_view_model.dart';
import '../providers/tasks_view_model.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import '../widgets/task_item_widget.dart';

import '../widgets/header_section.dart';
import '../widgets/quick_access_section.dart';
import '../widgets/daily_inspiration_card.dart';
import '../widgets/prayer_countdown_card.dart';

import '../../athkar/screens/athkar_details_screen.dart';
import '../../tasbeeh/screens/custom_tasbeeh_screen.dart';
import '../../athkar/screens/prophet_prayers_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../athkar/screens/surah_kahf_screen.dart';
import '../../statistics/screens/statistics_screen.dart';

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
    // We use a Consumer here so only the main content rebuilds if needed,
    // but the Scaffold structure is stable.
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : null,
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Consumer<TasksViewModel>(
              builder: (context, vm, child) {
                return RefreshIndicator(
                  onRefresh: () => _handleRefresh(vm, isDark),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        floating: true,
                        pinned: true,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.bar_chart_rounded,
                                color: Colors.white),
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
                          kAppName,
                          style: GoogleFonts.arefRuqaa(
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                            color: Colors.white,
                          ),
                        ),
                        centerTitle: true,
                      ),
                      SliverToBoxAdapter(
                        child: RepaintBoundary(
                          child: HeaderSection(vm: vm, isDark: isDark),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (vm.activeEvent != null) ...[
                                      Expanded(
                                        flex: 4,
                                        child: _buildSmartEventBanner(
                                            vm.activeEvent!, isDark),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      flex: 6,
                                      child: _buildContextAwareSuggestion(
                                          context, vm, isDark),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              QuickAccessSection(vm: vm, isDark: isDark),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                          child: DailyInspirationCard(vm: vm, isDark: isDark)),
                      if (vm.prayerTimes != null)
                        SliverToBoxAdapter(
                            child: PrayerCountdownCard(vm: vm, isDark: isDark)),
                      SliverToBoxAdapter(
                          child: _buildDailyProgress(context, vm, isDark)),
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
                      if (vm.earnedBadges.isNotEmpty)
                        SliverToBoxAdapter(child: _buildBadgesSection(vm, isDark)),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildBadgesSection(TasksViewModel vm, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "أوسمتك المستحقة",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: vm.earnedBadges.map((badgeId) {
                String title = "";
                IconData icon = Icons.star;
                Color color = Colors.amber;

                if (badgeId == 'dhikr_1000') {
                  title = "الذاكر الـ 1000";
                  icon = Icons.auto_awesome;
                } else if (badgeId == 'streak_morning_7') {
                  title = "سبعيني الصباح";
                  icon = Icons.wb_sunny;
                  color = Colors.orange;
                }

                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        Icon(icon, color: color, size: 40),
                        const SizedBox(height: 4),
                        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGratitudeSection(
      BuildContext context, TasksViewModel vm, bool isDark) {
    final blessingOfDay = vm.currentBlessing.isEmpty
        ? "نعمة الإسلام"
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
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF5E35B1),
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AthkarDetailsScreen(
            title: "أذكار النوم",
            isMorning: false,
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
            final task = tasks[localIndex];
            // Get original index to avoid search if possible, or just pass the task object
            return TaskItemWidget(
              task: task,
              index: localIndex, 
              isDark: isDark,
              now: vm.now,
              prayerTimes: vm.prayerTimes,
              onTap: () {
                final globalIndex = vm.tasks.indexOf(task);
                if (globalIndex != -1) {
                  _handleTaskTap(context, vm, globalIndex, task);
                }
              },
              onIncrement: () {
                final globalIndex = vm.tasks.indexOf(task);
                if (globalIndex != -1) {
                  vm.incrementCounter(globalIndex);
                }
              },
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

  Widget _buildDailyProgress(
      BuildContext context, TasksViewModel vm, bool isDark) {
    final progress = vm.progress;
    final percent = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.teal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "إنجازك اليومي",
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$percent%",
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutExpo,
                    width: constraints.maxWidth * progress,
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.tealAccent, Colors.teal],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${vm.completedCount} من ${vm.totalCount} مهام مكتملة",
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
              if (progress == 1.0)
                const Text(
                  "ممتاز! 🎉",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
