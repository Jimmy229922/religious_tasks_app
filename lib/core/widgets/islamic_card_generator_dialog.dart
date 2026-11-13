import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum CardThemePreset {
  emerald,
  midnight,
  sand,
  dark,
  teal,
}

class IslamicCardGeneratorDialog extends StatefulWidget {
  final String title;
  final String content;
  final String? subtitle;

  const IslamicCardGeneratorDialog({
    super.key,
    required this.title,
    required this.content,
    this.subtitle,
  });

  @override
  State<IslamicCardGeneratorDialog> createState() =>
      _IslamicCardGeneratorDialogState();
}

class _IslamicCardGeneratorDialogState
    extends State<IslamicCardGeneratorDialog> {
  final GlobalKey _cardKey = GlobalKey();
  CardThemePreset _selectedTheme = CardThemePreset.emerald;
  String _selectedFont = 'aref'; // 'aref', 'cairo', 'mono'
  bool _showWatermark = true;
  bool _isExporting = false;

  List<Color> _getGradients(CardThemePreset preset, bool isDark) {
    switch (preset) {
      case CardThemePreset.emerald:
        return const [Color(0xFF0B2915), Color(0xFF1B5E20)];
      case CardThemePreset.midnight:
        return const [Color(0xFF0F172A), Color(0xFF1E293B)];
      case CardThemePreset.sand:
        return const [Color(0xFFFEF3C7), Color(0xFFFDE68A)];
      case CardThemePreset.dark:
        return const [Color(0xFF000000), Color(0xFF18181B)];
      case CardThemePreset.teal:
        return const [Color(0xFF0F766E), Color(0xFF0369A1)];
    }
  }

  Color _getTextColor(CardThemePreset preset) {
    if (preset == CardThemePreset.sand) {
      return const Color(0xFF78350F);
    }
    return Colors.white;
  }

  Color _getAccentColor(CardThemePreset preset) {
    if (preset == CardThemePreset.sand) {
      return const Color(0xFFB45309);
    }
    return Colors.amber;
  }

  TextStyle _getFontStyle(CardThemePreset preset) {
    final color = _getTextColor(preset);
    switch (_selectedFont) {
      case 'cairo':
        return GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
          height: 1.5,
        );
      case 'mono':
        return GoogleFonts.ibmPlexMono(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
          height: 1.5,
        );
      case 'aref':
      default:
        return GoogleFonts.arefRuqaa(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: color,
          height: 1.5,
        );
    }
  }

  Future<void> _shareCardAsImage() async {
    if (_isExporting) return;
    setState(() {
      _isExporting = true;
    });

    try {
      RenderRepaintBoundary? boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary != null) {
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          Uint8List pngBytes = byteData.buffer.asUint8List();
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/islamic_card.png');
          await file.writeAsBytes(pngBytes);

          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path)],
              text: '🌿 تم الإنشاء عبر تطبيق رفيق المسلم - الدال على الخير كفاعله',
              subject: widget.title,
            ),
          );
          return;
        }
      }
    } catch (e) {
      debugPrint("Error sharing card as image: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }

    _shareCardAsText();
  }

  void _shareCardAsText() {
    final String textToShare =
        '✨ ${widget.title} ✨\n\n'
        '"${widget.content}"\n'
        '${widget.subtitle != null ? "📌 ${widget.subtitle}\n" : ""}\n'
        '${_showWatermark ? "🌿 تطبيق رفيق المسلم - الدال على الخير كفاعله\nhttps://whatsapp.com/channel/0029VaNwp3YDzgT3fxWoGx2z" : ""}';

    SharePlus.instance.share(
      ShareParams(
        text: textToShare,
        subject: widget.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF18181B) : Colors.white;

    final gradientColors = _getGradients(_selectedTheme, isDark);
    final textColor = _getTextColor(_selectedTheme);
    final accentColor = _getAccentColor(_selectedTheme);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.style_rounded, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        "صانع البطاقات الإيمانية 🎨",
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.teal.shade900,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Live Card Preview (Captured by RepaintBoundary)
              RepaintBoundary(
                key: _cardKey,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: accentColor,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '"${widget.content}"',
                        textAlign: TextAlign.center,
                        style: _getFontStyle(_selectedTheme),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          widget.subtitle!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      if (_showWatermark) ...[
                        const SizedBox(height: 20),
                        Divider(
                            color: textColor.withValues(alpha: 0.2), height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mosque, size: 14, color: accentColor),
                            const SizedBox(width: 6),
                            Text(
                              "تطبيق رفيق المسلم • الدال على الخير كفاعله 🌿",
                              style: GoogleFonts.cairo(
                                color: textColor.withValues(alpha: 0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Theme Selector
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "اختر النمط والألوان:",
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildThemeChip(CardThemePreset.emerald, "زمردي 🌿"),
                    const SizedBox(width: 8),
                    _buildThemeChip(CardThemePreset.midnight, "كحلي 🌌"),
                    const SizedBox(width: 8),
                    _buildThemeChip(CardThemePreset.sand, "رمال 📜"),
                    const SizedBox(width: 8),
                    _buildThemeChip(CardThemePreset.dark, "داكن 🖤"),
                    const SizedBox(width: 8),
                    _buildThemeChip(CardThemePreset.teal, "تركواز 💎"),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Font Selector
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "اختر نوع الخط:",
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildFontChip('aref', "رقعة إسلامي"),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFontChip('cairo', "خط كايرو"),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFontChip('mono', "حديث أنيق"),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Watermark Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "إظهار الشعار (الدال على الخير كفاعله)",
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                value: _showWatermark,
                activeTrackColor: Colors.teal,
                onChanged: (val) => setState(() => _showWatermark = val),
              ),

              const SizedBox(height: 16),

              // Export Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _shareCardAsImage,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.image_rounded, color: Colors.white),
                      label: Text(
                        _isExporting ? "جاري التجهيز..." : "مشاركة كصورة PNG 🖼️",
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: OutlinedButton.icon(
                      onPressed: _shareCardAsText,
                      icon: const Icon(Icons.text_snippet_rounded, size: 18),
                      label: Text(
                        "كنص 📝",
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
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
      ),
    );
  }

  Widget _buildThemeChip(CardThemePreset preset, String label) {
    final isSelected = _selectedTheme == preset;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.teal.shade900,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.teal,
      backgroundColor: Colors.teal.withValues(alpha: 0.1),
      onSelected: (_) => setState(() => _selectedTheme = preset),
    );
  }

  Widget _buildFontChip(String fontKey, String label) {
    final isSelected = _selectedFont == fontKey;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.teal.shade900,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.teal,
      backgroundColor: Colors.teal.withValues(alpha: 0.1),
      onSelected: (_) => setState(() => _selectedFont = fontKey),
    );
  }
}
