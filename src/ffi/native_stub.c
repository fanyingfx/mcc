#include <stdlib.h>
#include "moonbit.h"

MOONBIT_FFI_EXPORT int32_t run_cmd(moonbit_bytes_t cmd) {

    return system(cmd);
}