import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app_update_service.dart';

class UpdateViewModel extends ChangeNotifier {
  bool _isDownloading = false;
  double _downloadProgress = 0;
  bool _isDownloadFinished = false;
  Map<String, dynamic>? _updateInfo;

  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  bool get isDownloadFinished => _isDownloadFinished;
  Map<String, dynamic>? get updateInfo => _updateInfo;

  void setUpdateInfo(Map<String, dynamic> info) {
    _updateInfo = info;
    notifyListeners();
  }

  Future<void> startUpdate() async {
    if (_updateInfo == null || _isDownloading) return;

    if (await Permission.requestInstallPackages.request().isGranted) {
      _isDownloading = true;
      _isDownloadFinished = false;
      _downloadProgress = 0;
      notifyListeners();

      AppUpdateService.downloadAndInstall(
        _updateInfo!['downloadUrl'],
        _updateInfo!['version'].toString().replaceAll('.', '_'),
      ).listen(
        (event) {
          if (event.status == OtaStatus.DOWNLOADING) {
            _downloadProgress = double.tryParse(event.value ?? "0") ?? 0;
            notifyListeners();
          } else if (event.status == OtaStatus.INSTALLING) {
            _isDownloading = false;
            _isDownloadFinished = true;
            _downloadProgress = 100;
            notifyListeners();
          } else if (event.status.toString().contains('ERROR')) {
            _isDownloading = false;
            notifyListeners();
            // You can handle error message here
          }
        },
        onError: (e) {
          _isDownloading = false;
          notifyListeners();
        },
      );
    }
  }

  void resetStatus() {
    _isDownloading = false;
    _isDownloadFinished = false;
    _downloadProgress = 0;
    notifyListeners();
  }
}
