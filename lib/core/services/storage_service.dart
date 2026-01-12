import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _instance = StorageService._();
  }

  static StorageService get instance {
    if (_instance == null) {
      throw Exception("StorageService not initialized");
    }
    return _instance!;
  }

  String? getString(String key) => _prefs?.getString(key);
  Future<bool> setString(String key, String value) =>
      _prefs!.setString(key, value);
  // Add other methods as needed for transparency, or expose prefs
  SharedPreferences get prefs => _prefs!;
}
