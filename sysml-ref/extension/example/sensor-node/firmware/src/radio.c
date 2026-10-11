/* The radio task: encodes a reading for the uplink (a stand-in: the model's @Implements points here). */
#include "../../generated/node_icd_types.h"

size_t radio_task(const reading_t *reading, uint8_t *frame, size_t size) {
    return reading_encode(reading, frame, size);
}
