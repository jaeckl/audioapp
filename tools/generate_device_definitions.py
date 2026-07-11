#!/usr/bin/env python3
"""Generate the Flutter device-definition index from owned annotations."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEVICE_ROOT = ROOT / "app_flutter" / "lib" / "devices"
OUTPUT = DEVICE_ROOT / "generated_device_definitions.dart"
PATTERN = re.compile(
    r"@AudioDeviceDefinition\('([^']+)'\)\s+"
    r"final\s+class\s+(\w+)\s+(?:implements\s+DeviceDefinition|"
    r"extends\s+AudioEffectDefinition)"
)


def discover() -> list[tuple[str, str, Path]]:
    found: list[tuple[str, str, Path]] = []
    for path in sorted(DEVICE_ROOT.rglob("*_definition.dart")):
        if "definition" in path.parts[-2:]:
            continue
        text = path.read_text(encoding="utf-8")
        for type_id, class_name in PATTERN.findall(text):
            found.append((type_id, class_name, path))
    ids = [item[0] for item in found]
    if len(ids) != len(set(ids)):
        raise SystemExit("Duplicate @AudioDeviceDefinition type ID")
    return found


def render(found: list[tuple[str, str, Path]]) -> str:
    imports = []
    instances = []
    for _, class_name, path in found:
        relative = path.relative_to(DEVICE_ROOT).as_posix()
        imports.append(f"import '{relative}';")
        instances.append(f"  {class_name}(),")
    return "\n".join(
        [
            "// GENERATED FILE. Run tools/generate_device_definitions.py.",
            "// ignore_for_file: directives_ordering",
            "",
            "import '../bridge/project_snapshot.dart';",
            "import 'definition/device_definition.dart';",
            *imports,
            "",
            "final List<DeviceDefinition<DeviceSnapshot>> generatedDeviceDefinitions = [",
            *instances,
            "];",
            "",
        ]
    )


def main() -> None:
    OUTPUT.write_text(render(discover()), encoding="utf-8")
    print(f"Generated {OUTPUT}")


if __name__ == "__main__":
    main()
