# 10. Tolerances, worst case and Monte Carlo

A requirement verified at nominal values says nothing about the board in your hand. Resistors are
±1 %, the cell sits anywhere between 3.0 V and 4.2 V, the LDO's output is ±2 %. This chapter shows
how to attach **tolerances** to values and verify requirements over them: at the **worst-case**
corners, and statistically with **Monte Carlo** sampling.

## `@Tolerance`

SysML has no built-in notion of a tolerance, but it has **metadata**: annotations, written `@Name {
… }`, that tools understand. The extension's `Simulation` library defines `Tolerance`. Annotate an
attribute's value with it:

<!-- check: standalone -->
```sysml
package Tolerances {
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Simulation::*;

    part def Divider {
        attribute vin : ElectricPotentialValue = 4.2 [V] { @Tolerance { minimum = 3.0 [V]; maximum = 4.2 [V]; } }
        attribute r1 : ResistanceValue = 100 ['kΩ'] { @Tolerance { relative = 0.01; } }
        attribute r2 : ResistanceValue = 120 ['kΩ'] { @Tolerance { absolute = 1.2 ['kΩ']; distribution = Distribution::normal; } }
    }
}
```

The attribute's value is the **nominal** value. The annotation says how far it can stray:

| Tolerance | Range |
|---|---|
| `relative = 0.01` | ±1 % of the nominal value |
| `absolute = 1.2 ['kΩ']` | ±1.2 kΩ |
| `minimum = …; maximum = …;` | explicit limits (the nominal can be anywhere inside them) |
| `distribution = Distribution::normal` | for Monte Carlo: normal, with the limits at ±3σ (the default is uniform) |

Metadata is ordinary SysML: `@Tolerance { relative = 0.01; }` is short for a metadata usage typed by
`Simulation::Tolerance`, inside the attribute's body. Press **F12** on `Tolerance` to read its
definition.

## Worst case

A **worst-case analysis** asks, for each requirement, which combination of toleranced values gives
the lowest margin, and whether the requirement still holds there. The extension evaluates every
**corner**, every combination of minimum and maximum, for up to 12 toleranced values (4096
corners). Beyond that it estimates the worst corner from each value's sensitivity.

## Monte Carlo

A **Monte Carlo analysis** draws each toleranced value at random from its distribution, a thousand
times or more, and verifies the requirements every time. The **yield** is the fraction of samples in
which a requirement holds: the fraction of boards that would pass.

Worst case and Monte Carlo answer different questions. Worst case asks "can it fail?", which is
what safety and reliability reviews need. Monte Carlo asks "how often will it fail?", which is what
production cares about. A design can fail at a worst-case corner and still yield 100 %, because
that corner almost never happens.

## In the tool

The **Simulation** panel's toolbar (open it with **SysML: Verify Requirements**) has:

- **Nominal**: verify at nominal values only.
- **Worst case**: the corner analysis. The matrix gets a **Worst case** column: the status and lowest
  margin of each requirement over the corners. Hover it to see the corner (*vin = 4.2 V, r1 = 99 kΩ,
  r2 = 121.2 kΩ*). Expand a requirement to see the corner under its checks.
- **Monte Carlo** with a number of **samples** and a **seed**, then **Run**. The matrix gets a
  **Yield** column. The same seed gives the same samples, so a result can be reproduced.
- Below the matrix, **Toleranced values** lists every annotated value with its nominal, minimum and
  maximum. Click one to jump to it.

The commands **SysML: Run Worst-Case Analysis** and **SysML: Run Monte Carlo Analysis** do the same
from the Command Palette.

### An example that fails at a corner

Try it on this divider, which feeds an ADC that must stay below 2.3 V:

<!-- check: standalone -->
```sysml
package AdcDivider {
    private import SI::*;
    private import EngineeringUnits::*;
    private import ISQ::*;
    private import Simulation::*;

    part def Divider {
        attribute vin : ElectricPotentialValue = 4.2 [V] { @Tolerance { minimum = 3.0 [V]; maximum = 4.2 [V]; } }
        attribute r1 : ResistanceValue = 100 ['kΩ'] { @Tolerance { relative = 0.01; } }
        attribute r2 : ResistanceValue = 120 ['kΩ'] { @Tolerance { relative = 0.01; } }
        attribute vout : ElectricPotentialValue = vin * r2 / (r1 + r2);
    }

    requirement def <'ADC-1'> AdcRange {
        doc /* The divider output shall stay within 2.3 V. */
        subject divider : Divider;
        require constraint { divider.vout <= 2.3 [V] }
    }

    part battSense : Divider;
    requirement adcRange : AdcRange;
    satisfy adcRange by battSense;
}
```

- **Nominal:** 2.291 V, a pass with 0.4 % margin.
- **Worst case:** a fail, −0.5 %. At vin = 4.2 V, r1 = 99 kΩ (−1 %) and r2 = 121.2 kΩ (+1 %), the
  output is 2.31 V.
- **Monte Carlo** (1000 samples, seed 1): 100 % yield. Both resistors have to sit near opposite ends
  of their tolerance with a full cell, and in 1000 samples that never happened.

Whether that is acceptable is an engineering decision, which the model makes visible. Reduce R2, or
accept a rare saturation of the ADC on a fully charged cell.

## The EnviroNode

The EnviroNode's divider was sized in chapter 8 for 2.0 V at full charge, which leaves room for
tolerances. Annotate its values in `BatterySense`, in `model/node-parts.sysml`. The cell voltage
ranges over the cell's whole discharge curve, and the resistors are ±1 % parts:

<!-- check: project -->
```sysml
    /* Scales the battery voltage (up to 4.2 V) into the ADC's range: a divider with a filter capacitor. */
    part def BatterySense :> Component {
        private import Simulation::*;
        port top : Terminal;
        port tap : Terminal;
        port bottom : Terminal;
        attribute vin : ElectricPotentialValue = 4.2 [V] { @Tolerance { minimum = 3.0 [V]; maximum = 4.2 [V]; } }
        part r1 : Resistor {
            :>> resistance = 100 ['kΩ'] { @Tolerance { relative = 0.01; } }
            :>> powerRating = 63 [mW];
        }
        part r2 : Resistor {
            :>> resistance = 90.9 ['kΩ'] { @Tolerance { relative = 0.01; } }
            :>> powerRating = 63 [mW];
        }
        ...
    }
```

`private import Simulation::*;` inside the part definition makes `Tolerance` visible only there. An
import can go in any namespace, not just a package.

Run **Worst case** on `model/node-requirements.sysml`:

| ID | Margin | Worst case | Worst corner |
|---|---|---|---|
| ADC-1 | 13 % | ✓ 12 % | vin = 4.2 V, r1 = 99 kΩ, r2 = 91.81 kΩ |
| PWR-3 | 12 % | ✓ 11 % | vin = 4.2 V, r1 = 99 kΩ, r2 = 89.99 kΩ |

Both requirements hold at every corner. The worst cases are different corners: the highest output
comes with R2 high, the highest current with R2 low. Finding those by hand is exactly the kind of
work tolerance analysis takes off your hands. **Monte Carlo** with 1000 samples gives 100 % yield
for both.

PWR-1 (the lifetime) has the same margin at every corner: none of the toleranced values affects it.
Adding a tolerance to the cell's capacity or to the MCU's sleep current would change that; try it.

## Check yourself

1. Give the MCU's active current a ±20 % tolerance (`relative = 0.2`). What is PWR-1's worst-case
   margin?
2. Why does the worst case of a uniform ±1 % resistor pair not depend on the Monte Carlo seed?
3. Switch the resistors of the `AdcDivider` example to a normal distribution. Does the yield change?

<details><summary>Answers</summary>

1. Put `:>> activeCurrent = 4 [mA] { @Tolerance { relative = 0.2; } }` in `NodeMcu`, with
   `private import Simulation::*;` in `NodeParts`. At 4.8 mA the MCU draws about 49.5 µA on
   average, the cell about 74.8 µA, and the life drops to 2.93 years: PWR-1 fails at the worst case
   (−2.3 %) while still passing at nominal (9.4 %).
2. The worst case is not random: it evaluates the corners (all combinations of the limits). The
   seed only affects Monte Carlo.
3. With a normal distribution, values near the limits are even rarer (the limits are at ±3σ), so
   the yield stays at 100 %. The worst case is unchanged: it always uses the limits.

</details>

Next: [11. Analysis cases and trade studies](11-analysis.md)
