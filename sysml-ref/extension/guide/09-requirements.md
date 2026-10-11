# 9. Requirements

A requirement in a Word document is a sentence: "The node shall run at least three years on one
battery." Someone has to read the design, find the battery life, compare, and fill in a
compliance matrix by hand, again after every change. In SysML a requirement is a model element.
It has an ID, its text, **what it applies to** (its subject) and **the condition that must hold**
(a constraint). The extension can then verify it against the design continuously.

## Requirement definitions

<!-- check: standalone -->
```sysml
package Requirements {
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;

    part def Node {
        attribute life : DurationValue;
        attribute reportPeriod : DurationValue;
    }

    requirement def <'PWR-1'> NodeLifetime {
        doc /* The node shall run at least three years on one cell, reporting every 15 minutes or less often. */
        subject n : Node;
        assume constraint { n.reportPeriod >= 15 [min] }
        require constraint { n.life >= 3 [yr] }
    }
}
```

- The **short name** (`<'PWR-1'>`) is the requirement's ID.
- The **`doc`** is its text, the sentence a stakeholder signs off.
- The **subject** (`subject n : Node`) is what the requirement is about. Inside the requirement, `n`
  stands for whatever will satisfy it.
- **`require constraint`** is the condition the subject must meet. There can be several, and all
  must hold.
- **`assume constraint`** is a condition under which the requirement applies. Here: if the node
  reports more often than every 15 minutes, the three-year promise is off. When an assumption
  doesn't hold, the requirement is *not applicable* rather than failed.

A requirement definition is a kind of requirement, like a part definition is a kind of part. You
can reuse it for several subjects, specialize it, and give it attributes of its own.

## Requirement usages and `satisfy`

A **requirement usage** is a requirement of *this* system. **`satisfy`** says which element meets
it:

<!-- check: standalone -->
```sysml
package Satisfy {
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;

    part def Node { attribute life : DurationValue; }

    requirement def <'PWR-1'> NodeLifetime {
        subject n : Node;
        require constraint { n.life >= 3 [yr] }
    }

    part node : Node { :>> life = 3.28 [yr]; }

    requirement nodeLifetime : NodeLifetime;
    satisfy nodeLifetime by node;
}
```

`satisfy nodeLifetime by node` binds the requirement's subject to `node`: the extension evaluates
`n.life >= 3 [yr]` with `n` = `node` and reports whether it holds, and by how much.

### Margins

For a comparison like `life >= 3 [yr]`, the **margin** is how far inside the limit the actual value
is, relative to the limit: for the EnviroNode's 3.281 years, (3.281 − 3) / 3 = 9.4 %. A negative margin means the requirement is not
met, and by how much. Margins tell you which requirements are close to failing, which a pass/fail
matrix can't.

### Status

| Status | Meaning |
|---|---|
| **✓ pass** | Every required constraint holds. |
| **✗ fail** | At least one doesn't. |
| **? unknown** | Some value is missing, so it can't be evaluated. |
| **– not applicable** | An assumption doesn't hold. |
| **· unverified** | Nothing satisfies it yet (no `satisfy`). |

### Grouping requirements

Requirements can contain requirements, which gives you a specification's structure:

<!-- check: standalone -->
```sysml
package Groups {
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;

    part def Node {
        attribute life : DurationValue;
        attribute mass : MassValue;
    }

    requirement <'SYS'> nodeSpecification {
        subject n : Node;
        requirement <'PWR-1'> lifetime { subject :>> n; require constraint { n.life >= 3 [yr] } }
        requirement <'MEC-1'> mass { subject :>> n; require constraint { n.mass <= 0.2 [kg] } }
    }

    part node : Node { :>> life = 3.28 [yr]; :>> mass = 0.15 [kg]; }
    satisfy nodeSpecification by node;
}
```

Requirements can also trace to the concerns of stakeholders (`concern`, `stakeholder`); see the
standard's examples if your process needs that level of formality.

## In the tool

1. **Verdict hints.** After a `satisfy`, the editor shows `✓ 9.4 %` (met, with its margin) or
   `✗ -2.3 %` (not met). An `assert constraint` gets the same hint.
2. **Diagnostics.** A requirement that is not met is a `requirement-failed` warning:
   *Requirement PWR-1 nodeLifetime is not met by node: 2.93 yr >= 3 yr is false (margin -2.3 %).*
3. **The verification matrix.** Run **SysML: Verify Requirements** (the ✓ icon in the editor title).
   The **Simulation** panel's **Requirements** tab lists every requirement of the file: status, ID,
   name and text, subject, and margin.
   - Click **▸** to see each constraint checked, with its actual value and limit.
   - Click a requirement or a check to jump to it in the text.
   - **CSV** and **JSON** save the matrix for a report or a spreadsheet.
   - The panel follows your edits.
4. **Assertions and toleranced values** are listed below the matrix. Chapter 10 is about the latter.

![The verification matrix](images/node-requirements.png)

## The EnviroNode

Create `model/node-requirements.sysml` with the node's first three requirements:

<!-- check: project -->
```sysml
package NodeRequirements {
    doc /* What the EnviroNode must do, and which part of the design satisfies each requirement. */
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import NodeParts::*;
    private import NodeArchitecture::*;

    requirement def <'PWR-1'> NodeLifetime {
        doc /* The node shall run at least three years on one cell, reporting every 15 minutes or less often. */
        subject n : EnviroNode;
        assume constraint { n.reportPeriod >= 15 [min] }
        require constraint { n.life >= 3 [yr] }
    }

    requirement def <'ADC-1'> SenseRange {
        doc /* The battery-sense output shall stay below 2.3 V, inside the ADC's 2.5 V range with margin. */
        subject s : BatterySense;
        require constraint { s.vout <= 2.3 [V] }
    }

    requirement def <'PWR-3'> SenseCurrent {
        doc /* The battery-sense divider shall draw at most 25 µA. */
        subject s : BatterySense;
        require constraint { s.current <= 25 ['µA'] }
    }

    requirement nodeLifetime : NodeLifetime;
    requirement senseRange : SenseRange;
    requirement senseCurrent : SenseCurrent;

    satisfy nodeLifetime by node;
    satisfy senseRange by node.sense;
    satisfy senseCurrent by node.sense;
}
```

`satisfy senseRange by node.sense` uses a feature chain: the requirement applies to the `sense`
part of `node`.

Run **SysML: Verify Requirements** on this file:

| | ID | Requirement | Subject | Margin |
|---|---|---|---|---|
| ✓ | PWR-1 | nodeLifetime | node | 9.4 % |
| ✓ | ADC-1 | senseRange | sense | 13 % |
| ✓ | PWR-3 | senseCurrent | sense | 12 % |

The lifetime has 9.4 % margin: 3.28 years against 3. The divider output is 2.0 V against 2.3 V, and
its current 22 µA against 25 µA. The requirements live in their own file, but they are verified
against the design in `node-architecture.sysml` and `node-parts.sysml`: the extension follows the
references across files.

Now break something on purpose. In `NodeMcu`, raise the duty cycle from `0.01` to `0.012`. The
verdict on `satisfy nodeLifetime` turns to `✗ -2.3 %`, the panel shows the lifetime at 2.93 years,
and the Problems panel has the `requirement-failed` warning quoted above. Set it back.

## Check yourself

1. Write a requirement `<'PWR-2'> LedCurrent`: the LED shall be driven at no more than 5 mA. Satisfy
   it with `node.led`.
2. A requirement's assumption doesn't hold. What does the matrix show, and why is that better than
   "fail"?
3. What does the matrix show for a requirement usage without a `satisfy`?

<details><summary>Answers</summary>

1. In `node-requirements.sysml`:

   <!-- check: fragment -->
   ```sysml
   requirement def <'PWR-2'> LedCurrent {
       doc /* The status LED shall be driven at no more than 5 mA. */
       subject l : LED;
       require constraint { l.current <= 5 [mA] }
   }
   ```

   then `requirement ledCurrent : LedCurrent;` and `satisfy ledCurrent by node.led;`. It passes with
   60 % margin (2 mA against 5 mA).
2. *Not applicable* (–). The requirement doesn't claim anything under those conditions. Reporting a
   failure would be wrong: the design isn't broken, it's being used outside the requirement's
   scope.
3. *Unverified* (·): nothing claims to satisfy it yet. A matrix full of dots is a list of work to do.

</details>

Next: [10. Tolerances, worst case and Monte Carlo](10-tolerances.md)
