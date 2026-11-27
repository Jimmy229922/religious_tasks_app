import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/widgets/calendar_explorer_dialog.dart';
import 'package:religious_tasks_app/features/athkar/screens/custom_athkar_manager_screen.dart';
import 'package:religious_tasks_app/features/athkar/screens/duaa_safar_screen.dart';
import 'package:religious_tasks_app/features/athkar/screens/halqat_dhikr_screen.dart';
import 'package:religious_tasks_app/features/athkar/screens/prophet_prayers_screen.dart';
import 'package:religious_tasks_app/features/athkar/screens/qiyam_layl_screen.dart';
import 'package:religious_tasks_app/features/athkar/screens/surah_kahf_screen.dart';
import 'package:religious_tasks_app/features/athkar/screens/various_athkar_screen.dart';
import 'package:religious_tasks_app/features/happiness_jar/screens/happiness_jar_screen.dart';
import 'package:religious_tasks_app/features/mosques/screens/nearby_mosques_screen.dart';
import 'package:religious_tasks_app/features/names_of_allah/screens/names_of_allah_screen.dart';
import 'package:religious_tasks_app/features/qibla/screens/qibla_screen.dart';
import 'package:religious_tasks_app/features/quran/screens/khatmah_screen.dart';
import 'package:religious_tasks_app/features/quran/screens/quran_index_screen.dart';
import 'package:religious_tasks_app/features/radio/screens/radio_screen.dart';
import 'package:religious_tasks_app/features/ruqyah/screens/ruqyah_screen.dart';
import 'package:religious_tasks_app/features/settings/screens/settings_screen.dart';
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
  final bool embedded;
  final ThemeProvider? themeProvider;

  const AllFeaturesScreen({
    super.key,
    required this.vm,
    this.embedded = false,
    this.themeProvider,
  });

  @override
  State<AllFeaturesScreen> createState() => _AllFeaturesScreenState();
}

class _AllFeaturesScreenState extends State<AllFeaturesScreen> {
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldLight = Color(0xFFFDE68A);
  String _searchQuery = "";
  int _selectedCategoryIndex = -1;
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
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const QuranIndexScreen(openLastReadOnStart: true),
                )),
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
            title: "رقية الأطفال",
            description: "أدعية التحصين والرقية الموثوقة لحفظ الأطفال من العين والحسد",
            icon: Icons.child_care_rounded,
            color: const Color(0xFF0284C7),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RuqyahScreen(
                  initialCategoryId: 'children',
                  singleCategoryOnly: true,
                ),
              ),
            ),
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
          AppFeatureItem(
            title: "أذكار الاستيقاظ",
            description: "أذكار الاستيقاظ من النوم والشكر على بداية اليوم",
            icon: Icons.wb_sunny_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const VariousAthkarScreen(
                  initialCategoryId: 'daily_life',
                  singleCategoryOnly: true,
                ),
              ),
            ),
          ),
          AppFeatureItem(
            title: "أذكار المسجد",
            description: "أدعية الذهاب إلى المسجد ودخوله والخروج منه والوضوء",
            icon: Icons.mosque_rounded,
            color: const Color(0xFF0D9488),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const VariousAthkarScreen(
                  initialCategoryId: 'mosque',
                  singleCategoryOnly: true,
                ),
              ),
            ),
          ),
        ],
      ),
      FeatureCategory(
        name: "الأدوات والخدمات التفاعلية 🧭",
        icon: Icons.explore_rounded,
        features: [
          AppFeatureItem(
            title: "المساجد القريبة",
            description: "خريطة تفاعلية لاكتشاف أقرب المساجد من موقعك والاتجاهات إليها",
            icon: Icons.mosque_rounded,
            color: const Color(0xFF047857),
            badge: "جديد",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NearbyMosquesScreen(
                  initialLatitude: coords.latitude,
                  initialLongitude: coords.longitude,
                ),
              ),
            ),
          ),
          AppFeatureItem(
            title: "برطمان السعادة",
            description: "رسائل يومية مبهجة وبشائر تفاؤل تفرح قلبك كل يوم",
            icon: Icons.card_giftcard_rounded,
            color: const Color(0xFFD97706),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const HappinessJarScreen())),
          ),
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
    final totalServices =
        categories.fold<int>(0, (sum, cat) => sum + cat.features.length);

    final scopedCategories = _selectedCategoryIndex >= 0 &&
            _selectedCategoryIndex < categories.length
        ? [categories[_selectedCategoryIndex]]
        : categories;

    final filteredCategories = scopedCategories.map((cat) {
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

    final content = CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              children: [
                _buildServicesDomeHeader(
                  context: context,
                  isDark: isDark,
                  totalServices: totalServices,
                ),
                const SizedBox(height: 12),
                _buildSearchBar(isDark),
                const SizedBox(height: 12),
                _buildCategoryFilterStrip(categories, isDark),
              ],
            ),
          ),
        ),
        if (filteredCategories.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _gold.withValues(alpha: isDark ? 0.14 : 0.12),
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Icon(
                        Icons.search_off_rounded,
                        size: 42,
                        color: isDark ? _goldLight : const Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "لم نجد نتائج مطابقة لـ \"$_searchQuery\"",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = filteredCategories[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCategoryOrnamentHeader(category, isDark),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final int columns;
                          if (constraints.maxWidth < 310) {
                            columns = 2;
                          } else if (constraints.maxWidth >= 680) {
                            columns = 4;
                          } else {
                            columns = 3;
                          }
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              childAspectRatio: columns == 2 ? 1.05 : 0.92,
                              crossAxisSpacing: 9,
                              mainAxisSpacing: 9,
                            ),
                            itemCount: category.features.length,
                            itemBuilder: (context, fIndex) {
                              return _buildFeatureCard(
                                context,
                                category.features[fIndex],
                                isDark,
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                    ],
                  );
                },
                childCount: filteredCategories.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: content,
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
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
          child: SafeArea(child: content),
        ),
      ),
    );
  }

  Widget _buildServicesDomeHeader({
    required BuildContext context,
    required bool isDark,
    required int totalServices,
  }) {
    final accent = context.primaryColor;
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
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : _gold).withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ServicesArchLatticePainter(
                color: _gold.withValues(alpha: isDark ? 0.12 : 0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.embedded)
                  _buildCircleHeaderBtn(
                    icon: Icons.settings_outlined,
                    tooltip: 'الإعدادات',
                    isDark: isDark,
                    accent: accent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  )
                else
                  _buildCircleHeaderBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'رجوع',
                    isDark: isDark,
                    accent: accent,
                    onTap: () => Navigator.pop(context),
                  ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'الخدمات والخصائص',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? _goldLight : context.primaryDarkColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: isDark ? 0.16 : 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _gold.withValues(alpha: isDark ? 0.45 : 0.6),
                          ),
                        ),
                        child: Text(
                          '$totalServices خدمة وميزة إسلامية',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? _goldLight : const Color(0xFF78350F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.themeProvider != null)
                  _buildCircleHeaderBtn(
                    icon: isDark
                        ? Icons.wb_sunny_rounded
                        : Icons.nights_stay_rounded,
                    tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
                    isDark: isDark,
                    accent: accent,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.themeProvider!.toggleTheme(!isDark);
                    },
                  )
                else
                  const SizedBox(width: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleHeaderBtn({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
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
            icon,
            size: 20,
            color: isDark ? _goldLight : accent,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
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
          hintText: "ابحث عن خدمة أو ميزة...",
          hintStyle: GoogleFonts.cairo(
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? _goldLight : context.primaryColor,
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
    );
  }

  Widget _buildCategoryFilterStrip(
    List<FeatureCategory> categories,
    bool isDark,
  ) {
    final labels = ['القرآن والعبادات', 'الأذكار والأدعية', 'الأدوات والإحصائيات'];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final isAll = idx == 0;
          final catIdx = idx - 1;
          final selected = _selectedCategoryIndex == (isAll ? -1 : catIdx);
          final label = isAll
              ? 'الكل'
              : (catIdx < labels.length ? labels[catIdx] : categories[catIdx].name);
          final icon = isAll ? Icons.apps_rounded : categories[catIdx].icon;

          return InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategoryIndex = isAll ? -1 : catIdx);
            },
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
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
                    : (isDark
                        ? const Color(0xFF0E211E)
                        : const Color(0xFFFFFDF8)),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? _gold
                      : _gold.withValues(alpha: isDark ? 0.35 : 0.55),
                  width: selected ? 1.3 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: selected
                        ? (isDark ? Colors.white : const Color(0xFF451A03))
                        : (isDark ? _goldLight : const Color(0xFF78350F)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? (isDark ? Colors.white : const Color(0xFF451A03))
                          : (isDark ? Colors.white70 : const Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryOrnamentHeader(FeatureCategory category, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: _gold.withValues(alpha: 0.45),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                size: 17,
                color: isDark ? _goldLight : context.primaryDarkColor,
              ),
              const SizedBox(width: 6),
              Text(
                category.name,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? _goldLight : context.primaryDarkColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Divider(
            color: _gold.withValues(alpha: 0.45),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    AppFeatureItem feature,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        feature.onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: context.appCardGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _gold.withValues(alpha: isDark ? 0.45 : 0.65),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : _gold).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
                    shape: BoxShape.circle,
                    color: feature.color.withValues(alpha: isDark ? 0.18 : 0.14),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Icon(
                    feature.icon,
                    color: isDark ? _goldLight : feature.color,
                    size: 18,
                  ),
                ),
                if (feature.isLocked || feature.badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: feature.isLocked
                          ? Colors.amber.shade800
                          : _gold.withValues(alpha: isDark ? 0.22 : 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: feature.isLocked
                          ? null
                          : Border.all(
                              color: _gold.withValues(alpha: 0.6),
                            ),
                    ),
                    child: Text(
                      feature.badge ?? "قريباً",
                      style: GoogleFonts.cairo(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: feature.isLocked
                            ? Colors.white
                            : (isDark ? _goldLight : const Color(0xFF78350F)),
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: _gold.withValues(alpha: 0.75),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              feature.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              feature.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 9.2,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicesArchLatticePainter extends CustomPainter {
  final Color color;
  const _ServicesArchLatticePainter({required this.color});

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
  bool shouldRepaint(covariant _ServicesArchLatticePainter oldDelegate) =>
      oldDelegate.color != color;
}
