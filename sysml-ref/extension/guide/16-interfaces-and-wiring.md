# 16. Interface checks and wiring

Connecting two ports in a model is easy; connecting them on a board or with a cable has to be
*right*. A 3.3 V output must not drive a 1.8 V input, the bus clock must suit both ends, and a cable's
wires must carry the right signals at a safe current with an acceptable voltage drop. This chapter
covers the two levels at which the extension checks that: **interfaces between ports** (any model)
and **wiring harnesses** (with the Wiring library).

## Interface checks

Every connection between ports of a system (a top-level part usage, such as `node`) is checked. You
don't need to do anything but connect the ports:

| Diagnostic | What is wrong | Example |
|---|---|---|
| `port-direction` | Two outputs drive each other. (Two inputs with nothing driving them is a warning.) | `out port tx` to another `out port` |
| `interface-end` | A port doesn't match the type of the interface end it plays. | a `GPIOPort` as the `controller` end of `SpiLink`, which expects an `SPIPort` |
| `logic-overvoltage` | An output's high level is above what the input's supply allows. | a 3.3 V output into a 1.8 V input |
| `logic-level` | An output's high level is below the input's input-high threshold, or its low level above the input-low threshold. | a 1.8 V output into a 3.3 V CMOS input (VIH = 2.31 V) |
| `bus-rate` | UART baud rates differ, or an I²C/SPI controller runs a faster clock than a target supports. | a 400 kHz controller and a 100 kHz target |

Conjugated ports (`~P`) flip directions, and a part's port delegated to a port of one of its parts is
fine.

The logic and bus checks use the Electronics library's `LogicPort`s (`GPIOPort`, `I2CPort`,
`SPIPort`, `UARTPort`). The thresholds default to CMOS: VIH = 70 % and VIL = 30 % of `vdd`, with
outputs at the rails. Set `vih`, `vil`, `voh` and `vol` on a port to use a datasheet's values instead.

In the Interconnection view, a problem is a marker on the connection, with the message in its
tooltip.

![An interface check in the Interconnection view](images/node-interface-check.png)

## The EnviroNode: why it has a level shifter

The TMP117 runs from the 1.8 V rail, so its I²C pins swing to 1.8 V, but the MCU's swing to 3.3 V.
See what the checks say about connecting them directly. In `model/node-architecture.sysml`,
temporarily replace the two I²C connections through the shifter with one direct connection:

<!-- check: none -->
```sysml
        connect mcu.i2c to sensor.i2c;     // instead of the two lines through the shifter
```

(This snippet isn't checked by the test suite: it is the mistake on purpose.)

Two errors appear on the connection:

- *node.mcu.i2c drives 3.3 V high into node.sensor.i2c, which runs at 1.8 V: add a level shifter.*
  [`logic-overvoltage`]
- *node.sensor.i2c's high level 1.8 V is below node.mcu.i2c's input-high threshold 2.31 V.*
  [`logic-level`]

Both directions fail: the MCU would overdrive the sensor, and the sensor couldn't drive a valid high
level into the MCU. The fix is the design you already have, the PCA9306 level shifter between them:

<!-- check: project -->
```sysml
        connect mcu.i2c to shifter.high;
        connect shifter.low to sensor.i2c;
```

The shifter's `high` side is a 3.3 V I²C port and its `low` side a 1.8 V one, so each connection now
joins ports at the same voltage, and the errors disappear.

Now try the bus rate. With the direct connection back in place, change the sensor's I²C port to
`clockRate = 100 [kHz]`. A third diagnostic appears: *I²C clock: node.mcu.i2c runs the bus at 400 kHz,
but node.sensor.i2c supports at most 100 kHz.* [`bus-rate`]. Undo both changes.

## Wiring harnesses

Inside a box, ports and connections describe the electronics. Between boxes there are **cables**:
connectors with pins, wires of a gauge and length, splices, twisted pairs. The extension's **Wiring**
library models those, and its checks find wiring mistakes:
- signals that don't match;
- swapped polarities;
- wires too thin for their current;
- voltage drops a load can't tolerate;
- plugs mated with plugs.

### The building blocks

- **Signals** (items): what a pin carries.
  - `Power`, with `nominal`, `minimum`, `maximum`, `current` and `maxDrop`;
  - `Ground`, `Discrete`, `Analog`;
  - data links: `CAN`, `Ethernet`, `ARINC429`, `RS422`, `RS485` (differential, with `polarity` and
    `pair`) and `RS232`. All of them have a `bitrate`.

  Specialize them with your levels: `item def Probe3V3 :> Power { :>> nominal = 3.3 [V]; }`.
- **`Pin`**: one contact (a port). Redefine its `signal` with a direction:
  - `out` for a source;
  - `in` for a load;
  - `inout` for a bus.

  `pinId` defaults to the port's name and is what mating connectors match on. `maxCurrent` and
  `voltageRating` are checked.
- **`Connector`**: a part whose `Pin` ports are its pinout, with a `gender` (`plug` or `receptacle`).
- **`Wire`**: a connection between two pins, with a `length` and a `gauge` (`AWG::AWG24`…) or
  `crossSection`, a `color`, and an `ampacity` if you don't want the gauge's default.
- **`Splice`**, **`Harness`**, **`CableShield`**, and **`TwistedPair`** (the wires twisted
  together).
- **The installation** is a top-level part with the equipment and the harnesses. Connecting two
  connectors **mates** them, pin to pin by `pinId`.

### The checks

| Code | Meaning |
|---|---|
| `wiring-signal-mismatch` | A net joins different kinds of signal, e.g. 3.3 V and RS-485. |
| `wiring-polarity` | Differential legs are swapped, e.g. A to B. |
| `wiring-bitrate` | Bus pins on one net use different bit rates. |
| `wiring-multiple-sources` | More than one source drives a net. |
| `wiring-no-source` | A load (power, ground, discrete or analog) has no source on its net. |
| `wiring-unconnected` | A signal pin doesn't reach any other equipment (warning). |
| `wiring-voltage-range` | The source's level is outside what a load accepts (a load giving only a nominal level accepts ±5 %). |
| `wiring-voltage-rating` | A pin carries more voltage than its `voltageRating`. |
| `wiring-mate-gender` | Two plugs (or two receptacles) are mated. |
| `wiring-mate-unmatched` | A used pin has no pin with the same `pinId` on the mating connector (warning). |
| `wiring-duplicate-pin` | Two pins of one connector share a `pinId`. |
| `wiring-twisted-pair` | A twisted pair with a differential leg (CAN, Ethernet, ARINC 429, RS-422/485) doesn't twist the + and − legs of one link: another signal kind, two wires on the same leg, or legs of different Ethernet pairs (warning). A supply twisted with its return isn't checked. |
| `wiring-ampacity` | A wire carries more current than its gauge allows; the message suggests a gauge. |
| `wiring-pin-current` | A pin carries more than its `maxCurrent`. |
| `wiring-source-capacity` | A source's loads draw more than its `current` (warning). |
| `wiring-voltage-drop` | The drop to a load exceeds its `maxDrop` or pushes it below its `minimum`; the message names the wire to enlarge. |

The calculation behind the drops:
- the resistance of each wire is ρ·L/A (copper: 1.724 × 10⁻⁸ Ω·m at 20 °C);
- the current in a wire is the sum of the loads it feeds;
- the voltage at a load is the source voltage minus the I·R drop along the path.

Only the feed side is calculated; the return is its own ground net.

### Switched and redundant power (planned)

Today, a net has exactly one source: two `out` power pins on one net are reported as
`wiring-multiple-sources`, even if a switch or a diode would keep them apart in the real circuit. The
Wiring library doesn't have switches, relays or diodes yet. **Planned** (not available yet):

- switches and relays (the Electronics library's `Switch` and `Relay`, with their poles and selected
  `position`) and diode-OR supplies (`Diode`, with its forward drop counted in the voltage at the
  load) in harness analysis;
- checks per switch position or named operating mode ("with S1 in B, the display has no 28 V");
- the diagram showing the selected throw, with a position selector that re-runs the checks.

Until then, model one position at a time, or leave alternative sources unconnected.

## The EnviroNode's field installation

In the field, the node's enclosure has a 5-pin connector. Through it, the node powers a remote
temperature probe at 3.3 V and reads its analog output, and it talks RS-485 to a gateway 50 m away.
One harness, W1, does both. Create `model/node-harness.sysml`:

<!-- check: project -->
```sysml
package NodeHarness {
    doc
    /*
     * The field installation: the node's enclosure connector, a remote temperature probe it
     * powers, and an RS-485 link to a gateway, wired through one cable harness. The Wiring
     * library checks what flows through each pin and wire.
     */
    private import Wiring::*;
    private import SI::*;

    /* What flows. */
    item def Probe3V3 :> Power { :>> nominal = 3.3 [V]; }
    item def Probe3V3Load :> Power { :>> minimum = 3.0 [V]; :>> maximum = 3.6 [V]; }
    item def ProbeSignal :> Analog { :>> minimum = 0 [V]; :>> maximum = 2.5 [V]; }
    item def Rs485Link :> RS485 { :>> bitrate = 19200; }

    /* The node's enclosure connector. */
    part def NodeEnclosure {
        part J1 : Connector {
            :>> gender = ConnectorGender::receptacle;
            port '1' : Pin { :>> maxCurrent = 1 [A]; out item :>> signal : Probe3V3 { :>> current = 0.2 [A]; } }
            port '2' : Pin { out item :>> signal : Ground; }
            port '3' : Pin { in item :>> signal : ProbeSignal; }
            port '4' : Pin { inout item :>> signal : Rs485Link { :>> polarity = Polarity::positive; } }
            port '5' : Pin { inout item :>> signal : Rs485Link { :>> polarity = Polarity::negative; } }
        }
    }

    /* A remote probe, powered by the node. */
    part def TemperatureProbe {
        part J1 : Connector {
            :>> gender = ConnectorGender::receptacle;
            port A : Pin { in item :>> signal : Probe3V3Load { :>> current = 5 [mA]; :>> maxDrop = 0.1 [V]; } }
            port B : Pin { in item :>> signal : Ground; }
            port C : Pin { out item :>> signal : ProbeSignal { :>> current = 1 [mA]; } }
        }
    }

    /* The gateway's RS-485 port. */
    part def Gateway {
        part J1 : Connector {
            :>> gender = ConnectorGender::receptacle;
            port '1' : Pin { inout item :>> signal : Rs485Link { :>> polarity = Polarity::positive; } }
            port '2' : Pin { inout item :>> signal : Rs485Link { :>> polarity = Polarity::negative; } }
        }
    }

    /* The cable harness. */
    part def W1 :> Harness {
        :>> harnessId = "W1";
        part P1 : Connector { :>> gender = ConnectorGender::plug; port '1' : Pin; port '2' : Pin; port '3' : Pin; port '4' : Pin; port '5' : Pin; }
        part P2 : Connector { :>> gender = ConnectorGender::plug; port A : Pin; port B : Pin; port C : Pin; }
        part P3 : Connector { :>> gender = ConnectorGender::plug; port '1' : Pin; port '2' : Pin; }

        connection W101 : Wire connect P1.'1' to P2.A { :>> length = 10 [m]; :>> gauge = AWG::AWG24; :>> color = "red"; }
        connection W102 : Wire connect P1.'2' to P2.B { :>> length = 10 [m]; :>> gauge = AWG::AWG24; :>> color = "black"; }
        connection W103 : Wire connect P2.C to P1.'3' { :>> length = 10 [m]; :>> gauge = AWG::AWG24; :>> color = "white"; }

        /* RS-485 to the gateway, twisted. */
        connection W104 : Wire connect P1.'4' to P3.'1' { :>> length = 50 [m]; :>> gauge = AWG::AWG24; :>> color = "blue"; }
        connection W105 : Wire connect P1.'5' to P3.'2' { :>> length = 50 [m]; :>> gauge = AWG::AWG24; :>> color = "white/blue"; }
        part TP1 : TwistedPair { :>> wires = (W104, W105); }
    }

    /* The installation: the equipment and the harness, mated. */
    part fieldInstallation {
        part enclosure : NodeEnclosure;
        part probe : TemperatureProbe;
        part gateway : Gateway;
        part w1 : W1;
        connect enclosure.J1 to w1.P1;
        connect probe.J1 to w1.P2;
        connect gateway.J1 to w1.P3;
    }
}
```

Notes on the model:
- Pins named with digits are quoted names (`'1'`); the probe's pins are lettered.
- The equipment pins say what they carry (`out` for the node's 3.3 V and ground, `in` for the probe).
  The harness's plug pins carry nothing themselves: they only take the wires.
- The probe's supply input accepts 3.0–3.6 V and allows at most 0.1 V of drop.
- `TP1` twists the two RS-485 wires. They carry the positive and negative legs of one link, which is
  what the `wiring-twisted-pair` check wants.

### In the tool

1. Put the cursor on `part fieldInstallation` and run **SysML: Open Interconnection View of Element at
   Cursor**. The equipment and the harness appear with their connectors. Pins and wires are coloured
   by signal kind, and each wire is labelled with what it carries; the twisted wires' labels end in
   `· TP1`.
   The **legend** filters signal kinds, and **Bundle wires** collapses parallel wires into one.
2. **Hover** a wire for its size, resistance, current and voltage drop. W101: AWG24, 10 m, 0.841 Ω,
   5 mA, a 4 mV drop. Hover the probe's pin `A`: it gets 3.296 V.
3. **Alt+click** a wire (or run **SysML: Trace Signal at Cursor** in the editor) to highlight its net
   from end to end. The trace panel lists the source, each load's voltage and current, and the wires.
4. Run **SysML: Show Pinout and Wire Tables** for a pinout per connector and the wire list, each with
   a **CSV** button for the harness drawing or the shop floor.

![The field installation](images/node-harness.png)

### Three mistakes to try

- **Cross the RS-485 pair:** connect `W104` to `P3.'2'` and `W105` to `P3.'1'`. Two errors:
  *Polarity swapped: fieldInstallation.enclosure.J1.'4' is the positive RS485 leg but is connected to
  fieldInstallation.gateway.J1.'2', the negative leg.* [`wiring-polarity`], and the same for the other
  leg.
- **Load the probe supply:** set the probe's `current` to `150 [mA]`. The drop through W101, 10 m of
  AWG24 at 0.841 Ω, is 0.126 V: more than the probe's 0.1 V allowance. *fieldInstallation.probe.J1.A gets
  3.17 V: 0.126 V is lost in the wiring from fieldInstallation.enclosure.J1.'1' (allowed: 0.1 V); use
  AWG22 or larger for W101.* [`wiring-voltage-drop`]
- **Twist the wrong wires:** in `TP1`, replace `W104` with `W101`, the probe's supply. A warning:
  *fieldInstallation.w1.TP1 twists W101 (Probe3V3) and W105 (Rs485Link −): a twisted pair should
  carry the two legs of one RS485 link.* [`wiring-twisted-pair`]

## Check yourself

1. What does `logic-level` check that `logic-overvoltage` doesn't?
2. In the harness, mate `probe.J1` with `w1.P3` instead of `w1.P2`. Which checks fire?
3. Why does the analysis need the `out` and `in` on the equipment pins but not on the harness pins?

<details><summary>Answers</summary>

1. `logic-overvoltage` protects the input from too high a voltage. `logic-level` checks that the
   levels are *recognised*: an output's high must reach the input's VIH, and its low must stay under
   VIL. A 1.8 V output into a 3.3 V input is safe but not reliable.
2. `w1.P3` has pins `'1'` and `'2'`; the probe's are `A`, `B` and `C`. The pins don't match
   (`wiring-mate-unmatched` warnings). The probe's supply and ground, and the node's analog input, have
   no source (`wiring-no-source` errors). The node's 3.3 V and ground pins reach no equipment
   (`wiring-unconnected` warnings).
3. Sources and loads are properties of the equipment: the node supplies 3.3 V, the probe consumes it.
   The harness only conducts. The analysis follows the wires from the equipment pins through the
   harness, and works out the nets, the currents and the drops.

</details>

Next: [17. Variants, allocation and views](17-variants-and-allocation.md)
