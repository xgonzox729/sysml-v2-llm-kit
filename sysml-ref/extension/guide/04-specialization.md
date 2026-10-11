# 4. Specialization and redefinition

Datasheets come in families. An "LDO" has a dropout voltage and a quiescent current. A TPS7A02
*is* an LDO with particular values. A TPS7A0233 *is* a TPS7A02 fixed at 3.3 V. SysML captures that
family tree with **specialization**, and lets a more specific definition or usage **redefine**
what it inherits.

## Specialization: "is a kind of"

`part def B :> A` says **B specializes A**: every B is an A. B inherits all of A's features
(attributes, ports, parts) and may add more.

<!-- check: standalone -->
```sysml
package Specialization {
    private import ISQ::*;

    abstract part def Regulator {
        attribute outputVoltage : ElectricPotentialValue;
        attribute maxOutputCurrent : ElectricCurrentValue;
    }

    part def Ldo :> Regulator {
        attribute dropout : ElectricPotentialValue;        // added
    }

    part def BuckConverter :> Regulator {
        attribute switchingFrequency : FrequencyValue;     // added
    }

    part def Board {
        part reg : Ldo;    // reg has outputVoltage, maxOutputCurrent and dropout
    }
}
```

`:>` is shorthand for the keyword `specializes`: `part def Ldo specializes Regulator` means the
same.

**Abstract** definitions, like `Regulator` here, are kinds that are never used directly: no
actual part is "just a regulator", it is always some particular kind. Marking them `abstract`
documents that.

Every definition specializes something even if you don't write it: a `part def` implicitly
specializes `Parts::Part` from the standard library, an `attribute def` specializes
`Base::DataValue`, and so on. That is where features such as a part's `ownedPorts` come from.

## Redefinition: changing what you inherit

A specialization can do more than add features: it can **redefine** inherited ones, to give a
value, narrow the type or change the multiplicity. Write `:>>` (or `redefines`) and the name of the
inherited feature:

<!-- check: standalone -->
```sysml
package Redefinition {
    private import ISQ::*;
    private import SI::*;

    part def Ldo {
        attribute outputVoltage : ElectricPotentialValue;
        attribute dropout : ElectricPotentialValue;
    }

    part def TPS7A0233 :> Ldo {
        :>> outputVoltage = 3.3 [V];             // fix the inherited attribute's value
        attribute redefines dropout = 0.15 [V];  // the long form says the same
    }

    part def Board {
        part u2 : TPS7A0233;                     // u2.outputVoltage is 3.3 V
    }
}
```

`:>> outputVoltage = 3.3 [V];` reads "this definition's `outputVoltage` is the inherited one, and its
value is 3.3 V". You don't repeat the type; it is inherited too. The `[V]` is a unit; chapter 5 is
about them.

Usages redefine too. A usage typed by a definition can redefine that definition's features, for
one particular use:

<!-- check: standalone -->
```sysml
package UsageRedefinition {
    private import ISQ::*;
    private import SI::*;
    part def Resistor { attribute resistance : ResistanceValue; }
    part def Divider {
        part r1 : Resistor { :>> resistance = 100000 ['Ω']; }
        part r2 : Resistor { :>> resistance = 47000 ['Ω']; }
    }
}
```

This is how you will give every part of the EnviroNode its values: the definition says *which*
values exist, and the specialization or usage says *what* they are.

## Subsetting: a feature that is part of another

Specialization relates definitions. Between usages, the relationship "is one of" is
**subsetting**, also written `:>`:

<!-- check: standalone -->
```sysml
package Subsetting {
    part def Capacitor;
    part def Board {
        part capacitors : Capacitor[0..*];
        part decoupling : Capacitor[4] :> capacitors;   // the four decoupling caps are some of the capacitors
        part bulk : Capacitor :> capacitors;
    }
}
```

Every decoupling capacitor is also one of `capacitors`, so a BOM that lists `capacitors` lists
them too. You won't need subsetting often in this guide, but you will meet it in libraries: the
standard library uses it everywhere.

## The Electronics library

This extension comes with a library of electronic parts, `Electronics`, written in SysML (Appendix
[C](C-extension-libraries.md) lists it). Its definitions form a family tree:

```
Component                         partNumber, derating, power, spiceModel…
├── TwoTerminal                   ports p, n; voltage, current
│   ├── Resistor                  resistance, powerRating
│   ├── Capacitor, Inductor, Ferrite, Fuse
│   └── VoltageSource, CurrentSource
├── Diode ── LED, SchottkyDiode, ZenerDiode
├── MOSFET, BJT, Switch ── Relay
├── Battery                       capacity, nominal/full/cutoff voltage, supply port
├── Regulator                     input and output supply ports
│   ├── LDO                       dropout
│   └── SwitchingRegulator ── BuckConverter, BoostConverter
├── LoadSwitch
└── PoweredDevice                 supply port, active/sleep current, duty cycle
    ├── Microcontroller           flash, ram, clockFrequency
    ├── Sensor, Radio, OpAmp, Oscillator
```

You use it the way you use a vendor's component library: specialize a generic part and fill in
the datasheet values. Press **F12** on `Battery` in your model to read its definition. The
attributes and their comments are the documentation.

## In the tool

1. **Hover** over `NodeCell` (once you have written it, below): the tooltip shows
   `part def NodeCell :> Battery`. Hover over `capacity` in `:>> capacity = 2400 [mAh];` to see the
   redefined attribute.
2. **F12** on `Battery` opens `Electronics.sysml` at its definition. **Shift+F12** on `capacity`
   there lists every redefinition of it in your model.
3. In a diagram, specialization is a line with a hollow triangle pointing at the general
   definition, when both are on the diagram. Open the diagram of the `Specialization` snippet
   above to see `Ldo` and `BuckConverter` pointing at `Regulator`.

## The EnviroNode

Fill in the first three definitions in `model/node-parts.sysml` with their datasheet values. Each
`:>>` line redefines an attribute inherited from `Battery` or `LDO`:

<!-- check: project -->
```sysml
    /* A rechargeable lithium-ion cell (18650 size). */
    part def NodeCell :> Battery {
        :>> chemistry = Chemistry::liIon;
        :>> capacity = 2400 [mAh];
        :>> nominalVoltage = 3.7 [V];
        :>> fullVoltage = 4.2 [V];
        :>> cutoffVoltage = 3.0 [V];
        :>> maxCurrent = 1 [A];
    }
    comment about NodeCell /* Any protected 18650 cell with at least 2400 mAh fits the holder. */

    /* A low-quiescent-current LDO: 3.3 V for the MCU and the radio. */
    part def MainLdo :> LDO {
        :>> partNumber = "TPS7A0233";
        :>> outputVoltage = 3.3 [V];
        :>> dropout = 0.15 [V];
        :>> maxOutputCurrent = 200 [mA];
        :>> quiescentCurrent = 25 [nA];
        :>> minInputVoltage = 1.5 [V];
        :>> maxInputVoltage = 6 [V];
    }

    /* A second LDO: 1.8 V for the sensor, fed from the 3.3 V rail. */
    part def SensorLdo :> LDO {
        :>> partNumber = "TPS7A0218";
        :>> outputVoltage = 1.8 [V];
        :>> dropout = 0.15 [V];
        :>> maxOutputCurrent = 200 [mA];
        :>> quiescentCurrent = 25 [nA];
        :>> minInputVoltage = 1.5 [V];
        :>> maxInputVoltage = 6 [V];
    }
```

`Chemistry::liIon` is a value of an **enumeration**: `Chemistry` is an `enum def` in the
Electronics library listing the cell chemistries. Strings (`"TPS7A0233"`) are written in double
quotes. The `comment about NodeCell` (chapter 2) records a note that travels with the definition.

The node also has capacitors: four 100 nF decoupling capacitors, one per supply pin, and a 10 µF bulk
capacitor. All of them are "the node's capacitors", which is what subsetting says. Add them to `node`
in `model/node-architecture.sysml`, after `sense`:

<!-- check: project -->
```sysml
        /* Capacitors: one 100 nF per supply pin, and a bulk capacitor. */
        part capacitors : Capacitor[0..*];
        part decoupling : Capacitor[4] :> capacitors { :>> capacitance = 100 [nF]; :>> voltageRating = 10 [V]; }
        part bulk : Capacitor :> capacitors { :>> capacitance = 10 ['µF']; :>> voltageRating = 6.3 [V]; }
```

`decoupling` stands for four capacitors (its multiplicity), so the bill of materials of chapter 21
counts four. `capacitors` has no count of its own: it is the collection the others belong to.

## Check yourself

1. `part def TPS7A02 :> LDO` and `part def TPS7A0233 :> TPS7A02`. Does a `TPS7A0233` have a
   `dropout` attribute?
2. What is wrong with `part def NodeCell :> Battery { attribute capacity = 2400 [mAh]; }`?
3. Make a `part def GreenLed :> LED` with a forward voltage of 2.1 V.

<details><summary>Answers</summary>

1. Yes. Specialization is transitive: `TPS7A0233` inherits everything from `TPS7A02`, which
   inherits `dropout` from `LDO`.
2. Without `:>>` (or `redefines`), `attribute capacity` declares a *second*, unrelated attribute
   that happens to have the same name: a `NodeCell` then has two capacities, the inherited one
   without a value and the new one. Readers and other SysML tools can't tell which one is meant.
   Write `:>> capacity = 2400 [mAh];` to give the inherited attribute its value.
3. <!-- check: standalone -->
   ```sysml
   package Leds {
       private import SI::*;
       private import Electronics::*;
       part def GreenLed :> LED { :>> forwardVoltage = 2.1 [V]; }
   }
   ```

</details>

Next: [5. Attributes, quantities and units](05-attributes-and-units.md)
