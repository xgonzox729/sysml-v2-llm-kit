# SysML v2 kit for OpenCode (any LLM)

Teaches an LLM in [OpenCode](https://opencode.ai) to write SysML v2 by putting the right reference material in front
of it at the right time, instead of trusting its (mostly SysML v1) training data. It works with whatever model you
select in OpenCode, local or hosted, and checks every model it writes with the
[SysML v2 VS Code extension](https://github.com/xgonzox729/sysmlextension).

## What's inside
| File | Loaded | Purpose |
|---|---|---|
| `AGENTS.md` | always (OpenCode) | role, plan → look up → write → self-check → validate workflow, checklist |
| `sysml-ref/CHEATSHEET.md` | always (via `opencode.json`) | ~5K tokens of parse-checked patterns + v1→v2 error table |
| `sysml-ref/EXAMPLES_INDEX.md` | on demand | maps each construct to the official example files |
| `sysml-ref/examples/` | on demand | the 100 official OMG training models (EPL-2.0) |
| `sysml-ref/grammar/` | grep only | official KerML/SysML textual BNF |
| `sysml-ref/GoldExample_BatteryCharger.sysml` | on demand | one validated end-to-end model |
| `sysml-ref/WIRING.md`, `sysml-ref/wiring/` | on demand | connectors, pins, wires and harnesses with the extension's `Wiring` library, plus an avionics example |
| `.opencode/agents/sysml.md` | select with Tab | agent with the hard rules; uses the model you have selected |
| `.opencode/tools/sysml_check.ts` | tool | `sysml_check` tool the agent calls to validate files |
| `.opencode/commands/sysml-check.md` | `/sysml-check [path]` | check files and fix the errors |
| `.opencode/commands/sysml-review.md` | `/sysml-review file.sysml` | checklist-driven review and fix pass |
| `tools/sysml-check.mjs` | you / the tool | headless checker that runs the VS Code extension's language server |
| `opencode.json` | always | loads the cheat sheet; makes `sysml-ref/` read-only for the agent |
| `.vscode/extensions.json` | VS Code | recommends the SysML v2 extension |
| `tests/eval-prompts.md` | you | 8 prompts to compare models and settings |

## Setup
1. Copy everything into the root of your own SysML project folder — **not** a clone of this public repo, or your models could end up pushed publicly. Your models go in `models/` (the agent is told to write there). This repo's `.gitignore` excludes `models/` as a safety net — delete that line in your own project's copy, or your models won't be committed there.
2. Install the [SysML v2 VS Code extension](https://github.com/xgonzox729/sysmlextension) (see [below](#using-with-the-sysml-v2-vs-code-extension)). It is the checker; Node.js 18+ must be on PATH.
3. Open OpenCode in the project, pick any model with `/models`, switch to the `sysml` agent with Tab, and run the prompts in `tests/eval-prompts.md`.

The model needs tool calling (for `sysml_check`, file reads and edits). See [Model notes](#model-notes) for context sizes and per-model settings.

## Checking models
The agent validates every file it changes, using the first checker available (AGENTS.md step 6):

1. **SysML v2 VS Code extension** (preferred). Full SysML v2 parser and name resolution matching the SysML v2 Pilot
   Implementation, the standard library, and the electrical checks of the `Wiring` library. The agent calls the
   `sysml_check` tool; you can run the same check yourself:
   ```
   node tools/sysml-check.mjs models              # or individual files
   node tools/sysml-check.mjs models --errors-only
   node tools/sysml-check.mjs --probe             # where is the extension?
   ```
   Output is one line per problem, `models/Drone.sysml:12:5: error: <message> [code]`, then a summary.
   Exit codes: 0 no errors, 1 errors, 2 usage, 3 extension not found, 4 timeout.
   It finds the extension in `~/.vscode`, `~/.vscode-insiders`, `~/.cursor`, `~/.windsurf`, `~/.vscode-oss` or
   `~/.vscode-server`, or a built clone at `../sysmlextension`. Point it elsewhere with `--server <path>/out/language/main.cjs`
   or the `SYSML_LSP_SERVER` environment variable.
   Files in the same folder are linked together, so cross-file imports resolve. Never run it on the project root,
   which would also check the 100 reference examples.
2. **`sysml-validate`** (fallback): `npm install -g sysml-validate` (or `.\setup.ps1 -InstallValidator`). Third-party,
   slightly more lenient than the OMG grammar (e.g. it accepts `part def A : B;`), and it does not know `Wiring`.
3. Neither installed: the agent says so and relies on its self-check list. It never calls a model "valid" without a checker.

## Using with the SysML v2 VS Code extension
- **Install:** build `sysml-vscode-<version>.vsix` from the [extension repo](https://github.com/xgonzox729/sysmlextension) (`npm ci && npm run package`) or take it from its CI artifacts, then run *Extensions: Install from VSIX…* in VS Code. Opening this folder in VS Code also offers it as a recommended extension.
- **Diagrams:** open a file in `models/` and press Ctrl+Alt+D (⌥⌘D on macOS), or right-click an element for a view of just that element:

  | Model | View |
  |---|---|
  | part defs, specialization, requirements | General |
  | parts, ports, connections, interfaces, flows, wiring | Interconnection |
  | action defs, successions, decisions | Action flow |
  | state defs, transitions | State machine |

  Diagrams follow the text live, so you can watch the agent's edits land. You can also edit from the diagram (rename, add member, connect).
- **Wiring:** for harness models (see `sysml-ref/WIRING.md`), open the Interconnection view of the installation (`part system`), Alt+click a wire to trace its net, and run **SysML: Show Pinout and Wire Tables** for pinouts and a wire list (CSV export).
- **Same results in both places:** the editor's diagnostics and `tools/sysml-check.mjs` come from the same language server.
- If you open the kit root in VS Code, the SysML Model tree also lists the reference examples in `sysml-ref/`. Open `models/` on its own for a clean tree.

## Model notes
The kit is model-agnostic; these are the knobs worth comparing with `tests/eval-prompts.md`.
- **Context:** the always-loaded overhead is about 8K tokens on top of OpenCode's own prompt; each example file read adds 0.3–1.5K. For local models, load at least 64K context and make the context/output limits in your OpenCode provider config match what the server loaded.
- **Per-model settings:** the `sysml` agent sets no model or temperature, so it inherits your selection. To pin one, add to `opencode.json`:
  ```json
  "agent": { "sysml": { "model": "provider/model-id", "temperature": 0.4 } }
  ```
  A low temperature (0.2–0.5) helps strict syntax on most models; leave it unset for reasoning models whose providers ignore or reject it.
- **Reasoning / thinking:** if your model or provider has a thinking toggle, try it on, especially for state machines.
- **Local models (e.g. Gemma 4 26B A4B in LM Studio):** set the provider model id in OpenCode (e.g. `rog/<id shown in LM Studio>`). Google's general recommendation for Gemma 4 is temperature 1.0 / top-p 0.95 / top-k 64; this kit used 0.4 as its starting point for strict syntax. Gemma 4 enables thinking via `<|think|>` at the start of the system prompt, or LM Studio's reasoning toggle if it exposes one. Higher-bit quants (Q5/Q6) hold rare syntax better than Q4 if VRAM allows the context.

## Refreshing the references
`.\setup.ps1` refreshes the official examples and grammar from the SysML v2 Release repo and reports whether the
extension checker was found. `.\setup.ps1 -RefreshWiring` also copies the `Wiring` library and example from the
installed extension into `sysml-ref/wiring/`.

## License
MIT (see `LICENSE`), except `sysml-ref/examples/` and `sysml-ref/grammar/`, which are OMG SysML v2 Release
material under the Eclipse Public License 2.0. `sysml-ref/wiring/` comes from the SysML v2 VS Code extension (MIT).
