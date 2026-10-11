# C. The extension's libraries

Besides the SysML v2 standard library, the extension bundles six libraries of its own. They are
ordinary SysML packages (MIT licensed), loaded automatically: import them like any package, and press
**F12** on a name to read its source and documentation.

| Library | Import | For |
|---|---|---|
| `EngineeringUnits` | `private import EngineeringUnits::*;` | everyday units: mA, µA, kΩ, mAh, ms, KiB… |
| `Simulation` | `private import Simulation::*;` | tolerances, sweeps, SPICE runs, time simulation |
| `Electronics` | `private import Electronics::*;` | electronic parts, supply rails, logic ports, electrical calculations |
| `Software` | `private import Software::*;` | encodings, configuration values, tasks, timing, traceability |
| `Registers` | `private import Registers::*;` | register maps |
| `Wiring` | `private import Wiring::*;` | harnesses: connectors, pins, wires, signals |

`Electronics` and `Wiring` both define a `Ground` (a part and a signal), so import them in different
packages, or qualify the name.

## EngineeringUnits

Units for values engineers write every day, defined from SI with prefixes or conversions:

| Kind | Units |
|---|---|
| Voltage | `'µV'`, `mV`, `kV` |
| Current | `nA`, `'µA'`, `mA` |
| Resistance | `'mΩ'`, `'kΩ'`, `'MΩ'` |
| Power | `'µW'`, `mW`, `kW` |
| Capacitance | `pF`, `nF`, `'µF'`, `mF` |
| Inductance | `nH`, `'µH'`, `mH` |
| Frequency | `kHz`, `MHz`, `GHz` |
| Time | `ns`, `'µs'`, `ms`, `wk`, `yr` (SI has `s`, `min`, `h`, `d`) |
| Charge | `Ah`, `mAh`, `'µAh'` |
| Energy | `mJ`, `'µJ'`, `Wh`, `mWh`, `kWh` |
| Length | `'µm'`, `cm`, `mil` |
| Data | `KiB`, `MiB`, `kB`, `MB`, `'kbit/s'`, `'Mbit/s'` (SI has `B` and `bit`) |

## Simulation

| Element | Kind | Purpose | Ch. |
|---|---|---|---|
| `Tolerance` | metadata | `relative`, `absolute`, `minimum`, `maximum`, `distribution` on an attribute value | 10 |
| `Distribution` | enum | `uniform`, `normal` (limits at ±3σ) | 10 |
| `Sweep` | metadata | `parameter`, `start`, `stop`, `steps`, `scale`, or `values` on an analysis | 11 |
| `SweepScale` | enum | `linear`, `logarithmic` | 11 |
| `SpiceRun` | metadata | `command`, `measures`, `probes`, `netlist`, `schematic`, `directives`, `engine` on an analysis | 12 |
| `SpiceEngineKind` | enum | `auto`, `ngspice`, `ltspice` (the setting `sysml.spice.engine` also has `ngspice-wasm`) | 12 |
| `Simulate` | metadata | `duration`, `step`, `events`, `record`, `stopWhen` on a state machine | 15 |
| `Rate` | metadata | `rateOf`, `rate`: an integrated derivative, in a state or always | 15 |

## Electronics

**Ports:**
- `Terminal`: an electrical contact.
- `PowerPort`: a supply rail, with `nominal`, `minimum`, `maximum`, `current` and `load`.
- `LogicPort` (`vdd`, `vil`, `vih`, `vol`, `voh`) and its kinds:
  - `GPIOPort`;
  - `I2CPort` (`clockRate`, `isController`, `address`);
  - `SPIPort` (`clockRate`, `isController`);
  - `UARTPort` (`baudRate`).

**Parts** (all specialize `Component`, which has `partNumber`, `manufacturer`, `packageName`,
`derating`, `power`, `maxTemperature`, `spiceModel`, `spiceModelCard`):

| Part | Key attributes |
|---|---|
| `TwoTerminal` | ports `p`, `n`; `voltage`, `current` |
| `Resistor` | `resistance`, `powerRating`, `voltageRating`; `power` = I²R |
| `Capacitor` | `capacitance`, `voltageRating`, `dielectric`, `esr` |
| `Inductor` | `inductance`, `ratedCurrent`, `saturationCurrent`, `dcResistance` |
| `Ferrite`, `Fuse` | `ratedCurrent`, `dcResistance` / `resistance`, `impedance` (ferrite), `kind` (fuse: fast, slow, PTC) |
| `Ground` | port `gnd`: SPICE node 0 |
| `VoltageSource`, `CurrentSource` | `waveform` (a SPICE source specification) |
| `Diode`, `SchottkyDiode`, `ZenerDiode`, `LED` | ports `anode`, `cathode`; `forwardVoltage`, `maxForwardCurrent`, `maxReverseVoltage`, `current` (`ZenerDiode`: `zenerVoltage`; `LED`: `color`) |
| `MOSFET`, `BJT` | ports gate/drain/source or base/collector/emitter; `rdsOn`, `thresholdVoltage`, `maxDrainCurrent` / `gain`, `saturationVoltage`, `maxCollectorCurrent` |
| `Pole`, `Switch`, `Relay` | port `common` and throws as `Terminal` ports, `poles` (multi-pole), the selected `position` (a throw's name), `ratedCurrent`, `voltageRating`, `contactResistance`; a relay's `coilPositive`, `coilNegative`, `coilVoltage`, `coilCurrent` |
| `Battery` | `chemistry`, `capacity`, `nominalVoltage`, `fullVoltage`, `cutoffVoltage`, `internalResistance`, `maxCurrent`, `selfDischargePerMonth`; port `supply`; `current`, `runtime` |
| `Regulator`, `LDO`, `SwitchingRegulator`, `BuckConverter`, `BoostConverter` | ports `input`, `output`; `outputVoltage`, `maxOutputCurrent`, `minInputVoltage`, `maxInputVoltage`, `quiescentCurrent`, `dropout` (LDO), `efficiency`, `switchingFrequency` |
| `LoadSwitch` | ports `input`, `output`; `rdsOn`, `maxCurrent` |
| `PoweredDevice` | port `supply`; `activeCurrent`, `sleepCurrent`, `dutyCycle`, `averageCurrent`, `minSupplyVoltage`, `maxSupplyVoltage` |
| `Microcontroller` | `clockFrequency`, `flash`, `ram`, `deepSleepCurrent` |
| `Sensor`, `Radio` (`txCurrent`, `rxCurrent`), `OpAmp`, `Oscillator` | |
| `Crystal` | `frequency`, `tolerancePpm`, `loadCapacitance` |
| `BoardConnector` | `positions`, `pitch`, `ratedCurrent` |

**Calculations:**
- `AverageCurrent`, `BatteryLife`;
- `DividerOutput`, `LedResistor`;
- `RcTimeConstant`, `RcCutoff`;
- `LinearDissipation`, `TemperatureRise`.

**Checks:** `rail-overload`, `rail-voltage`, `rail-sources`, `derating`, `regulator-headroom`,
`regulator-input` (chapter 7), and the interface checks (chapter 16).

## Software

| Element | Kind | Purpose | Ch. |
|---|---|---|---|
| `Encoding` | metadata | `bits`, `signed`, `scale`, `offset`, `maxLength`, `byteOrder`, `code` | 20 |
| `ByteOrder` | enum | `littleEndian`, `bigEndian` | 20 |
| `Config` | metadata | `name`, `scale`: an attribute exported to configuration headers | 17 |
| `Processor` | part def | `cores`, `flash`, `ram` | 19 |
| `SoftwareComponent` | part def | `flash`, `ram` | 19 |
| `Task` | part def | `period`, `wcet`, `deadline`, `priority`, `core`, `stack` | 19 |
| `Utilization`, `ResponseTime`, `FlashUsed`, `RamUsed` | calc defs | schedulability and memory results | 19 |
| `Timing` | metadata | `duration` of an action step | 13 |
| `Latency` | calc def | the critical path of an action flow | 13 |
| `Implements`, `VerifiedBy` | metadata | `file` and `symbol` / `test`: traceability to code and tests | 20 |

**Checks:** `deadline-miss`, `cpu-overload`, `memory-budget`, `task-incomplete`,
`trace-missing-file`.

## Registers

| Element | Purpose |
|---|---|
| `RegisterBlock` | `baseAddress`, `registerBits`; contains registers |
| `Register` | `offset`, `bits`, `access`, `resetValue`; contains fields |
| `Field` | `lsb`, `width`, `access`; its attributes with a number are its named values |
| `Access` | `readWrite`, `readOnly`, `writeOnly`, `write1ToClear`, `readToClear` |

**Check:** `register-map`.

## Wiring

| Element | Purpose |
|---|---|
| `Signal` and its kinds | `Power` (`nominal`, `minimum`, `maximum`, `current`, `maxDrop`), `Ground`, `Discrete`, `Analog`, `CAN`, `Ethernet`, `ARINC429`, `RS422`, `RS485`, `RS232` (`bitrate`, `polarity`, `pair`), `Shield` |
| `Polarity` | `positive`, `negative` |
| `Pin` | a contact: `pinId`, `maxCurrent`, `voltageRating`, `contactSize`, `signal` |
| `Connector` | a pinout: `gender`, `partNumber` |
| `Wire` | `length`, `gauge` (`AWG::…`) or `crossSection`, `material`, `color`, `wireId`, `ampacity` |
| `Splice`, `Harness`, `CableShield`, `TwistedPair` | junctions, grouping, shields, twisted wires |

**Checks:** the `wiring-*` diagnostics of chapter 16. The full reference is [docs/wiring.md](../wiring.md).

Next: [D. Commands, settings and the CLI](D-commands.md)
