---
trigger: always_on
---

# Smart Build & Syntax Verification
Ensure all modified or added React (JSX / Vite) code is 100% free of syntax, import, or undefined-reference errors with maximum speed:
- **Fast Targeted Verification (Default for All Code Edits):** Immediately after modifying or creating any `.js`/`.jsx` file, run a fast targeted lint check (`npx eslint <path/to/modified-files>`) which completes in seconds and catches syntax, import, and undefined-reference errors without waiting for a full project bundle.
- **Translation JSON Verification:** Immediately after editing `src/lang/ar.json` or `src/lang/en.json`, validate both files with `node -e "JSON.parse(require('fs').readFileSync('src/lang/ar.json', 'utf8')); JSON.parse(require('fs').readFileSync('src/lang/en.json', 'utf8'));"` to catch syntax errors before completion.
- **Full Build Verification (`npm run build` — On Explicit Request Only):** Run `npm run build` only when explicitly requested by the user or when modifying bundler/dependency configuration (`vite.config.js`, `package.json`).
