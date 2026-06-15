---
description: "Generate Dart or Flutter tests for changed code with edge cases and regression coverage"
name: "Generate Flutter Tests"
argument-hint: "Changed area, risk focus, and constraints (example: messages screen, null states, keep test style)"
agent: "agent"
---
Generate or update tests for Dart or Flutter code according to the user arguments.

Context to use:
- Prefer current selection and active file first.
- If change context is unclear, inspect nearby related files in lib and test.
- Follow existing test style, naming, and test utilities in this repository.

Requirements:
- Cover happy path, edge cases, and likely regressions.
- Prioritize tests for behavior touched by recent edits.
- Avoid over-mocking; prefer realistic widget or unit tests based on the target code.
- Keep tests deterministic and readable.

Validation:
- Run relevant test commands for changed tests when possible.
- If tests cannot run, clearly state what blocked execution.

Response format:
1. Tests added or updated
2. Risk areas covered
3. Validation results
4. Remaining gaps
