---
description: Report what changed in the model between git revisions
agent: sysml
---
Report the model changes for: $ARGUMENTS (a git revision such as `HEAD`, `main` or `origin/main`, optionally a
second one; if empty, use `HEAD`, i.e. uncommitted changes).

1. Run `node tools/sysml.mjs diff <revisions> --out docs/model/changes.md -- models` (the project must be a git repo).
2. Read docs/model/changes.md and summarize: elements added, removed and changed, and computed values that changed
   (margins, budgets). Call out changes that affect requirements, interfaces or generated code
   (then suggest `/sysml-verify` or `/sysml-gen`).
