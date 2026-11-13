import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:religious_tasks_app/core/services/audio_service.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';

class DuaaSafarItem {
  final String title;
  final String text;
  final String reward;
  final int count;

  const DuaaSafarItem({
    required this.title,
    required this.text,
    required this.reward,
    this.count = 1,
  });
}

class DuaaSafarScreen extends StatefulWidget {
  const DuaaSafarScreen({super.key});

  @override
  State<DuaaSafarScreen> createState() => _DuaaSafarScreenState();
}

class _DuaaSafarScreenState extends State<DuaaSafarScreen> {
  final AudioService _audioService = AudioService();
  int? _playingIndex;
  late final List<int> _counters;

  final List<DuaaSafarItem> _items = const [
    DuaaSafarItem(
      title: 'التَّكْبِيرُ عِنْدَ رُكُوبِ المَرْكَبَةِ',
      text: 'اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ.',
      reward: 'سُنَّةٌ ثَابِتَةٌ عَنِ النَّبِيِّ ﷺ عِنْدَ اسْتِوَائِهِ عَلَى دَابَّتِهِ أَوْ مَرْكَبَتِهِ',
      count: 3,
    ),
    DuaaSafarItem(
      title: 'دُعَاءُ السَّفَرِ وَالرُّكُوبِ (مِنَ السُّنَّةِ)',
      text:
          'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ ﴿١٣﴾ وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ ﴿١٤﴾\n\n'
          'اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا الْبِرَّ وَالتَّقْوَى، وَمِنَ الْعَمَلِ مَا تَرْضَى،\n'
          'اللَّهُمَّ هَوِّنْ عَلَيْنَا سَفَرَنَا هَذَا، وَاطْوِ عَنَّا بُعْدَهُ،\n'
          'اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ، وَالْخَلِيفَةُ فِي الْأَهْلِ،\n'
          'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ وَعْثَاءِ السَّفَرِ، وَكَآبَةِ الْمَنْظَرِ، وَسُوءِ الْمُنْقَلَبِ فِي الْمَالِ وَالْأَهْلِ.',
      reward: 'الدُّعَاءُ الْجَامِعُ لِلْحِفْظِ وَالتَّوْفِيقِ وَالسَّلَامَةِ فِي السَّفَرِ',
      count: 1,
    ),
    DuaaSafarItem(
      title: 'دُعَاءُ الْعَوْدَةِ وَالإِيَابِ مِنَ السَّفَرِ',
      text:
          'آيِبُونَ تَائِبُونَ عَابِدُونَ لِرَبِّنَا حَامِدُونَ.',
      reward: 'يُقَالُ عِنْدَ الرُّجُوعِ مِنَ السَّفَرِ وَالْقُدُومِ إِلَى الْبَلَدِ',
      count: 1,
    ),
    DuaaSafarItem(
      title: 'دُعَاءُ الْمُقِيمِ لِلْمُسَافِرِ (وَدَاعُ الْمُسَافِرِ)',
      text: 'أَسْتَوْدِعُ اللَّهَ دِينَكَ، وَأَمَانَتَكَ، وَخَوَاتِيمَ عَمَلِكَ.',
      reward: 'يُقَالُ عِنْدَ تَوَدِيعِ الْمُسَافِرِ لِحِفْظِ الدِّينِ وَالْأَمَانَةِ',
      count: 1,
    ),
    DuaaSafarItem(
      title: 'دُعَاءُ الْمُسَافِرِ لِلْمُقِيمِ',
      text: 'أَسْتَوْدِعُكُمُ اللَّهَ الَّذِي لَا تَضِيعُ وَدَائِعُهُ.',
      reward: 'حِفْظُ وَسَلَامَةُ الْأَهْلِ وَالْمَالِ وَالأَحْبَابِ عِنْدَ الْمُغَادَرَةِ',
      count: 1,
    ),
    DuaaSafarItem(
      title: 'دُعَاءُ النُّزُولِ فِي مَكَانٍ أَوْ مَنْزِلٍ جَدِيدٍ',
      text: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.',
      reward: 'لَمْ يَضُرَّهُ شَيْءٌ حَتَّى يَرْتَحِلَ مِنْ مَنْزِلِهِ ذَلِكَ',
      count: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _counters = List<int>.filled(_items.length, 0);
    _audioService.init();
  }

  @override
  void dispose() {
    _audioService.stop();
    super.dispose();
  }

  Future<void> _speak(String text, int index) async {
    if (_playingIndex == index) {
      await _audioService.stop();
      setState(() => _playingIndex = null);
      return;
    }

    await _audioService.stop();
    setState(() => _playingIndex = index);

    await _audioService.speak(text, onCompletion: () {
      if (mounted) setState(() => _playingIndex = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = Color(0xFF0288D1); // Azure Blue for Travel

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'دعاء السفر',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Container(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0D47A1), const Color(0xFF006064)]
                        : [const Color(0xFF0288D1), const Color(0xFF00ACC1)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flight_takeoff_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'أدعية وأذكار السفر',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'حصّن نفسك وأهلك بأدعية السفر المأثورة عن النبي ﷺ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Items List
              ...List.generate(_items.length, (index) {
                final item = _items[index];
                final currentCount = _counters[index];
                final isDone = currentCount >= item.count;
                final isPlaying = _playingIndex == index;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? (isDone ? const Color(0xFF1A2634) : const Color(0xFF1E1E1E))
                        : (isDone ? const Color(0xFFE1F5FE) : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDone
                          ? accentColor
                          : (isDark ? Colors.white10 : Colors.black12),
                      width: isDone ? 2 : 1,
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF4FC3F7) : accentColor,
                                ),
                              ),
                            ),
                            if (item.count > 1)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_counters[index] < item.count) {
                                      _counters[index]++;
                                    } else {
                                      _counters[index] = 0;
                                    }
                                  });
                                  HapticFeedback.lightImpact();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: accentColor.withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.touch_app,
                                          size: 14, color: accentColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$currentCount / ${item.count}',
                                        style: const TextStyle(
                                          color: accentColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Dhikr Main Text
                        if (item.text.contains('﴿') || item.text.contains('۝') || item.text.contains('«'))
                          QuranTextFormatter.buildFormattedQuranText(
                            item.text,
                            baseStyle: TextStyle(
                              fontSize: 18,
                              height: 1.8,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            badgeColor: const Color(0xFFD4AF37),
                          )
                        else
                          SelectableText(
                            item.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              height: 1.8,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        const SizedBox(height: 14),

                        // Reward / Description
                        if (item.reward.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : accentColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.reward,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Action buttons (Audio, Copy, Share)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(
                                isPlaying
                                    ? Icons.stop_circle_outlined
                                    : Icons.volume_up_rounded,
                                color: isPlaying ? accentColor : (isDark ? Colors.white60 : Colors.black54),
                              ),
                              onPressed: () => _speak(item.text, index),
                              tooltip: 'استماع',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.copy_rounded,
                                color: isDark ? Colors.white60 : Colors.black54,
                                size: 20,
                              ),
                              onPressed: () async {
                                await Clipboard.setData(
                                    ClipboardData(text: item.text));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم نسخ النص بنجاح'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              tooltip: 'نسخ',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.share_rounded,
                                color: isDark ? Colors.white60 : Colors.black54,
                                size: 20,
                              ),
                              onPressed: () {
                                SharePlus.instance.share(
                                  ShareParams(
                                    text: '${item.title}\n\n${item.text}\n\n${item.reward}',
                                  ),
                                );
                              },
                              tooltip: 'مشاركة',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
