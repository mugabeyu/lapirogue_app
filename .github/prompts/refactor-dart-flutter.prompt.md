---
description: "Refactor Dart or Flutter code in selection or active file with minimal behavior changes"
name: "Refactor Dart Flutter Code"
argument-hint: "Goal, constraints, and scope (example: extract reusable widget, keep APIs unchanged)"
agent: "agent"
---
Refactor Dart or Flutter code using the user-provided arguments as requirements.

Context to use:
- Prefer the current editor selection.
- If there is no selection, use the active Dart file.
- Follow existing project patterns, naming, and architecture.

Refactor requirements:
- Preserve runtime behavior unless the user explicitly requests behavior changes.
- Keep public APIs stable unless the user explicitly asks for API updates.
- Keep changes minimal and focused on the requested refactor goal.
- Prioritize readability and structure first, then maintainability and duplication reduction.
- Add brief comments only when logic is non-obvious.

Validation:
- Run Dart or Flutter analyzer checks and related tests for changed files when possible.
- If validation cannot run, state exactly what could not be run.

Response format:
1. What changed
2. Why this refactor
3. Verification results
4. Any follow-up options
