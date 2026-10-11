# SysML v2 Textual Notation — Cheat Sheet (OMG SysML 2.0 formal, 2025)

Every ```sysml block below parses cleanly. Copy patterns from here, not from memory.
When this sheet doesn't cover something, read the matching official example (see `EXAMPLES_INDEX.md`).

## 0. Mental model (read first)

- SysML v2 is **text-first**. There are no blocks, value properties, stereotypes or diagrams in the text.
- Almost every concept comes as a **definition / usage pair**: `part def Engine` (the type) vs `part engine : Engine` (a use of it inside something).
  Same pattern for `attribute`, `item`, `port`, `connection`, `interface`, `flow`, `action`, `state`, `calc`, `constraint`, `requirement`, `use case`, `analysis`, `verification`, `allocation`, `enum`.
- Every statement ends with **either `;` or a `{ ... }` body** — never both, never neither.
- Relationship symbols (each has a keyword form):

| Symbol | Keyword | Used on | Meaning |
|---|---|---|---|
| `:` | `defined by` | usage | typed by a definition: `part eng : Engine;` |
| `:>` | `specializes` | definition | inherit from another def: `part def Car :> Vehicle;` |
| `:>` | `subsets` | usage | is a subset of another usage: `part engine :> carParts;` |
| `:>>` | `redefines` | usage | override an inherited usage: `attribute :>> mass = 1200 [kg];` |
| `::>` | `references` | end/usage | points at an existing feature: `source ::> supply.dcOut` |
| `~` | (conjugate) | port type | reverses in/out directions: `port p : ~FuelPort;` |
| `[n..m]` | | usage | multiplicity: `[1]`, `[0..1]`, `[2..*]`, `[*]` |

- `::` qualifies names (`ISQ::MassValue`, `ChargeMode::bulk`). `.` navigates features (`vehicle.engine.mass`).
- Names with spaces or leading digits use **single quotes**: `part def 'Fuel Station';`, `part '4cylEngine' : Engine;`

## 1. Packages, imports, comments

```sysml
package VehicleModel {
	doc /* Documentation attached to the owning element. */

	private import ScalarValues::*;      // Real, Integer, Boolean, String, Natural, Positive
	private import ISQ::*;               // quantity types: MassValue, PowerValue, ...
	private import SI::*;                // unit symbols: kg, m, s, V, A, W, ...
	public import ISQ::TorqueValue;      // single-element import

	comment about Engine /* A model comment about Engine. */
	// line comment: a note, NOT part of the model

	alias Motor for Engine;
	part def Engine;

	package Subsystems {
		part def Pump;
	}
}
```
- Imports end with `;`. Use `Pkg::*` for all members, `Pkg::Name` for one, `Pkg::**` for recursive.
- Nested packages are fine; reference across files with `private import OtherPackage::*;`.

## 2. Attributes, values, units, enums

```sysml
package AttrDemo {
	private import ScalarValues::*;
	private import ISQ::*;
	private import SI::*;

	attribute def Diameter :> LengthValue;

	enum def Color {
		enum red;
		enum green;
	}

	part def Wheel {
		attribute diameter : Diameter;
		attribute mass : MassValue = 12.5 [kg];          // bound (fixed) value
		attribute pressure : Real default 2.2;            // overridable default
		attribute paint : Color = Color::red;
		attribute count : Integer;
		attribute isSpare : Boolean;
		attribute label : String;
		attribute ratedVoltage : ElectricPotentialDifferenceValue = 12 [V];
		attribute current : ElectricCurrentValue;
		attribute p : PowerValue;
		attribute t : TimeValue = 5 [s];
	}
}
```
- Units go in square brackets after the number: `4.2 [V]`, `2 [A]`, `48 [h]`, `5 [SI::min]`.
- `=` binds a value; `default` gives an overridable initial value; `:=` is ONLY used inside `assign`.
- Useful ISQ types: `MassValue LengthValue TimeValue DurationValue SpeedValue AccelerationValue ForceValue TorqueValue PowerValue EnergyValue ElectricCurrentValue ElectricPotentialDifferenceValue ResistanceValue CapacitanceValue ElectricChargeValue FrequencyValue TemperatureValue`.
- Alternative: subset an ISQ quantity: `attribute mass :> ISQ::mass;`

## 3. Parts, items, references, specialization, redefinition

```sysml
package StructureDemo {
	private import ScalarValues::*;

	item def Fuel;
	item def Person;

	part def Engine {
		part cyl : Cylinder[4..6];
	}
	part def Cylinder;

	part def Vehicle {
		attribute mass : Real;
		part eng : Engine;                 // composite part (owned)
		ref part driver : Person;          // reference, not owned
		part wheels : Wheel[4];
		item fuel : Fuel;
	}
	part def Wheel;

	part def SmallEngine :> Engine {        // specialization of a def
		part redefines cyl[4];              // narrow multiplicity
	}

	part def SportsCar :> Vehicle {
		part sportEng : SmallEngine redefines eng;   // or:  part sportEng : SmallEngine :>> eng;
	}

	// Usage-level configuration (an instance-like usage of Vehicle)
	part myCar : Vehicle {
		attribute :>> mass = 1500.0;
		part :>> eng {
			part :>> cyl[6];
		}
	}

	abstract part def Machine;              // abstract definition
}
```
- Use `part def` for every type of physical/logical component. `item def` for things that flow or are stored (fuel, data, signals carried through items).
- `part x : T;` declares; `part :>> x { ... }` or `part redefines x { ... }` overrides an inherited one. Never re-declare an inherited feature with plain `part x : T;` — that creates a second feature.

## 4. Ports, interfaces, connections, binding, flows

```sysml
package InterfaceDemo {
	attribute def Temp;
	item def Fuel;

	port def FuelPort {
		attribute temperature : Temp;
		out item fuelSupply : Fuel;
		in item fuelReturn : Fuel;
	}

	interface def FuelInterface {
		end supplierPort : FuelPort;
		end consumerPort : ~FuelPort;
		flow supplierPort.fuelSupply to consumerPort.fuelSupply;
		flow consumerPort.fuelReturn to supplierPort.fuelReturn;
	}

	part def FuelTank { port fuelOut : FuelPort; }
	part def Engine { port fuelIn : ~FuelPort; }

	connection def Mount {
		end part a : FuelTank;
		end part b : Engine;
	}

	part vehicle {
		part tank : FuelTank;
		part eng : Engine;

		// typed interface between two ports
		interface : FuelInterface connect
			supplierPort ::> tank.fuelOut to
			consumerPort ::> eng.fuelIn;

		// untyped connection / typed connection
		connect tank to eng;
		connection mount : Mount connect a references tank to b references eng;

		// flow of an item between port features
		flow of Fuel from tank.fuelOut.fuelSupply to eng.fuelIn.fuelSupply;

		// binding: two features are always equal
		attribute t1 : Temp;
		bind t1 = tank.fuelOut.temperature;
	}
}
```
- Port directions live on the **features inside** the port def (`in item`, `out item`, `inout`). The mating side uses the conjugate `~FuelPort`.
- `connect A to B;` — always `to`, never `->` or `,`.
- `flow ... from X to Y;` (in a usage) or `flow X to Y;` (in an interface/connection def body).
- Electrical wiring (connectors, pins, wires, harnesses, pinouts): read `sysml-ref/WIRING.md` before writing.

## 5. Actions (activity-like behavior)

```sysml
package ActionDemo {
	private import ScalarValues::*;
	item def Scene;
	item def Image;
	item def Picture;

	action def Focus { in scene : Scene; out image : Image; }
	action def Shoot { in image : Image; out picture : Picture; }

	action def TakePicture {
		in item scene : Scene;
		out item picture : Picture;

		action focus : Focus {
			in item scene = TakePicture::scene;
			out item image;
		}
		flow from focus.image to shoot.image;        // data flow
		then action shoot : Shoot {                   // 'then' = sequence after previous
			in item image;
			out item picture = TakePicture::picture;
		}
	}

	action def MonitorBattery { out charge : Real; }
	action def AddCharge { in charge : Real; }

	// decision / merge loop
	action def ChargeBattery {
		first start;
		then merge continueCharging;
		then action monitor : MonitorBattery;
		then decide;
			if monitor.charge < 100 then addCharge;
			if monitor.charge >= 100 then endCharging;
		action addCharge : AddCharge { in charge = monitor.charge; }
		then continueCharging;
		action endCharging;
		then done;
	}

	// fork / join
	action def Brake {
		first start;
		then fork;
			then sensePedal;
			then senseTraction;
		action sensePedal;
		then joinNode;
		action senseTraction;
		then joinNode;
		join joinNode;
		then done;
	}

	// loop with until
	action def ChargeLoop {
		loop action charging {
			action monitor : MonitorBattery;
			then if monitor.charge < 100 {
				action addCharge : AddCharge { in charge = monitor.charge; }
			}
		} until charging.monitor.charge >= 100;
		then done;
	}

	// explicit succession and conditional succession
	action def Explicit {
		action a;
		action b;
		action c;
		first a then b;
		first b if true then c;
	}
}
```
- Control nodes: `start`, `done`, `merge name`, `decide`, `fork`, `join name`. Guards in decide: `if cond then target;`.
- Signals: `send new Sig() to target;` / `send new Sig() via port;` and `action trigger accept s : Sig via port;`.
- A part performs behavior with `perform action x : X;` or `perform someAction.subAction;`.

## 6. States

```sysml
package StateDemo {
	private import ISQ::*;
	private import SI::*;

	attribute def StartSignal;
	attribute def OnSignal;
	attribute def OffSignal;
	part def Vehicle { attribute maxTemp : TemperatureValue; attribute brakeOn : ScalarValues::Boolean; }
	part def Controller;
	attribute def ControllerStart;
	action senseTemp { out temp : TemperatureValue; }

	state def VehicleStates {
		in vehicle : Vehicle;
		in controller : Controller;

		entry; then off;                        // initial state  (also: first start then off;)

		state off;
		accept StartSignal                      // shorthand transition from the state just declared
			then starting;

		state starting;
		accept OnSignal
			if vehicle.brakeOn                  // guard
			do send new ControllerStart() to controller   // effect
			then on;

		state on {
			entry action selfTest;
			do action providePower;
			exit action applyBrake;
		}
		accept OffSignal then off;
		accept when senseTemp.temp > vehicle.maxTemp then off;   // change trigger
		accept after 48 [h] then off;                            // time trigger

		transition on_to_off                    // full named form
			first on
			accept OffSignal
			then off;
	}

	state def Modes parallel {                  // orthogonal regions
		state power;
		state health;
	}

	part car : Vehicle {
		part ctrl : Controller;
		exhibit state vs : VehicleStates {
			in vehicle = car;
			in controller = ctrl;
		}
	}
}
```
- Triggers: `accept Signal`, `accept s : Signal via port`, `accept at <time>`, `accept after <duration>`, `accept when <boolean expr>`.
- Order inside a transition: `first <source>` → `accept <trigger>` → `if <guard>` → `do <effect>` → `then <target>`.
- Inside a state body: `entry ...;` `do ...;` `exit ...;`. Assignments: `entry assign x := x + 1;`.
- NO v1/UML syntax: no `trigger [guard] / effect`, no `->` arrows, no `initial`/`final` keywords.

## 7. Calculations and constraints

```sysml
package CalcDemo {
	private import ISQ::*;
	private import SI::*;
	private import NumericalFunctions::*;

	calc def Power {
		in v : ElectricPotentialDifferenceValue;
		in i : ElectricCurrentValue;
		return : PowerValue = v * i;
	}

	constraint def MassLimit {
		in partMasses : MassValue[0..*];
		in limit : MassValue;
		sum(partMasses) <= limit                // last expression = the constraint (no ';')
	}

	part def Vehicle {
		attribute chassisMass : MassValue;
		attribute engineMass : MassValue;
		attribute p : PowerValue = Power(12 [V], 2 [A]);   // calc invocation

		assert constraint massOk : MassLimit {
			in partMasses = (chassisMass, engineMass);
			in limit = 2500 [kg];
		}
		assert constraint { chassisMass > 0 [kg] }       // inline constraint, no ';' inside braces
	}
}
```
- The boolean expression in a constraint body has **no trailing semicolon**.
- `constraint` = defines a condition; `assert constraint` = claims it holds.

## 8. Requirements, satisfy, verification, use cases

```sysml
package ReqDemo {
	private import ISQ::*;
	private import SI::*;

	part def Vehicle {
		attribute dryMass : MassValue;
		attribute fuelMass : MassValue;
	}

	requirement def <'REQ-1'> MassRequirement {
		doc /* The vehicle total mass shall not exceed the required mass. */
		subject vehicle : Vehicle;
		attribute massReqd : MassValue;
		assume constraint { vehicle.fuelMass >= 0 [kg] }
		require constraint { vehicle.dryMass + vehicle.fuelMass <= massReqd }
	}

	requirement <'REQ-1.1'> fullMassLimit : MassRequirement {
		attribute :>> massReqd = 2000 [kg];
	}

	requirement vehicleSpec {
		doc /* Requirement group. */
		subject vehicle : Vehicle;
		require fullMassLimit;
	}

	part car1 : Vehicle;
	satisfy vehicleSpec by car1;
	satisfy fullMassLimit by car1;

	verification def MassTest {
		private import VerificationCases::*;
		subject testVehicle : Vehicle;
		objective { verify fullMassLimit; }
		return verdict : VerdictKind;
	}

	part def Person;
	use case def 'Drive Vehicle' {
		subject vehicle : Vehicle;
		actor driver : Person;
		objective { doc /* Move the driver from A to B. */ }
	}
}
```
- Requirement IDs go in `<'...'>` right after `requirement def` / `requirement`.
- Requirement text goes in `doc /* ... */`; the formal part goes in `require constraint { ... }`.
- `satisfy <requirement> by <part usage>;` — usage, not definition.

## 9. Allocation, dependency, variability, metadata

```sysml
package MiscDemo {
	package Logical {
		action def GenerateTorque;
		part def TorqueGenerator;
		part torqueGenerator : TorqueGenerator;
	}
	package Physical {
		private import Logical::*;
		part def Engine;
		part engine : Engine;
		allocate torqueGenerator to engine;
		dependency from engine to torqueGenerator;
	}

	part def Transmission;
	part manual : Transmission;
	part automatic : Transmission;

	abstract part vehicleFamily {
		variation part transmission : Transmission {
			variant manual;
			variant automatic;
		}
	}
	part vehicleA :> vehicleFamily {
		part redefines transmission = transmission::manual;
	}

	metadata def SafetyCritical;
	part airbag { @SafetyCritical; }
}
```

## 10. Expression rules (common LLM errors)

- Boolean operators are words: `and` `or` `not` `xor` `implies`. **No `&&`, `||`, `!`.**
- Equality `==`, inequality `!=`. Comparison `< > <= >=`. Power `^` or `**`.
- Conditional: `if cond ? a else b`.
- Sequence literal: `(a, b, c)`. Index: `seq#(i)`. Collection ops: `sum(x)`, `size(x)`, `x->forAll { in i : T; ... }`.
- Strings use double quotes `"text"`; names use single quotes `'My Name'`.

## 11. v1 / hallucination → correct v2

| Wrong (do not write) | Correct SysML v2 |
|---|---|
| `block Engine { }` / `<<block>>` | `part def Engine { }` |
| `value mass : Real;` / `property` / `valueType` | `attribute mass : Real;` / `attribute def` |
| `part def Car : Vehicle;` | `part def Car :> Vehicle;` (`:` is only for typing usages) |
| `constraint block` / `parametric` | `constraint def` + `constraint`/`assert constraint` |
| `flowPort` / `proxy port` / `full port` | `port def` with `in`/`out item` features; `~` for the other side |
| `connector a -> b;` / `connect a, b;` | `connect a to b;` |
| `stateMachine` / `initial ->` / `[guard]/effect` | `state def`, `entry; then s;`, `accept X if g do e then s;` |
| `activity` / `controlFlow` / `objectFlow` | `action def`, `then`, `first a then b;`, `flow from a.x to b.y;` |
| `<<satisfy>>` / `satisfies` / `satisfiedBy` | `satisfy req by partUsage;` |
| `requirement Foo { text = "..."; id = 1; }` | `requirement def <'1'> Foo { doc /* ... */ }` |
| `import X.*;` / `import X::*` (no `;`) | `private import X::*;` |
| `&&` `\|\|` `!` | `and` `or` `not` |
| `x = 5` inside an action to change a value | `assign x := 5;` |
| `"Fuel Station"` as a name | `'Fuel Station'` |
| `value 4.2 V` / `4.2[volt]` | `4.2 [V]` (SI symbol) |
| `int`, `float`, `double`, `bool` | `Integer`, `Real`, `Boolean` (ScalarValues) |
