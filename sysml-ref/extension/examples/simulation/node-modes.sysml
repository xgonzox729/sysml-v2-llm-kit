package NodeModes {
    doc /* Operating modes of a sensor node (a state machine) and its measurement cycle (an action
         * flow). Run "Simulate State Machine or Action at Cursor" in either and send events, or
         * "Run Time Simulation" for a day of operation: the battery charge over time and the
         * charge used in each mode. */
    private import ScalarValues::*;
    private import SI::*;
    private import ISQ::*;
    private import EngineeringUnits::*;
    private import Simulation::*;

    item def Wake;
    item def Sleep;
    item def LowBattery;
    item def Reset;
    item def Ack;

    part node {
        attribute wakeups : Integer = 0;
        attribute batteryVoltage : Real = 3.7;
        attribute samples : Integer = 0;
        attribute charge : ElectricChargeValue = 2400 [mAh];
        attribute current : ElectricCurrentValue = 5 ['µA'];
        /* The battery discharges at the present current. */
        @Rate { rateOf = charge; rate = -current; }

        exhibit state modes {
            @Simulate {
                duration = 1 [d];
                step = 10 [s];
                events = ("Wake every 5 [min]", "Sleep every 5 [min] from 2 [s]");
                stopWhen = charge <= 0 [mAh];
            }
            entry; then sleeping;

            state sleeping { entry action sleepCurrent { assign current := 5 ['µA']; } }
            transition wake first sleeping accept Wake do assign wakeups := wakeups + 1 then active;

            state active {
                entry; then measuring;
                state measuring { entry action measureCurrent { assign current := 4 [mA]; } }
                transition first measuring accept after 500 [ms] then transmitting;
                state transmitting { entry action radioCurrent { assign current := 12 [mA]; } }
                transition first transmitting accept after 50 [ms] then idle;
                state idle { entry action idleCurrent { assign current := 1 [mA]; } }
            }
            transition sleep first active accept Sleep then sleeping;
            transition lowBattery first active accept LowBattery if batteryVoltage < 3.3 then fault;
            transition tooMany first active accept when wakeups > 1000 then fault;

            state fault { entry action alarm { assign batteryVoltage := 0; } }
            transition reset first fault accept Reset then sleeping;
        }

        action measurementCycle {
            first start;
            then sample;
            action sample { assign samples := samples + 1; }
            then decide enough;
            if samples < 3 then sample;
            else average;
            action average;
            then fork split;
            then store;
            then transmit;
            action store;
            action transmit;
            join both;
            succession first store then both;
            succession first transmit then both;
            first both then waitAck;
            action waitAck accept ack : Ack;
            then done;
        }
    }
}
