import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:religious_tasks_app/shared/services/audio/radio_service.dart';

class RadioViewModel extends ChangeNotifier {
  final RadioService _radioService = RadioService();
  RadioStation? _currentStation;
  bool _isLoading = false;

  RadioViewModel() {
    _radioService.player.playerStateStream.listen((state) {
      _handleOverlay();
      notifyListeners();
    });
  }

  void _handleOverlay() async {
    if (isPlaying) {
      if (!await FlutterOverlayWindow.isPermissionGranted()) {
        await FlutterOverlayWindow.requestPermission();
        return;
      }

      final bool isRunning = await FlutterOverlayWindow.isActive();
      if (!isRunning) {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          flag: OverlayFlag.defaultFlag,
          width: 120, // Slightly larger for easier dragging
          height: 120,
          alignment: OverlayAlignment.centerRight,
        );
      }
      // Delay slightly to ensure overlay is ready to receive
      Future.delayed(const Duration(milliseconds: 500), () {
        FlutterOverlayWindow.shareData("RADIO_MODE");
      });
    } else {
      await FlutterOverlayWindow.closeOverlay();
    }
  }

  RadioStation? get currentStation => _currentStation;
  bool get isLoading => _isLoading || 
                        playerState.processingState == ProcessingState.loading || 
                        playerState.processingState == ProcessingState.buffering;
  bool get isPlaying => _radioService.player.playing;
  PlayerState get playerState => _radioService.player.playerState;

  Future<void> toggleStation(RadioStation station) async {
    if (_currentStation?.id == station.id && isPlaying) {
      await _radioService.pause();
    } else {
      try {
        _isLoading = true;
        _currentStation = station;
        notifyListeners();
        await _radioService.playStation(station);
      } catch (e) {
        debugPrint("Error in toggleStation: $e");
        _isLoading = false;
        _currentStation = null;
        notifyListeners();
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> stop() async {
    await _radioService.stop();
    _currentStation = null;
    notifyListeners();
  }
}
