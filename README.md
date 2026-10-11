# SysML v2 kit for OpenCode (any LLM)

Helps an LLM in [OpenCode](https://opencode.ai) model, implement and document your system in SysML v2. It puts the
right reference material in front of the model at the right time, instead of trusting its (mostly SysML v1) training
data, and gives it the [SysML v2 VS Code extension](https://github.com/xgonzox729/sysmlextension)'s tools: check,
verify requirements, analyze, simulate, generate code and generate documents. It works with whatever model you
select in OpenCode, local or hosted.

## What's inside
| File | Loaded | Purpose |
|---|---|---|
| `AGENTS.md` | always (OpenCode) | role, project layout, workflow (understand → plan → look up → write → check → verify), implement and document steps |
| `sysml-ref/CHEATSHEET.md` | always (via `opencode.json`) | ~5K tokens of parse-checked patterns + v1→v2 error table |
| `sysml-ref/EXAMPLES_INDEX.md` | on demand | maps each construct and task to reference files |
| `sysml-ref/examples/` | on demand | the 100 official OMG training models (EPL-2.0) |
| `sysml-ref/grammar/` | grep only | official KerML/SysML textual BNF |
| `sysml-ref/GoldExample_BatteryCharger.sysml` | on demand | one validated end-to-end model |
| `sysml-ref/EXTENSION.md` | on demand | units, power trees, tolerances, firmware budgets, message formats, checkable requirements, code and documents |
| `sysml-ref/WIRING.md` | on demand | connectors, pins, wires and harnesses |
| `sysml-ref/extension/` | on demand | from the extension: its modeling guide, libraries, the multi-file EnviroNode example, small examples |
| `.opencode/agents/sysml.md` | select with Tab | agent with the hard rules; uses the model you have selected |
| `.opencode/tools/sysml.ts` | tools | `sysml_check`, `sysml_verify`, `sysml_query`, `sysml_analyze`, `sysml_simulate`, `sysml_docs`, `sysml_gen` |
| `.opencode/commands/` | slash commands | `/sysml-check`, `/sysml-review`, `/sysml-verify`, `/sysml-explain`, `/sysml-docs`, `/sysml-gen`, `/sysml-diff` |
| `tools/sysml.mjs` | you / the tools | runs the extension's `sysml-sim` CLI wherever the extension is installed |
| `tools/sysml-check.mjs` | you / the tools | `sysml-sim check`, with a language-server fallback for older extension versions |
| `opencode.json` | always | loads the cheat sheet; `sysml-ref/` and generated output are read-only for the agent |
| `.vscode/extensions.json` | VS Code | recommends the SysML v2 extension |
| `tests/eval-prompts.md` | you | 10 prompts to compare models and settings |

## Setup
1. Copy everything into the root of your own SysML project folder — **not** a clone of this public repo, or your models could end up pushed publicly. Your models go in `models/`, generated documents in `docs/model/`, generated code in `generated/`. This repo's `.gitignore` excludes those folders as a safety net — delete those lines in your own project's copy so they get committed there.
2. Install the [SysML v2 VS Code extension](https://github.com/xgonzox729/sysmlextension) (see [below](#using-with-the-sysml-v2-vs-code-extension)) and Node.js 20+. Check with `node tools/sysml.mjs --probe`.
3. Open OpenCode in the project, pick any model with `/models`, switch to the `sysml` agent with Tab, and describe your system — or start with `/sysml-explain` on an existing model.

The model needs tool calling. See [Model notes](#model-notes) for context sizes and per-model settings.

## Working on your system
| You want to… | Ask, or run | What happens |
|---|---|---|
| model something new or change the model | describe it | the agent plans, writes `models/<system>-<concern>.sysml`, runs `sysml_check` until clean, then `sysml_verify` |
| understand an existing model | `/sysml-explain` | structure, interfaces, behavior, requirement status, open issues — no edits |
| fix errors | `/sysml-check [path]` | check and fix loop |
| review a file | `/sysml-review models/x.sysml` | checklist review against the references, fixes, verification |
| know whether requirements are met | `/sysml-verify` | status and margin per requirement (worst case with tolerances), why failures fail |
| document the system | `/sysml-docs` | fills `doc` gaps (asking first), then `docs/model/requirements.md`, `icd.md`, `verification.md`, `bom.md`, `traceability.md` |
| implement it | `/sysml-gen` | C types + JSON Schema + protobuf from message formats, register headers, variant configs, C state machines in `generated/` |
| see what changed | `/sysml-diff main` | semantic model diff with changed computed values → `docs/model/changes.md` |

The agent follows the extension guide's project layout: one file per concern (`node-parts.sysml` → `NodeParts`,
`node-architecture.sysml`, `node-requirements.sysml`, …), private layered imports, requirement ids as short names
(`<'PWR-1'>`), and `doc` on everything — the generated documents are built from it. See
`sysml-ref/extension/example/sensor-node/model/` for a complete example.

## The tools
Everything goes through the extension's `sysml-sim` CLI, which ships inside the installed extension
(`<extension>/out/cli/sysml-sim.cjs`). You can run the same commands yourself:
```
node tools/sysml.mjs --probe                                  # where is the extension?
node tools/sysml-check.mjs models [--errors-only]             # syntax, names, units, engineering checks
node tools/sysml.mjs verify models [--worst-case] [--format junit --out reports/requirements.xml]
node tools/sysml.mjs query models --kind "part def" --name "*Battery*"
node tools/sysml.mjs analyze models
node tools/sysml.mjs simulate models/node-behavior.sysml --coverage
node tools/sysml.mjs docs models --out docs/model --merge     # one set of documents for the whole model
node tools/sysml.mjs gen models --out generated [--target types,registers,variants,state-machines] [--check]
node tools/sysml.mjs diff main --out docs/model/changes.md -- models
```
- Output of `check` is one line per problem, `models/x.sysml:12:5: error: <message> [code]`, then a summary.
- Exit codes: 0 ok, 1 a check, requirement or assertion failed, 2 usage or load error, 3 extension not found.
- The extension is found in `~/.vscode`, `~/.vscode-insiders`, `~/.cursor`, `~/.windsurf`, `~/.vscode-oss` or
  `~/.vscode-server`, or as a built clone at `../sysmlextension`. Point elsewhere with `--extension <folder>` or the
  `SYSML_EXTENSION` environment variable.
- A file argument also loads its sibling files, so cross-file imports resolve. The kit refuses to run on the project
  root or `sysml-ref/` (that would include the 100 reference examples).
- Kit additions over plain `sysml-sim`: `docs --merge` (whole-model documents instead of one set per file), keyword
  kinds for `query` (`interface def`, `use case`, …), options after `--` moved where `sysml-sim` reads them.
- Fallback without the extension: `npm install -g sysml-validate` (or `.\setup.ps1 -InstallValidator`). Third-party,
  syntax only, slightly more lenient than the OMG grammar, and it does not know the extension's libraries. Without
  either, the agent says so and relies on its self-check list; it never calls a model "valid" without a checker.

## Using with the SysML v2 VS Code extension
- **Install:** build `sysml-vscode-<version>.vsix` from the [extension repo](https://github.com/xgonzox729/sysmlextension) (`npm ci && npm run package`) or take it from its CI artifacts, then run *Extensions: Install from VSIX…* in VS Code. Opening this folder in VS Code also offers it as a recommended extension. Open the **folder** (not single files) so references across files resolve.
- **Diagrams:** open a file in `models/` and press Ctrl+Alt+D (⌥⌘D on macOS), or right-click an element for a view of just that element. Diagrams follow the text live, so you can watch the agent's edits land, and export as SVG/PNG for documents.

  | Model | View |
  |---|---|
  | part defs, specialization, requirements | General |
  | parts, ports, connections, interfaces, flows, wiring | Interconnection |
  | action defs, successions, decisions | Action flow |
  | state defs, transitions | State machine |

- **In the editor:** values and requirement margins appear as inline hints; **SysML: Verify Requirements**, **Generate Documents**, **Generate Code**, **Compare Model with HEAD** and the Simulation panel do interactively what the agent's tools do headlessly.
- **Wiring:** for harness models (see `sysml-ref/WIRING.md`), open the Interconnection view of the installation (`part system`), Alt+click a wire to trace its net, and run **SysML: Show Pinout and Wire Tables**.
- **Same results in both places:** the editor and `sysml-sim` use the same parser, libraries and checks.
- If you open the kit root in VS Code, the SysML Model tree also lists the reference files in `sysml-ref/`. Open your project's `models/` folder on its own for a clean tree.

## Continuous integration (optional)
The extension's CLI also runs in CI. Unzip the VSIX (`unzip -q sysml.vsix 'extension/*' -d sysml`) and run, e.g.:
```
SYSML_SIM="node sysml/extension/out/cli/sysml-sim.cjs"
$SYSML_SIM check models --warnings-as-errors
$SYSML_SIM verify models --worst-case --format junit --out reports/requirements.xml
$SYSML_SIM docs models --format html --out reports/docs
$SYSML_SIM gen models --out generated --check
$SYSML_SIM diff origin/main HEAD --out model-diff.md -- models     # --out before --
```
See `sysml-ref/extension/guide/21-models-as-code.md`.

## Model notes
The kit is model-agnostic; these are the knobs worth comparing with `tests/eval-prompts.md`.
- **Context:** the always-loaded overhead (AGENTS.md, cheat sheet, agent prompt) is about 10K tokens on top of OpenCode's own prompt; each reference file read adds 0.3–3K. For local models, load at least 64K context and make the context/output limits in your OpenCode provider config match what the server loaded.
- **Per-model settings:** the `sysml` agent sets no model or temperature, so it inherits your selection. To pin one, add to `opencode.json`:
  ```json
  "agent": { "sysml": { "model": "provider/model-id", "temperature": 0.4 } }
  ```
  A low temperature (0.2–0.5) helps strict syntax on most models; leave it unset for reasoning models whose providers ignore or reject it.
- **Reasoning / thinking:** if your model or provider has a thinking toggle, try it on, especially for state machines and requirement failures.
- **Local models (e.g. Gemma 4 26B A4B in LM Studio):** set the provider model id in OpenCode (e.g. `rog/<id shown in LM Studio>`). Google's general recommendation for Gemma 4 is temperature 1.0 / top-p 0.95 / top-k 64; this kit used 0.4 as its starting point for strict syntax. Gemma 4 enables thinking via `<|think|>` at the start of the system prompt, or LM Studio's reasoning toggle if it exposes one. Higher-bit quants (Q5/Q6) hold rare syntax better than Q4 if VRAM allows the context.

## Refreshing the references
- `.\setup.ps1` refreshes the official OMG examples and grammar from the SysML v2 Release repo and reports whether the
  extension and its CLI were found.
- `.\setup.ps1 -RefreshExtension -ExtensionPath <clone of the extension>` refreshes `sysml-ref/extension/` (guide,
  libraries, examples). Without `-ExtensionPath` it refreshes only the libraries, from the installed extension (the
  installed extension does not include the guide).

## License
MIT (see `LICENSE`), except `sysml-ref/examples/` and `sysml-ref/grammar/`, which are OMG SysML v2 Release
material under the Eclipse Public License 2.0. `sysml-ref/extension/` comes from the SysML v2 VS Code extension
(MIT, Copyright (c) 2026 Gonzalo Milian; see `sysml-ref/extension/README.md`).
