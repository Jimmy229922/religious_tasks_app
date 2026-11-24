import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:religious_tasks_app/core/services/storage_service.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/quran/data/quran_data.dart';
import 'package:religious_tasks_app/features/quran/data/quran_repository.dart';
import 'package:religious_tasks_app/features/quran/screens/quran_surah_reader_screen.dart';

class QuranIndexScreen extends StatefulWidget {
  const QuranIndexScreen({super.key});

  @override
  State<QuranIndexScreen> createState() => _QuranIndexScreenState();
}

class _QuranIndexScreenState extends State<QuranIndexScreen> {
  String _searchQuery = "";
  String _selectedFilter = "all"; // 'all', 'مكية', 'مدنية'
  final TextEditingController _searchController = TextEditingController();

  int? _lastReadSurahNum;
  String? _lastReadSurahName;
  String? _lastReadVerseNum;
  int? _lastReadPageNum;

  @override
  void initState() {
    super.initState();
    // Pre-cache Quran JSON in background for instant surah opening
    QuranRepository.loadQuran();
    _loadLastReadBookmark();
  }

  void _loadLastReadBookmark() {
    final prefs = StorageService.instance.prefs;
    final globalSurahNum = prefs.getInt('quran_global_bookmark_surah_number') ?? prefs.getInt('last_read_surah_number');
    final globalSurahName = prefs.getString('quran_global_bookmark_surah_name') ?? prefs.getString('last_read_surah_name');
    final globalVerse = prefs.getString('quran_global_bookmark_verse');
    final globalPage = prefs.getInt('quran_global_bookmark_page');

    setState(() {
      _lastReadSurahNum = globalSurahNum;
      _lastReadSurahName = globalSurahName;
      _lastReadVerseNum = globalVerse;
      _lastReadPageNum = globalPage;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldLight = Color(0xFFFDE68A);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = context.appBgGradient;

    final accent = context.primaryColor;

    final filteredSurahs = QuranData.surahs.where((surah) {
      final matchesSearch = surah.name.contains(_searchQuery) ||
          surah.englishName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          surah.number.toString() == _searchQuery;

      final matchesType = _selectedFilter == "all" || surah.type == _selectedFilter;

      return matchesSearch && matchesType;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.appScaffoldBg,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: bgGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: _buildQuranDomeHeader(context, isDark, accent),
                ),
                // Single Unified Global Reading Bookmark Banner
                if (_lastReadSurahNum != null && _lastReadSurahName != null)
                  GestureDetector(
                    onTap: () {
                      final surah = QuranData.surahs.firstWhere(
                        (s) => s.number == _lastReadSurahNum,
                        orElse: () => QuranData.surahs.first,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuranSurahReaderScreen(
                            surah: surah,
                            initialPage: _lastReadPageNum,
                          ),
                        ),
                      ).then((_) => _loadLastReadBookmark());
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(12, 10, 12, 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? const [Color(0xFF0E211E), Color(0xFF0A171C)]
                              : const [Color(0xFFFFFDF8), Color(0xFFF8F0DB)],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _gold.withValues(alpha: isDark ? 0.6 : 0.75),
                          width: 1.35,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withValues(alpha: 0.14),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _gold.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _gold.withValues(alpha: 0.65),
                              ),
                            ),
                            child: Icon(
                              Icons.bookmark_rounded,
                              color: isDark ? _goldLight : const Color(0xFFB45309),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "موقف القراءة الحالي لجميع المصحف",
                                  style: GoogleFonts.cairo(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? _goldLight
                                        : const Color(0xFF78350F),
                                  ),
                                ),
                                Text(
                                  "سورة $_lastReadSurahName ${_lastReadPageNum != null ? '• ص (${QuranTextFormatter.toArabicDigits(_lastReadPageNum!.toString())})' : ''} ${_lastReadVerseNum != null ? '• الآية (${QuranTextFormatter.toArabicDigits(_lastReadVerseNum!)})' : ''}",
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? _gold : accent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              "متابعة",
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFF041D16)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Search Input Box
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? const [Color(0xFF0E211E), Color(0xFF0A171C)]
                            : const [Color(0xFFFFFDF8), Color(0xFFF8F0DB)],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _gold.withValues(alpha: isDark ? 0.45 : 0.65),
                        width: 1.2,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                      style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: "ابحث برقم السورة أو اسمها (مثل: الكهف، يس، 18)...",
                        hintStyle: GoogleFonts.cairo(
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          fontSize: 12.5,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: isDark ? _goldLight : accent,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  size: 18,
                                  color: isDark ? _goldLight : const Color(0xFF64748B),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = "");
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                ),

                // Filter Pills (الكل / مكية / مدنية)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Row(
                    children: [
                      _buildQuranFilterPill("الكل (١١٤)", "all", isDark),
                      const SizedBox(width: 8),
                      _buildQuranFilterPill("مكية (٨٦)", "مكية", isDark),
                      const SizedBox(width: 8),
                      _buildQuranFilterPill("مدنية (٢٨)", "مدنية", isDark),
                    ],
                  ),
                ),

                // Surah List
                Expanded(
                  child: filteredSurahs.isEmpty
                      ? Center(
                          child: Text(
                            "لم نجد سورة مطابقة لـ \"$_searchQuery\"",
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          itemCount: filteredSurahs.length,
                          itemBuilder: (context, index) {
                            final surah = filteredSurahs[index];
                            return _buildSurahCard(context, surah, isDark, accent);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuranDomeHeader(
    BuildContext context,
    bool isDark,
    Color accent,
  ) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0A241D), Color(0xFF0F2D24)]
              : const [Color(0xFFFFFDF7), Color(0xFFF6EED9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
          bottom: Radius.circular(22),
        ),
        border: Border.all(
          color: _gold.withValues(alpha: isDark ? 0.5 : 0.7),
          width: 1.4,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _QuranArchLatticePainter(
                color: _gold.withValues(alpha: isDark ? 0.12 : 0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
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
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: isDark ? _goldLight : accent,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "فهرس المصحف الشريف",
                        style: GoogleFonts.cairo(
                          fontSize: 19.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? _goldLight : context.primaryDarkColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "١١٤ سورة مباركة",
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF78350F),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuranFilterPill(String label, String value, bool isDark) {
    final selected = _selectedFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = value),
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF92400E), Color(0xFFD4AF37)]
                        : const [Color(0xFFFDE68A), Color(0xFFE5B84B)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  )
                : null,
            color: selected
                ? null
                : (isDark ? const Color(0xFF0E211E) : const Color(0xFFFFFDF8)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? _gold
                  : _gold.withValues(alpha: isDark ? 0.35 : 0.55),
              width: selected ? 1.3 : 1.0,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected
                  ? (isDark ? Colors.white : const Color(0xFF451A03))
                  : (isDark ? Colors.white70 : const Color(0xFF334155)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurahCard(
    BuildContext context,
    SurahInfo surah,
    bool isDark,
    Color accent,
  ) {
    final isCurrentSurah = _lastReadSurahNum == surah.number;
    final arabicNumber = QuranTextFormatter.toArabicDigits(surah.number.toString());
    final arabicAyahCount = QuranTextFormatter.toArabicDigits(surah.ayahCount.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: isCurrentSurah
            ? LinearGradient(
                colors: isDark
                    ? const [Color(0xFF1F2410), Color(0xFF141A0B)]
                    : const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              )
            : LinearGradient(
                colors: isDark
                    ? const [Color(0xFF0E211E), Color(0xFF0A171C)]
                    : const [Color(0xFFFFFDF8), Color(0xFFF8F0DB)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrentSurah
              ? _gold
              : _gold.withValues(alpha: isDark ? 0.42 : 0.6),
          width: isCurrentSurah ? 1.6 : 1.15,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuranSurahReaderScreen(
                surah: surah,
                initialPage: isCurrentSurah ? _lastReadPageNum : null,
              ),
            ),
          ).then((_) => _loadLastReadBookmark());
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isCurrentSurah
                      ? _gold
                      : _gold.withValues(alpha: isDark ? 0.16 : 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.65),
                  ),
                ),
                child: Center(
                  child: Text(
                    arabicNumber,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isCurrentSurah
                          ? (isDark ? const Color(0xFF041D16) : Colors.white)
                          : (isDark ? _goldLight : const Color(0xFF78350F)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "سورة ${surah.name}",
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        if (isCurrentSurah) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _gold,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              "موقفك الحالي",
                              style: GoogleFonts.cairo(
                                color: const Color(0xFF041D16),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${surah.type} • $arabicAyahCount آية",
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: _gold.withValues(alpha: isCurrentSurah ? 1.0 : 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuranArchLatticePainter extends CustomPainter {
  final Color color;
  const _QuranArchLatticePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const step = 28.0;
    for (double x = 0; x <= size.width + step; x += step) {
      for (double y = 0; y <= size.height + step; y += step) {
        final path = Path()
          ..moveTo(x, y - 9)
          ..lineTo(x + 9, y)
          ..lineTo(x, y + 9)
          ..lineTo(x - 9, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QuranArchLatticePainter oldDelegate) =>
      oldDelegate.color != color;
}
