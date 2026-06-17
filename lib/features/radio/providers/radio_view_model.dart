import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:religious_tasks_app/shared/services/audio/radio_service.dart';

class RadioViewModel extends ChangeNotifier {
  final RadioService _radioService = RadioService();
  RadioStation? _currentStation;
  bool _isLoading = false;

  RadioViewModel() {
    _radioService.player.playerStateStream.listen((state) {
      notifyListeners();
    });
  }

  RadioStation? get currentStation => _currentStation;
  bool get isLoading => _isLoading;
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
        _currentStation = null;
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
