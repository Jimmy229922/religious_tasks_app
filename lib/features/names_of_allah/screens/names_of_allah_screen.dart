import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/names_of_allah_data.dart';
import 'package:religious_tasks_app/core/widgets/islamic_card_generator_dialog.dart';

class NamesOfAllahScreen extends StatefulWidget {
  const NamesOfAllahScreen({super.key});

  @override
  State<NamesOfAllahScreen> createState() => _NamesOfAllahScreenState();
}

class _NamesOfAllahScreenState extends State<NamesOfAllahScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NameOfAllah> get _filteredNames {
    if (_searchQuery.isEmpty) return NamesOfAllahData.names;
    return NamesOfAllahData.names.where((item) {
      return item.name.contains(_searchQuery) ||
          item.meaning.contains(_searchQuery) ||
          item.supplication.contains(_searchQuery);
    }).toList();
  }

  void _openCardGenerator(NameOfAllah name) {
    showDialog(
      context: context,
      builder: (_) => IslamicCardGeneratorDialog(
        title: "اسم الله الحسنى: ${name.name}",
        content: "${name.meaning}\n\n✨ الدعاء والتعبد:\n${name.supplication}",
        subtitle: "أسماء الله الحسنى - الاسم رقم ${name.id}",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0B131E) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            "أسماء الله الحسنى الـ 99",
            style: GoogleFonts.arefRuqaa(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: "ابحث عن اسم، معنى، أو دعاء...",
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.teal),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.teal.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.teal.withValues(alpha: 0.2)),
                  ),
                ),
              ),
            ),

            // Header count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "عدد الأسماء المعروضة (${_filteredNames.length})",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Names Grid View
            Expanded(
              child: _filteredNames.isEmpty
                  ? Center(
                      child: Text(
                        "لم نجد أي اسم مطابق للبحث",
                        style: GoogleFonts.cairo(color: Colors.grey),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _filteredNames.length,
                      itemBuilder: (context, index) {
                        final item = _filteredNames[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.teal.withValues(alpha: 0.2),
                            ),
                          ),
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _showNameDetailsDialog(context, item, isDark),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Number Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "#${item.id}",
                                      style: GoogleFonts.ibmPlexMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Name in Arabic calligraphy
                                  Text(
                                    item.name,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.arefRuqaa(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.amberAccent : Colors.teal.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Meaning preview
                                  Text(
                                    item.meaning,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white60 : Colors.grey[700],
                                    ),
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
        ),
      ),
    );
  }

  void _showNameDetailsDialog(BuildContext context, NameOfAllah name, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "الاسم رقم ${name.id}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.arefRuqaa(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.amberAccent : Colors.teal.shade900,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: Colors.teal),
                          const SizedBox(width: 6),
                          Text(
                            "المعنى والبيان:",
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name.meaning,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isDark ? Colors.white70 : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.volunteer_activism_rounded,
                              size: 18, color: Colors.amber),
                          const SizedBox(width: 6),
                          Text(
                            "الدعاء والتعبد باسمه:",
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name.supplication,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                          color: isDark ? Colors.amberAccent : Colors.teal.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openCardGenerator(name);
                        },
                        icon: const Icon(Icons.share_rounded, color: Colors.white),
                        label: const Text(
                          "تصميم بطاقة ومشاركة",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
