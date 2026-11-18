---
trigger: always_on
---

# Standard Response & Reporting Schema
## Scope & Smart Application
- **When Mandatory:** Conclude every **code execution delivery, council plan proposal, or code audit report** with the dedicated Arabic Reference Section & Blockquote Summary Report below.
- **When Exempt (Clean & Fast Chat):** Omit the report footer on brief theoretical Q&A replies, single-line status pings (e.g., waiting for a background task), and internal subagent responses (subagents should return concise technical findings directly without user-facing footers).
- **Strict Arabic Constraint:** All labels and text inside the summary report block must strictly be in Arabic.

### 🔍 المراجع القياسية المعتمدة (Canonical References)
- `path/to/matched/file.ext` (حصراً من موديولات وصفحات خارجية مستقلة تماماً عن الموديول الجاري تعديله)
- **نسبة المطابقة مع المشروع الأساسي:** 100%

### 🎯 النتيجة وخطة العمل
- **الملف المستهدف:** `path/to/file.ext`
- **الإجراء:** (شرح مختصر جداً للتعديل في سطر واحد)
- **الحالة:** تم التنفيذ / بانتظار التجربة

### 🖥️ مسار الواجهة وكيفية الاختبار اليدوي (UI Navigation & Manual Testing)
*(شرط إلزامي فقط عند تنفيذ إضافة أو تعديل فعلي في الواجهة)*
- **المسار في القائمة الجانبية (Sidebar):** [اسم القسم -> اسم الصفحة في القائمة]
- **الرابط المباشر (URL):** [المسار المباشر، مثل: `/crm/live-account-recovery?tab=mt5-bonus`]
- **التبويب والموضع الدقيق (Tab & Location):** [اسم التبويب إن وجد ومكان العنصر المعدل داخل الصفحة]
- **خطوات الاختبار بالبلدي خطوة بخطوة (Step-by-Step Test):**
  1. [ادخل على صفحة كذا من السايدبار أو الرابط]
  2. [افتح تبويب كذا أو انتقل للعنصر كذا]
  3. [اضغط على كذا أو اكتب كذا، وتأكد من حدوث النتيجة كذا]

> 📊 **تقرير ملخص الأيجنت**
> **الخلاصة المباشرة:**
>
> **ما تم إنجازه:** [ملخص مباشر وموجز جداً باللغة العربية حصراً لما تم تنفيذه]
> **الحالة والخطوة التالية:** [جاهز للتجربة / بانتظار المراجعة أو الموافقة]
