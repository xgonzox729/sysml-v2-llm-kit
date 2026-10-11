# Engineering models with the SysML v2 extension (units, requirements, electronics, software, code, documents)

Read this when the user wants the model to **compute, verify, generate or document** something: values with units,
requirements with pass/fail margins, power budgets, tolerances, analyses, firmware tasks, message formats, register
maps, generated code, or the system documents. Everything here is checked by the extension's `sysml-sim` CLI
(OpenCode tools `sysml_check`, `sysml_verify`, `sysml_analyze`, `sysml_simulate`, `sysml_docs`, `sysml_gen`,
`sysml_query`). `sysml-validate` does not know these libraries.

Deeper material (read only the part you need):
- `sysml-ref/extension/guide/` — the extension's modeling guide. `A-cheat-sheet.md` (syntax tables), `C-extension-libraries.md`
  (every library element), `F-troubleshooting.md` (error messages → fixes), chapters below.
- `sysml-ref/extension/example/sensor-node/model/` — a complete multi-file system (the EnviroNode) using all of it.
- `sysml-ref/extension/library/*.sysml` — library sources; `sysml-ref/extension/examples/` — small focused models.

| Task | Library | Guide chapter | Example |
|---|---|---|---|
| units like mA, µA, kΩ, mAh, ms, yr, KiB | `EngineeringUnits` | 05 | any sensor-node file |
| power tree, battery life, rail/derating checks | `Electronics` | 07 | `node-parts.sysml`, `node-architecture.sysml` |
| calculations, constraints, solving a value | — | 08 | `examples/simulation/divider.sysml` |
| requirements with pass/fail and margin | — | 09 | `node-requirements.sysml` |
| tolerances, worst case, Monte Carlo | `Simulation` (`@Tolerance`) | 10 | `examples/simulation/divider.sysml` |
| analyses, sweeps, trade studies | `Simulation` (`@Sweep`) | 11 | `node-analysis.sysml` |
| SPICE circuit runs | `Simulation` (`@SpiceRun`) | 12 | `node-spice.sysml`, `examples/simulation/rc-filter.sysml` |
| action flows, `@Timing`, latency | `Software` | 13 | `node-behavior.sysml` |
| state machines, coverage, test vectors | — | 14 | `node-behavior.sysml`, `examples/simulation/node-modes.sysml` |
| time simulation (`@Simulate`, `Rate`) | `Simulation` | 15 | `examples/simulation/sensor-power.sysml` |
| logic levels, buses, interfaces, harnesses | `Electronics`, `Wiring` | 16 | `node-harness.sysml`, `sysml-ref/WIRING.md` |
| variants, allocation, views, project layout | `Software` (`@Config`) | 17 | `node-variants.sysml`, `node-views.sysml` |
| use cases | — | 18 | `node-usecases.sysml` |
| firmware tasks, CPU/memory budgets | `Software` | 19 | `node-software.sysml` |
| message formats, registers, generated C, traceability | `Software`, `Registers` | 20 | `node-icd.sysml`, `node-parts.sysml` |
| JSON export, CLI, CI, documents, diff | — | 21 | — |

## Project layout (guide ch. 17)
- `models/<system>-<concern>.sysml`, one top-level package per file named `<System><Concern>`
  (e.g. `node-parts.sysml` → `NodeParts`, `node-architecture.sysml`, `node-requirements.sysml`, `node-software.sysml`).
- Definitions ("datasheets") in parts files; the system usage (`part node : EnviroNode { … }`) in the architecture file.
- `private import` between files, layered one way: parts ← architecture ← requirements / software / analysis. Never import back.
- Requirement ids as short names: `requirement def <'PWR-1'> NodeLifetime`. Requirement text is its `doc`.
- `doc /* … */` on every package, definition and requirement: the generated documents are built from it.
- Run the tools on the `models` folder (or one file: its sibling files are loaded too).

## One example with the important patterns

```sysml
package SensorExample {
    doc /* A battery sensor: values with units, a library part as a datasheet, a power rail, a requirement with a margin, a task budget and a message format. */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Electronics::*;
    private import Simulation::*;
    private import Software::*;

    /* A library part specialized as a datasheet: set inherited values with :>> (never `attribute x = …`). */
    part def Cell :> Battery {
        :>> capacity = 2400 [mAh];
        :>> nominalVoltage = 3.7 [V];
        :>> fullVoltage = 4.2 [V];
        :>> cutoffVoltage = 3.0 [V];
        :>> maxCurrent = 1 [A];
    }
    part def Ldo33 :> LDO {
        :>> partNumber = "TPS7A0233";
        :>> outputVoltage = 3.3 [V];
        :>> dropout = 0.15 [V];
        :>> maxOutputCurrent = 200 [mA];
        :>> quiescentCurrent = 25 [nA];
        :>> minInputVoltage = 1.5 [V];
        :>> maxInputVoltage = 6 [V];
    }
    part def Mcu :> Microcontroller {
        :>> minSupplyVoltage = 1.8 [V];
        :>> maxSupplyVoltage = 3.6 [V];
        :>> activeCurrent = 4 [mA];
        :>> sleepCurrent = 1.5 ['µA'];
        :>> dutyCycle = 0.01;
        :>> flash = 192 [KiB];
        :>> ram = 20 [KiB];
    }

    /* A value with a tolerance: worst case and Monte Carlo use it. */
    part def Divider {
        attribute vin : ElectricPotentialValue = 4.2 [V];
        attribute r1 : ResistanceValue = 100 ['kΩ'] { @Tolerance { relative = 0.01; } }
        attribute r2 : ResistanceValue = 120 ['kΩ'] { @Tolerance { relative = 0.01; } }
        attribute vout : ElectricPotentialValue = vin * r2 / (r1 + r2);
    }

    /* Firmware: tasks count against the processor they are allocated to. */
    part def Firmware {
        part sampler : Task { :>> period = 100 [ms]; :>> wcet = 4 [ms]; :>> stack = 1 [KiB]; }
        part radioTask : Task { :>> period = 1 [s]; :>> wcet = 40 [ms]; :>> deadline = 200 [ms]; :>> stack = 2 [KiB]; }
    }

    /* A message format: @Encoding drives generated C, JSON Schema and protobuf, and the ICD document. */
    item def Reading {
        doc /* The uplink message. */
        @Encoding { byteOrder = ByteOrder::bigEndian; }
        attribute sequence : Natural { @Encoding { bits = 16; } }
        attribute battery : ElectricPotentialValue { @Encoding { bits = 16; scale = 1 [mV]; } }
    }

    part def SensorNode {
        doc /* The sensor node. */
        attribute life : DurationValue;
    }

    part node : SensorNode {
        part battery : Cell;
        part ldo : Ldo33;
        part mcu : Mcu;
        part sense : Divider;
        part firmware : Firmware;
        /* Power rails are port connections: source output to load supply. */
        connect battery.supply to ldo.input;
        connect ldo.output to mcu.supply;
        allocate firmware to mcu;
        :>> life = BatteryLife(battery.capacity, battery.current, 0.8);
    }

    /* Checkable requirement: typed subject + require constraint + satisfy. */
    requirement def <'PWR-1'> Lifetime {
        doc /* The node shall run at least three years on one cell. */
        subject n : SensorNode;
        require constraint { n.life >= 3 [yr] }
    }
    requirement def <'ADC-1'> SenseRange {
        doc /* The sense output shall stay below 2.3 V. */
        subject d : Divider;
        require constraint { d.vout <= 2.3 [V] }
    }
    requirement def <'SW-1'> CpuHeadroom {
        doc /* The firmware leaves at least 30 % of the CPU free. */
        subject m : Microcontroller;
        require constraint { Utilization(m) <= 0.7 }
    }
    requirement lifetime : Lifetime;
    requirement senseRange : SenseRange;
    requirement cpuHeadroom : CpuHeadroom;
    satisfy lifetime by node;
    satisfy senseRange by node.sense;
    satisfy cpuHeadroom by node.mcu;
}
```

`sysml_verify` on this file passes all three requirements at nominal values (ADC-1 by only 0.4 %); with
`worstCase` ADC-1 fails at the ±1 % resistor corners (−0.5 %) — exactly the kind of finding to report to the user.
`sysml_docs` turns the file into a requirements specification, ICD, verification report, BOM and traceability matrix;
`sysml_gen` turns `Reading` into C, JSON Schema and protobuf.

## Traceability to code and tests
```
part sampler : Task { … @Implements { file = "../firmware/src/sampler.c"; symbol = "sampler_task"; } }
requirement cpuHeadroom : CpuHeadroom { @VerifiedBy { file = "../firmware/test/test_schedule.c"; test = "test_cpu_load"; } }
```
Paths are relative to the **model file**; a missing file is a `trace-missing-file` warning.

## Rules that LLMs get wrong here
- Units that are not plain identifiers are quoted: `['µA']`, `['kΩ']`, `['Ω']`, `['µF']`. Plain ones are not: `[mA]`, `[mAh]`, `[KiB]`, `[yr]`. Import `SI::*` and `EngineeringUnits::*`.
- Set an inherited value with `:>> name = value;`. `attribute name = value;` declares a **new** attribute and the old value stays.
- A requirement needs a **typed** subject (`subject n : SensorNode;`), a `require constraint { boolean expression }` (no `;` inside), and a `satisfy req by element;` — otherwise it is unknown or unverified.
- A failing requirement is a design result. Report it with its margin and propose design changes; never weaken the requirement unless the user asks.
- `@Tolerance` uses `minimum`/`maximum` (not `min`/`max`: `min` is the minute in SI), or `relative`/`absolute`.
- Conditional expression: `if c ? a else b`. `if c then x;` exists only as a decision guard in action flows.
- Keywords are not names: `join analysis filter from to then first in out end ref event message flow state transition accept send do entry exit if else loop until`. Rename (`joinNetwork`) or quote.
- `Electronics::Ground` (a part) and `Wiring::Ground` (a signal) clash: import the two libraries in different packages, or qualify.
- No hex literals: register reset values are strings, `resetValue = "0x0220"`. `@Encoding` `bits` must be 8, 16, 32 or 64.
- A `PoweredDevice` (Microcontroller, Sensor, Radio…) needs `activeCurrent`, `sleepCurrent` and `dutyCycle`, or its average current and the battery life stay unknown.
- Generated files (`generated/`) are never edited by hand, except the `*_actions.c` stubs, which are written only once.

## Reading the results
- `sysml_check`: `path:line:col: severity: message [code]`. Codes beyond syntax: units (`unit-mismatch`, `dimension-mismatch`,
  `missing-unit`), electronics (`rail-overload`, `rail-voltage`, `rail-sources`, `derating`, `regulator-headroom`,
  `regulator-input`, `logic-level`, `logic-overvoltage`, `bus-rate`, `port-direction`, `interface-end`), software
  (`deadline-miss`, `cpu-overload`, `memory-budget`, `task-incomplete`, `trace-missing-file`), `register-map`,
  `variant-choice`, `variant-constraint`, `assertion-failed`, `requirement-failed`, `wiring-*`.
- `sysml_verify`: `pass|fail|unknown|not applicable|unverified  <ID> <name> (<subject>) <margin>`; `unknown` means a
  value it depends on is missing (see `F-troubleshooting.md`, "Values").
