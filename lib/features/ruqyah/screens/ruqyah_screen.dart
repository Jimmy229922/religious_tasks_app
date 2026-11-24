import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/widgets/islamic_card_generator_dialog.dart';
import 'package:religious_tasks_app/features/ruqyah/data/ruqyah_data.dart';

class RuqyahScreen extends StatefulWidget {
  final String? initialCategoryId;
  const RuqyahScreen({super.key, this.initialCategoryId});

  @override
  State<RuqyahScreen> createState() => _RuqyahScreenState();
}

class _RuqyahScreenState extends State<RuqyahScreen> {
  late RuqyahCategory _selectedCategory;
  double _fontSize = 18.0;

  @override
  void initState() {
    super.initState();
    _selectedCategory = RuqyahData.categories.firstWhere(
      (c) => c.id == widget.initialCategoryId,
      orElse: () => RuqyahData.categories.first,
    );
  }

  void _onCategoryChanged(RuqyahCategory cat) {
    if (_selectedCategory.id == cat.id) return;
    setState(() {
      _selectedCategory = cat;
    });
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const goldLight = Color(0xFFFDE68A);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = context.appBgGradient;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.appScaffoldBg,
        appBar: AppBar(
          title: Text(
            "الرقية الشرعية المكتوبة",
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? goldLight : Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor:
              isDark ? context.appHeaderBg : context.primaryColor,
          foregroundColor: isDark ? goldLight : Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.format_size_rounded),
              tooltip: "حجم الخط",
              onPressed: () {
                setState(() {
                  _fontSize = _fontSize == 18.0
                      ? 21.0
                      : _fontSize == 21.0
                          ? 24.0
                          : 18.0;
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
              // Category Selector Chips
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: RuqyahData.categories.map((cat) {
                      final isSelected = _selectedCategory.id == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            cat.title,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isSelected
                                  ? (isDark
                                      ? Colors.white
                                      : const Color(0xFF451A03))
                                  : (isDark
                                      ? Colors.white70
                                      : const Color(0xFF334155)),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor:
                              isDark ? const Color(0xFF92400E) : goldLight,
                          backgroundColor: isDark
                              ? const Color(0xFF0E211E)
                              : const Color(0xFFFFFDF8),
                          side: BorderSide(
                            color: isSelected
                                ? gold
                                : gold.withValues(alpha: isDark ? 0.35 : 0.55),
                          ),
                          onSelected: (_) => _onCategoryChanged(cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Subtitle Card (tappable guide)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showRuqyahGuideDialog(context, isDark);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: isDark ? 0.14 : 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: gold.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: isDark ? goldLight : const Color(0xFF78350F),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedCategory.description,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF334155),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 15,
                          color: isDark ? goldLight : const Color(0xFF78350F),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Ruqyah Items List
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _selectedCategory.items.length,
                  itemBuilder: (context, index) {
                    final item = _selectedCategory.items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
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
                          color: gold.withValues(alpha: isDark ? 0.45 : 0.65),
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.shield_rounded,
                                          color: Colors.teal, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
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
                                  icon: const Icon(Icons.style_rounded,
                                      color: Colors.teal, size: 20),
                                  tooltip: "صانع البطاقات الإيمانية",
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => IslamicCardGeneratorDialog(
                                        title: item.title,
                                        content: item.text,
                                        subtitle: item.source,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Text(
                              item.text,
                              style: GoogleFonts.amiri(
                                fontSize: _fontSize,
                                height: 1.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "📌 المصدر: ${item.source}",
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "التكرار: ${item.count} مرات",
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal),
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }

  void _showRuqyahGuideDialog(BuildContext context, bool isDark) {
    final accent = context.primaryColor;
    final isChildren = _selectedCategory.id == 'children';
    final title = isChildren
        ? 'طريقة رقية الأطفال الصحيحة 👶'
        : 'آداب وطريقة الرقية الشرعية 📖';

    final steps = isChildren
        ? const [
            (
              '1. النية واليقين بالله',
              'استحضر بقلبك أن الشفاء والحفظ من الله وحده، وأن الرقية سبب شرعي مبارك يأخذ به الوالدان لحفظ أبنائهما.',
            ),
            (
              '2. الطهارة والوضوء',
              'يُستحب أن يكون الراقي (الأب أو الأم) على وضوء وطهارة، وأن يبدأ بالبسملة وحمد الله والصلاة على النبي ﷺ.',
            ),
            (
              '3. وضع اليد على رأس الطفل',
              'ضع يدك اليمنى على رأس الطفل أو على موضع الألم برفق واطمئنان أثناء القراءة والدعاء.',
            ),
            (
              '4. النفث اللطيف والمسح بالمعوذات',
              'اجمع كفيك واقرأ الفاتحة وآية الكرسي والمعوذات (الإخلاص، الفلق، الناس) ثلاثاً مع نفث لطيف (هواء يسير بلا ريق)، ثم امسح بهما رأس الطفل ووجهه وما أقبل من جسده.',
            ),
            (
              '5. تعويذ الحسن والحسين',
              'كرّر قول النبي ﷺ ثلاث مرات: «أُعيذك بكلمات الله التامة من كل شيطان وهامة ومن كل عين لامة» (صحيح البخاري 3371).',
            ),
            (
              '6. المواظبة والأوقات المستحبة',
              'حافظ على تحصين الأطفال في الصباح والمساء وعند النوم وقبل الخروج، وكذلك عند البكاء الشديد أو المرض.',
            ),
          ]
        : const [
            (
              '1. الإخلاص واليقين',
              'الاعتقاد الجازم بأن القرآن شفاء وهداية وأن النفع والضر بيد الله وحده.',
            ),
            (
              '2. الوضوء واستقبال القبلة',
              'يُستحب أن يكون القارئ على طهارة متوضئاً في مكان هادئ وبحضور قلب وتدبر للآيات.',
            ),
            (
              '3. النفث والمسح باليد',
              'القراءة في الكفين مع نفث خفيف ثم مسح الرأس والجسد، أو وضع اليد اليمنى على موضع الألم.',
            ),
            (
              '4. المداومة على الأذكار',
              'الجمع بين الرقية الشرعية وأذكار الصباح والمساء والنوم لتحصين النفس والأهل يومياً.',
            ),
          ];

    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: isDark ? const Color(0xFF141A1E) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (int i = 0; i < steps.length; i++) ...[
                    _buildGuideStep(
                      steps[i].$1,
                      steps[i].$2,
                      accent,
                      isDark,
                    ),
                    if (i < steps.length - 1) const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'فهمت، جزاكم الله خيراً',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildGuideStep(
    String title,
    String body,
    Color accent,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.amber.shade200 : accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: GoogleFonts.cairo(
              fontSize: 12.5,
              height: 1.6,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.88)
                  : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
