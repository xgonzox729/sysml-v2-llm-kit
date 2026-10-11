# 12. Circuit simulation with SPICE

The calculations so far are static: averages, DC values, steady state. Some questions need a circuit
simulator. How long does a filter take to settle? Does a supply ring at start-up? What does the
divider output look like when the MCU switches it on? This chapter runs **SPICE** from the model,
with no schematic to redraw and no netlist to keep in sync.

## How it works

An analysis case annotated with `@SpiceRun` (from the `Simulation` library) is a SPICE simulation:

1. **The circuit** is generated from the analysis's subject. Electronics parts connected through
   their `Terminal`s become a netlist, and a `Ground` part's node is SPICE node 0.
   - Resistors, capacitors, inductors, ferrites and fuses become the matching SPICE elements, with
     their values from the model.
   - A `VoltageSource` or `CurrentSource` has a `waveform` (DC, `PULSE`, `SIN`…). A `Battery`
     becomes a source with its internal resistance.
   - Diodes and LEDs get a model fitted to their forward voltage. A part with a `spiceModel` (and
     `spiceModelCard`) uses that model or subcircuit.
2. **The analysis** is the `command`: `"tran 20u 40m"`, `"ac dec 20 10 1meg"`, `"op"`.
3. **The measurements** are `.meas` statements. In them, `v(part.terminal)` names the node a
   terminal is on: `v(sense.tap)`.
4. **The results:** each measurement's value goes to the analysis's `return` or `out` parameter of
   the same name, converted from SI to its type. The analysis's objective is then checked on it, as
   in chapter 11.

Because the netlist is generated from the model each time, sweeps, tolerance corners and value
changes all change the circuit.

### Engines

| Engine | When |
|---|---|
| **ngspice (WebAssembly)** | Bundled with the extension. Works with nothing installed. The default. |
| **ngspice (installed)** | Used instead when found on your system (faster for long transients). |
| **LTspice** | If you install it: for Analog Devices' encrypted models and for `.asc` schematics. |

The setting `sysml.spice.engine` (`auto`, `ngspice-wasm`, `ngspice`, `ltspice`) chooses.
`sysml.spice.ngspicePath` and `sysml.spice.ltspicePath` point at the executables when they aren't in
the usual places, and `sysml.spice.timeout` (60 s by default) stops runaway simulations.

## The EnviroNode: does the battery sense settle in time?

The battery-sense divider has a 100 nF filter capacitor. When the firmware switches the divider on
to measure the cell (with a high-side switch, to save the 22 µA the rest of the time), the ADC input
rises with the RC time constant: R1 ∥ R2 = 47.6 kΩ times 100 nF is 4.8 ms. How long until a
reading is valid?

Create `model/node-spice.sysml`. A **test bench** is a part that puts the circuit under test
together with its stimulus. Here, a source that steps from 0 to 4.2 V, as a full cell switched on:

<!-- check: project -->
```sysml
package NodeSpice {
    doc
    /*
     * Circuit simulation of the battery-sense divider with SPICE: when the MCU switches the
     * cell onto the divider, how fast does the ADC input settle, and to what voltage?
     */
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Electronics::*;
    private import Simulation::*;
    private import NodeParts::*;

    /* A test bench: a 4.2 V step (a full cell switched on) into the divider. */
    part def SenseBench {
        part cell : VoltageSource { :>> waveform = "PULSE(0 4.2 0 1u 1u 50m 100m)"; }
        part sense : BatterySense;
        part gnd : Ground;
        connect cell.p to sense.top;
        connect cell.n to gnd.gnd;
        connect sense.bottom to gnd.gnd;
    }
    part senseBench : SenseBench;

    analysis def SenseSettling {
        subject bench : SenseBench;
        @SpiceRun {
            command = "tran 20u 40m";
            measures = ("tran vtap FIND v(sense.tap) AT=39m",
                        "tran settle TRIG v(sense.tap) VAL=0.2 RISE=1 TARG v(sense.tap) VAL=1.9 RISE=1");
            probes = ("v(sense.top)", "v(sense.tap)");
        }
        return vtap : ElectricPotentialValue;
        out settle : DurationValue;
        objective {
            doc /* The ADC input settles to its final value within 20 ms of switching the divider on. */
            require constraint { vtap <= 2.3 [V] and settle <= 20 [ms] }
        }
    }
    analysis settling : SenseSettling { subject :>> bench = senseBench; }
}
```

- The bench reuses `BatterySense` from `node-parts.sysml` unchanged: same resistors, same
  capacitor, same tolerances.
- `PULSE(0 4.2 0 1u 1u 50m 100m)` is SPICE's pulse syntax: from 0 to 4.2 V after 0 s, with 1 µs
  edges, 50 ms high, a 100 ms period.
- `vtap` is the tap voltage after 39 ms, practically the final value.
- `settle` is the time from the tap crossing 10 % of its final value (0.2 V) to crossing 95 %
  (1.9 V).
- `probes` selects the waveforms to chart.

## In the tool

1. Run **SysML: Run Analyses** on `node-spice.sysml`. The first run loads the WebAssembly engine,
   which takes a second or two.
2. The **Analyses** tab shows `settling`:
   - **result** 1.999 V, with the objective met by 13 %;
   - the **SPICE** section: the engine used (`ngspice-wasm`), the measurements in SI units
     (`vtap` 1.999, `settle` 0.01377), a chart of `v(sense.top)` and `v(sense.tap)` against time,
     and the **netlist** that was run.
3. Look at the netlist. The parts became `V_cell`, `R_sense_r1`, `R_sense_r2` and `C_sense_c1`, and
   the tap node is `sense_c1_p`. The netlist uses the model's names, so you can read it.

![The SPICE analysis](images/node-spice.png)

The answer: the reading is valid **13.8 ms** after switching the divider on (the objective allowed
20 ms). So the firmware should switch the divider on as soon as it wakes and read the cell last. In
chapter 13's measurement cycle, the cell is read in the `average` step, after four 4 ms temperature
samples: about 17 ms after waking, comfortably later than 13.8 ms.

The settling time is about 2.9 τ (13.8 ms / 4.8 ms). Rising from 10 % to 95 % takes
ln(0.9 / 0.05) τ = 2.89 τ, so the simulator agrees with the hand calculation.

### Sweeping and tolerances

`@Sweep` works on SPICE analyses like on any other: each point is a SPICE run. Add, for example,
`@Sweep { parameter = senseBench.sense.c1.capacitance; values = (10 [nF], 47 [nF], 100 [nF], 220 [nF]); }`
to `settling`. Each point re-runs SPICE. The chart shows the result (`vtap`) at each capacitance, and
the 220 nF point turns red: with that capacitor the divider takes more than 20 ms to settle.

### Using LTspice and vendor models

To simulate with a vendor's model (many Analog Devices regulators are only available as encrypted
LTspice models), install LTspice and either:
- give the part a `spiceModel` naming the subcircuit and set `sysml.spice.engine` to `ltspice`, or
- draw the circuit in LTspice and point the analysis at it: `@SpiceRun { schematic = "ldo-startup.asc";
  command = "tran 0 5m"; measures = (…); }`. The analysis's `in` parameters are passed as `.param`
  values, so the schematic can use `{vin}` and friends.

## Check yourself

1. Halve the filter capacitor to 47 nF. What settling time do you expect, and what does the
   simulation say?
2. Why is the bench a separate part, instead of simulating `node` directly?
3. Add a measurement of the tap voltage after 5 ms.

<details><summary>Answers</summary>

1. The settling time scales with C: about 13.8 × 47/100 ≈ 6.5 ms. The simulation says 6.47 ms.
2. `node` has no stimulus. Its cell is a power-tree element, not a SPICE source with a waveform, and
   it contains parts that aren't part of this circuit. A bench simulates one circuit in a defined
   test condition, as you would on a lab bench.
3. Add `"tran v5 FIND v(sense.tap) AT=5m"` to `measures`, and `out v5 : ElectricPotentialValue;` to
   the analysis definition.

</details>

Next: [13. Actions](13-actions.md)
