---
description: Review a .sysml file against the SysML v2 references and fix errors
agent: sysml
---
Review the SysML v2 file: $ARGUMENTS

Do this in order:
1. Read the file fully.
2. List every construct type it uses (part def, port, interface, flow, action, state, requirement, ...).
3. For each construct type, compare the file's syntax with sysml-ref/CHEATSHEET.md. For any construct not in the
   cheat sheet, open the matching official example listed in sysml-ref/EXAMPLES_INDEX.md and compare.
4. Write a numbered list of concrete problems: line, what is wrong, the correct form. Include SysML v1/UML leftovers,
   wrong relationship symbols (`:` vs `:>` vs `:>>`), missing imports, undeclared names, missing `;`, unit syntax,
   boolean operators, requirements without doc/subject. For wiring models, also check against sysml-ref/WIRING.md; for units, electronics, software or requirements, sysml-ref/EXTENSION.md. Missing `doc` on packages, definitions and requirements counts as a problem (documents are generated from it).
5. Fix the problems in the file with minimal edits.
6. Validate as AGENTS.md step 7 says: call `sysml_check` on $ARGUMENTS (falls back to
   `sysml-validate $ARGUMENTS --format compact` if the extension is not installed), and fix remaining errors
   (max 5 rounds). If the file has requirements, run `sysml_verify` and list each requirement's status and margin.
7. Reply with: number of issues fixed, any you could not fix, requirement status if verified, and whether a checker confirmed the result.
