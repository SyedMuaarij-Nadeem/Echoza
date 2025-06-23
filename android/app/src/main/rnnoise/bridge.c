#include "rnnoise.h"
#include <stdint.h>

DenoiseState* rnnoise_create_wrapper() {
    return rnnoise_create(NULL);
}

void rnnoise_destroy_wrapper(DenoiseState* st) {
    rnnoise_destroy(st);
}

int rnnoise_process_wrapper(DenoiseState* st, float* out, const float* in) {
    return rnnoise_process_frame(st, out, in);
}
