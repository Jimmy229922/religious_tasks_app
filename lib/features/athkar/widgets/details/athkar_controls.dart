import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';

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
    const gold = Color(0xFFD4AF37);
    const goldLight = Color(0xFFFDE68A);
    final isDark = isNightMode;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF475569);
    final accent = isDark ? goldLight : context.primaryColor;
    final chipBackground = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.85);
    final border = gold.withValues(alpha: isDark ? 0.42 : 0.6);
    final percent = (fontScale * 100).round();

    Widget buildPill(String label, bool selected, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            color: selected ? null : chipBackground,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? gold : border,
              width: selected ? 1.3 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected
                  ? (isDark ? Colors.white : const Color(0xFF451A03))
                  : textMuted,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.appCardGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              buildPill(
                'غير المكتملة',
                !showCompleted,
                () => onToggleShowCompleted(false),
              ),
              buildPill(
                'الكل',
                showCompleted,
                () => onToggleShowCompleted(true),
              ),
              buildPill(
                'وضع التركيز',
                focusMode,
                onToggleFocusMode,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.text_fields_rounded, color: accent, size: 19),
              const SizedBox(width: 8),
              Text(
                'حجم الخط',
                style: GoogleFonts.cairo(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: isDark ? 0.16 : 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: border),
                ),
                child: Text(
                  '$percent%',
                  style: GoogleFonts.ibmPlexMono(
                    color: isDark ? goldLight : const Color(0xFF78350F),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFontButton(
                icon: Icons.remove,
                onTap: () => onStepFont(-0.05),
                accent: isDark ? goldLight : const Color(0xFF78350F),
                surface: chipBackground,
                border: border,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: gold,
                    inactiveTrackColor: gold.withValues(alpha: 0.25),
                    thumbColor: isDark ? goldLight : gold,
                    overlayColor: gold.withValues(alpha: 0.14),
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
                accent: isDark ? goldLight : const Color(0xFF78350F),
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
