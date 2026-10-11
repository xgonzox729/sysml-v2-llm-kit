standard library package Wiring {
    doc
    /*
     * Wiring: pins, connectors, wires, splices and harnesses, and the signals that flow across
     * them (power, ground, discretes, analog, data buses). The extension checks wiring models
     * built from these definitions: every net carries one kind of signal, voltages are within
     * what the sinks accept and the pins are rated for, each sink has a source, mated connectors
     * match, and wires can carry their current without too much voltage drop.
     *
     * Usage:
     *   private import Wiring::*;
     *   item def DC28V :> Power { :>> nominal = 28 [V]; }
     *   part def PSU { part J1 : Connector { port A1 : Pin { out item :>> signal : DC28V; } } }
     *   part def W1 :> Harness {
     *       part P1 : Connector { port A1 : Pin; }   // pins mate with the equipment pin of the same pinId
     *       part P2 : Connector { port A1 : Pin; }
     *       connection w1 : Wire connect P1.A1 to P2.A1 { :>> length = 1.5 [m]; :>> gauge = AWG::AWG22; }
     *   }
     *   part system { part psu : PSU; part w1 : W1; connect psu.J1 to w1.P1; }
     *
     * Licensed under the MIT license (part of the SysML v2 VS Code extension).
     */

    private import ScalarValues::*;
    private import MeasurementReferences::*;
    private import SI::*;

    /* Units commonly used in wiring that the SI library does not predefine. */
    attribute <mV> millivolt : ElectricPotentialUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = milli; :>> referenceUnit = V; } }
    attribute <kV> kilovolt : ElectricPotentialUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = kilo; :>> referenceUnit = V; } }
    attribute <mA> milliampere : ElectricCurrentUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = milli; :>> referenceUnit = A; } }
    attribute <'μA'> microampere : ElectricCurrentUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = micro; :>> referenceUnit = A; } }
    attribute <'mΩ'> milliohm : ResistanceUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = milli; :>> referenceUnit = 'Ω'; } }
    attribute <'kΩ'> kiloohm : ResistanceUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = kilo; :>> referenceUnit = 'Ω'; } }
    attribute <mW> milliwatt : PowerUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = milli; :>> referenceUnit = W; } }
    attribute <kW> kilowatt : PowerUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = kilo; :>> referenceUnit = W; } }
    attribute <cm> centimetre : LengthUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = centi; :>> referenceUnit = m; } }
    attribute <'mm²'> 'millimetre squared' : AreaUnit = mm^2;
    attribute <ft> foot : LengthUnit { :>> unitConversion: ConversionByConvention { :>> referenceUnit = m; :>> conversionFactor = 0.3048; } }
    attribute <'in'> inch : LengthUnit { :>> unitConversion: ConversionByConvention { :>> referenceUnit = m; :>> conversionFactor = 0.0254; } }

    /* ---- Signals ------------------------------------------------------------------------- */

    abstract item def Signal {
        doc
        /*
         * What a pin carries. Equipment pins declare it with a direction:
         * `out` for a source (driver), `in` for a sink, `inout` for a bidirectional bus pin.
         * Harness pins usually declare nothing; they carry whatever their net carries.
         */
    }

    item def Power :> Signal {
        doc /* A supply. On a source: the voltage it provides and the current it can deliver;
             * on a sink: the voltage range it accepts and the current it draws. */
        attribute nominal : ElectricPotentialValue;
        attribute minimum : ElectricPotentialValue;
        attribute maximum : ElectricPotentialValue;
        attribute current : ElectricCurrentValue;
        attribute maxDrop : ElectricPotentialValue {
            doc /* Largest acceptable voltage drop from the source to this sink. */
        }
    }

    item def Ground :> Signal {
        doc /* Power or signal return. A source of a Ground is a ground reference. */
        attribute current : ElectricCurrentValue;
    }

    item def Discrete :> Signal {
        doc /* A two-state signal (e.g. 28V/open, ground/open). */
        attribute high : ElectricPotentialValue;
        attribute minimum : ElectricPotentialValue;
        attribute maximum : ElectricPotentialValue;
        attribute current : ElectricCurrentValue;
    }

    item def Analog :> Signal {
        doc /* A continuous signal within a voltage range. */
        attribute minimum : ElectricPotentialValue;
        attribute maximum : ElectricPotentialValue;
        attribute current : ElectricCurrentValue;
    }

    enum def Polarity {
        doc /* The leg of a differential pair: CAN_H/A/+ is positive, CAN_L/B/- is negative. */
        positive;
        negative;
    }

    abstract item def DataSignal :> Signal {
        doc /* A digital data link. Every pin on one net must use the same bit rate. */
        attribute bitrate : Natural { doc /* bits per second */ }
    }

    abstract item def Differential :> DataSignal {
        doc /* One leg of a differential pair. Every pin on one net must have the same polarity. */
        attribute polarity : Polarity;
        attribute pair : Natural { doc /* For multi-pair links (Ethernet): which pair. */ }
    }

    item def CAN :> Differential;
    item def Ethernet :> Differential;
    item def ARINC429 :> Differential;
    item def RS422 :> Differential;
    item def RS485 :> Differential;
    item def RS232 :> DataSignal;
    item def Shield :> Signal { doc /* A cable shield or drain. */ }

    /* ---- Pins and connectors -------------------------------------------------------------- */

    port def Pin {
        doc
        /*
         * One contact. Its pinId (by default its name) is what mating connectors match on.
         * The signal it carries is declared by redefining `signal` with a direction and type.
         */
        attribute pinId : String;
        attribute maxCurrent : ElectricCurrentValue;
        attribute voltageRating : ElectricPotentialValue;
        attribute contactSize : String;
        inout item signal : Signal[0..1];
    }

    enum def ConnectorGender {
        plug;
        receptacle;
    }

    part def Connector {
        doc
        /*
         * A connector; its pinout is its Pin ports. Connecting two connectors mates them:
         * pins with the same pinId are joined.
         */
        attribute partNumber : String;
        attribute gender : ConnectorGender;
        port pins : Pin[0..*];
    }

    /* ---- Wires and harnesses -------------------------------------------------------------- */

    enum def AWG {
        doc /* American Wire Gauge sizes; the cross-section of each is known to the checker. */
        AWG0; AWG2; AWG4; AWG6; AWG8; AWG10; AWG12; AWG14; AWG16; AWG18; AWG20; AWG22; AWG24; AWG26; AWG28; AWG30;
    }

    enum def ConductorMaterial {
        copper;
        aluminum;
    }

    connection def Wire {
        doc
        /*
         * A conductor between two pins. Its resistance follows from length, cross-section
         * (or gauge) and material; ampacity, if not given, from the gauge.
         */
        end a : Pin;
        end b : Pin;
        attribute wireId : String;
        attribute length : LengthValue;
        attribute gauge : AWG;
        attribute crossSection : AreaValue;
        attribute material : ConductorMaterial default ConductorMaterial::copper;
        attribute color : String;
        attribute ampacity : ElectricCurrentValue;
    }

    part def Splice {
        doc /* A junction of several wires: connect them all to `node`. */
        port node : Pin;
    }

    part def Harness {
        doc /* A wire harness: its connectors, wires, splices, twisted pairs and shields. */
        attribute harnessId : String;
    }

    part def TwistedPair {
        doc /* Wires twisted together; they should carry the two legs of one differential pair. */
        ref connection wires : Wire[2..*];
    }

    part def CableShield {
        doc /* A shield around wires, terminated through its drain pin. */
        ref connection wires : Wire[1..*];
        port drain : Pin;
    }
}
