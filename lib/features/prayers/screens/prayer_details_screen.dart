import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../athkar/models/dhikr_item.dart';
import '../data/prayer_details_data.dart';

class PrayerDetailsScreen extends StatefulWidget {
  final String prayerName;
  final DateTime? prayerTime;
  final bool isCompleted;
  final VoidCallback? onToggleCompletion;

  const PrayerDetailsScreen({
    super.key,
    required this.prayerName,
    this.prayerTime,
    this.isCompleted = false,
    this.onToggleCompletion,
  });

  @override
  State<PrayerDetailsScreen> createState() => _PrayerDetailsScreenState();
}

class _PrayerDetailsScreenState extends State<PrayerDetailsScreen>
    with SingleTickerProviderStateMixin {
  late PrayerInfo _info;
  late List<DhikrItem> _athkar;
  late TabController _tabController;
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _info = PrayerDetailsRepository.getPrayerInfo(widget.prayerName);
    _athkar = _info.afterPrayerAthkar
        .map((e) => DhikrItem(
              text: e.text,
              reward: e.reward,
              count: e.count,
              current: 0,
            ))
        .toList();
    _tabController = TabController(length: 2, vsync: this);
    _isCompleted = widget.isCompleted;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _completedAthkarCount =>
      _athkar.where((item) => item.current >= item.count).length;

  double get _athkarProgress =>
      _athkar.isEmpty ? 0.0 : _completedAthkarCount / _athkar.length;

  void _incrementDhikr(int index) {
    if (_athkar[index].current < _athkar[index].count) {
      setState(() {
        _athkar[index].current++;
      });
      HapticFeedback.lightImpact();
      if (_athkarProgress == 1.0) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("أحسنت! أتممت جميع أذكار بعد الصلاة 🤲"),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _resetAthkar() {
    setState(() {
      for (var item in _athkar) {
        item.current = 0;
      }
    });
    HapticFeedback.selectionClick();
  }

  Color _getPrayerAccent(bool isDark) {
    if (widget.prayerName.contains(kPrayerFajr)) {
      return isDark ? const Color(0xFF4DD0E1) : const Color(0xFF00838F);
    } else if (widget.prayerName.contains(kPrayerDhuhr)) {
      return isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
    } else if (widget.prayerName.contains(kPrayerAsr)) {
      return isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);
    } else if (widget.prayerName.contains(kPrayerMaghrib)) {
      return isDark ? const Color(0xFFBA68C8) : const Color(0xFF7B1FA2);
    } else if (widget.prayerName.contains(kPrayerIsha)) {
      return isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
    }
    return Colors.teal;
  }

  List<Color> _getHeaderGradient(bool isDark) {
    if (widget.prayerName.contains(kPrayerFajr)) {
      return isDark
          ? [const Color(0xFF0D324D), const Color(0xFF1C5D99)]
          : [const Color(0xFF006064), const Color(0xFF00838F)];
    } else if (widget.prayerName.contains(kPrayerDhuhr)) {
      return isDark
          ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)]
          : [const Color(0xFF0288D1), const Color(0xFF00ACC1)];
    } else if (widget.prayerName.contains(kPrayerAsr)) {
      return isDark
          ? [const Color(0xFFE65100), const Color(0xFFBF360C)]
          : [const Color(0xFFF59E0B), const Color(0xFFD97706)];
    } else if (widget.prayerName.contains(kPrayerMaghrib)) {
      return isDark
          ? [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)]
          : [const Color(0xFF7C3AED), const Color(0xFF6D28D9)];
    } else if (widget.prayerName.contains(kPrayerIsha)) {
      return isDark
          ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
          : [const Color(0xFF0F766E), const Color(0xFF0D9488)];
    }
    return [Colors.teal.shade800, Colors.teal.shade600];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _getPrayerAccent(isDark);
    final gradient = _getHeaderGradient(isDark);
    final backgroundColor = isDark ? Colors.black : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            "صلاة ${_info.title}",
                            style: GoogleFonts.arefRuqaa(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isCompleted = !_isCompleted;
                            });
                            widget.onToggleCompletion?.call();
                            HapticFeedback.mediumImpact();
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isCompleted
                                  ? Colors.green.withValues(alpha: 0.9)
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white38,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isCompleted
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isCompleted ? "مكتملة" : "إتمام الصلاة",
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Quick Info Chips
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildHeaderChip(
                          icon: Icons.numbers,
                          label: "${_info.rakaat} ركعات",
                        ),
                        _buildHeaderChip(
                          icon: Icons.record_voice_over,
                          label: _info.type,
                        ),
                        if (widget.prayerTime != null)
                          _buildHeaderChip(
                            icon: Icons.access_time,
                            label:
                                "${widget.prayerTime!.hour.toString().padLeft(2, '0')}:${widget.prayerTime!.minute.toString().padLeft(2, '0')}",
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // TabBar Navigation
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  indicator: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor:
                      isDark ? Colors.white60 : Colors.grey[700],
                  labelStyle: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold, fontSize: 13.5),
                  tabs: const [
                    Tab(
                      height: 40,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text("أذكار بعد الصلاة"),
                      ),
                    ),
                    Tab(
                      height: 40,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text("تفاصيل وأحكام الصلاة"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // TabBarView Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAthkarTab(isDark, accent),
                    _buildDetailsTab(isDark, accent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: Athkar After Prayer ---
  Widget _buildAthkarTab(bool isDark, Color accent) {
    return Column(
      children: [
        // Progress Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: accent.withValues(alpha: isDark ? 0.3 : 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "إنجاز أذكار بعد الصلاة",
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        "$_completedAthkarCount من ${_athkar.length}",
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: accent,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.refresh, color: accent, size: 18),
                        onPressed: _resetAthkar,
                        tooltip: "إعادة الأذكار",
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _athkarProgress,
                  minHeight: 8,
                  backgroundColor:
                      isDark ? Colors.grey[800] : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ],
          ),
        ),

        // Dhikr Cards List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _athkar.length,
            itemBuilder: (context, index) {
              final item = _athkar[index];
              final isDone = item.current >= item.count;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDone
                      ? (isDark
                          ? Colors.teal.withValues(alpha: 0.15)
                          : Colors.teal.shade50)
                      : (isDark ? const Color(0xFF151A1F) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDone
                        ? Colors.teal
                        : accent.withValues(alpha: isDark ? 0.2 : 0.15),
                    width: isDone ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => _incrementDhikr(index),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.text,
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 1.6,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (item.reward.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            item.reward,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.tealAccent.shade100
                                  : Colors.teal.shade800,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Counter Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDone
                                    ? Colors.teal
                                    : accent.withValues(
                                        alpha: isDark ? 0.2 : 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isDone)
                                    const Icon(Icons.check,
                                        color: Colors.white, size: 14)
                                  else
                                    Text(
                                      "${item.current} / ${item.count}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: accent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (isDone) const SizedBox(width: 4),
                                  if (isDone)
                                    const Text(
                                      "مكتمل",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Action instruction
                            Text(
                              isDone
                                  ? "تم الانتهاء"
                                  : "اضغط للعداد (${item.count - item.current} متبقي)",
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.grey[600],
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
          ),
        ),
      ],
    );
  }

  // --- TAB 2: Prayer Details & Sunnahs ---
  Widget _buildDetailsTab(bool isDark, Color accent) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Description Card
        _buildInfoCard(
          isDark: isDark,
          title: "نبذة عن الصلاة",
          icon: Icons.mosque_rounded,
          accent: accent,
          child: Text(
            _info.description,
            style: GoogleFonts.cairo(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Sunnah Prayers Card
        _buildInfoCard(
          isDark: isDark,
          title: "السنن الراتبة",
          icon: Icons.star_rounded,
          accent: accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSunnahRow(
                isDark: isDark,
                typeLabel: "قبل الصلاة:",
                text: _info.sunnahBefore,
                color: Colors.amber,
              ),
              const Divider(height: 16),
              _buildSunnahRow(
                isDark: isDark,
                typeLabel: "بعد الصلاة:",
                text: _info.sunnahAfter,
                color: Colors.teal,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Virtues Card
        _buildInfoCard(
          isDark: isDark,
          title: "فضائل وأحاديث نبوية",
          icon: Icons.auto_stories_rounded,
          accent: accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _info.virtues.map((v) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• ",
                        style: TextStyle(
                            color: accent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        v,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSunnahRow({
    required bool isDark,
    required String typeLabel,
    required String text,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            typeLabel,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.25 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
