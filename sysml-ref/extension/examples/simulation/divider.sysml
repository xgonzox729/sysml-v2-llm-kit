package DividerExample {
    doc /* A resistor divider that scales a battery voltage for an ADC input: requirements,
         * tolerances, an assertion and a value to solve for. Open "Verify Requirements". */
    private import SI::*;
    private import EngineeringUnits::*;
    private import ISQ::*;
    private import Simulation::*;

    part def Divider {
        attribute vin : ElectricPotentialValue = 4.2 [V] { @Tolerance { minimum = 3.0 [V]; maximum = 4.2 [V]; } }
        attribute r1 : ResistanceValue = 100 ['kΩ'] { @Tolerance { relative = 0.01; } }
        attribute r2 : ResistanceValue = 120 ['kΩ'] { @Tolerance { relative = 0.01; } }
        attribute vout : ElectricPotentialValue = vin * r2 / (r1 + r2);
        attribute current : ElectricCurrentValue = vin / (r1 + r2);
    }

    requirement def <'ADC-1'> AdcRange {
        doc /* The divider output shall stay within the ADC input range (0 to 2.5 V). */
        subject divider : Divider;
        require constraint { divider.vout <= 2.3 [V] }
    }
    requirement def <'PWR-3'> DividerCurrent {
        doc /* The divider shall draw at most 25 µA from the battery. */
        subject divider : Divider;
        require constraint { divider.current <= 25 ['µA'] }
    }

    part battSense : Divider {
        assert constraint { vout > 1 [V] }
    }
    requirement adcRange : AdcRange;
    requirement dividerCurrent : DividerCurrent;
    satisfy adcRange by battSense;
    satisfy dividerCurrent by battSense;
}
