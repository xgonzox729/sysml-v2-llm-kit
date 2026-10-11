/* TMP117 driver (a stand-in: the model's @Implements points here). */
#include <stdint.h>
#include "../../generated/tmp117_regs.h"

int tmp117_read(uint16_t config, int16_t *raw) {
    /* One-shot conversion: set MOD to oneShot in the configuration register. */
    uint16_t value = TMP117_CONFIGURATION_MOD_SET(config, TMP117_CONFIGURATION_MOD_ONE_SHOT);
    (void)value;
    *raw = 0;
    return 0;
}
