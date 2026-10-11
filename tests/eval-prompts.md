# Quick evaluation set

Run each prompt in a fresh OpenCode session with the `sysml` agent, saving output to `tests/out/<model>/<n>.sysml`.
Score each file: **syntax** (0 = errors, 1 = no errors from the checker) and **content** (0–2: missing / partial / complete).
Use it to compare models (record the exact model id and settings with each run), and re-run after any change to
the prompt files, temperature, thinking mode, or quantization.

| Model id | Settings | Syntax (/10) | Content (/20) | Notes |
|---|---|---|---|---|
| | | | | |

1. **Structure** — "Create `Drone.sysml`: a quadcopter with a frame, 4 motor-propeller units, a flight controller, a 3S LiPo battery (11.1 V, 5000 mAh), and a power distribution board. Give each part mass in kg and model the battery's rated voltage and capacity with ISQ types."
2. **Ports & flows** — "In `Drone.sysml`, add DC power ports from the battery to the PDB and from the PDB to each motor ESC, with an interface def carrying power, and a flow of a `PWMCommand` item from the flight controller to each ESC."
3. **Actions** — "Model the drone takeoff procedure as an action def: arm motors, then run a self-test; if the test passes, spin up to hover throttle, otherwise disarm and stop. Use a decide node."
4. **States** — "Add a state def `FlightModes` with Disarmed, Armed, Hovering, Landing, Failsafe. Arm/disarm by signals, Failsafe on low battery (`when` trigger on battery voltage < 10.5 V) from any flying state, and Landing exits to Disarmed after 5 s."
5. **Requirements** — "Add requirements: REQ-1 total mass ≤ 1.5 kg; REQ-2 hover time ≥ 15 min (as an attribute on the drone); REQ-3 the battery voltage shall stay ≥ 10.5 V in flight. Group them, and satisfy them with a configured drone usage."
6. **Variants** — "Add a variation for the battery: 3S 5000 mAh or 4S 4000 mAh, and two drone configurations selecting each. Add a constraint that the 4S variant requires the high-KV-rated ESC variant."
7. **Repair** — paste a v1-flavored snippet (e.g. `block Motor { value kv : Real; }` with `connector a -> b;`) and ask: "Convert this to valid SysML v2."
8. **Wiring** — "Create `PowerHarness.sysml`: a 28 V power supply (10 A max) feeds a display that draws 3 A and accepts 22–32.2 V with at most 1 V drop, through harness W1 with a 4 m power wire and a 4 m ground return. Choose a wire gauge that passes the checks." (Content: uses the `Wiring` library per `sysml-ref/WIRING.md`, an installation `part`, and no `wiring-*` errors.)
9. **Verified requirement** — "Create `sensor-parts.sysml` and `sensor-requirements.sysml`: a sensor node powered by a 2400 mAh Li-ion cell through a 3.3 V LDO, with an MCU drawing 4 mA active, 1.5 µA asleep, 1 % duty cycle. Add requirement PWR-1: the node shall run at least 3 years, and verify it." (Content: uses `Electronics` parts per `sysml-ref/EXTENSION.md`, a typed subject, `require constraint`, `satisfy`, and reports the margin from `sysml_verify` — not a made-up number.)
10. **Documents** — on the result of prompt 9: "Generate the system documents and tell me what is missing for a design review." (Content: runs `/sysml-docs` or the same steps, writes the five files to `docs/model/`, and lists real gaps such as missing `doc` or traceability without inventing text.)

Tip: `node tools/sysml-check.mjs tests/out/<model>` scores syntax for one model's whole set at once (keep prompt 2–6 follow-ups in the same `Drone.sysml` or the same folder so imports resolve), and `node tools/sysml.mjs verify tests/out/<model>` shows the requirement results for prompts 5 and 9. Without the extension, `sysml-validate tests/out/<model> --format compact` works for prompts 1–7.
