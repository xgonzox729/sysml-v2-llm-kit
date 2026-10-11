# 14. States

A battery-powered device spends its life switching between modes: asleep, measuring, transmitting,
in a fault. What it draws, what it reacts to and what it does depend on the mode. That is a **state
machine**, the second way SysML describes behaviour. This chapter models the EnviroNode's power
modes, steps through them, and finds out which transitions a test can actually reach.

## States and transitions

<!-- check: standalone -->
```sysml
package States {
    item def Wake;
    item def Sleep;

    state def Modes {
        entry; then sleeping;                      // the initial state

        state sleeping;
        state active;

        transition wakeUp
            first sleeping
            accept Wake
            then active;

        transition first active accept Sleep then sleeping;
    }
}
```

- A **state definition** (`state def`) contains **states** (`state`) and **transitions** between
  them.
- **`entry; then sleeping;`** says which state the machine starts in.
- A **transition** goes from a source (`first sleeping`) to a target (`then active`) when its
  **trigger** happens (`accept Wake`: an item of type `Wake` arrives). It can be named (`wakeUp`)
  or anonymous, and written on one line or several.

A full transition has up to four parts besides its source and target:

```
transition name first source accept trigger if guard do effect then target;
```

| Part | Meaning | Example |
|---|---|---|
| `accept` (trigger) | the event that fires it | `accept Wake`, `accept after 50 [ms]`, `accept when charge < 10 [mAh]` |
| `if` (guard) | a condition that must hold too | `if batteryVoltage < 3.3 [V]` |
| `do` (effect) | an action run on the way | `do assign wakeups := wakeups + 1` |

The trigger can be:
- **a signal**: `accept Wake` fires when an item of that type arrives;
- **a time event**: `accept after 50 [ms]` fires 50 ms after the source state was entered;
  `accept at 2 [h]` fires at a point in time (in the simulator and the generated C: 2 h after the
  start), once, if the source state is active then;
- **a change event**: `accept when wakeups > 1000` fires as soon as the condition becomes true;
- **nothing** (a completion transition): it fires as soon as the source state has nothing left to
  do.

### What states do

A state can run actions when it is entered, while it is active, and when it is left:

<!-- check: standalone -->
```sysml
package StateActions {
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;

    state def RadioModes {
        attribute current : ElectricCurrentValue = 0.4 ['µA'];
        entry; then off;
        state off { entry action { assign current := 0.4 ['µA']; } }
        state transmitting {
            entry action powerUp { assign current := 45 [mA]; }
            exit action powerDown;
        }
        transition first off accept after 1 [s] then transmitting;
        transition first transmitting accept after 40 [ms] then off;
    }
}
```

`entry action`, `do action` and `exit action` run on entering the state, while it is active, and on
leaving it. `assign` changes an attribute. Here, the current the radio draws in each mode.

### Nested and parallel states

A state can contain states: a **composite** state with its own initial substate. A transition from
the composite state leaves it whatever substate is active. That is how you say "from anywhere
inside *active*, a low battery goes to *fault*".

A state marked `parallel` has **regions** that are all active at once, for example a radio state
machine running alongside a sensor one. Entering the parallel state enters every region, and one
event can fire a transition in each region:

<!-- check: standalone -->
```sysml
package Parallel {
    item def Go;
    state def Device {
        entry; then running;
        state running parallel {
            state radio { entry; then idle; state idle; state busy; transition first idle accept Go then busy; }
            state sensor { entry; then waiting; state waiting; }
        }
    }
}
```

### Exhibiting a state machine

A part **exhibits** a state machine: `exhibit state powerModes : PowerModes;` in a part definition
says that every part of that kind behaves that way.

## In the tool

### The State machine view

Put the cursor in a state machine and run **SysML: Open State Machine View of Element at Cursor**.
States are rounded boxes, nested in their composite states, and their entry/do/exit actions are
listed in compartments. The initial state has an arrow from a filled circle. Transitions are
labelled `trigger [guard] / effect`.

### Stepping through it

Run **SysML: Simulate State Machine or Action at Cursor**. The **Behavior** tab shows:

- **Events:** a button for each event the active states react to: signals by their type name, timers
  as `after 50 [ms]`. Click one to send it. The text box sends any event by name; an event nothing
  reacts to is logged as ignored.
- **Active states**, innermost first. For a composite state, both it and its active substate.
- **Values changed**: the attributes the effects and entry actions have assigned.
- **Log**: every event, transition, entry, exit and assignment, in order.
- **Show diagram** highlights the active states and the transitions just taken in the State machine
  view. **Undo** and **Reset** work as for actions.

The simulator follows SysML's run-to-completion semantics. An event is handled completely before the
next one: exits, effect, entries, then any completion transitions and `when` conditions that now
hold.

### Coverage and test vectors

Which transitions can a test actually reach, and with which sequence of events? Run **SysML: State
Machine Coverage and Test Vectors** (or click **Coverage** in the Behavior tab). The extension
explores the machine with the simulator. From each configuration (active states and values) it tries
every event, including the timers, and remembers the shortest sequence that fires each transition.
It then shows:

- the **coverage**: how many transitions and states can be reached, and for each one that can't,
  **why**: a guard that never held, a source state that is never active, a `when` that never became
  true;
- the **test vectors**: for each transition, the shortest sequence of events that fires it, with the
  states expected after each event. **Test vectors (JSON)** saves them. Firmware tests can replay the
  events against the real code and compare the states (chapter 20 generates that code).

![Coverage and test vectors](images/node-coverage.png)

## The EnviroNode: power modes

Add the power modes to `model/node-behavior.sysml`. The node sleeps; on `Wake` it goes active,
measures for 50 ms, transmits, and 150 ms after waking it sleeps again. A low battery while active
leads to a fault state, from which only a `Reset` brings it back. The attributes record the current
in each mode and the charge left in the cell; chapter 15 uses them to simulate a week.

<!-- check: project -->
```sysml
    item def Wake;
    item def LowBattery;
    item def Reset;
    ...
    /* The node's power modes, with the current it draws in each and the charge left in its cell. */
    state def PowerModes {
        attribute current : ElectricCurrentValue = 6 ['µA'];
        /* 80 % of the 2400 mAh cell is usable. */
        attribute charge : ElectricChargeValue = 1920 [mAh];
        attribute batteryVoltage : ElectricPotentialValue = 3.7 [V];
        attribute wakeups : Integer = 0;
        ...
        entry; then sleeping;

        state sleeping { entry action sleepCurrent { assign current := 6 ['µA']; } }
        transition wake first sleeping accept Wake do assign wakeups := wakeups + 1 then active;

        state active {
            entry; then measuring;
            state measuring { entry action measureCurrent { assign current := 4.2 [mA]; } }
            transition first measuring accept after 50 [ms] then transmitting;
            state transmitting { entry action radioCurrent { assign current := 49 [mA]; } }
        }
        transition sleepAgain first active accept after 150 [ms] then sleeping;
        transition lowBattery first active accept LowBattery if batteryVoltage < 3.3 [V] then fault;

        state fault { entry action alarm { assign current := 1 ['µA']; } }
        transition reset first fault accept Reset then sleeping;
    }
```

The currents are the node's total in each mode:
- **sleeping:** 6 µA (everything asleep, plus the LDOs' quiescent current);
- **measuring:** 4.2 mA (the MCU at 4 mA, plus the sensor);
- **transmitting:** 49 mA (the MCU, plus the radio at 45 mA).

`sleepAgain` leaves `active` from whichever substate is active, 150 ms after `active` was entered.

Make every EnviroNode exhibit it, in `EnviroNode` in `model/node-architecture.sysml`:

<!-- check: project -->
```sysml
        perform action measurementCycle : MeasurementCycle;
        exhibit state powerModes : PowerModes;
```

### Step through it

Put the cursor in `PowerModes` and run **SysML: Simulate State Machine or Action at Cursor**:

1. **Active states:** `sleeping`. **Values changed:** `current = 6 µA`.
2. Click **Wake**. The log shows the transition `sleeping → active on Wake`, the effect `wakeups :=
   1`, entering `active`, then `measuring`, and `current := 4.2 mA`. The events are now `after 150
   [ms]`, `LowBattery` and `after 50 [ms]`.
3. Click **after 50 [ms]**: `transmitting`, `current := 49 mA`.
4. Click **LowBattery**: nothing happens. The guard `batteryVoltage < 3.3 [V]` doesn't hold at
   3.7 V, and the log says the event was ignored.
5. Click **after 150 [ms]**: back to `sleeping`.

### Coverage

Run **SysML: State Machine Coverage and Test Vectors** with the cursor in `PowerModes`:

- **3/5 transitions, 4/5 states.**
- Not covered: `lowBattery` (*its guard batteryVoltage < 3.3 [V] never held*), and `reset`
  (*fault is never active*), and so neither is the `fault` state.
- Two test vectors:
  1. `Wake → measuring`, `after 150 [ms] → sleeping`, covering `wake` and `sleepAgain`;
  2. `Wake → measuring`, `after 50 [ms] → transmitting`, covering `measuring → transmitting`.

The uncovered transitions are not a model error: with the cell at 3.7 V the guard can't hold. To
test the fault path, test with a low cell. Change `batteryVoltage` to `3.0 [V]` and run coverage
again: all five transitions and five states are covered, and a new vector, `Wake → measuring`,
`LowBattery → fault`, `Reset → sleeping`, covers `lowBattery` and `reset`. Change it back.

## Check yourself

1. Add a `do` action to `active` that blinks the LED: `do action blink;`. Where does it appear in the
   State machine view?
2. Why does `sleepAgain` start from `active` and not from `transmitting`?
3. What would a transition `first sleeping accept when wakeups > 1000 then fault;` do in the
   stepper?

<details><summary>Answers</summary>

1. In `active`'s compartment, as `do blink`. It runs while `active` is the active state, after its
   entry action.
2. From `active` it fires 150 ms after waking whatever the substate, even if a transmission takes
   longer than planned. From `transmitting` it would only fire once the node got there.
3. Nothing at first. After 1001 `Wake`/`after 150 [ms]` cycles, `wakeups` exceeds 1000 and the change
   event fires as soon as the machine is back in `sleeping`. Coverage would report it as not covered
   within its exploration limit.

</details>

Next: [15. Time simulation](15-time-simulation.md)
