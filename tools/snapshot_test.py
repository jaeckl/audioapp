#!/usr/bin/env python3
"""Snapshot the device_chain_test output to a file for later comparison.
Used to verify behavior is byte-identical between SRP refactor steps."""

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXE = ROOT / "build" / "engine" / "test_gate" / "device_chain_test.exe"


def main():
    if not EXE.exists():
        print(f"build first: python tools/step_gate.py")
        return 1
    out_path = Path(sys.argv[1] if len(sys.argv) > 1 else "build/engine/test_gate/baseline.txt")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    r = subprocess.run(str(EXE), capture_output=True, text=True, encoding="utf-8", errors="replace")
    output = r.stdout + r.stderr
    # Keep only the lines that prove the test passed/failed (drop MSVC leak dump).
    lines = []
    for line in output.splitlines():
        if line.startswith("{"):
            continue
        if line.startswith(" Data: <"):
            continue
        if line.startswith("Detected memory leaks!"):
            continue
        if line.startswith("Dumping objects"):
            continue
        if line.startswith("Object dump complete"):
            continue
        if line.strip() == "":
            continue
        lines.append(line)
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"snapshot: {out_path} ({len(lines)} lines)")
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())