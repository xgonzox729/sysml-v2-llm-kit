package SensorPower {
    doc /* The power tree of a battery-powered sensor node, built from the Electronics library:
         * rail loads, part ratings and battery life. Open "Verify Requirements". */
    private import SI::*;
    private import EngineeringUnits::*;
    private import ISQ::*;
    private import Electronics::*;
    private import ScalarValues::*;
    private import TradeStudies::*;
    private import Simulation::*;

    part def SensorNode {
        attribute life : DurationValue;
    }

    part node : SensorNode {
        part battery : Battery {
            :>> chemistry = Chemistry::liIon;
            :>> capacity = 2400 [mAh];
            :>> nominalVoltage = 3.7 [V]; :>> fullVoltage = 4.2 [V]; :>> cutoffVoltage = 3.0 [V];
            :>> maxCurrent = 1 [A];
        }
        part ldo : LDO {
            :>> partNumber = "TPS7A02-3.3";
            :>> outputVoltage = 3.3 [V]; :>> dropout = 0.15 [V];
            :>> maxOutputCurrent = 200 [mA]; :>> quiescentCurrent = 25 [nA];
            :>> minInputVoltage = 1.5 [V]; :>> maxInputVoltage = 6 [V];
        }
        part mcu : Microcontroller {
            :>> activeCurrent = 4 [mA]; :>> sleepCurrent = 1.5 ['µA']; :>> dutyCycle = 0.01;
            :>> minSupplyVoltage = 1.8 [V]; :>> maxSupplyVoltage = 3.6 [V];
        }
        part sensor : Sensor {
            :>> activeCurrent = 0.7 [mA]; :>> sleepCurrent = 0.1 ['µA']; :>> dutyCycle = 0.005;
            :>> minSupplyVoltage = 1.7 [V]; :>> maxSupplyVoltage = 3.6 [V];
        }
        part radio : Radio {
            :>> activeCurrent = 12 [mA]; :>> sleepCurrent = 0.4 ['µA']; :>> dutyCycle = 0.002;
            :>> minSupplyVoltage = 1.8 [V]; :>> maxSupplyVoltage = 3.6 [V];
        }
        part statusLed : LED { :>> forwardVoltage = 2.0 [V]; :>> maxForwardCurrent = 20 [mA]; :>> current = 2 [mA]; }
        part ledResistor : Resistor {
            :>> resistance = LedResistor(3.3 [V], 2.0 [V], 2 [mA]);
            :>> current = 2 [mA]; :>> powerRating = 63 [mW];
        }

        connect battery.supply to ldo.input;
        connect ldo.output to mcu.supply;
        connect ldo.output to sensor.supply;
        connect ldo.output to radio.supply;

        /* 80 % of the rated capacity is usable (temperature, ageing, cutoff). */
        :>> life = BatteryLife(battery.capacity, battery.current, 0.8);
    }

    requirement def <'PWR-1'> NodeLifetime {
        doc /* The node shall run at least three years on one battery. */
        subject n : SensorNode;
        require constraint { n.life >= 3 [yr] }
    }
    requirement nodeLifetime : NodeLifetime;
    satisfy nodeLifetime by node;

    /* How long does the node last, and how does that depend on how often the MCU wakes up? */
    analysis def LifetimeAnalysis {
        subject n : SensorNode;
        objective { require constraint { lifetime >= 3 [yr] } }
        return lifetime : DurationValue = n.life;
    }
    analysis lifetime : LifetimeAnalysis { subject :>> n = node; }
    analysis lifetimeVsDutyCycle : LifetimeAnalysis {
        subject :>> n = node;
        @Sweep { parameter = node.mcu.dutyCycle; start = 0.001; stop = 0.05; steps = 15; scale = SweepScale::logarithmic; }
    }

    /* Which battery: the most charge per unit cost (cost in any currency, per cell). */
    part def CellOption {
        attribute capacity : ElectricChargeValue;
        attribute cost : Real;
    }
    part aaLithium : CellOption { :>> capacity = 3000 [mAh]; :>> cost = 2.5; }
    part liIon18650 : CellOption { :>> capacity = 2400 [mAh]; :>> cost = 4.0; }
    part cr123a : CellOption { :>> capacity = 1500 [mAh]; :>> cost = 3.0; }
    analysis batteryTrade : TradeStudy {
        subject options : CellOption[1..*] = (aaLithium, liIon18650, cr123a);
        objective : MaximizeObjective;
        calc :>> evaluationFunction {
            in part option :>> alternative : CellOption;
            return :>> result : Real = option.capacity / 1 [mAh] / option.cost;
        }
    }
}
