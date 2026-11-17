import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:religious_tasks_app/core/services/storage_service.dart';
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

  @override
  void initState() {
    super.initState();
    // Pre-cache Quran JSON in background for instant surah opening
    QuranRepository.loadQuran();
    _loadLastReadBookmark();
  }

  void _loadLastReadBookmark() {
    final prefs = StorageService.instance.prefs;
    final lastNum = prefs.getInt('last_read_surah_number');
    final lastName = prefs.getString('last_read_surah_name');
    if (lastNum != null) {
      final lastVerse = prefs.getString('quran_bookmark_verse_$lastNum');
      setState(() {
        _lastReadSurahNum = lastNum;
        _lastReadSurahName = lastName;
        _lastReadVerseNum = lastVerse;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark
        ? const [Color(0xFF0B131E), Color(0xFF152233)]
        : const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)];

    const accent = Color(0xFF0F766E);

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
        appBar: AppBar(
          title: Text(
            "فهرس المصحف الشريف 📖",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: bgGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Last Read Resume Banner
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
                        builder: (_) => QuranSurahReaderScreen(surah: surah),
                      ),
                    ).then((_) => _loadLastReadBookmark());
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 10, 12, 2),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.amber.shade700.withValues(alpha: 0.6)
                            : Colors.amber.shade600.withValues(alpha: 0.7),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "📌 موقف القراءة الحالي",
                                style: GoogleFonts.cairo(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                                ),
                              ),
                              Text(
                                "سورة $_lastReadSurahName ${_lastReadVerseNum != null ? '• الآية (${QuranTextFormatter.toArabicDigits(_lastReadVerseNum!)})' : ''}",
                                style: GoogleFonts.cairo(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "متابعة 🎯",
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "ابحث برقم السورة أو اسمها (مثل: الكهف، يس، 18)...",
                      hintStyle: GoogleFonts.cairo(
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        fontSize: 12.5,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: accent),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = "");
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),

              // Filter Choice Chips (الكل / مكية / مدنية)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: Text("الكل (١١٤)", style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                      selected: _selectedFilter == "all",
                      selectedColor: accent,
                      backgroundColor: accent.withValues(alpha: 0.1),
                      labelStyle: TextStyle(color: _selectedFilter == "all" ? Colors.white : (isDark ? Colors.white70 : accent)),
                      onSelected: (_) => setState(() => _selectedFilter = "all"),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text("مكية (٨٦)", style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                      selected: _selectedFilter == "مكية",
                      selectedColor: accent,
                      backgroundColor: accent.withValues(alpha: 0.1),
                      labelStyle: TextStyle(color: _selectedFilter == "مكية" ? Colors.white : (isDark ? Colors.white70 : accent)),
                      onSelected: (_) => setState(() => _selectedFilter = "مكية"),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text("مدنية (٢٨)", style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                      selected: _selectedFilter == "مدنية",
                      selectedColor: accent,
                      backgroundColor: accent.withValues(alpha: 0.1),
                      labelStyle: TextStyle(color: _selectedFilter == "مدنية" ? Colors.white : (isDark ? Colors.white70 : accent)),
                      onSelected: (_) => setState(() => _selectedFilter = "مدنية"),
                    ),
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
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isCurrentSurah ? 3 : 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCurrentSurah
              ? Colors.amber.shade700
              : (isDark ? Colors.white10 : accent.withValues(alpha: 0.2)),
          width: isCurrentSurah ? 1.8 : 1,
        ),
      ),
      color: isCurrentSurah
          ? (isDark ? const Color(0xFF262010) : const Color(0xFFFFFBEB))
          : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuranSurahReaderScreen(surah: surah),
            ),
          ).then((_) => _loadLastReadBookmark());
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Surah Number Badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isCurrentSurah
                      ? Colors.amber.shade700
                      : accent.withValues(alpha: isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrentSurah
                        ? Colors.amber.shade800
                        : accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    arabicNumber,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isCurrentSurah ? Colors.white : accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Surah Details
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "موقف السورة 📌",
                              style: GoogleFonts.cairo(
                                color: Colors.white,
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
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Navigation Icon
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isCurrentSurah
                    ? Colors.amber.shade700
                    : (isDark ? Colors.white38 : Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
