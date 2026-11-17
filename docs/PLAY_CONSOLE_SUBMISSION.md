# مسودة تقديم Google Play

تاريخ الإعداد: 16 نوفمبر 2026

## بيانات المتجر المقترحة

- الاسم العربي: رفيق المسلم
- الاسم الإنجليزي: Rafiq Al Muslim
- التصنيف المقترح: نمط حياة
- الإعلانات: لا توجد حزمة إعلانات مكتشفة في المصدر؛ يجب أن يطابق التصريح أي تغيير لاحق.
- الجمهور: عام، وليس تطبيقًا موجّهًا للأطفال تحديدًا.

### وصف عربي قصير

مواقيت الصلاة والأذكار والقبلة والتسبيح والراديو في تطبيق إسلامي يومي.

### English short description

Prayer times, adhkar, qibla, tasbeeh and Quran radio in one daily Muslim app.

### وصف عربي كامل مقترح

رفيق المسلم يجمع أدوات العبادة اليومية في تجربة عربية واضحة: مواقيت الصلاة والتنبيهات، أذكار يومية بعدادات، اتجاه القبلة، التسبيح، الورد القرآني، التاريخ الهجري، وإذاعات القرآن. يمكن حفظ بيانات مختارة محليًا، مع نسخ سحابي اختياري عند ربط حساب Google بعد تفعيل الخدمة الآمنة. تعتمد دقة المواقيت والقبلة على إذن الموقع، ويمكن استخدام التطبيق بميزات محدودة عند رفض الأذونات الاختيارية.

### Proposed English full description

Rafiq Al Muslim brings daily worship tools into a clear Arabic-first experience: prayer times and reminders, daily adhkar with counters, qibla direction, tasbeeh, Quran reading goals, Hijri date, and Quran radio. Selected data can be stored locally, with optional cloud backup after connecting Google when the secure service is enabled. Prayer-time and qibla accuracy depend on location permission, while optional permissions may be declined with reduced functionality.

## مسودة Data safety

يجب إدخال الإجابات بعد مطابقتها مع البناء المنشور وسياسة الخصوصية:

- الموقع التقريبي أو الدقيق: يُستخدم لحساب المواقيت والقبلة واسم المكان؛ لا يُدرج في النسخة السحابية وفق التنفيذ الحالي.
- معلومات الحساب: بريد أو معرف Google وSupabase عند اختيار النسخ السحابي.
- نشاط التطبيق: إعدادات وبيانات متابعة مختارة قد تُرفع اختياريًا للنسخ الاحتياطي.
- التشفير أثناء النقل: نعم عبر HTTPS فقط في التطبيق، مع منع cleartext على Android.
- طلب الحذف: غير مكتمل حتى توفير حذف حساب Auth ورابط ويب خارجي؛ لا ترسل النموذج قبل ذلك.
- المشاركة مع أطراف ثالثة: Google Sign-In وSupabase والخدمات التي يختار المستخدم فتحها أو تشغيلها؛ يجب مراجعة تعريف Google Play القانوني للجمع والمشاركة قبل الإرسال.

## إقرارات إلزامية قبل الرفع

- الإصدار يستهدف API 36، وهو المستوى المطلوب للتطبيقات الجديدة والتحديثات منذ 31 أغسطس 2026 وفق [متطلبات Target API الرسمية](https://support.google.com/googleplay/android-developer/answer/11926878).
- تصوير فيديو لكل استخدام لخدمات foreground وإدخال الوصف المناسب.
- تبرير `SCHEDULE_EXACT_ALARM` لمواقيت الصلاة.
- مراجعة أهلية `SYSTEM_ALERT_WINDOW` و`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` و`specialUse` أو إزالتها إذا لم تقبلها السياسة.
- نشر سياسة الخصوصية على رابط HTTPS عام متاح بلا تسجيل دخول.
- نشر رابط HTTPS لحذف الحساب والبيانات، وتوفير نفس الإجراء داخل التطبيق؛ [سياسة Google Play](https://support.google.com/googleplay/android-developer/answer/13327111) تشترط المسارين للتطبيق الذي يتيح إنشاء حساب.
- إتمام متطلب الاختبار المغلق 12 مختبرًا منضمين باستمرار لمدة 14 يومًا إذا كان حساب المطور شخصيًا وأُنشئ بعد 13 نوفمبر 2023، وفق [المتطلب الرسمي](https://support.google.com/googleplay/android-developer/answer/14151465).
- لأن target أعلى من Android 14، يجب التصريح عن كل نوع foreground service في Play Console مع وصف الأثر وفيديو يوضح تشغيل الميزة، وفق [متطلبات FGS الرسمية](https://support.google.com/googleplay/android-developer/answer/13392821).
- تجهيز أيقونة 512×512، رسم ميزة 1024×500، ولقطات هاتف حديثة تعكس البناء الفعلي، مع إعادة التحقق من متطلبات Play Console وقت الإرسال.

## حالة التقديم

**FAIL حاليًا:** لا تُرفع الحزمة للإنتاج قبل إغلاق عناصر `REMAINING_OWNER_ACTIONS.md`.
