import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';

class AppUpdateService {
  static const String githubUser = "jimmy229922";
  static const String githubRepo = "religious_tasks_app";
  static const String? githubToken = null; // Add your token here if repo is private

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      final url = Uri.parse('https://api.github.com/repos/$githubUser/$githubRepo/releases/latest');
      final headers = {
        'Accept': 'application/vnd.github.v3+json',
        if (githubToken != null) 'Authorization': 'token $githubToken',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestTag = data['tag_name'] as String; // e.g., v3.5.3+15
        
        // Basic parsing: split by '+' to get version and build number
        final parts = latestTag.replaceAll('v', '').split('+');
        final latestVersion = parts[0];
        final latestBuildNumber = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

        // Compare build numbers or versions
        if (latestBuildNumber > currentBuildNumber || _isVersionGreater(latestVersion, currentVersion)) {
          // Find the best APK asset (prefer v7a or universal)
          final assets = data['assets'] as List;
          var apkAsset = assets.firstWhere(
            (asset) => (asset['name'] as String).toLowerCase().contains('v7a'),
            orElse: () => assets.firstWhere(
              (asset) => (asset['name'] as String).toLowerCase().contains('universal'),
              orElse: () => assets.firstWhere(
                (asset) => (asset['name'] as String).endsWith('.apk'),
                orElse: () => null,
              ),
            ),
          );

          if (apkAsset != null) {
            return {
              'version': latestVersion,
              'buildNumber': latestBuildNumber,
              'downloadUrl': apkAsset['browser_download_url'],
              'releaseNotes': data['body'],
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }
    return null;
  }

  static bool _isVersionGreater(String latest, String current) {
    List<int> latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (var i = 0; i < latestParts.length && i < currentParts.length; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return latestParts.length > currentParts.length;
  }

  static Stream<OtaEvent> downloadAndInstall(String url) {
    return OtaUpdate().execute(
      url,
      destinationFilename: 'update.apk', // Short and safe name
    );
  }
}
