# 6. Ports, connections and interfaces

A block diagram is boxes *and* lines. So far the EnviroNode is only boxes. This chapter adds the
lines: **ports** (the connection points of a part), **connections** (what is wired to what),
**interfaces** (connections with a defined contract), and **flows** (what travels across them).

## Ports

A **port** is a connection point on the boundary of a part: a connector, a group of pins, a bus
interface, a software API. As always there is a definition (`port def`, the kind of connection
point) and usages (`port`, one connection point on one part).

<!-- check: standalone -->
```sysml
package Ports {
    private import ISQ::*;
    private import SI::*;

    port def UsbPort {
        attribute maxCurrent : ElectricCurrentValue;
    }

    part def Charger {
        port usb : UsbPort { :>> maxCurrent = 0.5 [A]; }
    }
}
```

Ports describe **what crosses the boundary**. A port definition can say, with **directions**,
what goes in and what comes out:

<!-- check: standalone -->
```sysml
package Directions {
    item def Reading;
    item def Command;

    port def SensorBus {
        out item reading : Reading;     // the sensor sends readings
        in item command : Command;      // and receives commands
    }

    part def Sensor { port bus : SensorBus; }
    part def Logger { port bus : ~SensorBus; }    // the other side: conjugated
}
```

- An **item** (`item def`) is something that can flow: data, energy, material, a signal. Chapter
  13 uses items as the messages of an action flow.
- `in`, `out` and `inout` give the direction **as seen from the part that has the port**.
- **Conjugation** (`~SensorBus`) is the same port definition with every direction reversed. It is
  the mating half: a plug and its socket, a master and a slave. The logger's `bus` receives
  readings and sends commands.

## Connections

A **connection** joins two features, usually two ports, and says they are linked:

<!-- check: standalone -->
```sysml
package Connections {
    item def Reading;
    port def SensorBus { out item reading : Reading; }

    part def Sensor { port bus : SensorBus; }
    part def Logger { port bus : ~SensorBus; }

    part system {
        part sensor : Sensor;
        part logger : Logger;
        connect sensor.bus to logger.bus;
    }
}
```

`connect a.p to b.q` is a connection usage between the port `p` of part `a` and the port `q` of part
`b`. Like everything else it can have a name and a type: `connection link : Cable connect a.p to
b.q;` where `connection def Cable` describes what kind of connection it is.

Connections are made **in the context that owns both ends**: here `system`, which contains both
`sensor` and `logger`. That is why the EnviroNode's connections go in `node`, not in the part
definitions.

### Interfaces

An **interface** is a connection between ports, with a definition that names its **ends** and
their port types: a contract for both sides.

<!-- check: standalone -->
```sysml
package Interfaces {
    item def Reading;
    port def SensorBus { out item reading : Reading; }

    interface def SensorLink {
        end sensorSide : SensorBus;
        end loggerSide : ~SensorBus;
    }

    part def Sensor { port bus : SensorBus; }
    part def Logger { port bus : ~SensorBus; }

    part system {
        part sensor : Sensor;
        part logger : Logger;
        interface link : SensorLink connect sensorSide ::> sensor.bus to loggerSide ::> logger.bus;
    }
}
```

`sensorSide ::> sensor.bus` says which port plays which end. The extension checks the ends' types
(chapter 16).

### Bindings and flows

Two more kinds of connection:

<!-- check: standalone -->
```sysml
package BindingsAndFlows {
    private import ISQ::*;
    item def Reading;
    port def SensorBus { out item reading : Reading; }

    part def Sensor { port bus : SensorBus; }
    part def Logger { port bus : ~SensorBus; }

    part system {
        part sensor : Sensor;
        part logger : Logger;
        attribute supply : ElectricPotentialValue;
        attribute sensorSupply : ElectricPotentialValue;

        bind sensorSupply = supply;                                          // always equal
        flow of Reading from sensor.bus.reading to logger.bus.reading;       // readings travel
    }
}
```

- A **binding** (`bind x = y`) says two features are the same value: an equality, not a wire.
- A **flow** (`flow of Reading from a to b`) says items of a kind actually travel from one feature
  to another. Use flows when the *what* matters: the data on a bus, the coolant in a pipe.

## Ports in the Electronics library

The Electronics library defines the ports you need for electronics:

| Port def | For | Attributes |
|---|---|---|
| `Terminal` | one electrical contact (a resistor's `p` and `n`) | — |
| `PowerPort` | a supply rail: `out` on a source, `in` on a load | `nominal`, `minimum`, `maximum`, `current`, `load` |
| `LogicPort` | a digital signal | `vdd`, `vil`, `vih`, `vol`, `voh` |
| `GPIOPort`, `I2CPort`, `SPIPort`, `UARTPort` | logic signals and buses | plus `clockRate`, `isController`, `address`, `baudRate` |

Every `PoweredDevice` (MCU, sensor, radio) has an `in port supply : PowerPort`; a `Battery` has an
`out port supply`; a `Regulator` has `in port input` and `out port output`. You connect them to
describe the power tree, which chapter 7 analyses.

## In the tool: the Interconnection view

The General view shows *what* things are. The **Interconnection view** shows *how they are
connected*: parts nested inside their owner, ports on their borders, connections between ports.

1. Open the `Interfaces` snippet above (or the EnviroNode, below).
2. Put the cursor on `part system` and run **SysML: Open Interconnection View of Element at
   Cursor** from the editor's context menu.
3. `sensor` and `logger` are boxes inside `system`, each with its `bus` port as a small square on
   its border. The `link` interface is a line between them, labelled with its name.

Parts show the ports their definitions declare even when the usage doesn't mention them, so the
view shows the real pinout of each part.

### Editing from the diagram

You can also build the structure from the diagram. Every edit is a normal text edit, with your
formatting kept, and **⌘Z** / **Ctrl+Z** undoes it.

- **Right-click a part › Add member…** asks for the kind (part, port, attribute…), the name and
  the type, and inserts the declaration in the right place in the text.
- **Shift+drag from one port to another** (or right-click › **Connect from here**) asks whether
  you want a connection, an interface, a binding or a flow, and inserts `connect a.p to b.q;` (or
  the equivalent) in the owner that contains both.
- **F2** renames the selected element (and every reference to it); **Del** deletes it, warning
  you if other elements still refer to it.
- **Set type…** and **Specialize…** change a usage's type or a definition's general type.

Try it on the EnviroNode once you have added its ports: delete the `connect mcu.ledPin to
led.drive;` line, then put it back by Shift+dragging from the MCU's `ledPin` to the LED's `drive`.

## The EnviroNode

### Ports on the parts

Add the signal ports to the part definitions in `model/node-parts.sysml`. The MCU drives an I²C
bus, an SPI bus and the LED pin. The `vdd` of a logic port is the voltage its pins swing to, which
chapter 16 checks across every connection.

<!-- check: project -->
```sysml
    part def NodeMcu :> Microcontroller {
        ...
        port i2c : I2CPort { :>> vdd = 3.3 [V]; :>> clockRate = 400 [kHz]; :>> isController = true; }
        port spi : SPIPort { :>> vdd = 3.3 [V]; :>> clockRate = 8 [MHz]; :>> isController = true; }
        out port ledPin : GPIOPort { :>> vdd = 3.3 [V]; }
        ...
    }
```

<!-- check: project -->
```sysml
    part def TMP117 :> Sensor {
        ...
        port i2c : I2CPort { :>> vdd = 1.8 [V]; :>> clockRate = 400 [kHz]; :>> address = 72; }
        ...
    }
```

<!-- check: project -->
```sysml
    part def LoRaRadio :> Radio {
        ...
        port spi : SPIPort { :>> vdd = 3.3 [V]; :>> clockRate = 16 [MHz]; }
        ...
    }

    /* An I²C level shifter between a 1.8 V and a 3.3 V bus. */
    part def I2CLevelShifter :> Component {
        :>> partNumber = "PCA9306";
        port low : I2CPort { :>> vdd = 1.8 [V]; :>> clockRate = 400 [kHz]; }
        port high : I2CPort { :>> vdd = 3.3 [V]; :>> clockRate = 400 [kHz]; }
    }

    /* The status LED. */
    part def StatusLed :> LED {
        ...
        in port drive : GPIOPort;
    }
```

The supply ports (`supply`, `input`, `output`) are inherited from the library, so you don't
declare them.

### Connections in the node

In `model/node-architecture.sysml`, declare the SPI interface, then connect everything in `node`:

<!-- check: project -->
```sysml
    interface def SpiLink {
        doc /* The SPI bus between a controller and one target. */
        end controller : SPIPort;
        end target : SPIPort;
    }

    part node : EnviroNode {
        ...
        /* Power: the cell feeds the 3.3 V LDO; the 1.8 V LDO hangs off the 3.3 V rail. */
        connect battery.supply to ldo.input;
        connect ldo.output to mcu.supply;
        connect ldo.output to radio.supply;
        connect ldo.output to sensorLdo.input;
        connect sensorLdo.output to sensor.supply;

        /* Signals. The sensor's 1.8 V I²C reaches the 3.3 V MCU through the level shifter. */
        connect mcu.i2c to shifter.high;
        connect shifter.low to sensor.i2c;
        interface spi : SpiLink connect controller ::> mcu.spi to target ::> radio.spi;
        connect mcu.ledPin to led.drive;
        connect battery.positive to sense.top;

        /* The node's rail is the main LDO's output; the readings travel from the MCU to the radio. */
        bind railVoltage = ldo.outputVoltage;
        flow of NodeIcd::Reading from mcu to radio;
        ...
    }
```

- `battery.positive` and `sense.top` are `Terminal`s, electrical contacts: the divider is connected
  to the cell's positive terminal. Chapter 12 simulates that circuit.
- `bind railVoltage = ldo.outputVoltage` gives the node a rail voltage that always equals the LDO's
  output. Add `attribute railVoltage : ElectricPotentialValue;` to `EnviroNode`. Evaluate `node` and
  the Values view shows `railVoltage = 3.3 V`, which it gets through the binding.
- `flow of NodeIcd::Reading from mcu to radio` records *what* travels over the SPI interface: the
  readings. `Reading` is the radio message, defined in its own package. Create
  `model/node-icd.sysml` with `package NodeIcd { item def Reading; }` for now; chapter 20 gives it
  its fields.

Now open the Interconnection view of `node`. The parts sit inside the node, ports on their
borders:
- the power connections run from the battery to the LDO and from the LDO's `output` to the three
  loads;
- the I²C bus goes MCU → shifter → sensor;
- the SPI interface links the MCU and the radio, labelled with the reading that flows over it.

The picture shows the finished project, which also has the `txDone` message of chapter 19 going
back from the radio to the MCU.

![The EnviroNode in the Interconnection view](images/node-interconnection.png)

## Check yourself

1. Why does the logger's port use `~SensorBus` and not `SensorBus`?
2. Where must `connect mcu.spi to radio.spi` be written: in `NodeMcu`, in `LoRaRadio`, or in
   `node`? Why?
3. Add a UART port `debug` to the MCU, at 115200 baud and 3.3 V.

<details><summary>Answers</summary>

1. `SensorBus` says readings go *out*. On the logger side they come *in*. Conjugation reverses
   every direction, so the two sides match.
2. In `node`: a connection is made in the context that contains both ends. `NodeMcu` doesn't know
   about any radio.
3. `port debug : UARTPort { :>> vdd = 3.3 [V]; :>> baudRate = 115200 [Hz]; }` in `NodeMcu`.

</details>

Next: [7. The power tree](07-power-tree.md)
