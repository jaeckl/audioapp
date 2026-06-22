#!/usr/bin/env python3
"""Compile + link + run a single engine test file as a gate for the
iterative DeviceChain split. Uses MSVC via vcvars64.bat + response file."""

import json
import os
import subprocess
import sys
from pathlib import Path

VCVARS = r"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
ROOT = Path(__file__).resolve().parent.parent
COMPILE_DB = ROOT / "build" / "engine" / "compile_commands.json"
GATE_DIR = ROOT / "build" / "engine" / "test_gate"
LIB = ROOT / "build" / "engine" / "audioapp_engine.lib"


def run(cmd, **kwargs):
    print(f"\n>>> {cmd[:200]}{'...' if len(cmd) > 200 else ''}")
    r = subprocess.run(cmd, shell=True, capture_output=True, text=True, **kwargs)
    if r.stdout:
        print(r.stdout[-2000:])
    if r.stderr:
        print(r.stderr[-2000:], file=sys.stderr)
    return r.returncode


def find_entry(test_name):
    db = json.loads(COMPILE_DB.read_text())
    for entry in db:
        if entry["file"].endswith(f"{test_name}.cpp"):
            return entry
    raise SystemExit(f"no entry for {test_name}.cpp in compile_commands.json")


def main(test_name="device_chain_test"):
    GATE_DIR.mkdir(parents=True, exist_ok=True)
    for old in GATE_DIR.glob(f"{test_name}.*"):
        old.unlink()

    entry = find_entry(test_name)
    cmd = entry["command"]
    print(f"compile command length: {len(cmd)}")
    print(f"first 200: {cmd[:200]}")

    # The original cmd includes /c and the source path. Build an rsp with
    # one flag per line, drop -c, drop the source path, drop /Fo /Fd, then
    # add explicit /c, /Fo, and BOTH source paths (test + JuceTestRunner).
    rsp_path = GATE_DIR / f"{test_name}.rsp"
    src = entry["file"]
    runner = str(ROOT / "engine_juce" / "tests" / "JuceTestRunner.cpp")
    obj = str(GATE_DIR / f"{test_name}.obj")
    parts = []
    for tok in cmd.split():
        if tok.lower().endswith("cl.exe") or tok.lower() == "cl.exe":
            continue
        if tok == "/c":
            continue
        if tok.startswith("/Fo"):
            continue
        if tok.startswith("/Fd"):
            continue
        if tok.endswith(".cpp") and tok == src:
            continue
        if tok == "-c":
            continue
        parts.append(tok)
    parts.append("/c")
    # /Fo as a directory sends both source objs there.
    # No closing quote — cl's rsp parser strips it.
    parts.append(f'/Fo"{GATE_DIR}\\')
    parts.append(f'"{src}"')
    parts.append(f'"{runner}"')

    rsp_path.write_text("\n".join(parts), encoding="ascii")
    print(f"rsp has {len(parts)} tokens")

    # Compile via cl @rsp inside vcvars64.
    bat = GATE_DIR / "compile.bat"
    bat.write_text(f'@echo off\ncall "{VCVARS}" >nul 2>&1\ncl.exe @"{rsp_path}"\n', encoding="ascii")
    rc = run(f'cmd /c "{bat}"')
    if rc != 0 or not Path(obj).exists():
        print(f"COMPILE FAILED (rc={rc})")
        return rc or 1

    # Link with kernel32 + user32 (JuceTestRunner / juce_events needs them).
    exe = GATE_DIR / f"{test_name}.exe"
    obj_base = GATE_DIR / f"{test_name}.obj"
    runner_obj = GATE_DIR / "JuceTestRunner.obj"
    link_bat = GATE_DIR / "link.bat"
    link_bat.write_text(
        f'@echo off\ncall "{VCVARS}" >nul 2>&1\n'
        f'link.exe /nologo /SUBSYSTEM:CONSOLE /OUT:"{exe}" '
        f'"{obj_base}" "{runner_obj}" "{LIB}" '
        f'kernel32.lib user32.lib shell32.lib ole32.lib oleaut32.lib '
        f'propsys.lib advapi32.lib comdlg32.lib winspool.lib uuid.lib\n',
        encoding="ascii",
    )
    rc = run(f'cmd /c "{link_bat}"')
    if rc != 0 or not exe.exists():
        print(f"LINK FAILED (rc={rc})")
        return rc or 1

    # Run the test.
    print(f"\n=== run {exe} ===")
    r = subprocess.run(str(exe), capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.stdout:
        # Filter out MSVC debug CRT leak dump at exit; keep test-relevant lines.
        out = r.stdout
        # Truncate the long leak report tail (starts at "Object dump complete").
        if "Object dump complete." in out:
            idx = out.find("Object dump complete.")
            out = out[: idx + len("Object dump complete.")] + "\n[... leak dump truncated ...]"
        print(out[-3000:])
    if r.stderr:
        print(r.stderr[-3000:], file=sys.stderr)
    print(f"\nexit: {r.returncode}")
    return r.returncode


if __name__ == "__main__":
    name = sys.argv[1] if len(sys.argv) > 1 else "device_chain_test"
    sys.exit(main(name))