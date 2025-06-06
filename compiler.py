#!/usr/bin/env python3
import subprocess
import sys
from pathlib import Path


def compile():
    # print("args:",sys.argv[1:],file=sys.stderr)
    cfile = None
    stage = "--compile"
    compiled_to_exe=True
    for arg in sys.argv[1:]:
        if arg=="-c":
            compiled_to_exe=False
        elif arg.endswith("c"):
            cfile = Path(arg)
        elif arg.startswith("--"):
            stage = arg
    preprocessed_src = cfile.with_suffix(".i")
    asm_file = cfile.with_suffix(".asm")
    obj_file = cfile.with_suffix(".o")
    exe_name = cfile.with_suffix("")

    # run preprocesser
    subprocess.run(["gcc", "-E", "-P", str(cfile), "-o", str(preprocessed_src)])

    # compile to fasm
    subprocess.run(
        [
            "moon",
            "run",
            "--debug",
            "-C",
            "/home/fan/code/moonbit/mcc/",
            "src/main",
            "--",
            str(preprocessed_src),
            stage,
        ],
        check=True,
    )

    if stage == "--compile":
        subprocess.run(["fasm", str(asm_file)], check=True)
        if compiled_to_exe: 
            subprocess.run(
                [
                    "ld",
                    "/usr/lib/crt1.o",
                    str(obj_file),
                    "-dynamic-linker",
                    "/usr/lib/ld-linux-x86-64.so.2",
                    "-lc",
                    "-o",
                    str(exe_name),
                ],
                stdout=subprocess.DEVNULL,
                check=True,
            )
    # preprocessed_src.unlink(True)
    # asm_file.unlink(True)
    # obj_file.unlink(True)


if __name__ == "__main__":
    compile()
