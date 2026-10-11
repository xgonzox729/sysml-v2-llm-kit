# 21. Models as code

The EnviroNode model is a set of text files. That means it can be treated like source code:
- versioned in git and reviewed in pull requests;
- checked by CI on every push;
- queried by scripts and turned into documents automatically.

This last chapter shows the tools for that: the JSON export and queries, the `sysml-sim` command-line
tool, document generation, impact analysis before a change, and a semantic diff after it.

## The model as data: JSON export and queries

**SysML: Export Model as JSON** writes the resolved model as one JSON document. It contains every
element with:
- its **qualified name** (its `id`), kind and owner;
- its types and specializations;
- its `doc`, connector ends, and what a `satisfy` relates;
- every value **both as written and evaluated**, with its SI value and dimension.

The format is documented in [docs/model-json.md](../model-json.md). This is what `node.life` looks
like:

```json
{
  "id": "NodeArchitecture::node::life",
  "kind": "ReferenceUsage",
  "name": "life",
  "owner": "NodeArchitecture::node",
  "redefines": ["NodeArchitecture::EnviroNode::life"],
  "value": {
    "expression": "BatteryLife(battery.capacity, battery.current, 0.8)",
    "si": 103537454.80909158,
    "dimension": { "s": 1 },
    "text": "3.2809 yr"
  }
}
```

Scripts can read it without parsing SysML: feed a dashboard, cross-check a spreadsheet, generate
whatever the extension doesn't. For quick questions, **query** it from the command line (below):

```
$ sysml-sim query model --kind part --within NodeArchitecture::node
NodeArchitecture::node  (PartUsage) : NodeArchitecture::EnviroNode
NodeArchitecture::node::battery  (PartUsage) : NodeParts::NodeCell
NodeArchitecture::node::ldo  (PartUsage) : NodeParts::MainLdo
...
```

Queries filter by `--kind` (a keyword like `part`, `requirement def`, `port`, or a metaclass),
`--name` (with `*` and `?`), `--within` (a qualified name) and `--type` (typed by or specializing).

## The `sysml-sim` command-line tool

Everything the extension computes, `sysml-sim` computes too, without VS Code. It ships inside the
extension (`out/cli/sysml-sim.cjs` in the installed extension's folder, or in the `.vsix`, which is a
zip file) and needs only Node.js 20 or later:

```bash
node ~/.vscode/extensions/<publisher>.sysml-vscode-<version>/out/cli/sysml-sim.cjs --help
```

(Make an alias, `alias sysml-sim='node …/sysml-sim.cjs'`; the examples below assume one.) Run it from
the `sensor-node` folder:

| Command | What it does |
|---|---|
| `sysml-sim check model` | All diagnostics (syntax, names, units, power tree, interfaces, wiring, software…), gcc-style; exit 1 on errors (`--warnings-as-errors` for warnings too). |
| `sysml-sim verify model --worst-case --format junit --out reports/requirements.xml` | The verification matrix, as text, JSON, CSV or JUnit XML; exit 1 if a requirement fails. |
| `sysml-sim analyze model --format csv` | Analysis cases, sweeps, trade studies and SPICE runs. |
| `sysml-sim simulate model/node-behavior.sysml --behavior PowerModes --time` | The time simulation; `--input Wake --input run` steps a behaviour instead. |
| `sysml-sim simulate model/node-behavior.sysml --behavior PowerModes --coverage --format json` | State machine coverage and test vectors (chapter 14). |
| `sysml-sim export model --out model.json` | The JSON export. |
| `sysml-sim query model --kind requirement --name 'SW-*'` | Queries. |
| `sysml-sim docs model --format html --out reports/docs` | The documents (below). |
| `sysml-sim gen model --out generated` | Code generation (chapter 20); `--check` fails if `generated/` is out of date. |
| `sysml-sim diff main -- model` | The model changes since `main` (below). |

Given a folder, it loads every `.sysml` file in it. Given a file, it also loads the other model files
next to it, so references between files resolve, and reports only on the file you named. Exit codes:
0 for success, 1 when a check, requirement, objective or assertion fails, 2 for a usage or loading
error.

## Continuous integration

[example/sensor-node/ci/model.yml](example/sensor-node/ci/model.yml) is a GitHub Actions workflow for
the EnviroNode. On every push and pull request it:

1. installs `sysml-sim` from the extension's `.vsix`;
2. **checks** the model (`check --warnings-as-errors`);
3. **verifies** the requirements at the worst case and publishes the JUnit report. Every requirement
   is a test case, with its `@VerifiedBy` test as a property;
4. runs the **analyses** and generates the **documents**, and uploads both as build artifacts;
5. checks that the **generated code** is up to date (`gen --check`): change the model without
   regenerating, and CI says which file is stale;
6. saves the power-mode **test vectors**;
7. on a pull request, **comments with the model changes** (`diff`).

A model change that breaks a requirement, overloads a rail, misses a task deadline or leaves the
generated code stale now fails CI, the same way a broken unit test does.

## Documents

**SysML: Generate Documents** writes five documents for a model file, as Markdown or HTML, into a
folder you choose:

| Document | Contents |
|---|---|
| `requirements.md` | The requirements specification: each requirement's ID, name, text (its `doc`), subject, constraints, and what satisfies it with its status. |
| `icd.md` | The interface control document: port definitions with their features; every connection between ports, with the settings of both ends (`vdd 3.3 V, clockRate 400 kHz`); the message formats (chapter 20); the register maps. |
| `verification.md` | The verification report: the matrix with actual values, limits and margins; assertions; analyses; supply rails and part ratings. |
| `bom.md` | The bill of materials: the electronic components, grouped by type and value, with quantities, part numbers and reference designators. |
| `traceability.md` | Requirements against their tests and the implementation of what satisfies them; every element with an `@Implements` or `@VerifiedBy`. |

Run it on `model/node-architecture.sysml`. The BOM has 17 components in 13 lines:
- the resistors with their values: `650 Ω` for the LED resistor, `100 kΩ` and `90.9 kΩ` for the
  divider;
- five 100 nF capacitors, the divider's filter capacitor and the four decoupling capacitors, grouped
  because they have the same value.

A component made of components (the divider) is listed by its parts, and firmware and registers are
left out. Regenerate
the documents after every change, or let CI do it. They're only as good as the `doc` comments you
wrote.

## Impact analysis: before a change

Before changing something, find out what depends on it. Put the cursor on an element and run **SysML:
Show Impact of Element at Cursor** (editor context menu). The **SysML Impact** view in the Explorer
shows, transitively, everything that refers to it: what is typed by it, specializes, subsets or
redefines it, uses its value, connects to it, or satisfies it. Click an entry to go there. Open
diagrams highlight the affected elements.

For `NodeMcu`:

```
NodeParts::NodeMcu
  typed by ← NodeArchitecture::node::mcu
    uses value ← NodeAnalysis::lifetimeVsDutyCycle
    connects ← NodeArchitecture::node::(connect ldo.output to mcu.supply)
    connects ← NodeArchitecture::node::(connect mcu.i2c to shifter.high)
    connects ← NodeArchitecture::node::spi
    connects ← NodeArchitecture::node::(connect mcu.ledPin to led.drive)
    connects ← NodeArchitecture::node::(flow of NodeIcd::Reading from mcu to radio)
    connects ← NodeArchitecture::node::txDone
    connects ← NodeArchitecture::node::(allocate measurementCycle to mcu)
    connects ← NodeArchitecture::node::(allocate firmware to mcu)
    uses value ← NodeSoftware::(satisfy cpuHeadroom by node.mcu)
    uses value ← NodeSoftware::(satisfy memoryBudget by node.mcu)
```

Replacing the MCU affects its power and bus connections, the reading flow and the `txDone` message,
the two allocations, the duty-cycle sweep and two software requirements. That's the review list for the change.

## Semantic diff: after a change

A text diff of a model shows lines. What reviewers need to know is what changed *in the model*,
including the values that change as a consequence. **SysML: Compare Model with HEAD** compares the
file with its last committed version, as models (with the workspace's other files as they are, so
consequences elsewhere show up too):
- added and removed elements, by qualified name;
- changed types, values, multiplicities, documentation and connections;
- **computed values that changed** as a result.

Reformatting and reordering don't show. The result opens as a Markdown preview.

Try it: commit the project, then lower the MCU's duty cycle in `NodeMcu` from `0.01` to `0.008`. On
`model/node-parts.sysml`, *Compare Model with HEAD* shows:

```markdown
## Model changes in model/node-parts.sysml since HEAD

0 added, 0 removed, 1 changed, 1 computed value(s) changed.

### Changed

- `NodeParts::NodeMcu::dutyCycle` (reference)
  - value: `0.01` → `0.008`

### Computed values that changed

- `NodeArchitecture::node::life`: `3.2809 yr` → `3.72741 yr`
```

The one-line edit raises the battery life by 0.45 years, and the reviewer sees it without opening a
spreadsheet. In CI, `sysml-sim diff origin/main HEAD -- model` produces the same Markdown for the
whole model, ready to post as a pull-request comment (the workflow above does that).

## Keeping diffs clean

- **One concern per file**, as in the EnviroNode: a pull request that changes the firmware touches
  `node-software.sysml`, not the architecture.
- **Format before committing** (*Format Document*): only whitespace changes, never the model, so
  diffs show real changes only.
- **Commit generated files**, and let `gen --check` keep them honest: the generated code's diff in a
  pull request shows reviewers what the firmware will see.
- **Stable names and short names.** Element IDs in exports, diffs and documents are qualified names.
  Renaming is a real change; use F2, so references follow.

## Check yourself

1. Write the CI step that fails the build when any requirement fails at the worst case.
2. Which command tells you which requirements a change to `BatterySense` can affect?
3. You reorder the parts of `node` and reformat the file. What does *Compare Model with HEAD* show?

<details><summary>Answers</summary>

1. `- run: $SYSML_SIM verify model --worst-case --format junit --out reports/requirements.xml`. The
   command exits with 1 when a requirement fails, nominally or at the worst case, which fails the
   step.
2. **SysML: Show Impact of Element at Cursor** on `BatterySense`. It lists ADC-1 and PWR-3 (through
   `senseRange` and `senseCurrent` and their `satisfy`), and the SPICE bench that uses it.
3. *No model changes.* Elements are compared by qualified name, so order and whitespace don't
   matter.

</details>

---

You have built a complete system model:
- structure, interfaces and a power tree;
- requirements verified against tolerances;
- analyses, a circuit simulation, and behaviour simulated over a week;
- a wiring harness and a product line;
- firmware with its budgets, message sequences and test vectors;
- generated code and documents, and a CI pipeline that keeps it all honest.

The appendices are for reference from here on: [A. Syntax cheat sheet](A-cheat-sheet.md).
