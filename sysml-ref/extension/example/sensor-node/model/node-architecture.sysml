package NodeArchitecture {
    doc
    /*
     * The EnviroNode: a battery-powered sensor node that measures temperature and reports it
     * over LoRa. This file is its structure: the parts it is made of and how they connect.
     */
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;
    private import Electronics::*;
    private import NodeParts::*;
    private import NodeBehavior::*;

    part def EnviroNode {
        doc /* A battery-powered environmental sensor node. */
        attribute reportPeriod : DurationValue;
        attribute life : DurationValue;
        attribute railVoltage : ElectricPotentialValue;
        /* What a node does (NodeBehavior). */
        perform action measurementCycle : MeasurementCycle;
        exhibit state powerModes : PowerModes;
    }

    interface def SpiLink {
        doc /* The SPI bus between a controller and one target. */
        end controller : SPIPort;
        end target : SPIPort;
    }

    part node : EnviroNode {
        :>> reportPeriod = 15 [min];

        part battery : NodeCell;
        part ldo : MainLdo;
        part sensorLdo : SensorLdo;
        part mcu : NodeMcu;
        part sensor : TMP117;
        part radio : LoRaRadio;
        part shifter : I2CLevelShifter;
        part led : StatusLed;
        part ledResistor : Resistor {
            :>> resistance = LedResistor(3.3 [V], led.forwardVoltage, led.current);
            :>> current = led.current;
            :>> powerRating = 63 [mW];
        }
        part sense : BatterySense;

        /* Capacitors: one 100 nF per supply pin, and a bulk capacitor. */
        part capacitors : Capacitor[0..*];
        part decoupling : Capacitor[4] :> capacitors { :>> capacitance = 100 [nF]; :>> voltageRating = 10 [V]; }
        part bulk : Capacitor :> capacitors { :>> capacitance = 10 ['µF']; :>> voltageRating = 6.3 [V]; }

        /* Power: the cell feeds the 3.3 V LDO; the 1.8 V LDO hangs off the 3.3 V rail. */
        connect battery.supply to ldo.input;
        connect ldo.output to mcu.supply;
        connect ldo.output to radio.supply;
        connect ldo.output to sensorLdo.input;
        connect sensorLdo.output to sensor.supply;

        /* Signals. The sensor's 1.8 V I²C reaches the 3.3 V MCU through the level shifter. */
        connect mcu.i2c to shifter.high;
        connect shifter.low to sensor.i2c;
        interface spi : SpiLink connect controller ::> mcu.spi to target ::> radio.spi;
        connect mcu.ledPin to led.drive;
        connect battery.positive to sense.top;

        /* The node's rail is the main LDO's output; the readings travel from the MCU to the radio. */
        bind railVoltage = ldo.outputVoltage;
        flow of NodeIcd::Reading from mcu to radio;
        message txDone of NodeIcd::TxDone from radio to mcu;

        /* The measurement cycle runs on the MCU. */
        allocate measurementCycle to mcu;

        /* The firmware (NodeSoftware), and the processor it runs on. */
        part firmware : NodeSoftware::NodeFirmware;
        allocate firmware to mcu;

        /* 80 % of the rated capacity is usable (temperature, ageing, cutoff). */
        :>> life = BatteryLife(battery.capacity, battery.current, 0.8);
    }
}
