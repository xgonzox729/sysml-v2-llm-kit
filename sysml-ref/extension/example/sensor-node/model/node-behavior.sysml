package NodeBehavior {
    doc /* What the EnviroNode does: its measurement cycle (an action flow) and its power modes (a state machine). */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Simulation::*;
    private import Software::*;

    item def Wake;
    item def LowBattery;
    item def Reset;

    /* One measurement: wake up, read the sensor, store and send the reading, sleep again. */
    action def MeasurementCycle {
        attribute samples : Integer = 0;
        first start;
        then action wake { @Timing { duration = 1 [ms]; } }
        then action sample {
            @Timing { duration = 4 [ms]; }
            assign samples := samples + 1;
        }
        then decide enough;
        if samples < 4 then sample;
        else average;
        action average { @Timing { duration = 0.2 [ms]; } }
        then fork split;
        then store;
        then transmit;
        action store { @Timing { duration = 2 [ms]; } }
        action transmit { @Timing { duration = 40 [ms]; } }
        join both;
        first store then both;
        first transmit then both;
        first both then sleep;
        action sleep { @Timing { duration = 0.5 [ms]; } }
        then done;
    }

    /* The node's power modes, with the current it draws in each and the charge left in its cell. */
    state def PowerModes {
        attribute current : ElectricCurrentValue = 6 ['µA'];
        /* 80 % of the 2400 mAh cell is usable. */
        attribute charge : ElectricChargeValue = 1920 [mAh];
        attribute batteryVoltage : ElectricPotentialValue = 3.7 [V];
        attribute wakeups : Integer = 0;

        /* The cell discharges at the present current. */
        @Rate { rateOf = charge; rate = -current; }
        @Simulate {
            duration = 7 [d];
            step = 60 [s];
            events = ("Wake every 15 [min]");
            stopWhen = charge <= 0 [mAh];
        }

        entry; then sleeping;

        state sleeping { entry action sleepCurrent { assign current := 6 ['µA']; } }
        transition wake first sleeping accept Wake do assign wakeups := wakeups + 1 then active;

        state active {
            entry; then measuring;
            state measuring { entry action measureCurrent { assign current := 4.2 [mA]; } }
            transition first measuring accept after 50 [ms] then transmitting;
            state transmitting { entry action radioCurrent { assign current := 49 [mA]; } }
        }
        transition sleepAgain first active accept after 150 [ms] then sleeping;
        transition lowBattery first active accept LowBattery if batteryVoltage < 3.3 [V] then fault;

        state fault { entry action alarm { assign current := 1 ['µA']; } }
        transition reset first fault accept Reset then sleeping;
    }
}
