import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' as intl;

import '../constants/strings.dart';

// Just for the Calendar
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

  late DateTime selectedGregorian;
  late int viewHijriYear;
  late int viewHijriMonth;

  @override
  void initState() {
    super.initState();
    selectedGregorian = DateTime.now();
    final h = HijriCalendar.fromDate(selectedGregorian);
    viewHijriYear = h.hYear;
    viewHijriMonth = h.hMonth;
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
      final synced = HijriCalendar.fromDate(date);
      viewHijriYear = synced.hYear;
      viewHijriMonth = synced.hMonth;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF80CBC4) : const Color(0xFF1B5E20);
    final surface = isDark ? const Color(0xFF12181C) : Colors.white;
    final border = isDark ? Colors.white12 : Colors.black12;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white70 : Colors.black54;

    final selectedHijri = HijriCalendar.fromDate(selectedGregorian);
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
    final todayHijri = HijriCalendar.now();

    final size = MediaQuery.of(context).size;
    final maxWidth = size.width - 32;
    final maxHeight = size.height - 120;
    final dialogWidth = maxWidth.clamp(0.0, 560.0);
    final dialogHeight = maxHeight.clamp(0.0, 680.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: DefaultTabController(
        length: 2,
        initialIndex: widget.initialTab.clamp(0, 1),
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
                        AppStrings.calendar,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textPrimary),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
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
                    Tab(text: AppStrings.hijri),
                    Tab(text: AppStrings.gregorian),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    // Hijri View
                    Column(
                      children: [
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
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
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

                              final Color? textColor =
                                  isSelected ? accent : null;

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
                    // Gregorian View
                    CalendarDatePicker(
                      initialDate: selectedGregorian,
                      firstDate: DateTime(1937, 3, 14),
                      lastDate: DateTime(2077, 11, 16),
                      currentDate: DateTime.now(),
                      onDateChanged: selectGregorian,
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
    );
  }
}
