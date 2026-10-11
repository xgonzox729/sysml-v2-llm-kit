# 5. Attributes, quantities and units

Parts are things; **attributes** are the values that describe them: a voltage, a current, a part
number, a duty cycle. This chapter shows how to write values with their units, how to compute one
value from others, and how the extension evaluates them and catches unit mistakes.

## Attributes

An **attribute** is a feature whose values are data: numbers, quantities, strings, enumeration
literals. Unlike a part, an attribute value has no identity of its own. Two 3.3 V values are simply
the same value, while two LDOs are two different parts even if they are identical.

<!-- check: standalone -->
```sysml
package Attributes {
    private import ScalarValues::*;

    enum def Package { SOT23; SOIC8; QFN16; }

    part def Ldo {
        attribute partNumber : String;
        attribute pinCount : Integer;
        attribute adjustable : Boolean;
        attribute gainError : Real;
        attribute housing : Package;
    }

    part u2 : Ldo {
        :>> partNumber = "TPS7A0233";
        :>> pinCount = 4;
        :>> adjustable = false;
        :>> gainError = 0.01;
        :>> housing = Package::SOT23;
    }
}
```

- **Scalar types** come from the `ScalarValues` library: `Real`, `Integer`, `Natural` (0, 1, 2…),
  `Boolean`, `String`.
- An **enumeration** (`enum def`) lists the possible values; refer to one as `Package::SOT23`.
- **Your own attribute types** use `attribute def`, for structured values. An `attribute def`
  can have attributes of its own, like a C struct; chapter 20 turns such types into C code.

## Quantities and units

Engineering values have **units**. SysML's standard library includes the ISO 80000 International
System of Quantities (**ISQ**) and the SI units:

<!-- check: standalone -->
```sysml
package Quantities {
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;

    part def Board {
        attribute supply : ElectricPotentialValue = 3.3 [V];
        attribute sleepCurrent : ElectricCurrentValue = 1.5 ['µA'];
        attribute capacity : ElectricChargeValue = 2400 [mAh];
        attribute pullUp : ResistanceValue = 4.7 ['kΩ'];
        attribute clock : FrequencyValue = 32 [MHz];
        attribute wakeInterval : DurationValue = 15 [min];
        attribute flash : StorageCapacityValue = 192 [KiB];
    }
}
```

- The **type** says what kind of quantity an attribute is: `ElectricPotentialValue` (a voltage),
  `ElectricCurrentValue`, `PowerValue`, `DurationValue`, `TemperatureValue`… Press **F12** on one
  to browse the ISQ library.
- The **value** is a number followed by a unit in brackets: `3.3 [V]`. Units are elements of the
  `SI` package (`V`, `A`, `W`, `s`, `Hz`, `m`…). This extension's `EngineeringUnits` library adds
  the ones engineers use daily: `mA`, `µA`, `nA`, `mV`, `mW`, `kΩ`, `MΩ`, `µF`, `nF`, `pF`, `mAh`,
  `Wh`, `ms`, `µs`, `wk`, `yr`, `kHz`, `MHz`, `KiB`, `MiB` and more (Appendix
  [C](C-extension-libraries.md)). Minutes, hours and days (`min`, `h`, `d`) are in `SI`.
- A unit whose name is not a plain identifier is quoted: `['µA']`, `['kΩ']`, `['Ω']`. The `µ` is
  the micro sign (⌥M on a Mac keyboard).

Values are stored with their dimension (voltage, current, time…) and converted as needed:
`2400 [mAh]` divided by `66.8 ['µA']` is a duration, and the tools show it in whichever unit reads
best (`3.28 yr`).

## Expressions

A value can be computed from other values:

<!-- check: standalone -->
```sysml
package Expressions {
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;

    part def Load {
        attribute activeCurrent : ElectricCurrentValue;
        attribute sleepCurrent : ElectricCurrentValue;
        attribute dutyCycle : Real;
        attribute averageCurrent : ElectricCurrentValue = activeCurrent * dutyCycle + sleepCurrent * (1 - dutyCycle);
    }

    part radio : Load {
        :>> activeCurrent = 12 [mA];
        :>> sleepCurrent = 0.4 ['µA'];
        :>> dutyCycle = 0.002;
    }

    part board {
        part mcu : Load { :>> activeCurrent = 4 [mA]; :>> sleepCurrent = 1.5 ['µA']; :>> dutyCycle = 0.01; }
        attribute total : ElectricCurrentValue = mcu.averageCurrent + radio.averageCurrent;
        attribute fits : Boolean = total < 100 ['µA'];
        attribute label : String = if fits ? "low power" else "check the budget";
    }
}
```

You can use:
- **arithmetic** (`+ - * / **`), **comparison** (`< <= == != >= >`) and **logic** (`and`, `or`,
  `not`, `xor`, `implies`);
- **conditionals**: `if c ? a else b`, and `x ?? y` (x, or y when x has no value);
- **feature chains**: `mcu.averageCurrent` is the `averageCurrent` of the part `mcu`;
- **calls** of calculations and library functions: `sqrt(x)`, `max(a, b)`, `sum(currents)`. Chapter 8
  shows how to define your own.

Note how `averageCurrent` is defined *once*, in `Load`, and evaluates differently for `radio` and
for `board.mcu`: a value is always evaluated **in context**, with the redefinitions made there.

## `=` and `default`

`attribute x = 3 [V];` **binds** x to 3 V: x always equals that value, and a specialization cannot
give it another one. `attribute x default 3 [V];` gives a **default**, which a specialization or
usage may redefine. Library definitions use defaults where you are expected to override them.

## In the tool

Paste the `Expressions` snippet into a file and look at it:

1. **Inlay hints.** After `= mcu.averageCurrent + radio.averageCurrent` the editor shows
   `⇒ 65.9 µA`, the evaluated value, in grey. Computed values get a hint; plain literals like
   `3.3 [V]` don't, since that would repeat what you wrote. The hints are recomputed as you type.
2. **Hover** over `total`: the tooltip shows its value too.
3. **The SysML Values view.** Put the cursor on `part board` and run **SysML: Evaluate Element at
   Cursor** (also in the editor's context menu). The **SysML Values** view in the Explorer lists
   `board` with every attribute and its value, including the inherited ones (`mcu.dutyCycle = 0.01`).
   Without a selection, **SysML: Show Values of Current Document** lists all the top-level parts.
   Right-click a value and choose **Copy Value**. The view follows your edits.

### Unit errors

The extension checks every expression for dimension errors as you type:

<!-- check: standalone, expect: dimension-mismatch, unit-mismatch, missing-unit -->
```sysml
package UnitErrors {
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;

    part def Board {
        attribute v : ElectricPotentialValue = 3.3 [V];
        attribute i : ElectricCurrentValue = 2 [mA];
        attribute wrong1 : ElectricPotentialValue = v + i;      // dimension-mismatch: volts plus amps
        attribute wrong2 : ElectricCurrentValue = v / 1 [s];    // unit-mismatch: V/s is not a current
        attribute wrong3 : ElectricPotentialValue = 3.3;        // missing-unit: a plain number for a voltage
    }
}
```

| Diagnostic | Meaning |
|---|---|
| `dimension-mismatch` | Quantities of different dimensions are added, subtracted or compared. |
| `unit-mismatch` | The value's dimension is not what the attribute's quantity type expects. This also applies to the arguments of calculations. |
| `missing-unit` | A plain number is given to a quantity-typed attribute (a warning). |

These catch the classic spreadsheet errors (mA vs A, mW vs W) before they reach a power budget.

## The EnviroNode

Give the remaining parts their datasheet values in `model/node-parts.sysml`. The microcontroller:

<!-- check: project -->
```sysml
    /* The microcontroller: I²C to the sensor, SPI to the radio, a pin for the status LED. */
    part def NodeMcu :> Microcontroller {
        :>> partNumber = "STM32L072";
        :>> minSupplyVoltage = 1.8 [V];
        :>> maxSupplyVoltage = 3.6 [V];
        :>> activeCurrent = 4 [mA];
        :>> sleepCurrent = 1.5 ['µA'];
        :>> dutyCycle = 0.01;
        :>> clockFrequency = 32 [MHz];
        :>> flash = 192 [KiB];
        :>> ram = 20 [KiB];
        ...
    }
```

`activeCurrent`, `sleepCurrent` and `dutyCycle` come from `PoweredDevice`, which `Microcontroller`
specializes. `PoweredDevice` computes `averageCurrent` from them, the way `Load` did above. The duty
cycle is the fraction of time the part is awake. 1 % is a budgeting assumption for now (wake-ups,
retries, firmware updates); chapter 15 simulates the real schedule.

The sensor, the radio and the LED:

<!-- check: project -->
```sysml
    /* The temperature sensor. It runs from the 1.8 V rail, so its I²C pins are 1.8 V logic. */
    part def TMP117 :> Sensor {
        :>> partNumber = "TMP117";
        :>> minSupplyVoltage = 1.7 [V];
        :>> maxSupplyVoltage = 5.5 [V];
        :>> activeCurrent = 135 ['µA'];
        :>> sleepCurrent = 0.15 ['µA'];
        :>> dutyCycle = 0.005;
        ...
    }

    /* The LoRa radio. Its active current is the transmit current. */
    part def LoRaRadio :> Radio {
        :>> partNumber = "SX1262";
        :>> minSupplyVoltage = 1.8 [V];
        :>> maxSupplyVoltage = 3.7 [V];
        :>> activeCurrent = 12 [mA];
        :>> txCurrent = 45 [mA];
        :>> rxCurrent = 5 [mA];
        :>> sleepCurrent = 0.4 ['µA'];
        :>> dutyCycle = 0.002;
        ...
    }
    ...
    /* The status LED. */
    part def StatusLed :> LED {
        :>> forwardVoltage = 2.0 [V];
        :>> maxForwardCurrent = 20 [mA];
        :>> current = 2 [mA];
        ...
    }
```

(The radio's `activeCurrent` is the average over its active time: transmitting at 45 mA and
receiving at 5 mA.)

Finally, the LED's series resistor, in `node` in `model/node-architecture.sysml`. Its resistance is
*calculated* from the supply, the LED's forward voltage and the LED current, with the
`LedResistor` calculation from the Electronics library:

<!-- check: project -->
```sysml
        part ledResistor : Resistor {
            :>> resistance = LedResistor(3.3 [V], led.forwardVoltage, led.current);
            :>> current = led.current;
            :>> powerRating = 63 [mW];
        }
```

The editor shows `⇒ 650 Ω` after the resistance: (3.3 V − 2.0 V) / 2 mA. Change the LED current to
`5 [mA]` in `StatusLed` and the hint becomes `⇒ 260 Ω`. Change it back.

## Check yourself

1. Write an attribute for a 100 nF capacitance, and one for a 10 ms timeout.
2. The radio's average current is `activeCurrent * dutyCycle + sleepCurrent * (1 - dutyCycle)`.
   With the EnviroNode's radio values, what is it? Check your answer with **Evaluate Element at
   Cursor** on `part radio` in `model/node-architecture.sysml`.
3. What does the extension report for `attribute p : PowerValue = 3.3 [V] * 2 [mA] * 1 [s];`?

<details><summary>Answers</summary>

1. `attribute c : CapacitanceValue = 100 [nF];` and `attribute timeout : DurationValue = 10 [ms];`
2. 12 mA × 0.002 + 0.4 µA × 0.998 = 24 µA + 0.3992 µA ≈ 24.4 µA. The Values view shows
   `averageCurrent = 24.4 µA`.
3. `unit-mismatch`: V × A × s is energy (joules), not power.

</details>

Next: [6. Ports, connections and interfaces](06-ports-and-interfaces.md)
