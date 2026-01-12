import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:religious_tasks_app/core/services/storage_service.dart';

class TasbeehViewModel extends ChangeNotifier {
  static const String _prefsKey = 'custom_tasbeeh_athkar';
  static const String customOption = '__custom__';

  static const List<String> _defaultAthkar = [
    'سبحان الله',
    'الحمد لله',
    'الله أكبر',
    'لا إله إلا الله',
    'أستغفر الله',
    'سبحان الله وبحمده',
    'سبحان الله العظيم',
    'لا حول ولا قوة إلا بالله',
  ];

  int _counter = 0;
  String _selectedDhikr = _defaultAthkar.first;
  bool _isCustomInput = false;
  List<String> _customAthkar = [];
  final TextEditingController customController = TextEditingController();

  int get counter => _counter;
  String get selectedDhikr => _selectedDhikr;
  bool get isCustomInput => _isCustomInput;
  List<String> get allAthkar => [..._defaultAthkar, ..._customAthkar];

  TasbeehViewModel() {
    _loadCustomAthkar();
  }

  @override
  void dispose() {
    customController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomAthkar() async {
    final prefs = StorageService.instance.prefs;
    _customAthkar = prefs.getStringList(_prefsKey) ?? [];
    notifyListeners();
  }

  Future<void> _saveCustomAthkar() async {
    final prefs = StorageService.instance.prefs;
    await prefs.setStringList(_prefsKey, _customAthkar);
  }

  void increment() {
    _counter++;
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  void reset() {
    _counter = 0;
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  void selectDhikr(String? value) {
    if (value == null) return;
    if (value == customOption) {
      _isCustomInput = true;
      _selectedDhikr = customController.text.trim();
    } else {
      _isCustomInput = false;
      _selectedDhikr = value;
    }
    _counter = 0;
    notifyListeners();
  }

  void updateCustomText(String value) {
    if (_isCustomInput) {
      _selectedDhikr = value;
      notifyListeners();
    }
  }

  String? addCustomDhikr() {
    final text = customController.text.trim();
    if (text.isEmpty) {
      return 'اكتب الذكر أولاً';
    }

    final exists =
        _defaultAthkar.contains(text) || _customAthkar.contains(text);

    if (!exists) {
      _customAthkar.add(text);
      _saveCustomAthkar();
    }

    _selectedDhikr = text;
    _isCustomInput = false;
    _counter = 0;
    customController.clear();
    notifyListeners();

    return 'تمت إضافة الذكر';
  }
}
