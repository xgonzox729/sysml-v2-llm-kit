# 8. Calculations and constraints

You have already used two calculations, `LedResistor` and `BatteryLife`, without defining one. This
chapter shows how to write your own **calculations**, how to state **constraints** (conditions
that must hold), and how to make the extension **solve** a constraint for an unknown value, such as
the resistor that gives a divider the right output.

## Calculations

A **calculation definition** (`calc def`) is a reusable formula: named inputs, one result.

<!-- check: standalone -->
```sysml
package Calculations {
    private import ISQ::*;
    private import SI::*;

    calc def DividerOutput {
        doc /* The output of a resistor divider. */
        in vin : ElectricPotentialValue;
        in r1 : ResistanceValue;
        in r2 : ResistanceValue;
        return : ElectricPotentialValue = vin * r2 / (r1 + r2);
    }

    attribute adcIn : ElectricPotentialValue = DividerOutput(4.2 [V], 100000 ['Ω'], 90900 ['Ω']);
    attribute same : ElectricPotentialValue = DividerOutput(r2 = 90900 ['Ω'], r1 = 100000 ['Ω'], vin = 4.2 [V]);
}
```

- `in` parameters are the inputs, each with a type. Their units are checked when the calculation is
  called (`unit-mismatch` if you pass a current where a voltage is expected).
- `return` is the result, with its type and the expression that computes it.
- Call a calculation like a function. Arguments are positional, `DividerOutput(4.2 [V], …)`, or
  named, `DividerOutput(vin = 4.2 [V], …)`.

A calculation can have several steps: write intermediate attributes in its body, then the `return`
expression that uses them.

<!-- check: standalone -->
```sysml
package Steps {
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;

    calc def LdoEfficiency {
        in vin : ElectricPotentialValue;
        in vout : ElectricPotentialValue;
        in iout : ElectricCurrentValue;
        in iq : ElectricCurrentValue;
        attribute pin : PowerValue = vin * (iout + iq);
        attribute pout : PowerValue = vout * iout;
        return : Real = pout / pin;
    }

    attribute eta : Real = LdoEfficiency(3.7 [V], 3.3 [V], 0.0667 [A] / 1000, 25 [A] / 1000000000);
}
```

The Electronics library has the calculations electronics engineers need most:

| Calculation | Result |
|---|---|
| `AverageCurrent(active, sleep, duty)` | the average of an active and a sleep current |
| `BatteryLife(capacity, averageCurrent, usable)` | time to empty |
| `DividerOutput(vin, r1, r2)` | divider output voltage |
| `LedResistor(supply, forwardVoltage, current)` | LED series resistor |
| `RcTimeConstant(r, c)`, `RcCutoff(r, c)` | τ = RC, f₋₃dB = 1/(2πRC) |
| `LinearDissipation(vin, vout, current)` | heat in a linear regulator |
| `TemperatureRise(power, thermalResistance)` | junction temperature rise |

## Constraints

A **constraint** is a Boolean expression: a condition on values. A **constraint definition** gives
it a name and parameters, so it can be reused.

<!-- check: standalone -->
```sysml
package Constraints {
    private import ISQ::*;
    private import SI::*;

    constraint def LdoHeadroom {
        doc /* An LDO regulates only with enough input voltage. */
        in vin : ElectricPotentialValue;
        in vout : ElectricPotentialValue;
        in dropout : ElectricPotentialValue;
        vin >= vout + dropout
    }

    part def PowerStage {
        attribute cellVoltage : ElectricPotentialValue = 3.7 [V];
        attribute outputVoltage : ElectricPotentialValue = 3.3 [V];
        attribute ldoDropout : ElectricPotentialValue = 0.15 [V];

        constraint headroom : LdoHeadroom {
            in vin = cellVoltage;
            in vout = outputVoltage;
            in dropout = ldoDropout;
        }
        assert constraint { cellVoltage <= 4.2 [V] }
    }
}
```

A constraint by itself **states** a condition; it doesn't claim the condition is true. It can serve
as a design target, a test or a solver input. An **assert constraint** claims the condition must
hold: if it doesn't, the extension reports an `assertion-failed` error.

<!-- check: standalone, expect: assertion-failed -->
```sysml
package FailingAssertion {
    private import ISQ::*;
    private import SI::*;
    part def PowerStage {
        attribute cellVoltage : ElectricPotentialValue = 3.0 [V];
        attribute outputVoltage : ElectricPotentialValue = 3.3 [V];
        assert constraint { cellVoltage >= outputVoltage + 0.15 [V] }
    }
}
```

The error reads *Assertion does not hold: 3 V >= 3.45 V is false (margin -13 %)*: the actual
value, the limit and how far apart they are. Requirements (chapter 9) are the more structured way
to say what must hold: they have IDs and text, and they say what satisfies them. Use asserts for
internal consistency ("the output can't exceed the input"), and requirements for what the
customer or the system needs.

## Solving for a value

A constraint relates values. When one of them is unknown, the extension can **solve** for it: find
the value that makes the constraint hold exactly. This is how you size a resistor without leaving
the model.

The command is **SysML: Solve for Attribute at Cursor**. Put the cursor on the attribute you want to
change, run the command, and pick the constraint to satisfy if there are several. The solver
searches for the value at which the constraint's two sides are equal, shows it, and offers a **Set
Value** button that writes it into the model.

## The EnviroNode: the battery-sense divider

The MCU measures the cell voltage with its ADC, through a divider that scales the cell's 4.2 V
maximum down to the ADC's range. A capacitor filters the divider output. Put the circuit in its own
part definition in `model/node-parts.sysml`. Start with two 100 kΩ resistors:

<!-- check: fragment -->
```sysml
    /* Scales the battery voltage (up to 4.2 V) into the ADC's range: a divider with a filter capacitor. */
    part def BatterySense :> Component {
        port top : Terminal;
        port tap : Terminal;
        port bottom : Terminal;
        attribute vin : ElectricPotentialValue = 4.2 [V];
        part r1 : Resistor {
            :>> resistance = 100 ['kΩ'];
            :>> powerRating = 63 [mW];
        }
        part r2 : Resistor {
            :>> resistance = 100 ['kΩ'];
            :>> powerRating = 63 [mW];
        }
        part c1 : Capacitor { :>> capacitance = 100 [nF]; :>> voltageRating = 10 [V]; }
        attribute vout : ElectricPotentialValue = DividerOutput(vin, r1.resistance, r2.resistance);
        attribute current : ElectricCurrentValue = vin / (r1.resistance + r2.resistance);
        /* The design target: a full cell gives 2.0 V at the ADC. */
        constraint fullScale { vout == 2.0 [V] }
        connect top to r1.p;
        connect r1.n to r2.p;
        connect r1.n to c1.p;
        connect r1.n to tap;
        connect r2.n to bottom;
        connect c1.n to bottom;
    }
```

- `top`, `tap` and `bottom` are the circuit's terminals. The `connect` lines wire the resistors and
  the capacitor inside it: the definition is a small schematic.
- `vout` and `current` are computed. The editor shows `⇒ 2.1 V` and `⇒ 21 µA`.
- `fullScale` states the design target: 2.0 V at the ADC with a full cell. It is a plain
  constraint, not an assert. With two equal resistors it doesn't hold yet.

Now solve for R2:

1. Put the cursor on `100` in `r2`'s `:>> resistance = 100 ['kΩ'];`.
2. Run **SysML: Solve for Attribute at Cursor**.
3. The only constraint that involves R2 (through `vout`) is `vout == 2.0 [V]`, so the solver uses it
   and reports **resistance = 90.91 kΩ**. Click **Set Value**: the text becomes `90.91 ['kΩ']`.
4. 90.91 kΩ is not a standard value; the nearest E96 resistor is 90.9 kΩ. Change it to
   `90.9 ['kΩ']`. `vout` is now 1.99995 V (the hint rounds it to `⇒ 2 V`): close enough, and chapter
   10 checks it against tolerances.

<!-- check: project -->
```sysml
        part r2 : Resistor {
            :>> resistance = 90.9 ['kΩ']
            ...
            :>> powerRating = 63 [mW];
        }
```

Finally, add the divider to `node` and connect its top to the cell, if you haven't already in
chapter 6:

<!-- check: project -->
```sysml
        part sense : BatterySense;
        ...
        connect battery.positive to sense.top;
```

## Check yourself

1. Write a `calc def RcSettling` that returns the time for an RC network to settle to within 0.1 %
   of its final value (about 6.9 τ).
2. With R1 = 100 kΩ, what R2 gives 1.8 V at the ADC from a 4.2 V cell? Solve it in the tool by
   changing `fullScale`.
3. Why is `fullScale` a plain constraint and not an `assert constraint`?

<details><summary>Answers</summary>

1. <!-- check: standalone -->
   ```sysml
   package Settling {
       private import ISQ::*;
       calc def RcSettling {
           in r : ResistanceValue;
           in c : CapacitanceValue;
           return : DurationValue = 6.9 * r * c;
       }
   }
   ```
2. 75 kΩ: 4.2 × R2 / (100 k + R2) = 1.8 gives R2 = 180 k / 2.4 = 75 kΩ.
3. With E96 values it never holds *exactly* (1.99995 V ≠ 2.0 V), and that is fine. It is a design
   target for the solver, not a property the design must meet. What must hold, that the output
   stays below the ADC's limit, is a requirement (chapter 9).

</details>

Next: [9. Requirements](09-requirements.md)
