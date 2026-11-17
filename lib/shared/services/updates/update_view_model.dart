import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateViewModel extends ChangeNotifier {
  static final Uri _playStoreAppUri =
      Uri.parse('market://details?id=com.jimmy.religiousapp');
  static final Uri _playStoreWebUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.jimmy.religiousapp',
  );

  Map<String, dynamic>? _updateInfo;

  Map<String, dynamic>? get updateInfo => _updateInfo;

  void setUpdateInfo(Map<String, dynamic> info) {
    _updateInfo = info;
    notifyListeners();
  }

  Future<void> startUpdate() async {
    if (_updateInfo == null) return;

    try {
      if (await canLaunchUrl(_playStoreAppUri)) {
        final opened = await launchUrl(
          _playStoreAppUri,
          mode: LaunchMode.externalApplication,
        );
        if (opened) return;
      }
    } catch (_) {
      // Fall back to the HTTPS Play Store page below.
    }

    await launchUrl(_playStoreWebUri, mode: LaunchMode.externalApplication);
  }
}
