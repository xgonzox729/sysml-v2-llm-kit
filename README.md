# SysML v2 kit for a local Gemma 4 26B A4B in OpenCode

Teaches an offline model SysML v2 by putting the right reference material in front of it at the right time,
instead of trusting its (mostly SysML v1) training data.

## What's inside
| File | Loaded | Purpose |
|---|---|---|
| `AGENTS.md` | always (OpenCode) | role, plan → look up → write → self-check workflow, checklist |
| `sysml-ref/CHEATSHEET.md` | always (via `opencode.json`) | ~5K tokens of parse-checked patterns + v1→v2 error table |
| `sysml-ref/EXAMPLES_INDEX.md` | on demand | maps each construct to the official example files |
| `sysml-ref/examples/` | on demand | the 100 official OMG training models (EPL-2.0) |
| `sysml-ref/grammar/` | grep only | official KerML/SysML textual BNF |
| `sysml-ref/GoldExample_BatteryCharger.sysml` | on demand | one validated end-to-end model |
| `.opencode/agents/sysml.md` | select with Tab | agent with lower temperature + hard rules |
| `.opencode/commands/sysml-review.md` | `/sysml-review file.sysml` | checklist-driven review and fix pass |
| `tests/eval-prompts.md` | you | 7 prompts to measure changes |

## Setup
1. Copy everything into the root of your SysML project folder.
2. In `.opencode/agents/sysml.md`, set `model:` to your exact provider/model id (e.g. `rog/<id shown in LM Studio>`).
3. In LM Studio, load Gemma 4 26B A4B with **context length ≥ 65536**. Always-loaded overhead from this kit is about 8K tokens on top of OpenCode's own prompt; each example file read adds 0.3–1.5K.
4. Make sure the model's context/output limits in your OpenCode provider config match what LM Studio loaded.
5. Open OpenCode in the project, switch to the `sysml` agent, and run the prompts in `tests/eval-prompts.md`.

## Optional: syntax validator (recommended, still offline)
`npm install -g sysml-validate` (or `.\setup.ps1 -InstallValidator`). The agent detects it and runs a fix loop.
It parsed all 100 official examples with zero errors and flags v1 constructs, but it is a third-party tool and
slightly more lenient than the OMG grammar (e.g. it accepts `part def A : B;`, which the grammar rejects).

## Tuning knobs to A/B with the eval set
- **Temperature**: agent file uses 0.4 (my starting point for strict syntax). Google's general recommendation for Gemma 4 is 1.0 / top-p 0.95 / top-k 64.
- **Thinking mode**: Gemma 4 enables it via `<|think|>` at the start of the system prompt. If LM Studio exposes a thinking/reasoning toggle for this model, try it on, especially for state machines.
- **Quantization**: higher-bit quants (Q5/Q6) tend to hold rare syntax better than Q4 if VRAM allows the 64K context.
- `.\setup.ps1` refreshes examples and grammar from the official repo.

## License
MIT (see `LICENSE`), except `sysml-ref/examples/` and `sysml-ref/grammar/`, which are OMG SysML v2 Release
material under the Eclipse Public License 2.0.
