---
description: Generate implementation code from the model (types, registers, variants, state machines)
agent: sysml
---
Generate code from: $ARGUMENTS (if empty, use `models`).

1. `sysml_check` the paths; fix errors first (max 5 rounds).
2. Read sysml-ref/EXTENSION.md ("message format", "Rules") and say which targets the model supports: `types`
   (`@Encoding` on items/attributes), `registers` (`Registers` library), `variants` (variation + `@Config`),
   `state-machines` (state defs). If the user wants code for something the model does not describe yet, propose the
   model change first.
3. `sysml_gen` with out `generated` (and the targets the user asked for). Report generator issues and fix the model
   for each (e.g. `@Encoding` `bits` must be 8/16/32/64; quantities sent as integers need `scale`).
4. Reply with the files written, which ones the user owns (`*_actions.c` stubs, written once), and how to link their
   code back: `@Implements { file; symbol; }` / `@VerifiedBy { file; test; }`.
