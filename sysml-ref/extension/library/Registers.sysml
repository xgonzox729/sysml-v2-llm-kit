standard library package Registers {
    doc
    /*
     * Register maps of devices and peripherals: a block of registers (at a base address), each
     * with an offset, a size, an access type and a reset value, divided into bit fields. The
     * code generator writes a C header with the addresses, masks, shifts and reset values, and
     * the documents get a register table.
     *
     * Usage (SysML has no hexadecimal literals: write numbers in decimal, or as a string
     * "0x0220" or "0b0010"):
     *   part def TMP117 {
     *       part <TMP117> registers : RegisterBlock {
     *           :>> registerBits = 16;
     *           part <TEMP_RESULT> temperature : Register { :>> offset = 0; :>> access = Access::readOnly; :>> resetValue = "0x8000"; }
     *           part <CONFIGURATION> configuration : Register {
     *               :>> offset = 1;
     *               :>> resetValue = "0x0220";
     *               part <MOD> mode : Field {
     *                   :>> lsb = 10; :>> width = 2;
     *                   // Named values of the field: attributes with a number.
     *                   attribute continuous = 0; attribute shutdown = 1; attribute oneShot = 3;
     *               }
     *           }
     *       }
     *   }
     * Short names (<TEMP_RESULT>) name the C macros; without one the name is used.
     *
     * Licensed under the MIT license (part of the SysML v2 VS Code extension).
     */

    private import ScalarValues::*;

    enum def Access {
        readWrite;
        readOnly;
        writeOnly;
        /* Writing 1 to a bit clears it. */
        write1ToClear;
        /* Reading clears the register. */
        readToClear;
    }

    part def RegisterBlock {
        doc /* A block of registers, e.g. a device on a bus or a peripheral in memory. */
        /* The address of offset 0: a number or a string ("0x40021000"). */
        attribute baseAddress default 0;
        /* The size of registers that do not give their own, in bits. */
        attribute registerBits : Positive default 8;
        part registers : Register[0..*];
    }

    part def Register {
        /* The register's address relative to the block: a number or a string ("0x1C"). */
        attribute offset;
        /* Size in bits (default: the block's registerBits). */
        attribute bits : Positive[0..1];
        attribute access : Access default Access::readWrite;
        /* Value after reset: a number or a string ("0x0220", "0b1010"). */
        attribute resetValue default 0;
        part fields : Field[0..*];
    }

    part def Field {
        doc /* Bits lsb .. lsb + width - 1 of a register. Attributes with a number are its named values. */
        attribute lsb : Natural;
        attribute width : Positive default 1;
        /* Default: the register's access. */
        attribute access : Access[0..1];
    }
}
