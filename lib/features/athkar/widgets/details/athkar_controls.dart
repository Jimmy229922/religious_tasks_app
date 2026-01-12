import 'package:flutter/material.dart';

class AthkarControls extends StatelessWidget {
  final bool isMorning;
  final bool isNightMode;
  final bool showCompleted;
  final bool focusMode;
  final double fontScale;
  final double minFontScale;
  final double maxFontScale;
  final ValueChanged<bool> onToggleShowCompleted;
  final VoidCallback onToggleFocusMode;
  final ValueChanged<double> onFontScaleChanged;
  final ValueChanged<double> onStepFont;

  const AthkarControls({
    super.key,
    required this.isMorning,
    required this.isNightMode,
    required this.showCompleted,
    required this.focusMode,
    required this.fontScale,
    required this.minFontScale,
    required this.maxFontScale,
    required this.onToggleShowCompleted,
    required this.onToggleFocusMode,
    required this.onFontScaleChanged,
    required this.onStepFont,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = isNightMode;
    final surface = isDark ? Colors.black : Colors.white;
    final border = isDark ? Colors.white24 : Colors.black12;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white70 : Colors.black54;
    final accent = isMorning
        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFF9FA8DA) : const Color(0xFF3949AB));
    final chipBackground =
        isDark ? const Color(0xFF141414) : const Color(0xFFF2F4F2);
    final percent = (fontScale * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('غير المكتملة'),
                selected: !showCompleted,
                onSelected: (_) => onToggleShowCompleted(false),
                selectedColor: accent.withValues(alpha: isDark ? 0.25 : 0.18),
                backgroundColor: chipBackground,
                labelStyle: TextStyle(
                  color: !showCompleted ? accent : textMuted,
                  fontWeight: FontWeight.w600,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: !showCompleted ? accent : border,
                  ),
                ),
              ),
              ChoiceChip(
                label: const Text('الكل'),
                selected: showCompleted,
                onSelected: (_) => onToggleShowCompleted(true),
                selectedColor: accent.withValues(alpha: isDark ? 0.25 : 0.18),
                backgroundColor: chipBackground,
                labelStyle: TextStyle(
                  color: showCompleted ? accent : textMuted,
                  fontWeight: FontWeight.w600,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: showCompleted ? accent : border,
                  ),
                ),
              ),
              ChoiceChip(
                label: const Text('وضع التركيز'),
                selected: focusMode,
                onSelected: (_) => onToggleFocusMode(),
                selectedColor: accent.withValues(alpha: isDark ? 0.25 : 0.18),
                backgroundColor: chipBackground,
                labelStyle: TextStyle(
                  color: focusMode ? accent : textMuted,
                  fontWeight: FontWeight.w600,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: focusMode ? accent : border,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.text_fields, color: accent),
              const SizedBox(width: 8),
              Text(
                'حجم الخط',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFontButton(
                icon: Icons.remove,
                onTap: () => onStepFont(-0.05),
                accent: accent,
                surface: chipBackground,
                border: border,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accent,
                    inactiveTrackColor: accent.withValues(alpha: 0.25),
                    thumbColor: accent,
                    overlayColor: accent.withValues(alpha: 0.12),
                  ),
                  child: Slider(
                    value: fontScale,
                    min: minFontScale,
                    max: maxFontScale,
                    divisions: 12,
                    onChanged: onFontScaleChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildFontButton(
                icon: Icons.add,
                onTap: () => onStepFont(0.05),
                accent: accent,
                surface: chipBackground,
                border: border,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFontButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color accent,
    required Color surface,
    required Color border,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: surface,
          shape: BoxShape.circle,
          border: Border.all(color: border),
        ),
        child: Icon(icon, color: accent, size: 18),
      ),
    );
  }
}
