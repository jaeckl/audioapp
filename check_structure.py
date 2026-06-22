#!/usr/bin/env python3
import re, os, glob

# Concatenate all family + umbrella files
files = glob.glob(r"C:\Users\ludwi\Desktop\audioapp\app_flutter\lib\bridge\device_families\*.dart")
files.append(r"C:\Users\ludwi\Desktop\audioapp\app_flutter\lib\bridge\device_snapshots.dart")
text = ""
for p in files:
    with open(p, "r", encoding="utf-8") as f:
        text += f.read() + "\n"

# Extract leaf class declarations (those that extend something)
leaves = re.findall(r"(?:^|\n)class\s+(\w+)\s+extends", text)
print(f"Leaf classes (extends X): {len(leaves)}")
for c in sorted(set(leaves)):
    print(f"  {c}")

# Sealed bases
sealeds = re.findall(r"(?:^|\n)sealed\s+class\s+(\w+)", text)
print(f"\nSealed base classes: {len(sealeds)}")
for c in sorted(set(sealeds)):
    print(f"  {c}")

# 'type:' string literals used in super(type: '...')
types = re.findall(r"super\(type:\s*'([^']+)'\)", text)
print(f"\ntype: literals in super(): {len(types)}")
for t in sorted(set(types)):
    print(f"  '{t}'")

# Check helpers aren't orphaned in umbrella
umbrella = open(r"C:\Users\ludwi\Desktop\audioapp\app_flutter\lib\bridge\device_snapshots.dart", "r", encoding="utf-8").read()
print("\n--- Umbrella content sanity ---")
for h in ["readBypass", "readOscShape", "deriveOscMixFromLegacyLevels", "readCymbalColor", "readCrashColor"]:
    n = umbrella.count(h)
    print(f"  {h}: {n}")

# Field-name spot check
print("\n--- Spot-check tricky fields ---")
for fld in ["snareSnares", "kickPitch", "cymbalColor", "crashColor", "ffxBand1Freq", "ffxShift", "subtractiveSynthCutoff", "compThreshold"]:
    n = text.count(fld)
    print(f"  {fld}: {n} occurrences")