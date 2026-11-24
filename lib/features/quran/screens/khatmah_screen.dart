import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:religious_tasks_app/core/services/storage_service.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/quran/data/quran_data.dart';
import 'package:religious_tasks_app/features/quran/data/quran_page_mapping.dart';
import 'package:religious_tasks_app/features/quran/data/quran_repository.dart';
import 'package:religious_tasks_app/features/quran/screens/quran_index_screen.dart';
import 'package:religious_tasks_app/features/quran/screens/quran_surah_reader_screen.dart';
import 'package:religious_tasks_app/features/quran/services/khatmah_planner_service.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';

class KhatmahScreen extends StatefulWidget {
  const KhatmahScreen({super.key});

  @override
  State<KhatmahScreen> createState() => _KhatmahScreenState();
}

class _KhatmahScreenState extends State<KhatmahScreen> {
  Color get _emerald => context.primaryColor;
  Color get _emeraldDark => context.primaryDarkColor;
  static const Color _gold = Color(0xFFD4AF37);
  static const List<int> _juzStartPages = [
    1, 22, 42, 62, 82, 102, 122, 142, 162, 182,
    202, 222, 242, 262, 282, 302, 322, 342, 362, 382,
    402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
  ];

  late TextEditingController _ayahController;
  late SurahInfo _selectedSurah;
  KhatmahPlan? _plan;

  String _resolvedKey = '';
  String _resolvedVerseText = '';
  int _resolvedPage = 1;
  bool _isResolvingVerse = false;
  bool _isSavingManual = false;

  @override
  void initState() {
    super.initState();
    final vm = Provider.of<TasksViewModel>(context, listen: false);
    vm.syncQuranBookmarkFromPrefs();
    _selectedSurah = QuranRepository.findSurahByName(vm.lastSurah);
    _ayahController = TextEditingController(text: vm.lastAyah.toString());
    _resolvedPage = vm.lastPage;
    _resolvedVerseText = vm.lastVerseText;

    // Preload Quran data in background for instant verse lookup
    QuranRepository.loadQuran();
    QuranRepository.loadPageMapping();

    _loadPlan();
    _ensureVerseResolved(
      surahNumber: _selectedSurah.number,
      ayahNumber: vm.lastAyah,
      fallbackVerseText: vm.lastVerseText,
      fallbackPage: vm.lastPage,
    );
  }

  @override
  void dispose() {
    _ayahController.dispose();
    super.dispose();
  }

  Future<void> _loadPlan() async {
    final plan = await KhatmahPlannerService.loadPlan();
    if (mounted) {
      setState(() {
        _plan = plan;
      });
    }
  }

  Future<void> _ensureVerseResolved({
    required int surahNumber,
    required int ayahNumber,
    String fallbackVerseText = '',
    int fallbackPage = 1,
  }) async {
    final key = '$surahNumber:$ayahNumber';
    if (_resolvedKey == key && _resolvedVerseText.isNotEmpty) return;

    _resolvedKey = key;
    if (mounted) {
      setState(() {
        _isResolvingVerse = true;
      });
    }

    final results = await Future.wait([
      QuranRepository.getVerseText(surahNumber, ayahNumber),
      QuranRepository.getPageForAyah(surahNumber, ayahNumber),
    ]);

    if (!mounted || _resolvedKey != key) return;

    final fetchedText = results[0] as String?;
    final fetchedPage = results[1] as int;

    setState(() {
      _resolvedVerseText = (fetchedText != null && fetchedText.isNotEmpty)
          ? fetchedText
          : fallbackVerseText;
      _resolvedPage = fetchedPage > 0 ? fetchedPage : fallbackPage;
      _isResolvingVerse = false;
    });
  }

  void _syncEditorWithVm(TasksViewModel vm) {
    final surah = QuranRepository.findSurahByName(vm.lastSurah);
    _selectedSurah = surah;
    final ayahStr = vm.lastAyah.clamp(1, surah.ayahCount).toString();
    if (_ayahController.text != ayahStr) {
      _ayahController.text = ayahStr;
    }
  }

  Future<void> _saveManualPosition(TasksViewModel vm) async {
    if (_isSavingManual) return;
    FocusScope.of(context).unfocus();

    final parsedAyah =
        QuranTextFormatter.parseVerseNumber(_ayahController.text) ?? 1;
    final clampedAyah = parsedAyah.clamp(1, _selectedSurah.ayahCount);
    _ayahController.text = clampedAyah.toString();

    setState(() => _isSavingManual = true);

    try {
      final results = await Future.wait([
        QuranRepository.getPageForAyah(_selectedSurah.number, clampedAyah),
        QuranRepository.getVerseText(_selectedSurah.number, clampedAyah),
      ]);

      final page = (results[0] as int).clamp(1, 604);
      final verseText = (results[1] as String?) ?? '';
      final words = verseText.split(RegExp(r'\s+'));
      final snippet = words.length <= 7
          ? verseText
          : '${words.take(7).join(' ')} ...';

      // Sync global Quran bookmark so QuranIndex & QuranSurahReader stay aligned
      if (StorageService.isInitialized) {
        final prefs = StorageService.instance.prefs;
        await prefs.setString(
          'quran_global_bookmark_verse',
          clampedAyah.toString(),
        );
        await prefs.setInt('quran_global_bookmark_page', page);
        await prefs.setString(
          'quran_global_bookmark_surah_name',
          _selectedSurah.name,
        );
        await prefs.setInt(
          'quran_global_bookmark_surah_number',
          _selectedSurah.number,
        );
        await prefs.setString('quran_global_bookmark_snippet', snippet);
        await prefs.setString('quran_global_bookmark_full_text', verseText);
        await prefs.setInt('last_read_surah_number', _selectedSurah.number);
        await prefs.setString('last_read_surah_name', _selectedSurah.name);
      }

      await vm.updateQuranProgress(
        _selectedSurah.name,
        clampedAyah,
        surahNumber: _selectedSurah.number,
        page: page,
        verseText: verseText,
        hasBookmark: true,
      );

      if (!mounted) return;
      setState(() {
        _resolvedKey = '${_selectedSurah.number}:$clampedAyah';
        _resolvedPage = page;
        _resolvedVerseText = verseText;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: _gold.withValues(alpha: 0.5)),
          ),
          content: Row(
            children: [
              const Icon(Icons.bookmark_added_rounded,
                  color: Colors.amberAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "تم حفظ موقفك: سورة ${_selectedSurah.name} • آية ${QuranTextFormatter.toArabicDigits(clampedAyah.toString())} • ص ${QuranTextFormatter.toArabicDigits(page.toString())}",
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingManual = false);
      }
    }
  }

  Future<void> _openQuranAtPosition(
    SurahInfo surah,
    int page,
    TasksViewModel vm,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuranSurahReaderScreen(
          surah: surah,
          initialPage: page,
        ),
      ),
    );
    if (!mounted) return;
    vm.syncQuranBookmarkFromPrefs();
    _syncEditorWithVm(vm);
    _resolvedKey = '';
    _ensureVerseResolved(
      surahNumber: QuranRepository.findSurahByName(vm.lastSurah).number,
      ayahNumber: vm.lastAyah,
      fallbackVerseText: vm.lastVerseText,
      fallbackPage: vm.lastPage,
    );
  }

  void _showSurahPickerSheet(bool isDark) {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final query = searchCtrl.text.trim();
            final filtered = QuranData.surahs.where((s) {
              if (query.isEmpty) return true;
              return s.name.contains(query) ||
                  s.englishName.toLowerCase().contains(query.toLowerCase()) ||
                  s.number.toString() == query;
            }).toList();

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                height: MediaQuery.of(ctx).size.height * 0.72,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131D2B) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          Icon(Icons.menu_book_rounded, color: _emerald),
                          const SizedBox(width: 8),
                          Text(
                            "اختر السورة",
                            style: GoogleFonts.cairo(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: "ابحث باسم السورة أو رقمها...",
                          hintStyle: GoogleFonts.cairo(fontSize: 13),
                          prefixIcon:
                              Icon(Icons.search_rounded, color: _emerald),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, index) {
                          final surah = filtered[index];
                          final isSelected =
                              surah.number == _selectedSurah.number;
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() {
                                _selectedSurah = surah;
                                final curr = int.tryParse(
                                        _ayahController.text.trim()) ??
                                    1;
                                if (curr > surah.ayahCount || curr < 1) {
                                  _ayahController.text = "1";
                                }
                              });
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _emerald.withValues(alpha: 0.14)
                                    : (isDark
                                        ? const Color(0xFF1B2738)
                                        : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? _emerald
                                      : Colors.transparent,
                                  width: 1.4,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? _emerald
                                          : _emerald.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        QuranTextFormatter.toArabicDigits(
                                            surah.number.toString()),
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : _emerald,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "سورة ${surah.name}",
                                          style: GoogleFonts.cairo(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "${surah.type} • ${QuranTextFormatter.toArabicDigits(surah.ayahCount.toString())} آية",
                                          style: GoogleFonts.cairo(
                                            fontSize: 11.5,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle_rounded,
                                        color: _emerald),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() => searchCtrl.dispose());
  }

  void _showPlannerDialog(int currentPage) {
    double targetDays = (_plan?.targetDays ?? 30).toDouble();
    bool startFromCurrentPage = false;
    final messenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final startPage = startFromCurrentPage ? currentPage.clamp(1, 604) : 1;
          final remainingPages = 605 - startPage;
          final dailyPages = (remainingPages / targetDays).ceil();
          final pagesPerPrayer = (dailyPages / 5).ceil();

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor:
                  isDark ? const Color(0xFF162130) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _emerald.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: _gold, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "المنظم الذكي للختمة",
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "اختر المدة المناسبة لك، وسنحسب وردك اليومي وتوزيعه بعد كل صلاة تلقائياً:",
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [7, 15, 30, 60].map((d) {
                        final selected = targetDays.toInt() == d;
                        return ChoiceChip(
                          label: Text(
                            "${QuranTextFormatter.toArabicDigits(d.toString())} يوماً",
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : _emerald),
                            ),
                          ),
                          selected: selected,
                          selectedColor: _emerald,
                          backgroundColor: _emerald.withValues(alpha: 0.1),
                          onSelected: (_) => setDialogState(() {
                            targetDays = d.toDouble();
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "مدة الختمة:",
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "${QuranTextFormatter.toArabicDigits(targetDays.toInt().toString())} يوماً",
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            color: _emerald,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: targetDays,
                      min: 5,
                      max: 60,
                      divisions: 55,
                      activeColor: _emerald,
                      label: "${targetDays.toInt()} يوماً",
                      onChanged: (val) => setDialogState(() {
                        targetDays = val;
                      }),
                    ),
                    if (currentPage > 1) ...[
                      const SizedBox(height: 4),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        activeTrackColor: _emerald,
                        title: Text(
                          "البدء من موقفي الحالي (ص ${QuranTextFormatter.toArabicDigits(currentPage.toString())})",
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: startFromCurrentPage,
                        onChanged: (val) => setDialogState(() {
                          startFromCurrentPage = val;
                        }),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _emerald.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_stories_rounded,
                                  color: _emerald, size: 19),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "الورد اليومي: ${QuranTextFormatter.toArabicDigits(dailyPages.toString())} صفحة / يومياً",
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.mosque_rounded,
                                  color: _emerald, size: 19),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "بعد كل صلاة: نحو ${QuranTextFormatter.toArabicDigits(pagesPerPrayer.toString())} صفحات",
                                  style: GoogleFonts.cairo(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (_plan != null)
                  TextButton(
                    onPressed: () async {
                      await KhatmahPlannerService.clearPlan();
                      await _loadPlan();
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        messenger.showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              "تم إيقاف خطة الختمة",
                              style: GoogleFonts.cairo(),
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      "إيقاف الخطة",
                      style: GoogleFonts.cairo(color: Colors.redAccent),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("إلغاء", style: GoogleFonts.cairo()),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await KhatmahPlannerService.savePlan(
                      targetDays.toInt(),
                      startPage: startPage,
                    );
                    await _loadPlan();
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      messenger.showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            "تم اعتماد خطة الختمة الذكية بنجاح",
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _emerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "اعتماد الخطة",
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark
        ? const [Color(0xFF0B131E), Color(0xFF132030)]
        : const [Color(0xFFF3F8F6), Color(0xFFE7F2EE)];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Consumer<TasksViewModel>(
        builder: (context, tasksVm, _) {
          final currentSurahInfo =
              QuranRepository.findSurahByName(tasksVm.lastSurah);
          final currentAyah =
              tasksVm.lastAyah.clamp(1, currentSurahInfo.ayahCount);
          final targetKey = '${currentSurahInfo.number}:$currentAyah';

          if (_resolvedKey != targetKey && !_isResolvingVerse) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _ensureVerseResolved(
                surahNumber: currentSurahInfo.number,
                ayahNumber: currentAyah,
                fallbackVerseText: tasksVm.lastVerseText,
                fallbackPage: tasksVm.lastPage,
              );
            });
          }

          final effectivePage =
              (_resolvedKey == targetKey ? _resolvedPage : tasksVm.lastPage)
                  .clamp(1, 604);
          final effectiveJuz = QuranPageMapping.getJuzForPage(effectivePage);
          final effectiveVerseText = _resolvedKey == targetKey &&
                  _resolvedVerseText.isNotEmpty
              ? _resolvedVerseText
              : tasksVm.lastVerseText;

          final completedAyahs = QuranRepository.getCompletedAyahsCount(
            currentSurahInfo.number,
            currentAyah,
          );
          final progressRatio = (completedAyahs / 6236).clamp(0.0, 1.0);
          final progressPercent = (progressRatio * 100).toStringAsFixed(1);
          final remainingPages = (604 - effectivePage).clamp(0, 604);

          return Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor:
                isDark ? const Color(0xFF0B131E) : const Color(0xFFF3F8F6),
            appBar: AppBar(
              elevation: 0,
              centerTitle: true,
              backgroundColor:
                  isDark ? const Color(0xFF0B131E) : _emerald,
              foregroundColor: Colors.white,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              title: Text(
                "متابع ومخطط الختمة",
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.menu_book_rounded),
                  tooltip: "فهرس المصحف الشريف",
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QuranIndexScreen(),
                      ),
                    );
                    if (!mounted) return;
                    tasksVm.syncQuranBookmarkFromPrefs();
                    _syncEditorWithVm(tasksVm);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: "المنظم الذكي للختمة",
                  onPressed: () => _showPlannerDialog(effectivePage),
                ),
              ],
            ),
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: bgGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeroPositionCard(
                        context: context,
                        isDark: isDark,
                        vm: tasksVm,
                        surah: currentSurahInfo,
                        ayah: currentAyah,
                        page: effectivePage,
                        juz: effectiveJuz,
                        verseText: effectiveVerseText,
                        progressRatio: progressRatio,
                        progressPercent: progressPercent,
                        completedAyahs: completedAyahs,
                        remainingPages: remainingPages,
                      ),
                      const SizedBox(height: 16),
                      _buildSmartPlannerCard(
                        isDark: isDark,
                        vm: tasksVm,
                        currentPage: effectivePage,
                      ),
                      const SizedBox(height: 16),
                      _buildManualUpdateCard(
                        isDark: isDark,
                        vm: tasksVm,
                      ),
                      const SizedBox(height: 16),
                      _buildJuzOverviewCard(
                        isDark: isDark,
                        currentJuz: effectiveJuz,
                        vm: tasksVm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroPositionCard({
    required BuildContext context,
    required bool isDark,
    required TasksViewModel vm,
    required SurahInfo surah,
    required int ayah,
    required int page,
    required int juz,
    required String verseText,
    required double progressRatio,
    required String progressPercent,
    required int completedAyahs,
    required int remainingPages,
  }) {
    final arabicAyah = QuranTextFormatter.toArabicDigits(ayah.toString());
    final arabicPage = QuranTextFormatter.toArabicDigits(page.toString());
    final arabicJuz = QuranTextFormatter.toArabicDigits(juz.toString());
    final arabicPercent = QuranTextFormatter.toArabicDigits(progressPercent);
    final arabicRemaining =
        QuranTextFormatter.toArabicDigits(remainingPages.toString());

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0E2926), Color(0xFF132234)]
              : [_emerald, _emeraldDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _gold.withValues(alpha: isDark ? 0.45 : 0.6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : _emerald).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Status Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _gold.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(
                    Icons.bookmark_rounded,
                    color: Colors.amberAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "موقف القراءة الحالي",
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            vm.hasQuranBookmark
                                ? Icons.sync_rounded
                                : Icons.auto_stories_rounded,
                            size: 13,
                            color: Colors.amberAccent.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              vm.hasQuranBookmark
                                  ? "متزامن تلقائياً مع المصحف الشريف"
                                  : "اضغط على أي آية في المصحف لحفظها تلقائياً",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _gold.withValues(alpha: 0.65)),
                  ),
                  child: Text(
                    "$arabicPercent٪",
                    style: GoogleFonts.cairo(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Surah / Ayah / Page / Juz Stat Grid
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  _buildHeroStatItem("السورة", surah.name, flex: 3),
                  _buildStatDivider(),
                  _buildHeroStatItem("الآية", arabicAyah, flex: 2),
                  _buildStatDivider(),
                  _buildHeroStatItem("الصفحة", arabicPage, flex: 2),
                  _buildStatDivider(),
                  _buildHeroStatItem("الجزء", arabicJuz, flex: 2),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${QuranTextFormatter.toArabicDigits(completedAyahs.toString())} من ٦٢٣٦ آية",
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    Text(
                      remainingPages == 0
                          ? "أتممت قراءة المصحف بحمد الله"
                          : "متبقي $arabicRemaining صفحة للختمة",
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.amberAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Current Stopped Ayah Display Card
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF101B27)
                    : const Color(0xFFFFFDF7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _gold.withValues(alpha: isDark ? 0.45 : 0.7),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            size: 18,
                            color: isDark ? Colors.amberAccent : _emerald,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "الآية التي تقف عندها",
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.amberAccent : _emerald,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${surah.name} : $arabicAyah",
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.amber.shade200
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_isResolvingVerse && verseText.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: isDark ? Colors.amberAccent : _emerald,
                          ),
                        ),
                      ),
                    )
                  else if (verseText.isNotEmpty)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: verseText,
                            style: GoogleFonts.amiri(
                              fontSize: 21,
                              height: 1.9,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          TextSpan(
                            text: "  ﴿$arabicAyah﴾",
                            style: GoogleFonts.amiri(
                              fontSize: 20,
                              height: 1.9,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.amberAccent
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    Text(
                      "سورة ${surah.name} • الآية $arabicAyah",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Continue Reading CTA Button
            ElevatedButton.icon(
              onPressed: () => _openQuranAtPosition(surah, page, vm),
              icon: const Icon(Icons.menu_book_rounded, size: 20),
              label: Text(
                "متابعة القراءة من هذه الآية",
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStatItem(String label, String value, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.cairo(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.16),
    );
  }

  Widget _buildSmartPlannerCard({
    required bool isDark,
    required TasksViewModel vm,
    required int currentPage,
  }) {
    final plan = _plan;
    final todayRange = plan?.getTodayRange();
    final elapsedDay = (plan?.elapsedDays() ?? 0) + 1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172231) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : _emerald.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_note_rounded,
                    color: _gold, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "خطة الختمة الذكية",
                      style: GoogleFonts.cairo(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      plan == null
                          ? "نظّم وردك اليومي حسب المدة المناسبة لك"
                          : "خطة ${QuranTextFormatter.toArabicDigits(plan.targetDays.toString())} يوماً • اليوم ${QuranTextFormatter.toArabicDigits(elapsedDay.clamp(1, plan.targetDays).toString())}",
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _showPlannerDialog(currentPage),
                icon: Icon(
                  plan == null ? Icons.add_circle_outline_rounded : Icons.edit_rounded,
                  size: 17,
                  color: _emerald,
                ),
                label: Text(
                  plan == null ? "إعداد" : "تعديل",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: isDark ? Colors.tealAccent : _emerald,
                  ),
                ),
              ),
            ],
          ),
          if (plan != null && todayRange != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildMiniPlanMetric(
                    isDark: isDark,
                    icon: Icons.auto_stories_rounded,
                    label: "الورد اليومي",
                    value:
                        "${QuranTextFormatter.toArabicDigits(plan.pagesPerDay.toString())} صفحة",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniPlanMetric(
                    isDark: isDark,
                    icon: Icons.mosque_rounded,
                    label: "بعد كل صلاة",
                    value:
                        "${QuranTextFormatter.toArabicDigits(plan.pagesPerPrayer.toString())} صفحات",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _emerald.withValues(alpha: isDark ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _emerald.withValues(alpha: 0.22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.today_rounded,
                          size: 17, color: _emerald),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          todayRange.isCompleted
                              ? "اكتملت مدة خطة الختمة. يمكنك بدء خطة جديدة."
                              : "ورد اليوم: من صفحة ${QuranTextFormatter.toArabicDigits(todayRange.firstPage.toString())} إلى ${QuranTextFormatter.toArabicDigits(todayRange.lastPage.toString())}",
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.tealAccent : _emeraldDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!todayRange.isCompleted) ...[
                    const SizedBox(height: 6),
                    _buildTodayStatusText(
                      isDark: isDark,
                      currentPage: currentPage,
                      firstPage: todayRange.firstPage,
                      lastPage: todayRange.lastPage,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final targetPage = currentPage >= todayRange.firstPage &&
                                  currentPage <= todayRange.lastPage
                              ? currentPage
                              : todayRange.firstPage;
                          final range = QuranPageMapping.getPageRange(targetPage);
                          final surah = QuranData.surahs.firstWhere(
                            (s) => s.number == range.startSurah,
                            orElse: () => QuranData.surahs.first,
                          );
                          _openQuranAtPosition(surah, targetPage, vm);
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 19),
                        label: Text(
                          "افتح ورد اليوم (ص ${QuranTextFormatter.toArabicDigits((currentPage >= todayRange.firstPage && currentPage <= todayRange.lastPage ? currentPage : todayRange.firstPage).toString())})",
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              isDark ? Colors.tealAccent : _emerald,
                          side: BorderSide(
                            color: _emerald.withValues(alpha: 0.45),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showPlannerDialog(currentPage),
              icon: const Icon(Icons.edit_calendar_rounded, size: 18),
              label: Text(
                "تحديد خطة ختمة ذكية",
                style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _emerald.withValues(alpha: 0.12),
                foregroundColor: isDark ? Colors.tealAccent : _emerald,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayStatusText({
    required bool isDark,
    required int currentPage,
    required int firstPage,
    required int lastPage,
  }) {
    final String msg;
    final Color color;
    final IconData icon;

    if (currentPage >= lastPage) {
      msg = "ما شاء الله! وصلت لهدف ورد اليوم وأتممته";
      color = isDark ? Colors.greenAccent : Colors.green.shade700;
      icon = Icons.check_circle_rounded;
    } else if (currentPage >= firstPage) {
      final left = lastPage - currentPage + 1;
      msg =
          "أنت في المسار الصحيح • متبقي ${QuranTextFormatter.toArabicDigits(left.toString())} صفحات لإتمام ورد اليوم";
      color = isDark ? Colors.amberAccent : const Color(0xFFB45309);
      icon = Icons.trending_up_rounded;
    } else {
      final behind = firstPage - currentPage;
      msg =
          "متأخر بـ ${QuranTextFormatter.toArabicDigits(behind.toString())} صفحة عن بداية ورد اليوم";
      color = isDark ? Colors.orangeAccent : Colors.deepOrange.shade700;
      icon = Icons.schedule_rounded;
    }

    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            msg,
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniPlanMetric({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2B3C) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _emerald),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 10.5,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualUpdateCard({
    required bool isDark,
    required TasksViewModel vm,
  }) {
    final maxAyah = _selectedSurah.ayahCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172231) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : _emerald.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _emerald.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.edit_location_alt_rounded,
                    color: _emerald, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "تحديث الموقف يدوياً",
                      style: GoogleFonts.cairo(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "في حال القراءة من مصحف ورقي، حدد السورة والآية هنا",
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Searchable Surah Picker Tile
          InkWell(
            onTap: () => _showSurahPickerSheet(isDark),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2B3C)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _emerald.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _emerald.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        QuranTextFormatter.toArabicDigits(
                            _selectedSurah.number.toString()),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _emerald,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "سورة ${_selectedSurah.name}",
                          style: GoogleFonts.cairo(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${_selectedSurah.type} • ${QuranTextFormatter.toArabicDigits(maxAyah.toString())} آية",
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark ? Colors.white70 : _emerald,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Ayah Stepper & Field
          Row(
            children: [
              _buildStepperButton(
                isDark: isDark,
                icon: Icons.remove_rounded,
                onTap: () {
                  final curr =
                      QuranTextFormatter.parseVerseNumber(_ayahController.text) ??
                          1;
                  final next = (curr - 1).clamp(1, maxAyah);
                  setState(() => _ayahController.text = next.toString());
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _ayahController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText:
                        "رقم الآية (١ - ${QuranTextFormatter.toArabicDigits(maxAyah.toString())})",
                    labelStyle: GoogleFonts.cairo(
                      fontSize: 12,
                      color: isDark ? Colors.tealAccent : _emerald,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E2B3C)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _emerald.withValues(alpha: 0.35),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _emerald.withValues(alpha: 0.35),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: _emerald, width: 1.6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _saveManualPosition(vm),
                ),
              ),
              const SizedBox(width: 10),
              _buildStepperButton(
                isDark: isDark,
                icon: Icons.add_rounded,
                onTap: () {
                  final curr =
                      QuranTextFormatter.parseVerseNumber(_ayahController.text) ??
                          1;
                  final next = (curr + 1).clamp(1, maxAyah);
                  setState(() => _ayahController.text = next.toString());
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _isSavingManual ? null : () => _saveManualPosition(vm),
            icon: _isSavingManual
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.bookmark_added_rounded, size: 20),
            label: Text(
              "حفظ وتحديث الموقف",
              style: GoogleFonts.cairo(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _emerald,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required bool isDark,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 48,
        height: 50,
        decoration: BoxDecoration(
          color: _emerald.withValues(alpha: isDark ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _emerald.withValues(alpha: 0.35)),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.tealAccent : _emerald,
        ),
      ),
    );
  }

  Widget _buildJuzOverviewCard({
    required bool isDark,
    required int currentJuz,
    required TasksViewModel vm,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172231) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : _emerald.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _emerald.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.grid_view_rounded,
                        color: _emerald, size: 19),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "خريطة الأجزاء (٣٠ جزءاً)",
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                "الجزء ${QuranTextFormatter.toArabicDigits(currentJuz.toString())} / ٣٠",
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.amberAccent : _emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 30,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (_, index) {
              final juzNum = index + 1;
              final isCompleted = juzNum < currentJuz;
              final isCurrent = juzNum == currentJuz;

              Color bg;
              Color fg;
              Border? border;

              if (isCurrent) {
                bg = _gold;
                fg = const Color(0xFF0F172A);
                border = Border.all(color: Colors.amber.shade200, width: 1.5);
              } else if (isCompleted) {
                bg = _emerald;
                fg = Colors.white;
              } else {
                bg = isDark
                    ? const Color(0xFF1E2B3C)
                    : const Color(0xFFF1F5F9);
                fg = isDark ? Colors.white60 : Colors.grey.shade700;
              }

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  final startPage = _juzStartPages[index];
                  final range = QuranPageMapping.getPageRange(startPage);
                  final surah = QuranData.surahs.firstWhere(
                    (s) => s.number == range.startSurah,
                    orElse: () => QuranData.surahs.first,
                  );
                  _openQuranAtPosition(surah, startPage, vm);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: border,
                  ),
                  child: Center(
                    child: Text(
                      QuranTextFormatter.toArabicDigits(juzNum.toString()),
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: fg,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            "اضغط على أي جزء للانتقال مباشرة إلى بدايته في المصحف الشريف",
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
