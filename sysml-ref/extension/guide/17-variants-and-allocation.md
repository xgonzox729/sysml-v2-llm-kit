# 17. Variants, allocation and views

Real products come in versions, real functions run on real hardware, and real models grow large. This
chapter covers the three SysML features that manage that:
- **variability**: one model for a product line;
- **allocation**: which part carries out which function;
- **views**: showing a large model to different readers.

It ends with advice on organizing a project.

## Variants

The EnviroNode comes in two versions:
- **indoor:** a rechargeable Li-ion cell and Bluetooth LE;
- **outdoor:** a lithium primary cell, which loses almost no charge on the shelf, and LoRa for range.

Rather than two copies of the model, SysML describes the **variation points** and their **variants**
once, and **configurations** choose among them.

<!-- check: standalone -->
```sysml
package Variability {
    part def Radio;
    part def Ble :> Radio;
    part def LoRa :> Radio;

    variation part def RadioChoice :> Radio {
        variant part ble : Ble;
        variant part loRa : LoRa;
    }

    abstract part def NodeFamily {
        part radio : RadioChoice;
    }

    part indoor : NodeFamily {
        part :>> radio = radio::ble;
    }
}
```

- **`variation part def RadioChoice`** is a variation point: a radio that must be one of its
  **`variant`s**. A usage can be a variation point too: `variation part radio : Radio { variant … }`.
- **`part radio : RadioChoice`** in the family says "this node has a radio, to be chosen".
- **A configuration** redefines the variation points with a variant: `part :>> radio = radio::ble;`.
  `radio::ble` names the variant `ble` of `radio`'s variation.
- The family can **constrain** combinations with `assert constraint`. For example, LoRa needs the
  primary cell: `radio == radio::loRa implies battery == battery::lithiumPrimary`.

### Checks

For every configuration, the extension checks:

| Diagnostic | Meaning |
|---|---|
| `variant-choice` | A choice that isn't one of the point's variants (error), or a variation point the configuration doesn't choose (warning). |
| `variant-constraint` | The family's assertions don't hold for the variants chosen (error). |

### Configuration values

Firmware usually needs to know its configuration: which radio driver to build, the report period,
the cell's capacity for its fuel gauge. Annotate attributes with `@Config` (from the `Software`
library) to export them, with their value in each configuration, to the generated configuration
headers and Kconfig (chapter 20):

<!-- check: fragment -->
```sysml
    part def Settings {
        attribute reportPeriod : DurationValue = 15 [min] { @Config { name = "REPORT_PERIOD_S"; scale = 1 [s]; } }
    }
```

`scale = 1 [s]` exports the period in seconds: `#define CONFIG_REPORT_PERIOD_S 900`.

## The EnviroNode product line

Create `model/node-variants.sysml`:

<!-- check: project -->
```sysml
package NodeVariants {
    doc
    /*
     * The EnviroNode product line: the cell and the radio vary, and two configurations choose
     * them. Each configuration is checked against the family's constraints and generated as a
     * configuration header and a Kconfig defconfig.
     */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Electronics::*;
    private import Software::*;
    private import NodeParts::*;
    private import NodeArchitecture::*;

    variation part def CellChoice :> Battery {
        doc /* The cells a node can be built with. */
        variant part liIon : NodeCell {
            doc /* Rechargeable 18650: for nodes that can be serviced. */
        }
        variant part lithiumPrimary : Battery {
            doc /* Li-SOCl2 AA primary cell: flat 3.6 V, very low self-discharge, for remote nodes. */
            :>> chemistry = Chemistry::lithiumPrimary;
            :>> capacity = 2600 [mAh];
            :>> nominalVoltage = 3.6 [V];
            :>> maxCurrent = 100 [mA];
        }
    }

    variation part def RadioChoice :> Radio {
        doc /* The radios a node can be built with. */
        variant part loRa : LoRaRadio {
            doc /* Long range (kilometres), high transmit current. */
        }
        variant part ble : Radio {
            doc /* Bluetooth LE: short range, low current. */
            :>> partNumber = "nRF52805";
            :>> activeCurrent = 5 [mA];
            :>> sleepCurrent = 0.3 ['µA'];
            :>> dutyCycle = 0.002;
        }
    }

    abstract part nodeFamily : EnviroNode {
        part battery : CellChoice;
        part radio : RadioChoice;
        attribute :>> reportPeriod = 15 [min] { @Config { name = "REPORT_PERIOD_S"; scale = 1 [s]; } }
        attribute cellCapacity : ElectricChargeValue = battery.capacity { @Config { name = "CELL_CAPACITY_MAH"; scale = 1 [mAh]; } }
        /* A LoRa node is installed far away: it needs the primary cell's decade-long shelf life
         * (a Li-ion cell loses a few per cent of its charge a month). */
        assert constraint loRaNeedsPrimaryCell { radio == radio::loRa implies battery == battery::lithiumPrimary }
    }

    part outdoorNode :> nodeFamily {
        part :>> battery = battery::lithiumPrimary;
        part :>> radio = radio::loRa;
    }

    part indoorNode :> nodeFamily {
        part :>> battery = battery::liIon;
        part :>> radio = radio::ble;
        attribute :>> reportPeriod = 5 [min];
    }
}
```

- The variants reuse the part definitions of `node-parts.sysml` (`NodeCell`, `LoRaRadio`) or describe
  a part in place (`lithiumPrimary`, `ble`).
- `nodeFamily` is `abstract`: no node is "just a family", every real node is a configuration.
- `cellCapacity` is computed from whichever cell is chosen, so each configuration exports its own
  value: 2600 mAh for the outdoor node, 2400 mAh for the indoor one.
- `indoorNode` also redefines the report period: indoor nodes report every 5 minutes.

The file has no diagnostics: both configurations choose every variation point with a valid variant,
and both satisfy `loRaNeedsPrimaryCell`. Now break it. In `indoorNode`, change the radio to
`radio::loRa`. The configuration violates the family's constraint:

> *indoorNode violates a constraint of its family: radio == radio::loRa implies battery ==
> battery::lithiumPrimary* [`variant-constraint`]

Change it back. Then delete the `part :>> battery = …` line of `outdoorNode`:

> *outdoorNode does not choose a variant for battery (liIon, lithiumPrimary).* [`variant-choice`]

Put it back. Chapter 20 generates `config_outdoor_node.h`, `config_indoor_node.h`, their defconfigs
and a Kconfig file from this model.

## Allocation

Behaviour and structure meet through **allocation**: `allocate a to b` says that `b` carries out (or
holds) `a`. Typical uses:
- functions to components (the measurement cycle runs on the MCU);
- software to processors (the firmware runs on the MCU, chapter 19);
- logical to physical (the "radio link" function is realized by the LoRa radio).

<!-- check: standalone -->
```sysml
package Allocation {
    action def Measure;
    part def Mcu;
    part def Board {
        perform action measure : Measure;
        part mcu : Mcu { }
        allocate measure to mcu;
    }
}
```

An allocation is a connection like any other: it can be named and typed (`allocation def`), and it
appears in its owner's *allocations* compartment in the General view. When both of its ends are
drawn as boxes, it is also drawn as a dashed arrow labelled «allocate».

In the EnviroNode, the measurement cycle runs on the MCU. Add the allocation to `node` in
`model/node-architecture.sysml`:

<!-- check: project -->
```sysml
        /* The measurement cycle runs on the MCU. */
        allocate measurementCycle to mcu;
```

`measurementCycle` is the action every `EnviroNode` performs (chapter 13), and `node` inherits it from
its definition.

## Views

A large model needs different pictures for different readers: the power tree for the hardware
review, the message flows for the firmware team, the requirements for the customer. SysML has
**viewpoints** (a concern and who has it) and **views** (what part of the model to show for a
viewpoint):

<!-- check: standalone -->
```sysml
package Views {
    part def Node { part battery; part radio; }
    part node : Node;

    viewpoint def PowerReview {
        doc /* What the power review needs to see. */
    }

    view def PowerView {
        satisfy requirement : PowerReview;
    }

    view powerView : PowerView {
        expose node::battery;
    }
}
```

`expose` selects the elements a view shows. The EnviroNode has a view per review, in
`model/node-views.sysml`:

<!-- check: project -->
```sysml
package NodeViews {
    doc /* What each review of the EnviroNode looks at: a view per review, exposing the elements it needs. */
    private import NodeArchitecture::*;
    private import NodeRequirements::*;

    viewpoint def PowerReview {
        doc /* The hardware review: the power tree and the battery life. */
    }
    viewpoint def FirmwareReview {
        doc /* The firmware review: the MCU, its tasks and memory. */
    }

    view def PowerView { satisfy requirement : PowerReview; }
    view def FirmwareView { satisfy requirement : FirmwareReview; }

    view powerView : PowerView {
        expose node::battery;
        expose node::ldo;
        expose node::sensorLdo;
        expose nodeLifetime;
    }
    view firmwareView : FirmwareView {
        expose node::mcu;
        expose node::firmware::*;
    }
}
```

`node::firmware::*` exposes everything in the firmware. The extension doesn't render `view` usages
specially.
Its diagrams are views of their own:
- the **General** view for definitions and their relationships;
- **Interconnection** for structure and connections;
- **Action flow** and **State machine** for behaviour.

You choose what they show by opening them on the element you want (*Open Diagram of Element at
Cursor*), by depth, and with the filter. Use SysML views to *document* which pictures a review needs,
and the extension's diagrams to *draw* them.

## Organizing a project

A few rules that keep a model workable as it grows:

- **One file per concern**, each holding one top-level package: parts, architecture, requirements,
  analyses, behaviour, interfaces, software, variants. The EnviroNode project shows the layout.
  Smaller files mean smaller diffs, fewer merge conflicts and clear ownership.
- **Definitions in libraries, usages in systems.** Part definitions (the datasheets) change rarely
  and are reused; put them in their own package, and reuse them across projects as a company parts
  library. Systems (`node`, `fieldInstallation`) use them.
- **Private imports.** Import what each file needs, privately. The dependencies between your packages
  stay visible and acyclic: architecture imports parts, requirements import architecture, never the
  other way round.
- **IDs in short names.** `requirement def <'PWR-1'> NodeLifetime` keeps the ID stable when the name
  changes, and readable in every report.
- **`doc` everything that matters.** Generated documents (chapter 21) are only as good as the `doc`
  comments.
- **Git.** The textual notation is made for version control: commit the model, review changes in pull
  requests, and let CI run the checks (chapter 21). *Compare Model with HEAD* (chapter 21) shows what
  changed in the model, not just in the text.

## Check yourself

1. Add a third configuration, `testNode`, with the Li-ion cell and the LoRa radio. What does the
   extension say?
2. Why is `nodeFamily` typed by `EnviroNode`?
3. What is the difference between `perform action measurementCycle` and `allocate measurementCycle to
   mcu`?

<details><summary>Answers</summary>

1. *testNode violates a constraint of its family: radio == radio::loRa implies battery ==
   battery::lithiumPrimary* [`variant-constraint`]. A LoRa node needs the primary cell.
2. So that every configuration is an EnviroNode. The requirements of chapter 9, which have
   `EnviroNode` as their subject, apply to every configuration, and `reportPeriod` is the same feature
   everywhere.
3. `perform` says the node (as a whole) does the measurement cycle: what. `allocate` says which of its
   parts carries it out: who. The first is a functional statement, the second a design decision.

</details>

Next: [18. Use cases](18-use-cases.md)
