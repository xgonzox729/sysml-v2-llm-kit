package SensorInterfaces {
    doc /* Logic levels across interfaces: a 3.3 V microcontroller talks to a 1.8 V sensor over
         * I²C through a level shifter, and to a GPS over a UART. Connect mcu.i2c directly to
         * sensor.i2c (the commented line) to see the overvoltage, logic-level and clock-rate checks. */
    private import SI::*;
    private import EngineeringUnits::*;
    private import Electronics::*;

    part def LevelShifter :> Component {
        port low : I2CPort { :>> vdd = 1.8 [V]; :>> clockRate = 400 [kHz]; }
        port high : I2CPort { :>> vdd = 3.3 [V]; :>> clockRate = 400 [kHz]; }
    }

    part board {
        part mcu : Microcontroller {
            port i2c : I2CPort { :>> vdd = 3.3 [V]; :>> clockRate = 400 [kHz]; :>> isController = true; }
            out port uartTx : UARTPort { :>> vdd = 3.3 [V]; :>> baudRate = 9600 [Hz]; }
        }
        part sensor : Sensor {
            port i2c : I2CPort { :>> vdd = 1.8 [V]; :>> clockRate = 100 [kHz]; }
        }
        part gps : Sensor {
            in port uartRx : UARTPort { :>> vdd = 3.3 [V]; :>> baudRate = 9600 [Hz]; }
        }
        part shifter : LevelShifter;

        // connect mcu.i2c to sensor.i2c;     // 3.3 V into a 1.8 V part: logic-overvoltage
        connect mcu.i2c to shifter.high;
        connect shifter.low to sensor.i2c;
        connect mcu.uartTx to gps.uartRx;
    }
}
