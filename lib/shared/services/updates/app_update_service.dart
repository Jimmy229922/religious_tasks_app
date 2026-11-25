import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';

class AppUpdateService {
  static const String githubUser = "jimmy229922";
  static const String githubRepo = "religious_tasks_app";
  static const String? githubToken =
      null; // Add your token here if repo is private

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      final url = Uri.parse(
          'https://api.github.com/repos/$githubUser/$githubRepo/releases/latest');
      final headers = {
        'Accept': 'application/vnd.github.v3+json',
        if (githubToken != null) 'Authorization': 'token $githubToken',
      };

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is! Map || data['tag_name'] is! String) return null;
        final latestTag = data['tag_name'] as String;

        debugPrint(
            'Checking update: Current Build $currentBuildNumber, Current Version $currentVersion');
        debugPrint('Checking update: Latest Tag from GitHub: $latestTag');

        final parts = latestTag.replaceAll('v', '').split('+');
        final latestVersion = parts[0];
        final latestBuildNumber =
            parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

        debugPrint(
            'Checking update: Parsed Latest Version: $latestVersion, Build: $latestBuildNumber');

        if (isUpdateAvailable(
          latestVersion: latestVersion,
          latestBuildNumber: latestBuildNumber,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
        )) {
          debugPrint('Checking update: Update FOUND!');
          return {
            'version': latestVersion,
            'buildNumber': latestBuildNumber,
            'releaseNotes': data['body'],
          };
        }
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }
    return null;
  }

  static bool isVersionGreater(String latest, String current) {
    final latestParts =
        latest.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    final currentParts =
        current.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    final partCount = latestParts.length > currentParts.length
        ? latestParts.length
        : currentParts.length;

    for (var i = 0; i < partCount; i++) {
      final latestPart = i < latestParts.length ? latestParts[i] : 0;
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }
    return false;
  }

  static bool isUpdateAvailable({
    required String latestVersion,
    required int latestBuildNumber,
    required String currentVersion,
    required int currentBuildNumber,
  }) {
    if (isVersionGreater(latestVersion, currentVersion)) return true;
    if (isVersionGreater(currentVersion, latestVersion)) return false;
    return latestBuildNumber > currentBuildNumber;
  }
}
