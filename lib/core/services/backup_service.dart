import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
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
  static const int _maxBackupBytes = 512 * 1024;
  static const String _googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static const Set<String> _allowedBackupKeys = {
    'app_theme_mode_v1',
    'app_theme_mode',
    'app_accent_color_v1',
    'app_text_scale_v1',
    'app_oled_black_v1',
    'hijri_date_offset_v1',
    'khatmah_target_days',
    'khatmah_start_page',
    'khatmah_start_date',
    'athkar_morning_done_dates',
    'athkar_evening_done_dates',
    'athkar_morning_date',
    'athkar_morning_progress',
    'athkar_evening_date',
    'athkar_evening_progress',
    'athkar_sleep_date',
    'athkar_sleep_progress',
    'athkar_font_scale',
    'last_opened_date_v2',
    'saved_tasks_v2',
    'athkar_streaks_v1',
    'earned_badges_v1',
    'total_dhikr_count_v1',
    'quran_last_surah',
    'quran_last_ayah',
    'prophet_prayer_counter',
    'custom_tasbeeh_athkar',
    'total_tasbeeh_count_v1',
    'favorite_radio_stations',
    'calculation_method',
    'adhan_sound_type_v1',
    'hourly_dhikr_enabled_v1',
    'hourly_dhikr_interval_minutes_v1',
    'morning_athkar_reminder_enabled_v1',
    'evening_athkar_reminder_enabled_v1',
    'floating_dhikr_enabled_v1',
    'selected_moazzen_id_v1',
    'salawat_reminder_enabled_v1',
    'salawat_interval_minutes_v1',
    'stop_adhan_on_volume_btn_v1',
    'stop_salawat_on_volume_btn_v1',
    'happiness_jar_enabled_v1',
    'happiness_jar_hour_v1',
    'happiness_jar_minute_v1',
    'happiness_jar_favorites_v1',
    'user_custom_dhikrs_v1',
  };

  static const Set<String> _allowedBackupKeyPrefixes = {
    'adhan_enabled_',
    'prayer_offset_',
    'saved_tasks_v2_last_date_',
  };

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: _googleWebClientId.isEmpty ? null : _googleWebClientId,
  );

  static bool _isAllowedBackupKey(String key) {
    return _allowedBackupKeys.contains(key) ||
        _allowedBackupKeyPrefixes.any(key.startsWith);
  }

  static String _normalizedEmail(String email) => email.trim().toLowerCase();

  // Get saved Gmail / Google account email
  static Future<String?> getSavedGoogleAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_googleAccountKey);
    final user = Supabase.instance.client.auth.currentUser;
    if (savedEmail == null ||
        user == null ||
        user.email == null ||
        _normalizedEmail(savedEmail) != _normalizedEmail(user.email!)) {
      return null;
    }
    return savedEmail;
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
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }

  // Authenticate with Google, then exchange the verified ID token for a
  // Supabase Auth session. An email address alone is never proof of ownership.
  static Future<String?> selectGoogleAccount() async {
    if (_googleWebClientId.isEmpty) {
      debugPrint('Google authentication is not configured for this build.');
      return null;
    }

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      if (idToken == null ||
          idToken.isEmpty ||
          accessToken == null ||
          accessToken.isEmpty) {
        await _googleSignIn.signOut();
        return null;
      }

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      final user = response.user;
      if (response.session == null ||
          user == null ||
          user.email == null ||
          _normalizedEmail(user.email!) != _normalizedEmail(account.email)) {
        await unlinkGoogleAccount();
        return null;
      }

      // This RPC has no email parameter. It may only claim an unowned legacy
      // row whose email matches the verified Google identity on the server.
      await Supabase.instance.client.rpc('claim_legacy_app_backup');
      await saveGoogleAccount(user.email!);
      return user.email;
    } catch (e) {
      debugPrint('Google/Supabase authentication failed: $e');
      await unlinkGoogleAccount();
    }
    return null;
  }

  static String? _authenticatedOwnerId(String googleEmail) {
    final auth = Supabase.instance.client.auth;
    final session = auth.currentSession;
    final user = auth.currentUser;
    if (session == null ||
        user == null ||
        user.email == null ||
        _normalizedEmail(user.email!) != _normalizedEmail(googleEmail)) {
      return null;
    }
    return user.id;
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
      if (!_isAllowedBackupKey(key)) continue;
      final value = prefs.get(key);
      backupMap[key] = value;
    }

    final Map<String, dynamic> fullPackage = {
      'header': _backupHeader,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': backupMap,
    };

    final encoded = jsonEncode(fullPackage);
    if (utf8.encode(encoded).length > _maxBackupBytes) {
      throw const FormatException('Backup data is too large.');
    }
    return encoded;
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
        text: '🌿 نسخة احتياطية محفوظة من تطبيق رفيق المسلم',
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
      final ownerId = _authenticatedOwnerId(googleEmail);
      if (ownerId == null) return false;

      final jsonStr = await exportBackupData();

      final supabase = Supabase.instance.client;
      await supabase.from('app_backups').upsert({
        'owner_id': ownerId,
        'backup_data': jsonStr,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'owner_id').timeout(const Duration(seconds: 15));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _lastBackupTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      return true;
    } catch (e) {
      debugPrint("Cloud backup upload error: $e");
      return false;
    }
  }

  // Get Cloud Backup Metadata before restoring
  static Future<Map<String, dynamic>?> getCloudBackupMetadata(
      String googleEmail) async {
    try {
      final ownerId = _authenticatedOwnerId(googleEmail);
      if (ownerId == null) return null;

      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('app_backups')
          .select('backup_data, updated_at')
          .eq('owner_id', ownerId)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));

      if (response != null && response['backup_data'] != null) {
        final backupJson = response['backup_data'].toString();
        if (utf8.encode(backupJson).length > _maxBackupBytes) return null;
        final decoded = jsonDecode(backupJson);
        if (decoded is! Map<String, dynamic> ||
            decoded['header'] != _backupHeader) {
          return null;
        }
        final fullPackage = decoded;
        final int timestamp = fullPackage['timestamp'] ?? 0;
        final dt = DateTime.fromMillisecondsSinceEpoch(
            timestamp > 0 ? timestamp : DateTime.now().millisecondsSinceEpoch);
        final formattedDate =
            intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(dt);

        return {
          'formattedDate': formattedDate,
          'jsonStr': backupJson,
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
      if (_authenticatedOwnerId(googleEmail) == null) return false;
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

  // Delete Cloud Backup record & account from Supabase (Google Play Data Deletion Policy Compliance)
  static Future<bool> deleteCloudBackup(String googleEmail) async {
    try {
      final ownerId = _authenticatedOwnerId(googleEmail);
      if (ownerId == null) return false;

      final supabase = Supabase.instance.client;
      try {
        await supabase
            .rpc('delete_user_account')
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        debugPrint("RPC delete_user_account fallback: $e");
        await supabase
            .from('app_backups')
            .delete()
            .eq('owner_id', ownerId)
            .timeout(const Duration(seconds: 15));
      }
      await unlinkGoogleAccount();
      return true;
    } catch (e) {
      debugPrint("Error deleting cloud backup: $e");
      return false;
    }
  }

  // Restore app data from JSON string
  static Future<bool> restoreBackupData(String jsonStr) async {
    try {
      if (utf8.encode(jsonStr).length > _maxBackupBytes) return false;

      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) return false;
      final fullPackage = decoded;
      if (fullPackage['header'] != _backupHeader) {
        return false;
      }

      final rawData = fullPackage['data'];
      if (rawData is! Map) return false;
      final data = Map<String, dynamic>.from(rawData);
      final approvedEntries = data.entries
          .where((entry) => _isAllowedBackupKey(entry.key))
          .toList(growable: false);

      // Validate the complete approved payload before changing any local value.
      // This prevents a malformed late entry from leaving a partial restore.
      for (final entry in approvedEntries) {
        final val = entry.value;
        final isPrimitive =
            val is bool || val is int || val is double || val is String;
        final isStringList = val is List && val.every((item) => item is String);
        if (!isPrimitive && !isStringList) return false;
      }

      final prefs = await SharedPreferences.getInstance();

      for (final entry in approvedEntries) {
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
            key,
            List<String>.from(val),
          );
        }
      }

      return true;
    } catch (e) {
      debugPrint("Error restoring backup data: $e");
      return false;
    }
  }
}
