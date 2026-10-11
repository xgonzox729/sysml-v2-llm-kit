# 0. What SysML v2 is

## Models instead of documents

Think about how a board-level design is usually described. There is a block diagram in a slide
deck, a power budget in a spreadsheet, and requirements in a Word document. There are interface
tables in another spreadsheet, a schematic in the EDA tool, and firmware notes on a wiki. Each
holds part of the truth. When the radio's transmit current changes, someone has to remember to
update the power budget, the battery-life estimate, the requirement compliance table and the
firmware's timing assumptions. Often nobody does.

**Model-based systems engineering (MBSE)** replaces that pile of documents with one **model**. The
model is a single structured description of the system: its parts and how they connect, what it
must do (requirements), how it behaves, and how it performs. The documents, diagrams, tables and
analyses are then *views* of the model, generated from it, so they cannot disagree with each
other. Change the radio's current once, and the power budget, the battery-life figure and the
requirement status all follow.

A schematic is already a model of this kind. You don't draw a netlist and then type the same
connections into a spreadsheet: the EDA tool derives the netlist, the BOM and the DRC from one
source. MBSE does the same for the whole system, beyond the circuit: mechanics, power, firmware,
requirements, operating modes.

## SysML v2

**SysML** (Systems Modeling Language) is the standard language for MBSE, published by the Object
Management Group (OMG). Version 2, adopted in 2025, is a complete redesign of SysML 1:

- **It is a language first, with a textual notation.** You can write a SysML v2 model in a text
  file, much as you write VHDL, Verilog or C. It can be versioned in git, diffed, reviewed in pull
  requests, and generated or checked by scripts. SysML 1 models lived in tool databases and were
  edited only through diagrams.
- **It also has a graphical notation.** Diagrams are views of the same model. This extension draws
  them from your text: you never have to keep a picture and a text in sync.
- **It has precise semantics.** Every construct is defined in terms of a small kernel language,
  **KerML**. That is why a tool can evaluate expressions, check units and simulate behaviour from
  the model alone.
- **It comes with a standard library:** quantities and units (ISQ and SI), calculations, analysis
  cases, trade studies, and much more.

Here is a taste: a part of the EnviroNode in SysML v2.

<!-- check: standalone -->
```sysml
package Taste {
    private import ISQ::*;
    private import SI::*;

    part def Radio {
        attribute txCurrent : ElectricCurrentValue;
    }

    part radio : Radio {
        attribute redefines txCurrent = 0.045 [A];
    }
}
```

Without knowing any SysML you can probably read it:
- there is a kind of thing called `Radio` (a **definition**, like a datasheet);
- it has a transmit current;
- `radio` is one particular radio (a **usage**, like a reference designator on a schematic) whose
  transmit current is 45 mA.

Chapters 3 to 5 explain each piece.

## What you can describe

SysML v2 covers four kinds of information about a system. This guide teaches all of them on the
EnviroNode.

| Kind | SysML constructs | Chapters |
|---|---|---|
| **Structure:** what it is made of and how the parts connect | parts, attributes, ports, connections, interfaces | 3–7 |
| **Requirements:** what it must do and how well | requirements, constraints, `satisfy` | 9–10 |
| **Behaviour:** what it does, in what order, in which modes | actions, states, transitions, messages | 13–15, 19 |
| **Analysis:** how well it does it, and which design is best | calculations, analysis cases, trade studies | 8, 10–12 |

## What this extension does

This VS Code extension is a complete SysML v2 environment for the textual notation. It:

- **edits:** syntax highlighting, completion, diagnostics as you type, go to definition, rename,
  formatting, an outline and a model tree;
- **draws:** General, Interconnection, Action flow and State machine views of the model, updated
  as you type, and edited from the diagram;
- **calculates:** every attribute value is evaluated with its units, shown inline, and checked for
  dimension errors (adding volts to amps);
- **verifies:** requirements are checked against the design, with margins, and again over
  tolerances (worst case, Monte Carlo);
- **simulates:** analysis cases and trade studies, circuits (with SPICE), state machines and
  action flows step by step, and the whole system over days of simulated time;
- **checks:** electrical interfaces, supply rails, component derating, wiring harnesses,
  firmware schedules and memory budgets;
- **generates:** documents (requirements specification, ICD, verification report, BOM,
  traceability), C code (message types, register maps, configuration headers, state machines),
  JSON exports, and CI reports;
- **runs headless:** the `sysml-sim` command-line tool runs the same checks and simulations in CI.

The extension adds a few libraries of its own for what standard SysML has no construct for:
tolerances, SPICE runs, time simulation, electronic parts, software and register encodings,
wiring. They are ordinary SysML packages that you import. Appendix [C](C-extension-libraries.md)
describes them.

## The example: the EnviroNode

The EnviroNode is a small, battery-powered sensor node of a kind that is everywhere in IoT
products:

- **Power:** a lithium-ion cell feeds a 3.3 V low-dropout regulator (LDO), which feeds a
  microcontroller (MCU) and a LoRa radio. A second LDO makes 1.8 V for a temperature sensor.
- **Sensing and status:** the sensor talks I²C through a level shifter. A resistor divider lets
  the MCU measure the cell voltage, and an LED shows status.
- **Operation:** every 15 minutes it wakes up, measures, sends a reading over the radio and goes
  back to sleep. It must last at least three years on one cell.
- **Firmware:** an RTOS with a few tasks, a radio driver, and a binary message format.
- **Field installation:** a cable harness connects the node to a remote probe and to an RS-485
  gateway.
- **Variants:** an indoor model with a rechargeable cell and Bluetooth LE, and an outdoor model
  with a primary cell and LoRa.

It is small enough to understand completely and real enough to need every part of SysML.

## Check yourself

1. Why is a spreadsheet power budget *not* a model in the MBSE sense, even though it calculates
   things?
2. In the snippet above, which line is the "datasheet" and which is the "reference designator"?

<details><summary>Answers</summary>

1. Nothing ties it to the rest of the design: the parts in the spreadsheet are not the parts in
   the block diagram or the requirements, so a change in one place is not seen in the others. In a
   model, the power budget is computed from the same `radio` element that the requirements, the
   diagrams and the firmware timing refer to.
2. `part def Radio { … }` is the datasheet (what any radio of that kind has). `part radio : Radio
   { … }` is the reference designator (one particular radio in this design, with its own values).

</details>

Next: [1. Getting started](01-getting-started.md)
