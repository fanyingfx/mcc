#!/usr/bin/env python3
import subprocess
import sys
from pathlib import Path
import os
def main():
    cfile = None
    stage = "--compile"
    for arg in sys.argv[1:]:
        if arg.endswith('c'):
            cfile=Path(arg)
        if arg.startswith("--"):
            stage=arg
    preprocessed_src = str(cfile.with_suffix(".i"))
    asm_file= str(cfile.with_suffix(".asm"))
    obj_file= str(cfile.with_suffix(".o"))
    exe_name=str(cfile.with_suffix(""))

    #run preprocesser
    subprocess.run(["gcc","-E","-P",cfile,"-o",preprocessed_src])

    #compile to fasm
    subprocess.run(["moon","run", "-C","/home/fan/code/moonbit/mcc/","src/main","--",preprocessed_src,stage],check=True)


    if stage == "--compile":
        subprocess.run(["fasm",asm_file],check=True)
        subprocess.run(["ld",str(obj_file),"-dynamic-linker","/usr/lib/ld-linux-x86-64.so.2" ,"-lc" , "-o",exe_name],stdout=subprocess.DEVNULL,check=True)
    # if Path(asm_file).exists():
    #     os.remove(asm_file)
    if Path(preprocessed_src).exists():
        os.remove(preprocessed_src)


if __name__ == "__main__":
    main()