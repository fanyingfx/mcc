#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <errno.h>
#include "moonbit.h"
int system_execv(const char *path, char *const argv[]);

MOONBIT_FFI_EXPORT int32_t run_cmd(moonbit_bytes_t cmd) {

    return system(cmd);
}
MOONBIT_FFI_EXPORT void preprocess(moonbit_bytes_t c_filename,moonbit_bytes_t processed_filename){
    char*args[]={"gcc","-E","-P",c_filename,"-o",processed_filename,NULL};
    if (system_execv("/usr/bin/gcc",args)!=0) exit(1);
}

MOONBIT_FFI_EXPORT void fasm(moonbit_bytes_t asm_filename){
    char*args[]={"fasm",asm_filename,NULL};
    if(system_execv("/usr/bin/fasm",args)!=0) exit(1);
}

int system_execv(const char *path, char *const argv[]) {
    pid_t pid = fork(); 
    if (pid < 0) {
        return -1;
    } else if (pid == 0) {
        execv(path, argv); 
        exit(EXIT_FAILURE); 
    } else {
        int status;
        if (waitpid(pid, &status, 0) == -1) {
            return -1;
        }
        if (WIFEXITED(status)) {
            return WEXITSTATUS(status);
        }
        return -1;
    }
}