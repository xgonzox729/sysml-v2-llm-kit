# 3. Parts: definitions and usages

The most important idea in SysML is the difference between a **definition** and a **usage**. Once
it clicks, the rest of the language follows the same pattern. This chapter introduces it with
parts, the physical (or logical) pieces of a system, and builds the structure of the EnviroNode.

## Definitions and usages

An electronics engineer already knows the idea:

| Electronics | SysML | Software |
|---|---|---|
| A **datasheet**: what every LM317 is and has | a **definition**: `part def LM317` | a class |
| A **reference designator** on a schematic: *U3 is an LM317, used here* | a **usage**: `part u3 : LM317` | a field of a class (an instance in context) |

A **definition** (`part def`) describes a kind of thing: its features, its ports, its parts, its
values. It says nothing about where it is used.

A **usage** (`part`) is a use of a definition in a particular context: *this* board has *a* U3 that
is an LM317. Writing `part u3 : LM317` means "u3 is typed by LM317": u3 has everything LM317
defines. The usage can also add things of its own or change values; chapters 4 and 5 show how.

<!-- check: standalone -->
```sysml
package DefinitionsAndUsages {
    part def LM317;                     // a kind of regulator (definition)
    part def Capacitor;

    part def PowerBoard {               // a kind of board...
        part u3 : LM317;                // ...that contains a regulator (usage)
        part c5 : Capacitor;
        part c6 : Capacitor;            // two usages of one definition
    }

    part board1 : PowerBoard;           // one actual board in our system
}
```

Every construct you will learn comes in this pair: `attribute def` / `attribute`, `port def` /
`port`, `action def` / `action`, `state def` / `state`, `requirement def` / `requirement`. The
definition says what something is; the usage says where it is used and how.

## Decomposition

A part usage inside a definition (or inside another usage) is **owned** by it. That is
**composition**: the parts are the pieces the whole is made of, and they come and go with it.
Nesting parts gives a **decomposition tree**:

<!-- check: standalone -->
```sysml
package Decomposition {
    part def Mcu;
    part def Flash;
    part def Crystal;

    part def ControllerModule {
        part mcu : Mcu;
        part flash : Flash;
        part xtal : Crystal;
    }

    part def Product {
        part controller : ControllerModule;
        part display {                  // a usage without a definition of its own
            part backlight;
            part panel;
        }
    }
}
```

`display` has no type: a usage can stand on its own and be described in place. That is handy for
one-off pieces. As soon as you need a second display, make a `part def Display` and type both
usages with it.

## Multiplicity

A usage can stand for several things: write the **multiplicity** in brackets after the type.

<!-- check: standalone -->
```sysml
package Multiplicity {
    part def Capacitor;
    part def Sensor;
    part def Board {
        part decoupling : Capacitor[4];        // exactly four
        part sensors : Sensor[1..8];           // one to eight
        part spares : Capacitor[0..*];         // any number, maybe none
        part backup : Capacitor[0..1];         // optional
    }
}
```

Without a multiplicity, a part usage means exactly one.

## References

Not every relationship is ownership. A board is *connected to* a host computer, but the host is
not one of its parts. Use `ref` for parts that are referred to, not owned:

<!-- check: standalone -->
```sysml
package References {
    part def Computer;
    part def Probe {
        ref part host : Computer;     // the probe knows its host, but doesn't contain it
    }
}
```

## In the tool: the General view

Open the `hello.sysml` file from chapter 1, or the snippet above, and open its diagram
(**⌥⌘D** / **Ctrl+Alt+D**). This is the **General view**:

- **Definitions** are boxes with a «part def» keyword. **Usages** have rounded corners and show their
  type after a colon (`u3 : LM317`).
- Each box has **compartments**: *parts*, *attributes*, *ports* and so on, one line per feature.
- **Edges:** a filled diamond is composition (owner to owned part), a dashed line with a hollow
  triangle is typing (usage to its definition), and a hollow triangle is specialization
  (chapter 4).
- A part usage that declares features of its own in braces (`part display { part panel; }`) is
  drawn as a box too, nested parts and all, down to the **depth** set in the toolbar (2 by
  default). A usage without such a body stays a line in its owner's *parts* compartment.

To navigate:

- **double-click** a box to show a diagram of just that element, **↑** to go to its owner and
  **⌂** to go back to the whole file;
- **click** a box to reveal its declaration in the text, and put the text cursor on a declaration
  to highlight its box;
- **Filter** highlights elements by name or kind;
- **Fit** zooms to show everything, and **Export** saves the diagram as SVG or PNG;
- the **SysML Model** tree's diagram icon, or **SysML: Open Diagram of Element at Cursor** in the
  editor's context menu, opens a diagram of one element directly.

## The EnviroNode

The node is built from these parts:

| Part | What it is |
|---|---|
| `battery` | an 18650 lithium-ion cell |
| `ldo` | a 3.3 V low-dropout regulator for the MCU and the radio |
| `sensorLdo` | a 1.8 V LDO for the sensor |
| `mcu` | the microcontroller |
| `sensor` | a TMP117 temperature sensor |
| `radio` | an SX1262 LoRa radio |
| `shifter` | an I²C level shifter (1.8 V ↔ 3.3 V) |
| `led` and `ledResistor` | the status LED and its series resistor |
| `sense` | a divider that lets the MCU measure the cell voltage |

### Step 1: the part definitions

In `model/node-parts.sysml`, declare a definition for each kind of part, after the imports you
wrote in chapter 2:

<!-- check: project -->
```sysml
package NodeParts {
    ...
    part def NodeCell :> Battery {
        ...
    }
    ...
    part def MainLdo :> LDO {
        ...
    }
    ...
    part def SensorLdo :> LDO {
        ...
    }
    ...
    part def NodeMcu :> Microcontroller {
        ...
    }
    ...
    part def TMP117 :> Sensor {
        ...
    }
    ...
    part def LoRaRadio :> Radio {
        ...
    }
    ...
    part def I2CLevelShifter :> Component {
        ...
    }
    ...
    part def StatusLed :> LED {
        ...
    }
    ...
    part def BatterySense :> Component {
        ...
    }
}
```

For now, leave the bodies empty: write `{ }` or `;`. You fill them in during the next chapters.
`:> Battery` reads "is a kind of Battery". It makes `NodeCell` a special case of the `Battery`
definition from the Electronics library, so it inherits everything a battery has. Chapter 4 is
about exactly that.

### Step 2: the node

Create `model/node-architecture.sysml`. It holds the system itself: a definition of what an
EnviroNode is, and `node`, the one we are designing, with its parts:

<!-- check: project -->
```sysml
package NodeArchitecture {
    doc
    /*
     * The EnviroNode: a battery-powered sensor node that measures temperature and reports it
     * over LoRa. This file is its structure: the parts it is made of and how they connect.
     */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Electronics::*;
    private import NodeParts::*;
    ...
    part def EnviroNode {
        doc /* A battery-powered environmental sensor node. */
        ...
    }
    ...
    part node : EnviroNode {
        ...
        part battery : NodeCell;
        part ldo : MainLdo;
        part sensorLdo : SensorLdo;
        part mcu : NodeMcu;
        part sensor : TMP117;
        part radio : LoRaRadio;
        part shifter : I2CLevelShifter;
        part led : StatusLed;
        part ledResistor : Resistor {
            ...
        }
        part sense : BatterySense;
        ...
    }
}
```

Why both `EnviroNode` and `node`? `EnviroNode` is what *any* EnviroNode is: the requirements in
chapter 9 apply to it. `node` is the particular design: it is where the parts and their values
live. The product line of chapter 17 has more nodes of the same definition.

### Step 3: look at it

Put the cursor on `part node` and run **SysML: Open Diagram of Element at Cursor**. You see `node`
with its *parts* compartment: `battery : NodeCell`, `ldo : MainLdo`, and so on. `ledResistor`
declares values of its own in braces, so it is also drawn as a box.

## Check yourself

1. Is `part def Resistor` a definition or a usage? And `part r12 : Resistor`?
2. A board has eight identical status LEDs. Write the usage.
3. Should the cable that connects the node to its gateway be a composite part of the node, or a
   reference?

<details><summary>Answers</summary>

1. `part def Resistor` is a definition (a kind of part). `part r12 : Resistor` is a usage (one
   resistor in some context).
2. `part statusLeds : StatusLed[8];`
3. Usually neither: the cable is a part of the *installation*, which contains both the node and
   the gateway (chapter 16 models exactly that). From the node's point of view, at most a `ref`.

</details>

Next: [4. Specialization and redefinition](04-specialization.md)
