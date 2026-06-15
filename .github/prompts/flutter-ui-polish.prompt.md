---
description: "Polish Flutter UI for spacing, typography, and responsive behavior while preserving existing design language"
name: "Flutter UI Polish"
argument-hint: "Screen, visual issues, and constraints (example: messages screen, tighten spacing, mobile-first)"
agent: "agent"
---
Polish a Flutter UI screen or component based on the user arguments.

Context to use:
- Start from current selection and active file.
- Reuse existing theme tokens, widgets, and layout patterns from the project.
- Keep consistency with current design language unless the user requests a new direction.

Polish goals:
- Improve spacing rhythm, visual hierarchy, and readability.
- Refine typography scale and alignment using project theme values.
- Improve responsive behavior for common phone widths and larger layouts.
- Keep interactions and behavior unchanged unless explicitly requested.

Implementation constraints:
- Make minimal, focused edits.
- Prefer reusable widgets when duplication appears.
- Preserve accessibility semantics and touch target usability.

Validation:
- Run analyzer checks for changed files when possible.
- If available, run relevant widget tests or note missing test coverage.

Response format:
1. UI improvements made
2. Why these changes improve UX
3. Validation results
4. Optional next visual refinements
