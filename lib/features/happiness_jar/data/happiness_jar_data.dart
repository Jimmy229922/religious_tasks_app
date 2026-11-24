import 'dart:math';

enum HappinessCategory {
  all('الكل', '✨'),
  hope('بشائر وأمل', '🌅'),
  calm('طمأنينة وسكينة', '🕊️'),
  gratitude('شكر وامتنان', '🌿'),
  love('لطف وجبر خاطر', '💛'),
  dua('دعوات مبهجة', '🤲');

  final String label;
  final String emoji;
  const HappinessCategory(this.label, this.emoji);
}

class HappinessMessage {
  final String id;
  final String title;
  final String body;
  final String? reflection;
  final HappinessCategory category;

  const HappinessMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.reflection,
  });

  static final RegExp _diacriticsRegex = RegExp(r'[\u064B-\u065F\u0670]');

  static int visualLength(String text) =>
      text.replaceAll(_diacriticsRegex, '').length;

  /// Complete, non-truncated short sentence for Android's collapsed notification
  /// preview so it always displays in full without trailing "..." ellipsis.
  String get notificationPreview {
    final cleaned = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (visualLength(cleaned) <= 38) return cleaned;

    for (final sep in const ['..', '؛', '.']) {
      final idx = cleaned.indexOf(sep);
      if (idx >= 12) {
        final candidate = cleaned.substring(0, idx).trim();
        if (visualLength(candidate) <= 38) {
          return candidate;
        }
      }
    }

    final refl = reflection?.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (refl != null && refl.isNotEmpty && visualLength(refl) <= 38) {
      return refl;
    }

    return title;
  }
}

class HappinessJarData {
  static final Random _random = Random();

  static const List<HappinessMessage> messages = [
    HappinessMessage(
      id: 's1',
      title: 'القادم أجمل بإذن الله',
      body: 'وعسى القادم كله خير، وعسى أن يهبنا الله أعظم مما حلمنا به. 💛',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's2',
      title: 'لا تستصغر خطوتك',
      body: 'لا تستصغر أي خطوة تخطوها اليوم، فقد تكون سببًا في وصولك لحلم كبير غدًا.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's3',
      title: 'دعاء للأيام الجميلة',
      body: 'اللهم أيامًا لا نُجبر فيها على الصبر، وأحلامًا تأتي كما تمنينا وأجمل.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 's4',
      title: 'تذكّر نعم الله',
      body: 'لا تجعل انشغالك بما ينقصك ينسيك النعم الكثيرة التي تملكها.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 's5',
      title: 'هدايا غير متوقعة',
      body: 'أحيانًا تكون أجمل الهدايا هي الأشياء التي لم نكن نتوقعها.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's6',
      title: 'الأثر الطيب يبقى',
      body: 'كن شخصًا يترك أثرًا طيبًا أينما ذهب، فالحياة قصيرة والأثر يبقى.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 's7',
      title: 'قوة الاستمرار',
      body: 'لا تقس نجاحك بسرعة وصولك، بل بقدرتك على الاستمرار رغم الصعوبات.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's8',
      title: 'دعوات الأمس واقع',
      body: 'عسى أن نصل إلى يوم نرى فيه دعوات الأمس واقعًا نعيشه اليوم.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's9',
      title: 'لا تؤجل المعروف',
      body: 'لا تؤجل كلمة حلوة، ولا معروفًا تستطيع تقديمه، ولا فرحة تستطيع مشاركتها.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 's10',
      title: 'بدايات صغيرة عظيمة',
      body: 'تذكّر أن البدايات الصغيرة قد تصنع نهايات عظيمة.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's11',
      title: 'دعاء الاختيار والبال',
      body: 'اللهم ارزقنا حُسن الاختيار، وجمال الأقدار، وراحة البال.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 's12',
      title: 'لا تخف من المحاولة',
      body: 'لا تسمح لفشل تجربة واحدة أن يجعلك تخاف من خوض تجارب جديدة.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's13',
      title: 'أبواب تُفتح فجأة',
      body: 'أجمل ما في الحياة أن الأبواب قد تُفتح في اللحظة التي نظن فيها أن كل الطرق انتهت.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's14',
      title: 'امتنان للأحبة',
      body: 'كن ممتنًا للأشخاص الذين يجعلون الحياة أخف على قلبك.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 's15',
      title: 'ابدأ بما تملك',
      body: 'لا تنتظر أن تصبح الظروف مثالية حتى تبدأ، ابدأ بما تملك.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's16',
      title: 'أخبار تملأ القلب سعادة',
      body: 'عسى أن نُفاجأ بأخبار تملأ قلوبنا سعادة وتنسينا طول الانتظار.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's17',
      title: 'يكفي صدق المحاولة',
      body: 'ليس عليك أن تكون الأفضل في كل شيء، يكفي أن تكون صادقًا في محاولاتك.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's18',
      title: 'استمتع بالرحلة',
      body: 'تعلّم أن تستمتع برحلتك، فليس كل الجمال في الوصول.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's19',
      title: 'دعاء الخير في الأمنيات',
      body: 'اللهم لا تجعل لنا أمنية إلا وكتبت لنا فيها الخير.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 's20',
      title: 'راحة نفسك أولًا',
      body: 'لا تستهلك عمرك في محاولة إرضاء الجميع، فأنت لست مسؤولًا عن كل انطباع يتركه الآخرون.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's21',
      title: 'نصيب من الهدوء',
      body: 'اجعل لك نصيبًا من الهدوء بعيدًا عن ضجيج العالم.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's22',
      title: 'لا تتوقف عن المحاولة',
      body: 'لا تتوقف عن المحاولة لمجرد أن النتائج تأخرت.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's23',
      title: 'ذكريات تستحق الحفظ',
      body: 'عسى أن تكون الأيام المقبلة مليئة باللحظات التي تستحق أن نحفظها في ذاكرتنا.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's24',
      title: 'الحكاية لم تنتهِ',
      body: 'لا تحكم على حياتك من فصل واحد، فالحكاية لم تنتهِ بعد.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's25',
      title: 'ازرع خيرًا',
      body: 'ازرع خيرًا في حياة الناس، فربما يأتيك يوم تحتاج فيه إلى ثمرة ما زرعت.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 's26',
      title: 'ثروات لا تُقدّر بثمن',
      body: 'لا تنسَ أن صحتك ووقتك وراحة بالك ثروات لا تُقدّر بثمن.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 's27',
      title: 'دعاء الفرحة الدائمة',
      body: 'اللهم ارزقنا فرحة لا يعقبها حزن، ونعمة لا تزول.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 's28',
      title: 'تعلّم من الماضي',
      body: 'لا تجعل الماضي مكانًا تسكن فيه، اجعله درسًا تتعلم منه.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's29',
      title: 'أجمل استثمار',
      body: 'أجمل استثمار هو أن تطوّر عقلك، وتهذّب أخلاقك، وتعتني بنفسك.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 's30',
      title: 'فرصة أخرى لنفسك',
      body: 'امنح نفسك فرصة أخرى، فربما تكون المحاولة القادمة هي التي ستغيّر كل شيء.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's31',
      title: 'لا تنتظر التقدير',
      body: 'لا تنتظر التقدير من الجميع، فليس كل الناس يرون الأشياء بالطريقة نفسها.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's32',
      title: 'لحظات الجبر القريبة',
      body: 'وعسى أن تأتي لحظات الجبر من حيث لا نحتسب.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's33',
      title: 'لا تندم على طيبتك',
      body: 'لا تندم على طيبتك، فقط تعلّم لمن تمنحها.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 's34',
      title: 'ابحث عن السعادة',
      body: 'الحياة لا تتطلب أن تكون سعيدًا طوال الوقت، لكنها تستحق أن تبحث فيها عن أسباب السعادة.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's35',
      title: 'اكتشف شغفك',
      body: 'اترك لنفسك مساحة لتجربة أشياء جديدة، فقد تجد شغفك في مكان لم تتوقعه.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's36',
      title: 'دعاء التوفيق والبركة',
      body: 'اللهم اجعل لنا في كل خطوة توفيقًا، وفي كل اختيار بركة.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 's37',
      title: 'قيمتك ليست برأي أحد',
      body: 'لا تجعل رأي شخص واحد يحدد قيمتك.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's38',
      title: 'اسعَ لأحلامك بصبر',
      body: 'من الجميل أن تكون لديك أحلام كبيرة، والأجمل أن تسعى إليها بصبر.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's39',
      title: 'اصنع فرحتك بنفسك',
      body: 'لا تنتظر من الحياة أن تعطيك كل شيء، تعلّم كيف تصنع بعض الأشياء بنفسك.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's40',
      title: 'اختر السلام الداخلي',
      body: 'اختر السلام الداخلي، حتى لو اضطررت إلى الابتعاد عن بعض الضوضاء.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's41',
      title: 'لا تفقد الأمل أبدًا',
      body: 'قد يتغير كل شيء في يوم واحد، فلا تفقد الأمل أبدًا.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's42',
      title: 'شكر الداعمين',
      body: 'لا تنسَ أن تشكر من وقف بجانبك في الأيام التي لم يكن فيها شيء سهلًا.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 's43',
      title: 'دعاء الفرح والحمد',
      body: 'اللهم ارزقنا أيامًا نضحك فيها من قلوبنا، ونحمدك فيها على جميل عطائك.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 's44',
      title: 'اكتسب الخبرة',
      body: 'لا تجعل الخوف من الخطأ يمنعك من اكتساب الخبرة.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's45',
      title: 'اكتشف الحياة',
      body: 'تعلّم مهارة جديدة، اقرأ كتابًا، جرّب شيئًا مختلفًا؛ لا تتوقف عن اكتشاف الحياة.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's46',
      title: 'بعض الخسارات حماية',
      body: 'ليس كل ما تفقده يستحق الحزن، فبعض الخسارات حماية لا ندركها إلا لاحقًا.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's47',
      title: 'حكمة الاختيار',
      body: 'كن كريمًا في مشاعرك، لكن حكيمًا في اختياراتك.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 's48',
      title: 'بداية أجمل فصل',
      body: 'عسى أن يكون القادم بداية لأجمل فصل في حكايتنا.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's49',
      title: 'احتفل بإنجازك',
      body: 'لا تنتظر أن يصفق لك أحد، احتفل بنفسك وبكل إنجاز تحققه.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 's50',
      title: 'تستحق الصبر والاجتهاد',
      body: 'تذكّر أن الإنسان الذي تسعى لتصبحه يستحق منك الصبر والاجتهاد.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's51',
      title: 'لا تقارن حياتك',
      body: 'لا تُقارن كواليس حياتك بصور الآخرين الجميلة.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's52',
      title: 'دعاء الطمأنينة والرضا',
      body: 'اللهم ارزقنا قلوبًا مطمئنة، وأرواحًا راضية، وأقدارًا سعيدة.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 's53',
      title: 'حكمة الصمت والكلام',
      body: 'من الحكمة أن تعرف متى تتحدث، ومتى تصمت، ومتى ترحل.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's54',
      title: 'لا تضيّع يومك',
      body: 'لا تجعل يومك كله يضيع بسبب موقف لم يستغرق سوى دقائق.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's55',
      title: 'علاقتك بنفسك',
      body: 'اهتم بعلاقتك بنفسك، فهي العلاقة التي سترافقك طوال العمر.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 's56',
      title: 'توقف لتستعيد قوتك',
      body: 'أحيانًا تحتاج أن تتوقف قليلًا، لا لتستسلم، بل لتستعيد قوتك.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's57',
      title: 'تقدير النعم يحفظها',
      body: 'لا تتعامل مع النعم على أنها أمور مضمونة، فالتقدير يحفظ جمال الأشياء.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 's58',
      title: 'رزق فوق التوقعات',
      body: 'عسى أن نُرزق فوق ما طلبنا، وأن نُسعد فوق ما توقعنا.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's59',
      title: 'أشياء لا تُشترى',
      body: 'لا تجعل المال مقياسًا وحيدًا للنجاح، فهناك أشياء لا تُشترى.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's60',
      title: 'اختر كلماتك بعناية',
      body: 'اختر كلماتك بعناية، فقد تنسى ما قلته، لكن غيرك قد يتذكر أثره طويلًا.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 's61',
      title: 'البدء بخبرة سابقة',
      body: 'لا تخجل من أن تبدأ من الصفر، فالخبرة التي اكتسبتها لن تبدأ معك من الصفر.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's62',
      title: 'هدف وخطوات ثابتة',
      body: 'اجعل لك هدفًا واضحًا، وخطة واقعية، وخطوات ثابتة.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's63',
      title: 'دعاء البركة في العمر',
      body: 'اللهم بارك لنا في أعمارنا وأرزاقنا وأهلنا وأحبابنا.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 's64',
      title: 'قوة الكلمة الطيبة',
      body: 'لا تستهين بقوة الكلمة الطيبة، فقد تغيّر يوم إنسان بالكامل.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 's65',
      title: 'حكمة التأخير',
      body: 'ليس كل تأخير حرمانًا، وليس كل ما نريده خيرًا لنا.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's66',
      title: 'شغف التعلّم',
      body: 'حافظ على فضولك تجاه الحياة، فما زال هناك الكثير لتتعلمه وتراه.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's67',
      title: 'راحة قلبك',
      body: 'لا تُحمّل قلبك مسؤولية أشياء لم تكن يومًا تحت سيطرتك.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's68',
      title: 'أيام تشبه أحلامنا',
      body: 'عسى أن نعيش أيامًا تشبه أحلامنا، وتفوق توقعاتنا.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's69',
      title: 'استعد للفرصة',
      body: 'لا تنتظر الفرصة المناسبة فقط، بل اعمل على أن تكون مستعدًا لها.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's70',
      title: 'افرح بإنجازك',
      body: 'لا تنسَ أن تستمتع بإنجازاتك بدلًا من الانتقال مباشرة إلى الهدف التالي.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 's71',
      title: 'طمأنينة القرب من الله',
      body: 'اجعل علاقتك بالله أولويتك، فالقرب منه طمأنينة لا تشبهها طمأنينة.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's72',
      title: 'ثبات الأخلاق',
      body: 'لا ترد الإساءة بمثلها، احتفظ بأخلاقك مهما اختلفت أخلاق الآخرين.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 's73',
      title: 'قلب نقي',
      body: 'الحياة أجمل حين نعيشها بقلوب لا تحمل الحقد ولا تنتظر الانتقام.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 's74',
      title: 'ابدأ الآن',
      body: 'لا تترك أحلامك حبيسة التأجيل، فالوقت الذي تملكه اليوم لن يعود.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's75',
      title: 'دعاء للقادم',
      body: 'اللهم اجعل القادم من أعمارنا أجمل، وأوسع رزقًا، وأكثر طمأنينة.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 's76',
      title: 'فن الاستماع',
      body: 'كن مستمعًا جيدًا، فليس كل من يتحدث يحتاج إلى نصيحة، بعضهم يحتاج فقط إلى من يسمعه.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 's77',
      title: 'لا تندم على نيتك',
      body: 'لا تستهلك طاقتك في الندم على قرار اتخذته بنية صادقة وبالمعرفة التي كانت لديك وقتها.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's78',
      title: 'قوة الالتزام',
      body: 'تذكّر أن وراء كل إنجاز عظيم أيامًا عادية من الالتزام.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's79',
      title: 'مفاجآت جميلة',
      body: 'عسى أن تحمل لنا الأيام مفاجآت جميلة لم تخطر على بالنا.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's80',
      title: 'عِش لحظتك',
      body: 'لا تجعل انشغالك بالمستقبل يحرمك من ذكريات جميلة تصنعها الآن.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 's81',
      title: 'فرحة الرزق',
      body: 'تعلم أن تفرح لنجاح غيرك، فالأرزاق ليست سباقًا بين الناس.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 's82',
      title: 'العناية بنفسك',
      body: 'لا تتوقف عن الاهتمام بمظهرك وصحتك ونفسيتك، فالعناية بالنفس ليست رفاهية.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 's83',
      title: 'دعاء الصحبة والقلب',
      body: 'اللهم ارزقنا صحبة صالحة، وقلوبًا نقية، وأيامًا مباركة.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 's84',
      title: 'تجاوزت بلطفك',
      body: 'أحيانًا يكون أعظم إنجاز هو أن تتجاوز يومًا صعبًا دون أن تفقد لطفك.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 's85',
      title: 'اعرف قيمتك',
      body: 'لا تخلط بين التواضع والتقليل من شأن نفسك، اعرف قيمتك جيدًا.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's86',
      title: 'عادة تصنع يومك',
      body: 'اجعل لك عادة جميلة تضيف إلى يومك معنى، ولو كانت عشر دقائق من القراءة.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 's87',
      title: 'قوة التعلّم والمواجهة',
      body: 'لا تبحث عن حياة بلا مشكلات، بل ابنِ نفسًا تعرف كيف تتعامل معها.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's88',
      title: 'اختيار الله أحنّ',
      body: 'ما أجمل أن يأتي يوم نكتشف فيه أن الله اختار لنا ما هو أحنّ وأجمل.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's89',
      title: 'اصنع حياتك',
      body: 'لا تحاول أن تعيش حياة شخص آخر، اصنع الحياة التي تناسب أحلامك وقيمك.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's90',
      title: 'النجاح عادة يومية',
      body: 'اجعل النجاح عادة يومية، وليس مجرد أمنية تنتظر تحقيقها.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's91',
      title: 'دعاء الخير والأقدار',
      body: 'اللهم اجعل لنا نصيبًا من كل خير، واصرف عنا كل شر، واكتب لنا أجمل الأقدار.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 's92',
      title: 'لا تخسر نفسك',
      body: 'لا تخسر نفسك وأنت تحاول الحفاظ على أي علاقة.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's93',
      title: 'اتخذ خطوتك',
      body: 'لا تجعل كثرة التفكير تمنعك من اتخاذ خطوة تعرف أنها ضرورية.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's94',
      title: 'جمال التفاصيل',
      body: 'عوّد نفسك أن ترى الجمال في التفاصيل العادية؛ في فنجان قهوة، وضحكة، وصباح هادئ.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 's95',
      title: 'لا تؤجل اللطف',
      body: 'لا تؤجل الاعتذار إذا أخطأت، ولا تؤجل الامتنان إذا أُحسن إليك.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 's96',
      title: 'حكمة الاختيار',
      body: 'الحياة تمنحنا فرصًا كثيرة، لكن الحكمة أن نعرف أيها يستحق أن نتمسك به.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's97',
      title: 'نصيبنا من الفرح',
      body: 'وعسى أن يكون لنا من الفرح نصيب يفوق كل ما تمنيناه في دعائنا.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 's98',
      title: 'راحة البال أولًا',
      body: 'لا تقضِ وقتك في إثبات أنك على حق، أحيانًا تكون راحة بالك أهم من الانتصار في النقاش.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 's99',
      title: 'خطوة صغيرة اليوم',
      body: 'مهما كبرت أحلامك، لا تنسَ أن تبدأ بخطوة صغيرة اليوم.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 's100',
      title: 'حمد واستبشار',
      body: 'وفي نهاية كل يوم، احمد الله على ما كان، واستبشر بما سيكون، فالغد يحمل رزقًا لا تعلمه.',
      category: HappinessCategory.gratitude,
    ),
  ];

  static HappinessMessage getMessageForDate(DateTime date) {
    final dayNumber = date.year * 1000 +
        date.difference(DateTime(date.year, 1, 1)).inDays;
    return messages[dayNumber % messages.length];
  }

  static HappinessMessage getRandomMessage({
    HappinessCategory category = HappinessCategory.all,
    String? excludeId,
  }) {
    final pool = category == HappinessCategory.all
        ? messages
        : messages.where((m) => m.category == category).toList();
    if (pool.isEmpty) return messages.first;
    if (pool.length == 1) return pool.first;

    final filtered = excludeId == null
        ? pool
        : pool.where((m) => m.id != excludeId).toList();
    final activePool = filtered.isNotEmpty ? filtered : pool;
    return activePool[_random.nextInt(activePool.length)];
  }
}
