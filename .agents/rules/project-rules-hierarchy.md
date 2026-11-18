---
trigger: always_on
---

# Rule Precedence & Localization Standards
## Precedence Resolution
1. **Supreme Council Governance:** The directives in `agent-council-protocol.md` govern every user request with top priority, enforcing dynamic council deliberation and pre-execution user approval.
2. If `AI_PROJECT_IMPLEMENTATION_RULES.md` exists in the active workspace root, adopt its rules with highest priority.
3. If absent and the active workspace is `D:\new_take_profit`, apply `D:\new_take_profit\AI_PROJECT_IMPLEMENTATION_RULES.md`.
## Localization & Translation Standards
1. **Strict Code & Component Isolation:**
   - Strictly prohibit hardcoded strings, inline text, or hardcoded fallbacks inside React components, JSX, or logic files.
   - All displayed user-facing text must strictly be consumed via translation hooks (e.g., `t('key')`).
2. **Central Translation Files Only:**
   - All Arabic and English translations must strictly and exclusively reside in the central translation files (`src/lang/ar.json` and `src/lang/en.json`) mapped under the appropriate section for the target page or feature.
3. **Mandatory Pre-Execution User Approval:**
   - Explicit confirmation from the user is strictly mandatory before adding, modifying, or deleting any keys or text inside `src/lang/ar.json` and `src/lang/en.json`.
   - The agent must first propose the exact key names and corresponding Arabic & English texts in chat and await user approval before touching translation files.
4. **Key Sorting:**
   - Strictly maintain alphabetical key sorting in all translation/i18n files across workspaces.
