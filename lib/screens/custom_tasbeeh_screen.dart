import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/storage_service.dart';

class CustomTasbeehScreen extends StatefulWidget {
  const CustomTasbeehScreen({super.key});

  @override
  State<CustomTasbeehScreen> createState() => _CustomTasbeehScreenState();
}

class _CustomTasbeehScreenState extends State<CustomTasbeehScreen> {
  static const String _customOption = '__custom__';
  static const String _prefsKey = 'custom_tasbeeh_athkar';

  int _counter = 0;
  String _selectedDhikr = _defaultAthkar.first;
  final TextEditingController _customController = TextEditingController();
  bool _isCustomInput = false;
  List<String> _customAthkar = [];

  static const List<String> _defaultAthkar = [
    '\u0633\u0628\u062d\u0627\u0646 \u0627\u0644\u0644\u0647',
    '\u0627\u0644\u062d\u0645\u062f \u0644\u0644\u0647',
    '\u0627\u0644\u0644\u0647 \u0623\u0643\u0628\u0631',
    '\u0644\u0627 \u0625\u0644\u0647 \u0625\u0644\u0627 \u0627\u0644\u0644\u0647',
    '\u0623\u0633\u062a\u063a\u0641\u0631 \u0627\u0644\u0644\u0647',
    '\u0633\u0628\u062d\u0627\u0646 \u0627\u0644\u0644\u0647 \u0648\u0628\u062d\u0645\u062f\u0647',
    '\u0633\u0628\u062d\u0627\u0646 \u0627\u0644\u0644\u0647 \u0627\u0644\u0639\u0638\u064a\u0645',
    '\u0644\u0627 \u062d\u0648\u0644 \u0648\u0644\u0627 \u0642\u0648\u0629 \u0625\u0644\u0627 \u0628\u0627\u0644\u0644\u0647',
  ];

  List<String> get _allAthkar => [
        ..._defaultAthkar,
        ..._customAthkar,
      ];

  @override
  void initState() {
    super.initState();
    _loadCustomAthkar();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomAthkar() async {
    // StorageService does not expose getStringList directly in the snippet I saw,
    // but looking at usage elsewhere:
    // "final prefs = StorageService.instance.prefs;" can be used.
    final prefs = StorageService.instance.prefs;
    final saved = prefs.getStringList(_prefsKey) ?? [];
    if (!mounted) return;
    setState(() {
      _customAthkar = saved;
    });
  }

  Future<void> _saveCustomAthkar() async {
    final prefs = StorageService.instance.prefs;
    await prefs.setStringList(_prefsKey, _customAthkar);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _increment() {
    setState(() {
      _counter++;
    });
    HapticFeedback.lightImpact();
  }

  void _reset() {
    setState(() {
      _counter = 0;
    });
    HapticFeedback.mediumImpact();
  }

  void _addCustomDhikr() {
    final text = _customController.text.trim();
    if (text.isEmpty) {
      _showSnack(
          '\u0627\u0643\u062a\u0628 \u0627\u0644\u0630\u0643\u0631 \u0623\u0648\u0644\u0627\u064b');
      return;
    }

    final exists =
        _defaultAthkar.contains(text) || _customAthkar.contains(text);

    setState(() {
      if (!exists) {
        _customAthkar.add(text);
      }
      _selectedDhikr = text;
      _isCustomInput = false;
      _counter = 0;
    });

    _customController.clear();
    _saveCustomAthkar();
    _showSnack(
        '\u062a\u0645\u062a \u0625\u0636\u0627\u0641\u0629 \u0627\u0644\u0630\u0643\u0631');
  }

  void _onSelectDhikr(String? value) {
    if (value == null) return;
    setState(() {
      if (value == _customOption) {
        _isCustomInput = true;
        _selectedDhikr = _customController.text.trim();
      } else {
        _isCustomInput = false;
        _selectedDhikr = value;
      }
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF151E1C) : Colors.white;
    final surfaceBorder = isDark ? Colors.white12 : Colors.black12;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1D1B);
    final textMuted = isDark ? Colors.white70 : Colors.black54;
    final accent = isDark ? const Color(0xFF7BE495) : const Color(0xFF1B5E20);
    final accentSoft =
        isDark ? const Color(0xFF4CAF50) : const Color(0xFF43A047);
    final background = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [Color(0xFF0B1A16), Color(0xFF0F2E1A), Color(0xFF0B1320)]
          : const [Color(0xFFF7FBF6), Color(0xFFE7F1EA), Color(0xFFF3F6FF)],
    );

    final dropdownValue = _isCustomInput
        ? _customOption
        : (_allAthkar.contains(_selectedDhikr)
            ? _selectedDhikr
            : _defaultAthkar.first);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
              '\u0627\u0644\u0633\u0628\u062d\u0629 \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a\u0629'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: textPrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
              tooltip:
                  '\u0625\u0639\u0627\u062f\u0629 \u0627\u0644\u062a\u0635\u0641\u064a\u0631',
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(gradient: background),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: surfaceBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.2 : 0.08),
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
                          ..._allAthkar.map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              )),
                          const DropdownMenuItem(
                            value: _customOption,
                            child: Text(
                                '\u0630\u0643\u0631 \u0645\u062e\u0635\u0635...'),
                          ),
                        ],
                        onChanged: _onSelectDhikr,
                      ),
                    ),
                  ),
                  if (_isCustomInput) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customController,
                      decoration: InputDecoration(
                        labelText:
                            '\u0627\u0643\u062a\u0628 \u0627\u0644\u0630\u0643\u0631 \u0647\u0646\u0627',
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
                      onChanged: (val) {
                        setState(() {
                          _selectedDhikr = val.trim();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addCustomDhikr,
                        icon: const Icon(Icons.add),
                        label: const Text(
                            '\u0625\u0636\u0627\u0641\u0629 \u0627\u0644\u0630\u0643\u0631'),
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
                  const SizedBox(height: 24),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _increment,
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  accent.withValues(
                                      alpha: isDark ? 0.28 : 0.15),
                                  isDark
                                      ? const Color(0xFF0E1E18)
                                      : const Color(0xFFFDFEFD),
                                ],
                              ),
                              border: Border.all(color: accent, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(
                                      alpha: isDark ? 0.35 : 0.2),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$_counter',
                                  style: TextStyle(
                                    fontSize: 80,
                                    fontWeight: FontWeight.bold,
                                    color: accent,
                                  ),
                                ),
                                Text(
                                  '\u0645\u0631\u0629',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                surface.withValues(alpha: isDark ? 0.95 : 0.98),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: surfaceBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, color: accentSoft),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedDhikr.isEmpty
                                      ? '\u0627\u062e\u062a\u0631 \u0630\u0643\u0631\u0627 \u0623\u0648 \u0627\u0643\u062a\u0628 \u0630\u0643\u0631\u0627 \u0645\u062e\u0635\u0635\u0627'
                                      : _selectedDhikr,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}
