# SysML v2 modeling project

You help the user model, implement and document their system in **SysML v2 textual notation** (OMG SysML 2.0,
formally adopted 2025), using the SysML v2 VS Code extension to check, verify, simulate, generate code and documents.
Your training data contains very little SysML v2 and a lot of SysML v1/UML. Assume your memory of the syntax is wrong
unless it matches `sysml-ref/CHEATSHEET.md` (already loaded in your context) or a reference file.

## Where files go
- User models: `models/` (create it if missing), unless the user names another path. Generated documents: `docs/model/`.
  Generated code: `generated/`.
- Never create or edit files inside `sysml-ref/` — it is read-only reference material.
- Never hand-edit generated documents or code; change the model and regenerate. Exception: `*_actions.c` stubs in
  `generated/` belong to the user (they are written only once).

## Project layout (one system, many files)
- One file per concern, one top-level package per file, named alike: `models/<system>-<concern>.sysml` → package
  `<System><Concern>` (e.g. `node-parts.sysml` → `NodeParts`; also `-architecture`, `-requirements`, `-behavior`,
  `-software`, `-icd`, `-analysis`, `-harness`, `-variants`, `-views`).
- Definitions in parts files; the system usage (`part node : Node { … }`) in the architecture file.
- `private import` between files, layered one way: parts ← architecture ← requirements / software / analysis.
- Requirement ids as short names (`requirement def <'PWR-1'> Lifetime`); the requirement text is its `doc`.
- `doc /* … */` on every package, definition and requirement: the generated documents are built from it.
- Small single-file models are fine when the user asks for one.

## Reference files (read on demand with your Read/Grep tools)
- `sysml-ref/CHEATSHEET.md` — always-loaded syntax rules and correct patterns. Section 11 lists forbidden v1 syntax.
- `sysml-ref/EXAMPLES_INDEX.md` — maps each construct and task to reference files. Read it, then read only the 1–3 matching files.
- `sysml-ref/examples/**.sysml` — 100 official OMG examples. Copy their syntax exactly.
- `sysml-ref/GoldExample_BatteryCharger.sysml` — one validated end-to-end model.
- `sysml-ref/EXTENSION.md` — units, power trees, tolerances, analyses, firmware budgets, message formats, checkable
  requirements, code and document generation with the extension's libraries. Points into `sysml-ref/extension/`
  (the extension's guide, libraries, and the multi-file EnviroNode example).
- `sysml-ref/WIRING.md` — connectors, pins, wires and harnesses with the `Wiring` library.
- `sysml-ref/grammar/SysML-textual-bnf.kebnf` — the official grammar. NEVER read it whole (it is huge). Grep it for one rule name or keyword, e.g. `grep -n "^TransitionUsage" -A12`.

## Tools (SysML v2 extension, via `sysml-sim`)
In OpenCode call the tools; elsewhere run the command (same results). Pass model files or the `models` folder —
never the project root or `sysml-ref/`.

| Tool | Command | Use it to |
|---|---|---|
| `sysml_check` | `node tools/sysml-check.mjs <paths>` | find syntax, name, unit and engineering-check errors |
| `sysml_verify` | `node tools/sysml.mjs verify <paths> [--worst-case]` | requirement pass/fail with margins |
| `sysml_query` | `node tools/sysml.mjs query <paths> --kind … --name …` | locate elements in an existing model |
| `sysml_analyze` | `node tools/sysml.mjs analyze <paths>` | run analyses, sweeps, trade studies |
| `sysml_simulate` | `node tools/sysml.mjs simulate <file> …` | step a state machine / action flow, coverage, timeline |
| `sysml_docs` | `node tools/sysml.mjs docs <paths> --out docs/model --merge` | requirements spec, ICD, verification report, BOM, traceability |
| `sysml_gen` | `node tools/sysml.mjs gen <paths> --out generated` | C types/JSON Schema/protobuf, register headers, variant configs, state machines |
| — | `node tools/sysml.mjs diff <rev> --out docs/model/changes.md -- models` | semantic change report between git revisions |

Exit code 3 (or a tool saying the extension is not available) means the extension is not installed: say so once,
fall back as step 7 says, and do not invent results the tools would have computed.

## Workflow for every modeling request
1. **Understand what exists.** If `models/` has files, read the ones involved (and what they import) before planning;
   use `sysml_query` to find where an element is defined. Keep existing names, ids and file layout.
2. **Clarify.** If the system, scope, or level of detail is unclear, ask up to 3 short questions before writing.
3. **Plan in plain English first** (short bullet list, no SysML yet):
   - structure: part defs, their parts, attributes (with units), ports and what flows through them;
   - behavior: actions and their order, or states and their transitions (source → trigger → guard → effect → target);
   - requirements: id, text, subject, the measurable condition, and which part satisfies it;
   - which file each change goes in.
4. **Look up before writing.** For each construct type in the plan that you have not already used in this session, check the cheat sheet; if it is not there, open the matching reference from the index. For units, power, tolerances, firmware, message formats or checkable requirements read `sysml-ref/EXTENSION.md`; for wiring read `sysml-ref/WIRING.md`.
5. **Write the file(s).** Definitions (`part def`, `port def`, …) first, then usages and configurations, then `satisfy`/`allocate`. One top-level `package` per file, named like the file.
6. **Self-check** (do not skip) — re-read what you wrote and check each item:
   - [ ] every statement ends with `;` or a `{ }` body, never both; braces balanced
   - [ ] no SysML v1 / UML words: block, value, property, valueType, flowPort, stereotypes `<< >>`, `->` arrows, `[guard]/effect`
   - [ ] definitions specialize with `:>` (never `:`); usages are typed with `:`; inherited values are set with `:>>`
   - [ ] every name used is declared in this file or imported (`private import X::*;`); library types come from `ScalarValues`, `ISQ`, `SI`, `EngineeringUnits` (and `Electronics`, `Simulation`, `Software`, `Registers`, `Wiring` when used)
   - [ ] numbers with units use `value [unit]` (e.g. `12 [V]`, `1.5 ['µA']`); booleans use `and/or/not`, never `&& || !`
   - [ ] names with spaces use single quotes; strings use double quotes; keywords are not used as names
   - [ ] constraint bodies end with an expression and no `;`
   - [ ] every requirement has `doc /* text */`, a typed `subject`, a `require constraint` when it is measurable, and a `satisfy`
   - [ ] connections use `connect A to B;`, flows use `flow ... from A to B;` or `flow A to B;`
   Fix anything that fails, then state in one line which checks you ran.
7. **Validate.** Use the first checker that is available:
   1. `sysml_check` on the files you changed (or `models`). Fix every `error`; rerun until clean (max 5 rounds).
      Warnings with engineering codes (`rail-*`, `derating`, `wiring-*`, `deadline-miss`, …) are design findings: fix
      them when they are modeling mistakes, otherwise report them.
   2. Extension not installed: `sysml-validate <changed files> --format compact`, if it is on PATH (it does not know
      the extension's libraries).
   3. Neither available: say so in one line and rely on step 6.
8. **Verify requirements** when the model has requirements: `sysml_verify` (add `worstCase` when values carry
   `@Tolerance`). Report each requirement's status and margin. A failing or unknown requirement is a result for the
   user: explain why, and propose design changes. Never weaken or delete a requirement to make it pass unless asked.

## Implementing the system (when the user asks for code)
- Model what the code needs first: message formats with `@Encoding`, register maps with `Registers`, variants with
  `@Config`, state machines with `entry; then …` and transitions. See `sysml-ref/EXTENSION.md` and guide chapter 20.
- `sysml_check`, then `sysml_gen` into `generated/`. Report the files written. `sysml_gen` with `check` tells whether
  `generated/` is out of date with the model.
- Link hand-written code and tests back to the model with `@Implements { file; symbol; }` and
  `@VerifiedBy { file; test; }` (paths relative to the model file).

## Documenting the system (when the user asks for documents or a review)
- Make sure every package, definition and requirement has a `doc`, ids are short names, and requirements are satisfied.
- `sysml_check`, `sysml_verify`, then `sysml_docs` into `docs/model/`: `requirements.md`, `icd.md`,
  `verification.md`, `bom.md`, `traceability.md`. Summarize what they say (open requirements, failing margins,
  missing traceability) instead of pasting them.
- Diagrams come from the VS Code extension (General, Interconnection, Action flow, State machine views; export SVG/PNG).
  Suggest the view that fits; you cannot render them yourself.
- For "what changed": `node tools/sysml.mjs diff <rev> --out docs/model/changes.md -- models`.

## Editing existing models
- Read the whole target file (and files it imports) before changing it. Keep existing names and IDs.
- Make the smallest change that does the job; do not reformat untouched code.
- When adding to a definition that others specialize, check usages for needed `:>>` redefinitions.

## Modeling conventions
- Definitions: `UpperCamelCase`. Usages/attributes: `lowerCamelCase`. Requirement IDs: short names like `<'PWR-1'>`.
- Prefer ISQ quantity types (`MassValue`, `ElectricCurrentValue`, `ElectricPotentialValue`, `PowerValue`, `DurationValue`, …) over bare `Real` for physical values.
- Model what was asked. Do not invent extra subsystems, requirements, or numbers; if a value is unknown, declare the attribute without a value and say so.
- Never claim a model is "valid" or a requirement "met" unless a tool said so. Say "self-checked" otherwise.
