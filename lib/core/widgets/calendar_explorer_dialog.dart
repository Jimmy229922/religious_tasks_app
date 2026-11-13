import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/strings.dart';

class CalendarExplorerDialog extends StatefulWidget {
  final int initialTab;
  const CalendarExplorerDialog({super.key, required this.initialTab});

  @override
  State<CalendarExplorerDialog> createState() => _CalendarExplorerDialogState();
}

class _CalendarExplorerDialogState extends State<CalendarExplorerDialog> {
  static const int _hijriMinYear = 1356;
  static const int _hijriMaxYear = 1500;
  static const List<int> _hijriWeekdayOrder = [6, 7, 1, 2, 3, 4, 5]; // Sat..Fri
  static const String _hijriOffsetKey = 'hijri_date_offset_v1';

  late DateTime selectedGregorian;
  late int viewHijriYear;
  late int viewHijriMonth;
  int _hijriOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadHijriOffset();
    selectedGregorian = DateTime.now();
    final h = HijriCalendar.fromDate(selectedGregorian);
    viewHijriYear = h.hYear;
    viewHijriMonth = h.hMonth;
  }

  Future<void> _loadHijriOffset() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hijriOffset = prefs.getInt(_hijriOffsetKey) ?? 0;
      });
    }
  }

  Future<void> _setHijriOffset(int offset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hijriOffsetKey, offset);
    if (mounted) {
      setState(() {
        _hijriOffset = offset;
      });
    }
  }

  String _hijriMonthName(int year, int month) {
    final hijri = HijriCalendar()
      ..hYear = year
      ..hMonth = month;
    return hijri.getLongMonthName();
  }

  void selectGregorian(DateTime date) {
    setState(() {
      selectedGregorian = date;
      final synced = HijriCalendar.fromDate(date.add(Duration(days: _hijriOffset)));
      viewHijriYear = synced.hYear;
      viewHijriMonth = synced.hMonth;
    });
  }

  List<Map<String, dynamic>> _getIslamicEvents(HijriCalendar nowHijri) {
    final currentYear = nowHijri.hYear;

    return [
      {
        'title': 'رمضان المبارك 🌙',
        'dateLabel': '1 رمضان $currentYear',
        'month': 9,
        'day': 1,
      },
      {
        'title': 'عيد الفطر المبارك 🎉',
        'dateLabel': '1 شوال $currentYear',
        'month': 10,
        'day': 1,
      },
      {
        'title': 'يوم عرفة 🕋',
        'dateLabel': '9 ذو الحجة $currentYear',
        'month': 12,
        'day': 9,
      },
      {
        'title': 'عيد الأضحى المبارك 🐑',
        'dateLabel': '10 ذو الحجة $currentYear',
        'month': 12,
        'day': 10,
      },
      {
        'title': 'رأس السنة الهجرية 🕌',
        'dateLabel': '1 محرم ${currentYear + 1}',
        'month': 1,
        'day': 1,
      },
      {
        'title': 'يوم عاشوراء 📜',
        'dateLabel': '10 محرم ${currentYear + 1}',
        'month': 1,
        'day': 10,
      },
    ];
  }

  int _calculateDaysUntilEvent(int targetMonth, int targetDay, HijriCalendar today) {
    DateTime todayGreg = DateTime.now().add(Duration(days: _hijriOffset));
    int year = today.hYear;

    if (today.hMonth > targetMonth || (today.hMonth == targetMonth && today.hDay > targetDay)) {
      year += 1;
    }

    try {
      DateTime eventGreg = HijriCalendar().hijriToGregorian(year, targetMonth, targetDay);
      return eventGreg.difference(todayGreg).inDays;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF80CBC4) : const Color(0xFF1B5E20);
    final surface = isDark ? const Color(0xFF12181C) : Colors.white;
    final border = isDark ? Colors.white12 : Colors.black12;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white70 : Colors.black54;

    final adjustedDate = selectedGregorian.add(Duration(days: _hijriOffset));
    final selectedHijri = HijriCalendar.fromDate(adjustedDate);
    final hijriLabel =
        '${selectedHijri.hDay} ${selectedHijri.longMonthName} ${selectedHijri.hYear} ${AppStrings.hijri}';
    final gregorianLabel =
        intl.DateFormat('d MMMM yyyy', 'ar').format(selectedGregorian);
    final dayName = intl.DateFormat('EEEE', 'ar').format(selectedGregorian);

    final daysInMonth =
        HijriCalendar().getDaysInMonth(viewHijriYear, viewHijriMonth);
    final firstGregorian =
        HijriCalendar().hijriToGregorian(viewHijriYear, viewHijriMonth, 1);
    final startIndex = _hijriWeekdayOrder.indexOf(firstGregorian.weekday);
    final startOffset = startIndex < 0 ? 0 : startIndex;
    final totalSlots = startOffset + daysInMonth;
    final rows = (totalSlots / 7).ceil();
    final monthName = _hijriMonthName(viewHijriYear, viewHijriMonth);

    final isPrevDisabled =
        viewHijriYear == _hijriMinYear && viewHijriMonth == 1;
    final isNextDisabled =
        viewHijriYear == _hijriMaxYear && viewHijriMonth == 12;
    final todayHijri = HijriCalendar.fromDate(DateTime.now().add(Duration(days: _hijriOffset)));

    final size = MediaQuery.of(context).size;
    final maxWidth = size.width - 32;
    final maxHeight = size.height - 100;
    final dialogWidth = maxWidth.clamp(0.0, 560.0);
    final dialogHeight = maxHeight.clamp(0.0, 700.0);

    final events = _getIslamicEvents(todayHijri);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: DefaultTabController(
          length: 3,
          initialIndex: widget.initialTab.clamp(0, 2),
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "التقويم الهجري والمناسبات 📅",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textPrimary),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: textPrimary),
                        tooltip: AppStrings.close,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TabBar(
                    labelColor: accent,
                    unselectedLabelColor: textMuted,
                    indicatorColor: accent,
                    tabs: const [
                      Tab(text: "التقويم"),
                      Tab(text: "المناسبات 🌙"),
                      Tab(text: "سنن الصيام 🌿"),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Hijri Calendar Tab
                      Column(
                        children: [
                          // Adjustment Offset Control
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: accent.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("تعديل التاريخ الهجري:",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                      onPressed: () => _setHijriOffset(_hijriOffset - 1),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        "${_hijriOffset > 0 ? '+' : ''}$_hijriOffset يوم",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: accent,
                                            fontSize: 13),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20),
                                      onPressed: () => _setHijriOffset(_hijriOffset + 1),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: isPrevDisabled
                                    ? null
                                    : () {
                                        setState(() {
                                          if (viewHijriMonth == 1) {
                                            viewHijriYear -= 1;
                                            viewHijriMonth = 12;
                                          } else {
                                            viewHijriMonth -= 1;
                                          }
                                        });
                                      },
                                icon: const Icon(Icons.chevron_right),
                              ),
                              Text(
                                '$monthName $viewHijriYear ${AppStrings.hijri}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, color: accent),
                              ),
                              IconButton(
                                onPressed: isNextDisabled
                                    ? null
                                    : () {
                                        setState(() {
                                          if (viewHijriMonth == 12) {
                                            viewHijriYear += 1;
                                            viewHijriMonth = 1;
                                          } else {
                                            viewHijriMonth += 1;
                                          }
                                        });
                                      },
                                icon: const Icon(Icons.chevron_left),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: AppStrings.hijriWeekdays
                                .map((label) => Expanded(
                                      child: Center(
                                        child: Text(label,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: textMuted)),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                              ),
                              itemCount: rows * 7,
                              itemBuilder: (context, index) {
                                final day = index - startOffset + 1;
                                if (day < 1 || day > daysInMonth) {
                                  return const SizedBox.shrink();
                                }

                                final isSelected =
                                    viewHijriYear == selectedHijri.hYear &&
                                        viewHijriMonth == selectedHijri.hMonth &&
                                        day == selectedHijri.hDay;
                                final isToday =
                                    viewHijriYear == todayHijri.hYear &&
                                        viewHijriMonth == todayHijri.hMonth &&
                                        day == todayHijri.hDay;

                                final Color textColor =
                                    isSelected ? accent : textPrimary;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      final gregorian = HijriCalendar()
                                          .hijriToGregorian(
                                              viewHijriYear, viewHijriMonth, day);
                                      selectGregorian(gregorian);
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? accent.withValues(alpha: 0.2)
                                            : (isToday
                                                ? accent.withValues(alpha: 0.12)
                                                : Colors.transparent),
                                        borderRadius: BorderRadius.circular(10),
                                        border: isSelected
                                            ? Border.all(
                                                color: accent, width: 1.2)
                                            : (isToday
                                                ? Border.all(
                                                    color: accent.withValues(
                                                        alpha: 0.5),
                                                    width: 1)
                                                : null),
                                      ),
                                      child: Text('$day',
                                          style: TextStyle(
                                              color: textColor,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500)),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      // Islamic Events Countdown Tab
                      ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          final daysLeft = _calculateDaysUntilEvent(
                              event['month'], event['day'], todayHijri);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: accent.withValues(alpha: 0.15),
                                child: Icon(Icons.event_seat_rounded, color: accent),
                              ),
                              title: Text(
                                event['title'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(event['dateLabel']),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: daysLeft == 0
                                      ? Colors.amber.withValues(alpha: 0.2)
                                      : accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  daysLeft == 0
                                      ? "اليوم 🎉"
                                      : "متبقي $daysLeft يوم",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: daysLeft == 0
                                        ? Colors.amber.shade900
                                        : accent,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Sunnah Fasting Reminders Tab
                      ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          _buildFastingCard(
                            title: "صيام الأيام البيض ⚪",
                            subtitle: "13 و 14 و 15 من كل شهر هجري",
                            description: "اليوم الهجري الحالي: ${todayHijri.hDay} ${todayHijri.longMonthName}",
                            isDark: isDark,
                            accent: accent,
                          ),
                          const SizedBox(height: 10),
                          _buildFastingCard(
                            title: "صيام الإثنين والخميس 🌿",
                            subtitle: "تُعرض فيهما الأعمال على الله تعالى",
                            description: "سُنّة مؤكدة كان يحافظ عليها النبي ﷺ",
                            isDark: isDark,
                            accent: accent,
                          ),
                          const SizedBox(height: 10),
                          _buildFastingCard(
                            title: "صيام يوم عرفة وعاشوراء 🕋",
                            subtitle: "كفارة سنة ماضية وسنة باقية",
                            description: "من أفضل الأيام المقربة إلى الله سبحانه",
                            isDark: isDark,
                            accent: accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${AppStrings.today}$dayName',
                            style: TextStyle(
                                color: textPrimary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('${AppStrings.hijriDate}$hijriLabel',
                            style: TextStyle(color: textMuted)),
                        const SizedBox(height: 4),
                        Text('${AppStrings.gregorianDate}$gregorianLabel',
                            style: TextStyle(color: textMuted)),
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

  Widget _buildFastingCard({
    required String title,
    required String subtitle,
    required String description,
    required bool isDark,
    required Color accent,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wb_twilight_rounded, color: accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.teal.shade800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
