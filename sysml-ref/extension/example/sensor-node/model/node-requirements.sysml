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
