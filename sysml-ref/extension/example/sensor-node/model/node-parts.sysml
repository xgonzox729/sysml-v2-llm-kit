package NodeParts {
    doc
    /*
     * The kinds of parts the EnviroNode is built from: each definition is like a datasheet. It
     * specializes a part of the extension's Electronics library and fills in the values of one
     * real (or realistic) component.
     */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Electronics::*;
    private import NodeIcd::*;
    private import NodeBehavior::Wake;

    /* A rechargeable lithium-ion cell (18650 size). */
    part def NodeCell :> Battery {
        :>> chemistry = Chemistry::liIon;
        :>> capacity = 2400 [mAh];
        :>> nominalVoltage = 3.7 [V];
        :>> fullVoltage = 4.2 [V];
        :>> cutoffVoltage = 3.0 [V];
        :>> maxCurrent = 1 [A];
    }
    comment about NodeCell /* Any protected 18650 cell with at least 2400 mAh fits the holder. */

    /* A low-quiescent-current LDO: 3.3 V for the MCU and the radio. */
    part def MainLdo :> LDO {
        :>> partNumber = "TPS7A0233";
        :>> outputVoltage = 3.3 [V];
        :>> dropout = 0.15 [V];
        :>> maxOutputCurrent = 200 [mA];
        :>> quiescentCurrent = 25 [nA];
        :>> minInputVoltage = 1.5 [V];
        :>> maxInputVoltage = 6 [V];
    }

    /* A second LDO: 1.8 V for the sensor, fed from the 3.3 V rail. */
    part def SensorLdo :> LDO {
        :>> partNumber = "TPS7A0218";
        :>> outputVoltage = 1.8 [V];
        :>> dropout = 0.15 [V];
        :>> maxOutputCurrent = 200 [mA];
        :>> quiescentCurrent = 25 [nA];
        :>> minInputVoltage = 1.5 [V];
        :>> maxInputVoltage = 6 [V];
    }

    /* The microcontroller: I²C to the sensor, SPI to the radio, a pin for the status LED. */
    part def NodeMcu :> Microcontroller {
        :>> partNumber = "STM32L072";
        :>> minSupplyVoltage = 1.8 [V];
        :>> maxSupplyVoltage = 3.6 [V];
        :>> activeCurrent = 4 [mA];
        :>> sleepCurrent = 1.5 ['µA'];
        :>> dutyCycle = 0.01;
        :>> clockFrequency = 32 [MHz];
        :>> flash = 192 [KiB];
        :>> ram = 20 [KiB];
        port i2c : I2CPort { :>> vdd = 3.3 [V]; :>> clockRate = 400 [kHz]; :>> isController = true; }
        port spi : SPIPort { :>> vdd = 3.3 [V]; :>> clockRate = 8 [MHz]; :>> isController = true; }
        out port ledPin : GPIOPort { :>> vdd = 3.3 [V]; }

        /* The radio driver in the firmware: on Wake, sample, hand the reading to the radio, retry twice. */
        attribute retries : Integer = 0;
        exhibit state radioDriver {
            entry; then idle;
            state idle;
            state sampling;
            state sending { entry send Reading() via spi; }
            transition first idle accept Wake then sampling;
            transition first sampling accept after 5 [ms] then sending;
            transition sent first sending accept TxDone then idle;
            transition retry first sending accept after 100 [ms] if retries < 2 do assign retries := retries + 1 then sending;
        }
    }

    /* The temperature sensor. It runs from the 1.8 V rail, so its I²C pins are 1.8 V logic. */
    part def TMP117 :> Sensor {
        :>> partNumber = "TMP117";
        :>> minSupplyVoltage = 1.7 [V];
        :>> maxSupplyVoltage = 5.5 [V];
        :>> activeCurrent = 135 ['µA'];
        :>> sleepCurrent = 0.15 ['µA'];
        :>> dutyCycle = 0.005;
        port i2c : I2CPort { :>> vdd = 1.8 [V]; :>> clockRate = 400 [kHz]; :>> address = 72; }

        /* Its registers (TMP117 datasheet, section 7.6). */
        part <TMP117> registers : Registers::RegisterBlock {
            :>> registerBits = 16;
            part <TEMP_RESULT> temperature : Registers::Register {
                doc /* The last conversion, 7.8125 m°C per count. */
                :>> offset = 0; :>> access = Registers::Access::readOnly; :>> resetValue = "0x8000";
            }
            part <CONFIGURATION> configuration : Registers::Register {
                :>> offset = 1;
                :>> resetValue = "0x0220";
                part <HIGH_ALERT> highAlert : Registers::Field { :>> lsb = 15; :>> access = Registers::Access::readOnly; }
                part <LOW_ALERT> lowAlert : Registers::Field { :>> lsb = 14; :>> access = Registers::Access::readOnly; }
                part <DATA_READY> dataReady : Registers::Field { :>> lsb = 13; :>> access = Registers::Access::readOnly; }
                part <MOD> mode : Registers::Field {
                    :>> lsb = 10; :>> width = 2;
                    attribute continuous = 0;
                    attribute shutdown = 1;
                    attribute oneShot = 3;
                }
                part <CONV> conversionCycle : Registers::Field { :>> lsb = 7; :>> width = 3; }
                part <AVG> averaging : Registers::Field { :>> lsb = 5; :>> width = 2; }
            }
            part <DEVICE_ID> deviceId : Registers::Register { :>> offset = 15; :>> access = Registers::Access::readOnly; :>> resetValue = "0x0117"; }
        }
    }

    /* The LoRa radio. Its active current is the transmit current. */
    part def LoRaRadio :> Radio {
        :>> partNumber = "SX1262";
        :>> minSupplyVoltage = 1.8 [V];
        :>> maxSupplyVoltage = 3.7 [V];
        :>> activeCurrent = 12 [mA];
        :>> txCurrent = 45 [mA];
        :>> rxCurrent = 5 [mA];
        :>> sleepCurrent = 0.4 ['µA'];
        :>> dutyCycle = 0.002;
        port spi : SPIPort { :>> vdd = 3.3 [V]; :>> clockRate = 16 [MHz]; }

        /* The modem: a reading from the MCU goes on the air for 40 ms, then the MCU is told. */
        exhibit state modem {
            entry; then standby;
            state standby;
            state transmitting;
            transition first standby accept Reading then transmitting;
            transition first transmitting accept after 40 [ms] do send TxDone() via spi then standby;
        }
    }

    /* An I²C level shifter between a 1.8 V and a 3.3 V bus. */
    part def I2CLevelShifter :> Component {
        :>> partNumber = "PCA9306";
        port low : I2CPort { :>> vdd = 1.8 [V]; :>> clockRate = 400 [kHz]; }
        port high : I2CPort { :>> vdd = 3.3 [V]; :>> clockRate = 400 [kHz]; }
    }

    /* The status LED. */
    part def StatusLed :> LED {
        :>> forwardVoltage = 2.0 [V];
        :>> maxForwardCurrent = 20 [mA];
        :>> current = 2 [mA];
        in port drive : GPIOPort;
    }

    /* Scales the battery voltage (up to 4.2 V) into the ADC's range: a divider with a filter capacitor. */
    part def BatterySense :> Component {
        private import Simulation::*;
        port top : Terminal;
        port tap : Terminal;
        port bottom : Terminal;
        attribute vin : ElectricPotentialValue = 4.2 [V] { @Tolerance { minimum = 3.0 [V]; maximum = 4.2 [V]; } }
        part r1 : Resistor {
            :>> resistance = 100 ['kΩ'] { @Tolerance { relative = 0.01; } }
            :>> powerRating = 63 [mW];
        }
        part r2 : Resistor {
            :>> resistance = 90.9 ['kΩ'] { @Tolerance { relative = 0.01; } }
            :>> powerRating = 63 [mW];
        }
        part c1 : Capacitor { :>> capacitance = 100 [nF]; :>> voltageRating = 10 [V]; }
        attribute vout : ElectricPotentialValue = DividerOutput(vin, r1.resistance, r2.resistance);
        attribute current : ElectricCurrentValue = vin / (r1.resistance + r2.resistance);
        /* The design target: a full cell gives 2.0 V at the ADC. */
        constraint fullScale { vout == 2.0 [V] }
        connect top to r1.p;
        connect r1.n to r2.p;
        connect r1.n to c1.p;
        connect r1.n to tap;
        connect r2.n to bottom;
        connect c1.n to bottom;
    }
}
