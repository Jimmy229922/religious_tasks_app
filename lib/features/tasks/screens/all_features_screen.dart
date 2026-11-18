import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:religious_tasks_app/core/widgets/calendar_explorer_dialog.dart';
import 'package:religious_tasks_app/features/athkar/screens/custom_athkar_manager_screen.dart';
import 'package:religious_tasks_app/features/athkar/screens/duaa_safar_screen.dart';
import 'package:religious_tasks_app/features/athkar/screens/halqat_dhikr_screen.dart';
import 'package:religious_tasks_app/features/athkar/screens/prophet_prayers_screen.dart';
import 'package:religious_tasks_app/features/athkar/screens/qiyam_layl_screen.dart';
import 'package:religious_tasks_app/features/athkar/screens/surah_kahf_screen.dart';
import 'package:religious_tasks_app/features/athkar/screens/various_athkar_screen.dart';
import 'package:religious_tasks_app/features/names_of_allah/screens/names_of_allah_screen.dart';
import 'package:religious_tasks_app/features/qibla/screens/qibla_screen.dart';
import 'package:religious_tasks_app/features/quran/screens/khatmah_screen.dart';
import 'package:religious_tasks_app/features/quran/screens/quran_index_screen.dart';
import 'package:religious_tasks_app/features/radio/screens/radio_screen.dart';
import 'package:religious_tasks_app/features/ruqyah/screens/ruqyah_screen.dart';
import 'package:religious_tasks_app/features/statistics/screens/statistics_screen.dart';
import 'package:religious_tasks_app/features/tasbeeh/screens/custom_tasbeeh_screen.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';

class FeatureCategory {
  final String name;
  final IconData icon;
  final List<AppFeatureItem> features;

  const FeatureCategory({
    required this.name,
    required this.icon,
    required this.features,
  });
}

class AppFeatureItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLocked;
  final String? badge;

  const AppFeatureItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isLocked = false,
    this.badge,
  });
}

class AllFeaturesScreen extends StatefulWidget {
  final TasksViewModel vm;

  const AllFeaturesScreen({super.key, required this.vm});

  @override
  State<AllFeaturesScreen> createState() => _AllFeaturesScreenState();
}

class _AllFeaturesScreenState extends State<AllFeaturesScreen> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  List<FeatureCategory> _getCategories(BuildContext context) {
    final coords = widget.vm.prayerTimes?.coordinates ??
        Coordinates(21.4225, 39.8262);

    return [
      FeatureCategory(
        name: "القرآن الكريم والعبادات 📖",
        icon: Icons.menu_book_rounded,
        features: [
          AppFeatureItem(
            title: "القرآن الكريم",
            description: "تصفح وفهرس الـ ١١٤ سورة وقراءة المصحف الشريف",
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF6A1B9A),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const QuranIndexScreen())),
          ),
          AppFeatureItem(
            title: "متابع الختمة",
            description: "تتبع وردك اليومي وتخطيط ختمتك المباركة",
            icon: Icons.bookmark_added_rounded,
            color: const Color(0xFFD4AF37),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const KhatmahScreen())),
          ),
          AppFeatureItem(
            title: "حلقة الذكر",
            description: "مشاركة وتسبيح جماعي وتحديات إيمانية",
            icon: Icons.groups_rounded,
            color: const Color(0xFF66BB6A),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const HalqatDhikrScreen())),
          ),
          AppFeatureItem(
            title: "سورة الكهف",
            description: "قراءة سورة الكهف يوم الجمعة وتدبرها كاملة",
            icon: Icons.auto_stories_rounded,
            color: const Color(0xFF2E7D32),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SurahKahfScreen())),
          ),
          AppFeatureItem(
            title: "قيام الليل",
            description: "مساعد وصلاة قيام الليل والتهجد",
            icon: Icons.nights_stay_rounded,
            color: const Color(0xFF3F51B5),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const QiyamLaylScreen())),
          ),
        ],
      ),
      FeatureCategory(
        name: "الأذكار والأدعية 📿",
        icon: Icons.favorite_rounded,
        features: [
          AppFeatureItem(
            title: "حصن المسلم",
            description: "أذكار الخروج والدخول، لبس الثوب، المرآة، المسجد، الطعام والشفاء",
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF7C3AED),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const VariousAthkarScreen())),
          ),
          AppFeatureItem(
            title: "أذكاري الخاصة",
            description: "إضافة وتعديل وحذف أذكارك الخاصة في الصباح والمساء",
            icon: Icons.edit_note_rounded,
            color: const Color(0xFF0D9488),
            badge: "جديد",
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const CustomAthkarManagerScreen())),
          ),
          AppFeatureItem(
            title: "الرقية الشرعية",
            description: "آيات الرقية والتحصين من الكتاب والسنة",
            icon: Icons.record_voice_over_rounded,
            color: const Color(0xFF0F766E),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const RuqyahScreen())),
          ),
          AppFeatureItem(
            title: "أسماء الله الحسنى",
            description: "تأمل ومعاني أسماء الله الحسنى وفوائدها",
            icon: Icons.stars_rounded,
            color: const Color(0xFFD97706),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const NamesOfAllahScreen())),
          ),
          AppFeatureItem(
            title: "التسبيح الإلكتروني",
            description: "عداد ومسبحة إلكترونية مخصصة للتسبيح",
            icon: Icons.fingerprint_rounded,
            color: const Color(0xFF1565C0),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const CustomTasbeehScreen())),
          ),
          AppFeatureItem(
            title: "الصلاة على النبي",
            description: "تتبع ورد الصلاة على النبي والسنن المهجورة",
            icon: Icons.favorite_rounded,
            color: const Color(0xFFE91E63),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ProphetPrayersScreen())),
          ),
          AppFeatureItem(
            title: "دعاء السفر",
            description: "أدعية وحصن المسافر أثناء الرحلات",
            icon: Icons.flight_takeoff_rounded,
            color: const Color(0xFF0288D1),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const DuaaSafarScreen())),
          ),
        ],
      ),
      FeatureCategory(
        name: "الأدوات والخدمات التفاعلية 🧭",
        icon: Icons.explore_rounded,
        features: [
          AppFeatureItem(
            title: "اتجاه القبلة",
            description: "بوصلة دقيقة لتحديد اتجاه القبلة من موقعك",
            icon: Icons.explore_rounded,
            color: const Color(0xFF00695C),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => QiblaScreen(coordinates: coords))),
          ),
          AppFeatureItem(
            title: "راديو القرآن الكريم",
            description: "بث مباشر لإذاعات القرآن الكريم والمقرئين",
            icon: Icons.radio_rounded,
            color: const Color(0xFFE53935),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const RadioScreen())),
          ),
          AppFeatureItem(
            title: "التقويم الهجري",
            description: "مستكشف التقويم الهجري والمناسبات الإسلامية",
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFF00ACC1),
            onTap: () => showDialog(
              context: context,
              builder: (context) => const CalendarExplorerDialog(initialTab: 0),
            ),
          ),
          AppFeatureItem(
            title: "إحصائيات العبادات",
            description: "سجل متابعة وإحصائيات إنجازاتك الإيمانية",
            icon: Icons.insights_rounded,
            color: const Color(0xFF8E24AA),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => StatisticsScreen(
                          morningStreak: widget.vm.morningStreak,
                          eveningStreak: widget.vm.eveningStreak,
                          sleepStreak: widget.vm.sleepStreak,
                        ))),
          ),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = _getCategories(context);

    // Filter features based on search query
    final filteredCategories = categories.map((cat) {
      final matches = cat.features.where((item) {
        return item.title.contains(_searchQuery) ||
            item.description.contains(_searchQuery);
      }).toList();
      return FeatureCategory(
        name: cat.name,
        icon: cat.icon,
        features: matches,
      );
    }).where((cat) => cat.features.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "جميع الخدمات والخصائص",
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        elevation: 0,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Search Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.teal.shade50.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.teal.withValues(alpha: 0.2),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "ابحث عن خدمة أو تطبيق...",
                        hintStyle: GoogleFonts.cairo(
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.teal),
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
                ],
              ),
            ),
          ),

          // Categories & Feature Cards List
          if (filteredCategories.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "لم نجد نتائج مطابقة لـ \"$_searchQuery\"",
                      style: GoogleFonts.cairo(
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = filteredCategories[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 12.0, bottom: 12.0, right: 4.0),
                          child: Row(
                            children: [
                              Icon(category.icon, color: Colors.teal, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                category.name,
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: category.features.length,
                          itemBuilder: (context, fIndex) {
                            final feature = category.features[fIndex];
                            return _buildFeatureCard(
                              context,
                              feature,
                              isDark,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  childCount: filteredCategories.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    AppFeatureItem feature,
    bool isDark,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: feature.color.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: InkWell(
        onTap: feature.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: feature.color.withValues(alpha: isDark ? 0.2 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      feature.icon,
                      color: feature.color,
                      size: 22,
                    ),
                  ),
                  if (feature.isLocked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        feature.badge ?? "قريباً",
                        style: GoogleFonts.cairo(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                feature.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Text(
                feature.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
