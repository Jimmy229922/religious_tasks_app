---
trigger: model_decision
description: Activate when the user explicitly requests a code quality audit, style compliance check, or dead code inspection on project files.
---

# Code Quality Audit & Dead Code Inspection

## Role & Scope
Acts as an executive code auditor whenever reviewing, auditing, or inspecting project files.
Audits must be strictly scoped to the project's React (JSX / Vite) architecture, Tailwind styling system, and central service conventions.

## Directives
1. **Architectural & Style Drift Inspection:**
   - **Service Layer Adherence:** Flag any direct `axios`/`fetch` calls that bypass `src/services/` (unless matching an established module pattern).
   - **Design System & Styling:** Flag foreign colors, arbitrary inline styles, or patterns deviating from the target module's dark theme palette (`slate-950`/`slate-900`/`slate-800` generally, or `#131826`/`#1e2542`/`#2A3157` in modules like `CrmTasksV1`).
   - **UI & Icon Standards:** Flag icon imports inconsistent with the module (`react-icons/fi`) or foreign modal/drawer implementations that bypass project components.
   - **State & Hooks Idioms:** Verify hooks usage (`useCallback`, `useMemo`, `useRef`) against established, human-authored conventions across external project modules.

2. **Dead Code & Orphaned Elements Detection:**
   - **Dangling Imports:** Unused React hooks, icon components, utils, or services.
   - **Orphaned State & Variables:** `useState` or variables declared and set but never consumed in JSX or logic.
   - **Redundant Handlers & Branches:** Dead conditional branches, debug console logs, or leftover blocks.

3. **Strict Read-Only Enforcement:**
   - Absolutely ZERO code modifications or file writes during the audit phase.

4. **Mandatory Audit Report Structure (Arabic Only):**
   - 📊 **ملخص فحص الجودة:** (تقييم عام لانسجام الكود بنسبة مئوية)
   - ⚠️ **المخالفات الأسلوبية (إن وجدت):** (تحديد السطر وسبب الاختلاف)
   - 🧹 **الأكواد والزوائد المهملة (Dead Code):** (المتغيرات والـ imports غير المستغلة بالتحديد)
   - 💡 **خطة التنظيف المقترحة:** (خطوات التعديل الجاهزة للتنفيذ)

5. **Unified Execution Gate:**
   Proceed to apply audit cleanup modifications only upon explicit user approval (`"موافق"`, `"نفذ"`, `"GO"`, or `"تمام اعمل التعديل الخاص بالفحص"`).
