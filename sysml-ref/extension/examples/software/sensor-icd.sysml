package SensorIcd {
    doc /* The messages a sensor node sends, and its temperature sensor's registers. Run
         * "Generate Code" for C types with encode/decode functions, a JSON Schema, a protobuf
         * file and the register header. */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Software::*;
    private import Registers::*;

    enum def NodeStatus {
        doc /* What the node is doing when it reports. */
        enum ok;
        enum lowBattery;
        enum sensorFault { @Encoding { code = 8; } }
    }

    attribute def Location {
        attribute latitude : Real { @Encoding { bits = 32; } }
        attribute longitude : Real { @Encoding { bits = 32; } }
    }

    item def Reading {
        doc /* One measurement, sent every cycle. */
        @Encoding { byteOrder = ByteOrder::bigEndian; }
        attribute sequence : Natural { @Encoding { bits = 16; } }
        attribute temperature : ThermodynamicTemperatureValue { @Encoding { bits = 16; signed = true; scale = 0.01 [K]; offset = 273.15 [K]; } }
        attribute battery : ElectricPotentialValue { @Encoding { bits = 16; scale = 1 [mV]; } }
        attribute status : NodeStatus;
        attribute samples : Integer[4] { @Encoding { bits = 16; signed = true; } }
        attribute history : Natural[0..*] { @Encoding { bits = 8; maxLength = 8; } }
        attribute where : Location;
        attribute name : String { @Encoding { maxLength = 12; } }
        attribute charging : Boolean;
    }

    part def TMP117 {
        part <TMP117> registers : RegisterBlock {
            :>> registerBits = 16;
            part <TEMP_RESULT> temperature : Register { :>> offset = 0; :>> access = Access::readOnly; :>> resetValue = "0x8000"; }
            part <CONFIGURATION> configuration : Register {
                :>> offset = 1;
                :>> resetValue = "0x0220";
                part <HIGH_ALERT> highAlert : Field { :>> lsb = 15; :>> access = Access::readOnly; }
                part <LOW_ALERT> lowAlert : Field { :>> lsb = 14; :>> access = Access::readOnly; }
                part <MOD> mode : Field {
                    :>> lsb = 10; :>> width = 2;
                    attribute continuous = 0;
                    attribute shutdown = 1;
                    attribute oneShot = 3;
                }
                part <CONV> conversionCycle : Field { :>> lsb = 7; :>> width = 3; }
                part <AVG> averaging : Field { :>> lsb = 5; :>> width = 2; }
            }
            part <DEVICE_ID> deviceId : Register { :>> offset = 15; :>> access = Access::readOnly; :>> resetValue = "0x0117"; }
        }
    }
}
