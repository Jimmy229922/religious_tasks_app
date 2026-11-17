# تقرير التدقيق النهائي — رفيق المسلم

تاريخ التقرير: 16 نوفمبر 2026

## النتيجة التنفيذية

**FAIL — غير جاهز للنشر الإنتاجي.**

نجح البناء والتحليل والاختبارات والتحقق البنيوي للحزمة محليًا، لكن تبقى ثلاثة موانع نشر مباشرة: عدم تطبيق واختبار حماية RLS على Supabase الإنتاجي، غياب حذف حساب Supabase Auth والرابط العام المطلوب، وشحن 14 ملفًا صوتيًا بلا دليل ترخيص. كما تبقى تهيئة Google OAuth واختبارات الجهاز وإقرارات Play والمراجعة الدينية وحقوق البث عناصر إلزامية قبل الإنتاج.

## مصفوفة الحالة

| المجال | الحالة | الدليل أو المتبقي |
|---|---|---|
| إصلاح عميل النسخ الاحتياطي وSQL المحلي | PASS محلي | مصادقة فعلية، `auth.uid()`، RLS، استعادة ذرية، قائمة سماح وحد 512KB |
| حماية Supabase الإنتاجية | FAIL | migration لم تُطبق، SQL لم يُنفذ على خادم اختبار، واختبار الحسابين لم يُنفذ |
| التحدي العالمي | PASS محلي / WARNING إنتاجي | RPC ذري بهوية Google مؤكدة، حفظ pending وتقسيمه وإعادة المحاولة؛ الإنتاج غير مؤكد |
| التحليل الساكن | PASS | `No issues found` |
| الاختبارات الآلية | PASS | 10 من 10 |
| حزمة AAB | PASS بنيويًا | `bundletool` و`zipalign` و`jarsigner` نجحت |
| Android API | PASS إعدادًا | min 24، target وcompile 36 |
| دعم 16KB | PASS للحزمة / WARNING للتشغيل | `zipalign -P 16` وELF ناجحان؛ لا يوجد اختبار جهاز 16KB |
| الوظائف الأساسية | WARNING | أُصلحت أعطال محددة، لكن لا يوجد اختبار end-to-end على جهاز |
| الخصوصية | WARNING | السياسة محدثة محليًا؛ تحتاج نشر HTTPS ومطابقة Data safety |
| حذف الحساب | FAIL | حذف النسخة موجود، حذف Supabase Auth والرابط الخارجي غير موجودين |
| تراخيص الصوت | FAIL | 14 ملفًا مشحونًا بلا إثبات مصدر أو ترخيص |
| المحتوى الديني | WARNING | تصحيح مؤكد واحد، وبنود تحتاج مراجعًا مؤهلًا |
| Play Console والصلاحيات | WARNING | exact alarm وFGS وoverlay وbattery optimization تحتاج إقرارات واختبارًا |

## ملف الإصدار الناتج

- المسار: `build/app/outputs/bundle/release/app-release.aab`
- الحجم: `92,839,619` بايت
- SHA-256: `8F552762311D61AC445E78B8C15C0E849C9056DBD54C8248E9E3F7AB16FC5F8B`
- الحزمة: `com.jimmy.religiousapp`
- الإصدار: `3.8.6+37`
- التوقيع: `jar verified`؛ لم يتغير keystore.
- البيان النهائي: minSdk 24، target/compile 36، و`usesCleartextTraffic=false`، دون صلاحيات تثبيت APK أو full-screen intent.

هذه حزمة ناجحة بنيويًا وليست حزمة معتمدة للنشر؛ ما زالت تحتوي الأصول الصوتية غير الموثقة وتنتظر إغلاق موانع الإنتاج.

## أهم الإصلاحات المنفذة

- رُبط النسخ السحابي بجلسة Supabase الموثقة و`auth.uid()`، وأصبحت الاستعادة تتحقق من الحمولة كاملة قبل أي كتابة محلية.
- قُسم SQL إلى مرحلة احتواء تغلق RLS والصلاحيات أولًا ثم مرحلة ترحيل، مع مطالبة محافظة للصفوف القديمة وترك التكرارات للمراجعة.
- صار التحدي العالمي يتطلب هوية Google مؤكدة، ويحفظ الزيادات غير المرسلة ويقسمها ويعيد إرسالها دون فقد صامت.
- أزيلت OTA وتنزيل أو تثبيت APK وصلاحياتها، ومنعت الاتصالات غير المشفرة.
- أُصلحت جدولة التنبيهات والغفوة الصامتة وإيقاف الأذان وAudio Focus وتجديد مهام الخلفية، ومنعت جدولة أذان الشروق.
- أصبحت الأذونات الاختيارية لا تمنع دخول التطبيق، وفشل اكتشاف المنطقة الزمنية لا يختار القاهرة بصمت.
- أُصلحت مقارنة الإصدارات الدلالية، وسباق تراكب الراديو، وتسريب/إلغاء اشتراكات البث.
- أزيلت بطاقة الطقس العشوائية، وصار طلب الموقع بفعل المستخدم، وعولج تغيير منتصف الليل والقيم المخزنة التالفة.
- لم يعد إكمال أذكار النوم يسجل إكمال أذكار المساء، وصارت خطة الختمة تحسب نطاقات الصفحات، وتعرض القبلة تعذر المستشعر بدل التحميل الدائم.
- فُعل عرض edge-to-edge بدل الوضع الغامر، واحترم تكبير خط النظام، وقُصر WebView سورة الكهف على Quran.com عبر HTTPS.
- صُحح نص ديني مؤكد ووُحدت مصطلحات عربية ظاهرة دون تغيير النصوص القرآنية غير المتحققة.

## الملفات المعدلة أو المضافة

### Android والبناء

- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/jimmy/religiousapp/AdhanPlaybackService.kt`
- `android/app/src/main/kotlin/com/jimmy/religiousapp/MainActivity.kt`
- `android/app/src/main/kotlin/com/jimmy/religiousapp/NativeAdhanScheduler.kt`
- `android/app/src/main/res/xml/filepaths.xml`
- `pubspec.yaml`
- `pubspec.lock`

### Dart والاختبارات

- `lib/main.dart`
- `lib/app/bootstrap/app_startup.dart`
- `lib/app/religious_app.dart`
- `lib/core/constants/strings.dart`
- `lib/core/services/backup_service.dart`
- `lib/core/services/global_challenge_service.dart`
- `lib/core/services/location_service.dart`
- `lib/core/widgets/full_adhan_overlay_dialog.dart`
- `lib/features/athkar/data/athkar_data.dart`
- `lib/features/athkar/providers/athkar_view_model.dart`
- `lib/features/athkar/screens/surah_kahf_screen.dart`
- `lib/features/notifications/presentation/screens/notification_settings_screen.dart`
- `lib/features/qibla/screens/qibla_screen.dart`
- `lib/features/quran/screens/khatmah_screen.dart`
- `lib/features/quran/services/khatmah_planner_service.dart`
- `lib/features/radio/providers/radio_view_model.dart`
- `lib/features/settings/screens/permissions_onboarding_screen.dart`
- `lib/features/settings/screens/settings_screen.dart`
- `lib/features/tasbeeh/providers/tasbeeh_view_model.dart`
- `lib/features/tasbeeh/screens/custom_tasbeeh_screen.dart`
- `lib/features/tasks/providers/tasks_view_model.dart`
- `lib/shared/services/notifications/app_notification_service.dart`
- `lib/shared/services/notifications/dhikr_background_refresher.dart`
- `lib/shared/services/notifications/notification_preferences.dart`
- `lib/shared/services/notifications/notification_preferences_service.dart`
- `lib/shared/services/updates/app_update_service.dart`
- `lib/shared/services/updates/update_view_model.dart`
- `lib/shared/widgets/dhikr_overlay.dart`
- `supabase/migrations/202611140001_secure_cloud_data.sql`
- `test/core/services/backup_service_test.dart`
- `test/widget_test.dart`

### الوثائق

- `README.md`
- `PRIVACY_POLICY.md`
- `RELEASE_WORKFLOW.md`
- ملفات التدقيق والإصدار داخل `docs/`.

## تتبع الأثر

البصمة الحالية حُسبت مباشرة من الملف المبني في 16 نوفمبر 2026. البصمة التاريخية المشار إليها سابقًا لم يعد أثرها متاحًا للمقارنة الثنائية، وتشابه أحجام آثار سابقة لا يثبت تطابقها. تغييرات المصدر الأخيرة تفسر تغير الحجم والبصمة. كما أن سجل مارس 2026 في الملاحظات التاريخية لا يُعد دليلًا على نتيجة تدقيق نوفمبر ولا توجد قرينة تبرر إعادة كتابته.

## حدود ما تم التحقق منه

- لم تُعرض أو تُنسخ بيانات مستخدمين حقيقية.
- لم يحدث أي تعديل مباشر لقاعدة الإنتاج، ولم تُنفذ migration على أي خادم.
- لم تُنفذ أي عملية Git.
- لم يُغيّر package name أو keystore أو مفاتيح التوقيع.
- لم تُحذف ملفات أصلية؛ النسخ المحلية قبل التعديل محفوظة داخل `.codex-backups`.
- لم يتوفر جهاز لاختبار الوظائف كاملة؛ النتائج المعتمدة على الجهاز موصوفة صراحة كـWARNING.
- توجد شاشة صلاحيات قديمة غير مستخدمة ضمن `features/onboarding`؛ تُركت دون حذف وفق سياسة الحفاظ على الملفات الأصلية.

## قرار الإصدار

لا ترفع AAB إلى مسار الإنتاج. احتفظ بها كأثر بناء اختباري فقط حتى إغلاق عناصر P0 في `REMAINING_OWNER_ACTIONS.md`، ثم أعد البناء والاختبار وأصدر بصمة جديدة.
