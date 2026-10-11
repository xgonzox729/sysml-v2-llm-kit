package Avionics {
    doc
    /*
     * A small avionics installation: a 28 V power supply, a flight computer and a display
     * unit on a CAN bus and an Ethernet link, wired through one harness (W1).
     * Open the Interconnection view on `system`, or break something (swap CAN_H and CAN_L in
     * W1, shorten a wire gauge) to see the wiring checks.
     */
    private import Wiring::*;
    private import SI::*;

    /* ---- Signals ---- */

    item def DC28V :> Power {
        :>> nominal = 28 [V];
    }
    item def DC28VLoad :> Power {
        doc /* What a 28 V avionics load accepts (DO-160 normal range). */
        :>> minimum = 22 [V];
        :>> maximum = 32.2 [V];
    }
    item def CAN500k :> CAN {
        :>> bitrate = 500000;
    }
    item def Eth100 :> Ethernet {
        :>> bitrate = 100000000;
    }

    /* ---- Equipment and their pinouts ---- */

    part def PowerSupply {
        part J1 : Connector {
            :>> gender = ConnectorGender::receptacle;
            port '1' : Pin { :>> maxCurrent = 13 [A]; out item :>> signal : DC28V { :>> current = 10 [A]; } }
            port '2' : Pin { :>> maxCurrent = 13 [A]; out item :>> signal : Ground; }
        }
    }

    part def FlightComputer {
        part J1 : Connector {
            :>> gender = ConnectorGender::receptacle;
            port A : Pin { in item :>> signal : DC28VLoad { :>> current = 3 [A]; :>> maxDrop = 1 [V]; } }
            port B : Pin { in item :>> signal : Ground; }
            port C : Pin { inout item :>> signal : CAN500k { :>> polarity = Polarity::positive; } }
            port D : Pin { inout item :>> signal : CAN500k { :>> polarity = Polarity::negative; } }
            port E : Pin { inout item :>> signal : Eth100 { :>> polarity = Polarity::positive; :>> pair = 1; } }
            port F : Pin { inout item :>> signal : Eth100 { :>> polarity = Polarity::negative; :>> pair = 1; } }
        }
    }

    part def DisplayUnit {
        part J1 : Connector {
            :>> gender = ConnectorGender::receptacle;
            port '1' : Pin { in item :>> signal : DC28VLoad { :>> current = 2 [A]; :>> maxDrop = 1 [V]; } }
            port '2' : Pin { in item :>> signal : Ground; }
            port '3' : Pin { inout item :>> signal : CAN500k { :>> polarity = Polarity::positive; } }
            port '4' : Pin { inout item :>> signal : CAN500k { :>> polarity = Polarity::negative; } }
            port '5' : Pin { inout item :>> signal : Eth100 { :>> polarity = Polarity::positive; :>> pair = 1; } }
            port '6' : Pin { inout item :>> signal : Eth100 { :>> polarity = Polarity::negative; :>> pair = 1; } }
        }
    }

    /* ---- Harness ---- */

    part def W1 :> Harness {
        :>> harnessId = "W1";

        /* Plugs, mating with the equipment receptacles pin for pin. */
        part P1 : Connector {
            :>> gender = ConnectorGender::plug;
            port '1' : Pin;
            port '2' : Pin;
        }
        part P2 : Connector {
            :>> gender = ConnectorGender::plug;
            port A : Pin; port B : Pin; port C : Pin; port D : Pin; port E : Pin; port F : Pin;
        }
        part P3 : Connector {
            :>> gender = ConnectorGender::plug;
            port '1' : Pin; port '2' : Pin; port '3' : Pin; port '4' : Pin; port '5' : Pin; port '6' : Pin;
        }

        /* 28 V feed from the supply, split to both loads. */
        part SP1 : Splice;
        part SP2 : Splice;

        connection W1001 : Wire connect P1.'1' to SP1.node {
            :>> length = 2 [m]; :>> gauge = AWG::AWG16; :>> color = "red";
        }
        connection W1002 : Wire connect SP1.node to P2.A {
            :>> length = 3 [m]; :>> gauge = AWG::AWG20; :>> color = "red";
        }
        connection W1003 : Wire connect SP1.node to P3.'1' {
            :>> length = 4 [m]; :>> gauge = AWG::AWG20; :>> color = "red";
        }

        /* Returns. */
        connection W1004 : Wire connect P1.'2' to SP2.node {
            :>> length = 2 [m]; :>> gauge = AWG::AWG16; :>> color = "black";
        }
        connection W1005 : Wire connect SP2.node to P2.B {
            :>> length = 3 [m]; :>> gauge = AWG::AWG20; :>> color = "black";
        }
        connection W1006 : Wire connect SP2.node to P3.'2' {
            :>> length = 4 [m]; :>> gauge = AWG::AWG20; :>> color = "black";
        }

        /* CAN bus, twisted. */
        connection W1007 : Wire connect P2.C to P3.'3' {
            :>> length = 5 [m]; :>> gauge = AWG::AWG24; :>> color = "white";
        }
        connection W1008 : Wire connect P2.D to P3.'4' {
            :>> length = 5 [m]; :>> gauge = AWG::AWG24; :>> color = "blue";
        }
        part TP1 : TwistedPair {
            :>> wires = (W1007, W1008);
        }

        /* Ethernet pair, twisted. */
        connection W1009 : Wire connect P2.E to P3.'5' {
            :>> length = 5 [m]; :>> gauge = AWG::AWG24; :>> color = "orange";
        }
        connection W1010 : Wire connect P2.F to P3.'6' {
            :>> length = 5 [m]; :>> gauge = AWG::AWG24; :>> color = "white/orange";
        }
        part TP2 : TwistedPair {
            :>> wires = (W1009, W1010);
        }
    }

    /* ---- Installation ---- */

    part system {
        part psu : PowerSupply;
        part fcc : FlightComputer;
        part du : DisplayUnit;
        part w1 : W1;

        connect psu.J1 to w1.P1;
        connect fcc.J1 to w1.P2;
        connect du.J1 to w1.P3;
    }
}
