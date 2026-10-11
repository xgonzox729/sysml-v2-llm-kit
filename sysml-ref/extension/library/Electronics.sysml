standard library package Electronics {
    doc
    /*
     * Basic electronic parts for system and board-level models: passives, power devices,
     * semiconductors, switches and relays, ICs, and the ports they connect through. Parts carry
     * their parameters and ratings and the equations of what they dissipate or draw. The
     * extension checks ratings (derating), regulator headroom and the current budget of every
     * supply rail. It does not solve circuits; that is what the SPICE analyses are for.
     *
     * Two levels of connection:
     * - `Terminal`: an electrical contact of a part (a resistor's p and n, a diode's anode).
     *   Connect terminals to describe a circuit.
     * - `PowerPort`: a supply rail at system level. A source has `out` power ports, a load
     *   `in` power ports. Connecting them forms rails whose current budget is checked.
     *
     * Usage:
     *   private import SI::*;
     *   private import EngineeringUnits::*;
     *   private import Electronics::*;
     *   part r1 : Resistor { :>> resistance = 10 ['kΩ']; :>> current = 0.3 [mA]; }
     *   part ldo : LDO { :>> outputVoltage = 3.3 [V]; :>> maxOutputCurrent = 300 [mA]; :>> dropout = 0.2 [V]; }
     *
     * Licensed under the MIT license (part of the SysML v2 VS Code extension).
     */

    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import EngineeringUnits::*;

    /* ==== Ports ============================================================================ */

    port def Terminal {
        doc /* An electrical contact of a part. */
    }

    port def PowerPort {
        doc
        /*
         * A supply rail. On a source (`out` port): the voltage it provides and the most current it
         * can deliver; the analysis computes `load`, the current the rail draws from it. On a load
         * (`in` port): the voltage range it accepts and the current it draws.
         */
        attribute nominal : ElectricPotentialValue[0..1];
        attribute minimum : ElectricPotentialValue[0..1];
        attribute maximum : ElectricPotentialValue[0..1];
        attribute current : ElectricCurrentValue[0..1];
        attribute load : ElectricCurrentValue[0..1];
    }

    port def LogicPort {
        doc /* A digital signal: the logic levels its driver produces or its receiver needs. */
        attribute vdd : ElectricPotentialValue[0..1];
        attribute vil : ElectricPotentialValue[0..1];
        attribute vih : ElectricPotentialValue[0..1];
        attribute vol : ElectricPotentialValue[0..1];
        attribute voh : ElectricPotentialValue[0..1];
    }

    port def GPIOPort :> LogicPort;

    port def I2CPort :> LogicPort {
        doc /* On the controller (isController = true): the clock it runs the bus at; on a target: the fastest clock it supports. */
        attribute clockRate : FrequencyValue[0..1];
        attribute isController : Boolean[0..1];
        attribute address : Integer[0..1];
    }

    port def SPIPort :> LogicPort {
        doc /* On the controller (isController = true): the clock it runs the bus at; on a target: the fastest clock it supports. */
        attribute clockRate : FrequencyValue[0..1];
        attribute isController : Boolean[0..1];
    }

    port def UARTPort :> LogicPort {
        attribute baudRate : FrequencyValue[0..1];
    }

    /* ==== Common ============================================================================ */

    abstract part def Component {
        doc
        /*
         * Any electronic part. `power` is what it dissipates at its operating point. `derating`
         * is the fraction of a rating it may use (0.5: at most half the rated power, voltage or
         * current); the rating checks use it.
         */
        attribute partNumber : String[0..1];
        attribute manufacturer : String[0..1];
        attribute packageName : String[0..1];
        attribute derating : Real = 0.5;
        attribute power : PowerValue[0..1];
        attribute maxTemperature : ThermodynamicTemperatureValue[0..1];
        /*
         * For circuit simulation: a SPICE model for this part. For a two-terminal or diode part,
         * a model name defined by a `.model` card (give the card in `spiceModelCard`); for any
         * other part with terminals, a subcircuit name, instantiated with its terminals in
         * declaration order.
         */
        attribute spiceModel : String[0..1];
        attribute spiceModelCard : String[0..1];
    }

    abstract part def TwoTerminal :> Component {
        doc /* A part with two terminals; `voltage` across them and `current` through them at its operating point. */
        port p : Terminal;
        port n : Terminal;
        attribute voltage : ElectricPotentialValue[0..1];
        attribute current : ElectricCurrentValue[0..1];
    }

    /* ==== Passives ========================================================================== */

    part def Resistor :> TwoTerminal {
        attribute resistance : ResistanceValue;
        attribute powerRating : PowerValue[0..1];
        attribute voltageRating : ElectricPotentialValue[0..1];
        :>> power = if current != null ? current * current * resistance else voltage * voltage / resistance;
    }

    enum def Dielectric {
        C0G; X7R; X5R; Y5V; electrolytic; tantalum; film;
    }

    part def Capacitor :> TwoTerminal {
        attribute capacitance : CapacitanceValue;
        attribute voltageRating : ElectricPotentialValue[0..1];
        attribute dielectric : Dielectric[0..1];
        attribute esr : ResistanceValue[0..1];
    }

    part def Inductor :> TwoTerminal {
        attribute inductance : InductanceValue;
        attribute ratedCurrent : ElectricCurrentValue[0..1];
        attribute saturationCurrent : ElectricCurrentValue[0..1];
        attribute dcResistance : ResistanceValue[0..1];
        :>> power = current * current * dcResistance;
    }

    part def Ferrite :> TwoTerminal {
        doc /* A ferrite bead: impedance at 100 MHz, rated current and DC resistance. */
        attribute impedance : ResistanceValue[0..1];
        attribute ratedCurrent : ElectricCurrentValue[0..1];
        attribute dcResistance : ResistanceValue[0..1];
        :>> power = current * current * dcResistance;
    }

    enum def FuseKind {
        fast; slow; ptc;
    }

    part def Fuse :> TwoTerminal {
        doc /* A fuse or resettable PTC. It should carry at most 75 % of its rating continuously. */
        attribute ratedCurrent : ElectricCurrentValue;
        attribute voltageRating : ElectricPotentialValue[0..1];
        attribute kind : FuseKind[0..1];
        attribute resistance : ResistanceValue[0..1];
        :>> derating = 0.75;
        :>> power = current * current * resistance;
    }

    /* ==== Sources and ground (circuit simulation) =========================================== */

    part def Ground :> Component {
        doc /* The circuit's reference node (SPICE node 0). Connect terminals to `gnd`. */
        port gnd : Terminal;
    }

    part def VoltageSource :> TwoTerminal {
        doc
        /*
         * An independent voltage source from p (+) to n (−): `dcVoltage`, or a SPICE source
         * specification in `waveform` (e.g. "PULSE(0 3.3 0 1u 1u 5m 10m)", "SIN(0 1 1k)").
         */
        attribute dcVoltage : ElectricPotentialValue[0..1];
        attribute waveform : String[0..1];
    }

    part def CurrentSource :> TwoTerminal {
        doc /* An independent current source, flowing from p through the source to n. */
        attribute dcCurrent : ElectricCurrentValue[0..1];
        attribute waveform : String[0..1];
    }

    /* ==== Semiconductors ==================================================================== */

    part def Diode :> Component {
        port anode : Terminal;
        port cathode : Terminal;
        attribute forwardVoltage : ElectricPotentialValue;
        attribute maxForwardCurrent : ElectricCurrentValue[0..1];
        attribute maxReverseVoltage : ElectricPotentialValue[0..1];
        attribute current : ElectricCurrentValue[0..1];
        :>> power = forwardVoltage * current;
    }

    part def SchottkyDiode :> Diode;

    part def ZenerDiode :> Diode {
        attribute zenerVoltage : ElectricPotentialValue;
    }

    part def LED :> Diode {
        attribute color : String[0..1];
    }

    enum def Channel {
        n; p;
    }

    part def MOSFET :> Component {
        doc /* A MOSFET used as a switch: conduction loss is I²·Rds(on). */
        port gate : Terminal;
        port drain : Terminal;
        port source : Terminal;
        attribute channel : Channel[0..1];
        attribute rdsOn : ResistanceValue;
        attribute thresholdVoltage : ElectricPotentialValue[0..1];
        attribute maxDrainCurrent : ElectricCurrentValue[0..1];
        attribute maxDrainSourceVoltage : ElectricPotentialValue[0..1];
        attribute current : ElectricCurrentValue[0..1];
        :>> power = current * current * rdsOn;
    }

    enum def BjtType {
        npn; pnp;
    }

    part def BJT :> Component {
        doc /* A bipolar transistor used as a switch: conduction loss is Ic·Vce(sat). */
        port base : Terminal;
        port collector : Terminal;
        port emitter : Terminal;
        attribute type : BjtType[0..1];
        attribute gain : Real[0..1];
        attribute saturationVoltage : ElectricPotentialValue[0..1];
        attribute maxCollectorCurrent : ElectricCurrentValue[0..1];
        attribute current : ElectricCurrentValue[0..1];
        :>> power = current * saturationVoltage;
    }

    /* ==== Switches and relays =============================================================== */

    part def Pole {
        doc
        /*
         * One pole of a switch: a common terminal and the throws it can connect to. Declare the
         * throws as further Terminal ports (`port A : Terminal; port B : Terminal;`); the switch's
         * `position` names the throw every pole is connected to.
         */
        port common : Terminal;
    }

    part def Switch :> Component {
        doc
        /*
         * A switch. A single-pole switch declares its throws as Terminal ports next to `common`:
         *     part s1 : Switch { port A : Terminal; port B : Terminal; :>> position = "A"; }
         * A multi-pole switch declares its poles by subsetting `poles`; they all switch together:
         *     part s2 : Switch { part p1 :> poles { port A : Terminal; port B : Terminal; }
         *                        part p2 :> poles { port A : Terminal; port B : Terminal; } :>> position = "B"; }
         * `position` is the name of the selected throw.
         */
        port common : Terminal[0..1];
        part poles : Pole[0..*];
        attribute position : String[0..1];
        attribute ratedCurrent : ElectricCurrentValue[0..1];
        attribute voltageRating : ElectricPotentialValue[0..1];
        attribute contactResistance : ResistanceValue[0..1];
        attribute current : ElectricCurrentValue[0..1];
        :>> power = current * current * contactResistance;
    }

    part def Relay :> Switch {
        doc /* A relay: a switch driven by its coil. */
        port coilPositive : Terminal;
        port coilNegative : Terminal;
        attribute coilVoltage : ElectricPotentialValue[0..1];
        attribute coilCurrent : ElectricCurrentValue[0..1];
    }

    /* ==== Power ============================================================================= */

    enum def Chemistry {
        alkaline; lithiumPrimary; liIon; liPo; LiFePO4; NiMH; leadAcid;
    }

    part def Battery :> Component {
        doc
        /*
         * A battery or cell. Its supply port provides the nominal voltage and holds from the
         * full-charge voltage down to the cutoff voltage.
         */
        attribute chemistry : Chemistry[0..1];
        attribute capacity : ElectricChargeValue;
        attribute nominalVoltage : ElectricPotentialValue;
        attribute fullVoltage : ElectricPotentialValue[0..1];
        attribute cutoffVoltage : ElectricPotentialValue[0..1];
        attribute internalResistance : ResistanceValue[0..1];
        attribute maxCurrent : ElectricCurrentValue[0..1];
        attribute selfDischargePerMonth : Real[0..1];
        :>> derating = 1;
        port positive : Terminal;
        port negative : Terminal;
        out port supply : PowerPort {
            :>> nominal = nominalVoltage;
            :>> minimum = cutoffVoltage;
            :>> maximum = fullVoltage;
            :>> current = maxCurrent;
        }
        /* The current drawn from the battery (the load on its supply rail). */
        attribute current : ElectricCurrentValue[0..1] = supply.load;
        :>> power = if current != null and internalResistance != null ? current * current * internalResistance else null;
        /* Time to empty at the present current. */
        attribute runtime : DurationValue[0..1] = capacity / current;
    }

    abstract part def Regulator :> Component {
        doc
        /*
         * A voltage regulator. The output current defaults to the load on its output rail
         * (computed by the power analysis); the input voltage to its input rail's nominal voltage.
         */
        in port input : PowerPort {
            :>> minimum = minInputVoltage;
            :>> maximum = maxInputVoltage;
            :>> current = inputCurrent;
        }
        out port output : PowerPort {
            :>> nominal = outputVoltage;
            :>> current = maxOutputCurrent;
        }
        attribute inputVoltage : ElectricPotentialValue[0..1];
        attribute outputVoltage : ElectricPotentialValue;
        attribute outputCurrent : ElectricCurrentValue[0..1] = output.load;
        attribute maxOutputCurrent : ElectricCurrentValue[0..1];
        attribute minInputVoltage : ElectricPotentialValue[0..1];
        attribute maxInputVoltage : ElectricPotentialValue[0..1];
        attribute quiescentCurrent : ElectricCurrentValue[0..1];
        attribute inputCurrent : ElectricCurrentValue[0..1];
        attribute efficiency : Real[0..1];
        :>> derating = 0.8;
    }

    part def LDO :> Regulator {
        doc /* A linear regulator: it needs `dropout` of headroom and burns the difference as heat. */
        attribute dropout : ElectricPotentialValue[0..1];
        :>> inputCurrent = outputCurrent + (quiescentCurrent ?? 0 [A]);
        :>> power = (inputVoltage - outputVoltage) * outputCurrent;
        :>> efficiency = outputVoltage * outputCurrent / (inputVoltage * inputCurrent);
    }

    part def SwitchingRegulator :> Regulator {
        doc /* A switching converter: input power is output power divided by the efficiency. */
        attribute switchingFrequency : FrequencyValue[0..1];
        :>> efficiency = 0.9;
        :>> inputCurrent = outputVoltage * outputCurrent / (efficiency * inputVoltage) + (quiescentCurrent ?? 0 [A]);
        :>> power = outputVoltage * outputCurrent * (1 / efficiency - 1);
    }

    part def BuckConverter :> SwitchingRegulator;
    part def BoostConverter :> SwitchingRegulator;

    part def LoadSwitch :> Component {
        doc /* A power switch between two rails: it passes its output's load and drops I·Rds(on). */
        in port input : PowerPort { :>> current = output.load; }
        out port output : PowerPort { :>> current = maxCurrent; }
        attribute rdsOn : ResistanceValue[0..1];
        attribute maxCurrent : ElectricCurrentValue[0..1];
        attribute current : ElectricCurrentValue[0..1] = output.load;
        :>> power = current * current * rdsOn;
    }

    /* ==== ICs =============================================================================== */

    abstract part def PoweredDevice :> Component {
        doc
        /*
         * A device powered from a rail. `averageCurrent` is what it draws on average: give the
         * active and sleep currents and the duty cycle (the active fraction of time), or set it
         * directly. Without a supply voltage of its own it runs at its rail's nominal voltage.
         */
        in port supply : PowerPort {
            :>> minimum = minSupplyVoltage;
            :>> maximum = maxSupplyVoltage;
            :>> current = averageCurrent;
        }
        attribute supplyVoltage : ElectricPotentialValue[0..1];
        attribute minSupplyVoltage : ElectricPotentialValue[0..1];
        attribute maxSupplyVoltage : ElectricPotentialValue[0..1];
        attribute activeCurrent : ElectricCurrentValue[0..1];
        attribute sleepCurrent : ElectricCurrentValue[0..1];
        attribute dutyCycle : Real[0..1];
        attribute averageCurrent : ElectricCurrentValue[0..1] = AverageCurrent(activeCurrent, sleepCurrent, dutyCycle);
        :>> power = supplyVoltage * averageCurrent;
    }

    part def Microcontroller :> PoweredDevice {
        attribute clockFrequency : FrequencyValue[0..1];
        attribute flash : StorageCapacityValue[0..1];
        attribute ram : StorageCapacityValue[0..1];
        attribute deepSleepCurrent : ElectricCurrentValue[0..1];
    }

    part def Sensor :> PoweredDevice;
    part def Radio :> PoweredDevice {
        attribute txCurrent : ElectricCurrentValue[0..1];
        attribute rxCurrent : ElectricCurrentValue[0..1];
    }

    part def OpAmp :> PoweredDevice {
        attribute gainBandwidth : FrequencyValue[0..1];
        attribute offsetVoltage : ElectricPotentialValue[0..1];
        attribute railToRail : Boolean[0..1];
    }

    part def Crystal :> Component {
        port x1 : Terminal;
        port x2 : Terminal;
        attribute frequency : FrequencyValue;
        attribute tolerancePpm : Real[0..1];
        attribute loadCapacitance : CapacitanceValue[0..1];
    }

    part def Oscillator :> PoweredDevice {
        attribute frequency : FrequencyValue;
        attribute tolerancePpm : Real[0..1];
    }

    part def BoardConnector :> Component {
        doc /* A board-level connector (header, socket). For harness connectors use Wiring::Connector. */
        attribute positions : Natural[0..1];
        attribute pitch : LengthValue[0..1];
        attribute ratedCurrent : ElectricCurrentValue[0..1];
    }

    /* ==== Calculations ====================================================================== */

    calc def AverageCurrent {
        doc /* Average of an active and a sleep current at a duty cycle (the active fraction of time). */
        in active : ElectricCurrentValue;
        in sleep : ElectricCurrentValue;
        in duty : Real;
        return : ElectricCurrentValue = active * duty + sleep * (1 - duty);
    }

    calc def BatteryLife {
        doc /* Time to empty: usable capacity (a fraction of the rated one) over the average current. */
        in capacity : ElectricChargeValue;
        in averageCurrent : ElectricCurrentValue;
        in usable : Real = 1;
        return : DurationValue = capacity * usable / averageCurrent;
    }

    calc def DividerOutput {
        in vin : ElectricPotentialValue;
        in r1 : ResistanceValue;
        in r2 : ResistanceValue;
        return : ElectricPotentialValue = vin * r2 / (r1 + r2);
    }

    calc def LedResistor {
        doc /* The series resistor that sets an LED's current from a supply. */
        in supply : ElectricPotentialValue;
        in forwardVoltage : ElectricPotentialValue;
        in current : ElectricCurrentValue;
        return : ResistanceValue = (supply - forwardVoltage) / current;
    }

    calc def RcTimeConstant {
        in r : ResistanceValue;
        in c : CapacitanceValue;
        return : DurationValue = r * c;
    }

    calc def RcCutoff {
        doc /* -3 dB frequency of an RC low-pass or high-pass filter. */
        in r : ResistanceValue;
        in c : CapacitanceValue;
        return : FrequencyValue = 1 / (2 * 3.141592653589793 * r * c);
    }

    calc def LinearDissipation {
        doc /* Heat in a linear regulator or series pass element. */
        in vin : ElectricPotentialValue;
        in vout : ElectricPotentialValue;
        in current : ElectricCurrentValue;
        return : PowerValue = (vin - vout) * current;
    }

    calc def TemperatureRise {
        doc /* Junction temperature rise: power times the junction-to-ambient thermal resistance. */
        in power : PowerValue;
        in thermalResistance : ThermalResistanceValue;
        return : TemperatureDifferenceValue = power * thermalResistance;
    }
}
