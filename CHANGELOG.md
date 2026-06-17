# Changelog

## [3.2.2] - 2026-01-20
### Fixed
- **تحسين بروتوكول بث الراديو:** تحديث رؤوس الطلبات (HTTP Headers) لمحطات القاهرة والسعودية لضمان التوافق مع خوادم RadioJar.
- **معالجة تداخل البث:** إضافة آلية إيقاف إجباري للبث السابق قبل بدء محطة جديدة لضمان سرعة الاستجابة.

## [3.2.1] - 2026-01-20
### Fixed
- **إصلاح راديو القاهرة والسعودية:** معالجة مشكلة تشغيل بعض المحطات عبر بروتوكول HTTP وإضافة إعدادات `User-Agent` لضمان استقرار البث.
- **تحسين استقرار النظام:** رفع توافقية التطبيق مع روابط البث المباشر الخارجية.

## [3.2.0] - 2026-01-20
### Added
- **راديو القرآن الكريم:** إضافة خدمة البث المباشر لإذاعة القرآن الكريم من القاهرة والسعودية ومحطات تلاوات كبار القراء.
- **التشغيل في الخلفية:** دعم كامل لتشغيل الراديو في الخلفية ومع شاشة القفل.
- **التكامل الذكي:** إيقاف الراديو تلقائياً عند دخول وقت الأذان واستئنافه لاحقاً.

## [3.1.0] - 2026-01-20
### Added
- **خيار التذكير كل 5 دقائق:** إضافة خيار جديد في إعدادات التذكير المتكرر للسماح بفواصل زمنية أقصر (5 دقائق) بناءً على طلب المستخدمين.

## [3.0.0] - 2026-01-20
### Added
- **خدمة تشغيل الأذان:** إضافة نظام تشغيل الأذان في الخلفية بشكل متطور لضمان الدقة والموثوقية.
- **شاشة الصلاحيات الجديدة:** تحسين واجهة طلب الصلاحيات لضمان عمل التطبيق بشكل مثالي (Onboarding).
- **نظام تحديث الأذكار:** تحسين آلية تحديث الأذكار في الخلفية (Background Refresher).
- **تحسينات واجهة الأذكار:** تحديثات في عرض تفاصيل الأذكار لتجربة مستخدم أفضل.

### Changed
- تحديث النظام الداخلي للتنبيهات ليتوافق مع أحدث إصدارات أندرويد.
- تحسين أداء تشغيل الأصوات في الخلفية.

## [2.0.0] - 2026-01-14
### Added
- **عداد تنازلي ذكي:** إضافة مؤقت حي في الإعدادات يوضح الوقت المتبقي للذكر القادم بالثانية.
- **تحسين الذكر العائم:** إضافة خاصية الإخفاء التلقائي بعد 10 ثوانٍ لراحة المستخدم.
- **إشعارات احترافية:** تحسين نظام التنبيهات ليكون أكثر سلاسة وأقل استهلاكاً للبطارية.

### Changed
- تحديث شامل لهوية البرنامج البصرية والتقنية.
- تحسين سرعة بناء التطبيق (Build Performance).

## [1.1.0] - 2026-01-12
### Added
- "Qiyam al-Lail" (قيام الليل) task added to daily schedule.
- Dynamic weather updates on refresh.
- Professional app versioning system.

### Changed
- Removed default logo splash screen.
- App now launches directly to the "Ahmed Jamal" copyrights screen.
- Improved launch speed perception by matching background colors.
- Updated `TasksViewModel` clock logic to update every second for smoother countdowns.

### Fixed
- Fixed black screen issue on startup.
- Fixed stuck countdown timer for next prayer.
- Fixed unused variable warnings in code.
- Fixed issue where resetting Athkar counters did not update the main task checklist.

## [1.0.0] - 2026-01-10
### Initial Release
- Basic prayer times tracking.
- Athkar (Morning/Evening/Sleep).
- Location services and Qibla.
