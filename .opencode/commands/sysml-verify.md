---
description: Verify the model's requirements and explain any that fail
agent: sysml
---
Verify the requirements in: $ARGUMENTS (if empty, use `models`).

1. `sysml_check` the same paths; fix errors first (max 5 rounds).
2. `sysml_verify` the paths. If any value in the model has `@Tolerance`, run it again with `worstCase`.
3. Report a table: ID, requirement, satisfied by, status (nominal and worst case), margin.
4. For every requirement that is `fail`: read its `require constraint` and the values it depends on, and say what
   drives the shortfall and which design changes would fix it (with the numbers from the model). Do not edit the
   requirement or the design unless the user asks.
5. For `unknown`: name the missing value (see sysml-ref/extension/guide/F-troubleshooting.md, "Values").
   For `unverified`: the requirement has no `satisfy` — say which element likely should satisfy it.
