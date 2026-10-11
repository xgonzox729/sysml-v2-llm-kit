standard library package EngineeringUnits {
    doc
    /*
     * Units that electrical, electronic and software engineers use every day but that the SI
     * library does not predefine: prefixed volts, amperes, ohms, watts, farads, henries and
     * hertz, short durations, battery charge and energy (mAh, Wh), data sizes and rates.
     *
     * Each unit is defined from an SI unit (a prefix or a conversion factor), so the evaluator
     * converts between all of them.
     *
     * Usage:
     *   private import SI::*;
     *   private import EngineeringUnits::*;
     *   attribute sleepCurrent : ElectricCurrentValue = 3.5 ['µA'];   // µ is not an identifier letter: quote it
     *   attribute capacity : ElectricChargeValue = 2400 [mAh];
     *
     * Licensed under the MIT license (part of the SysML v2 VS Code extension).
     */

    private import MeasurementReferences::*;
    private import SI::*;

    /* ---- Electric potential, current, resistance, power -------------------------------- */
    attribute <'µV'> microvolt : ElectricPotentialUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = micro; :>> referenceUnit = V; } }
    attribute <mV> millivolt : ElectricPotentialUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = milli; :>> referenceUnit = V; } }
    attribute <kV> kilovolt : ElectricPotentialUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = kilo; :>> referenceUnit = V; } }
    attribute <nA> nanoampere : ElectricCurrentUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = nano; :>> referenceUnit = A; } }
    attribute <'µA'> microampere : ElectricCurrentUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = micro; :>> referenceUnit = A; } }
    attribute <mA> milliampere : ElectricCurrentUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = milli; :>> referenceUnit = A; } }
    attribute <'mΩ'> milliohm : ResistanceUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = milli; :>> referenceUnit = 'Ω'; } }
    attribute <'kΩ'> kiloohm : ResistanceUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = kilo; :>> referenceUnit = 'Ω'; } }
    attribute <'MΩ'> megaohm : ResistanceUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = mega; :>> referenceUnit = 'Ω'; } }
    attribute <'µW'> microwatt : PowerUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = micro; :>> referenceUnit = W; } }
    attribute <mW> milliwatt : PowerUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = milli; :>> referenceUnit = W; } }
    attribute <kW> kilowatt : PowerUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = kilo; :>> referenceUnit = W; } }

    /* ---- Capacitance, inductance, frequency ------------------------------------------- */
    attribute <pF> picofarad : CapacitanceUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = pico; :>> referenceUnit = F; } }
    attribute <nF> nanofarad : CapacitanceUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = nano; :>> referenceUnit = F; } }
    attribute <'µF'> microfarad : CapacitanceUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = micro; :>> referenceUnit = F; } }
    attribute <mF> millifarad : CapacitanceUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = milli; :>> referenceUnit = F; } }
    attribute <nH> nanohenry : InductanceUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = nano; :>> referenceUnit = H; } }
    attribute <'µH'> microhenry : InductanceUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = micro; :>> referenceUnit = H; } }
    attribute <mH> millihenry : InductanceUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = milli; :>> referenceUnit = H; } }
    attribute <kHz> kilohertz : FrequencyUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = kilo; :>> referenceUnit = Hz; } }
    attribute <MHz> megahertz : FrequencyUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = mega; :>> referenceUnit = Hz; } }
    attribute <GHz> gigahertz : FrequencyUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = giga; :>> referenceUnit = Hz; } }

    /* ---- Time ------------------------------------------------------------------------- */
    attribute <ns> nanosecond : DurationUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = nano; :>> referenceUnit = s; } }
    attribute <'µs'> microsecond : DurationUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = micro; :>> referenceUnit = s; } }
    attribute <ms> millisecond : DurationUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = milli; :>> referenceUnit = s; } }
    attribute <wk> week : DurationUnit { :>> unitConversion: ConversionByConvention { :>> referenceUnit = d; :>> conversionFactor = 7; } }
    attribute <yr> year : DurationUnit {
        doc /* A Julian year (365.25 days), the usual basis for battery life figures. */
        :>> unitConversion: ConversionByConvention { :>> referenceUnit = d; :>> conversionFactor = 365.25; }
    }

    /* ---- Battery charge and energy --------------------------------------------------- */
    attribute <Ah> 'ampere hour' : ElectricChargeUnit = A*h;
    attribute <mAh> 'milliampere hour' : ElectricChargeUnit = mA*h;
    attribute <'µAh'> 'microampere hour' : ElectricChargeUnit = 'µA'*h;
    attribute <Wh> 'watt hour' : EnergyUnit = W*h;
    attribute <mWh> 'milliwatt hour' : EnergyUnit = mW*h;
    attribute <kWh> 'kilowatt hour' : EnergyUnit = kW*h;
    attribute <mJ> millijoule : EnergyUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = milli; :>> referenceUnit = J; } }
    attribute <'µJ'> microjoule : EnergyUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = micro; :>> referenceUnit = J; } }

    /* ---- Lengths ---------------------------------------------------------------------- */
    attribute <cm> centimetre : LengthUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = centi; :>> referenceUnit = m; } }
    attribute <'µm'> micrometre : LengthUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = micro; :>> referenceUnit = m; } }
    attribute <mil> mil : LengthUnit {
        doc /* A thousandth of an inch (PCB trace widths and clearances). */
        :>> unitConversion: ConversionByConvention { :>> referenceUnit = m; :>> conversionFactor = 0.0000254; }
    }

    /* ---- Data sizes and rates (bytes have a dimension of their own in evaluation) ------- */
    attribute <KiB> kibibyte : StorageCapacityUnit { :>> unitConversion: ConversionByConvention { :>> referenceUnit = B; :>> conversionFactor = 1024; } }
    attribute <MiB> mebibyte : StorageCapacityUnit { :>> unitConversion: ConversionByConvention { :>> referenceUnit = B; :>> conversionFactor = 1048576; } }
    attribute <kB> kilobyte : StorageCapacityUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = kilo; :>> referenceUnit = B; } }
    attribute <MB> megabyte : StorageCapacityUnit { :>> unitConversion: ConversionByPrefix { :>> prefix = mega; :>> referenceUnit = B; } }
    attribute <'kbit/s'> 'kilobit per second' : BinaryDigitRateUnit = 1000 * 'bit/s';
    attribute <'Mbit/s'> 'megabit per second' : BinaryDigitRateUnit = 1000000 * 'bit/s';

    /* ---- The same micro units spelled with the Greek letter mu (μ, as SI prefixes use) --- */
    alias 'μV' for 'µV';
    alias 'μA' for 'µA';
    alias 'μW' for 'µW';
    alias 'μF' for 'µF';
    alias 'μH' for 'µH';
    alias 'μs' for 'µs';
    alias 'μAh' for 'µAh';
    alias 'μJ' for 'µJ';
    alias 'μm' for 'µm';
}
