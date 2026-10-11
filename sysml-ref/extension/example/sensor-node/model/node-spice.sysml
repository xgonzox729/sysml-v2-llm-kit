package NodeSpice {
    doc
    /*
     * Circuit simulation of the battery-sense divider with SPICE: when the MCU switches the
     * cell onto the divider, how fast does the ADC input settle, and to what voltage?
     */
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Electronics::*;
    private import Simulation::*;
    private import NodeParts::*;

    /* A test bench: a 4.2 V step (a full cell switched on) into the divider. */
    part def SenseBench {
        part cell : VoltageSource { :>> waveform = "PULSE(0 4.2 0 1u 1u 50m 100m)"; }
        part sense : BatterySense;
        part gnd : Ground;
        connect cell.p to sense.top;
        connect cell.n to gnd.gnd;
        connect sense.bottom to gnd.gnd;
    }
    part senseBench : SenseBench;

    analysis def SenseSettling {
        subject bench : SenseBench;
        @SpiceRun {
            command = "tran 20u 40m";
            measures = ("tran vtap FIND v(sense.tap) AT=39m",
                        "tran settle TRIG v(sense.tap) VAL=0.2 RISE=1 TARG v(sense.tap) VAL=1.9 RISE=1");
            probes = ("v(sense.top)", "v(sense.tap)");
        }
        return vtap : ElectricPotentialValue;
        out settle : DurationValue;
        objective {
            doc /* The ADC input settles to its final value within 20 ms of switching the divider on. */
            require constraint { vtap <= 2.3 [V] and settle <= 20 [ms] }
        }
    }
    analysis settling : SenseSettling { subject :>> bench = senseBench; }
}
