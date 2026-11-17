# سير إصدار رفيق المسلم عبر Google Play

هذا المستند يصف مسار إصدار الحزمة `com.jimmy.religiousapp` من خلال Google Play فقط. لا يستخدم إصدار Play تنزيل APK أو التثبيت الجانبي.

## قبل البناء

1. راجع رقم الإصدار في `pubspec.yaml`، ولا ترفع `versionCode` إلا إذا كان الإصدار المقابل مستخدمًا بالفعل في Play Console.
2. طبّق وراجع إجراءات Supabase المطلوبة في `docs/REMAINING_OWNER_ACTIONS.md`. لا تعتبر النسخ السحابي آمنًا قبل نجاح اختبارات العزل الفعلية.
3. تأكد من حالة تراخيص الأصول في `docs/AUDIO_LICENSE_AUDIT.md` و`docs/THIRD_PARTY_LICENSES.md`.
4. شغّل:

```text
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## بناء حزمة الاختبار المغلق

استخدم إعداد التوقيع الحالي دون عرض كلمات المرور أو تغيير ملف المفتاح:

```text
flutter build appbundle --release
```

المخرج المتوقع:

```text
build/app/outputs/bundle/release/app-release.aab
```

بعد البناء، تحقق من معرّف الحزمة والإصدار وMerged Manifest والصلاحيات والمكتبات الأصلية والأصول المشحونة، ثم احسب الحجم وSHA-256 وسجل النتيجة في وثائق الإصدار.

## النشر والاختبار

- ارفع AAB إلى مسار Internal testing أولًا لإجراء فحص سريع.
- للحسابات الشخصية الجديدة، نفّذ Closed testing بعدد 12 مختبرًا على الأقل، مع بقائهم مشتركين بصورة متصلة لمدة 14 يومًا قبل طلب الوصول إلى الإنتاج.
- لا تنشر إلى Production ما دام أي بند P0 أو P1 بحالة FAIL.
- التحديث داخل التطبيق يفتح Google Play. لا تُرفق APK داخل مسار تحديث التطبيق ولا تطلب صلاحية تثبيت حزم.

## التوقيع والأسرار

- لا تغير `applicationId` أو keystore أو alias أو ملكية التطبيق.
- لا تطبع أو تنقل محتوى `key.properties` أو كلمات مرور التوقيع.
- لا تضع مفاتيح service-role أو أسرار الخادم في تطبيق Flutter.
- مرّر `GOOGLE_WEB_CLIENT_ID` في بيئة البناء الآمنة عند اعتماد Google Sign-In، ولا تضع سرًا خاصًا في المصدر.
