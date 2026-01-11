import '../models/dhikr_item.dart';

class DhikrSeed {
  final String text;
  final String reward;
  final int count;

  const DhikrSeed({
    required this.text,
    required this.reward,
    required this.count,
  });
}

const String _ayatKursiText =
    'آية الكرسي: الله لا إله إلا هو الحي القيوم لا تأخذه سنة ولا نوم له ما في السماوات وما في الأرض من ذا الذي يشفع عنده إلا بإذنه يعلم ما بين أيديهم وما خلفهم ولا يحيطون بشيء من علمه إلا بما شاء وسع كرسيه السماوات والأرض ولا يؤوده حفظهما وهو العلي العظيم';
const String _surahIkhlas =
    'قل هو الله أحد ۝ الله الصمد ۝ لم يلد ولم يولد ۝ ولم يكن له كفوا أحد';
const String _surahFalaq =
    'قل أعوذ برب الفلق ۝ من شر ما خلق ۝ ومن شر غاسق إذا وقب ۝ ومن شر النفاثات في العقد ۝ ومن شر حاسد إذا حسد';
const String _surahNas =
    'قل أعوذ برب الناس ۝ ملك الناس ۝ إله الناس ۝ من شر الوسواس الخناس ۝ الذي يوسوس في صدور الناس ۝ من الجنة والناس';

const String _morningInvocation =
    'أصبحنا وأصبح الملك لله والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير. رب أسألك خير ما في هذا اليوم وخير ما بعده، وأعوذ بك من شر ما في هذا اليوم وشر ما بعده، رب أعوذ بك من الكسل وسوء الكبر، رب أعوذ بك من عذاب في النار وعذاب في القبر.';
const String _eveningInvocation =
    'أمسينا وأمسى الملك لله والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير. رب أسألك خير ما في هذه الليلة وخير ما بعدها، وأعوذ بك من شر ما في هذه الليلة وشر ما بعدها، رب أعوذ بك من الكسل وسوء الكبر، رب أعوذ بك من عذاب في النار وعذاب في القبر.';
const String _morningLife =
    'اللهم بك أصبحنا وبك أمسينا وبك نحيا وبك نموت وإليك النشور.';
const String _eveningLife =
    'اللهم بك أمسينا وبك أصبحنا وبك نحيا وبك نموت وإليك المصير.';
const String _sayyidIstighfar =
    'اللهم أنت ربي لا إله إلا أنت، خلقتني وأنا عبدك، وأنا على عهدك ووعدك ما استطعت، أعوذ بك من شر ما صنعت، أبوء لك بنعمتك علي، وأبوء بذنبي، فاغفر لي فإنه لا يغفر الذنوب إلا أنت.';
const String _morningBlessing =
    'اللهم ما أصبح بي من نعمة أو بأحد من خلقك فمنك وحدك لا شريك لك، فلك الحمد ولك الشكر.';
const String _eveningBlessing =
    'اللهم ما أمسى بي من نعمة أو بأحد من خلقك فمنك وحدك لا شريك لك، فلك الحمد ولك الشكر.';
const String _ridhaText =
    'رضيت بالله ربا وبالإسلام دينا وبمحمد صلى الله عليه وسلم نبيا.';
const String _afwAafiyahText =
    'اللهم إني أسألك العفو والعافية في الدنيا والآخرة، اللهم إني أسألك العفو والعافية في ديني ودنياي وأهلي ومالي، اللهم استر عوراتي وآمن روعاتي، اللهم احفظني من بين يدي ومن خلفي وعن يميني وعن شمالي ومن فوقي، وأعوذ بعظمتك أن أغتال من تحتي.';
const String _aafiniText =
    'اللهم عافني في بدني، اللهم عافني في سمعي، اللهم عافني في بصري، لا إله إلا أنت.';
const String _kufrFaqrText =
    'اللهم إني أعوذ بك من الكفر والفقر، وأعوذ بك من عذاب القبر، لا إله إلا أنت.';
const String _hisbiAllahText =
    'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم.';
const String _bismillahText =
    'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم.';
const String _ilmNafiText =
    'اللهم إني أسألك علما نافعا ورزقا طيبا وعملا متقبلا.';
const String _yaHayyText =
    'يا حي يا قيوم برحمتك أستغيث أصلح لي شأني كله ولا تكلني إلى نفسي طرفة عين.';
const String _fitrahMorning =
    'أصبحنا على فطرة الإسلام وعلى كلمة الإخلاص وعلى دين نبينا محمد صلى الله عليه وسلم وعلى ملة أبينا إبراهيم حنيفا مسلما وما كان من المشركين.';
const String _fitrahEvening =
    'أمسينا على فطرة الإسلام وعلى كلمة الإخلاص وعلى دين نبينا محمد صلى الله عليه وسلم وعلى ملة أبينا إبراهيم حنيفا مسلما وما كان من المشركين.';
const String _tahlilText =
    'لا إله إلا الله وحده لا شريك له له الملك وله الحمد وهو على كل شيء قدير.';
const String _subhanAllahText = 'سبحان الله وبحمده.';
const String _subhanAllah3Text =
    'سبحان الله وبحمده عدد خلقه ورضا نفسه وزنة عرشه ومداد كلماته.';
const String _aoodhuKalimahText = 'أعوذ بكلمات الله التامات من شر ما خلق.';
const String _salawatText = 'اللهم صل وسلم على نبينا محمد.';
const String _faterText =
    'اللهم فاطر السماوات والأرض، عالم الغيب والشهادة، رب كل شيء ومليكه، أشهد أن لا إله إلا أنت، أعوذ بك من شر نفسي ومن شر الشيطان وشركه، وأن أقترف على نفسي سوءا أو أجره إلى مسلم.';

const DhikrSeed _ridhaSeed = DhikrSeed(
  text: _ridhaText,
  reward: 'حقا على الله أن يرضيه',
  count: 3,
);
const DhikrSeed _hisbiAllahSeed = DhikrSeed(
  text: _hisbiAllahText,
  reward: 'كفاية الهم والبلاء',
  count: 7,
);
const DhikrSeed _bismillahSeed = DhikrSeed(
  text: _bismillahText,
  reward: 'حفظ من كل سوء',
  count: 3,
);
const DhikrSeed _subhanAllahSeed = DhikrSeed(
  text: _subhanAllahText,
  reward: 'غفران الذنوب وإن كانت مثل زبد البحر',
  count: 100,
);
const DhikrSeed _salawatSeed = DhikrSeed(
  text: _salawatText,
  reward: 'الصلاة والسلام على النبي',
  count: 10,
);

const List<DhikrSeed> _morningSeeds = [
  DhikrSeed(
    text: _ayatKursiText,
    reward: 'حفظ ورعاية حتى تمسي',
    count: 1,
  ),
  DhikrSeed(
    text: _surahIkhlas,
    reward: 'المعوذات (سورة الإخلاص)',
    count: 3,
  ),
  DhikrSeed(
    text: _surahFalaq,
    reward: 'المعوذات (سورة الفلق)',
    count: 3,
  ),
  DhikrSeed(
    text: _surahNas,
    reward: 'المعوذات (سورة الناس)',
    count: 3,
  ),
  DhikrSeed(
    text: _morningInvocation,
    reward: 'ذكر وتوحيد وبركة اليوم',
    count: 1,
  ),
  DhikrSeed(
    text: _morningLife,
    reward: 'تفويض الأمر لله',
    count: 1,
  ),
  DhikrSeed(
    text: _sayyidIstighfar,
    reward: 'غفران الذنوب إن مت في يومك',
    count: 1,
  ),
  DhikrSeed(
    text: _morningBlessing,
    reward: 'شكر النعمة وتجديدها',
    count: 1,
  ),
  _ridhaSeed,
  DhikrSeed(
    text: _afwAafiyahText,
    reward: 'دعاء جامع للعفو والعافية والحفظ',
    count: 1,
  ),
  DhikrSeed(
    text: _aafiniText,
    reward: 'سؤال العافية في البدن والسمع والبصر',
    count: 3,
  ),
  DhikrSeed(
    text: _kufrFaqrText,
    reward: 'استعاذة من الكفر والفقر وعذاب القبر',
    count: 3,
  ),
  _bismillahSeed,
  _hisbiAllahSeed,
  DhikrSeed(
    text: _ilmNafiText,
    reward: 'سؤال العلم النافع والرزق الطيب والعمل المتقبل',
    count: 1,
  ),
  DhikrSeed(
    text: _yaHayyText,
    reward: 'استغاثة بالله لإصلاح الحال والثبات',
    count: 1,
  ),
  DhikrSeed(
    text: _fitrahMorning,
    reward: 'تجديد العهد على التوحيد والفطرة',
    count: 1,
  ),
  DhikrSeed(
    text: _faterText,
    reward: 'تفويض الأمر لله والاستعاذة من النفس والشيطان',
    count: 1,
  ),
  DhikrSeed(
    text: _tahlilText,
    reward: 'توحيد وتجديد الإيمان وذكر عظيم',
    count: 100,
  ),
  _subhanAllahSeed,
  DhikrSeed(
    text: _subhanAllah3Text,
    reward: 'تسبيح وتعظيم لله بألفاظ جامعة',
    count: 3,
  ),
  DhikrSeed(
    text: _aoodhuKalimahText,
    reward: 'تحصين واستعاذة من كل شر',
    count: 3,
  ),
  _salawatSeed,
];

const List<DhikrSeed> _eveningSeeds = [
  DhikrSeed(
    text: _ayatKursiText,
    reward: 'حفظ ورعاية حتى تصبح',
    count: 1,
  ),
  DhikrSeed(
    text: _surahIkhlas,
    reward: 'المعوذات (سورة الإخلاص)',
    count: 3,
  ),
  DhikrSeed(
    text: _surahFalaq,
    reward: 'المعوذات (سورة الفلق)',
    count: 3,
  ),
  DhikrSeed(
    text: _surahNas,
    reward: 'المعوذات (سورة الناس)',
    count: 3,
  ),
  DhikrSeed(
    text: _eveningInvocation,
    reward: 'ذكر وتوحيد وبركة الليل',
    count: 1,
  ),
  DhikrSeed(
    text: _eveningLife,
    reward: 'تفويض الأمر لله',
    count: 1,
  ),
  DhikrSeed(
    text: _sayyidIstighfar,
    reward: 'غفران الذنوب إن مت في ليلتك',
    count: 1,
  ),
  DhikrSeed(
    text: _eveningBlessing,
    reward: 'شكر النعمة وتجديدها',
    count: 1,
  ),
  _ridhaSeed,
  DhikrSeed(
    text: _afwAafiyahText,
    reward: 'دعاء جامع للعفو والعافية والحفظ',
    count: 1,
  ),
  DhikrSeed(
    text: _aafiniText,
    reward: 'سؤال العافية في البدن والسمع والبصر',
    count: 3,
  ),
  DhikrSeed(
    text: _kufrFaqrText,
    reward: 'استعاذة من الكفر والفقر وعذاب القبر',
    count: 3,
  ),
  _bismillahSeed,
  _hisbiAllahSeed,
  DhikrSeed(
    text: _yaHayyText,
    reward: 'استغاثة بالله لإصلاح الحال والثبات',
    count: 1,
  ),
  DhikrSeed(
    text: _fitrahEvening,
    reward: 'تجديد العهد على التوحيد والفطرة',
    count: 1,
  ),
  DhikrSeed(
    text: _faterText,
    reward: 'تفويض الأمر لله والاستعاذة من النفس والشيطان',
    count: 1,
  ),
  DhikrSeed(
    text: _tahlilText,
    reward: 'توحيد وتجديد الإيمان وذكر عظيم',
    count: 100,
  ),
  _subhanAllahSeed,
  DhikrSeed(
    text: _subhanAllah3Text,
    reward: 'تسبيح وتعظيم لله بألفاظ جامعة',
    count: 3,
  ),
  DhikrSeed(
    text: _aoodhuKalimahText,
    reward: 'تحصين واستعاذة من كل شر',
    count: 3,
  ),
  _salawatSeed,
];

List<DhikrItem> buildMorningAthkar() => _buildAthkar(_morningSeeds);
List<DhikrItem> buildEveningAthkar() => _buildAthkar(_eveningSeeds);

List<DhikrItem> _buildAthkar(List<DhikrSeed> seeds) {
  return seeds
      .map((seed) =>
          DhikrItem(text: seed.text, reward: seed.reward, count: seed.count))
      .toList(growable: false);
}
