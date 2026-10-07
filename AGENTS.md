# SysML v2 modeling project

You help write and edit `.sysml` files in **SysML v2 textual notation** (OMG SysML 2.0, formally adopted 2025).
Your training data contains very little SysML v2 and a lot of SysML v1/UML. Assume your memory of the syntax is wrong
unless it matches `sysml-ref/CHEATSHEET.md` (already loaded in your context) or an official example file.

## Reference files (read on demand with your Read/Grep tools)
- `sysml-ref/CHEATSHEET.md` — always-loaded syntax rules and correct patterns. Section 11 lists forbidden v1 syntax.
- `sysml-ref/EXAMPLES_INDEX.md` — maps each construct to official example files. Read it, then read only the 1–3 matching examples.
- `sysml-ref/examples/**.sysml` — 100 official OMG examples. Copy their syntax exactly.
- `sysml-ref/GoldExample_BatteryCharger.sysml` — one validated end-to-end model.
- `sysml-ref/grammar/SysML-textual-bnf.kebnf` — the official grammar. NEVER read it whole (it is huge). Grep it for one rule name or keyword, e.g. `grep -n "^TransitionUsage" -A12`.

## Workflow for every modeling request
1. **Clarify.** If the system, scope, or level of detail is unclear, ask up to 3 short questions before writing.
2. **Plan in plain English first** (short bullet list, no SysML yet):
   - structure: part defs, their parts, attributes (with units), ports and what flows through them;
   - behavior: actions and their order, or states and their transitions (source → trigger → guard → effect → target);
   - requirements: id, text, subject, the measurable condition, and which part satisfies it.
3. **Look up before writing.** For each construct type in the plan that you have not already used in this session, check the cheat sheet; if it is not there, open the matching official example from the index.
4. **Write the file.** Definitions (`part def`, `port def`, …) first, then usages and configurations, then `satisfy`/`allocate`. One top-level `package` per file, named like the file.
5. **Verify** (do not skip) — re-read what you wrote and check each item:
   - [ ] every statement ends with `;` or a `{ }` body, never both; braces balanced
   - [ ] no SysML v1 / UML words: block, value, property, valueType, flowPort, stereotypes `<< >>`, `->` arrows, `[guard]/effect`
   - [ ] definitions specialize with `:>` (never `:`); usages are typed with `:`; overrides use `:>>` or `redefines`
   - [ ] every name used is declared in this file or imported (`private import X::*;`); library types come from `ScalarValues`, `ISQ`, `SI`
   - [ ] numbers with units use `value [unit]` (e.g. `12 [V]`); booleans use `and/or/not`, never `&& || !`
   - [ ] names with spaces use single quotes; strings use double quotes
   - [ ] constraint bodies end with an expression and no `;`
   - [ ] every requirement has `doc /* text */`, a `subject`, and a `require constraint` when it is measurable
   - [ ] connections use `connect A to B;`, flows use `flow ... from A to B;` or `flow A to B;`
   Fix anything that fails, then state in one line which checks you ran.
6. **Validate if a validator exists.** If `sysml-validate` is on PATH, run `sysml-validate <file> --format compact`, fix every `error`, rerun until clean (max 5 rounds). Warnings are optional. If it is not installed, say so in one line and rely on step 5.

## Editing existing models
- Read the whole target file (and files it imports) before changing it. Keep existing names and IDs.
- Make the smallest change that does the job; do not reformat untouched code.
- When adding to a definition that others specialize, check usages for needed `:>>` redefinitions.

## Modeling conventions
- Definitions: `UpperCamelCase`. Usages/attributes: `lowerCamelCase`. Requirement IDs: `<'REQ-x.y'>`.
- Prefer ISQ quantity types (`MassValue`, `ElectricCurrentValue`, `ElectricPotentialDifferenceValue`, `PowerValue`, …) over bare `Real` for physical values.
- Model what was asked. Do not invent extra subsystems, requirements, or numbers; if a value is unknown, declare the attribute without a value and say so.
- Never claim a model is "valid" unless a validator said so. Say "self-checked" otherwise.
