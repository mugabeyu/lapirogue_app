---
description: "Fix a Dart or Flutter bug with root cause analysis and add or update regression tests"
name: "Dart Bugfix With Regression Test"
argument-hint: "Bug description, expected behavior, and constraints (example: crash on empty messages list)"
agent: "agent"
---
Fix a Dart or Flutter bug using the user-provided bug details.

Workflow:
- Reproduce or reason about the bug from the described scenario and local code context.
- Identify and explain the root cause before proposing the fix.
- Implement the smallest safe fix that preserves unrelated behavior.
- Add or update regression tests that fail before and pass after the fix.

Constraints:
- Keep public APIs unchanged unless required by the fix.
- Reuse existing architecture and patterns.
- Avoid broad refactors unless needed to fix the bug safely.

Validation:
- Run analyzer checks and relevant tests when possible.
- If execution is blocked, provide exact blockers and what was verified manually.

Response format:
1. Root cause
2. Code changes
3. Regression test changes
4. Validation results
5. Residual risks
