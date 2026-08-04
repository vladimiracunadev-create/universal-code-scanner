#!/usr/bin/env python3
from __future__ import annotations
import hashlib, sys
from pathlib import Path
files=[Path(value) for value in sys.argv[1:] if Path(value).is_file()]
for path in files:
    digest=hashlib.sha256(path.read_bytes()).hexdigest()
    print(f"{digest}  {path}")
