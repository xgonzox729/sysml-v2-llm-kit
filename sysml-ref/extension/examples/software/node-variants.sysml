package NodeVariants {
    doc /* A family of sensor nodes: a battery and a radio to choose, and two configurations that
         * choose them. "Generate Code" writes a configuration header and a defconfig for each
         * configuration, and a Kconfig with the choices. */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Software::*;

    part def Battery {
        attribute capacity : ElectricChargeValue { @Config { name = "BATTERY_CAPACITY_MAH"; scale = 1 [mAh]; } }
        attribute nominalVoltage : ElectricPotentialValue;
    }
    part def Radio {
        attribute peakCurrent : ElectricCurrentValue { @Config { name = "RADIO_PEAK_CURRENT_MA"; scale = 1 [mA]; } }
    }

    variation part def BatteryChoice :> Battery {
        variant part aaLithium : Battery {
            doc /* Primary lithium AA: high capacity, handles pulse loads. */
            :>> capacity = 3000 [mAh];
            :>> nominalVoltage = 3.6 [V];
        }
        variant part liIon : Battery {
            doc /* Rechargeable 18650. */
            :>> capacity = 2600 [mAh];
            :>> nominalVoltage = 3.7 [V];
        }
    }

    variation part def RadioChoice :> Radio {
        variant part loRa : Radio { :>> peakCurrent = 120 [mA]; }
        variant part ble : Radio { :>> peakCurrent = 8 [mA]; }
    }

    abstract part nodeFamily {
        part battery : BatteryChoice;
        part radio : RadioChoice;
        attribute reportPeriod : DurationValue = 15 [min] { @Config { scale = 1 [s]; } }
        attribute useWatchdog : Boolean = true { @Config; }
        /* LoRa's transmit pulses need the primary cell. */
        assert constraint loRaNeedsLithium { radio == radio::loRa implies battery == battery::aaLithium }
    }

    part outdoorNode :> nodeFamily {
        part :>> battery = battery::aaLithium;
        part :>> radio = radio::loRa;
    }

    part indoorNode :> nodeFamily {
        part :>> battery = battery::liIon;
        part :>> radio = radio::ble;
        attribute :>> reportPeriod = 1 [min];
    }
}
