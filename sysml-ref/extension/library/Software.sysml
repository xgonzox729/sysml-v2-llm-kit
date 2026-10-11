standard library package Software {
    doc
    /*
     * Annotations for generating software from a model: how data is encoded in messages and
     * registers, and which values a build configuration exports. The data types themselves are
     * plain SysML: attribute, item and enumeration definitions.
     *
     * Usage:
     *   private import Software::*;
     *   item def Reading {
     *       attribute temperature : TemperatureValue { @Encoding { bits = 16; signed = true; scale = 0.01 [K]; } }
     *       attribute battery : ElectricPotentialValue { @Encoding { bits = 16; scale = 1 [mV]; } }
     *       attribute sequence : Natural { @Encoding { bits = 8; } }
     *   }
     *
     * Licensed under the MIT license (part of the SysML v2 VS Code extension).
     */

    private import ScalarValues::*;
    private import ISQ::DurationValue;
    private import ISQ::StorageCapacityValue;

    enum def ByteOrder {
        littleEndian;
        bigEndian;
    }

    metadata def Encoding {
        doc
        /*
         * How a value is represented in a message, packet or register.
         *   bits      the size of the field: 8, 16, 32 or 64 (Booleans take 8; Reals are IEEE
         *             floats of 32 bits unless 64 is given).
         *   signed    two's complement (default: false for Natural, quantities and enumerations,
         *             true for Integer).
         *   scale     what one count is worth: 1 [mV], 0.01 [K], 0.5. A quantity with a scale is
         *             sent as an integer count: count = (value - offset) / scale.
         *   offset    the value at count 0 (same kind as scale).
         *   maxLength the maximum length of a String (in bytes, without a terminator) or of a
         *             variable-length sequence ([0..*]). (Not `length`: ISQ::* imports one.)
         *   byteOrder on a definition: the byte order of all its fields (default little endian).
         *   code      on an enumeration literal: its number (default: its position, from 0).
         */
        attribute bits : Positive[0..1];
        attribute signed : Boolean[0..1];
        attribute scale[0..1];
        attribute offset[0..1];
        attribute maxLength : Positive[0..1];
        attribute byteOrder : ByteOrder[0..1];
        attribute code : Integer[0..1];
    }

    metadata def Config {
        doc
        /*
         * Exports the annotated attribute to the generated configuration header (and Kconfig),
         * with its value in each configuration of a variant model.
         *   name   the macro name, without the CONFIG_ prefix (default: from the attribute's path).
         *   scale  the unit of the exported number: 1 [ms] exports 2 [s] as 2000 (default: SI
         *          units; numbers are exported as they are).
         */
        attribute name : String[0..1];
        attribute scale[0..1];
    }

    /* ---- Firmware architecture, scheduling and memory ------------------------------------- */

    part def Processor {
        doc
        /*
         * Something that runs software: its cores and memory. Electronics::Microcontroller is
         * one too. Software components and tasks count against the processor they are part of
         * (at any depth):
         *   part mcu : Microcontroller {
         *       :>> flash = 256 [KiB]; :>> ram = 32 [KiB];
         *       part sampler : Task { :>> period = 100 [ms]; :>> wcet = 3 [ms]; :>> stack = 1 [KiB]; }
         *   }
         */
        attribute cores : Positive[0..1];
        attribute flash : StorageCapacityValue[0..1];
        attribute ram : StorageCapacityValue[0..1];
    }

    part def SoftwareComponent {
        doc /* A piece of firmware (driver, protocol stack, library) and the memory it takes. */
        attribute flash : StorageCapacityValue[0..1];
        attribute ram : StorageCapacityValue[0..1];
    }

    part def Task :> SoftwareComponent {
        doc
        /*
         * A periodic task (or an interrupt handler with its minimum inter-arrival time as the
         * period). Fixed-priority preemptive scheduling: response-time analysis checks that each
         * task finishes by its deadline, per core.
         *   period    time between releases
         *   wcet      worst-case execution time
         *   deadline  when it must have finished, after its release (default: the period)
         *   priority  higher runs first (default: rate monotonic, the shorter period first)
         *   core      the core it runs on (default 0)
         *   stack     its stack, counted as RAM
         */
        attribute period : DurationValue;
        attribute wcet : DurationValue;
        attribute deadline : DurationValue[0..1];
        attribute priority : Integer[0..1];
        attribute core : Natural[0..1];
        attribute stack : StorageCapacityValue[0..1];
    }

    calc def Utilization {
        doc /* The share of a processor (or of one of its cores) its tasks use: the sum of wcet / period. */
        in processor;
        in core : Natural[0..1];
        return : Real;
    }

    calc def ResponseTime {
        doc /* A task's worst-case response time (release to completion) under fixed priorities. */
        in task;
        return : DurationValue;
    }

    calc def FlashUsed {
        doc /* Flash taken by the software components and tasks of a processor. */
        in processor;
        return : StorageCapacityValue;
    }

    calc def RamUsed {
        doc /* RAM taken by the software components of a processor, with the tasks' stacks. */
        in processor;
        return : StorageCapacityValue;
    }

    /* ---- Timing of actions ---------------------------------------------------------------- */

    metadata def Timing {
        doc
        /*
         * How long an action takes (at worst). Latency(action) adds them up along the longest
         * path of an action flow, from its start to its end:
         *   action sample { @Timing { duration = 2 [ms]; } }
         */
        attribute duration : DurationValue;
    }

    calc def Latency {
        doc /* The longest (critical) path through an action flow: the sum of the @Timing durations along it. */
        in action;
        return : DurationValue;
    }

    /* ---- Traceability ---------------------------------------------------------------------- */

    metadata def Implements {
        doc
        /*
         * The source file (and optionally the function or class) that implements an element.
         * Paths are relative to the model file. Shown in the verification matrix and documents;
         * the path is a link in the editor.
         *   part sampler : Task { @Implements { file = "firmware/src/sampler.c"; symbol = "sampler_task"; } }
         */
        attribute file : String;
        attribute symbol : String[0..1];
    }

    metadata def VerifiedBy {
        doc
        /*
         * The test that verifies a requirement (or another element): a test file, optionally the
         * test case in it.
         *   requirement nodeLifetime : NodeLifetime { @VerifiedBy { file = "firmware/test/test_power.c"; test = "test_sleep_current"; } }
         */
        attribute file : String;
        attribute test : String[0..1];
    }
}
