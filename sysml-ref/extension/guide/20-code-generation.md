# 20. Code generation and traceability

A model that only produces documents is a second source of truth that firmware developers have to
copy from. This chapter closes the loop. The firmware's message formats, register definitions,
configuration headers and state machines are **generated** from the model, so they can't disagree
with it. And the model records which **source files implement** which element and which **tests
verify** which requirement.

Generation is one-way: you change the model, not the generated files. The output is deterministic,
so the generated files can be committed and their diffs reviewed, and CI can check that they are up
to date (chapter 21).

## In the tool

Run **SysML: Generate Code** in a model file. It asks:

1. **What to generate:** data types, register maps, variant configurations, state machines (all four
   are selected by default);
2. **Where:** a folder.

It writes the files and reports how many, and any problems: a field it can't encode, for example. On
the command line, `sysml-sim gen model/ --out generated` does the same for a whole folder (chapter 21).

The EnviroNode's generated files are in [example/sensor-node/generated](example/sensor-node/generated).
The firmware stand-ins in [example/sensor-node/firmware](example/sensor-node/firmware) include them.

## Data types: the ICD as code

The EnviroNode sends one message over LoRa, a `Reading`, and receives a `Configure`. Their exact
binary layout is part of the interface control document (ICD). Model them as item definitions, and say
how each field is encoded with `@Encoding` (from the `Software` library). Create (or complete)
`model/node-icd.sysml`:

<!-- check: project -->
```sysml
package NodeIcd {
    doc
    /*
     * The interface control document of the EnviroNode as model: the message it sends over
     * LoRa, field by field, with how each field is encoded. "Generate Code" turns it into C,
     * a JSON Schema and protobuf; "Generate Documents" lists it in the ICD.
     */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Software::*;

    enum def NodeStatus {
        doc /* What the node reports about itself. */
        enum ok;
        enum lowBattery;
        enum sensorFault { @Encoding { code = 8; } }
    }

    item def Reading {
        doc /* The uplink message: one measurement, sent every report period. */
        @Encoding { byteOrder = ByteOrder::bigEndian; }
        attribute sequence : Natural { @Encoding { bits = 16; } }
        attribute temperature : ThermodynamicTemperatureValue { @Encoding { bits = 16; signed = true; scale = 0.01 [K]; offset = 273.15 [K]; } }
        attribute battery : ElectricPotentialValue { @Encoding { bits = 16; scale = 1 [mV]; } }
        attribute status : NodeStatus;
        attribute samples : Integer[4] { @Encoding { bits = 16; signed = true; } }
    }
    ...
    item def Configure {
        doc /* The downlink message: a new report period. */
        @Encoding { byteOrder = ByteOrder::bigEndian; }
        attribute reportPeriod : DurationValue { @Encoding { bits = 16; scale = 1 [s]; } }
        attribute ledEnabled : Boolean;
    }
}
```

| `@Encoding` attribute | Meaning |
|---|---|
| `bits` | the field's size: 8, 16, 32 or 64 (fields are byte aligned) |
| `signed` | two's complement (default: unsigned for `Natural`, quantities and enumerations) |
| `scale`, `offset` | for a quantity sent as an integer count: value = count × scale + offset |
| `maxLength` | the maximum length of a `String` or of a `[0..*]` sequence |
| `byteOrder` | on a definition: `ByteOrder::bigEndian` or `littleEndian` (the default) |
| `code` | on an enumeration literal: its number (default: its position) |

So `temperature` travels as a signed 16-bit count of 0.01 K above 273.15 K: 21.5 °C is 2150. `battery`
is in millivolts. A multiplicity makes an array (`samples : Integer[4]`); a `[0..*]` with a
`maxLength` makes a counted array.

Generating data types writes four files:

- **`node_icd_types.h` / `.c`**: C. The struct holds what is sent: the count, not the physical value.
  Macros convert between counts and units, and the `encode`/`decode` functions handle the byte layout:

  ```c
  typedef struct {
      uint16_t sequence;
      /* 0.01 K per count, offset 273.15 K */
      int16_t temperature;
      /* 0.001 V per count */
      uint16_t battery;
      node_status_t status;
      int16_t samples[4];
  } reading_t;

  #define READING_MAX_SIZE 15u
  #define READING_TEMPERATURE_TO_K(count) ...
  #define READING_TEMPERATURE_FROM_K(value) ...
  size_t reading_encode(const reading_t *value, uint8_t *buf, size_t size);
  size_t reading_decode(reading_t *value, const uint8_t *buf, size_t size);
  ```

  The firmware's radio task encodes with it:

  ```c
  size_t radio_task(const reading_t *reading, uint8_t *frame, size_t size) {
      return reading_encode(reading, frame, size);
  }
  ```

- **`node_icd.schema.json`**: a JSON Schema for the same messages, in their units (`"x-unit": "K"`),
  with the ranges the encoding allows. Use it in the backend that receives the readings.
- **`node_icd.proto`**: Protocol Buffers messages with the same fields.

The generated C compiles warning-free with `-std=c11 -Wall -Wextra -pedantic`. The extension's tests
compile it and check that a message survives an encode/decode round trip byte for byte.

**Generate Documents** (chapter 21) lists the same messages in the ICD, field by field with encodings
and units. The document, the code and the model can't disagree.

## Register maps

The TMP117's registers are part of its datasheet, so they belong to its definition. The extension's
`Registers` library has `RegisterBlock`, `Register` and `Field`. Add the register block to `TMP117` in
`model/node-parts.sysml`:

<!-- check: project -->
```sysml
        /* Its registers (TMP117 datasheet, section 7.6). */
        part <TMP117> registers : Registers::RegisterBlock {
            :>> registerBits = 16;
            part <TEMP_RESULT> temperature : Registers::Register {
                doc /* The last conversion, 7.8125 m°C per count. */
                :>> offset = 0; :>> access = Registers::Access::readOnly; :>> resetValue = "0x8000";
            }
            part <CONFIGURATION> configuration : Registers::Register {
                :>> offset = 1;
                :>> resetValue = "0x0220";
                part <HIGH_ALERT> highAlert : Registers::Field { :>> lsb = 15; :>> access = Registers::Access::readOnly; }
                part <LOW_ALERT> lowAlert : Registers::Field { :>> lsb = 14; :>> access = Registers::Access::readOnly; }
                part <DATA_READY> dataReady : Registers::Field { :>> lsb = 13; :>> access = Registers::Access::readOnly; }
                part <MOD> mode : Registers::Field {
                    :>> lsb = 10; :>> width = 2;
                    attribute continuous = 0;
                    attribute shutdown = 1;
                    attribute oneShot = 3;
                }
                part <CONV> conversionCycle : Registers::Field { :>> lsb = 7; :>> width = 3; }
                part <AVG> averaging : Registers::Field { :>> lsb = 5; :>> width = 2; }
            }
            part <DEVICE_ID> deviceId : Registers::Register { :>> offset = 15; :>> access = Registers::Access::readOnly; :>> resetValue = "0x0117"; }
        }
```

- **Short names** (`<TEMP_RESULT>`) name the C macros, so they can follow the datasheet's naming.
- Numbers can be strings in hex or binary (`"0x0220"`, `"0b10"`), because SysML has no hex literals.
- A field's **named values** are attributes with a number (`oneShot = 3`).
- Access is `readWrite` (the default), `readOnly`, `writeOnly`, `write1ToClear` or `readToClear`; a
  field inherits its register's.

The extension checks the map as you type (`register-map`): overlapping registers or fields, fields
beyond the register's size, reset values and named values that don't fit.

Generating register maps writes `tmp117_regs.h`:

```c
#define TMP117_CONFIGURATION_OFFSET 0x01u
#define TMP117_CONFIGURATION_RESET 0x0220u
/* MOD: bits 11..10, RW */
#define TMP117_CONFIGURATION_MOD_SHIFT 10u
#define TMP117_CONFIGURATION_MOD_WIDTH 2u
#define TMP117_CONFIGURATION_MOD_MASK 0x0C00u
#define TMP117_CONFIGURATION_MOD_GET(reg) (((reg) & TMP117_CONFIGURATION_MOD_MASK) >> TMP117_CONFIGURATION_MOD_SHIFT)
#define TMP117_CONFIGURATION_MOD_SET(reg, value) ...
#define TMP117_CONFIGURATION_MOD_ONE_SHOT 3u
```

The driver uses it: `TMP117_CONFIGURATION_MOD_SET(config, TMP117_CONFIGURATION_MOD_ONE_SHOT)`. The ICD
document gets a register table.

## Variant configurations

From `node-variants.sysml` (chapter 17), generating variant configurations writes:

- **`config_outdoor_node.h`** and **`config_indoor_node.h`**: the choices and the `@Config` values of
  each configuration:

  ```c
  /* battery: lithiumPrimary (one of liIon, lithiumPrimary) */
  #define CONFIG_BATTERY_LI_ION 0
  #define CONFIG_BATTERY_LITHIUM_PRIMARY 1
  #define CONFIG_BATTERY "lithiumPrimary"
  ...
  #define CONFIG_REPORT_PERIOD_S 900 /* s */
  #define CONFIG_CELL_CAPACITY_MAH 2600 /* mAh */
  ```

- **`Kconfig`**: a `choice` per variation point (`BATTERY`, `RADIO`), with the variants' `doc` as help
  text, and a `config` for each `@Config` value;
- **`outdoor_node_defconfig`** and **`indoor_node_defconfig`**: each configuration's settings
  (`CONFIG_BATTERY_LITHIUM_PRIMARY=y`, `CONFIG_REPORT_PERIOD_S=900`…), for Zephyr or any Kconfig
  build.

The firmware then builds one image per configuration, and `#if CONFIG_RADIO_LO_RA` selects the
driver.

## State machines

Each state machine becomes table-driven C:

- **`power_modes.h`** declares:
  - the states and events as enumerations;
  - a `power_modes_t` holding the active states and their entry times;
  - the API: `power_modes_init`, `power_modes_dispatch(sm, event)`, `power_modes_tick(sm, now_ms)`
    for `after` and `at` timers and `when` conditions, `power_modes_state`, `power_modes_in`,
    `power_modes_next_timeout`;
  - one function per entry/do/exit action, guard, effect and `when` condition, which you implement.
- **`power_modes.c`** has the transition table and a small run-time with the simulator's semantics:
  inner states first, composite states entered through their initial substate, every region of a
  parallel state active with a transition per region, run to completion.
- **`power_modes_actions.c`** has stubs of the functions to implement, each with the SysML text it
  stands for as a comment. It is written only when it doesn't exist yet: once you fill it in, the
  generator leaves it alone.

```c
typedef enum {
    POWER_MODES_SLEEPING,
    POWER_MODES_ACTIVE,
    POWER_MODES_MEASURING, /* in active */
    POWER_MODES_TRANSMITTING, /* in active */
    POWER_MODES_FAULT,
    POWER_MODES_STATE_COUNT
} power_modes_state_t;

/* guard of lowBattery: batteryVoltage < 3.3 [V] */
bool power_modes_guard_low_battery(power_modes_t *sm);
```

The same goes for the MCU's `radioDriver` and the radio's `modem` (chapter 19): `radio_driver.c` is
the MCU side of the radio link. The test vectors of chapter 14 (**State Machine Coverage and Test
Vectors**) give the event sequences and expected states to test the generated machines with.

Parallel states and `accept at` triggers are generated too: `power_modes_in` tells which state of
each region is active, and `at` times count from `power_modes_init`.

## Traceability

Code and tests are where the design meets reality. Record **where each element is implemented** and
**which test verifies each requirement** with two metadata annotations from the `Software` library:

- `@Implements { file = "…"; symbol = "…"; }`: the source file (and optionally the function or
  class) that implements an element;
- `@VerifiedBy { file = "…"; test = "…"; }`: the test file (and optionally the test case) that
  verifies a requirement or element.

Paths are relative to the model file. Annotate the EnviroNode's firmware components in
`model/node-software.sysml`:

<!-- check: project -->
```sysml
        part rtos : SoftwareComponent {
            :>> flash = 12 [KiB]; :>> ram = 2 [KiB];
            @Implements { file = "../firmware/src/rtos_port.c"; }
        }
        part loraStack : SoftwareComponent { :>> flash = 96 [KiB]; :>> ram = 8 [KiB]; }
        part sensorDriver : SoftwareComponent {
            :>> flash = 4 [KiB]; :>> ram = 256 [B];
            @Implements { file = "../firmware/src/tmp117.c"; symbol = "tmp117_read"; }
        }
        ...
        part sampler : Task {
            :>> period = 100 [ms]; :>> wcet = 4 [ms]; :>> stack = 1 [KiB]; :>> flash = 2 [KiB];
            @Implements { file = "../firmware/src/sampler.c"; symbol = "sampler_task"; }
        }
        part radioTask : Task {
            :>> period = 1 [s]; :>> wcet = 40 [ms]; :>> deadline = 200 [ms]; :>> stack = 2 [KiB];
            @Implements { file = "../firmware/src/radio.c"; symbol = "radio_task"; }
        }
```

and the software requirements:

<!-- check: project -->
```sysml
    requirement cpuHeadroom : CpuHeadroom { @VerifiedBy { file = "../firmware/test/test_schedule.c"; test = "test_cpu_load"; } }
    ...
    requirement cycleLatency : CycleLatency { @VerifiedBy { file = "../firmware/test/test_cycle.c"; test = "test_cycle_latency"; } }
```

The links show up everywhere the extension reports:

- **In the editor**, each path is a link: **⌘-click** / **Ctrl+click** opens the file. A path to a file
  that doesn't exist is a `trace-missing-file` warning, so renamed or deleted files are caught.
- **In the verification matrix**, under each requirement: its tests (⟨test⟩) and the implementation
  of what satisfies it (⟨impl⟩). SW-2 shows `radio.c · radio_task`, because `radioTask` satisfies it
  and is implemented there. Click to open.
- **In the Software tab**, next to each task and component.
- **In the documents:** `traceability.md` has a matrix of requirements against tests and
  implementation, and a list of every implemented element (chapter 21).
- **In the JSON export** (`implements`, `verifiedBy`) and in **JUnit reports** as test case
  properties, so CI dashboards can link a requirement's result to its test.

## Check yourself

1. Add a field `rssi : Integer` (an 8-bit signed value) to `Reading`. What changes in the generated C?
2. In the TMP117's register map, give `AVG` a width of 3. What does the extension say?
3. You rename `firmware/src/sampler.c` to `sampling.c` and forget the model. What happens?

<details><summary>Answers</summary>

1. Add `attribute rssi : Integer { @Encoding { bits = 8; signed = true; } }`. The struct gets an
   `int8_t rssi;`, `READING_MAX_SIZE` becomes 16, and `reading_encode`/`decode` write and read one
   more byte. The JSON Schema and the protobuf message get the field too, and the ICD lists it.
2. A `register-map` error: *Field AVG overlaps CONV in CONFIGURATION*. Bits 7..5 collide with CONV's
   9..7.
3. A `trace-missing-file` warning on the `@Implements` path in `node-software.sysml`, and the link is
   struck through in the verification matrix and the Software tab. In CI, `sysml-sim check
   --warnings-as-errors` fails the build.

</details>

Next: [21. Models as code](21-models-as-code.md)
