import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme_provider.dart';
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

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldLight = Color(0xFFFDE68A);

  Color _getPrayerAccent(bool isDark) {
    return isDark ? _goldLight : context.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _getPrayerAccent(isDark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: context.appScaffoldBg,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: context.appBgGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _gold.withValues(alpha: isDark ? 0.65 : 0.8),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: isDark ? 0.16 : 0.22),
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
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22.5),
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  Colors.black.withValues(alpha: 0.62),
                                  Colors.black.withValues(alpha: 0.25),
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.68),
                                  Colors.white.withValues(alpha: 0.25),
                                ],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? Colors.black.withValues(alpha: 0.35)
                                        : Colors.white.withValues(alpha: 0.85),
                                    border: Border.all(
                                      color: _gold.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 18,
                                    color: isDark
                                        ? _goldLight
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "صلاة ${_info.title}",
                                  style: GoogleFonts.arefRuqaa(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
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
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _isCompleted
                                        ? const Color(0xFF10B981)
                                        : (isDark
                                            ? Colors.black.withValues(alpha: 0.4)
                                            : Colors.white
                                                .withValues(alpha: 0.85)),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: _isCompleted
                                          ? const Color(0xFF10B981)
                                          : _gold.withValues(alpha: 0.7),
                                      width: 1.3,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isCompleted
                                            ? Icons.check_circle_rounded
                                            : Icons.radio_button_unchecked_rounded,
                                        color: _isCompleted
                                            ? Colors.white
                                            : (isDark
                                                ? _goldLight
                                                : const Color(0xFF78350F)),
                                        size: 17,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _isCompleted ? "مكتملة" : "إتمام الصلاة",
                                        style: GoogleFonts.cairo(
                                          color: _isCompleted
                                              ? Colors.white
                                              : (isDark
                                                  ? _goldLight
                                                  : const Color(0xFF78350F)),
                                          fontSize: 12,
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
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _buildHeaderChip(
                                icon: Icons.numbers,
                                label: "${_info.rakaat} ركعات",
                                isDark: isDark,
                              ),
                              _buildHeaderChip(
                                icon: Icons.record_voice_over,
                                label: _info.type,
                                isDark: isDark,
                              ),
                              if (widget.prayerTime != null)
                                _buildHeaderChip(
                                  icon: Icons.access_time,
                                  label:
                                      "${widget.prayerTime!.hour.toString().padLeft(2, '0')}:${widget.prayerTime!.minute.toString().padLeft(2, '0')}",
                                  isDark: isDark,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0E211E)
                          : const Color(0xFFFFFDF8),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _gold.withValues(alpha: isDark ? 0.45 : 0.65),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      indicator: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? const [Color(0xFF92400E), Color(0xFFD4AF37)]
                              : const [Color(0xFFFDE68A), Color(0xFFE5B84B)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      labelColor:
                          isDark ? Colors.white : const Color(0xFF451A03),
                      unselectedLabelColor:
                          isDark ? Colors.white70 : const Color(0xFF475569),
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
        ),
      ),
    );
  }

  Widget _buildHeaderChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _gold.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isDark ? _goldLight : const Color(0xFF78350F),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
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
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF0E211E), Color(0xFF0A171C)]
                  : const [Color(0xFFFFFDF8), Color(0xFFF8F0DB)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _gold.withValues(alpha: isDark ? 0.45 : 0.65),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mosque_rounded, color: accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "إنجاز أذكار بعد الصلاة",
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(_gold),
                ),
              ),
            ],
          ),
        ),

        // Dhikr Cards List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            itemCount: _athkar.length,
            itemBuilder: (context, index) {
              final item = _athkar[index];
              final isDone = item.current >= item.count;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: isDone
                      ? LinearGradient(
                          colors: isDark
                              ? const [Color(0xFF0A2E25), Color(0xFF07211A)]
                              : const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : LinearGradient(
                          colors: isDark
                              ? const [Color(0xFF0E211E), Color(0xFF0A171C)]
                              : const [Color(0xFFFFFDF8), Color(0xFFF8F0DB)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFF10B981)
                        : _gold.withValues(alpha: isDark ? 0.45 : 0.65),
                    width: isDone ? 1.5 : 1.2,
                  ),
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
