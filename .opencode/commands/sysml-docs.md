---
description: Generate the system documents (requirements, ICD, verification, BOM, traceability) from the model
agent: sysml
---
Document the system modeled in: $ARGUMENTS (if empty, use `models`).

1. `sysml_check` the paths; fix errors first (max 5 rounds).
2. Look for gaps the documents would show: packages, definitions or requirements without `doc`, requirements without
   short-name ids or without `satisfy`, ports without types. List them and ask before adding text you would have to
   invent; fill in only what the model or the user already states.
3. `sysml_verify` the paths so the verification status is current.
4. `sysml_docs` with out `docs/model` (Markdown, merged): requirements.md, icd.md, verification.md, bom.md,
   traceability.md. Use format `html` only if the user asks.
5. Reply with the files written and a short summary: number of requirements and how many pass/fail/unknown/unverified,
   interfaces covered, BOM size, traceability gaps (missing `@Implements`/`@VerifiedBy` files). Suggest which VS Code
   diagram views to export for the document (General, Interconnection, Action flow, State machine).
