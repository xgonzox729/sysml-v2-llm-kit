# A. Syntax cheat sheet

The SysML v2 textual notation at a glance, with the chapter that explains each construct. Every
definition keyword `X def` has a matching usage keyword `X`.

## Organization

| Construct | Syntax | Ch. |
|---|---|---|
| Package | `package Name { … }` | 2 |
| Import (one, all, recursive) | `private import Pkg::Name;` · `private import Pkg::*;` · `private import Pkg::**;` | 2 |
| Alias | `alias Volt for SI::V;` | 2 |
| Short name (ID) | `requirement def <'PWR-1'> NodeLifetime;` | 2 |
| Quoted name | `part '3V3 rail';` | 2 |
| Note (ignored) | `// text` | 2 |
| Documentation | `doc /* text */` | 2 |
| Comment | `/* text */` · `comment about X /* text */` | 2 |

## Structure

| Construct | Syntax | Ch. |
|---|---|---|
| Part definition / usage | `part def Mcu;` · `part mcu : Mcu;` | 3 |
| Multiplicity | `part caps : Capacitor[4];` · `[0..1]` · `[1..*]` | 3 |
| Reference | `ref part host : Computer;` | 3 |
| Specialization | `part def Ldo :> Regulator;` | 4 |
| Abstract | `abstract part def Regulator;` | 4 |
| Redefinition | `:>> outputVoltage = 3.3 [V];` · `attribute redefines x = 1;` | 4 |
| Subsetting | `part decoupling : Capacitor[4] :> capacitors;` | 4 |
| Attribute | `attribute supply : ElectricPotentialValue = 3.3 [V];` | 5 |
| Default value | `attribute x : Real default 1.0;` | 5 |
| Enumeration | `enum def Package { SOT23; QFN16; }` · `Package::SOT23` | 5 |
| Item | `item def Reading;` · `item reading : Reading;` | 6 |
| Port definition / usage | `port def Bus { out item r : Reading; }` · `port bus : Bus;` | 6 |
| Conjugated port | `port bus : ~Bus;` | 6 |
| Connection | `connect a.p to b.q;` · `connection c : Cable connect a.p to b.q;` | 6 |
| Interface | `interface def Link { end x : Bus; end y : ~Bus; }` · `interface l : Link connect x ::> a.p to y ::> b.q;` | 6 |
| Binding | `bind a.x = b.y;` | 6 |
| Flow | `flow of Reading from a.p.r to b.q.r;` | 6 |
| Allocation | `allocate measure to mcu;` | 17 |
| Variation / variant | `variation part def Radio { variant part ble : Ble; }` · `part :>> radio = radio::ble;` | 17 |

## Calculations, constraints, requirements

| Construct | Syntax | Ch. |
|---|---|---|
| Calculation | `calc def F { in x : Real; return : Real = x * 2; }` · `F(3)` · `F(x = 3)` | 8 |
| Constraint | `constraint def C { in x : Real; x > 0 }` · `constraint c : C { in x = 1; }` | 8 |
| Assertion | `assert constraint { a <= b }` | 8 |
| Requirement | `requirement def <'ID'> R { doc /* … */ subject s : S; require constraint { … } }` | 9 |
| Assumption | `assume constraint { … }` | 9 |
| Satisfaction | `satisfy r by node;` | 9 |
| Analysis | `analysis def A { subject s : S; objective { … } return r : T = …; }` | 11 |
| Trade study | `analysis t : TradeStudy { subject … ; objective : MaximizeObjective; calc :>> evaluationFunction { … } }` | 11 |

## Behaviour

| Construct | Syntax | Ch. |
|---|---|---|
| Action | `action def A { first start; then action b; then done; }` | 13 |
| Succession | `then x;` · `first a then b;` | 13 |
| Decision | `then decide d; if c then x; else y;` | 13 |
| Fork / join / merge | `then fork f; then a; then b;` · `join j; first a then j;` · `merge m;` | 13 |
| Assignment | `assign x := x + 1;` | 13 |
| Send / accept | `send Reading() via port;` · `send Ack() to mcu;` · `accept r : Reading;` | 13, 19 |
| Perform | `perform action cycle : Cycle;` | 13 |
| State | `state def S { entry; then a; state a; state b; }` | 14 |
| Transition | `transition t first a accept E if g do e then b;` | 14 |
| Time and change triggers | `accept after 50 [ms]` · `accept when x > 10` | 14 |
| State actions | `entry action …;` · `do action …;` · `exit action …;` | 14 |
| Parallel state | `state running parallel { state r1 { … } state r2 { … } }` | 14 |
| Exhibit | `exhibit state modes : Modes;` | 14 |
| Use case | `use case def U { subject s : S; actor a : A; objective { … } }` · `include use case x : U;` | 18 |

## Expressions

| | |
|---|---|
| Arithmetic | `+ - * / **` |
| Comparison | `< <= == != >= >` |
| Logic | `and or not xor implies` |
| Conditional | `if c ? a else b` · `x ?? fallback` |
| Feature chain | `node.battery.capacity` |
| Units | `3.3 [V]` · `1.5 ['µA']` · `100 ['kΩ']` · `(x) [mm]` (conversion) |
| Sequences | `(a, b, c)` · `sum(xs)` · `size(xs)` · `xs->collect { in x; x * 2 }` |

## Metadata (this extension's libraries)

| Annotation | On | Ch. |
|---|---|---|
| `@Tolerance { relative = 0.01; }` | an attribute | 10 |
| `@Sweep { parameter = …; start = …; stop = …; steps = …; }` | an analysis | 11 |
| `@SpiceRun { command = "…"; measures = (…); }` | an analysis | 12 |
| `@Timing { duration = 4 [ms]; }` | an action | 13 |
| `@Simulate { duration = 7 [d]; events = (…); }` · `@Rate { rateOf = x; rate = …; }` | a state machine | 15 |
| `@Encoding { bits = 16; scale = 1 [mV]; }` | an attribute or definition | 20 |
| `@Config { name = "…"; scale = 1 [s]; }` | an attribute | 17 |
| `@Implements { file = "…"; }` · `@VerifiedBy { file = "…"; test = "…"; }` | any element | 20 |

## Everything at once

<!-- check: standalone -->
```sysml
package CheatSheet {
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;

    doc /* A tiny model that uses most of the constructs above. */

    enum def Mode { sleep; active; }
    item def Reading;
    item def Wake;

    port def SensorBus { out item reading : Reading; }

    abstract part def Device {
        attribute current : ElectricCurrentValue;
    }

    part def Sensor :> Device {
        port bus : SensorBus;
        :>> current = 135 ['µA'];
    }

    part def Logger :> Device {
        port bus : ~SensorBus;
        :>> current = 4 [mA];
        exhibit state modes : Modes;
    }

    interface def SensorLink {
        end sensorSide : SensorBus;
        end loggerSide : ~SensorBus;
    }

    calc def Total {
        in a : ElectricCurrentValue;
        in b : ElectricCurrentValue;
        return : ElectricCurrentValue = a + b;
    }

    action def Measure {
        first start;
        then action read;
        then action store;
        then done;
    }

    state def Modes {
        entry; then sleeping;
        state sleeping;
        state measuring;
        transition first sleeping accept Wake then measuring;
        transition first measuring accept after 10 [ms] then sleeping;
    }

    part def System {
        attribute total : ElectricCurrentValue;
    }

    part system : System {
        part sensor : Sensor;
        part logger : Logger;
        interface link : SensorLink connect sensorSide ::> sensor.bus to loggerSide ::> logger.bus;
        perform action measure : Measure;
        allocate measure to logger;
        :>> total = Total(sensor.current, logger.current);
        assert constraint { total < 10 [mA] }
    }

    requirement def <'R-1'> LowPower {
        doc /* The system shall draw less than 5 mA. */
        subject s : System;
        require constraint { s.total < 5 [mA] }
    }
    requirement lowPower : LowPower;
    satisfy lowPower by system;
}
```

Next: [B. A tour of the standard library](B-standard-library.md)
