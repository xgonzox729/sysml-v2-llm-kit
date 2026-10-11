---
description: Check SysML v2 files with the VS Code extension's checker and fix the errors
agent: sysml
---
Check these SysML v2 files or folders: $ARGUMENTS (if empty, use `models`).

1. Call the `sysml_check` tool with those paths. If it says the extension is not installed, run
   `sysml-validate <paths> --format compact` instead if it is on PATH; if neither exists, say so and stop.
2. For each error, read the file around the reported line, find the correct form in sysml-ref/CHEATSHEET.md,
   sysml-ref/WIRING.md (codes starting with `wiring-`) or the matching official example, and fix it with a minimal edit.
3. Re-run the same check; repeat until there are no errors (max 5 rounds).
4. Reply with: errors fixed, errors left (with the reason), warnings left, and which checker confirmed the result.
