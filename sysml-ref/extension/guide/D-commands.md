# D. Commands, settings and the CLI

## Commands

Run them from the Command Palette (**⇧⌘P** / **Ctrl+Shift+P**, type `SysML`), the editor's context
menu (right-click in a `.sysml` file), or the editor title bar.

| Command | Where | What it does | Ch. |
|---|---|---|---|
| **Open Diagram** | title bar, palette, ⌥⌘D / Ctrl+Alt+D | The General view of the file | 1, 3 |
| **Open Diagram of Element at Cursor** | context menu | A diagram of the element at the cursor | 3 |
| **Open Interconnection View of Element at Cursor** | context menu | Parts, ports and connections | 6 |
| **Open Action Flow View of Element at Cursor** | context menu | An action's steps and successions | 13 |
| **Open State Machine View of Element at Cursor** | context menu | A state machine | 14 |
| **Evaluate Element at Cursor** | context menu | The element's values in the SysML Values view | 5 |
| **Show Values of Current Document** | SysML Values view | Every top-level part's values | 5 |
| **Verify Requirements** | title bar, context menu | The Simulation panel: requirements, power, analyses, software, behaviour | 9 |
| **Run Worst-Case Analysis** / **Run Monte Carlo Analysis** | palette, panel | Requirements over tolerances | 10 |
| **Solve for Attribute at Cursor** | context menu | The value that makes a constraint hold | 8 |
| **Run Analyses** | context menu | Analysis cases, sweeps, trade studies, SPICE | 11, 12 |
| **Simulate State Machine or Action at Cursor** | context menu | The stepper in the Behavior tab (also interactions) | 13, 14, 19 |
| **Run Time Simulation** | context menu | A `@Simulate` state machine over time | 15 |
| **State Machine Coverage and Test Vectors** | context menu | Reachable transitions and states, and test vectors | 14 |
| **Trace Signal at Cursor** | context menu | A wiring net, end to end | 16 |
| **Show Pinout and Wire Tables** | palette | Connector pinouts and the wire list | 16 |
| **Export Model as JSON** | palette | The resolved model as JSON | 21 |
| **Generate Documents** | palette | Requirements spec, ICD, verification report, BOM, traceability | 21 |
| **Generate Code** | palette | C types, register headers, configurations, state machines | 20 |
| **Show Impact of Element at Cursor** | context menu | What depends on an element, in the SysML Impact view | 21 |
| **Compare Model with HEAD** | palette | The model changes since the last commit | 21 |
| **Refresh** | SysML Model view | Rebuild the model tree | 1 |

Standard VS Code features work as usual: **F12** go to definition, **Shift+F12** references, **F2**
rename, **Ctrl+Space** completion, **⇧⌥F** / **Shift+Alt+F** format, hover, the Outline view and
breadcrumbs, and the Problems panel.

## Views and panels

| View | Where | Shows |
|---|---|---|
| **SysML Model** | Explorer | The models of the workspace as a tree, with a diagram button per element |
| **SysML Values** | Explorer | Evaluated values of the element or document chosen |
| **SysML Impact** | Explorer | The dependents of the element chosen |
| **Diagram** | editor column | General, Interconnection, Action flow and State machine views |
| **Simulation** | editor column | Tabs: Requirements, Power, Analyses, Software, Behavior |

## In a diagram

| Action | Effect |
|---|---|
| Click / double-click | Reveal in the text / show a diagram of the element |
| ↑ / ⌂ | The owning element / the whole file |
| Drag, scroll; ⌘/Ctrl+scroll, pinch, − / + | Pan; zoom |
| Fit, Filter, Depth, view selector | Show all; highlight by name or kind; nesting depth; switch views |
| Export | SVG or PNG |
| Right-click | Rename, Add member…, Set type…, Specialize…, Delete, Connect from here |
| F2, Del | Rename, delete the selected element |
| Shift+drag | Connect two elements (connection, interface, binding, flow, succession, transition) |
| Alt+click a pin or wire | Trace its signal |
| Esc | Cancel connecting, clear a trace, close the tables |

## Settings

| Setting | Default | |
|---|---|---|
| `sysml.diagram.defaultView` | `general` | The view **Open Diagram** shows |
| `sysml.diagram.defaultDepth` | `2` | Levels of nested elements drawn as boxes |
| `sysml.diagram.updateDelay` | `250` | Milliseconds after the last edit before a diagram updates |
| `sysml.spice.engine` | `auto` | `auto` (an installed ngspice if found, else the bundled one), `ngspice-wasm`, `ngspice`, `ltspice` |
| `sysml.spice.ngspicePath`, `sysml.spice.ltspicePath` | | Paths of the ngspice and LTspice executables |
| `sysml.spice.timeout` | `60000` | Milliseconds before an external SPICE run is stopped |

## The `sysml-sim` command-line tool

`out/cli/sysml-sim.cjs` in the extension's folder (or in the `.vsix`); it needs Node.js 20 or later.

```
Usage: sysml-sim <command> [options] <files or folders...>

  check    <files|dirs...>                  diagnostics; exit 1 on errors (--warnings-as-errors)
  verify   <files...> [--format text|json|csv|junit] [--worst-case] [--monte-carlo N] [--seed S]
  analyze  <files...> [--format text|json|csv]
  simulate <file> [--behavior ID] [--input EVENT|part: EVENT|step|run ...] [--time] [--coverage] [--format text|json|csv]
                                              --coverage: reachable transitions and test vectors (JSON)
  export   <files...>                         the resolved model as JSON
  query    <files...> [--kind K] [--name PATTERN] [--within QNAME] [--type T] [--format text|json]
  docs     <files...> --out DIR [--format md|html]
  gen      <files...> --out DIR [--target types,registers,variants,state-machines] [--check] [--force]
                                              generated code; --check: exit 1 if DIR is out of date
  diff     <rev> [<rev2>] [-- paths...]        model changes between git revisions (or the working tree)

Options: --out FILE, --library DIR, --spice-engine auto|ngspice-wasm|ngspice|ltspice
Exit codes: 0 success, 1 a check, requirement or assertion failed, 2 usage or load error.
```

- A **folder** argument loads every `.sysml` and `.kerml` file below it. A **file** argument loads
  the other model files next to it too, so references resolve, and reports only on the file.
- `--library DIR` adds a folder of your own libraries (a company parts library).
- `--out FILE` writes the output to a file instead of printing it.

Next: [E. Glossary](E-glossary.md)
