import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:religious_tasks_app/features/athkar/data/athkar_data.dart';

class CustomAthkarManagerScreen extends StatefulWidget {
  const CustomAthkarManagerScreen({super.key});

  @override
  State<CustomAthkarManagerScreen> createState() =>
      _CustomAthkarManagerScreenState();
}

class _CustomAthkarManagerScreenState extends State<CustomAthkarManagerScreen> {
  List<CustomDhikrModel> _items = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _items = CustomAthkarRepository.loadAll();
    });
  }

  Future<void> _saveAndRefresh(List<CustomDhikrModel> updated) async {
    await CustomAthkarRepository.saveAll(updated);
    if (!mounted) return;
    setState(() {
      _items = updated;
    });
  }

  List<CustomDhikrModel> get _filteredItems {
    if (_filter == 'morning') {
      return _items
          .where((e) =>
              e.target == CustomDhikrTarget.morning ||
              e.target == CustomDhikrTarget.both)
          .toList();
    }
    if (_filter == 'evening') {
      return _items
          .where((e) =>
              e.target == CustomDhikrTarget.evening ||
              e.target == CustomDhikrTarget.both)
          .toList();
    }
    return _items;
  }

  String _targetLabel(CustomDhikrTarget target) {
    switch (target) {
      case CustomDhikrTarget.morning:
        return 'أذكار الصباح';
      case CustomDhikrTarget.evening:
        return 'أذكار المساء';
      case CustomDhikrTarget.both:
        return 'الصباح والمساء';
    }
  }

  Color _targetColor(CustomDhikrTarget target) {
    switch (target) {
      case CustomDhikrTarget.morning:
        return const Color(0xFF0F766E);
      case CustomDhikrTarget.evening:
        return const Color(0xFF4F46E5);
      case CustomDhikrTarget.both:
        return const Color(0xFFD97706);
    }
  }

  void _showDhikrEditorDialog({CustomDhikrModel? existing}) {
    final textController = TextEditingController(text: existing?.text ?? '');
    final rewardController =
        TextEditingController(text: existing?.reward ?? '');
    final countController =
        TextEditingController(text: (existing?.count ?? 1).toString());
    CustomDhikrTarget selectedTarget =
        existing?.target ?? CustomDhikrTarget.both;
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor:
                  isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                existing == null ? 'إضافة ذكر جديد ✍️' : 'تعديل الذكر ✏️',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: textController,
                      maxLines: 4,
                      minLines: 2,
                      decoration: InputDecoration(
                        labelText: 'نص الذكر',
                        hintText: 'اكتب الذكر هنا...',
                        errorText: errorText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rewardController,
                      maxLines: 2,
                      minLines: 1,
                      decoration: InputDecoration(
                        labelText: 'الفضل أو الملاحظة (اختياري)',
                        hintText: 'مثال: ذكر مأثور أو دعاء خاص',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'عدد مرات التكرار',
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [1, 3, 7, 10, 33, 100].map((preset) {
                        final isSelected =
                            countController.text.trim() == preset.toString();
                        return ChoiceChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            '$preset',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : null,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0F766E),
                          onSelected: (_) {
                            setDialogState(() {
                              countController.text = preset.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: countController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: 'أو اكتب العدد يدوياً',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'مكان الظهور',
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: CustomDhikrTarget.values.map((t) {
                        final selected = selectedTarget == t;
                        return ChoiceChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            _targetLabel(t),
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.white : null,
                            ),
                          ),
                          selected: selected,
                          selectedColor: _targetColor(t),
                          onSelected: (_) {
                            setDialogState(() {
                              selectedTarget = t;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'إلغاء',
                    style: GoogleFonts.cairo(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                  ),
                  onPressed: () async {
                    final text = textController.text.trim();
                    if (text.isEmpty) {
                      setDialogState(() {
                        errorText = 'يرجى كتابة نص الذكر';
                      });
                      return;
                    }
                    final parsedCount =
                        int.tryParse(countController.text.trim()) ?? 1;
                    final count = parsedCount.clamp(1, 10000);
                    final reward = rewardController.text.trim();

                    final updated = List<CustomDhikrModel>.from(_items);
                    if (existing == null) {
                      updated.add(
                        CustomDhikrModel(
                          id: DateTime.now().microsecondsSinceEpoch.toString(),
                          text: text,
                          reward: reward,
                          count: count,
                          target: selectedTarget,
                        ),
                      );
                    } else {
                      final idx = updated.indexWhere((e) => e.id == existing.id);
                      if (idx != -1) {
                        updated[idx] = CustomDhikrModel(
                          id: existing.id,
                          text: text,
                          reward: reward,
                          count: count,
                          target: selectedTarget,
                        );
                      }
                    }

                    Navigator.pop(ctx);
                    await _saveAndRefresh(updated);
                  },
                  child: Text(
                    existing == null ? 'حفظ وإضافة' : 'حفظ التعديل',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(CustomDhikrModel item) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'حذف الذكر',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Text(
            'هل تريد حذف هذا الذكر من أذكارك الخاصة؟',
            style: GoogleFonts.cairo(fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(ctx);
                final updated =
                    _items.where((e) => e.id != item.id).toList();
                await _saveAndRefresh(updated);
              },
              child: Text(
                'حذف',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark
        ? const [Color(0xFF0B131E), Color(0xFF152233)]
        : const [Color(0xFFF0FDF4), Color(0xFFE6F4EA), Color(0xFFF0FDF4)];
    const accent = Color(0xFF0F766E);
    final filtered = _filteredItems;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'أذكاري الخاصة ✍️',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF0B131E) : accent,
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showDhikrEditorDialog(),
          backgroundColor: accent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'إضافة ذكر',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
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
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.35 : 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: accent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'الأذكار التي تضيفها هنا تُحفظ دائماً وتظهر في نهاية أذكار الصباح والمساء قبل الذكرين الإضافيين (١٠٠ مرة) مباشرة.',
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.teal.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip('الكل (${_items.length})', 'all', isDark, accent),
                    const SizedBox(width: 8),
                    _buildFilterChip('الصباح', 'morning', isDark, accent),
                    const SizedBox(width: 8),
                    _buildFilterChip('المساء', 'evening', isDark, const Color(0xFF4F46E5)),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                size: 64,
                                color: accent.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'لا توجد أذكار مضافة بعد',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'اضغط على زر "إضافة ذكر" بالأسفل لإضافة أذكارك الخاصة وتحديد عدد تكرارها.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 88),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final tagColor = _targetColor(item.target);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 1.5,
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: tagColor.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: tagColor.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _targetLabel(item.target),
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: tagColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.amber
                                              .withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'التكرار: ${item.count}',
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.amber.shade200
                                                : Colors.amber.shade900,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(
                                          Icons.edit_rounded,
                                          size: 19,
                                          color: Colors.teal,
                                        ),
                                        tooltip: 'تعديل',
                                        onPressed: () =>
                                            _showDhikrEditorDialog(existing: item),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 20,
                                          color: Colors.redAccent,
                                        ),
                                        tooltip: 'حذف',
                                        onPressed: () => _confirmDelete(item),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.text,
                                    style: GoogleFonts.amiri(
                                      fontSize: 18,
                                      height: 1.6,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (item.reward.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      item.reward,
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
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

  Widget _buildFilterChip(
    String label,
    String value,
    bool isDark,
    Color activeColor,
  ) {
    final selected = _filter == value;
    return ChoiceChip(
      visualDensity: VisualDensity.compact,
      label: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: selected
              ? Colors.white
              : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
        ),
      ),
      selected: selected,
      selectedColor: activeColor,
      onSelected: (_) => setState(() => _filter = value),
    );
  }
}
