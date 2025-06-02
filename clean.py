#!/usr/bin/python3
from pathlib import Path
import sys
if len(sys.argv)<2:
    raise ValueError("Not enought arguments")
path = Path(sys.argv[1])
for file in path.iterdir():
    if not file.name.endswith(".c"):
        file.unlink()