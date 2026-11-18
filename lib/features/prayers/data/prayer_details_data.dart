import '../../athkar/models/dhikr_item.dart';
import '../../../core/constants/app_constants.dart';

class PrayerInfo {
  final String name;
  final String title;
  final int rakaat;
  final String type; // جهرية / سرية
  final String sunnahBefore;
  final String sunnahAfter;
  final String description;
  final List<String> virtues;
  final List<DhikrItem> afterPrayerAthkar;

  const PrayerInfo({
    required this.name,
    required this.title,
    required this.rakaat,
    required this.type,
    required this.sunnahBefore,
    required this.sunnahAfter,
    required this.description,
    required this.virtues,
    required this.afterPrayerAthkar,
  });
}

class PrayerDetailsRepository {
  static PrayerInfo getPrayerInfo(String prayerName) {
    if (prayerName.contains(kPrayerFajr) || prayerName.contains('الفجر')) {
      return _fajrInfo;
    } else if (prayerName.contains(kPrayerDhuhr) || prayerName.contains('الظهر')) {
      return _dhuhrInfo;
    } else if (prayerName.contains(kPrayerAsr) || prayerName.contains('العصر')) {
      return _asrInfo;
    } else if (prayerName.contains(kPrayerMaghrib) || prayerName.contains('المغرب')) {
      return _maghribInfo;
    } else if (prayerName.contains(kPrayerIsha) || prayerName.contains('العشاء')) {
      return _ishaInfo;
    }
    return _fajrInfo;
  }

  // Common Athkar seeds
  static List<DhikrItem> _getCommonAfterPrayerAthkar({required bool isFajrOrMaghrib}) {
    return [
      DhikrItem(
        text: 'أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ.\nاللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ.',
        reward: 'سنة مأثورة عقب السلام مباشرة من الصلاة المفروضة',
        count: 1,
      ),
      DhikrItem(
        text: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ.',
        reward: 'التوحيد والثناء بعد كل صلاة مكتوبة',
        count: 1,
      ),
      DhikrItem(
        text: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ، لَا إِلَهَ إِلَّا اللَّهُ، وَلَا نَعْبُدُ إِلَّا إِيَّاهُ، لَهُ النِّعْمَةُ وَلَهُ الْفَضْلُ وَلَهُ الثَّنَاءُ الْحَسَنُ، لَا إِلَهَ إِلَّا اللَّهُ مُخْلِصِينَ لَهُ الدِّينَ وَلَوْ كَرِهَ الْكَافِرُونَ.',
        reward: 'من أذكار النبي ﷺ دبر كل صلاة',
        count: 1,
      ),
      DhikrItem(
        text: 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ.',
        reward: 'وصية النبي ﷺ لمعاذ بن جبل ألا يدعها دبر كل صلاة',
        count: 1,
      ),
      DhikrItem(
        text: 'سُبْحَانَ اللَّهِ',
        reward: 'التسبيح دبر كل صلاة (33 مرة)',
        count: 33,
      ),
      DhikrItem(
        text: 'الْحَمْدُ لِلَّهِ',
        reward: 'التحميد دبر كل صلاة (33 مرة)',
        count: 33,
      ),
      DhikrItem(
        text: 'اللَّهُ أَكْبَرُ',
        reward: 'التكبير دبر كل صلاة (33 مرة)',
        count: 33,
      ),
      DhikrItem(
        text: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
        reward: 'تمام المائة - غُفرت خطاياه وإن كانت مثل زبد البحر',
        count: 1,
      ),
      DhikrItem(
        text: 'آيَةُ الْكُرْسِيِّ:\n«اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ»',
        reward: 'من قرأها دبر كل صلاة لم يمنعه من دخول الجنة إلا الموت',
        count: 1,
      ),
      DhikrItem(
        text: 'المعوذات:\nسورة الإخلاص، وسورة الفلق، وسورة الناس',
        reward: isFajrOrMaghrib ? 'تُكرر 3 مرات بعد الفجر والمغرب' : 'تُقرأ مرة واحدة دبر الصلاة',
        count: isFajrOrMaghrib ? 3 : 1,
      ),
      if (isFajrOrMaghrib)
        DhikrItem(
          text: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ يُحْيِي وَيُمِيتُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
          reward: 'تُقال 10 مرات بعد الفجر والمغرب قبل ثني الرجلين (حرز من كل مكروه)',
          count: 10,
        ),
      if (isFajrOrMaghrib)
        DhikrItem(
          text: 'اللَّهُمَّ أَجِرْنِي مِنَ النَّارِ.',
          reward: 'تُقال 7 مرات بعد صلاتي الفجر والمغرب',
          count: 7,
        ),
    ];
  }

  static final _fajrInfo = PrayerInfo(
    name: kPrayerFajr,
    title: 'الفجر',
    rakaat: 2,
    type: 'جهرية',
    sunnahBefore: 'ركعتان قبلية مؤكدة (سنة الفجر)',
    sunnahAfter: 'لا توجد سنة بعدية',
    description: 'صلاة الفجر هي أولى الصلوات الخمس في اليوم، وتشهدها ملائكة الليل وملائكة النهار، وهي برهان الصدق والعهد مع الله.',
    virtues: [
      'قال رسول الله ﷺ: «مَنْ صَلَّى الْبَرَدَيْنِ دَخَلَ الْجَنَّةَ» (متفق عليه - البردان هما الفجر والعصر).',
      'قال النبي ﷺ: «مَنْ صَلَّى الصُّبْحَ فَهُوَ فِي ذِمَّةِ اللَّهِ» (رواه مسلم).',
      'قال ﷺ: «رَكْعَتَا الْفَجْرِ خَيْرٌ مِنَ الدُّنْيَا وَمَا فِيهَا» (رواه مسلم).',
      'قال تعالى: ﴿إِنَّ قُرْآنَ الْفَجْرِ كَانَ مَشْهُودًا﴾ [الإسراء: 78].',
    ],
    afterPrayerAthkar: [
      ..._getCommonAfterPrayerAthkar(isFajrOrMaghrib: true),
      DhikrItem(
        text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا.',
        reward: 'دعاء النبي ﷺ عند السلام من صلاة الصبح',
        count: 1,
      ),
    ],
  );

  static final _dhuhrInfo = PrayerInfo(
    name: kPrayerDhuhr,
    title: 'الظهر',
    rakaat: 4,
    type: 'سرية',
    sunnahBefore: '4 ركعات قبلية (بتسليمتين) مؤكدة',
    sunnahAfter: '2 ركعة بعدية مؤكدة (ويُستحب 4 ركعات)',
    description: 'صلاة الظهر تؤدى عند زوال الشمس، وهي وقت تُفتح فيه أبواب السماء ويستجاب فيه الدعاء.',
    virtues: [
      'قال رسول الله ﷺ: «مَنْ حَافَظَ عَلَى أَرْبَعِ رَكَعَاتٍ قَبْلَ الظُّهْرِ وَأَرْبَعٍ بَعْدَهَا حَرَّمَهُ اللَّهُ عَلَى النَّارِ» (رواه الترمذي).',
      'عن عبد الله بن السائب أن رسول الله ﷺ كان يصلي أربعاً بعد أن تزول الشمس قبل الظهر وقال: «إِنَّهَا سَاعَةٌ تُفْتَحُ فِيهَا أَبْوَابُ السَّمَاءِ وَأُحِبُّ أَنْ يَصْعَدَ لِي فِيهَا عَمَلٌ صَالِحٌ».',
    ],
    afterPrayerAthkar: _getCommonAfterPrayerAthkar(isFajrOrMaghrib: false),
  );

  static final _asrInfo = PrayerInfo(
    name: kPrayerAsr,
    title: 'العصر',
    rakaat: 4,
    type: 'سرية',
    sunnahBefore: '4 ركعات قبلية مستحبة (غير مؤكدة)',
    sunnahAfter: 'لا توجد سنة بعدية',
    description: 'صلاة العصر هي الصلاة الوسطى التي أكد القرآن على حفظها، وتفويتها سبب لحبوط العمل.',
    virtues: [
      'قال تعالى: ﴿حَافِظُوا عَلَى الصَّلَوَاتِ وَالصَّلَاةِ الْوُسْطَىٰ وَقُومُوا لِلَّهِ قَانِتِينَ﴾ [البقرة: 238].',
      'قال رسول الله ﷺ: «مَنْ تَرَكَ صَلَاةَ الْعَصْرِ فَقَدْ حَبِطَ عَمَلُهُ» (رواه البخاري).',
      'قال ﷺ: «رَحِمَ اللَّهُ امْرَأً صَلَّى قَبْلَ الْعَصْرِ أَرْبَعًا» (رواه الترمذي وأبو داود).',
      'قال ﷺ: «الَّذِي تَفُوتُهُ صَلَاةُ الْعَصْرِ كَأَنَّمَا وُتِرَ أَهْلَهُ وَمَالَهُ» (متفق عليه).',
    ],
    afterPrayerAthkar: _getCommonAfterPrayerAthkar(isFajrOrMaghrib: false),
  );

  static final _maghribInfo = PrayerInfo(
    name: kPrayerMaghrib,
    title: 'المغرب',
    rakaat: 3,
    type: 'جهرية / سرية',
    sunnahBefore: 'ركعتان خفيفتان بين الأذان والإقامة (مستحبة)',
    sunnahAfter: '2 ركعة بعدية مؤكدة',
    description: 'صلاة المغرب هي وتر النهار وتؤدى فور غروب الشمس، وهي بداية ليل جديد يملؤه الذكر والطاعة.',
    virtues: [
      'صلاة المغرب هي وتر النهار، وكان النبي ﷺ لا يدع ركعتين بعد المغرب.',
      'عن النبي ﷺ قال: «صَلُّوا قَبْلَ صَلَاةِ الْمَغْرِبِ... لِمَنْ شَاءَ» (رواه البخاري).',
      'تُستحب المسارعة بأدائها في أول وقتها عقب غروب الشمس مباشرة.',
    ],
    afterPrayerAthkar: _getCommonAfterPrayerAthkar(isFajrOrMaghrib: true),
  );

  static final _ishaInfo = PrayerInfo(
    name: kPrayerIsha,
    title: 'العشاء',
    rakaat: 4,
    type: 'جهرية / سرية',
    sunnahBefore: 'ركعتان بين الأذان والإقامة (مستحبة)',
    sunnahAfter: '2 ركعة بعدية مؤكدة (ثم صلاة الشفع والوتر)',
    description: 'صلاة العشاء هي ختام الصلوات المفروضة باليوم، وفي شهودها بالجميع أجر قيام نصف الليل.',
    virtues: [
      'قال رسول الله ﷺ: «مَنْ صَلَّى الْعِشَاءَ فِي جَمَاعَةٍ فَكَأَنَّمَا قَامَ نِصْفَ اللَّيْلِ» (رواه مسلم).',
      'قال النبي ﷺ: «وَلَوْ يَعْلَمُونَ مَا فِي الْعَتَمَةِ وَالصُّبْحِ لَأَتَوْهُمَا وَلَوْ حَبْوًا» (متفق عليه).',
      'يُسن أداء صلاة الوتر بعد العشاء وسنتها البعدية لتكون آخر صلاة الليل وتراً.',
    ],
    afterPrayerAthkar: _getCommonAfterPrayerAthkar(isFajrOrMaghrib: false),
  );
}
