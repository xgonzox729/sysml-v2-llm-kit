# 7. The power tree

With the parts, their values and their supply connections in place, the model already *contains*
the EnviroNode's power budget: who supplies whom, and how much each load draws. This chapter shows
how the extension reads it as a **power tree**, computes the current on every rail, checks every
part against its ratings, and gives you the battery life.

No new SysML syntax here: this is what the model you have written so far can tell you.

## Rails, sources and loads

The Electronics library's `PowerPort` describes a supply rail:

- **A source** has an `out` power port: a battery's `supply`, a regulator's `output`. Its
  `nominal` is the voltage it provides and `current` is the most it can deliver.
- **A load** has an `in` power port: a `PoweredDevice`'s `supply`, a regulator's `input`. Its
  `minimum` and `maximum` are the voltages it accepts and `current` is what it draws.

**Connections** between power ports form **rails**. For each rail the analysis:

1. adds up the current of every load on it;
2. sets that total as the source's `load`. For a regulator, its output current then gives its
   input current, which is a load on the rail above it;
3. repeats until the currents reach the battery.

That is exactly the calculation you would do in a spreadsheet, except that it follows the model:
connect another load and every number above it changes.

A load's current is its `averageCurrent`. For the library's devices that is `activeCurrent ×
dutyCycle + sleepCurrent × (1 − dutyCycle)`, from the values you gave in chapter 5. An LDO draws its
output current plus its quiescent current. A switching regulator draws output power divided by its
efficiency, at its input voltage.

## Ratings and derating

Each library part also knows what it is rated for. The analysis compares what it carries or
dissipates against `derating × rating`:

| Part | Checked | Rating |
|---|---|---|
| `Resistor` | power (I²R), voltage | `powerRating`, `voltageRating` |
| `Capacitor` | voltage | `voltageRating` |
| `Inductor`, `Ferrite`, `Fuse` | current | `ratedCurrent` (and `saturationCurrent`) |
| `Diode`, `LED` | forward current | `maxForwardCurrent` |
| `MOSFET`, `BJT` | drain / collector current | `maxDrainCurrent`, `maxCollectorCurrent` |
| `Battery` | current drawn | `maxCurrent` |
| `Regulator` | output current | `maxOutputCurrent` |

`derating` is the fraction of the rating a part may use. It defaults to 0.5 (half) for parts,
0.8 for regulators and 1 for batteries. Redefine it on a part if your derating policy differs:
`:>> derating = 0.6;`.

## The checks

The analysis reports problems as diagnostics in the editor:

| Diagnostic | Meaning |
|---|---|
| `rail-overload` | A rail draws more than its source can deliver. |
| `rail-voltage` | A load doesn't accept the voltage its rail supplies, e.g. a 3.6 V maximum on a 5 V rail. |
| `rail-sources` | Several sources feed one rail (a warning). |
| `derating` | A part exceeds its derated rating (a warning), or its absolute rating (an error). |
| `regulator-headroom` | An LDO's input is below its output plus dropout, or a buck's input is not above its output. |
| `regulator-input` | A regulator's input voltage is outside its allowed input range. |

## Battery life

Battery life is a calculation over the power tree: usable charge divided by the average current
drawn from the cell. The Electronics library has it ready as `BatteryLife`, and `Battery` exposes
its current as `battery.current`. Chapter 8 explains calculations in general.

## In the tool

1. Open `model/node-architecture.sysml` and run **SysML: Verify Requirements** (the ✓ icon in the
   editor title bar). The **Simulation** panel opens beside the editor.
2. Select its **Power** tab. **Supply rails** lists each source with its voltage, its load, the
   most it can deliver, and how much of that is used. **Loads** lists who draws what. **Part
   ratings** lists every rated part, most stressed first, with the share of its derated rating it
   uses.
3. Click a source or a part to jump to it in the text.
4. Open the Interconnection view of `node`. If a rail or a part has a problem, a marker (a small
   red or yellow badge) sits on the connection or the part, with the message in its tooltip.

![The Power tab of the Simulation panel](images/node-power.png)

## The EnviroNode

The power tab shows the EnviroNode's power tree:

| Rail | Voltage | Load | Loads |
|---|---|---|---|
| `battery.supply` | 3.7 V | 66.76 µA | `ldo.input` |
| `ldo.output` | 3.3 V | 66.73 µA | `mcu.supply` 41.48 µA, `radio.supply` 24.4 µA, `sensorLdo.input` 849.2 nA |
| `sensorLdo.output` | 1.8 V | 824.2 nA | `sensor.supply` |

The MCU dominates: 4 mA × 1 % = 40 µA, plus 1.5 µA asleep. The radio's 12 mA × 0.2 % = 24 µA is
second. The sensor's 135 µA at 0.5 % is under 1 µA, and the LDOs' 25 nA each barely register.

The part ratings are all comfortable. The LED uses 20 % of its derated 20 mA rating (2 mA of
10 mA), and the LED resistor dissipates 2.6 mW against 31.5 mW (8 %).

Now record the battery life. Add an attribute to `EnviroNode` in
`model/node-architecture.sysml`:

<!-- check: project -->
```sysml
    part def EnviroNode {
        doc /* A battery-powered environmental sensor node. */
        attribute reportPeriod : DurationValue;
        attribute life : DurationValue;
        ...
    }
```

and compute it in `node`, at the end of its body:

<!-- check: project -->
```sysml
    part node : EnviroNode {
        :>> reportPeriod = 15 [min];
        ...
        /* 80 % of the rated capacity is usable (temperature, ageing, cutoff). */
        :>> life = BatteryLife(battery.capacity, battery.current, 0.8);
    }
```

The editor shows `⇒ 3.28 yr`: 2400 mAh × 0.8 / 66.76 µA. (`reportPeriod` is used by the
requirements of chapter 9.) Chapter 9 turns "at least three years" into a requirement and checks
it.

## Check yourself

1. Change the LED's current in `StatusLed` to `15 [mA]`. What does the extension report, and
   why is it a warning and not an error?
2. Which single change would add the most battery life: halving the MCU's duty cycle, or halving
   the radio's?
3. Add a load to `node`, `part heater : Sensor { :>> activeCurrent = 300 [mA]; :>> sleepCurrent =
   0 [A]; :>> dutyCycle = 1; }`, and `connect ldo.output to heater.supply;`. What happens?

<details><summary>Answers</summary>

1. `derating`: *node.led: forward current 15 mA, more than 50 % of its 20 mA rating.* It is a
   warning because 15 mA is within the absolute rating (20 mA) but above the derated one (10 mA).
   Above 20 mA it would be an error.
2. The MCU's: it draws 41.5 µA of the 66.8 µA, so halving its duty cycle saves about 20 µA. Halving
   the radio's saves about 12 µA. Chapter 11 sweeps the duty cycle to show the whole curve.
3. The 3.3 V rail now draws 300 mA from an LDO that delivers at most 200 mA: a `rail-overload`
   warning on the rail and a `derating` error on the LDO (*output current 300 mA, above its 200 mA
   rating*). The battery's current and life follow: the cell would last 6.4 hours. (Without a
   `sleepCurrent`, the heater's average current has no value and it adds nothing: a model only
   computes what it is given.)

</details>

Next: [8. Calculations and constraints](08-calculations.md)
