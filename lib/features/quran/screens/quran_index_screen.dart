import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:religious_tasks_app/core/services/storage_service.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/quran/data/quran_data.dart';
import 'package:religious_tasks_app/features/quran/data/quran_repository.dart';
import 'package:religious_tasks_app/features/quran/screens/quran_surah_reader_screen.dart';

class QuranIndexScreen extends StatefulWidget {
  final bool openLastReadOnStart;

  const QuranIndexScreen({
    super.key,
    this.openLastReadOnStart = false,
  });

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

  int? _savedPageBookmark;
  int? _savedPageSurahNum;
  String? _savedPageSurahName;

  int? _savedVersePage;
  String? _savedVerseNum;
  int? _savedVerseSurahNum;
  String? _savedVerseSurahName;

  @override
  void initState() {
    super.initState();
    QuranRepository.loadQuran();
    _loadLastReadBookmark();
    if (widget.openLastReadOnStart) {
      _tryAutoOpenLastReadPage();
    }
  }

  void _tryAutoOpenLastReadPage() {
    final prefs = StorageService.instance.prefs;
    final lastPage = prefs.getInt('last_read_page_number');
    if (lastPage == null || lastPage < 1 || lastPage > 604) return;
    final lastSurahNum = prefs.getInt('last_read_surah_number') ?? 1;
    final targetSurah = QuranData.surahs.firstWhere(
      (s) => s.number == lastSurahNum,
      orElse: () => QuranData.surahs.first,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuranSurahReaderScreen(
            surah: targetSurah,
            initialPage: lastPage,
          ),
        ),
      ).then((_) {
        if (mounted) _loadLastReadBookmark();
      });
    });
  }

  void _loadLastReadBookmark() {
    final prefs = StorageService.instance.prefs;
    final pageBm = prefs.getInt('quran_page_bookmark_number');
    final pageBmSurahNum = prefs.getInt('quran_page_bookmark_surah_number');
    final pageBmSurahName = prefs.getString('quran_page_bookmark_surah_name');

    final verseBmPage = prefs.getInt('quran_verse_bookmark_page');
    final verseBmNum = prefs.getString('quran_verse_bookmark_verse');
    final verseBmSurahNum = prefs.getInt('quran_verse_bookmark_surah_number');
    final verseBmSurahName = prefs.getString('quran_verse_bookmark_surah_name');

    final globalSurahNum = prefs.getInt('quran_global_bookmark_surah_number');
    final globalSurahName = prefs.getString('quran_global_bookmark_surah_name');
    final globalVerse = prefs.getString('quran_global_bookmark_verse');
    final globalPage = prefs.getInt('quran_global_bookmark_page');

    setState(() {
      _savedPageBookmark = pageBm;
      _savedPageSurahNum = pageBmSurahNum;
      _savedPageSurahName = pageBmSurahName;

      _savedVersePage = verseBmPage;
      _savedVerseNum = verseBmNum;
      _savedVerseSurahNum = verseBmSurahNum;
      _savedVerseSurahName = verseBmSurahName;

      _lastReadSurahNum = pageBmSurahNum ?? verseBmSurahNum ?? globalSurahNum;
      _lastReadSurahName = pageBmSurahName ?? verseBmSurahName ?? globalSurahName;
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
                if (_savedPageBookmark != null ||
                    (_savedVersePage != null && _savedVerseNum != null))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        if (_savedPageBookmark != null)
                          Expanded(
                            child: _buildSavedBookmarkCard(
                              context: context,
                              isDark: isDark,
                              accent: accent,
                              icon: Icons.menu_book_rounded,
                              iconColor: isDark
                                  ? Colors.tealAccent
                                  : Colors.teal.shade700,
                              label: "الصفحة المحفوظة",
                              subtitle:
                                  "${_savedPageSurahName != null ? '$_savedPageSurahName • ' : ''}ص ${QuranTextFormatter.toArabicDigits(_savedPageBookmark!.toString())}",
                              actionLabel: "فتح",
                              compact: _savedVersePage != null &&
                                  _savedVerseNum != null,
                              onTap: () {
                                final surah = QuranData.surahs.firstWhere(
                                  (s) => s.number == (_savedPageSurahNum ?? 1),
                                  orElse: () => QuranData.surahs.first,
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QuranSurahReaderScreen(
                                      surah: surah,
                                      initialPage: _savedPageBookmark,
                                    ),
                                  ),
                                ).then((_) => _loadLastReadBookmark());
                              },
                            ),
                          ),
                        if (_savedPageBookmark != null &&
                            _savedVersePage != null &&
                            _savedVerseNum != null)
                          const SizedBox(width: 8),
                        if (_savedVersePage != null && _savedVerseNum != null)
                          Expanded(
                            child: _buildSavedBookmarkCard(
                              context: context,
                              isDark: isDark,
                              accent: accent,
                              icon: Icons.format_quote_rounded,
                              iconColor:
                                  isDark ? _goldLight : const Color(0xFFB45309),
                              label: "الآية المحفوظة",
                              subtitle:
                                  "${_savedVerseSurahName != null ? '$_savedVerseSurahName • ' : ''}ص ${QuranTextFormatter.toArabicDigits(_savedVersePage!.toString())} • آية ${QuranTextFormatter.toArabicDigits(_savedVerseNum!)}",
                              actionLabel: "فتح",
                              compact: _savedPageBookmark != null,
                              onTap: () {
                                final surah = QuranData.surahs.firstWhere(
                                  (s) => s.number == (_savedVerseSurahNum ?? 1),
                                  orElse: () => QuranData.surahs.first,
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QuranSurahReaderScreen(
                                      surah: surah,
                                      initialPage: _savedVersePage,
                                    ),
                                  ),
                                ).then((_) => _loadLastReadBookmark());
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                if (_savedPageBookmark == null &&
                    (_savedVersePage == null || _savedVerseNum == null) &&
                    _lastReadSurahNum != null &&
                    _lastReadSurahName != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: _buildSavedBookmarkCard(
                      context: context,
                      isDark: isDark,
                      accent: accent,
                      icon: Icons.bookmark_rounded,
                      iconColor: isDark ? _goldLight : const Color(0xFFB45309),
                      label: "موقف القراءة الحالي لجميع المصحف",
                      subtitle:
                          "سورة $_lastReadSurahName ${_lastReadPageNum != null ? '• ص (${QuranTextFormatter.toArabicDigits(_lastReadPageNum!.toString())})' : ''} ${_lastReadVerseNum != null ? '• الآية (${QuranTextFormatter.toArabicDigits(_lastReadVerseNum!)})' : ''}",
                      actionLabel: "متابعة",
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

  Widget _buildSavedBookmarkCard({
    required BuildContext context,
    required bool isDark,
    required Color accent,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF0E211E), Color(0xFF0A171C)]
                : const [Color(0xFFFFFDF8), Color(0xFFF8F0DB)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _gold.withValues(alpha: isDark ? 0.6 : 0.75),
            width: 1.25,
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
              padding: EdgeInsets.all(compact ? 6 : 8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.55),
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: compact ? 15 : 18,
              ),
            ),
            SizedBox(width: compact ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: compact ? 9.5 : 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? _goldLight : const Color(0xFF78350F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: compact ? 11.5 : 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!compact)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? _gold : accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF041D16) : Colors.white,
                  ),
                ),
              )
            else
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: _gold,
              ),
          ],
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
              const SizedBox(width: 8),
              _SurahRevelationBadge(
                isMakki: surah.type == "مكية",
              ),
              const SizedBox(width: 10),
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

class _SurahRevelationBadge extends StatelessWidget {
  final bool isMakki;

  const _SurahRevelationBadge({
    required this.isMakki,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isMakki ? "سورة مكية" : "سورة مدنية",
      child: Image.asset(
        isMakki
            ? 'assets/images/makkah_icon.png'
            : 'assets/images/madinah_icon.png',
        width: 38,
        height: 38,
        cacheWidth: 96,
        cacheHeight: 96,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
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
