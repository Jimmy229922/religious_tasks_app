import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import 'package:religious_tasks_app/core/constants/app_constants.dart';
import '../models/task_item.dart';
import '../providers/tasks_view_model.dart';

class PrayersTimelineSection extends StatefulWidget {
  final TasksViewModel vm;
  final List<TaskItem> prayerTasks;
  final bool isDark;
  final void Function(TaskItem task) onOpenDetails;
  final void Function(TaskItem task) onToggleCompletion;

  const PrayersTimelineSection({
    super.key,
    required this.vm,
    required this.prayerTasks,
    required this.isDark,
    required this.onOpenDetails,
    required this.onToggleCompletion,
  });

  @override
  State<PrayersTimelineSection> createState() => _PrayersTimelineSectionState();
}

class _PrayersTimelineSectionState extends State<PrayersTimelineSection> {
  final ScrollController _scrollController = ScrollController();
  double _lastCardWidth = 124.0;
  double _scrollRatio = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToNextPrayer(animate: false);
    });
  }

  @override
  void didUpdateWidget(covariant PrayersTimelineSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vm.nextPrayerName != widget.vm.nextPrayerName ||
        oldWidget.prayerTasks.length != widget.prayerTasks.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToNextPrayer(animate: true);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions) {
      return;
    }
    final max = _scrollController.position.maxScrollExtent;
    final ratio = max <= 0 ? 0.0 : (_scrollController.offset / max).clamp(0.0, 1.0);
    if ((ratio - _scrollRatio).abs() > 0.04 && mounted) {
      setState(() {
        _scrollRatio = ratio;
      });
    }
  }

  void _scrollToNextPrayer({required bool animate}) {
    if (!mounted ||
        !_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions) {
      return;
    }
    final nextName = widget.vm.nextPrayerName;
    if (nextName.isEmpty) return;

    final nextIdx = widget.prayerTasks.indexWhere((t) => _isNextPrayer(t, nextName));
    if (nextIdx <= 0) return;

    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;

    final targetOffset =
        ((nextIdx * (_lastCardWidth + 10.0)) - 12.0).clamp(0.0, maxExtent);
    if (animate) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prayerTasks = widget.prayerTasks;
    final isDark = widget.isDark;
    if (prayerTasks.isEmpty) return const SizedBox.shrink();

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final nextName = widget.vm.nextPrayerName;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useEqualGrid = constraints.maxWidth >= 660 && textScale < 1.2;
        final double cardWidth = (constraints.maxWidth < 360
                ? 118.0
                : (textScale >= 1.15 ? 136.0 : 124.0))
            .clamp(114.0, 160.0);
        _lastCardWidth = cardWidth;

        if (useEqualGrid) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < prayerTasks.length; i++) ...[
                Expanded(
                  child: _buildPrayerCard(
                    task: prayerTasks[i],
                    isNext: _isNextPrayer(prayerTasks[i], nextName),
                    formattedTime: _prayerTimeLabel(prayerTasks[i]),
                    icon: _prayerIcon(prayerTasks[i]),
                  ),
                ),
                if (i < prayerTasks.length - 1) const SizedBox(width: 10),
              ],
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < prayerTasks.length; i++) ...[
                    SizedBox(
                      width: cardWidth,
                      child: _buildPrayerCard(
                        task: prayerTasks[i],
                        isNext: _isNextPrayer(prayerTasks[i], nextName),
                        formattedTime: _prayerTimeLabel(prayerTasks[i]),
                        icon: _prayerIcon(prayerTasks[i]),
                      ),
                    ),
                    if (i < prayerTasks.length - 1) const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildScrollCueRow(isDark, prayerTasks, nextName),
          ],
        );
      },
    );
  }

  Widget _buildScrollCueRow(
    bool isDark,
    List<TaskItem> prayerTasks,
    String nextName,
  ) {
    final activeColor =
        isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
    final mutedColor =
        isDark ? Colors.white38 : const Color(0xFF94A3B8);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.swipe_rounded,
                size: 13,
                color: mutedColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  "اسحب لباقي الصلوات",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: mutedColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < prayerTasks.length; i++) ...[
                  Builder(
                    builder: (_) {
                      final bool isNext =
                          _isNextPrayer(prayerTasks[i], nextName);
                      final bool isDone = prayerTasks[i].isCompleted;
                      final double approxPos = prayerTasks.length <= 1
                          ? 0
                          : i / (prayerTasks.length - 1);
                      final bool nearViewport =
                          (_scrollRatio - approxPos).abs() < 0.28;
                      final Color dotColor = isDone
                          ? activeColor
                          : (isNext
                              ? const Color(0xFFD4AF37)
                              : (nearViewport
                                  ? activeColor.withValues(alpha: 0.45)
                                  : mutedColor.withValues(alpha: 0.4)));
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isNext || nearViewport ? 14 : 6,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: dotColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    },
                  ),
                  if (i < prayerTasks.length - 1) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerCard({
    required TaskItem task,
    required bool isNext,
    required String formattedTime,
    required IconData icon,
  }) {
    final isDark = widget.isDark;
    final bool done = task.isCompleted;
    const Color emerald = Color(0xFF0F766E);
    const Color emeraldLight = Color(0xFF2DD4BF);
    const Color gold = Color(0xFFD4AF37);

    final Color accent = done
        ? (isDark ? emeraldLight : emerald)
        : (isNext ? gold : (isDark ? Colors.white70 : const Color(0xFF475569)));

    final List<Color> bgColors;
    if (isNext && !done) {
      bgColors = isDark
          ? const [Color(0xFF251E10), Color(0xFF172231)]
          : const [Color(0xFFFFFBEB), Color(0xFFFFFFFF)];
    } else if (done) {
      bgColors = isDark
          ? const [Color(0xFF0E2A26), Color(0xFF152230)]
          : const [Color(0xFFECFDF5), Color(0xFFFFFFFF)];
    } else {
      bgColors = isDark
          ? const [Color(0xFF172231), Color(0xFF131C29)]
          : const [Colors.white, Color(0xFFF8FAFC)];
    }

    final borderColor = done
        ? (isDark
            ? emeraldLight.withValues(alpha: 0.58)
            : emerald.withValues(alpha: 0.50))
        : (isNext
            ? gold.withValues(alpha: isDark ? 0.72 : 0.78)
            : (isDark
                ? Colors.white.withValues(alpha: 0.16)
                : const Color(0xFFCBD5E1)));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onOpenDetails(task),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: bgColors,
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: isNext || done ? 1.55 : 1.25,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: (isNext ? gold : emerald).withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: isDark ? 0.34 : 0.26),
                      ),
                    ),
                    child: Icon(icon, size: 17, color: accent),
                  ),
                  if (isNext && !done) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: isDark ? 0.24 : 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: gold.withValues(alpha: isDark ? 0.55 : 0.6),
                            ),
                          ),
                          child: Text(
                            "التالية",
                            maxLines: 1,
                            style: GoogleFonts.cairo(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFFDE68A)
                                  : const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _shortPrayerName(task.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formattedTime,
                  maxLines: 1,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onToggleCompletion(task);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                  decoration: BoxDecoration(
                    color: done
                        ? emerald
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: done
                          ? emerald
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.22)
                              : const Color(0xFF94A3B8).withValues(alpha: 0.7)),
                      width: 1.15,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          done
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 14,
                          color: done
                              ? Colors.white
                              : (isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          done ? "تمت" : "أتممتها",
                          maxLines: 1,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: done
                                ? Colors.white
                                : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortPrayerName(String name) {
    return name.replaceFirst('صلاة ', '').trim();
  }

  bool _isNextPrayer(TaskItem task, String nextPrayerName) {
    if (nextPrayerName.isEmpty) return false;
    return task.name.contains(nextPrayerName);
  }

  String _prayerTimeLabel(TaskItem task) {
    final times = widget.vm.prayerTimes;
    if (times != null) {
      DateTime? dt;
      if (task.name.contains(kPrayerFajr)) {
        dt = times.fajr;
      } else if (task.name.contains(kPrayerDhuhr)) {
        dt = times.dhuhr;
      } else if (task.name.contains(kPrayerAsr)) {
        dt = times.asr;
      } else if (task.name.contains(kPrayerMaghrib)) {
        dt = times.maghrib;
      } else if (task.name.contains(kPrayerIsha)) {
        dt = times.isha;
      }
      if (dt != null) {
        return intl.DateFormat('hh:mm a', 'ar').format(dt);
      }
    }
    if (task.description.isNotEmpty) {
      return task.description;
    }
    return '--:--';
  }

  IconData _prayerIcon(TaskItem task) {
    if (task.name.contains(kPrayerFajr)) return Icons.nights_stay_rounded;
    if (task.name.contains(kPrayerDhuhr)) return Icons.wb_sunny_rounded;
    if (task.name.contains(kPrayerAsr)) return Icons.wb_sunny_outlined;
    if (task.name.contains(kPrayerMaghrib)) return Icons.wb_twilight_rounded;
    if (task.name.contains(kPrayerIsha)) return Icons.bedtime_rounded;
    return Icons.mosque_rounded;
  }
}
