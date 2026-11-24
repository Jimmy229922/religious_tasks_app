---
trigger: always_on
---

# Code Integrity & Zero Refactoring
## Directives
- Strict Scope Isolation: Zero unsolicited refactoring, cosmetic reformatting, or logic alteration outside the explicit user request.
- Minimal Comments Policy: Avoid adding filler or "what" comments inside code files. Preserve existing docstrings/comments, and only add a brief comment in rare cases where non-obvious business logic ("why") would otherwise be unclear.
- Visual Assets & Custom Artwork Prompting: Whenever a UI redesign or new screen benefits from custom high-resolution illustrations, backgrounds, or emblems (matching the luxury Islamic gold/emerald aesthetic of the home dashboard), proactively provide the user with exact, ready-to-use image generation prompts (specifying aspect ratio and background transparency/readability zone) so the user can generate and supply the artwork for integration.
- Performance & Smoothness Guarantee (Zero Jank / Lag): Always ensure every modified or newly built screen remains lightweight and lag-free (60fps+): avoid expensive work inside `build()`, isolate periodic timers/animations with `RepaintBoundary` and `const` widgets, set `resizeToAvoidBottomInset: false` on heavy reader scaffolds when dialogs open keyboards, use lazy `ListView.builder`/`GridView.builder` for long lists, and avoid blocking the UI thread with synchronous heavy parsing or redundant rebuilds.
