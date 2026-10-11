package NodeIcd {
    doc
    /*
     * The interface control document of the EnviroNode as model: the message it sends over
     * LoRa, field by field, with how each field is encoded. "Generate Code" turns it into C,
     * a JSON Schema and protobuf; "Generate Documents" lists it in the ICD.
     */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Software::*;

    enum def NodeStatus {
        doc /* What the node reports about itself. */
        enum ok;
        enum lowBattery;
        enum sensorFault { @Encoding { code = 8; } }
    }

    item def Reading {
        doc /* The uplink message: one measurement, sent every report period. */
        @Encoding { byteOrder = ByteOrder::bigEndian; }
        attribute sequence : Natural { @Encoding { bits = 16; } }
        attribute temperature : ThermodynamicTemperatureValue { @Encoding { bits = 16; signed = true; scale = 0.01 [K]; offset = 273.15 [K]; } }
        attribute battery : ElectricPotentialValue { @Encoding { bits = 16; scale = 1 [mV]; } }
        attribute status : NodeStatus;
        attribute samples : Integer[4] { @Encoding { bits = 16; signed = true; } }
    }

    item def TxDone {
        doc /* The radio's signal to the MCU that a packet is on the air. */
    }

    item def Configure {
        doc /* The downlink message: a new report period. */
        @Encoding { byteOrder = ByteOrder::bigEndian; }
        attribute reportPeriod : DurationValue { @Encoding { bits = 16; scale = 1 [s]; } }
        attribute ledEnabled : Boolean;
    }
}
