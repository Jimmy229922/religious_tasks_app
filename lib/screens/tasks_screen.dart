import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:adhan/adhan.dart';

import '../constants/app_constants.dart';
import '../constants/strings.dart';
import '../providers/tasks_view_model.dart';
import '../providers/theme_provider.dart';
import '../widgets/task_item_widget.dart';
import '../widgets/calendar_explorer_dialog.dart';

import 'athkar_details_screen.dart';
import 'custom_tasbeeh_screen.dart';
import 'guided_tasbeeh_screen.dart';
import 'prophet_prayers_screen.dart';
import 'qibla_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'surah_kahf_screen.dart';

class TasksScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const TasksScreen({super.key, required this.themeProvider});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  void _showSuccessOverlay(BuildContext context, bool isDark) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height *
            0.2, // Show a bit down from top
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: value,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF64FFDA)
                            : const Color(0xFF009688),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: isDark ? Colors.black : Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            "تم تحديث المحتوى بنجاح",
                            style: GoogleFonts.cairo(
                              color: isDark ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (overlayEntry != null) {
        try {
          overlayEntry?.remove();
          overlayEntry = null;
        } catch (_) {}
      }
    });
  }

  Future<void> _handleRefresh(TasksViewModel vm, bool isDark) async {
    vm.refreshRandomContent();
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      _showSuccessOverlay(context, isDark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<TasksViewModel>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // 1. Sliver App Bar with Title & Settings
              SliverAppBar(
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor:
                    isDark ? const Color(0xFF1A1F26) : Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                title: Text(
                  AppStrings.appName,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.teal[800],
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.bar_chart_rounded),
                    tooltip: AppStrings.stats,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => StatisticsScreen(
                                morningStreak: vm.morningStreak,
                                eveningStreak: vm.eveningStreak,
                                sleepStreak: vm.sleepStreak,
                              )),
                    ),
                  )
                ],
              ),
            ],
            body: RefreshIndicator(
              color: isDark ? const Color(0xFF64FFDA) : Colors.teal,
              backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              displacement: 20,
              onRefresh: () => _handleRefresh(vm, isDark),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 2. Date & Location (Header)
                  SliverToBoxAdapter(
                    child: _buildDateAndLocationHeader(context, vm, isDark),
                  ),

                  // 2.5 Combined Header Info (Smart Banner + Quran Progress)
                  SliverToBoxAdapter(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Quran Progress takes priority or half space
                          Expanded(
                              flex: 3,
                              child:
                                  _buildQuranProgressCard(context, vm, isDark)),

                          // Smart Event (if Active)
                          if (vm.activeEvent != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                                flex: 2,
                                child: _buildSmartEventBanner(
                                    vm.activeEvent!, isDark)),
                          ]
                        ],
                      ),
                    ),
                  )),

                  // 3. Daily Inspiration Quote
                  SliverToBoxAdapter(
                    child: _buildDailyInspiration(vm, isDark),
                  ),

                  // 4. Dynamic Prayer Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          _buildDynamicPrayerCard(vm, isDark),
                          const SizedBox(height: 12),
                          _buildContextAwareSuggestion(
                              vm, isDark), // New Context Aware Button
                        ],
                      ),
                    ),
                  ),

                  // 5. Daily Progress Bar (Linear)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.dailyProgress,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              Text(
                                "${(vm.progress * 100).toInt()}%",
                                style: GoogleFonts.ibmPlexMono(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color:
                                      isDark ? Colors.tealAccent : Colors.teal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: vm.progress,
                              minHeight: 10,
                              backgroundColor:
                                  isDark ? Colors.white10 : Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation(
                                isDark ? Colors.tealAccent : Colors.teal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 6. Quick Actions Horizontal Scroll
                  SliverToBoxAdapter(
                    child: Container(
                      height: 100,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildQuickActionCard(
                            context,
                            icon: Icons.menu_book_rounded,
                            label: AppStrings.quran,
                            color: const Color(0xFF1E5128),
                            isDark: isDark,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SurahKahfScreen())),
                          ),
                          _buildQuickActionCard(
                            context,
                            icon: Icons.fingerprint,
                            label: AppStrings.tasbeeh,
                            color: const Color(0xFF8E24AA),
                            isDark: isDark,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const CustomTasbeehScreen())),
                          ),
                          _buildQuickActionCard(
                            context,
                            icon: Icons.explore_rounded,
                            label: AppStrings.qibla,
                            color: const Color(0xFFD84315),
                            isDark: isDark,
                            onTap: () {
                              if (vm.prayerTimes?.coordinates != null) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => QiblaScreen(
                                            coordinates:
                                                vm.prayerTimes!.coordinates)));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(AppStrings.locating)));
                              }
                            },
                          ),
                          _buildQuickActionCard(
                            context,
                            icon: Icons.calendar_month_rounded,
                            label: AppStrings.calendar,
                            color: const Color(0xFF1976D2),
                            isDark: isDark,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) =>
                                    const CalendarExplorerDialog(initialTab: 0),
                              );
                            },
                          ),
                          _buildQuickActionCard(
                            context,
                            icon: Icons.repeat_on_rounded, // or loops icon
                            label: "حلقة ذكر",
                            color: const Color(0xFFE94560),
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GuidedTasbeehScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 7. Loading State or Task Lists
                  if (vm.isLoadingLocation)
                    SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: isDark ? Colors.white : Colors.teal,
                        ),
                      ),
                    )
                  else ...[
                    // Prayer Tasks Group
                    if (vm.prayerTasks.isNotEmpty) ...[
                      _buildSectionHeader("الصلوات المفروضة", isDark),
                      _buildTasksSliverList(
                          context, vm, vm.prayerTasks, isDark),
                    ],

                    // Other Tasks Group
                    if (vm.otherTasks.isNotEmpty) ...[
                      _buildSectionHeader("السنن والأذكار", isDark),
                      _buildTasksSliverList(context, vm, vm.otherTasks, isDark),
                    ],

                    // 8. Gratitude Section (The "Thanks" feature)
                    SliverToBoxAdapter(
                        child: _buildGratitudeSection(context, vm, isDark)),

                    const SliverToBoxAdapter(
                        child: SizedBox(height: 80)), // Bottom padding
                  ],
                ],
              ),
            ),
          ),
        ),
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

  Widget _buildDateAndLocationHeader(
      BuildContext context, TasksViewModel vm, bool isDark) {
    // Date Formatting
    final hijri = HijriCalendar.fromDate(vm.now);
    final dayName = intl.DateFormat('EEEE', 'ar').format(vm.now);
    final hijriStr = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}';
    final gregorianStr = intl.DateFormat('d MMMM yyyy', 'ar').format(vm.now);
    final timeStr = intl.DateFormat('hh:mm a', 'ar').format(vm.now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: isDark ? const Color(0xFF1A1F26) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // DATE SECTION -> Opens Calendar
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) =>
                        const CalendarExplorerDialog(initialTab: 0),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$dayName، $gregorianStr',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.teal[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hijriStr,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // TIME SECTION -> Opens Professional Clock
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) =>
                        _buildProfessionalClockDialog(ctx, vm, isDark),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.tealAccent.withValues(alpha: 0.3)
                          : Colors.teal.shade100,
                    ),
                  ),
                  child: Text(
                    timeStr,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.tealAccent : Colors.teal[900],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.location_on,
                  size: 16, color: isDark ? Colors.white70 : Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vm.locationName,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Weather Mock Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white10
                      : Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wb_cloudy_outlined,
                        size: 14,
                        color: isDark ? Colors.white70 : Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      vm.weatherInfo['temp'] ?? "",
                      style: GoogleFonts.ibmPlexMono(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              )
            ],
          ),
          if (vm.weatherInfo['advice'] != null) ...[
            const SizedBox(height: 4),
            Text(
              vm.weatherInfo['advice']!,
              style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.end,
            )
          ]
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

  Widget _buildQuranProgressCard(
      BuildContext context, TasksViewModel vm, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2C3E50)
            : Colors.white, // Slightly darker/distinct background
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
      ),
      child: InkWell(
        onTap: () => _showUpdateQuranDialog(context, vm),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E5128).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_stories_rounded,
                  color: Color(0xFF1E5128), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "متابع الختمة",
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: Colors.grey, height: 1.0),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "سورة ${vm.lastSurah} : ${vm.lastAyah}",
                    style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_note, size: 20, color: Colors.grey)
          ],
        ),
      ),
    );
  }

  void _showUpdateQuranDialog(BuildContext context, TasksViewModel vm) {
    final surahController = TextEditingController(text: vm.lastSurah);
    final ayahController = TextEditingController(text: vm.lastAyah.toString());

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text("تحديث الختمة",
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: surahController,
                    decoration: const InputDecoration(labelText: "اسم السورة"),
                  ),
                  TextField(
                    controller: ayahController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "رقم الآية"),
                  )
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("إلغاء")),
                ElevatedButton(
                  onPressed: () {
                    vm.updateQuranProgress(surahController.text,
                        int.tryParse(ayahController.text) ?? 1);
                    Navigator.pop(ctx);
                  },
                  child: const Text("حفظ"),
                )
              ],
            ));
  }

  Widget _buildContextAwareSuggestion(TasksViewModel vm, bool isDark) {
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

  Widget _buildDynamicPrayerCard(TasksViewModel vm, bool isDark) {
    if (vm.prayerTimes == null) {
      return const SizedBox.shrink();
    }

    var next = vm.prayerTimes!.nextPrayer();
    var nextPrayerTime = vm.prayerTimes!.timeForPrayer(next);

    // Handle rollover to next day Fajr
    if (next == Prayer.none && vm.tomorrowPrayerTimes != null) {
      next = Prayer.fajr;
      nextPrayerTime = vm.tomorrowPrayerTimes!.fajr;
    }

    // Dynamic Gradient Logic
    List<Color> gradientColors;
    IconData timeIcon;

    switch (next) {
      case Prayer.fajr:
        gradientColors = [
          const Color(0xFF0D47A1),
          const Color(0xFF1976D2)
        ]; // Deep Blue
        timeIcon = Icons.nights_stay;
        break;
      case Prayer.sunrise:
        gradientColors = [
          const Color(0xFFFF6F00),
          const Color(0xFFFF8F00)
        ]; // Orange
        timeIcon = Icons.wb_twilight;
        break;
      case Prayer.dhuhr:
      case Prayer.asr:
        gradientColors = [
          const Color(0xFF0288D1),
          const Color(0xFF29B6F6)
        ]; // Light Blue
        timeIcon = Icons.wb_sunny;
        break;
      case Prayer.maghrib:
        gradientColors = [
          const Color(0xFFBF360C),
          const Color(0xFFFF5722)
        ]; // Sunset Orange
        timeIcon = Icons.wb_twilight;
        break;
      case Prayer.isha:
        gradientColors = [
          const Color(0xFF1A237E),
          const Color(0xFF283593)
        ]; // Dark Navy
        timeIcon = Icons.nights_stay;
        break;
      default:
        gradientColors = [
          const Color(0xFF455A64),
          const Color(0xFF607D8B)
        ]; // Grey
        timeIcon = Icons.access_time;
    }

    final diff = nextPrayerTime != null
        ? nextPrayerTime.difference(vm.now)
        : const Duration(hours: 0);

    String remaining = '--:--:--';
    if (nextPrayerTime != null && !diff.isNegative) {
      final hours = diff.inHours.toString().padLeft(2, '0');
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
      remaining = '$hours:$minutes:$seconds';
    }

    String nextName = _getPrayerName(next);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern (Optional opacity)
          Positioned(
            right: -20,
            top: -20,
            child: Icon(timeIcon,
                size: 120, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${AppStrings.nextPrayer}: $nextName',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  remaining,
                  style: GoogleFonts.ibmPlexMono(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      width: 80,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ]),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
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
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AthkarDetailsScreen(
                  title: isMorning ? kAthkarMorning : kAthkarEvening,
                  isMorning: isMorning))).then((result) {
        if (result == true) {
          vm.toggleTask(index, completionValue: true);
        }
      });
    } else if (task.name.contains(kProphetPrayer)) {
      Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProphetPrayersScreen()))
          .then((_) => vm.toggleTask(index, completionValue: true));
    } else if (task.name == kCustomWird) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CustomTasbeehScreen()));
    } else {
      vm.toggleTask(index);
    }
  }

  String _getPrayerName(Prayer p) {
    switch (p) {
      case Prayer.fajr:
        return AppStrings.fajr;
      case Prayer.sunrise:
        return AppStrings.sunrise;
      case Prayer.dhuhr:
        return AppStrings.dhuhr;
      case Prayer.asr:
        return AppStrings.asr;
      case Prayer.maghrib:
        return AppStrings.maghrib;
      case Prayer.isha:
        return AppStrings.isha;
      default:
        return AppStrings.fajr; // Next day
    }
  }
}
