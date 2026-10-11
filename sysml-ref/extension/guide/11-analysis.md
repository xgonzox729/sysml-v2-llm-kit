# 11. Analysis cases and trade studies

Requirements ask "is it good enough?". Engineering also asks "how good is it?", "what does it depend
on?" and "which option is best?". SysML answers those with **analysis cases** and **trade
studies**. The extension runs them, sweeps their parameters and charts the results.

## Analysis cases

An **analysis definition** (`analysis def`) is a question about a subject: what it is analysing (the
**subject**), what it computes (the **result**, `return`), and optionally what result would be
acceptable (the **objective**, a requirement on the result).

<!-- check: standalone -->
```sysml
package Analyses {
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;

    part def Node {
        attribute capacity : ElectricChargeValue;
        attribute averageCurrent : ElectricCurrentValue;
    }

    analysis def LifetimeAnalysis {
        subject n : Node;
        objective { require constraint { lifetime >= 3 [yr] } }
        return lifetime : DurationValue = n.capacity / n.averageCurrent;
    }

    part node : Node { :>> capacity = 1920 [mAh]; :>> averageCurrent = 66.76 ['µA']; }

    analysis lifetime : LifetimeAnalysis { subject :>> n = node; }
}
```

An **analysis usage** (`analysis lifetime : LifetimeAnalysis`) runs the analysis for one subject.
`subject :>> n = node` binds the subject. The result is computed in the subject's context, and the
objective is checked against it.

How is that different from an attribute and a requirement? Conceptually, not much: an analysis
packages a question, its answer and its acceptance criterion as one reusable thing. In practice,
analysis cases are what you **sweep** and what **trade studies** evaluate, and they can call
external solvers such as SPICE (chapter 12).

## Sweeps

`@Sweep` (from the `Simulation` library) runs an analysis for a range of values of one attribute and
charts the result:

<!-- check: fragment -->
```sysml
    part def Load { attribute dutyCycle : Real = 0.01; attribute current : ElectricCurrentValue = 4 [mA] * dutyCycle; }
    part load : Load;
    analysis def CurrentAnalysis {
        subject l : Load;
        return current : ElectricCurrentValue = l.current;
    }
    analysis currentVsDuty : CurrentAnalysis {
        subject :>> l = load;
        @Sweep { parameter = load.dutyCycle; start = 0.001; stop = 0.1; steps = 25; scale = SweepScale::logarithmic; }
    }
```

| `@Sweep` attribute | Meaning |
|---|---|
| `parameter` | the attribute to vary (a feature chain from the analysis's context) |
| `start`, `stop`, `steps` | the range, with units if the parameter has them |
| `scale` | `SweepScale::linear` (default) or `SweepScale::logarithmic` |
| `values` | instead of a range, a list: `values = (1 [mA], 2 [mA], 5 [mA]);` |

Two `@Sweep`s on one analysis give a **family of curves**: the first parameter is the x axis, and
each value of the second is one curve.

## Trade studies

A **trade study** compares alternatives against an objective and picks the best. The SysML standard
library defines it (`TradeStudies::TradeStudy`), and you specialize it:

- the **subject** is the list of alternatives;
- the **objective** is `MaximizeObjective` or `MinimizeObjective`;
- the **evaluation function** (`evaluationFunction`) scores one alternative.

The EnviroNode's cell trade below is an example.

## In the tool

1. **Hints.** After an analysis usage the editor shows its result and verdict:
   `⇒ 3.28 yr ✓ 9.4 %`. After a trade study it shows the winner: `⇒ aaLithium`.
2. **The Analyses tab.** Run **SysML: Run Analyses** (editor context menu), or open the Simulation
   panel and select **Analyses**. Each analysis shows:
   - its **result** and its **objective**, with status and margin;
   - for a **sweep**, a chart of the result against the parameter. Filled points meet the
     objective, hollow points don't; hover a point for its values.
   - for a **trade study**, a table of the alternatives with their scores, the selected one marked.
3. **Export.** The toolbar's **JSON** button saves all results, sweeps included. From the command
   line, `sysml-sim analyze model/ --format csv` writes every sweep point as a CSV row (chapter 21).

![A sweep in the Analyses tab](images/node-sweep.png)

## The EnviroNode

Create `model/node-analysis.sysml` with three analyses: the lifetime, the lifetime against the MCU's
duty cycle, and a trade study of cells:

<!-- check: project -->
```sysml
package NodeAnalysis {
    doc /* Questions about the design, answered by calculation: how long it lasts, what that depends on, which cell to use. */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Simulation::*;
    private import TradeStudies::*;
    private import NodeArchitecture::*;

    analysis def LifetimeAnalysis {
        doc /* How long the node runs on one cell. */
        subject n : EnviroNode;
        objective { require constraint { lifetime >= 3 [yr] } }
        return lifetime : DurationValue = n.life;
    }

    analysis lifetime : LifetimeAnalysis { subject :>> n = node; }

    analysis lifetimeVsDutyCycle : LifetimeAnalysis {
        doc /* How the lifetime depends on how much of the time the MCU is awake. */
        subject :>> n = node;
        @Sweep { parameter = node.mcu.dutyCycle; start = 0.001; stop = 0.05; steps = 15; scale = SweepScale::logarithmic; }
    }
    ...
}
```

Run **SysML: Run Analyses**:

- **lifetime:** 3.28 years, objective met with 9.4 % margin. This is the same number as PWR-1: the
  analysis is a reusable form of the same question.
- **lifetimeVsDutyCycle:** fifteen points from 0.1 % to 5 % duty cycle. At 0.1 % the node lasts 7.1
  years, at 5 % less than one. The curve crosses three years at about 1.15 %. That is your real
  budget for the MCU's awake time, and the reason the 1 % assumption of chapter 5 matters.

The sweep changes `dutyCycle` where it is defined, in `NodeMcu`, and the whole power tree follows:
average current, rail loads, battery current, life. That is the benefit of one model: you don't
re-enter anything to ask a new question.

### The cell trade study

Which cell gives the most charge for the money? Add to `model/node-analysis.sysml`:

<!-- check: project -->
```sysml
    /* Which cell: the most charge for the money. */
    part def CellOption {
        attribute capacity : ElectricChargeValue;
        attribute cost : Real;
    }
    part aaLithium : CellOption { :>> capacity = 3000 [mAh]; :>> cost = 2.5; }
    part liIon18650 : CellOption { :>> capacity = 2400 [mAh]; :>> cost = 4.0; }
    part cr123a : CellOption { :>> capacity = 1500 [mAh]; :>> cost = 3.0; }

    analysis cellTrade : TradeStudy {
        subject options : CellOption[1..*] = (aaLithium, liIon18650, cr123a);
        objective : MaximizeObjective;
        calc :>> evaluationFunction {
            in part option :>> alternative : CellOption;
            return :>> result : Real = option.capacity / 1 [mAh] / option.cost;
        }
    }
```

- `subject options : CellOption[1..*] = (aaLithium, liIon18650, cr123a)` lists the alternatives.
- `calc :>> evaluationFunction` redefines the trade study's scoring calculation: milliamp-hours per
  unit of cost.
- `objective : MaximizeObjective` picks the highest score.

The Analyses tab shows the scores: **aaLithium 1200**, liIon18650 600, cr123a 500. The AA lithium
cell wins on charge per cost, but it is not rechargeable. A trade study answers exactly the question
you ask it; use several criteria (or a weighted score) when one isn't enough. Chapter 17 keeps both
cells as variants of the product.

## Check yourself

1. Add a second `@Sweep` on `lifetimeVsDutyCycle`, over the radio's duty cycle with `values =
   (0.001, 0.002, 0.005)`. What do you get?
2. Change the trade study to minimize cost per mAh. Which cell wins, and why is the result the same?
3. Why does the sweep's parameter say `NodeMcu.dutyCycle` in the panel, although the sweep is
   written as `node.mcu.dutyCycle`?

<details><summary>Answers</summary>

1. A family of three curves, one per radio duty cycle. Each is the lifetime against the MCU's duty
   cycle; the higher the radio's duty cycle, the lower the curve.
2. `objective : MinimizeObjective;` with `return :>> result : Real = option.cost / (option.capacity
   / 1 [mAh]);`. The AA lithium again: minimizing cost per charge is the same ordering as maximizing
   charge per cost.
3. `node.mcu` doesn't give the duty cycle a value of its own; it inherits it from `NodeMcu`, where
   `:>> dutyCycle = 0.01` is declared. The sweep varies the value where it is declared.

</details>

Next: [12. Circuit simulation with SPICE](12-spice.md)
