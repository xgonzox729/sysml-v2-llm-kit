# E. Glossary: SysML for electronics engineers

| SysML term | What it is | Electronics analogy |
|---|---|---|
| **Model** | The structured description of a system that documents, diagrams and analyses are views of | The design database behind a schematic, a BOM and a netlist |
| **Package** | A named container of elements | A folder; a schematic sheet or library |
| **Element** | Anything in a model | — |
| **Definition** (`… def`) | A kind of thing: its features and values | A datasheet; a library symbol |
| **Usage** | A use of a definition in a context | A reference designator (U3) on a schematic |
| **Part** | A piece of the system, physical or logical | A component or module |
| **Attribute** | A value describing something: a voltage, a part number | A parameter on a symbol |
| **Quantity / unit** | A value with a dimension, written `3.3 [V]` | A value with its unit, checked |
| **Item** | Something that flows or is exchanged: a signal, a message, energy | What travels on a net or a bus |
| **Port** | A connection point on a part's boundary | A connector, a pin group, a bus interface |
| **Conjugated port** (`~P`) | The same port with every direction reversed | The mating half: plug vs socket, master vs slave |
| **Connection** (`connect`) | A link between two features (usually ports) | A wire or a net |
| **Interface** | A connection with a definition of its ends | A defined bus or cable type |
| **Binding** (`bind`) | Two features that are always equal | A net label joining two names |
| **Flow** | Items actually travelling from one feature to another | The signal or current on a net |
| **Specialization** (`:>` on definitions) | "Is a kind of": inherits everything | A part family: TPS7A0233 is a TPS7A02 |
| **Redefinition** (`:>>`) | Giving an inherited feature a value, type or multiplicity | Filling in the variant-specific values of a datasheet |
| **Subsetting** (`:>` on usages) | "Is one of" | Decoupling caps are some of the capacitors |
| **Multiplicity** (`[4]`, `[0..*]`) | How many | Quantity in the BOM |
| **Calculation** (`calc`) | A reusable formula | A design equation |
| **Constraint** | A condition on values | A design rule |
| **Assertion** (`assert constraint`) | A condition that must hold | A DRC rule that must pass |
| **Requirement** | A required condition, with an ID, text and subject | A specification line item |
| **Subject** | What a requirement or analysis is about | The device under test |
| **Satisfy** | Says which element meets a requirement | A compliance matrix entry |
| **Margin** | How far inside its limit a value is | Design margin, headroom |
| **Tolerance** (`@Tolerance`) | How far a value can stray from nominal | ±1 % on a resistor |
| **Worst case** | The combination of tolerances giving the lowest margin | Worst-case circuit analysis |
| **Monte Carlo / yield** | Random sampling of tolerances; the share that passes | Production yield |
| **Analysis case** | A question about a subject: result and objective | A design calculation with its acceptance criterion |
| **Sweep** (`@Sweep`) | An analysis over a range of a parameter | A parametric sweep (`.step`) |
| **Trade study** | Comparing alternatives against an objective | Component selection |
| **Action** | A step of behaviour; an action flow is a procedure | A flowchart; a firmware routine |
| **Succession** (`then`) | "After this, that" | Sequence in a flowchart |
| **Fork / join** | Start / wait for concurrent steps | Parallel processes |
| **State machine** | Modes and the events that switch between them | Operating modes; a firmware FSM |
| **Transition** | A change of state on a trigger, under a guard, with an effect | An edge in a state diagram |
| **Trigger** (`accept`) | What fires a transition: a signal, a time, a change | An interrupt, a timeout, a threshold |
| **Guard** (`if`) | A condition a transition also needs | An enable condition |
| **Exhibit / perform** | A part behaves as a state machine / carries out an action | — |
| **Allocation** (`allocate`) | Which part carries out (or holds) which function or element | Mapping functions to ICs; firmware to an MCU |
| **Variation / variant** | A choice point and its options | Assembly variants, DNP options |
| **Configuration** | A part that chooses a variant for every variation point | A build variant / SKU |
| **Use case** | An interaction with actors that delivers value | A user scenario |
| **Actor** | A party outside the system that takes part | The user, an external system |
| **View / viewpoint** | What part of the model to show, for whom | A drawing set for a review |
| **Metadata** (`@X { … }`) | An annotation that tools understand | Symbol attributes for tools |
| **Qualified name** | `Pkg::Def::feature`: an element's full name | A hierarchical net or reference name |
| **Short name** (`<'ID'>`) | An alternative identifier | A part number or requirement ID |
| **KerML** | The kernel language SysML is defined in | — |

Next: [F. Troubleshooting](F-troubleshooting.md)
