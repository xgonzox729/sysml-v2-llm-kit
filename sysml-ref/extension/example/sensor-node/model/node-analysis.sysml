package NodeAnalysis {
    doc /* Questions about the design, answered by calculation: how long it lasts, what that depends on, which cell to use. */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Simulation::*;
    private import TradeStudies::*;
    private import NodeArchitecture::*;

    analysis def LifetimeAnalysis {
        doc /* How long the node runs on one cell. */
        subject n : EnviroNode;
        objective { require constraint { lifetime >= 3 [yr] } }
        return lifetime : DurationValue = n.life;
    }

    analysis lifetime : LifetimeAnalysis { subject :>> n = node; }

    analysis lifetimeVsDutyCycle : LifetimeAnalysis {
        doc /* How the lifetime depends on how much of the time the MCU is awake. */
        subject :>> n = node;
        @Sweep { parameter = node.mcu.dutyCycle; start = 0.001; stop = 0.05; steps = 15; scale = SweepScale::logarithmic; }
    }

    /* Which cell: the most charge for the money. */
    part def CellOption {
        attribute capacity : ElectricChargeValue;
        attribute cost : Real;
    }
    part aaLithium : CellOption { :>> capacity = 3000 [mAh]; :>> cost = 2.5; }
    part liIon18650 : CellOption { :>> capacity = 2400 [mAh]; :>> cost = 4.0; }
    part cr123a : CellOption { :>> capacity = 1500 [mAh]; :>> cost = 3.0; }

    analysis cellTrade : TradeStudy {
        subject options : CellOption[1..*] = (aaLithium, liIon18650, cr123a);
        objective : MaximizeObjective;
        calc :>> evaluationFunction {
            in part option :>> alternative : CellOption;
            return :>> result : Real = option.capacity / 1 [mAh] / option.cost;
        }
    }
}
