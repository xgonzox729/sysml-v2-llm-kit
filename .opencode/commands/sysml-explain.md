---
description: Explain the system modeled in this project in plain English
agent: sysml
---
Explain the system modeled in: $ARGUMENTS (if empty, use `models`). Do not edit any file.

1. List the model files and read their package `doc` comments. Use `sysml_query` to collect: part defs and the
   system usages (`--kind part`), ports and interfaces (`--kind "port def"`, `--kind "interface def"`), requirements
   (`--kind requirement`), behaviors (`--kind "state def"`, `--kind "action def"`).
2. `sysml_check` and `sysml_verify` the paths (report, do not fix).
3. Write a short overview: purpose, structure (main parts and what they connect to), interfaces and what flows through
   them, behavior, requirements with status and margin, open issues (errors, failing/unknown requirements, warnings),
   and which files hold what. Name elements by qualified name so the user can find them (F12 in VS Code).
