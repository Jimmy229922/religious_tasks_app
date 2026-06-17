import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class RadioStation {
  final String id;
  final String title;
  final String url;
  final String? artUri;

  const RadioStation({
    required this.id,
    required this.title,
    required this.url,
    this.artUri,
  });
}

class RadioService {
  static final RadioService _instance = RadioService._internal();
  factory RadioService() => _instance;
  RadioService._internal();

  final AudioPlayer _player = AudioPlayer();

  static const List<RadioStation> stations = [
    RadioStation(
      id: 'cairo_quran',
      title: 'إذاعة القرآن الكريم من القاهرة',
      url: 'https://n0a.radiojar.com/8s9u5p3ncd0uv',
      artUri: 'https://i.ibb.co/X7R0qjC/quran-radio.png',
    ),
    RadioStation(
      id: 'saudi_quran',
      title: 'إذاعة القرآن الكريم من السعودية',
      url: 'https://stream.radiojar.com/4wqne2v2p78uv',
    ),
    RadioStation(
      id: 'quran_live',
      title: 'بث مباشر للقرآن الكريم (قناة القرآن)',
      url: 'https://backup.qurango.net/radio/tarateel',
    ),
    RadioStation(
      id: 'nasser_al_qatami',
      title: 'ناصر القطامي',
      url: 'https://backup.qurango.net/radio/nasser_alqatami',
    ),
    RadioStation(
      id: 'maher_al_muaiqly',
      title: 'ماهر المعيقلي',
      url: 'https://backup.qurango.net/radio/maher',
    ),
    RadioStation(
      id: 'yasser_al_dosari',
      title: 'ياسر الدوسري',
      url: 'https://backup.qurango.net/radio/yasser_aldosari',
    ),
  ];

  AudioPlayer get player => _player;

  Future<void> init() async {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.jimmy.religiousapp.channel.audio',
      androidNotificationChannelName: 'راديو القرآن الكريم',
      androidNotificationOngoing: true,
    );

    // Handle interruptions (like Adhan)
    _player.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace stackTrace) {
      debugPrint('A stream error occurred: $e');
    });
  }

  void resume() {
    if (!_player.playing && _player.processingState == ProcessingState.ready) {
      _player.play();
    }
  }

  Future<void> playStation(RadioStation station) async {
    try {
      final uri = Uri.parse(station.url);
      
      // تحسين الرؤوس (Headers) لمحطات RadioJar
      final headers = <String, String>{
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept': '*/*',
        'Connection': 'keep-alive',
      };

      final source = AudioSource.uri(
        uri,
        headers: headers,
        tag: MediaItem(
          id: station.id,
          title: station.title,
          album: 'راديو القرآن الكريم',
          artUri: station.artUri != null ? Uri.parse(station.artUri!) : null,
        ),
      );
      
      await _player.stop(); // التأكد من إيقاف أي بث سابق تماماً
      await _player.setAudioSource(source, preload: true);
      await _player.play();
    } catch (e) {
      debugPrint("Error playing radio: $e");
      rethrow;
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> pause() async {
    await _player.pause();
  }
}
