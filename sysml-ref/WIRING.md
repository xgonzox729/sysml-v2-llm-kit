# Wiring harnesses and pinouts (SysML v2 VS Code extension `Wiring` library)

Read this only when the request is about electrical wiring: connectors, pins, pinouts, wires, harnesses,
splices, power/ground nets or data buses (CAN, Ethernet, ARINC 429, RS-422/485/232).

- `Wiring` is **not** part of the OMG standard library. It ships with the SysML v2 VS Code extension
  (github.com/xgonzox729/sysmlextension), whose checker (`tools/sysml-check.mjs`) resolves it and runs the
  electrical checks below. `sysml-validate` does not know it and reports `Wiring::*` names as unresolved.
- Library source (read-only copy): `sysml-ref/wiring/Wiring.sysml`. Full example: `sysml-ref/wiring/avionics.sysml`
  (28 V supply, flight computer, display, CAN bus, Ethernet, one harness). Never copy `Wiring.sysml` into `models/`.

## Four steps
1. **Signals** — `item def` specializing a library signal kind says what flows.
2. **Pinouts** — each equipment `part def` has `part J1 : Connector { ... }` with one `port <id> : Pin` per contact.
   An equipment pin redefines `signal` with a direction: `out` = source, `in` = load, `inout` = bus.
3. **Harnesses** — `part def W1 :> Harness` with its own connectors whose pins declare **no** signals, and
   `connection <wireId> : Wire connect P1.'1' to P2.A { :>> length = ...; :>> gauge = AWG::AWG20; }`.
4. **Installation** — a top-level `part` usage instantiates equipment and harnesses. `connect psu.J1 to w1.P1;`
   mates two connectors pin-for-pin by pin ID (the port name unless `pinId` is set).

```sysml
package Example {
    private import Wiring::*;
    private import SI::*;

    item def DC28V :> Power { :>> nominal = 28 [V]; }
    item def DC28VLoad :> Power { :>> minimum = 22 [V]; :>> maximum = 32.2 [V]; }

    part def PSU {
        part J1 : Connector {
            :>> gender = ConnectorGender::receptacle;
            port '1' : Pin { :>> maxCurrent = 13 [A]; out item :>> signal : DC28V { :>> current = 10 [A]; } }
            port '2' : Pin { out item :>> signal : Ground; }
        }
    }
    part def Display {
        part J1 : Connector {
            :>> gender = ConnectorGender::receptacle;
            port A : Pin { in item :>> signal : DC28VLoad { :>> current = 3 [A]; :>> maxDrop = 1 [V]; } }
            port B : Pin { in item :>> signal : Ground; }
        }
    }
    part def W1 :> Harness {
        part P1 : Connector { :>> gender = ConnectorGender::plug; port '1' : Pin; port '2' : Pin; }
        part P2 : Connector { :>> gender = ConnectorGender::plug; port A : Pin; port B : Pin; }
        connection W1001 : Wire connect P1.'1' to P2.A { :>> length = 3 [m]; :>> gauge = AWG::AWG20; }
        connection W1002 : Wire connect P1.'2' to P2.B { :>> length = 3 [m]; :>> gauge = AWG::AWG20; }
    }

    part system {
        part psu : PSU;
        part display : Display;
        part w1 : W1;
        connect psu.J1 to w1.P1;
        connect display.J1 to w1.P2;
    }
}
```

## Library contents
- **Signal kinds**: `Power` (`nominal`, `minimum`, `maximum`, `current`, `maxDrop`), `Ground`, `Discrete` (`high`),
  `Analog`, buses with `bitrate`: `CAN`, `Ethernet`, `ARINC429`, `RS422`, `RS485` (also `polarity` =
  `Polarity::positive`/`negative` and `pair`), `RS232`; `Shield`.
- **Parts/ports**: `Pin` (`pinId`, `maxCurrent`, `voltageRating`, `contactSize`), `Connector` (`gender` =
  `ConnectorGender::plug`/`receptacle`, `partNumber`), `Wire` (`length`, `gauge` `AWG::AWG0`…`AWG30` or
  `crossSection`, `material`, `color`, `wireId`, `ampacity`), `Splice` (connect each wire to its `node`),
  `Harness`, `TwistedPair`, `CableShield`.
- **Units**: SI plus `mV`, `kV`, `mA`, `mΩ`, `kΩ`, `mW`, `kW`, `cm`, `ft`, `'in'`, `'mm²'`. Quote non-ASCII units:
  `1.5 ['mm²']`. On a pin named like a unit (pin `A`), `[A]` still means amperes.

## Rules that trip models up
- Pin names that are numbers must be quoted: `port '1' : Pin;`, referenced as `P1.'1'`.
- Redefine the signal with `out item :>> signal : DC28V { ... }` — direction keyword first, then `item :>> signal`.
- Harness pins have **no** `signal`; only equipment pins say what they carry.
- Mated connectors need opposite genders and matching pin IDs.
- One source per net; every load (power, ground, discrete, analog) needs a source.
- Each top-level part usage is one installation; the checks run per installation.

## What the checker reports (diagnostic codes)
`wiring-signal-mismatch` (different signal kinds on one net), `wiring-polarity` (swapped differential legs),
`wiring-bitrate`, `wiring-multiple-sources`, `wiring-no-source`, `wiring-unconnected` (warning),
`wiring-voltage-range`, `wiring-voltage-rating`, `wiring-mate-gender`, `wiring-mate-unmatched` (warning),
`wiring-duplicate-pin`, `wiring-ampacity` (message suggests a gauge), `wiring-pin-current`,
`wiring-source-capacity` (warning), `wiring-voltage-drop` (message names the wire to enlarge).
Fix the model, not the check: e.g. for `wiring-ampacity` pick the suggested gauge; for `wiring-voltage-drop`
enlarge the named wire or shorten it.

In VS Code, open the Interconnection view of the installation (`part system`) to see nets coloured by signal kind,
Alt+click a wire to trace it, and use **SysML: Show Pinout and Wire Tables** for pinout and wire-list tables.
