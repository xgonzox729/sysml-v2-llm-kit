package NodeVariants {
    doc
    /*
     * The EnviroNode product line: the cell and the radio vary, and two configurations choose
     * them. Each configuration is checked against the family's constraints and generated as a
     * configuration header and a Kconfig defconfig.
     */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Electronics::*;
    private import Software::*;
    private import NodeParts::*;
    private import NodeArchitecture::*;

    variation part def CellChoice :> Battery {
        doc /* The cells a node can be built with. */
        variant part liIon : NodeCell {
            doc /* Rechargeable 18650: for nodes that can be serviced. */
        }
        variant part lithiumPrimary : Battery {
            doc /* Li-SOCl2 AA primary cell: flat 3.6 V, very low self-discharge, for remote nodes. */
            :>> chemistry = Chemistry::lithiumPrimary;
            :>> capacity = 2600 [mAh];
            :>> nominalVoltage = 3.6 [V];
            :>> maxCurrent = 100 [mA];
        }
    }

    variation part def RadioChoice :> Radio {
        doc /* The radios a node can be built with. */
        variant part loRa : LoRaRadio {
            doc /* Long range (kilometres), high transmit current. */
        }
        variant part ble : Radio {
            doc /* Bluetooth LE: short range, low current. */
            :>> partNumber = "nRF52805";
            :>> activeCurrent = 5 [mA];
            :>> sleepCurrent = 0.3 ['µA'];
            :>> dutyCycle = 0.002;
        }
    }

    abstract part nodeFamily : EnviroNode {
        part battery : CellChoice;
        part radio : RadioChoice;
        attribute :>> reportPeriod = 15 [min] { @Config { name = "REPORT_PERIOD_S"; scale = 1 [s]; } }
        attribute cellCapacity : ElectricChargeValue = battery.capacity { @Config { name = "CELL_CAPACITY_MAH"; scale = 1 [mAh]; } }
        /* A LoRa node is installed far away: it needs the primary cell's decade-long shelf life
         * (a Li-ion cell loses a few per cent of its charge a month). */
        assert constraint loRaNeedsPrimaryCell { radio == radio::loRa implies battery == battery::lithiumPrimary }
    }

    part outdoorNode :> nodeFamily {
        part :>> battery = battery::lithiumPrimary;
        part :>> radio = radio::loRa;
    }

    part indoorNode :> nodeFamily {
        part :>> battery = battery::liIon;
        part :>> radio = radio::ble;
        attribute :>> reportPeriod = 5 [min];
    }
}
