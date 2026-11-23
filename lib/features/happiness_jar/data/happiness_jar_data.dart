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
    // --- بشائر وأمل (Hope) ---
    HappinessMessage(
      id: 'h1',
      title: 'بشارة ربانية ليومك',
      body: 'لَعَلَّ اللَّهَ يُحْدِثُ بَعْدَ ذَٰلِكَ أَمْرًا.. اطمئن، فالمُدبِّر هو الله، وأقداره كلها رحمة ولطف بك.',
      reflection: 'تفاءل، فما عند الله أجمل مما تتخيل.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 'h2',
      title: 'رسالة تفاؤل',
      body: 'قد يأتيك الفرج من حيث لم تخطط له، وتُفتح لك الأبواب التي ظننتها أُغلقت إلى الأبد.. فقط أحسن الظن بربك.',
      reflection: 'أنا عند ظن عبدي بي.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 'h3',
      title: 'فرج قريب',
      body: 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا ۝ إِنَّ مَعَ الْعُسْرِ يُسْرًا.. العسر محاط بيسرين، وبشائر الخير في طريقها إليك.',
      reflection: 'كل ضيق يعقبه اتساع بأمر الله.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 'h4',
      title: 'أمل متجدد',
      body: 'يومك هذا قد يكون هو اليوم الذي تُستجاب فيه دعوتك القديمة التي طال انتظارها، فابتسم واستبشر!',
      reflection: 'لا يرد القضاء إلا الدعاء.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 'h5',
      title: 'وعدٌ لا يُخلف',
      body: 'وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ.. عطاء الله سيجعلك تنسى كل تعبٍ مررت به.',
      reflection: 'الرضا والعطاء من كرم الكريم.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 'h6',
      title: 'خطوة نحو النور',
      body: 'كل خطوة تخطوها نحو الخير وإن كانت صغيرة، يبارك الله فيها ويزيدك بها نوراً وسعادة في قلبك.',
      reflection: 'أحب الأعمال إلى الله أدومها وإن قل.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 'h7',
      title: 'أبواب السماء مفتوحة',
      body: 'لا تقل مستحيل، فأنت تدعو من يقول للشيء كن فيكون! ارفع يديك بقلبٍ موقن بالإجابة.',
      reflection: 'ادعوني أستجب لكم.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 'h8',
      title: 'غدٌ أجمل بإذن الله',
      body: 'ما فاتك لم يكن لك، وما كُتب لك سيصلك ولو كان بين جبلين؛ فاستبشر خيراً بما أعدّه الله لك.',
      reflection: 'قل لن يصيبنا إلا ما كتب الله لنا.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 'h9',
      title: 'أثرٌ لا يضيع',
      body: 'تلك الكلمة الطيبة والابتسامة التي قدّمتها يوماً، ادّخرها الله لك سعادةً تعود إلى قلبك في وقتها المناسب.',
      reflection: 'هل جزاء الإحسان إلا الإحسان.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 'h10',
      title: 'بداية جديدة',
      body: 'كل صباح هو فرصة جديدة يهبها الله لك لتبدأ بقلبٍ أنقى، وهمّةٍ أعلى، وفرحةٍ تنتظرك.',
      reflection: 'الحمد لله الذي أحيانا بعد ما أماتنا.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 'h11',
      title: 'رزقك يبحث عنك',
      body: 'رزقك من السعادة والبركة والسكينة يعرف عنوانك ولن يخطئك أبداً؛ فقط توكّل على الحي الذي لا يموت.',
      reflection: 'ومن يتوكل على الله فهو حسبه.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 'h12',
      title: 'تيسيرٌ من اللطيف',
      body: 'سيُيسّر الله لك الصعب، ويُقرّب لك البعيد، ويُبدّل حيرتك يقيناً وفرحاً يملأ صدرك.',
      reflection: 'إن ربي لطيف لما يشاء.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 'h13',
      title: 'جبرُ الله عظيم',
      body: 'إذا جبر الله خاطراً، أدهشه بعوضه! فاستعد لعوض الله الجميل الذي يليق بكرمه.',
      reflection: 'إن الله على كل شيء قدير.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 'h14',
      title: 'نور الفرج',
      body: 'أشدّ ساعات الليل ظلمةً هي التي تسبق الفجر مباشرة؛ فابشر بانفراج همّك وإشراق فرحك.',
      reflection: 'أليس الصبح بقريب!',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 'h15',
      title: 'سعيك مشكور',
      body: 'تعبك اليوم في طاعتك، وفي عملك، وفي برّك بأهلك؛ كلّه مسطور في صحائف نور لا تضيع عند الله.',
      reflection: 'إن الله لا يضيع أجر من أحسن عملا.',
      category: HappinessCategory.hope,
    ),

    // --- طمأنينة وسكينة (Calm) ---
    HappinessMessage(
      id: 'c1',
      title: 'همسة طمأنينة',
      body: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ.. خذ نفساً عميقاً، واذكر الله الآن، واشعر بالسلام يسري في روحك.',
      reflection: 'سبحان الله وبحمده، سبحان الله العظيم.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 'c2',
      title: 'أنت في معيّة الله',
      body: 'لَا تَحْزَنْ إِنَّ اللَّهَ مَعَنَا.. يكفيك من السعادة والأمان أن رب السماوات والأرض معك ويسمعك.',
      reflection: 'اطمئن، لست وحدك أبداً.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 'c3',
      title: 'تفويضٌ وراحة',
      body: 'وَأُفَوِّضُ أَمْرِي إِلَى اللَّهِ ۚ إِنَّ اللَّهَ بَصِيرٌ بِالْعِبَادِ.. ألقِ همومك على باب الكريم ونَم قرير العين.',
      reflection: 'حسبي الله ونعم الوكيل.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 'c4',
      title: 'رحمة واسعة',
      body: 'وَرَحْمَتِي وَسِعَتْ كُلَّ شَيْءٍ.. وأنت من هذا الكون الواسع الذي تشمله رحمة الله ولطفه الآن.',
      reflection: 'اللهم أدخلنا في واسع رحمتك.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 'c5',
      title: 'عنايةُ الرحمن بك',
      body: 'وَاصْبِرْ لِحُكْمِ رَبِّكَ فَإِنَّكَ بِأَعْيُنِنَا.. هل هناك أمانٌ أعظم من أنك في حفظ الله وعنايته؟',
      reflection: 'فالله خير حافظاً وهو أرحم الراحمين.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 'c6',
      title: 'سلامٌ داخلي',
      body: 'لا تحمل همّ الغد في قلبك اليوم، فالذي دبّر لك أمسك وكفاك، هو نفسه الذي سيكفيك غدك بأجمل مما ترجو.',
      reflection: 'لا حول ولا قوة إلا بالله.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 'c7',
      title: 'سكون القلب',
      body: 'سجدة واحدة صادقة تضع فيها جبهتك على الأرض كفيلة بأن ترفع عن قلبك ثقل الدنيا كلّها.',
      reflection: 'أقرب ما يكون العبد من ربه وهو ساجد.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 'c8',
      title: 'قريبٌ مجيب',
      body: 'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ.. لم يجعل بينك وبينه حاجباً، هو أقرب إليك من حبل الوريد.',
      reflection: 'ناجِ ربك بما في قلبك الآن.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 'c9',
      title: 'برد السكينة',
      body: 'اللهم أنزل على قلب قارئ هذه الرسالة سكينةً تُذهب كل قلق، وطمأنينةً تملأ حياته بالرضا والفرح.',
      reflection: 'آمين يا رب العالمين.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 'c10',
      title: 'ثباتٌ وهدوء',
      body: 'إذا هدأ قلبك بالاستغفار، انقشع الضباب عن طريقك واتضحت لك خيارات الخير.',
      reflection: 'أستغفر الله العظيم وأتوب إليه.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 'c11',
      title: 'اختيار الله أرحم',
      body: 'لو كُشف لك حجاب الغيب، لما اخترت لنفسك إلا ما اختاره الله لك من خيرٍ وسلامة.',
      reflection: 'رضيت بالله رباً وبالإسلام ديناً.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 'c12',
      title: 'نسمة ارتياح',
      body: 'تذكّر كم من أزماتٍ مرّت بك في السابق وكنت تظنها لن تنتهي، ثم مرّت بلطف الله وصارت ذكريات!',
      reflection: 'سيمر هذا أيضاً بسلام.',
      category: HappinessCategory.calm,
    ),

    // --- شكر وامتنان (Gratitude) ---
    HappinessMessage(
      id: 'g1',
      title: 'نعمٌ لا تُحصى',
      body: 'استيقظت اليوم بعافيةٍ في جسدك، وأمانٍ في بيتك، وقلبٍ ينبض بذكر الله.. هذه وحدها كنوز تستحق الابتسامة!',
      reflection: 'الحمد لله حمداً كثيراً طيباً.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 'g2',
      title: 'وعد الزيادة',
      body: 'لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ.. اشكر الله الآن على نعمةٍ صغيرة في حياتك، وسترى كيف تتضاعف بركاتها!',
      reflection: 'اللهم لك الحمد كما ينبغي لجلال وجهك.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 'g3',
      title: 'كنوز في يومك',
      body: 'من أسباب السعادة أن تنظر إلى ما بين يديك بعين الرضا؛ ففي حياتك أرزاق يتمناها الكثيرون.',
      reflection: 'أصبحنا وأصبح الملك لله.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 'g4',
      title: 'نعمة الهداية',
      body: 'أجمل نعمة تستشعرها الآن أن الله اصطفاك وجعل في قلبك حباً لذكره، وطاعته، وتلاوة كتابه.',
      reflection: 'الحمد لله على نعمة الإسلام.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 'g5',
      title: 'شكرُ اللطف الخفي',
      body: 'كم من بلاءٍ صرفه الله عنك وأنت لا تدري، وكم من خيرٍ ساقه إليك دون أن تطلبه! فله الحمد دائماً.',
      reflection: 'سبحانك ربي ما أرحمك!',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 'g6',
      title: 'قناعةٌ تُسعد القلب',
      body: 'قال النبي ﷺ: «قد أفلح من أسلم، ورُزق كفافاً، وقنّعه الله بما آتاه». القناعة مفتاح البهجة الدائمة.',
      reflection: 'اللهم قنعني بما رزقتني وبارك لي فيه.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 'g7',
      title: 'أحباب في حياتك',
      body: 'وجود شخص واحد يدعو لك بظهر الغيب أو يسعد بسعادتك هو رزقٌ عظيم، احمد الله عليه وادعُ له الآن.',
      reflection: 'اللهم بارك لي في أهلي وأحبتي.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 'g8',
      title: 'فرحة الإنجاز',
      body: 'كافئ نفسك بابتسامة امتنان على كل خطوة أنجزتها اليوم، مهما كانت بسيطة، فالله يبارك السعي.',
      reflection: 'الحمد لله الذي بنعمته تتم الصالحات.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 'g9',
      title: 'بركة العافية',
      body: 'نفسٌ يتردد بسهولة، وعينٌ تبصر الجمال، ويدٌ تعطي الخير؛ نعمٌ مجانية نعيش فيها كل لحظة.',
      reflection: 'اللهم أدم علينا عافيتك وسترك.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 'g10',
      title: 'الرضا جنة الدنيا',
      body: 'متى ما رضي القلب بقسمة الله، تحوّل القليل إلى كثير، واليوم العادي إلى عيد من الفرح.',
      reflection: 'اللهم ارزقنا نفساً مطمئنة راضية.',
      category: HappinessCategory.gratitude,
    ),

    // --- لطف وجبر خاطر (Love & Kindness) ---
    HappinessMessage(
      id: 'l1',
      title: 'أنت محبوبٌ ومقدّر',
      body: 'ربما لا تعرف كم من القلوب تسعد بكلامك الطيب، وكم من الدعوات الصادقة تذكر اسمك في الخفاء!',
      reflection: 'تبسمك في وجه أخيك صدقة.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 'l2',
      title: 'لطفٌ يحيط بك',
      body: 'أنت شخص ذو أثر جميل؛ حضورك يُضيف سكينةً وبهجةً، فكن لطيفاً مع نفسك اليوم كما تكون مع الآخرين.',
      reflection: 'رفقاً بنفسك، فإنك عند الله غالٍ.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 'l3',
      title: 'محبةُ الله لأهل الخير',
      body: 'ما دمت تحب الخير للناس وتفرح لفرحهم، فإن الله يزرع محبّتك في قلوب عباده ويُفرحك أضعافاً.',
      reflection: 'إن الله يحب المحسنين.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 'l4',
      title: 'ابتسامة نبوية',
      body: 'كان النبي ﷺ أكثر الناس تبسماً وإدخالاً للسرور على قلوب أصحابه.. ابتسم الآن، فابتسامتك عبادة وصدقة!',
      reflection: 'اللهم صلّ وسلم على نبينا محمد.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 'l5',
      title: 'كلمة تجبر الخاطر',
      body: 'قد تمنح شخصاً اليوم سعادة يوم كامل برسالة لطيفة تسأل فيها عنه أو تدعو له فيها بالخير.',
      reflection: 'أحب الناس إلى الله أنفعهم للناس.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 'l6',
      title: 'هدية قلبية',
      body: 'لا تسمح لأي عارضٍ عابر أن يسرق بهجة يومك؛ أنت تستحق أن تعيش لحظاتك مطمئناً ومبتسماً.',
      reflection: 'يسّروا ولا تعسّروا، وبشّروا ولا تنفّروا.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 'l7',
      title: 'ذكرى تُفرح القلب',
      body: 'من رحمة الله بك أنه إذا أراد لك خيراً ألهَمك الدعاء به، ثم هيّأ لك أسبابه، ثم أسعدك بتمامه!',
      reflection: 'سبحان اللطيف الخبير.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 'l8',
      title: 'أثرٌ باقٍ',
      body: 'تأكّد أن الله يرى صبرك، ويرى محاولاتك الصادقة، ولن يترك قلبك دون جبرٍ يغمرك فرحاً.',
      reflection: 'وما كان ربك نسياً.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 'l9',
      title: 'الصلاة على الحبيب ﷺ',
      body: 'كل صلاة على النبي ﷺ تفتح لك أبواب الفرج، وتكفيك همّك، وتغفر ذنبك، وتملأ يومك بركة ونوراً.',
      reflection: 'اللهم صلّ على محمد وعلى آل محمد.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 'l10',
      title: 'رسالة حانية',
      body: 'إن تعثرت يوماً فلا بأس؛ الرحمة تسع عثرتك، وباب التوبة واللطف مفتوح لك في كل لحظة بحب.',
      reflection: 'إن الله يغفر الذنوب جميعاً.',
      category: HappinessCategory.love,
    ),

    // --- دعوات مبهجة (Dua) ---
    HappinessMessage(
      id: 'd1',
      title: 'دعوة لك من القلب',
      body: 'أسأل الله أن يرزقك اليوم فرحةً لم تكن في الحسبان، وبشارةً تدمع لها عيناك سروراً وامتناناً.',
      reflection: 'آمين يا رب العالمين.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 'd2',
      title: 'دعاء البركة والتوفيق',
      body: 'اللهم بارك لصاحب هذا الهاتف في وقته، وصحته، ورزقه، وأهله، وافتح له أبواب السعادة أينما توجّه.',
      reflection: 'اللهم آمين.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 'd3',
      title: 'دعاء الجبر والرضا',
      body: 'يا رب اجبر خاطره جبراً يتعجّب منه أهل السماوات والأرض، وحقّق له كل أمنيةٍ فيها خيرٌ له في الدنيا والآخرة.',
      reflection: 'ربنا آتنا في الدنيا والآخرة حسنة.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 'd4',
      title: 'دعاء شرح الصدر',
      body: 'اللهم اشرح صدره، ويسّر أمره، واجعل التوفيق حليفه، والطمأنينة تسكن قلبه طوال هذا اليوم.',
      reflection: 'رب اشرح لي صدري ويسر لي أمري.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 'd5',
      title: 'دعاء الرزق الطيب',
      body: 'اللهم ارزقه رزقاً حلالاً طيباً واسعاً مباركاً فيه، واكفه بحلالك عن حرامك، وأغنه بفضلك عمّن سواك.',
      reflection: 'يا رزّاق يا كريم.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 'd6',
      title: 'دعاء السعادة الدائمة',
      body: 'اللهم اجعل أيامه القادمة حاملةً للبشائر، خاليةً من الأحزان، عامرةً بذكرك وشكرك وحسن عبادتك.',
      reflection: 'اللهم أعني على ذكرك وشكرك.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 'd7',
      title: 'دعاء الحفظ والأمان',
      body: 'اللهم احفظه بحفظك الذي لا يُرام، واكلأه بعينك التي لا تنام، وأحطه بألطافك في كل خطوة.',
      reflection: 'أستودعكم الله الذي لا تضيع ودائعه.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 'd8',
      title: 'دعاء القبول والمحبة',
      body: 'اللهم حبّب إليه الإيمان وزيّنه في قلبه، وارزقه صحبةً صالحةً تعينه على الخير وتفرح قلبه.',
      reflection: 'اللهم إني أسألك حبك وحب من يحبك.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 'd9',
      title: 'دعاء الفرج العاجل',
      body: 'يا فارج الهم ويا كاشف الغم، أبدل كل همٍّ في قلبه فرحاً، وكل ضيقٍ فرجاً، وكل تعبٍ راحةً.',
      reflection: 'يا حي يا قيوم برحمتك أستغيث.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 'd10',
      title: 'دعاء الختام المبارك',
      body: 'اللهم أسعد قلبه سعادةً لا تشقى بعدها أبداً، واكتب له نصيباً من كل خيرٍ قسمته لعبادك الصالحين.',
      reflection: 'الحمد لله رب العالمين.',
      category: HappinessCategory.dua,
    ),

    // --- إضافات متنوعة تملأ البرطمان بهجة ---
    HappinessMessage(
      id: 'x1',
      title: 'مفاجأة من السماء',
      body: 'أجمل الأيام لم تأتِ بعد! تذكّر أن الله يخبّئ لك لحظات فرح ستقول عندها: ما أكرمك يا رب!',
      reflection: 'وتوكل على العزيز الرحيم.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 'x2',
      title: 'قوة الدعاء',
      body: 'كفّان مرفوعتان بصدقٍ في لحظة هدوء قد تغيّران مجرى حياتك كلّها نحو الأجمل.',
      reflection: 'إن ربي لسميع الدعاء.',
      category: HappinessCategory.dua,
    ),
    HappinessMessage(
      id: 'x3',
      title: 'قلبٌ أخضر',
      body: 'اجعل في يومك لحظة تسعد فيها قلب غيرك؛ فإن أسرع طريق للفرح أن تكون سبباً في فرح إنسان.',
      reflection: 'أحب الأعمال سرور تدخله على مسلم.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 'x4',
      title: 'سحابة خير',
      body: 'بعض الدعوات تبدو متأخرة، لكنها في الحقيقة تتجمّع كالغيث لتمطر حياتك بركةً في أجمل توقيت.',
      reflection: 'وعسى أن تكرهوا شيئاً وهو خير لكم.',
      category: HappinessCategory.hope,
    ),
    HappinessMessage(
      id: 'x5',
      title: 'نور القرآن',
      body: 'لو لم تقرأ اليوم إلا وجهاً واحداً من كتاب الله بتدبّر، فكفى به نوراً وانشراحاً لبقية يومك.',
      reflection: 'وننزل من القرآن ما هو شفاء ورحمة.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 'x6',
      title: 'تذكير لطيف',
      body: 'إن كان في قلبك شيء تخاف أن يضيع، فاستودعه الله؛ فودائع الله لا تضيع أبداً.',
      reflection: 'استودعت الله ديني وأهلي وقلبي.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 'x7',
      title: 'فرحة السماء بك',
      body: 'لو علمت كيف يفرَح الله بتوبتك ورجوعك إليه في كل مرة، لطار قلبك شوقاً وبهجة.',
      reflection: 'التائب من الذنب كمن لا ذنب له.',
      category: HappinessCategory.love,
    ),
    HappinessMessage(
      id: 'x8',
      title: 'لحظة شكر',
      body: 'توقف لثوانٍ.. اشرب كوب ماء وقل "الحمد لله"، وتأمّل كم من النعم تعمل في جسدك دون عناء منك.',
      reflection: 'وإن تعدوا نعمة الله لا تحصوها.',
      category: HappinessCategory.gratitude,
    ),
    HappinessMessage(
      id: 'x9',
      title: 'أنس بالله',
      body: 'من وجد الله في قلبه لم يفتقد شيئاً، ومن كان أنسه بمولاه عاش مطمئناً في كل حال.',
      reflection: 'الله لا إله إلا هو الحي القيوم.',
      category: HappinessCategory.calm,
    ),
    HappinessMessage(
      id: 'x10',
      title: 'نقطة نور',
      body: 'كل ذكرٍ تقوله الآن هو غرسٌ في الجنة يُبنى لك به نعيمٌ مقيم، وأنت تقرأ هذه الكلمات في بيتك!',
      reflection: 'سبحان الله وبحمده، سبحان الله العظيم.',
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
