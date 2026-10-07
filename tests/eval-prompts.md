# Quick evaluation set

Run each prompt in a fresh OpenCode session with the `sysml` agent, saving output to `tests/out/<n>.sysml`.
Score each file: **syntax** (0 = doesn't parse, 1 = parses) and **content** (0–2: missing / partial / complete).
Re-run after any change to the prompt files, temperature, thinking mode, or quantization, and compare totals.

1. **Structure** — "Create `Drone.sysml`: a quadcopter with a frame, 4 motor-propeller units, a flight controller, a 3S LiPo battery (11.1 V, 5000 mAh), and a power distribution board. Give each part mass in kg and model the battery's rated voltage and capacity with ISQ types."
2. **Ports & flows** — "In `Drone.sysml`, add DC power ports from the battery to the PDB and from the PDB to each motor ESC, with an interface def carrying power, and a flow of a `PWMCommand` item from the flight controller to each ESC."
3. **Actions** — "Model the drone takeoff procedure as an action def: arm motors, then run a self-test; if the test passes, spin up to hover throttle, otherwise disarm and stop. Use a decide node."
4. **States** — "Add a state def `FlightModes` with Disarmed, Armed, Hovering, Landing, Failsafe. Arm/disarm by signals, Failsafe on low battery (`when` trigger on battery voltage < 10.5 V) from any flying state, and Landing exits to Disarmed after 5 s."
5. **Requirements** — "Add requirements: REQ-1 total mass ≤ 1.5 kg; REQ-2 hover time ≥ 15 min (as an attribute on the drone); REQ-3 the battery voltage shall stay ≥ 10.5 V in flight. Group them, and satisfy them with a configured drone usage."
6. **Variants** — "Add a variation for the battery: 3S 5000 mAh or 4S 4000 mAh, and two drone configurations selecting each. Add a constraint that the 4S variant requires the high-KV-rated ESC variant."
7. **Repair** — paste a v1-flavored snippet (e.g. `block Motor { value kv : Real; }` with `connector a -> b;`) and ask: "Convert this to valid SysML v2."

Tip: if a validator is installed, `sysml-validate tests/out --format compact` scores syntax for the whole set at once.
