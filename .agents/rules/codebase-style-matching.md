---
trigger: always_on
---

# Codebase Style & Architectural Alignment

## Directives
### 1. Dynamic Contextual Reference Mining & Broad Project Synthesis
Before writing or altering any code:
- Strictly avoid being restricted to fixed, predetermined, or hardcoded file lists.
- Dynamically analyze the required modification, and search across the entire project for files that contain identical, similar, or analogous features, components, or logic.
- Broad Project Inspection Trigger: Whenever the user requests reviewing or inspecting the whole project (e.g., "شوف ملفات المشروع كلها" / "افحص المشروع كامل"), strictly avoid limiting inspection to 1 or 2 files. The agent must thoroughly inspect a wide range of project files across multiple modules to synthesize how that requirement is implemented system-wide.
- **Cross-Module Reference Isolation (عزل المراجع ومنع المرجعية الذاتية للموديول):**
  - يُحظر تماماً وبشكل قاطع عبر كامل المشروع مراجعة أو الاستشهاد بأي ملف ينتمي لنفس الصفحة أو القسم أو الموديول الجاري تعديله حالياً (أياً كان نوع الصفحة أو مكانها).
  - يجب أن تكون ملفات المراجعة والمطابقة مفتوحة ومستخرجة حصراً من باقي صفحات وموديولات المشروع ككل في أي مكان آخر بالكامل، لضمان استخلاص المعايير العامة والأسلوب القياسي الشامل للمشروع ومنع أي انحياز أو تكرار لخلل محلي خاص بنطاق التعديل.
- Extract canonical, human-authored patterns from those matching external files: naming conventions, defensive checks (`Array.isArray`, optional chaining, fallback defaults), state paradigms, and Tailwind classes.

### 2. Strict Pattern Replication & Management Review Alignment
Seamlessly replicate the exact conventions of senior human developers in the project:
- Component architecture, hooks usage, and error handling flows.
- State management and API integration standards.
- Styling and dark theme tokens matching the target module (`slate-950`/`slate-900`/`slate-800`, or module-specific dark tokens like `#131826`/`#1e2542`/`#2A3157` where established).
- Consensus Architecture: Replicate the shared stylistic consensus of the human development team so that management reviews pass immediately with zero friction, zero structural drift, and zero indication of different or AI-authored implementations.
- Strictly zero AI artifacts, zero unsolicited refactoring, zero added comments.

### 3. Post-Modification Architectural Alignment Audit
Immediately after completing any code change and BEFORE declaring completion:
- Perform an explicit comparison against the dynamically discovered similar files across external modules in the codebase (حصراً من موديولات أخرى مستقلة تماماً عن الموديول الجاري تعديله) to verify that the newly written code exactly matches their syntax, structure, and defensive idioms.
- Verify that the code looks 100% human-authored by the original development team to guarantee immediate pass during management PR review.

### 4. Mandatory Reference Disclosure & Parity Percentage
In every response involving code modifications, explicitly include the dedicated reference section right before the summary report:
- Cite the relevant project files that were dynamically matched and compared against (strictly from external modules outside the modified module).
- Explicitly declare the exact Architectural Parity Percentage with the main project (نسبة المطابقة مع المشروع الأساسي: e.g., 100%), confirming that the change—even if only a single line—strictly conforms to the project's human conventions and architecture.

## Constraint
All additions and modifications must strictly match existing project conventions to ensure immediate pass during management PR review. Introducing foreign architectural patterns, unconventional syntax, or AI hallmarks is strictly prohibited.
