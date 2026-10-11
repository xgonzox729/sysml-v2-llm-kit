# 15. Time simulation

The stepper of chapter 14 is driven by you, one event at a time. To answer "how much charge does a
week of operation use?" you need to run the state machine **over simulated time**:
- events arrive on a schedule;
- timers fire on their own;
- quantities that change continuously, like the charge in a cell, are integrated between events.

This chapter adds the two annotations that make the EnviroNode's power modes a time simulation, and
reads the result.

## `@Rate`: values that change continuously

`@Rate` (from the `Simulation` library) says an attribute changes at a rate: its derivative.

<!-- check: fragment -->
```sysml
    state def Discharge {
        attribute current : ElectricCurrentValue = 5 [mA];
        attribute charge : ElectricChargeValue = 2400 [mAh];
        @Rate { rateOf = charge; rate = -current; }     // d(charge)/dt = -current
        entry; then on;
        state on;
    }
```

- `rateOf` is the attribute that changes, `rate` its rate of change: here the cell discharges at the
  present current.
- The rate can be any expression, and it is re-evaluated as the attributes it uses change: when a
  state's entry action assigns a new `current`, the discharge follows.
- Put `@Rate` in a **state** to make it apply only while that state is active (a heater warming up
  only while `heating`), or on the **state machine** or a **part** to make it apply always.
- Between events the simulator integrates rates with a fixed-step Runge–Kutta (RK4) method.

## `@Simulate`: the run

`@Simulate` on a state machine (or a part with state machines) makes it runnable over time:

| Attribute | Meaning |
|---|---|
| `duration` | how long to simulate: `7 [d]` |
| `step` | the integration step between events: `60 [s]` (default: duration / 1000) |
| `events` | a schedule of signals: `"Wake every 15 [min]"`, `"Reset at 2 [h]"`, `"Wake every 1 [h] from 30 [min]"` |
| `record` | more attributes to chart (rate attributes are always recorded) |
| `stopWhen` | a condition that ends the run early: `charge <= 0 [mAh]` |

The simulator handles the machine as the stepper does, with time added:

- `after` and `at` timers fire when they are due;
- scheduled events arrive at their times;
- `when` conditions are checked after every step;
- the simulator jumps exactly to each timer and event, so a 50 ms state in a 60 s step is timed
  precisely.

## In the tool

Run **SysML: Run Time Simulation** with the cursor in the state machine, or click **Run over time**
in the Behavior tab (the button appears when the selected state machine has `@Simulate`). The tab
gets an **Over time** section:

- a **state timeline**: one row per innermost state, with a bar wherever it was active;
- a **chart per recorded value** (here, the charge) against time;
- the **budget per mode**: for each mode, the time spent in it, the share of the run, and the change
  of each rate attribute while in it (the charge used in each mode);
- **CSV** to save the recorded values for a spreadsheet or a plot.

![A week of operation](images/node-timeline.png)

## The EnviroNode: a week of operation

Add the two annotations to `PowerModes` in `model/node-behavior.sysml`, after its attributes:

<!-- check: project -->
```sysml
    state def PowerModes {
        ...
        /* The cell discharges at the present current. */
        @Rate { rateOf = charge; rate = -current; }
        @Simulate {
            duration = 7 [d];
            step = 60 [s];
            events = ("Wake every 15 [min]");
            stopWhen = charge <= 0 [mAh];
        }

        entry; then sleeping;
        ...
    }
```

Run **SysML: Run Time Simulation**. The node wakes 672 times in the week (4 times an hour, for 168
hours) and the run gives:

| Mode | Time | Share | Charge used |
|---|---|---|---|
| sleeping | 6.999 d | 99.98 % | 1.008 mAh |
| transmitting | 1.118 min | 0.01 % | 913.3 µAh |
| measuring | 33.55 s | 0.01 % | 39.14 µAh |

The cell goes from 1.92 Ah to 1.91804 Ah: **1.96 mAh a week**. Two things stand out:

- **Sleep and transmit cost about the same.** The node spends 99.98 % of its time asleep at 6 µA, and
  0.01 % transmitting at 49 mA, and the two use similar charge. To extend the battery life, attack
  both: the sleep current (leakage, LDO quiescent current, sensor standby) and the time on air
  (shorter packets, a higher data rate).
- **At this rate the cell would last 18.8 years** (1920 mAh / 1.96 mAh a week). The power-tree
  estimate of chapter 7 said 3.28 years. Both are right, for different questions. The power tree used
  *budgeted* duty cycles: the MCU awake 1 % of the time, about 14 minutes a day, a deliberate
  allowance for retries, firmware updates and worst-case wake-ups. The time simulation runs the
  *nominal* schedule: 150 ms every 15 minutes.

  A real design keeps the budget for the requirement and uses the simulation to understand where the
  charge goes. But one real effect is missing from both: the cell's own **self-discharge**.

## Check yourself

1. A lithium-ion cell loses about 2 % of its charge a month to self-discharge: for 2400 mAh, about
   66 µA on average. Add it to the rate: `rate = -(current + 66 ['µA'])`. How long would the cell
   last now?
2. Add `"LowBattery at 3 [d]"` to the events. What happens on day 3?
3. Why does the step of 60 s not make the 50 ms measuring state inaccurate?

<details><summary>Answers</summary>

1. A week now uses 13.05 mAh (the sleep budget becomes 12.09 mAh), so the cell lasts 1920 / 13.05 ≈
   147 weeks: **2.8 years**. Self-discharge, not the electronics, dominates, and the three-year
   requirement fails. That is why the outdoor variant of chapter 17 uses a lithium primary cell, which
   loses only about 1 % a *year*.
2. Nothing. At exactly three days a `Wake` is due too, so the node is active when `LowBattery`
   arrives, but the transition's guard needs `batteryVoltage < 3.3 [V]`, which never holds at 3.7 V.
   The budget per mode still lists only sleeping, measuring and transmitting: `fault` is never
   entered. (At any other time the node would almost certainly be asleep, where `LowBattery` isn't
   accepted at all.)
3. The simulator doesn't wait for the next step to fire a timer: it jumps to the exact time of each
   event and timer, and integrates the rate in between. The step only sets the resolution of the
   integration and of the charts.

</details>

Next: [16. Interface checks and wiring](16-interfaces-and-wiring.md)
