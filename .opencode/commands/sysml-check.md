---
description: Check SysML v2 files with the extension and fix the errors
agent: sysml
---
Check these SysML v2 files or folders: $ARGUMENTS (if empty, use `models`).

1. Call `sysml_check` with those paths. If it says the extension is not installed, run
   `sysml-validate <paths> --format compact` instead if it is on PATH; if neither exists, say so and stop.
2. For each error, read the file around the reported line, find the correct form in sysml-ref/CHEATSHEET.md,
   sysml-ref/EXTENSION.md (unit, electronics, software, requirement codes), sysml-ref/WIRING.md (`wiring-*` codes),
   sysml-ref/extension/guide/F-troubleshooting.md, or the matching example, and fix it with a minimal edit.
3. Re-run the same check; repeat until there are no errors (max 5 rounds).
4. Reply with: errors fixed, errors left (with the reason), warnings left (engineering warnings are design findings:
   list them), and which checker confirmed the result.
