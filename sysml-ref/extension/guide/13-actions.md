# 13. Actions

So far the model says what the EnviroNode *is*. Now it describes what it *does*. SysML has two
complementary ways to describe behaviour:

- **actions**: what is done, in what order. Use them for procedures, algorithms and functional
  flows. This chapter.
- **states**: which mode the system is in, and what makes it change. Chapter 14.

## Actions and successions

An **action definition** is a kind of activity, with input and output parameters. Its body lists the
**steps** (sub-actions) and the order they run in (**successions**):

<!-- check: standalone -->
```sysml
package Actions {
    item def Reading;

    action def TakeReading {
        out reading : Reading;
    }

    action def Report {
        first start;
        then action wake;
        then action read : TakeReading;
        then action send;
        then action sleep;
        then done;
    }
}
```

- `start` and `done` are the beginning and the end of the action, from the standard library.
- `first start;` names the first step. **`then x;`** is a **succession**: after the previous step,
  do `x`. A succession can also be written in full, `first wake then read;`, anywhere in the body.
- `then action wake;` declares the step and orders it in one line. You can also declare steps first
  and order them separately.
- Steps can be typed by action definitions (`read : TakeReading`), so behaviour decomposes the way
  structure does.

### Decisions, loops, forks and joins

<!-- check: standalone -->
```sysml
package ControlFlow {
    private import ScalarValues::*;

    action def Measure {
        attribute samples : Integer = 0;
        first start;
        then action sample { assign samples := samples + 1; }
        then decide enough;
            if samples < 4 then sample;     // back to sample: a loop
            else average;
        action average;
        then fork split;                    // after average, two things at once
            then store;
            then transmit;
        action store;
        action transmit;
        join both;                          // wait for both
        first store then both;
        first transmit then both;
        first both then done;
    }
}
```

- A **decide** node takes one of its outgoing successions: the first whose guard (`if …`) holds, or
  the `else` one.
- A **fork** starts all its outgoing successions; a **join** waits for all its incoming ones. Use
  them for concurrency: storing a reading in flash while the radio sends it.
- **`assign x := value`** changes an attribute. Here it counts the samples, so the decision can end
  the loop.
- There is also `merge` (the counterpart of a decision), and `accept` / `send` for events and
  messages. The `readData` use case in chapter 18 waits for a reading with
  `action waitForReading accept Reading`.

### Performing actions

A part **performs** an action: `perform action measurementCycle : MeasurementCycle;` in a part
definition says every part of that kind does it. Chapter 17 shows how to **allocate** a performed
action to the part that carries it out.

## Timing and latency

How long does a measurement take, from waking up to going back to sleep? Give each step a duration
with `@Timing` (from the extension's `Software` library):

<!-- check: fragment -->
```sysml
    action def Blink {
        first start;
        then action on { @Timing { duration = 5 [ms]; } }
        then action off { @Timing { duration = 95 [ms]; } }
        then done;
    }
```

The **latency** of an action is the length of its longest path from `start` to `done`: the
**critical path**.
- A sequence adds up its steps.
- A fork takes its slowest branch.
- A loop is counted once (the extension can't know how many times it will run).
- A step with no `@Timing` but a flow of its own counts that flow's latency.
- Untimed steps count as zero and are listed.

The library calculation `Latency(action)` returns it, so a requirement can constrain it (chapter
19).

## In the tool

### The Action flow view

Put the cursor in an action definition and run **SysML: Open Action Flow View of Element at Cursor**.
The view draws:

- steps as rounded boxes, with `start` as a filled circle and `done` as a bull's-eye;
- decisions and merges as diamonds, forks and joins as bars;
- successions as arrows, labelled with their guards (`[samples < 4]`, `[else]`);
- parameters as pins on the border, and item flows as arrows with the item's name.

As everywhere, click to reveal in the text. Shift+drag from one step to another adds a succession
(or a flow) in the text.

### Running it

Put the cursor in the action and run **SysML: Simulate State Machine or Action at Cursor**. The
Simulation panel's **Behavior** tab shows the action and its controls:

- **Step** moves every token one step along the flow; **Run** runs until the action is done or waits
  for an event.
- **Tokens at** lists where the tokens are. Two tokens after a fork, one again after the join.
- **Values changed** shows the attributes assigned so far (`samples = 4`).
- **Log** records every step, decision and assignment.
- **Show diagram** opens the Action flow view with the active steps and the successions just taken
  highlighted.
- **Undo** takes back the last step, and **Reset** starts again. The run follows your edits: change
  the model and the panel replays the same inputs on the new version.

The behaviour selector at the top of the tab lists every state machine and action flow in the file.

![Stepping through the measurement cycle](images/node-action.png)

## The EnviroNode: the measurement cycle

Create `model/node-behavior.sysml`. Every report period the node wakes up, takes four temperature
samples, averages them (and reads the cell voltage), then stores and transmits the result in
parallel, and goes back to sleep:

<!-- check: project -->
```sysml
package NodeBehavior {
    doc /* What the EnviroNode does: its measurement cycle (an action flow) and its power modes (a state machine). */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Simulation::*;
    private import Software::*;
    ...
    /* One measurement: wake up, read the sensor, store and send the reading, sleep again. */
    action def MeasurementCycle {
        attribute samples : Integer = 0;
        first start;
        then action wake { @Timing { duration = 1 [ms]; } }
        then action sample {
            @Timing { duration = 4 [ms]; }
            assign samples := samples + 1;
        }
        then decide enough;
        if samples < 4 then sample;
        else average;
        action average { @Timing { duration = 0.2 [ms]; } }
        then fork split;
        then store;
        then transmit;
        action store { @Timing { duration = 2 [ms]; } }
        action transmit { @Timing { duration = 40 [ms]; } }
        join both;
        first store then both;
        first transmit then both;
        first both then sleep;
        action sleep { @Timing { duration = 0.5 [ms]; } }
        then done;
    }
    ...
}
```

Then make every EnviroNode perform it. In `model/node-architecture.sysml`, import the behaviour
package and add the `perform` to `EnviroNode`:

<!-- check: project -->
```sysml
    private import NodeBehavior::*;

    part def EnviroNode {
        ...
        /* What a node does (NodeBehavior). */
        perform action measurementCycle : MeasurementCycle;
        ...
    }
```

### Step through it

Put the cursor in `MeasurementCycle` and run **SysML: Simulate State Machine or Action at Cursor**.
Click **Step** repeatedly:

1. the token moves from `start` to `wake` to `sample`;
2. at `enough`, `samples < 4` holds, so it goes back to `sample`;
3. after the fourth sample, `else` leads to `average`;
4. at the fork, two tokens appear: `store` and `transmit`;
5. at the join, they wait for each other and become one again;
6. `sleep`, then `done`.

**Values changed** shows `samples = 4`. Click **Run** to do it all at once, and **Show diagram** to
watch the tokens in the Action flow view.

### Its latency

Run **SysML: Verify Requirements** on `node-behavior.sysml` and open the **Software** tab. Its
**Latency (critical path)** section shows:

> **MeasurementCycle: 45.7 ms** — wake 1 ms → sample 4 ms → average 200 µs → transmit 40 ms → sleep 500 µs

The path goes through `transmit` (40 ms), not `store` (2 ms): the fork takes its slowest branch.
`sample` is counted once although it runs four times, because a loop's iterations aren't known to the
analysis. The real cycle takes 12 ms more (three more samples), which you can add to the budget
by hand, or model as four steps instead of a loop. Chapter 19 turns "a measurement is sent within
60 ms" into a requirement on `Latency`.

## Check yourself

1. Add a step `checkBattery` between `average` and the fork, with a duration of 1 ms. What is the new
   latency?
2. What happens in the simulation if you change the guard to `samples < 0`?
3. Why is `samples` an attribute of the action definition, rather than of the node?

<details><summary>Answers</summary>

1. Replace `then fork split;` after `average` with `then checkBattery;`, add `action checkBattery {
   @Timing { duration = 1 [ms]; } }` and `then fork split;` after it. The latency becomes 46.7 ms.
2. The first decision takes `else` immediately: one sample, then `average`. The loop is gone, and so is
   the 12 ms it hid from the latency.
3. It is the action's own working state: a counter that exists while the action runs. An attribute of
   the node would be state of the whole node.

</details>

Next: [14. States](14-states.md)
