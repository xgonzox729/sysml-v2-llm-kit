package RcFilterExample {
    doc /* A battery-sense RC divider simulated with SPICE: the circuit is generated from the
         * Electronics parts, the analysis measures the settled output and its rise time, and a
         * sweep shows how the output depends on R2. Open "Run Analyses". */
    private import SI::*;
    private import EngineeringUnits::*;
    private import ISQ::*;
    private import Electronics::*;
    private import Simulation::*;

    part def RcDivider {
        part src : VoltageSource { :>> waveform = "PULSE(0 3.3 0 1u 1u 5m 10m)"; }
        part r1 : Resistor { :>> resistance = 10 ['kΩ']; :>> powerRating = 63 [mW]; }
        part r2 : Resistor { :>> resistance = 10 ['kΩ']; :>> powerRating = 63 [mW]; }
        part c1 : Capacitor { :>> capacitance = 100 [nF]; :>> voltageRating = 10 [V]; }
        part gnd : Ground;
        connect src.p to r1.p;
        connect r1.n to r2.p;
        connect r1.n to c1.p;
        connect src.n to gnd.gnd;
        connect r2.n to gnd.gnd;
        connect c1.n to gnd.gnd;
    }
    part divider : RcDivider;

    analysis def StepResponse {
        subject circuit : RcDivider;
        @SpiceRun {
            command = "tran 10u 5m";
            measures = ("tran vout FIND v(r1.n) AT=4.9m",
                        "tran riseTime TRIG v(r1.n) VAL=0.165 RISE=1 TARG v(r1.n) VAL=1.485 RISE=1");
            probes = ("v(r1.p)", "v(r1.n)");
        }
        return vout : ElectricPotentialValue;
        out riseTime : DurationValue;
        objective {
            doc /* The ADC input settles to at least 1.6 V within 2 ms. */
            require constraint { vout >= 1.6 [V] and riseTime <= 2 [ms] }
        }
    }
    analysis step : StepResponse { subject :>> circuit = divider; }
    analysis stepVsR2 : StepResponse {
        subject :>> circuit = divider;
        @Sweep { parameter = divider.r2.resistance; start = 2 ['kΩ']; stop = 20 ['kΩ']; steps = 10; }
    }
}
