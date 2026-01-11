import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInit = false;

  Future<void> init() async {
    if (_isInit) return;
    await _flutterTts.setLanguage("ar-SA");
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setVolume(1.0);
    _isInit = true;
  }

  Future<void> speak(String text, {Function? onCompletion}) async {
    if (!_isInit) await init();

    // Clear previous handler to avoid ghost calls
    _flutterTts.setCompletionHandler(() {});

    if (onCompletion != null) {
      _flutterTts.setCompletionHandler(() => onCompletion());
    }

    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
