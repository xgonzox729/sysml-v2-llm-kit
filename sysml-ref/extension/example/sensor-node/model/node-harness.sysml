package NodeHarness {
    doc
    /*
     * The field installation: the node's enclosure connector, a remote temperature probe it
     * powers, and an RS-485 link to a gateway, wired through one cable harness. The Wiring
     * library checks what flows through each pin and wire.
     */
    private import Wiring::*;
    private import SI::*;

    /* What flows. */
    item def Probe3V3 :> Power { :>> nominal = 3.3 [V]; }
    item def Probe3V3Load :> Power { :>> minimum = 3.0 [V]; :>> maximum = 3.6 [V]; }
    item def ProbeSignal :> Analog { :>> minimum = 0 [V]; :>> maximum = 2.5 [V]; }
    item def Rs485Link :> RS485 { :>> bitrate = 19200; }

    /* The node's enclosure connector. */
    part def NodeEnclosure {
        part J1 : Connector {
            :>> gender = ConnectorGender::receptacle;
            port '1' : Pin { :>> maxCurrent = 1 [A]; out item :>> signal : Probe3V3 { :>> current = 0.2 [A]; } }
            port '2' : Pin { out item :>> signal : Ground; }
            port '3' : Pin { in item :>> signal : ProbeSignal; }
            port '4' : Pin { inout item :>> signal : Rs485Link { :>> polarity = Polarity::positive; } }
            port '5' : Pin { inout item :>> signal : Rs485Link { :>> polarity = Polarity::negative; } }
        }
    }

    /* A remote probe, powered by the node. */
    part def TemperatureProbe {
        part J1 : Connector {
            :>> gender = ConnectorGender::receptacle;
            port A : Pin { in item :>> signal : Probe3V3Load { :>> current = 5 [mA]; :>> maxDrop = 0.1 [V]; } }
            port B : Pin { in item :>> signal : Ground; }
            port C : Pin { out item :>> signal : ProbeSignal { :>> current = 1 [mA]; } }
        }
    }

    /* The gateway's RS-485 port. */
    part def Gateway {
        part J1 : Connector {
            :>> gender = ConnectorGender::receptacle;
            port '1' : Pin { inout item :>> signal : Rs485Link { :>> polarity = Polarity::positive; } }
            port '2' : Pin { inout item :>> signal : Rs485Link { :>> polarity = Polarity::negative; } }
        }
    }

    /* The cable harness. */
    part def W1 :> Harness {
        :>> harnessId = "W1";
        part P1 : Connector { :>> gender = ConnectorGender::plug; port '1' : Pin; port '2' : Pin; port '3' : Pin; port '4' : Pin; port '5' : Pin; }
        part P2 : Connector { :>> gender = ConnectorGender::plug; port A : Pin; port B : Pin; port C : Pin; }
        part P3 : Connector { :>> gender = ConnectorGender::plug; port '1' : Pin; port '2' : Pin; }

        connection W101 : Wire connect P1.'1' to P2.A { :>> length = 10 [m]; :>> gauge = AWG::AWG24; :>> color = "red"; }
        connection W102 : Wire connect P1.'2' to P2.B { :>> length = 10 [m]; :>> gauge = AWG::AWG24; :>> color = "black"; }
        connection W103 : Wire connect P2.C to P1.'3' { :>> length = 10 [m]; :>> gauge = AWG::AWG24; :>> color = "white"; }

        /* RS-485 to the gateway, twisted. */
        connection W104 : Wire connect P1.'4' to P3.'1' { :>> length = 50 [m]; :>> gauge = AWG::AWG24; :>> color = "blue"; }
        connection W105 : Wire connect P1.'5' to P3.'2' { :>> length = 50 [m]; :>> gauge = AWG::AWG24; :>> color = "white/blue"; }
        part TP1 : TwistedPair { :>> wires = (W104, W105); }
    }

    /* The installation: the equipment and the harness, mated. */
    part fieldInstallation {
        part enclosure : NodeEnclosure;
        part probe : TemperatureProbe;
        part gateway : Gateway;
        part w1 : W1;
        connect enclosure.J1 to w1.P1;
        connect probe.J1 to w1.P2;
        connect gateway.J1 to w1.P3;
    }
}
