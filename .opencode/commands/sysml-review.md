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
   boolean operators, requirements without doc/subject.
5. Fix the problems in the file with minimal edits.
6. If `sysml-validate` is on PATH, run `sysml-validate $ARGUMENTS --format compact` and fix remaining errors
   (max 5 rounds).
7. Reply with: number of issues fixed, any you could not fix, and whether a validator confirmed the result.
