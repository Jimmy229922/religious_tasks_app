import 'package:flutter/material.dart';

class TasbeehSelector extends StatelessWidget {
  final List<String> items;
  final String? selectedItem;
  final bool isCustomInput;
  final TextEditingController customController;
  final VoidCallback onAddCustom;
  final ValueChanged<String?> onChanged;
  final ValueChanged<String> onCustomTextChanged;
  static const String customOption = '__custom__';

  const TasbeehSelector({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.isCustomInput,
    required this.customController,
    required this.onAddCustom,
    required this.onChanged,
    required this.onCustomTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF151E1C) : Colors.white;
    final surfaceBorder = isDark ? Colors.white12 : Colors.black12;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1D1B);
    final textMuted = isDark ? Colors.white70 : Colors.black54;
    final accent = isDark ? const Color(0xFF7BE495) : const Color(0xFF1B5E20);

    final dropdownValue = isCustomInput
        ? customOption
        : (items.contains(selectedItem) ? selectedItem : items.first);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: surfaceBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: dropdownValue,
              icon: Icon(Icons.keyboard_arrow_down, color: textMuted),
              dropdownColor: surface,
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              items: [
                ...items.map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    )),
                const DropdownMenuItem(
                  value: customOption,
                  child: Text('ذكر مخصص...'),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
        if (isCustomInput) ...[
          const SizedBox(height: 12),
          TextField(
            controller: customController,
            decoration: InputDecoration(
              labelText: 'اكتب الذكر هنا',
              labelStyle: TextStyle(color: textMuted),
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: accent),
              ),
            ),
            style: TextStyle(color: textPrimary),
            onChanged: onCustomTextChanged,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddCustom,
              icon: const Icon(Icons.add),
              label: const Text('إضافة الذكر'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
