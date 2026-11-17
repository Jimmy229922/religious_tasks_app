import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:religious_tasks_app/core/services/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('export includes approved progress and excludes private/internal data',
      () async {
    SharedPreferences.setMockInitialValues({
      'quran_last_surah': 'الفاتحة',
      'total_tasbeeh_count_v1': 12,
      'last_latitude': '30.0000',
      'last_longitude': '31.0000',
      'last_location_name': 'private-location',
      'saved_google_account_email': 'private@example.invalid',
      'supabase.auth.token': 'private-session-token',
      'unreviewed_key': 'private-value',
    });

    final encoded = await BackupService.exportBackupData();
    final package = jsonDecode(encoded) as Map<String, dynamic>;
    final data = package['data'] as Map<String, dynamic>;

    expect(data['quran_last_surah'], 'الفاتحة');
    expect(data['total_tasbeeh_count_v1'], 12);
    expect(data, isNot(contains('last_latitude')));
    expect(data, isNot(contains('last_longitude')));
    expect(data, isNot(contains('last_location_name')));
    expect(data, isNot(contains('saved_google_account_email')));
    expect(data, isNot(contains('supabase.auth.token')));
    expect(data, isNot(contains('unreviewed_key')));
  });

  test('restore writes only approved keys', () async {
    final encoded = jsonEncode({
      'header': 'RELIGIOUS_APP_BACKUP_V1',
      'timestamp': 1,
      'data': {
        'quran_last_surah': 'البقرة',
        'adhan_enabled_fajr': false,
        'last_latitude': '30.0000',
        'saved_google_account_email': 'private@example.invalid',
        'supabase.auth.token': 'private-session-token',
      },
    });

    expect(await BackupService.restoreBackupData(encoded), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('quran_last_surah'), 'البقرة');
    expect(prefs.getBool('adhan_enabled_fajr'), isFalse);
    expect(prefs.getString('last_latitude'), isNull);
    expect(prefs.getString('saved_google_account_email'), isNull);
    expect(prefs.getString('supabase.auth.token'), isNull);
  });

  test('restore rejects oversized or invalid backup values', () async {
    final oversized = 'x' * (513 * 1024);
    expect(await BackupService.restoreBackupData(oversized), isFalse);

    final invalidList = jsonEncode({
      'header': 'RELIGIOUS_APP_BACKUP_V1',
      'timestamp': 1,
      'data': {
        'favorite_radio_stations': [1, 2, 3],
      },
    });
    expect(await BackupService.restoreBackupData(invalidList), isFalse);
  });

  test('restore validates all approved values before writing any of them',
      () async {
    SharedPreferences.setMockInitialValues({
      'quran_last_surah': 'الفاتحة',
    });
    final malformed = jsonEncode({
      'header': 'RELIGIOUS_APP_BACKUP_V1',
      'timestamp': 1,
      'data': {
        'quran_last_surah': 'البقرة',
        'favorite_radio_stations': [1, 2, 3],
      },
    });

    expect(await BackupService.restoreBackupData(malformed), isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('quran_last_surah'), 'الفاتحة');
  });
}
