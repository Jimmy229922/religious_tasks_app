---
trigger: model_decision
description: Activate when modifying or creating page backgrounds, full-page themes, layouts, sidebars, split-pane headers, or UI components.
---

# UI Layout, Edge-to-Edge Backgrounds & RTL/LTR Precision

## Mandatory Visual & Structural Checklist (First-Shot Accuracy)
Whenever altering page colors, themes, containers, or UI layouts, verify all 3 pillars BEFORE delivering code:

1. **Parent `Layout.jsx` (`#detail`) Perimeter & Scrollbar Harmony:**
   - When changing a page's outer background color (e.g., `#0a0f17`, `#0E1529`, `#0f172a`), always inspect `src/routers/layout/Layout.jsx` (`#detail` container) to ensure the route pathname is included in the `mx-0` and matching `bg-[...]` conditions so legacy `#13181F` (`sm:px-4`) side strips never appear on the edges.
   - Never nest `h-screen` inside `#detail` (`h-screen`) without `overflow-hidden` on `#detail`; use `h-full` on inner full-page workspaces to prevent double vertical scrollbars.

2. **Split-Pane Border & Header Line Alignment:**
   - In multi-column layouts (e.g., Sidebar + Main Panel), verify that adjacent containers share complete outer borders (`border` + `border-s-0` or shared divider) and that adjacent top header sections share an identical height (`h-[...]` / `min-h-[...]`) so top and bottom `border-b` lines align on a single unbroken horizontal axis.
   - Preserve hover (`hover:bg-gray-800` / `hover:bg-white/[0.06]`) and divider (`border-gray-800`) contrast when darkening card or modal surfaces, and ensure dark modals have a visible `border` (`border-gray-700` or `border-white/[0.08]`).

3. **Bidirectional (`RTL` / `LTR`) Integrity:**
   - Enforce `dir-ltr` and `font-mono` on technical values (IP addresses, timestamps, emails, account numbers, MQIDs) so Arabic (`RTL`) never reverses digits or punctuation.
   - Prefer logical properties (`ms-`, `me-`, `ps-`, `pe-`, `border-s`, `border-e`, `rounded-s`, `rounded-e`, `text-start`, `text-end`) and verify both `ar` and `en` layouts remain symmetrical.

4. **Full-Height Vertical Expansion on Zoom-Out (`flex-1` Parent/Child Rule):**
   - When an element or main page section fails to stretch vertically to fill remaining viewport height (especially visible when zooming out), the parent container must use `flex flex-col flex-1` (with `min-h-0` where internal scrolling is needed) and the expanding child must use `flex-1` (avoiding fixed `height` on the child when vertical stretching is expected).
   - **Proactive Detection & Approval Gate:** While working in any page or module, if this vertical-gap / zoom-out height issue is spotted, proactively flag it to the user with a plain-Arabic explanation, and **never** apply the layout fix without explicit user approval first.

