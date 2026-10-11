# Modeling with SysML v2

A practical guide to SysML v2 for engineers who know electronics but have never used SysML. It
teaches the language one concept at a time. In parallel you build one complete example: a
battery-powered sensor node, the **EnviroNode**. Along the way you use this VS Code extension to
document the design and to calculate, check and simulate it.

By the end the EnviroNode model covers:
- its structure, ports and interfaces;
- its power tree and its requirements, verified against tolerances;
- trade studies and a SPICE simulation of one circuit;
- its behaviour, simulated over a week of operation;
- its wiring harness and its product variants;
- its firmware: tasks, memory, message sequences and test vectors;
- generated C code, documents and a CI pipeline.

Every SysML snippet in this guide is checked by the extension's test suite: the snippets parse, the
names resolve, and the numbers quoted in the text are the numbers the tools compute.

## How to read it

Chapters 1–8 are the core of the language: everyone should read them in order. After that,
pick by interest:

- **Hardware and systems engineers:** chapters 9–17 (requirements, tolerances, analyses, SPICE, behaviour, time, interfaces and wiring, variants).
- **Software engineers:** chapters 9, 13–15 and 18–21 (requirements, behaviour, use cases, firmware architecture, code generation, models in CI).

Each chapter has the same structure:
1. **The concepts.** What the SysML construct means, with an analogy from electronics wherever one helps.
2. **In the tool.** Exactly what to click, type and run, and what you should see.
3. **The EnviroNode.** What the chapter adds to the example project.
4. **Check yourself.** A short exercise, with its solution.

## Contents

| | Chapter | You learn |
|---|---|---|
| 0 | [What SysML v2 is](00-introduction.md) | Models, MBSE, the textual and graphical notations, what this extension does |
| 1 | [Getting started](01-getting-started.md) | Installing, the first model, diagnostics, outline, model tree, hover, diagrams |
| 2 | [Packages, names and comments](02-packages-and-names.md) | `package`, `import`, qualified names, short names, `doc` |
| 3 | [Parts: definitions and usages](03-parts.md) | `part def` vs `part`, decomposition, multiplicity, the General view |
| 4 | [Specialization and redefinition](04-specialization.md) | `:>`, `:>>`, subsetting, abstract definitions, the Electronics library |
| 5 | [Attributes, quantities and units](05-attributes-and-units.md) | `attribute`, ISQ/SI units, evaluation, inlay hints, unit errors |
| 6 | [Ports, connections and interfaces](06-ports-and-interfaces.md) | `port def`, conjugation, `connect`, `interface`, the Interconnection view, diagram editing |
| 7 | [The power tree](07-power-tree.md) | Supply rails, loads, regulators, ratings and derating |
| 8 | [Calculations and constraints](08-calculations.md) | `calc`, `constraint`, `assert`, solving for a value |
| 9 | [Requirements](09-requirements.md) | `requirement`, subjects, `require`/`assume`, `satisfy`, the verification matrix |
| 10 | [Tolerances, worst case, Monte Carlo](10-tolerances.md) | `@Tolerance`, corners, yield |
| 11 | [Analysis cases and trade studies](11-analysis.md) | `analysis`, objectives, sweeps, `TradeStudy` |
| 12 | [Circuit simulation with SPICE](12-spice.md) | `@SpiceRun`, test benches, measurements, waveforms, LTspice |
| 13 | [Actions](13-actions.md) | Action flows, successions, decisions, forks, `@Timing`, latency, the Action flow view |
| 14 | [States](14-states.md) | State machines, transitions, guards, the stepper, coverage and test vectors |
| 15 | [Time simulation](15-time-simulation.md) | `@Simulate`, `@Rate`, a week of operation, the energy budget |
| 16 | [Interface checks and wiring](16-interfaces-and-wiring.md) | Logic levels, level shifters, harnesses, pins and wires, twisted pairs |
| 17 | [Variants, allocation and views](17-variants-and-allocation.md) | `variation`/`variant`, configurations, `allocate`, views, organizing a project |
| 18 | [Use cases](18-use-cases.md) | `use case`, `actor`, `include`, from use cases to requirements |
| 19 | [Firmware architecture](19-firmware.md) | Tasks, schedulability, memory budgets, message sequences |
| 20 | [Code generation and traceability](20-code-generation.md) | Data types and ICDs, register maps, configurations, state machines in C, `@Implements` |
| 21 | [Models as code](21-models-as-code.md) | JSON export, queries, the `sysml-sim` CLI, CI, documents, impact analysis, semantic diff |

Appendices:

- [A. Syntax cheat sheet](A-cheat-sheet.md)
- [B. A tour of the standard library](B-standard-library.md)
- [C. The extension's libraries](C-extension-libraries.md)
- [D. Commands, settings and the CLI](D-commands.md)
- [E. Glossary: SysML for electronics engineers](E-glossary.md)
- [F. Troubleshooting](F-troubleshooting.md)

[FEATURES.md](FEATURES.md) maps every feature of the language and the extension to the chapter
and the EnviroNode element that uses it.

## The example project

The finished project is in [example/sensor-node](example/sensor-node):

```
sensor-node/
├── model/                    the SysML model, one file per concern
│   ├── node-parts.sysml          part definitions (the "datasheets")
│   ├── node-architecture.sysml   the node: parts, power and signal connections
│   ├── node-requirements.sysml   requirements and what satisfies them
│   ├── node-analysis.sysml       lifetime analysis, duty-cycle sweep, cell trade study
│   ├── node-spice.sysml          SPICE test bench for the battery-sense divider
│   ├── node-behavior.sysml       measurement cycle (actions), power modes (states)
│   ├── node-icd.sysml            the radio message, field by field
│   ├── node-software.sysml       firmware components, tasks, software requirements
│   ├── node-variants.sysml       the product line: cells, radios, configurations
│   ├── node-usecases.sysml       use cases and actors
│   ├── node-harness.sysml        the field installation's cable harness
│   └── node-views.sysml          views for the power and firmware reviews
├── firmware/                 stand-ins for the firmware the model traces to
├── generated/                code generated from the model (checked in, kept up to date by CI)
└── ci/model.yml              the GitHub Actions workflow
```

You can follow the chapters and type the model yourself, or open the finished project and read
along. Either way, open the `sensor-node` folder (not just one file) in VS Code, so that the files
can refer to each other.
