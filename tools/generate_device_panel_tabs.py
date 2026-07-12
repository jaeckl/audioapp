#!/usr/bin/env python3
"""Generate device panel-tab registration from panel-owned type metadata."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

from split_dart_declarations import DECLARATION, declaration_end

ROOT = Path(__file__).resolve().parents[1]
PANEL_ROOT = ROOT / "app_flutter" / "lib" / "features" / "device_strip"
LEGACY = PANEL_ROOT / "device_container_tabs.dart"
OUTPUT = PANEL_ROOT / "generated_device_panel_tabs.dart"

REGISTRATION = re.compile(
    r"(?P<types>'[^']+'(?:\s*\|\|\s*'[^']+')*)\s*=>\s*"
    r"(?P<class>[A-Za-z_]\w*)\.containerTabs,"
)
TYPE_LIST = re.compile(
    r"static const registeredDeviceTypes\s*=\s*\[(?P<types>[^]]*)\];"
)


def dart_classes() -> list[tuple[Path, str, int, int]]:
    result: list[tuple[Path, str, int, int]] = []
    for path in sorted(PANEL_ROOT.rglob("*.dart")):
        text = path.read_text(encoding="utf-8")
        for match in DECLARATION.finditer(text):
            prefix = text[match.start() : match.start() + 40]
            if "class" not in prefix:
                continue
            result.append((path, match.group(1), match.start(), declaration_end(text, match.start())))
    return result


def migrate() -> None:
    legacy = LEGACY.read_text(encoding="utf-8")
    classes = dart_classes()
    by_name = {name: (path, start, end) for path, name, start, end in classes}
    for match in REGISTRATION.finditer(legacy):
        class_name = match.group("class")
        type_ids = re.findall(r"'([^']+)'", match.group("types"))
        if class_name not in by_name:
            raise ValueError(f"Panel class not found: {class_name}")
        path, start, end = by_name[class_name]
        text = path.read_text(encoding="utf-8")
        body = text[start:end]
        if "registeredDeviceTypes" in body:
            continue
        brace = text.find("{", start, end)
        values = ", ".join(repr(type_id) for type_id in type_ids)
        text = text[: brace + 1] + f"\n  static const registeredDeviceTypes = [{values}];" + text[brace + 1 :]
        path.write_text(text, encoding="utf-8")


def library_for(path: Path) -> Path:
    text = path.read_text(encoding="utf-8")
    part = re.search(r"(?m)^part of '([^']+)';", text)
    return (path.parent / part.group(1)).resolve() if part else path.resolve()


def generate() -> None:
    registrations: list[tuple[str, str, Path]] = []
    for path, class_name, start, end in dart_classes():
        text = path.read_text(encoding="utf-8")
        owned = TYPE_LIST.search(text[start:end])
        if not owned:
            continue
        for type_id in re.findall(r"'([^']+)'", owned.group("types")):
            registrations.append((type_id, class_name, library_for(path)))
    registrations.sort()
    if not registrations:
        raise ValueError("No panel-owned registrations found")
    duplicate_ids = {item for item in (r[0] for r in registrations) if sum(x[0] == item for x in registrations) > 1}
    if duplicate_ids:
        raise ValueError(f"Duplicate device panel registrations: {sorted(duplicate_ids)}")

    libraries = sorted({library for _, _, library in registrations})
    imports = "".join(
        f"import '{library.relative_to(PANEL_ROOT).as_posix()}';\n"
        for library in libraries
    )
    entries = "".join(
        f"  '{type_id}': {class_name}.containerTabs,\n"
        for type_id, class_name, _ in registrations
    )
    OUTPUT.write_text(
        "// GENERATED FILE. Run tools/generate_device_panel_tabs.py.\n"
        "// ignore_for_file: directives_ordering\n\n"
        "import 'device_tab_bar.dart';\n"
        f"{imports}\n"
        "final Map<String, List<DeviceTabSpec>> generatedDevicePanelTabs = {\n"
        f"{entries}}};\n",
        encoding="utf-8",
    )
    print(f"Generated {len(registrations)} device panel-tab registrations")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--migrate", action="store_true")
    args = parser.parse_args()
    if args.migrate:
        migrate()
    generate()


if __name__ == "__main__":
    main()
