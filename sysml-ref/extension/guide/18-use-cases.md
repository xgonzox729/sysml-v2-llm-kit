# 18. Use cases

Requirements say *what* the system must achieve; **use cases** say *for whom* and *in what
situation*. A use case is an interaction between the system and the people or systems around it
(the **actors**) that delivers something of value: "a technician installs a node", "an operator reads
the latest data". Use cases are where requirements come from, and they make good acceptance tests.

## Use case definitions and usages

<!-- check: standalone -->
```sysml
package UseCases {
    part def Node;
    part def Technician;

    use case def InstallNode {
        doc /* A technician mounts a node and brings it on line. */
        subject node : Node;
        actor technician : Technician;
        objective { doc /* The first reading arrives within a minute. */ }
    }

    use case install : InstallNode {
        first start;
        then action mount;
        then action insertCell;
        then action joinNetwork;
        then done;
    }
}
```

- The **subject** is the system the use case is about, as for requirements.
- **Actors** are the parties outside the system that take part: people (technician, operator), or
  other systems (the gateway, a cloud service). They are parts, usually typed by a simple `part def`.
- The **objective** says what success means, as text or as a constraint.
- A use case is a kind of **action**: its body can have steps and successions, which describe the
  scenario.

### Including other use cases

A use case can include another as one of its steps:

<!-- check: fragment -->
```sysml
    part def Node;
    use case def ReadData { subject node : Node; }
    use case def ReplaceCell { subject node : Node; }
    use case replaceCell : ReplaceCell {
        first start;
        then action openEnclosure;
        then action swapCell;
        then include use case check : ReadData;     // the replacement ends with a successful reading
        then done;
    }
```

`include use case` is the SysML v2 version of UML's «include»: the included scenario is part of this
one.

### From use cases to requirements

Use cases are where requirements come from. Record the link with a dependency, so a change to the use
case can be traced to the requirements it affects:

<!-- check: project -->
```sysml
    /* The lifetime requirement comes from how often cells can be replaced. */
    dependency from replaceCell to NodeLifetime;
```

## In the tool

- **The General view** draws use cases as ovals and lists their subjects, actors and objectives in
  compartments. The composition edges from a use case definition to its actors' definitions show who
  takes part.
- **The Action flow view** of a use case shows its scenario.
- **The simulator** steps through a use case like any action (**SysML: Simulate State Machine or
  Action at Cursor**): included use cases run as steps, and `accept` steps wait for the event they
  name. Walking a scenario this way is a cheap review: does the order make sense, and is every step
  there?

![Use cases in the General view](images/node-usecases.png)

## The EnviroNode's use cases

Create `model/node-usecases.sysml`:

<!-- check: project -->
```sysml
package NodeUseCases {
    doc
    /*
     * What people do with an EnviroNode: use cases with their actors. They lead to requirements
     * (dependencies) and are carried out by actions, so they can be stepped through.
     */
    private import NodeArchitecture::*;
    private import NodeRequirements::*;
    private import NodeIcd::Reading;

    part def Technician;
    part def Operator;

    use case def InstallNode {
        doc /* A technician mounts a node and brings it on line. */
        subject node : EnviroNode;
        actor technician : Technician;
        objective { doc /* The first reading arrives within a minute. */ }
    }

    use case def ReadData {
        doc /* An operator looks at a node's latest readings. */
        subject node : EnviroNode;
        actor operator : Operator;
    }

    use case def ReplaceCell {
        doc /* A technician replaces a flat cell. */
        subject node : EnviroNode;
        actor technician : Technician;
    }

    use case install : InstallNode {
        first start;
        then action mount;
        then action insertCell;
        then action joinNetwork;
        then include use case firstReading : ReadData;
        then done;
    }

    use case readData : ReadData {
        first start;
        then action requestReading;
        then action waitForReading accept Reading;
        then action showReading;
        then done;
    }

    use case replaceCell : ReplaceCell {
        first start;
        then action openEnclosure;
        then action swapCell;
        then include use case reinstall : InstallNode;
        then done;
    }

    /* The lifetime requirement comes from how often cells can be replaced. */
    dependency from replaceCell to NodeLifetime;
}
```

`Reading` is the radio message (`NodeIcd::Reading`) you declared in chapter 6 and complete in chapter
20.

Now try it:
1. Open the General view of the file: three use case definitions as ovals with their actors, and the
   three use cases.
2. Simulate `install` (cursor in it, **SysML: Simulate State Machine or Action at Cursor**) and click
   **Run**. The log lists `mount`, `insertCell`, `joinNetwork` and the included `firstReading`, then
   the use case is done.
3. Simulate `readData` and click **Run**. It stops at `waitForReading`, and the events show
   **Reading**: the scenario waits for the node's message. Click **Reading**, then **Run** to finish.

## Check yourself

1. Add an actor `gateway` to `ReadData`: the gateway relays the reading. Which part definition does it
   need?
2. Write a use case `FirmwareUpdate` whose scenario includes `readData` as its last step, to confirm
   the node is back.
3. Why is `join` a bad name for a step? (Try `then action join;`.)

<details><summary>Answers</summary>

1. A `part def Gateway;` in the package (or reuse `NodeHarness::Gateway` from chapter 16), and `actor
   gateway : Gateway;` in `ReadData`.
2. <!-- check: fragment -->
   ```sysml
   part def Node;
   use case def ReadData2 { subject node : Node; }
   use case def FirmwareUpdate { subject node : Node; }
   use case firmwareUpdate : FirmwareUpdate {
       first start;
       then action transferImage;
       then action reboot;
       then include use case confirm : ReadData2;
       then done;
   }
   ```
3. `join` is a SysML keyword (the join node of an action flow), so `then action join;` is a syntax
   error: *Unexpected 'join'*. Keywords can't be names unless you quote them: `'join'`. That's why the
   EnviroNode's step is `joinNetwork`. Appendix [F](F-troubleshooting.md) lists the keywords that
   commonly trip people up.

</details>

Next: [19. Firmware architecture](19-firmware.md)
