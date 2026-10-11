# Wiring harnesses and pinouts

The extension can check electrical wiring written in SysML v2. You model your equipment pinouts and harnesses with the bundled `Wiring` library. The language server then tells you whether the right things flow across each interface: voltages, grounds, discretes and data buses. It also works out the current in each wire and the voltage drop to each load.

A complete example is in [examples/wiring/avionics.sysml](../examples/wiring/avionics.sysml).

## Modeling

```sysml
package Example {
    private import Wiring::*;
    private import SI::*;

    // What flows: specialize the library's signal kinds.
    item def DC28V :> Power { :>> nominal = 28 [V]; }
    item def DC28VLoad :> Power { :>> minimum = 22 [V]; :>> maximum = 32.2 [V]; }

    // Pinouts: a connector with one Pin port per contact; equipment pins say what they carry.
    part def PSU {
        part J1 : Connector {
            :>> gender = ConnectorGender::receptacle;
            port '1' : Pin { :>> maxCurrent = 13 [A]; out item :>> signal : DC28V { :>> current = 10 [A]; } }
        }
    }
    part def Load {
        part J1 : Connector {
            port A : Pin { in item :>> signal : DC28VLoad { :>> current = 3 [A]; :>> maxDrop = 1 [V]; } }
        }
    }

    // A harness: its connectors (pins without signals) and wires between them.
    part def W1 :> Harness {
        part P1 : Connector { :>> gender = ConnectorGender::plug; port '1' : Pin; }
        part P2 : Connector { :>> gender = ConnectorGender::plug; port A : Pin; }
        connection W1001 : Wire connect P1.'1' to P2.A { :>> length = 2 [m]; :>> gauge = AWG::AWG20; }
    }

    // The installation: a top-level part usage. Connecting two connectors mates them.
    part system {
        part psu : PSU;
        part load : Load;
        part w1 : W1;
        connect psu.J1 to w1.P1;
        connect load.J1 to w1.P2;
    }
}
```

These are the library's building blocks:

- **`Pin`**: one contact.
  - `pinId` defaults to the port's name. Mating connectors match their pins on it.
  - Other attributes: `maxCurrent`, `voltageRating`, `contactSize`.
  - Redefine `signal` with a direction to say what the pin carries:
    - `out` for a source;
    - `in` for a load;
    - `inout` for a bus.
- **`Connector`**: a part whose `Pin` ports are its pinout. It also has `gender` and `partNumber`.
- **`Wire`**: a connection between two pins.
  - Size: `length` plus either `gauge` (`AWG::AWG0` … `AWG30`) or `crossSection`.
  - Other attributes: `material`, `color`, `wireId`.
  - `ampacity` overrides the gauge's default.
- **`Splice`**: connect every wire of a junction to its `node`.
- **`Harness`**, **`CableShield`**: used for grouping and documentation.
- **`TwistedPair`**: lists the wires twisted together (`:>> wires = (W1007, W1008);`). The pair is checked (see `wiring-twisted-pair`) and shown on its wires in the diagram.
- **Signals**:
  - `Power`: `nominal`, `minimum`, `maximum`, `current`, `maxDrop`.
  - `Ground`.
  - `Discrete`: `high`.
  - `Analog`.
  - Data links, all with a `bitrate`:
    - the differential ones (`CAN`, `Ethernet`, `ARINC429`, `RS422`, `RS485`) also have `polarity` and `pair`;
    - `RS232` has no polarity.
- **Units**: SI units plus the engineering units (`mV`, `mA`, `µA`, `kΩ`, `mW`, `cm`, ... see `library/EngineeringUnits.sysml`), `'mm²'`, `ft`, `'in'`.
  - Quote units that contain non-ASCII characters: `1.5 ['mm²']`.
  - On a pin named like a unit (pin `A`), `[A]` still means amperes.

A wiring analysis covers each top-level part usage, which is called an installation. It expands that usage through its definitions, so one equipment definition used twice gives two separate sets of pins.

## Checks

| Code | Meaning |
|---|---|
| `wiring-signal-mismatch` | A net joins different kinds of signal, e.g. 28 V and CAN. |
| `wiring-polarity` | Differential legs are swapped, e.g. CAN_H to CAN_L. |
| `wiring-bitrate` | Bus pins on one net use different bit rates. |
| `wiring-multiple-sources` | More than one source drives a net. |
| `wiring-no-source` | A load (power, ground, discrete or analog) has no source on its net. |
| `wiring-unconnected` | A signal pin doesn't reach any other equipment (warning). |
| `wiring-voltage-range` | The source's level is outside what a load accepts. A load that gives only a nominal level accepts ±5 %. |
| `wiring-voltage-rating` | A pin carries more voltage than its `voltageRating`. |
| `wiring-mate-gender` | Two plugs (or two receptacles) are mated. |
| `wiring-mate-unmatched` | A used pin has no pin with the same pinId on the mating connector (warning). |
| `wiring-duplicate-pin` | Two pins of one connector share a pinId. |
| `wiring-twisted-pair` | A twisted pair with a differential leg (CAN, Ethernet, ARINC 429, RS-422/485) does not twist the + and − legs of one link: another signal kind, two wires on the same leg, or legs of different Ethernet pairs (warning). A supply twisted with its return is not checked. |
| `wiring-ampacity` | A wire carries more current than its gauge allows. The message suggests a gauge. |
| `wiring-pin-current` | A pin carries more than its `maxCurrent`. |
| `wiring-source-capacity` | A source's loads draw more than its `current` (warning). |
| `wiring-voltage-drop` | The drop to a load exceeds its `maxDrop`, or pushes it below its `minimum`. The message names the wire to enlarge. |

**Where errors appear:** each error is reported on the wire nearest the problem, otherwise on the pin or on the part usage that contains it. Related locations point at the pins involved.

**Hover:**
- On a pin, the hover shows what it carries, its net, its current and the voltage at the load.
- On a wire, it shows the wire's size, resistance, current and voltage drop.

## How the calculations work

- **Resistance:** R = ρ·L/A. The resistivity at 20 °C is 1.724e-8 Ω·m for copper and 2.82e-8 Ω·m for aluminum. AWG cross-sections are the standard values.
- **Current:** a wire carries the sum of the `current` of the loads it feeds from the net's single source.
- **Voltage at a load:** the source's voltage minus the I·R drop of every wire on the path to the load.
- **What isn't computed:** only the feed side is calculated; the return is its own Ground net.
- **Default ampacities:** these are conservative values for copper wire in a bundle. Set `ampacity` on a wire for your own derating.

## In the diagram

These features are in the **Interconnection** view of an installation. The [README](../README.md#wiring-harnesses-and-pinouts) has screenshots of each.

- **Colors and labels:** pins and wires are colored by signal kind, and each wire is labeled with what it carries. Mates are labeled with how many signals they carry.
- **Badges** show the checks' errors and warnings on the elements concerned.
- **Legend:** filters signal kinds.
- **Bundle wires** collapses parallel wires between two connectors into one bundle.
- **Twisted pairs:** each twisted wire's label ends with its pair (`· TP1`), the pair's box lists the wires it twists, and tracing a net highlights its pair. The trace panel and the wire list name the pair too.
- **Trace:** Alt+click a pin or wire (or run **SysML: Trace Signal at Cursor** in the editor) to highlight its net from end to end. A panel lists the source, each load's voltage and current, and the wires.
- **Tables** (or **SysML: Show Pinout and Wire Tables**) shows a pinout per connector and the wire list. Each can be exported as CSV.

**Server requests** behind these features:
- `sysml/diagram` carries the overlay in the Interconnection view: `DiagramGraph.wiring`, edge `flows` and `markers`, and port `flow`.
- `sysml/wiringTables` returns the tables.
- `sysml/wiringTrace` returns the nets at a position.

The types are in `src/shared/wiring-protocol.ts`.
