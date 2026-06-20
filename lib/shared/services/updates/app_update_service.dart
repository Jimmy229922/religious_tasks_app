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
        final latestTag = data['tag_name'] as String; 
        
        debugPrint('Checking update: Current Build $currentBuildNumber, Current Version $currentVersion');
        debugPrint('Checking update: Latest Tag from GitHub: $latestTag');
        
        final parts = latestTag.replaceAll('v', '').split('+');
        final latestVersion = parts[0];
        final latestBuildNumber = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

        debugPrint('Checking update: Parsed Latest Version: $latestVersion, Build: $latestBuildNumber');

        if (latestBuildNumber > currentBuildNumber || _isVersionGreater(latestVersion, currentVersion)) {
          debugPrint('Checking update: Update FOUND!');
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

  static Stream<OtaEvent> downloadAndInstall(String url, String version) {
    return OtaUpdate().execute(
      url,
      destinationFilename: 'update_$version.apk', // Unique name per version
    );
  }
}
