package NodeMessages {
    doc /* The microcontroller and the radio of a sensor node exchange messages. Simulate the
         * interaction "node" (Behavior tab, or "Simulate State Machine or Action at Cursor" on
         * node) and send Wake: the sequence diagram shows the reading going to the radio, the
         * radio's acknowledgement coming back, and the timers in between. Below it, the declared
         * messages are checked against the run. */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;

    item def Wake;
    item def Reading;
    item def Ack;
    item def Timeout;

    port def RadioLink {
        out item reading : Reading;
        in item ack : Ack;
    }

    part node {
        part mcu {
            port link : RadioLink;
            attribute retries : Integer = 0;
            exhibit state control {
                entry; then sleeping;
                state sleeping;
                state measuring;
                state sending { entry send Reading() via link; }
                transition first sleeping accept Wake then measuring;
                transition first measuring accept after 5 [ms] then sending;
                transition sent first sending accept Ack then sleeping;
                transition retry first sending accept after 100 [ms] if retries < 2 do assign retries := retries + 1 then sending;
            }
        }
        part radio {
            port link : ~RadioLink;
            exhibit state radioModes {
                entry; then idle;
                state idle;
                state transmitting;
                transition first idle accept Reading then transmitting;
                transition first transmitting accept after 40 [ms] do send Ack() to mcu then idle;
            }
        }
        connect mcu.link to radio.link;

        /* The messages the two exchange: the run is checked against them (seen, not seen, and
         * signals nobody declared). */
        message reading of Reading from mcu to radio;
        message ack of Ack from radio to mcu;
    }
}
