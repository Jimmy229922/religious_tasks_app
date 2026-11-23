import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class RadioStation {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String url;
  final String? fallbackUrl;
  final String category; // 'radios', 'reciters', 'tafseer'
  final String? artUri;

  const RadioStation({
    required this.id,
    required this.title,
    this.subtitle = 'بث قرآني مباشر على مدار الساعة',
    this.badge = 'مباشر',
    required this.url,
    this.fallbackUrl,
    this.category = 'reciters',
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
      title: 'إذاعة القرآن الكريم (عامة ومباشرة)',
      subtitle: 'تلاوات مختارة وبرامج قرآنية على مدار الساعة',
      badge: 'إذاعة عامة',
      url: 'https://backup.qurango.net/radio/mix',
      fallbackUrl: 'https://backup.qurango.net/radio/tarateel',
      category: 'radios',
      artUri: 'https://i.ibb.co/X7R0qjC/quran-radio.png',
    ),
    RadioStation(
      id: 'saudi_quran',
      title: 'إذاعة القرآن الكريم (تلاوات ممتازة)',
      subtitle: 'بث متواصل لأجمل التلاوات العذبة الخاشعة',
      badge: 'تلاوات مختارة',
      url: 'https://backup.qurango.net/radio/salma',
      fallbackUrl: 'https://backup.qurango.net/radio/tarateel',
      category: 'radios',
    ),
    RadioStation(
      id: 'quran_live',
      title: 'بث مباشر للقرآن الكريم (تراويح وتلاوات)',
      subtitle: 'تراتيل وتلاوات هادئة طوال اليوم',
      badge: 'تراتيل',
      url: 'https://backup.qurango.net/radio/tarateel',
      fallbackUrl: 'https://backup.qurango.net/radio/mix',
      category: 'radios',
    ),
    RadioStation(
      id: 'roqyah',
      title: 'إذاعة الرقية الشرعية',
      subtitle: 'آيات السكينة والرقية الشرعية والتحصين',
      badge: 'رقية وتحصين',
      url: 'https://backup.qurango.net/radio/roqiah',
      fallbackUrl: 'https://qurango.net/radio/roqiah',
      category: 'radios',
    ),
    RadioStation(
      id: 'tafseer',
      title: 'إذاعة تفسير القرآن الكريم',
      subtitle: 'تدبر معاني الآيات الكريمة وتفسيرها الميسر',
      badge: 'تفسير وتدبر',
      url: 'https://backup.qurango.net/radio/tafseer',
      fallbackUrl: 'https://qurango.net/radio/tafseer',
      category: 'tafseer',
    ),
    RadioStation(
      id: 'mishary_alafasi',
      title: 'الشيخ مشاري العفاسي',
      subtitle: 'تلاوات عذبة خاشعة برواية حفص عن عاصم',
      badge: 'مرتل',
      url: 'https://backup.qurango.net/radio/mishary_alafasi',
      fallbackUrl: 'https://qurango.net/radio/mishary_alafasi',
      category: 'reciters',
    ),
    RadioStation(
      id: 'abdulbasit_mojawwad',
      title: 'الشيخ عبد الباسط عبد الصمد (المجود)',
      subtitle: 'المصحف المجود بصوت القيثارة الذهبية',
      badge: 'مجود',
      url: 'https://backup.qurango.net/radio/abdulbasit_abdulsamad_mojawwad',
      fallbackUrl: 'https://qurango.net/radio/abdulbasit_abdulsamad_mojawwad',
      category: 'reciters',
    ),
    RadioStation(
      id: 'minshawi_mojawwad',
      title: 'الشيخ محمد صديق المنشاوي (المجود)',
      subtitle: 'تلاوات مجودة خاشعة تأسر القلوب',
      badge: 'مجود',
      url: 'https://backup.qurango.net/radio/minshawi_mojawwad',
      fallbackUrl: 'https://qurango.net/radio/minshawi_mojawwad',
      category: 'reciters',
    ),
    RadioStation(
      id: 'minshawi_mrtl',
      title: 'الشيخ محمد صديق المنشاوي (مرتل)',
      subtitle: 'المصحف المرتل بصوت الشيخ المنشاوي',
      badge: 'مرتل',
      url: 'https://backup.qurango.net/radio/minshawi',
      fallbackUrl: 'https://qurango.net/radio/minshawi',
      category: 'reciters',
    ),
    RadioStation(
      id: 'hussary',
      title: 'الشيخ محمود خليل الحصري',
      subtitle: 'إتقان أحكام التجويد ومخارج الحروف',
      badge: 'مرتل',
      url: 'https://backup.qurango.net/radio/hussary',
      fallbackUrl: 'https://qurango.net/radio/hussary',
      category: 'reciters',
    ),
    RadioStation(
      id: 'maher_al_muaiqly',
      title: 'الشيخ ماهر المعيقلي',
      subtitle: 'أجواء الحرم المكي وتلاوات خاشعة',
      badge: 'مرتل',
      url: 'https://backup.qurango.net/radio/maher',
      fallbackUrl: 'https://qurango.net/radio/maher',
      category: 'reciters',
    ),
    RadioStation(
      id: 'yasser_al_dosari',
      title: 'الشيخ ياسر الدوسري',
      subtitle: 'تلاوات مؤثرة من المسجد الحرام',
      badge: 'مرتل',
      url: 'https://backup.qurango.net/radio/yasser_aldosari',
      fallbackUrl: 'https://qurango.net/radio/yasser_aldosari',
      category: 'reciters',
    ),
    RadioStation(
      id: 'nasser_al_qatami',
      title: 'الشيخ ناصر القطامي',
      subtitle: 'تلاوات هادئة ومؤثرة للخشوع والتدبر',
      badge: 'مرتل',
      url: 'https://backup.qurango.net/radio/nasser_alqatami',
      fallbackUrl: 'https://qurango.net/radio/nasser_alqatami',
      category: 'reciters',
    ),
    RadioStation(
      id: 'sudaes',
      title: 'الشيخ عبد الرحمن السديس',
      subtitle: 'تلاوات الحرم المكي الجهورية المباركة',
      badge: 'مرتل',
      url: 'https://backup.qurango.net/radio/sudaes',
      fallbackUrl: 'https://qurango.net/radio/sudaes',
      category: 'reciters',
    ),
    RadioStation(
      id: 'shuraym',
      title: 'الشيخ سعود الشريم',
      subtitle: 'ترتيل عذب يبعث السكينة في النفوس',
      badge: 'مرتل',
      url: 'https://backup.qurango.net/radio/shuraym',
      fallbackUrl: 'https://qurango.net/radio/shuraym',
      category: 'reciters',
    ),
    RadioStation(
      id: 'ahmad_al_ajmy',
      title: 'الشيخ أحمد العجمي',
      subtitle: 'صوت شجي وتلاوات خاشعة طوال اليوم',
      badge: 'مرتل',
      url: 'https://backup.qurango.net/radio/ahmad_al_ajmy',
      fallbackUrl: 'https://qurango.net/radio/ahmad_al_ajmy',
      category: 'reciters',
    ),
    RadioStation(
      id: 's_ghamedi',
      title: 'الشيخ سعد الغامدي',
      subtitle: 'ترتيل متوازن وهادئ مناسب للمراجعة والاستماع',
      badge: 'مرتل',
      url: 'https://backup.qurango.net/radio/s_ghamedi',
      fallbackUrl: 'https://qurango.net/radio/s_ghamedi',
      category: 'reciters',
    ),
    RadioStation(
      id: 'banna_mojawwad',
      title: 'الشيخ محمود علي البنا (المجود)',
      subtitle: 'روائع التلاوة المصرية الأصيلة',
      badge: 'مجود',
      url: 'https://backup.qurango.net/radio/banna_mojawwad',
      fallbackUrl: 'https://qurango.net/radio/banna_mojawwad',
      category: 'reciters',
    ),
    RadioStation(
      id: 'mohammad_ayyoub',
      title: 'الشيخ محمد أيوب',
      subtitle: 'تلاوة حجازية أصيلة من المسجد النبوي',
      badge: 'مرتل',
      url: 'https://backup.qurango.net/radio/mohammad_ayyoub',
      fallbackUrl: 'https://qurango.net/radio/mohammad_ayyoub',
      category: 'reciters',
    ),
    RadioStation(
      id: 'juhany',
      title: 'الشيخ عبد الله الجهني',
      subtitle: 'ترتيل خاشع من رحاب المسجد الحرام',
      badge: 'مرتل',
      url: 'https://backup.qurango.net/radio/juhany',
      fallbackUrl: 'https://qurango.net/radio/juhany',
      category: 'reciters',
    ),
    RadioStation(
      id: 'tablawi',
      title: 'الشيخ محمد محمود الطبلاوي',
      subtitle: 'نغمات قرآنية أصيلة وتلاوة متقنة',
      badge: 'مرتل',
      url: 'https://backup.qurango.net/radio/mohammad_altablawi',
      fallbackUrl: 'https://qurango.net/radio/mohammad_altablawi',
      category: 'reciters',
    ),
  ];

  AudioPlayer get player => _player;
  Stream<IcyMetadata?> get icyMetadataStream => _player.icyMetadataStream;

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> init() async {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.jimmy.religiousapp.channel.audio',
      androidNotificationChannelName: 'راديو القرآن الكريم',
      androidNotificationOngoing: true,
    );

    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      debugPrint('A stream error occurred: $e');
    });
  }

  void resume() {
    if (!_player.playing && _player.processingState == ProcessingState.ready) {
      _player.play();
    }
  }

  Future<void> playStation(RadioStation station) async {
    final urlsToTry = <String>[
      station.url,
      if (station.fallbackUrl != null && station.fallbackUrl != station.url)
        station.fallbackUrl!,
      if (station.url.contains('backup.qurango.net'))
        station.url.replaceAll('backup.qurango.net', 'qurango.net')
      else if (station.url.contains('qurango.net'))
        station.url.replaceAll('qurango.net', 'backup.qurango.net'),
    ];

    Object? lastError;

    for (final url in urlsToTry) {
      try {
        final uri = Uri.parse(url);
        final headers = <String, String>{
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Mobile Safari/537.36',
          'Accept': '*/*',
          'Icy-MetaData': '1',
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

        await _player.stop();
        // preload: false guarantees ExoPlayer starts Shoutcast/Icecast streaming immediately without blocking
        await _player
            .setAudioSource(source, preload: false)
            .timeout(const Duration(seconds: 15));
        await _player.play();
        return; // Success!
      } catch (e) {
        debugPrint("Failed to play stream URL $url: $e");
        lastError = e;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> pause() async {
    await _player.pause();
  }
}
