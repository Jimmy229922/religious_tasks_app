import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/widgets/islamic_card_generator_dialog.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';

class VariousDhikrCategory {
  final String id;
  final String title;
  final IconData icon;
  final List<VariousDhikrItem> items;

  const VariousDhikrCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.items,
  });
}

class VariousDhikrItem {
  final String title;
  final String text;
  final String reward;
  final String source;
  final int count;

  const VariousDhikrItem({
    required this.title,
    required this.text,
    required this.reward,
    required this.source,
    this.count = 1,
  });
}

class VariousAthkarScreen extends StatefulWidget {
  final String? initialCategoryId;
  const VariousAthkarScreen({super.key, this.initialCategoryId});

  @override
  State<VariousAthkarScreen> createState() => _VariousAthkarScreenState();
}

class _VariousAthkarScreenState extends State<VariousAthkarScreen> {
  double _fontSize = 19.0;
  late String _selectedCategoryId;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId ?? "home";
  }

  static const List<VariousDhikrCategory> _categories = [
    VariousDhikrCategory(
      id: "home",
      title: "المنزل واللبس 🏠",
      icon: Icons.home_rounded,
      items: [
        VariousDhikrItem(
          title: "أذكار الخروج من المنزل",
          text:
              "بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ.\n\n"
              "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ أَنْ أَضِلَّ أَوْ أُضَلَّ، أَوْ أَزِلَّ أَوْ أُزَلَّ، أَوْ أَظْلِمَ أَوْ أُظْلَمَ، أَوْ أَجْهَلَ أَوْ يُجْهَلَ عَلَيَّ.",
          reward: "يُقال له: هُديتَ وكُفيتَ ووُقيتَ، وتتنحّى عنه الشياطين.",
          source: "رواه أبو داود والترمذي",
          count: 1,
        ),
        VariousDhikrItem(
          title: "أذكار دخول المنزل",
          text:
              "بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى اللَّهِ رَبِّنَا تَوَكَّلْنَا، ثُمَّ لِيُسَلِّمْ عَلَى أَهْلِهِ.",
          reward: "إذا ذكر الله عند دخوله وعند طعامه، قال الشيطان لأصحابه: لا مبيت لكم ولا عشاء.",
          source: "رواه أبو داود ومسلم",
          count: 1,
        ),
        VariousDhikrItem(
          title: "دعاء النظر في المرآة",
          text:
              "اللَّهُمَّ أَنْتَ حَسَّنْتَ خَلْقِي فَحَسِّنْ خُلُقِي، وَحَرِّمْ وَجْهِي عَلَى النَّارِ.",
          reward: "سؤال الله تعالى كمال الخلق وحسن الأخلاق والسلامة من النار.",
          source: "رواه ابن السني وأحمد",
          count: 1,
        ),
        VariousDhikrItem(
          title: "دعاء لبس الثوب (الملابس)",
          text:
              "الْحَمْدُ لِلَّهِ الَّذِي كَسَانِي هَذَا الثَّوْبَ وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ.",
          reward: "غُفر له ما تقدم من ذنبه.",
          source: "رواه أصحاب السنن",
          count: 1,
        ),
        VariousDhikrItem(
          title: "دعاء لبس الثوب الجديد",
          text:
              "اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ كَسَوْتَنِيهِ، أَسْأَلُكَ مِنْ خَيْرِهِ وَخَيْرِ مَا صُنِعَ لَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّهِ وَشَرِّ مَا صُنِعَ لَهُ.",
          reward: "شكر نعم الله وسؤاله البركة والنفع بالحسنى.",
          source: "رواه الترمذي وأبو داود",
          count: 1,
        ),
        VariousDhikrItem(
          title: "دعاء خلع الثوب",
          text: "بِسْمِ اللَّهِ.",
          reward: "ستر ما بين أستر عورات بني آدم وأعين الجن.",
          source: "رواه الترمذي",
          count: 1,
        ),
      ],
    ),
    VariousDhikrCategory(
      id: "mosque",
      title: "المسجد والوضوء 🕌",
      icon: Icons.mosque_rounded,
      items: [
        VariousDhikrItem(
          title: "دعاء الذهاب إلى المسجد",
          text:
              "اللَّهُمَّ اجْعَلْ فِي قَلْبِي نُورًا، وَفِي بَصَرِي نُورًا، وَفِي سَمْعِي نُورًا، وَعَنْ يَمِينِي نُورًا، وَعَنْ يَسَارِي نُورًا، وَفَوْقِي نُورًا، وَتَحْتِي نُورًا، وَأَمَامِي نُورًا، وَخَلْفِي نُورًا، وَاجْعَلْ لِي نُورًا.",
          reward: "نور يحيط بالمؤمن في حركته وسكناته إلى بيت الله.",
          source: "متفق عليه",
          count: 1,
        ),
        VariousDhikrItem(
          title: "دعاء دخول المسجد",
          text:
              "بِسْمِ اللَّهِ، وَالصَّلَاةُ وَالسَّلَامُ عَلَى رَسُولِ اللَّهِ، اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ.",
          reward: "استمطار الرحمات ودخول بيت الله بالسكينة.",
          source: "رواه مسلم وابن ماجه",
          count: 1,
        ),
        VariousDhikrItem(
          title: "دعاء الخروج من المسجد",
          text:
              "بِسْمِ اللَّهِ، وَالصَّلَاةُ وَالسَّلَامُ عَلَى رَسُولِ اللَّهِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ، اللَّهُمَّ اعْصِمْنِي مِنَ الشَّيْطَانِ الرَّجِيمِ.",
          reward: "سؤال الفضل والحماية من وسواس الشيطان.",
          source: "رواه مسلم وابن ماجه",
          count: 1,
        ),
        VariousDhikrItem(
          title: "أذكار قبل وبعد الوضوء",
          text:
              "قبل الوضوء: «بِسْمِ اللَّهِ»\n\n"
              "بعد الوضوء: «أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ. اللَّهُمَّ اجْعَلْنِي مِنَ التَّوَّابِينَ وَاجْعَلْنِي مِنَ الْمُتَطَهِّرِينَ».",
          reward: "فُتحت له أبواب الجنة الثمانية يدخل من أيهاشاء.",
          source: "رواه مسلم والترمذي",
          count: 1,
        ),
      ],
    ),
    VariousDhikrCategory(
      id: "food",
      title: "الطعام والشراب 🍽️",
      icon: Icons.restaurant_rounded,
      items: [
        VariousDhikrItem(
          title: "الذكر عند البدء بالفي الطعام",
          text:
              "بِسْمِ اللَّهِ.\n\nفإن نسي في أوله فلْيَقُلْ:\n«بِسْمِ اللَّهِ فِي أَوَّلِهِ وَآخِرِهِ».",
          reward: "البركة في الطعام ومنع الشيطان من الأكل منه.",
          source: "رواه أبو داود والترمذي",
          count: 1,
        ),
        VariousDhikrItem(
          title: "الذكر بعد الفراغ من الطعام",
          text:
              "الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ.",
          reward: "غُفر له ما تقدم من ذنبه.",
          source: "رواه أصحاب السنن",
          count: 1,
        ),
        VariousDhikrItem(
          title: "دعاء من أكل عند قوم (الضيافة)",
          text:
              "أَفْطَرَ عِنْدَكُمُ الصَّائِمُونَ، وَأَكَلَ طَعَامَكُمُ الأَبْرَارُ، وَصَلَّتْ عَلَيْكُمُ الْمَلائِكَةُ.",
          reward: "دعاء بالبركة والرحمة والاستغفار لأصحاب الطعام.",
          source: "رواه أبو داود والنسائي",
          count: 1,
        ),
      ],
    ),
    VariousDhikrCategory(
      id: "daily_life",
      title: "الاستيقاظ والخلاء 🌅",
      icon: Icons.wb_sunny_rounded,
      items: [
        VariousDhikrItem(
          title: "أذكار الاستيقاظ من النوم",
          text:
              "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ.\n\n"
              "الْحَمْدُ لِلَّهِ الَّذِي عَافَانِي فِي جَسَدِي، وَرَدَّ عَلَيَّ رُوحِي، وَأَذِنَ لِي بِذِكْرِهِ.",
          reward: "شكر الله على استعادة الحياة والروح كل صباح.",
          source: "متفق عليه والترمذي",
          count: 1,
        ),
        VariousDhikrItem(
          title: "دعاء دخول الخلاء",
          text: "بِسْمِ اللَّهِ، اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْخُبُثِ وَالْخَبَائِثِ.",
          reward: "التحصين من الشياطين والخبائث عند دخول الخلاء.",
          source: "متفق عليه",
          count: 1,
        ),
        VariousDhikrItem(
          title: "دعاء الخروج من الخلاء",
          text: "غُفْرَانَكَ.",
          reward: "سؤال المغفرة وشكر الله على عافية الجسد.",
          source: "رواه أصحاب السنن",
          count: 1,
        ),
      ],
    ),
    VariousDhikrCategory(
      id: "distress",
      title: "الكرب والشفاء 🤲",
      icon: Icons.health_and_safety_rounded,
      items: [
        VariousDhikrItem(
          title: "دعاء الكرب والهم والغم",
          text:
              "لَا إِلَهَ إِلَّا اللَّهُ الْعَظِيمُ الْحَلِيمُ، لَا إِلَهَ إِلَّا اللَّهُ رَبُّ الْعَرْشِ الْعَظِيمِ، لَا إِلَهَ إِلَّا اللَّهُ رَبُّ السَّمَاوَاتِ وَرَبُّ الْأَرْضِ وَرَبُّ الْعَرْشِ الْكَرِيمِ.\n\n"
              "اللَّهُمَّ رَحْمَتَكَ أَرْجُو فَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ، وَأَصْلِحْ لِي شَأْنِي كُلَّهُ لَا إِلَهَ إِلَّا أَنْتَ.",
          reward: "دعاء النبي ﷺ عند الحزن والشدة وتفريج الهموم.",
          source: "متفق عليه وأبو داود",
          count: 1,
        ),
        VariousDhikrItem(
          title: "دعاء يونس عليه السلام (دعوة ذي النون)",
          text: "لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ.",
          reward: "لم يدعُ بها رجل مسلم في شيء قط إلا استجاب الله له.",
          source: "رواه الترمذي والحاكم",
          count: 1,
        ),
        VariousDhikrItem(
          title: "ما يقوله من شعر بوجع في جسده",
          text:
              "ضَعْ يَدَكَ عَلَى الَّذِي تَعَلَّمَ مِنْ جَسَدِكَ، وَقُلْ:\n"
              "«بِسْمِ اللَّهِ» (ثَلَاثًا)،\n\n"
              "وَقُلْ (سَبْعَ مَرَّاتٍ):\n«أَعُوذُ بِاللَّهِ وَقُدْرَتِهِ مِنْ شَرِّ مَا أَجِدُ وَأُحَاذِرُ».",
          reward: "شفاء للأوجاع والآلام ببركة اسم الله تعالى.",
          source: "رواه مسلم",
          count: 7,
        ),
        VariousDhikrItem(
          title: "دعاء عيادة المريض",
          text: "لَا بَأْسَ طَهُورٌ إِنْ شَاءَ اللَّهُ.",
          reward: "دعاء بالشفاء والتطهير من الذنوب للمريض.",
          source: "رواه البخاري",
          count: 1,
        ),
      ],
    ),
  ];

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

    final selectedCategory = _categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => _categories.first,
    );

    // Filter items based on search query
    List<VariousDhikrItem> visibleItems;
    if (_searchQuery.isEmpty) {
      visibleItems = selectedCategory.items;
    } else {
      visibleItems = _categories
          .expand((c) => c.items)
          .where((item) =>
              item.title.contains(_searchQuery) ||
              item.text.contains(_searchQuery) ||
              item.reward.contains(_searchQuery))
          .toList();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "أذكار متنوعة وحصن المسلم 📖",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.format_size_rounded),
              tooltip: "حجم الخط",
              onPressed: () {
                setState(() {
                  _fontSize = _fontSize == 19.0
                      ? 22.0
                      : _fontSize == 22.0
                          ? 25.0
                          : 19.0;
                });
              },
            ),
          ],
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
              // Search Bar Container
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
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
                      hintText: "ابحث في الأذكار المتنوعة...",
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
              ),

              // Category Selector Choice Chips (only when search is empty)
              if (_searchQuery.isEmpty)
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategoryId == cat.id;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ChoiceChip(
                            avatar: Icon(
                              cat.icon,
                              size: 16,
                              color: isSelected ? Colors.white : Colors.teal,
                            ),
                            label: Text(
                              cat.title,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.teal.shade900),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.teal,
                            backgroundColor: isDark
                                ? Colors.teal.withValues(alpha: 0.15)
                                : Colors.teal.withValues(alpha: 0.08),
                            onSelected: (_) {
                              setState(() {
                                _selectedCategoryId = cat.id;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              // Dhikr Items List
              Expanded(
                child: visibleItems.isEmpty
                    ? Center(
                        child: Text(
                          "لم نجد نتائج مطابقة لـ \"$_searchQuery\"",
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: visibleItems.length,
                        itemBuilder: (context, index) {
                          final item = visibleItems[index];
                          return _buildDhikrCard(context, item, isDark);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDhikrCard(
    BuildContext context,
    VariousDhikrItem item,
    bool isDark,
  ) {
    final accent = context.primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark
              ? Colors.white10
              : accent.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.bookmark_rounded,
                          color: accent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  icon: Icon(Icons.style_rounded,
                      color: accent, size: 20),
                  tooltip: "صانع البطاقات الإيمانية",
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => IslamicCardGeneratorDialog(
                        title: item.title,
                        content: item.text,
                        subtitle: item.reward,
                      ),
                    );
                  },
                ),
              ],
            ),

            Divider(height: 18, color: accent.withValues(alpha: 0.15)),

            // Dhikr Main Arabic Text
            _buildArabicText(item.text, isDark),

            const SizedBox(height: 14),

            // Virtue / Reward Box
            if (item.reward.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : accent.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : accent.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.reward,
                        style: GoogleFonts.cairo(
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Source & Target Count Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "📌 المصدر: ${item.source}",
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.count > 1) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "التكرار: ${item.count} مرات",
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArabicText(String text, bool isDark) {
    final baseStyle = GoogleFonts.amiri(
      fontSize: _fontSize,
      height: 1.85,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : const Color(0xFF0F172A),
    );

    if (text.contains('﴿') || text.contains('۝') || text.contains('«')) {
      return QuranTextFormatter.buildFormattedQuranText(
        text,
        baseStyle: baseStyle,
        badgeColor: const Color(0xFFD4AF37),
      );
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: baseStyle,
      strutStyle: StrutStyle(
        fontSize: _fontSize,
        height: 1.85,
        forceStrutHeight: true,
      ),
    );
  }
}
