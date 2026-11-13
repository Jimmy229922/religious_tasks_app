import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:religious_tasks_app/core/widgets/islamic_card_generator_dialog.dart';
import 'package:religious_tasks_app/features/ruqyah/data/ruqyah_data.dart';

class RuqyahScreen extends StatefulWidget {
  const RuqyahScreen({super.key});

  @override
  State<RuqyahScreen> createState() => _RuqyahScreenState();
}

class _RuqyahScreenState extends State<RuqyahScreen> {
  RuqyahCategory _selectedCategory = RuqyahData.categories.first;
  double _fontSize = 18.0;

  void _onCategoryChanged(RuqyahCategory cat) {
    if (_selectedCategory.id == cat.id) return;
    setState(() {
      _selectedCategory = cat;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark
        ? const [Color(0xFF0B131E), Color(0xFF152233)]
        : const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "الرقية الشرعية المكتوبة 📖",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
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
                              color: isSelected ? Colors.white : Colors.teal.shade900,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.teal,
                          backgroundColor: Colors.teal.withValues(alpha: 0.1),
                          onSelected: (_) => _onCategoryChanged(cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Subtitle Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.teal, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedCategory.description,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.teal.shade900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
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
                                      const Icon(Icons.auto_awesome_rounded,
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
}
