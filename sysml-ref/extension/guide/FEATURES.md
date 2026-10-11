# Feature coverage

Every feature of SysML v2 the guide teaches, and every feature of the extension, with the chapter
that explains it and the element of the EnviroNode example that uses it. Element names are qualified
names in [example/sensor-node/model](example/sensor-node/model) (the test suite checks that each one
exists), and file names are relative to [example/sensor-node](example/sensor-node). A few language
constructs appear only in a chapter's examples, marked *snippet*.

## Language: organization

| Feature | Ch. | EnviroNode |
|---|---|---|
| Packages | 2 | `NodeParts`, `NodeArchitecture`, `NodeRequirements` (one per file) |
| Private imports | 2 | `NodeArchitecture` imports `NodeParts::*`, `NodeBehavior::*` |
| Importing one element | 2 | `NodeParts` imports `NodeBehavior::Wake`; `NodeUseCases` imports `NodeIcd::Reading` |
| Imports inside a definition | 10 | `NodeParts::BatterySense` (`private import Simulation::*;`) |
| Qualified names | 2 | `NodeArchitecture::node::firmware` (typed `NodeSoftware::NodeFirmware`) |
| Short names (IDs) | 2, 9 | `NodeRequirements::NodeLifetime` (`<'PWR-1'>`), `NodeParts::TMP117::registers` (`<TMP117>`) |
| Quoted names | 16 | `NodeHarness::NodeEnclosure::J1` (pins `'1'`…`'5'`) |
| Documentation (`doc`) | 2 | `NodeParts`, `NodeArchitecture::EnviroNode`, every requirement |
| Comments (`comment about`) | 2, 4 | `NodeParts::NodeCell` (in `node-parts.sysml`) |
| Alias | 2 | *snippet* |

## Language: structure

| Feature | Ch. | EnviroNode |
|---|---|---|
| Part definitions and usages | 3 | `NodeArchitecture::EnviroNode`, `NodeArchitecture::node` |
| Decomposition | 3 | `NodeArchitecture::node::battery` … `NodeArchitecture::node::sense` |
| Usage with a body of its own | 3, 5 | `NodeArchitecture::node::ledResistor` |
| Multiplicity | 3, 4 | `NodeArchitecture::node::decoupling` (`[4]`), `NodeIcd::Reading::samples` (`[4]`) |
| Reference parts (`ref`) | 3 | *snippet* |
| Specialization | 4 | `NodeParts::NodeCell` (`:> Battery`), `NodeParts::MainLdo` (`:> LDO`) |
| Abstract usage | 17 | `NodeVariants::nodeFamily` |
| Redefinition | 4 | `NodeParts::NodeCell::capacity`, `NodeArchitecture::node::life` |
| Subsetting | 4 | `NodeArchitecture::node::decoupling`, `NodeArchitecture::node::bulk` (`:> capacitors`) |
| Attributes with quantities and units | 5 | `NodeParts::NodeMcu::activeCurrent`, `NodeArchitecture::EnviroNode::railVoltage` |
| Strings, Booleans, integers | 5 | `NodeParts::NodeMcu::partNumber`, `NodeIcd::Configure::ledEnabled`, `NodeParts::NodeMcu::retries` |
| Enumerations | 4, 20 | `NodeIcd::NodeStatus`, `NodeParts::NodeCell::chemistry` |
| Computed values (expressions) | 5 | `NodeParts::BatterySense::vout`, `NodeParts::BatterySense::current` |
| Feature chains | 5 | `NodeArchitecture::node::ledResistor::resistance` (`led.forwardVoltage`) |
| Items | 6, 20 | `NodeIcd::Reading`, `NodeIcd::TxDone`, `NodeBehavior::Wake` |
| Ports with values | 6 | `NodeParts::NodeMcu::i2c`, `NodeParts::TMP117::i2c` |
| Port directions | 6 | `NodeParts::NodeMcu::ledPin` (`out`), `NodeParts::StatusLed::drive` (`in`) |
| Connections | 6 | `NodeArchitecture::node::#connection1` (`battery.supply` to `ldo.input`) |
| Interface definitions and usages | 6 | `NodeArchitecture::SpiLink`, `NodeArchitecture::node::spi` |
| Binding | 6 | `NodeArchitecture::node::#bindingConnectorAs1` (`railVoltage = ldo.outputVoltage`) |
| Flow | 6 | `NodeArchitecture::node::#flow1` (`Reading` from `mcu` to `radio`) |
| Terminals and circuits | 8, 12 | `NodeParts::BatterySense` (ports `top`, `tap`, `bottom`) |
| Conjugated ports | 6 | *snippet* (the harness's plug and receptacle pins play this role) |

## Language: calculations, constraints, requirements, analysis

| Feature | Ch. | EnviroNode |
|---|---|---|
| Calling library calculations | 5, 7 | `NodeArchitecture::node::ledResistor::resistance` (`LedResistor`), `NodeArchitecture::node::life` (`BatteryLife`) |
| Calculation definitions | 8 | *snippet* (the library's `DividerOutput`, used in `NodeParts::BatterySense::vout`) |
| Constraints | 8 | `NodeParts::BatterySense::fullScale` |
| Assertions | 8, 17 | `NodeVariants::nodeFamily::loRaNeedsPrimaryCell` |
| Requirement definitions, IDs, text | 9 | `NodeRequirements::NodeLifetime`, `NodeRequirements::SenseRange`, `NodeRequirements::SenseCurrent` |
| Subjects | 9 | `NodeRequirements::NodeLifetime::n` |
| `require` / `assume` | 9 | `NodeRequirements::NodeLifetime` |
| Requirement usages and `satisfy` | 9 | `NodeRequirements::nodeLifetime`, `NodeRequirements::#satisfy1` |
| `satisfy` by a feature chain | 9 | `NodeRequirements::#satisfy2` (`by node.sense`) |
| Analysis cases with objectives | 11 | `NodeAnalysis::LifetimeAnalysis`, `NodeAnalysis::lifetime` |
| Trade studies | 11 | `NodeAnalysis::cellTrade` |
| Dependencies | 18 | `NodeUseCases::replaceCell` (to `NodeRequirements::NodeLifetime`) |

## Language: behaviour

| Feature | Ch. | EnviroNode |
|---|---|---|
| Action definitions, steps, `start`/`done` | 13 | `NodeBehavior::MeasurementCycle` |
| Successions (`then`, `first … then`) | 13 | `NodeBehavior::MeasurementCycle` |
| Decision and loop | 13 | `NodeBehavior::MeasurementCycle::enough` |
| Fork and join | 13 | `NodeBehavior::MeasurementCycle::split`, `NodeBehavior::MeasurementCycle::both` |
| Assignment | 13, 14 | `NodeBehavior::MeasurementCycle::sample`, `NodeBehavior::PowerModes::sleeping::sleepCurrent` |
| Perform | 13 | `NodeArchitecture::EnviroNode::measurementCycle` |
| State definitions, nested states | 14 | `NodeBehavior::PowerModes`, `NodeBehavior::PowerModes::active` |
| Transitions with signal triggers | 14 | `NodeBehavior::PowerModes::wake` |
| Guards | 14 | `NodeBehavior::PowerModes::lowBattery` |
| Effects | 14 | `NodeBehavior::PowerModes::wake` (`do assign wakeups := wakeups + 1`) |
| Time triggers (`after`) | 14 | `NodeBehavior::PowerModes::sleepAgain`, `NodeBehavior::PowerModes::active::#transition1` |
| Entry actions | 14 | `NodeBehavior::PowerModes::active::measuring::measureCurrent` |
| Exhibit | 14 | `NodeArchitecture::EnviroNode::powerModes` |
| Change triggers (`when`) | 14 | *snippet* |
| Parallel states | 14 | *snippet* |
| Send and accept between parts | 19 | `NodeParts::NodeMcu::radioDriver` (`send Reading() via spi`), `NodeParts::LoRaRadio::modem` |
| `message … of … from … to …` | 19 | `NodeArchitecture::node::txDone` |
| Use case definitions, actors, objectives | 18 | `NodeUseCases::InstallNode`, `NodeUseCases::InstallNode::technician` |
| Use cases with scenarios | 18 | `NodeUseCases::install`, `NodeUseCases::readData` |
| `include use case` | 18 | `NodeUseCases::install::firstReading`, `NodeUseCases::replaceCell::reinstall` |
| Accept in an action | 18 | `NodeUseCases::readData::waitForReading` |
| Allocation | 17, 19 | `NodeArchitecture::node::#allocation1`, `NodeArchitecture::node::#allocation2` |
| Variation and variants | 17 | `NodeVariants::CellChoice`, `NodeVariants::RadioChoice` |
| Configurations | 17 | `NodeVariants::outdoorNode`, `NodeVariants::indoorNode` |
| Viewpoints and views | 17 | `NodeViews::PowerReview`, `NodeViews::powerView`, `NodeViews::firmwareView` |

## Extension: editing and diagrams

| Feature | Ch. | EnviroNode |
|---|---|---|
| Diagnostics, completion, hover, go to definition, rename, formatting | 1 | every file |
| Outline and SysML Model tree | 1 | every file |
| General view | 3 | `NodeArchitecture::node`, `NodeUseCases::InstallNode` (use cases as ovals) |
| Interconnection view | 6 | `NodeArchitecture::node`, `NodeHarness::fieldInstallation` |
| Action flow view | 13 | `NodeBehavior::MeasurementCycle` |
| State machine view | 14 | `NodeBehavior::PowerModes` |
| Editing from diagrams (add, connect, rename, delete) | 6 | `NodeArchitecture::node::#connection9` (`mcu.ledPin` to `led.drive`) |
| Allocation edges | 17 | `NodeArchitecture::node::#allocation1` |

## Extension: values and checks

| Feature | Ch. | EnviroNode |
|---|---|---|
| Evaluation with units, inlay hints, Values view | 5 | `NodeArchitecture::node::ledResistor::resistance`, `NodeParts::BatterySense::vout` |
| Unit and dimension checks | 5 | every quantity (the deliberate errors are *snippets*) |
| Bindings evaluated | 6 | `NodeArchitecture::EnviroNode::railVoltage` |
| Power tree: rails, loads, propagation | 7 | `NodeArchitecture::node` (`battery`, `ldo`, `sensorLdo`) |
| Ratings and derating | 7 | `NodeArchitecture::node::led`, `NodeArchitecture::node::ledResistor` |
| Regulator checks | 7 | `NodeArchitecture::node::ldo`, `NodeArchitecture::node::sensorLdo` |
| Battery life | 7 | `NodeArchitecture::node::life` |
| Solving for a value | 8 | `NodeParts::BatterySense::r2` (from `fullScale`) |
| Assertions checked per configuration | 17 | `NodeVariants::nodeFamily::loRaNeedsPrimaryCell` |
| Logic-level and bus checks | 16 | `NodeArchitecture::node::shifter` (the level shifter they require) |
| Interface-end check | 16 | `NodeArchitecture::node::spi` |
| Wiring checks, trace, tables | 16 | `NodeHarness::fieldInstallation`, `NodeHarness::W1` |
| Twisted pairs | 16 | `NodeHarness::W1::TP1` |
| Register map checks | 20 | `NodeParts::TMP117::registers` |
| Variant checks | 17 | `NodeVariants::outdoorNode`, `NodeVariants::indoorNode` |
| Software checks (deadlines, CPU, memory) | 19 | `NodeSoftware::NodeFirmware` |
| Traceability checks (missing files) | 20 | `NodeSoftware::NodeFirmware::sampler` |

## Extension: verification and analysis

| Feature | Ch. | EnviroNode |
|---|---|---|
| Verification matrix, margins, verdict hints | 9 | `NodeRequirements::nodeLifetime`, `NodeSoftware::cpuHeadroom` |
| CSV / JSON export of results | 9 | `node-requirements.sysml` |
| Tolerances | 10 | `NodeParts::BatterySense::vin`, `NodeParts::BatterySense::r1::resistance` |
| Worst case | 10 | `NodeRequirements::senseRange` |
| Monte Carlo | 10 | `NodeRequirements::senseCurrent` |
| Analysis cases | 11 | `NodeAnalysis::lifetime` |
| Sweeps | 11 | `NodeAnalysis::lifetimeVsDutyCycle` |
| Trade studies | 11 | `NodeAnalysis::cellTrade` |
| SPICE (bundled ngspice) | 12 | `NodeSpice::settling`, `NodeSpice::SenseBench` |
| SPICE measurements, waveforms, netlist | 12 | `NodeSpice::SenseSettling` |
| Action flow simulation | 13 | `NodeBehavior::MeasurementCycle` |
| Latency (`@Timing`, `Latency`) | 13, 19 | `NodeBehavior::MeasurementCycle`, `NodeSoftware::CycleLatency` |
| State machine stepper | 14 | `NodeBehavior::PowerModes` |
| Coverage and test vectors | 14 | `NodeBehavior::PowerModes` |
| Time simulation (`@Simulate`, `@Rate`) | 15 | `NodeBehavior::PowerModes` |
| Budget per mode | 15 | `NodeBehavior::PowerModes::charge` |
| Use case simulation | 18 | `NodeUseCases::install` |
| Tasks, response-time analysis, CPU | 19 | `NodeSoftware::NodeFirmware::radioTask` |
| Memory budgets | 19 | `NodeSoftware::NodeFirmware::rtos`, `NodeSoftware::memoryBudget` |
| Software allocated to a processor | 19 | `NodeArchitecture::node::#allocation2` |
| Library calculations in requirements | 19 | `NodeSoftware::CpuHeadroom`, `NodeSoftware::RadioDeadline`, `NodeSoftware::MemoryBudget` |
| Interactions and sequence diagrams | 19 | `NodeArchitecture::node` (`mcu.radioDriver`, `radio.modem`) |
| Declared messages checked against a run | 19 | `NodeArchitecture::node::txDone` |

## Extension: generation and tooling

| Feature | Ch. | EnviroNode |
|---|---|---|
| Data types to C, JSON Schema, protobuf | 20 | `NodeIcd::Reading` → `generated/node_icd_types.h`, `generated/node_icd.schema.json`, `generated/node_icd.proto` |
| Encodings (`@Encoding`) | 20 | `NodeIcd::Reading::temperature` |
| Register maps to C | 20 | `NodeParts::TMP117::registers` → `generated/tmp117_regs.h` |
| Configuration headers, defconfigs, Kconfig | 17, 20 | `NodeVariants::outdoorNode` → `generated/config_outdoor_node.h`, `generated/outdoor_node_defconfig`, `generated/Kconfig` |
| `@Config` values | 17 | `NodeVariants::nodeFamily::cellCapacity` |
| State machines to C | 20 | `NodeBehavior::PowerModes` → `generated/power_modes.c`, `generated/radio_driver.c`, `generated/modem.c` |
| `@Implements` | 20 | `NodeSoftware::NodeFirmware::sensorDriver` → `firmware/src/tmp117.c` |
| `@VerifiedBy` | 20 | `NodeSoftware::cpuHeadroom` → `firmware/test/test_schedule.c` |
| Firmware using generated code | 20 | `firmware/src/radio.c`, `firmware/src/tmp117.c` |
| JSON export and queries | 21 | every file |
| Documents (spec, ICD, verification, BOM, traceability) | 21 | `node-architecture.sysml`, `node-requirements.sysml` |
| Impact analysis | 21 | `NodeParts::NodeMcu` |
| Semantic diff | 21 | `NodeParts::NodeMcu::dutyCycle` → `NodeArchitecture::node::life` |
| `sysml-sim` CLI | 21 | `ci/model.yml` |
| CI workflow | 21 | `ci/model.yml` |
