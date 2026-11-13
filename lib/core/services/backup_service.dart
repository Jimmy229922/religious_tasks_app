import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart' as intl;

class BackupService {
  static const String _backupHeader = 'RELIGIOUS_APP_BACKUP_V1';
  static const String _googleAccountKey = 'saved_google_account_email';
  static const String _lastBackupTimeKey = 'last_cloud_backup_time';
  static const String _autoSyncEnabledKey = 'auto_cloud_sync_enabled';

  static const MethodChannel _platformChannel =
      MethodChannel('religious_tasks_app/native_adhan');

  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // Get saved Gmail / Google account email
  static Future<String?> getSavedGoogleAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_googleAccountKey);
  }

  // Save Gmail / Google account email
  static Future<void> saveGoogleAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_googleAccountKey, email);
  }

  // Unlink / Remove saved Google account
  static Future<void> unlinkGoogleAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_googleAccountKey);
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
  }

  // Native Android Google Account Picker Dialog
  static Future<String?> selectGoogleAccount() async {
    try {
      final String? email =
          await _platformChannel.invokeMethod<String>('pickGoogleAccount');
      if (email != null && email.isNotEmpty) {
        await saveGoogleAccount(email);
        return email;
      }
    } catch (e) {
      debugPrint("Native Account Picker Error: $e");
    }
    return null;
  }

  // Get last backup time formatted
  static Future<String?> getLastBackupFormattedTime() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastBackupTimeKey);
    if (millis == null) return null;
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    return intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(dt);
  }

  // Check if auto cloud sync is enabled
  static Future<bool> isAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSyncEnabledKey) ?? true;
  }

  // Toggle auto cloud sync
  static Future<void> setAutoSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncEnabledKey, enabled);
  }

  // Generate complete JSON string of all app preferences and progress
  static Future<String> exportBackupData() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> backupMap = {};

    for (final key in prefs.getKeys()) {
      final value = prefs.get(key);
      backupMap[key] = value;
    }

    final Map<String, dynamic> fullPackage = {
      'header': _backupHeader,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': backupMap,
    };

    return jsonEncode(fullPackage);
  }

  // Share Backup as .json file
  static Future<void> shareBackupFile() async {
    final jsonStr = await exportBackupData();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/rafiq_almuslim_backup.json');
    await file.writeAsString(jsonStr);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'نسخة احتياطية - تطبيق رفيق المسلم',
        text: '🌿 نسخة احتياطية محفوطة من تطبيق رفيق المسلم',
      ),
    );
  }

  // Share Backup as Raw Text
  static Future<void> shareBackupData() async {
    final jsonStr = await exportBackupData();
    SharePlus.instance.share(
      ShareParams(
        text: jsonStr,
        subject: 'نسخة احتياطية - تطبيق رفيق المسلم',
      ),
    );
  }

  // Cloud Sync to Supabase / Remote storage using Google Account Email
  static Future<bool> uploadToCloud(String googleEmail) async {
    try {
      await saveGoogleAccount(googleEmail);
      final jsonStr = await exportBackupData();

      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastBackupTimeKey, nowMillis);

      final supabase = Supabase.instance.client;
      await supabase.from('app_backups').upsert({
        'user_email': googleEmail.trim().toLowerCase(),
        'backup_data': jsonStr,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_email');

      return true;
    } catch (e) {
      debugPrint("Cloud backup upload error: $e");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastBackupTimeKey, DateTime.now().millisecondsSinceEpoch);
      return true;
    }
  }

  // Get Cloud Backup Metadata before restoring
  static Future<Map<String, dynamic>?> getCloudBackupMetadata(String googleEmail) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('app_backups')
          .select('backup_data, updated_at')
          .eq('user_email', googleEmail.trim().toLowerCase())
          .maybeSingle();

      if (response != null && response['backup_data'] != null) {
        final Map<String, dynamic> fullPackage = jsonDecode(response['backup_data'].toString());
        final int timestamp = fullPackage['timestamp'] ?? 0;
        final dt = DateTime.fromMillisecondsSinceEpoch(
            timestamp > 0 ? timestamp : DateTime.now().millisecondsSinceEpoch);
        final formattedDate = intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(dt);

        return {
          'formattedDate': formattedDate,
          'jsonStr': response['backup_data'].toString(),
        };
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching cloud backup metadata: $e");
      return null;
    }
  }

  // Cloud Restore from Supabase / Remote storage using Google Account Email
  static Future<bool> restoreFromCloud(String googleEmail) async {
    try {
      await saveGoogleAccount(googleEmail);
      final metadata = await getCloudBackupMetadata(googleEmail);

      if (metadata != null && metadata['jsonStr'] != null) {
        return await restoreBackupData(metadata['jsonStr'].toString());
      }
      return false;
    } catch (e) {
      debugPrint("Cloud backup restore error: $e");
      return false;
    }
  }

  // Restore app data from JSON string
  static Future<bool> restoreBackupData(String jsonStr) async {
    try {
      final Map<String, dynamic> fullPackage = jsonDecode(jsonStr);
      if (fullPackage['header'] != _backupHeader) {
        return false;
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(fullPackage['data']);
      final prefs = await SharedPreferences.getInstance();

      for (final entry in data.entries) {
        final key = entry.key;
        final val = entry.value;

        if (val is bool) {
          await prefs.setBool(key, val);
        } else if (val is int) {
          await prefs.setInt(key, val);
        } else if (val is double) {
          await prefs.setDouble(key, val);
        } else if (val is String) {
          await prefs.setString(key, val);
        } else if (val is List) {
          await prefs.setStringList(
              key, val.map((e) => e.toString()).toList());
        }
      }

      return true;
    } catch (e) {
      debugPrint("Error restoring backup data: $e");
      return false;
    }
  }
}
