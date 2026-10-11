# F. Troubleshooting

## Syntax and names

**"Unexpected 'join'" (or `fork`, `merge`, `decide`, `analysis`, `filter`, `from`, `to`, `all`,
`state`, `action`, `item`…) where you wrote a name.** It is a keyword. Rename the element
(`joinNetwork`), or quote the name (`'join'`). Names that trip people up: `join`, `analysis`,
`filter`, `from`, `to`, `then`, `first`, `in`, `out`, `end`, `ref`, `event`, `message`, `flow`,
`state`, `transition`, `accept`, `send`, `do`, `entry`, `exit`, `if`, `else`, `loop`, `until`.

**"Expected '?' but found 'then'".** The conditional expression is `if c ? a else b`, not `if c then
a else b`. (`if … then` is the guard syntax of an action flow's decision.)

**"Could not resolve reference to … named 'X'".**
- The element doesn't exist, or is in a package you didn't import: add `private import Pkg::*;`.
- It's in another file: open the **folder** containing all the files (**File › Open Folder…**), not
  just one file, so the extension sees the whole model.
- It's a feature you reach through an untyped subject: `subject n;` has no features, so write
  `subject n : EnviroNode;`.

**A unit in brackets doesn't resolve (`[µA]`, `[kΩ]`).** Units whose names aren't plain identifiers
must be quoted: `['µA']`, `['kΩ']`, `['Ω']`. Also check that `SI::*` or `EngineeringUnits::*` is
imported.

**Inside a metadata body, which `min` is meant?** In `@Limits { min = 1; }`, `min` is the metadata
definition's own feature, even where `SI::*` (whose `min` is the minute) is imported: a body
redefines the features of its definition first. (Earlier versions of the extension picked the
minute; that's why its own metadata use `minimum`/`maximum` and `maxLength`.) Outside a metadata body,
`min` is the minute wherever `SI::*` is imported, so give your own features unambiguous names.

## Values

**A value shows no hint, or a requirement is *unknown*.** Something it depends on has no value.
- Evaluate the element (**Evaluate Element at Cursor**) and look for `–` in the Values view.
- A common case is a library calculation with a missing input. A `PoweredDevice` needs
  `activeCurrent`, `sleepCurrent` and `dutyCycle` for its `averageCurrent`.

**`unit-mismatch` / `dimension-mismatch`.** Exactly what it says: check the units. `V × A × s` is
energy, not power; `mA` was probably meant where `A` was written.

**An inherited attribute keeps its old value.** You declared a new attribute (`attribute capacity =
…`) instead of redefining the inherited one (`:>> capacity = …`).

**The battery life (or another power-tree value) is unknown in a requirements file.** The power tree
is analysed for the systems of the file and of the files it refers to. Make sure the requirement's
file refers to the system (`satisfy … by node`) and that the system's file is in the workspace.

## Diagrams

**A part isn't drawn as a box.** Only usages with features of their own in braces are drawn as boxes;
others are lines in their owner's *parts* compartment. Raise the **depth**, or open a diagram of the
part itself (double-click).

**The diagram doesn't change.** It updates 250 ms after the last edit (`sysml.diagram.updateDelay`),
and only when the file parses. Fix syntax errors first.

## Simulation

**The Behavior tab says "No state machines or action flows in this file".** A state machine needs
substates; an action flow needs successions. A usage typed by a definition (`exhibit state modes :
PowerModes;`) is simulated through its definition: put the cursor in the definition.

**An event button does nothing.** The event is ignored: no transition from the active states accepts
it, or its guard doesn't hold. The log says which.

**A time simulation stops early or doesn't start.** Check `stopWhen`, and the log for errors. More
than two million steps (`duration` / `step`) is refused: use a larger `step`.

**SPICE: "Measurement … failed (its condition never occurred in the simulated interval)".**
- The measurement's condition never happens in the simulated time (a `TRIG` level the signal never
  reaches, an `AT` beyond the run's end): lengthen the `command`'s stop time.
- Node names are `v(part.terminal)` paths from the analysis's subject: check them against the
  netlist the panel shows.

**SPICE: the engine is not found.**
- With `sysml.spice.engine` set to `ngspice` or `ltspice`, the program must be installed: set
  `sysml.spice.ngspicePath` or `sysml.spice.ltspicePath`.
- `auto` always works: it falls back to the bundled engine.

## Software and code generation

**`trace-missing-file`.** `@Implements` and `@VerifiedBy` paths are relative to the **model file**,
not to the workspace: `../firmware/src/radio.c` from `model/node-software.sysml`.

**A task is listed under no processor.** It must be part of a processor (or a `Microcontroller`), at
any depth, or part of something allocated to one (`allocate firmware to mcu`).

**Generate Code reports a field it can't encode.**
- Give it an `@Encoding`: `bits` must be 8, 16, 32 or 64.
- A quantity sent as an integer needs a `scale`.
- A `String` or a `[0..*]` sequence needs a `maxLength`.

**My edits to `*_actions.c` were not overwritten. Is the file stale?** No: the action stubs are
written only once, on purpose. Delete the file (or use `sysml-sim gen --force`) to get fresh stubs.

## The command line

**`sysml-sim` reports unresolved names that VS Code doesn't.** Pass the model's folder, or a file
whose sibling files hold the rest of the model. Libraries of your own need `--library DIR`.

**Exit code 2.** A usage or loading error: a misspelled command, a missing `--out`, a file that doesn't
exist. The message says which.
