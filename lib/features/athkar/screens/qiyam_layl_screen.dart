import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';

class QiyamItem {
  final String title;
  final String text;
  final String reward;
  final String category; // 'virtue', 'dua', 'istighfar'
  final int targetCount;

  const QiyamItem({
    required this.title,
    required this.text,
    required this.reward,
    required this.category,
    this.targetCount = 1,
  });
}

class QiyamLaylScreen extends StatefulWidget {
  const QiyamLaylScreen({super.key});

  @override
  State<QiyamLaylScreen> createState() => _QiyamLaylScreenState();
}

class _QiyamLaylScreenState extends State<QiyamLaylScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<int> _counters;

  static const List<QiyamItem> _allItems = [
    // --- الفضائل (Virtues) ---
    QiyamItem(
      category: 'virtue',
      title: 'شَرَفُ الْمُؤْمِنِ (من القرآن الكريم)',
      text:
          '﴿وَمِنَ اللَّيْلِ فَتَهَجَّدْ بِهِ نَافِلَةً لَّكَ عَسَىٰ أَن يَبْعَثَكَ رَبُّكَ مَقَامًا مَّحْمُودًا﴾\n[سورة الإسراء: 79]',
      reward: 'قيام الليل سببٌ لنيل المقام المحمود والقرب من الله تعالى.',
    ),
    QiyamItem(
      category: 'virtue',
      title: 'صِفَةُ عِبَادِ الرَّحْمَنِ',
      text:
          '﴿وَالَّذِينَ يَبِيتُونَ لِرَبِّهِمْ سُجَّدًا وَقِيَامًا﴾\n[سورة الفرقان: 64]\n\n'
          '﴿تَتَجَافَىٰ جُنُوبُهُمْ عَنِ الْمَضَاجِعِ يَدْعُونَ رَبَّهُمْ خَوْفًا وَطَمَعًا وَمِمَّا رَزَقْنَاهُمْ يُنْفِقُونَ﴾\n[سورة السجدة: 16]',
      reward: 'مدح الله تعالى المستغفرين والقائمين بالليل ووعدهم بما تقر به الأعين.',
    ),
    QiyamItem(
      category: 'virtue',
      title: 'أَفْضَلُ الصَّلَاةِ بَعْدَ الْفَرِيضَةِ',
      text:
          'قَالَ رَسُولُ اللَّهِ ﷺ:\n'
          '«أَفْضَلُ الصَّلَاةِ بَعْدَ الصَّلَاةِ الْمَكْتُوبَةِ صَلَاةُ اللَّيْلِ»\n[رواه مسلم]',
      reward: 'صلاة الليل هي أفضل النوافل والصلوات بعد الصلوات الخمس المفروضة.',
    ),
    QiyamItem(
      category: 'virtue',
      title: 'دَأْبُ الصَّالِحِينَ وَمَكْفَرَةُ السَّيِّئَاتِ',
      text:
          'قَالَ رَسُولُ اللَّهِ ﷺ:\n'
          '«عَلَيْكُمْ بِقِيَامِ اللَّيْلِ فَإِنَّهُ دَأْبُ الصَّالِحِينَ قَبْلَكُمْ، وَقُرْبَةٌ إِلَى رَبِّكُمْ، وَمَكْفَرَةٌ لِلسَّيِّئَاتِ، وَمَنْهَاةٌ عَنِ الْإِثْمِ»\n[رواه الترمذي]',
      reward: 'قيام الليل ينهى عن المعاصي ويكفّر الذنوب ويقرّب العبد إلى مولاه.',
    ),
    QiyamItem(
      category: 'virtue',
      title: 'التَّنَزُّلُ الإِلَهِيُّ فِي الثُّلُثِ الأَخِيرِ',
      text:
          'قَالَ رَسُولُ اللَّهِ ﷺ:\n'
          '«يَنْزِلُ رَبُّنَا تَبَارَكَ وَتَعَالَى كُلَّ لَيْلَةٍ إِلَى السَّمَاءِ الدُّنْيَا حِينَ يَبْقَى ثُلُثُ اللَّيْلِ الآخِرُ، فَيَقُولُ:\n'
          'مَنْ يَدْعُونِي فَأَسْتَجِيبَ لَهُ؟ مَنْ يَسْأَلُنِي فَأُعْطِيَهُ؟ مَنْ يَسْتَغْفِرُنِي فَأَغْفِرَ لَهُ؟»\n[متفق عليه]',
      reward: 'ساعة إجابة ورحمة ومغفرة يفتح الله فيها أبواب عطائه للسائلين.',
    ),

    // --- الأدعية والتهجد (Duas) ---
    QiyamItem(
      category: 'dua',
      title: 'دُعَاءُ اسْتِفْتَاحِ صَلَاةِ اللَّيْلِ (عَنِ ابْنِ عَبَّاسٍ)',
      text:
          'اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ نُورُ السَّمَاوَاتِ وَالأَرْضِ وَمَنْ فِيهِنَّ،\n'
          'وَلَكَ الْحَمْدُ أَنْتَ قَيِّمُ السَّمَاوَاتِ وَالأَرْضِ وَمَنْ فِيهِنَّ،\n'
          'وَلَكَ الْحَمْدُ أَنْتَ رَبُّ السَّمَاوَاتِ وَالأَرْضِ وَمَنْ فِيهِنَّ،\n'
          'أَنْتَ الْحَقُّ، وَوَعْدُكَ الْحَقُّ، وَقَوْلُكَ الْحَقُّ، وَلِقَاؤُكَ الْحَقُّ، وَالْجَنَّةُ حَقٌّ، وَالنَّارُ حَقٌّ، وَالنَّبِيُّونَ حَقٌّ، وَمُحَمَّدٌ ﷺ حَقٌّ، وَالسَّاعَةُ حَقٌّ،\n'
          'اللَّهُمَّ لَكَ أَسْلَمْتُ، وَبِكَ آمَنْتُ، وَعَلَيْكَ تَوَكَّلْتُ، وَإِلَيْكَ أَنَبْتُ، وَبِكَ خَاصَمْتُ، وَإِلَيْكَ حَاكَمْتُ،\n'
          'فَاغْفِرْ لِي مَا قَدَّمْتُ وَمَا أَخَّرْتُ، وَمَا أَسْرَرْتُ وَمَا أَعْلَنْتُ، أَنْتَ إِ لَهِي لَا إِلَهَ إِلَّا أَنْتَ.',
      reward: 'دعاء النبي ﷺ عند افتتاحه صلاة قيام الليل.',
      targetCount: 1,
    ),
    QiyamItem(
      category: 'dua',
      title: 'دُعَاءُ الْقُنُوتِ فِي صَلَاةِ الْوِتْرِ',
      text:
          'اللَّهُمَّ اهْدِنَا فِيمَنْ هَدَيْتَ، وَعَافِنَا فِيمَنْ عَافَيْتَ، وَتَوَلَّنَا فِيمَنْ تَوَلَّيْتَ، وَبَارِكْ لَنَا فِيمَا أَعْطَيْتَ، وَقِنَا وَاصْرِفْ عَنَّا شَرَّ مَا قَضَيْتَ، فَإِنَّكَ تَقْضِي وَلَا يُقْضَى عَلَيْكَ، إِنَّهُ لَا يَذِلُّ مَنْ وَالَيْتَ، وَلَا يَعِزُّ مَنْ عَادَيْتَ، تَبَارَكْتَ رَبَّنَا وَتَعَالَيْتَ.\n\n'
          'اللَّهُمَّ إِ نَّا نَسْتَعِينُكَ وَنَسْتَغْفِرُكَ وَنُثْنِي عَلَيْكَ الْخَيْرَ كُلَّهُ، وَنَشْكُرُكَ وَلَا نَكْفُرُكَ.',
      reward: 'دعاء القنوت المبارك في ركعة الوتر.',
      targetCount: 1,
    ),
    QiyamItem(
      category: 'dua',
      title: 'دُعَاءُ الثُّلُثِ الأَخِيرِ لِقَضَاءِ الْحَوَائِجِ',
      text:
          'اللَّهُمَّ يَا حَيُّ يَا قَيُّومُ، يَا ذَا الْجَلَالِ وَالْإِكْرَامِ، يَا مَنْ لا يَعْجِزُهُ شَيْءٌ فِي الأَرْضِ وَلا فِي السَّمَاءِ،\n'
          'أَسْأَلُكَ فِي هَذِهِ اللَّيْلَةِ الْمُبَارَكَةِ أَنْ تَغْفِرَ لِي ذُنُوبِي كُلَّهَا، دِقَّهَا وَجِلَّهَا، أَوَّلَهَا وَآخِرَهَا، عَلَانِيَتَهَا وَسِرَّهَا.\n\n'
          'اللَّهُمَّ اقْضِ حَاجَتِي، وَفَرِّجْ كَرْبِي، وَارْزُقْنِي مِنْ حَيْثُ لَا أَحْتَسِبُ، وَاجْعَلْ لِي مِنْ كُلِّ ضِيقٍ مَخْرَجًا وَمِنْ كُلِّ هَمٍّ فَرَجًا.',
      reward: 'دعاء جامع للرزق وقضاء الحوائج والفرج في الثلث الأخير.',
      targetCount: 1,
    ),

    // --- الاستغفار بالسحر (Istighfar) ---
    QiyamItem(
      category: 'istighfar',
      title: 'سَيِّدُ الاسْتِغْفَارِ',
      text:
          'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَىٰ عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.',
      reward: 'مَنْ قَالَهَا مُوقِنًا بِهَا فَمَاتَ مِنْ لَيْلَتِهِ دَخَلَ الْجَنَّةَ.',
      targetCount: 3,
    ),
    QiyamItem(
      category: 'istighfar',
      title: 'اسْتِغْفَارُ الأَسْحَارِ',
      text:
          'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ.',
      reward: '﴿وَبِالْأَسْحَارِ هُمْ يَسْتَغْفِرُونَ﴾ - غُفِرَتْ ذُنُوبُهُ وَإِنْ كَانَ فَرَّ مِنَ الزَّحْفِ.',
      targetCount: 100,
    ),
    QiyamItem(
      category: 'istighfar',
      title: 'التَّسْبِيحُ وَالتَّهْلِيلُ فِي اللَّيْلِ',
      text:
          'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
      reward: 'حُطَّتْ خَطَايَاهُ وَإِنْ كَانَتْ مِثْلَ زَبَدِ الْبَحْرِ.',
      targetCount: 100,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _counters = List<int>.filled(_allItems.length, 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _incrementCounter(int index, int maxTarget) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_counters[index] < maxTarget) {
        _counters[index]++;
      } else {
        _counters[index] = 0; // Reset
      }
    });
  }

  void _copyToClipboard(String title, String text) {
    Clipboard.setData(ClipboardData(text: "$title\n\n$text"));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ النص إلى الحافظة 📋'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareContent(String title, String text) {
    SharePlus.instance.share(
      ShareParams(
        text: '🌿 $title\n\n$text\n\n- من تطبيق رفيق المسلم',
        subject: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: Text(
            'قيام الليل والتهجد',
            style: GoogleFonts.arefRuqaa(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 2,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFFFD54F),
            indicatorWeight: 3,
            labelColor: const Color(0xFFFFD54F),
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.stars_rounded, size: 20), text: 'فضائل القيامات'),
              Tab(icon: Icon(Icons.menu_book_rounded, size: 20), text: 'أدعية التهجد'),
              Tab(icon: Icon(Icons.nightlight_round, size: 20), text: 'استغفار السحر'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildHeaderBanner(isDark),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildItemsList('virtue', isDark),
                  _buildItemsList('dua', isDark),
                  _buildItemsList('istighfar', isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF1E3C72), const Color(0xFF2A5298)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bedtime_rounded, color: Colors.amber, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '«شَرَفُ الْمُؤْمِنِ قِيَامُهُ بِاللَّيْلِ»',
                  style: GoogleFonts.arefRuqaa(
                    color: const Color(0xFFFFD54F),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الثلث الأخير من الليل وقت تنزيل الرحمات وإجابة الدعوات',
                  style: GoogleFonts.cairo(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(String category, bool isDark) {
    final filtered = _allItems
        .asMap()
        .entries
        .where((entry) => entry.value.category == category)
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, idx) {
        final originalIndex = filtered[idx].key;
        final item = filtered[idx].value;
        final count = _counters[originalIndex];
        final isCompleted = count >= item.targetCount;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: isDark ? 1 : 3,
          shadowColor: isDark ? Colors.black54 : Colors.teal.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isCompleted
                  ? Colors.amber.shade600
                  : (isDark ? const Color(0xFF334155) : Colors.teal.shade100),
              width: isCompleted ? 2 : 1,
            ),
          ),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFFFD54F) : Colors.teal.shade900,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      color: isDark ? Colors.white60 : Colors.teal.shade700,
                      onPressed: () => _copyToClipboard(item.title, item.text),
                      tooltip: 'نسخ',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded, size: 20),
                      color: isDark ? Colors.white60 : Colors.teal.shade700,
                      onPressed: () => _shareContent(item.title, item.text),
                      tooltip: 'مشاركة',
                    ),
                  ],
                ),
                const Divider(height: 16),
                const SizedBox(height: 8),
                QuranTextFormatter.buildFormattedQuranText(
                  item.text,
                  baseStyle: GoogleFonts.cairo(
                    fontSize: 16,
                    height: 1.8,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.95)
                        : Colors.black87,
                  ),
                  textAlign: TextAlign.start,
                  badgeColor: Colors.amber,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : Colors.teal.shade50.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.nights_stay_rounded,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.reward,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.teal.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.targetCount > 1) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCompleted
                            ? 'أتممت التكرار بحمد الله 🎉'
                            : 'التكرار المطلوب: ${item.targetCount}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.green : Colors.grey,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _incrementCounter(originalIndex, item.targetCount),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCompleted
                              ? Colors.green
                              : (isDark ? Colors.teal.shade700 : Colors.teal),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.touch_app_rounded,
                            size: 18, color: Colors.white),
                        label: Text(
                          '$count / ${item.targetCount}',
                          style: GoogleFonts.ibmPlexMono(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
