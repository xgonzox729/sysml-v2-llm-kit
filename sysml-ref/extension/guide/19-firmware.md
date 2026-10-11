# 19. Firmware architecture

Firmware is part of the system, and its budgets are as real as the power budget: CPU time, flash, RAM,
stack, deadlines and latencies. This chapter models the EnviroNode's firmware with SysML parts, checks
that its tasks are schedulable and fit in memory, and simulates the messages between the MCU and the
radio.

## Software as parts

SysML doesn't distinguish hardware from software: a part is anything with features, and a software
component is a part. The extension's `Software` library defines what firmware analysis needs:

| Definition | Means | Attributes |
|---|---|---|
| `Processor` | something that runs software (Electronics' `Microcontroller` counts as one) | `cores`, `flash`, `ram` |
| `SoftwareComponent` | a piece of firmware: a driver, a protocol stack, a library | `flash`, `ram` |
| `Task` (a `SoftwareComponent`) | a periodic task or an interrupt handler | `period`, `wcet`, `deadline`, `priority`, `core`, `stack` |

Software components and tasks count against a processor when they are **parts of it**, at any depth,
or **allocated to it** (`allocate firmware to mcu`, chapter 17). Allocation is the better model: the
firmware is a product of its own, and the MCU runs it.

### Schedulability

Tasks are scheduled with **fixed priorities, preemptively**, as in FreeRTOS, Zephyr or any common
RTOS:

- a task's **period** is the time between its releases; for an interrupt, its minimum inter-arrival
  time;
- its **WCET** is its worst-case execution time;
- its **deadline** is when it must have finished after its release (the period, by default);
- its **priority**: higher runs first. Without one, priorities are **rate monotonic**: the shorter the
  period, the higher the priority.

The extension computes:

- **CPU utilization** per core: Σ WCET / period. Above 100 % the core can't keep up. Below the
  **rate-monotonic bound** n(2^(1/n) − 1), about 76 % for four tasks, any set of rate-monotonic tasks
  is schedulable.
- **Response-time analysis** for each task: the worst case from release to completion, including
  every preemption by higher-priority tasks. R = C + Σ ⌈R / Tⱼ⌉ Cⱼ over the higher-priority tasks j,
  iterated until it settles. A task whose response time exceeds its deadline misses it.

### Memory

**Flash used** is the sum of the components' and tasks' `flash`; **RAM used** is the sum of their `ram`
plus every task's `stack`. Both are compared with the processor's `flash` and `ram`.

### Checks and calculations

| Diagnostic | Meaning |
|---|---|
| `deadline-miss` | A task's worst-case response time exceeds its deadline, or it can starve. |
| `cpu-overload` | A core is more than 100 % used. |
| `memory-budget` | The software needs more flash or RAM than the processor has. |
| `task-incomplete` | A task has no period or WCET (warning). |

A task is reported where it is declared when that file also holds the processor. Otherwise (the
firmware in a file of its own, as in the EnviroNode) the error appears on the processor, naming
the task.

Requirements can use the results through library calculations:

| Calculation | Result |
|---|---|
| `Utilization(processor)`, `Utilization(processor, core)` | the CPU share used (0 to 1) |
| `ResponseTime(task)` | its worst-case response time |
| `FlashUsed(processor)`, `RamUsed(processor)` | memory used |
| `Latency(action)` | the critical path of an action flow (chapter 13) |

## The EnviroNode's firmware

Create `model/node-software.sysml`. The firmware is a part definition with three components and four
tasks:

<!-- check: project -->
```sysml
package NodeSoftware {
    doc
    /*
     * The EnviroNode's firmware: its components and tasks on the microcontroller, what they
     * cost in flash, RAM and CPU time, and the software requirements. Paths in @Implements and
     * @VerifiedBy are relative to this file.
     */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Electronics::*;
    private import Software::*;
    private import NodeArchitecture::*;

    part def NodeFirmware {
        doc /* Everything that runs on the MCU. */
        part rtos : SoftwareComponent {
            :>> flash = 12 [KiB]; :>> ram = 2 [KiB];
            ...
        }
        part loraStack : SoftwareComponent { :>> flash = 96 [KiB]; :>> ram = 8 [KiB]; }
        part sensorDriver : SoftwareComponent {
            :>> flash = 4 [KiB]; :>> ram = 256 [B];
            ...
        }

        part wakeIsr : Task {
            doc /* The wake-up interrupt; at most every 10 ms. */
            :>> period = 10 [ms]; :>> wcet = 50 ['µs']; :>> priority = 10; :>> stack = 256 [B];
        }
        part sampler : Task {
            :>> period = 100 [ms]; :>> wcet = 4 [ms]; :>> stack = 1 [KiB]; :>> flash = 2 [KiB];
            ...
        }
        part radioTask : Task {
            :>> period = 1 [s]; :>> wcet = 40 [ms]; :>> deadline = 200 [ms]; :>> stack = 2 [KiB];
            ...
        }
        part watchdog : Task { :>> period = 500 [ms]; :>> wcet = 200 ['µs']; :>> stack = 512 [B]; }
    }
    ...
}
```

(The `...` lines are the `@Implements` annotations of chapter 20.)

The wake interrupt gets an explicit priority of 10, the highest, as an interrupt would have. The other
tasks are rate monotonic.

Then put the firmware into the node and allocate it to the MCU. In `node` in
`model/node-architecture.sysml`:

<!-- check: project -->
```sysml
        /* The firmware (NodeSoftware), and the processor it runs on. */
        part firmware : NodeSoftware::NodeFirmware;
        allocate firmware to mcu;
```

### The Software tab

Run **SysML: Verify Requirements** on `model/node-architecture.sysml` and open the **Software** tab:

- **mcu:** CPU **8.5 %** (rate-monotonic bound 76 %), flash **114 KiB of 192 KiB** (59 %), RAM **14 KiB
  of 20 KiB** (70 %).
- The tasks, by priority (the panel rounds the percentages):

  | Task | Priority | Period | WCET | CPU | Deadline | Response | Of deadline | Stack |
  |---|---|---|---|---|---|---|---|---|
  | firmware.wakeIsr | 1 | 10 ms | 50 µs | 0.5 % | 10 ms | 50 µs | 0.5 % | 256 B |
  | firmware.sampler | 2 | 100 ms | 4 ms | 4 % | 100 ms | 4.05 ms | 4 % | 1 KiB |
  | firmware.watchdog | 3 | 500 ms | 200 µs | 0.04 % | 500 ms | 4.25 ms | 0.85 % | 512 B |
  | firmware.radioTask | 4 | 1 s | 40 ms | 4 % | 200 ms | 44.45 ms | 22 % | 2 KiB |

- The components, with their flash and RAM.

The radio task's response time is its own 40 ms plus the preemptions during it: five wake interrupts
(0.25 ms), one sampler run (4 ms) and one watchdog run (0.2 ms), 44.45 ms in all. Its 200 ms deadline
is comfortable. The CPU is mostly idle, as it should be in a sleepy sensor node. The RAM is the tighter
budget.

![The Software tab](images/node-software.png)

### Software requirements

Add the software requirements to `model/node-software.sysml`:

<!-- check: project -->
```sysml
    requirement def <'SW-1'> CpuHeadroom {
        doc /* The firmware leaves at least 30 % of the CPU free. */
        subject m : Microcontroller;
        require constraint { Utilization(m) <= 0.7 }
    }
    requirement def <'SW-2'> RadioDeadline {
        doc /* A reading is on its way to the radio within 200 ms of its release. */
        subject t : Task;
        require constraint { ResponseTime(t) <= 200 [ms] }
    }
    requirement def <'SW-3'> MemoryBudget {
        doc /* At least 25 % of flash and RAM stay free for updates. */
        subject m : Microcontroller;
        require constraint { FlashUsed(m) <= 0.75 * m.flash }
        require constraint { RamUsed(m) <= 0.75 * m.ram }
    }
    requirement def <'SW-4'> CycleLatency {
        doc /* A measurement is sent within 60 ms of waking up. */
        subject n : EnviroNode;
        require constraint { Latency(n.measurementCycle) <= 60 [ms] }
    }
    ...
    requirement radioDeadline : RadioDeadline;
    requirement memoryBudget : MemoryBudget;
    ...
    satisfy cpuHeadroom by node.mcu;
    satisfy radioDeadline by node.firmware.radioTask;
    satisfy memoryBudget by node.mcu;
    satisfy cycleLatency by node;
```

(The two elided requirement usages carry `@VerifiedBy` annotations; chapter 20 shows them in full.)

Verify the file:

| | ID | Requirement | Subject | Margin |
|---|---|---|---|---|
| ✓ | SW-1 | cpuHeadroom | mcu | 88 % |
| ✓ | SW-2 | radioDeadline | radioTask | 78 % |
| ✓ | SW-3 | memoryBudget | mcu | 6.7 % |
| ✓ | SW-4 | cycleLatency | node | 24 % |

SW-3 is the one to watch: 14 KiB of RAM against a limit of 15 KiB (75 % of 20). Add a 2 KiB buffer
anywhere and it fails, long before the hardware would.

## Messages between the MCU and the radio

The task model says *how much* the firmware does. How the MCU and the radio talk to each other is
behaviour: each has a state machine, and they exchange **messages**:

- `send Reading() via spi` sends a `Reading` item out of the MCU's `spi` port. The extension follows
  the port's connection (the `spi` interface of chapter 6) to the radio.
- `send TxDone() to mcu` sends straight to a part by name.
- `accept Reading` on the other side is the trigger that receives it.

A part whose parts have state machines is an **interaction**: the Behavior tab lists it, and the
simulator runs all the machines together.
- An input you send goes to the part you name (`node.radio: Ack`), or to every part that reacts to it.
- After each input, messages are delivered in order and `after` timers fire in time order, until
  nothing is left to do.
- Every message is recorded with its time, sender and receiver, and drawn as a **sequence diagram**.

### The EnviroNode's radio link

Add the message `TxDone` to `model/node-icd.sysml` (chapter 20 completes that file):

<!-- check: project -->
```sysml
    item def TxDone {
        doc /* The radio's signal to the MCU that a packet is on the air. */
    }
```

Give the MCU a radio driver and the radio a modem, in `model/node-parts.sysml`. First the imports at
the top of the package:

<!-- check: project -->
```sysml
    private import Electronics::*;
    private import NodeIcd::*;
    private import NodeBehavior::Wake;
```

The MCU's driver, at the end of `NodeMcu`: on `Wake` it samples, hands the reading to the radio, and
retries twice if the radio doesn't confirm within 100 ms.

<!-- check: project -->
```sysml
        /* The radio driver in the firmware: on Wake, sample, hand the reading to the radio, retry twice. */
        attribute retries : Integer = 0;
        exhibit state radioDriver {
            entry; then idle;
            state idle;
            state sampling;
            state sending { entry send Reading() via spi; }
            transition first idle accept Wake then sampling;
            transition first sampling accept after 5 [ms] then sending;
            transition sent first sending accept TxDone then idle;
            transition retry first sending accept after 100 [ms] if retries < 2 do assign retries := retries + 1 then sending;
        }
```

The radio's modem, at the end of `LoRaRadio`: a reading goes on the air for 40 ms, then the MCU is
told.

<!-- check: project -->
```sysml
        /* The modem: a reading from the MCU goes on the air for 40 ms, then the MCU is told. */
        exhibit state modem {
            entry; then standby;
            state standby;
            state transmitting;
            transition first standby accept Reading then transmitting;
            transition first transmitting accept after 40 [ms] do send TxDone() via spi then standby;
        }
```

### Run the interaction

Open `model/node-architecture.sysml`, put the cursor on `part node`, and run **SysML: Simulate State
Machine or Action at Cursor**. The Behavior tab shows the **interaction node**, with the active states
of both parts (`node.mcu: idle`, `node.radio: standby`) and the events `node.mcu: Wake` and
`node.radio: Reading`. Click **node.mcu: Wake**. The **Sequence** diagram draws:

| Time | From | To | Message |
|---|---|---|---|
| 0 s | environment | node.mcu | Wake |
| 5 ms | node.mcu | node.mcu | after 5 [ms] (timer) |
| 5 ms | node.mcu | node.radio | Reading |
| 45 ms | node.radio | node.radio | after 40 [ms] (timer) |
| 45 ms | node.radio | node.mcu | TxDone |

The reading is on the air 45 ms after the wake-up, consistent with the measurement cycle's latency of
chapter 13.

![The MCU–radio interaction](images/node-sequence.png)

### Declared messages

The state machines say what the parts *do*. The architecture can also say what they *should*
exchange, independently of how: a **message** usage names an item, its sender and its receiver. A
`flow` (chapter 6) says the same for an item that travels over a connection.

<!-- check: project -->
```sysml
        message txDone of NodeIcd::TxDone from radio to mcu;
```

Add it to `node` in `model/node-architecture.sysml`, after the `flow of NodeIcd::Reading from mcu to
radio;` of chapter 6. Every interaction run is then checked against the declarations: under the
sequence diagram, **Declared messages: 2/2 seen** lists the `Reading` flow and `txDone`, each with how
often the run sent it. A signal no declaration covers is listed with ✗ *not declared*, or *declared in
the other direction* when only the direction is wrong. A declaration the run didn't use is marked
*not seen in this run*: run the scenario that should send it. `sysml-sim simulate` prints the same
check under the sequence.

Declarations are the interface contract, the state machines are the implementation, and the run checks
one against the other.

## Check yourself

1. The radio stack needs 4 KiB more RAM. Which requirement fails, and with what margin?
2. Give the radio task priority 20 (above the wake interrupt). What happens to the wake interrupt's
   response time?
3. Remove `do send TxDone() via spi` from the modem and run the interaction again. What does the
   sequence diagram show?

<details><summary>Answers</summary>

1. SW-3: RAM used becomes 18 KiB against 15 KiB, a margin of −20 %. The CPU and the deadlines are
   unaffected.
2. The wake interrupt now waits for the radio task: its response time becomes 40.05 ms, far beyond its
   10 ms deadline. A `deadline-miss` error appears on the MCU in `node-architecture.sysml`, where
   the firmware runs: *firmware.wakeIsr misses its deadline: worst-case response 40.05 ms > 10 ms.*
   Interrupts belong at the top.
3. No `TxDone` comes back, so the driver retries: `Reading` goes to the radio at 5 ms, 105 ms and
   205 ms, and the declared `txDone` is *not seen in this run*. After the second retry (`retries` = 2) the guard stops it, and the driver stays in
   `sending`. A real driver needs a way out: a transition to an error state after the last retry.

</details>

Next: [20. Code generation and traceability](20-code-generation.md)
