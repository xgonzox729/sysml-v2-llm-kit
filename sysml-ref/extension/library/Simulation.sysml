standard library package Simulation {
    doc
    /*
     * Annotations for the extension's analyses, for what standard SysML has no construct of its
     * own. Everything else the analyses use is plain SysML: attributes and their values,
     * calculations, constraints, requirements with `satisfy`, analysis cases, states, actions.
     *
     * Usage:
     *   private import Simulation::*;
     *   attribute r1 : ResistanceValue = 10 ['kΩ'] { @Tolerance { relative = 0.01; } }      // ±1 %
     *   attribute vin : ElectricPotentialValue = 3.0 [V] { @Tolerance { minimum = 2.0 [V]; maximum = 3.6 [V]; } }
     *
     * Licensed under the MIT license (part of the SysML v2 VS Code extension).
     */

    private import Base::Anything;
    private import ScalarValues::*;
    private import Quantities::*;

    enum def Distribution {
        doc /* How a toleranced value is sampled in a Monte Carlo analysis. */
        /* Any value between the limits is equally likely. */
        uniform;
        /* Normal around the nominal value, with the limits at ±3 standard deviations. */
        normal;
    }

    metadata def Tolerance {
        doc
        /*
         * The range a value can take: a relative tolerance (0.05 = ±5 % of the nominal value), an
         * absolute one (±0.1 V), or explicit limits. The attribute's own value is the nominal
         * value. Worst-case and Monte Carlo analyses vary every toleranced value in the model.
         */
        attribute relative : Real[0..1];
        attribute absolute : ScalarQuantityValue[0..1];
        /* Explicit limits. (Named minimum/maximum rather than min/max, which read as SI's minute outside a metadata body.) */
        attribute minimum : ScalarQuantityValue[0..1];
        attribute maximum : ScalarQuantityValue[0..1];
        attribute distribution : Distribution[0..1] default Distribution::uniform;
    }

    enum def SweepScale {
        linear;
        logarithmic;
    }

    metadata def Sweep {
        doc
        /*
         * Runs the annotated analysis case for a range of values of one attribute and charts its
         * result and whether its objective holds:
         *     analysis lifeVsDuty : NodeLifeAnalysis {
         *         @Sweep { parameter = node.mcu.dutyCycle; start = 0.001; stop = 0.1; steps = 25; scale = SweepScale::logarithmic; }
         *     }
         * Either `start`, `stop` and `steps`, or a list of `values`. Two sweeps on one analysis
         * give a family of curves (the second parameter selects the curve).
         */
        ref parameter : Anything;
        attribute start[0..1];
        attribute stop[0..1];
        attribute steps : Natural[0..1] default 11;
        attribute values[0..*];
        attribute scale : SweepScale[0..1] default SweepScale::linear;
    }

    enum def SpiceEngineKind {
        /* Native ngspice if installed, else the bundled one. */
        auto;
        ngspice;
        ltspice;
    }

    metadata def SpiceRun {
        doc
        /*
         * Runs the annotated analysis case as a SPICE simulation:
         * - the circuit: generated from the case's subject (Electronics parts connected through
         *   their terminals, with a Ground), or a `netlist` file, or an LTspice `schematic`
         *   (needs LTspice); file paths are relative to the model file;
         * - the case's `in` parameters become `.param` values;
         * - `command` is the SPICE analysis ("tran 10u 5m", "ac dec 20 10 1meg", "op"; not
         *   `analysis`, which is a SysML keyword);
         * - `measures` are `.meas` statements; `v(part.terminal)` names a terminal's node;
         * - each measurement's value goes to the case's `return` or `out` parameter of the
         *   same name, in the unit of its type (SI), and the objective is checked on it.
         * `probes` lists the vectors to chart (default: the node voltages).
         */
        attribute command : String[0..1];
        attribute measures : String[0..*];
        attribute netlist : String[0..1];
        attribute schematic : String[0..1];
        attribute directives : String[0..*];
        attribute probes : String[0..*];
        attribute engine : SpiceEngineKind[0..1] default SpiceEngineKind::auto;
    }

    metadata def Simulate {
        doc
        /*
         * Runs the annotated state machine (or the state machines of the annotated part) over
         * simulated time:
         *     exhibit state modes {
         *         @Simulate { duration = 7 [d]; step = 1 [min]; events = ("Wake every 15 [min]"); stopWhen = charge <= 0 [mAh]; }
         *         ...
         *     }
         * - `events`: scheduled events, "Name at 10 [s]" or "Name every 15 [min]" (optionally
         *   "from 5 [s]"); `after` timers of the active states fire on their own;
         * - `@Rate` values are integrated between events (fixed step, Runge–Kutta);
         * - `record`: further attributes to chart (rate attributes are always recorded);
         * - `stopWhen`: a condition that ends the run (e.g. the battery is empty).
         */
        attribute duration : ScalarQuantityValue;
        attribute step : ScalarQuantityValue[0..1];
        attribute events : String[0..*];
        ref record : Anything[0..*];
        attribute stopWhen : Boolean[0..1];
    }

    metadata def Rate {
        doc
        /*
         * The rate of change of an attribute, integrated by the time simulation: while the
         * annotated state is active (on a state), or always (elsewhere).
         *     part node {
         *         attribute charge : ElectricChargeValue = 2400 [mAh];
         *         attribute current : ElectricCurrentValue = 0 [A];
         *         @Rate { rateOf = charge; rate = -current; }
         *     }
         */
        ref rateOf : Anything;
        attribute rate;
    }
}
