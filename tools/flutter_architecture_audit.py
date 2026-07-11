#!/usr/bin/env python3
"""Enforce incremental Flutter source-architecture constraints."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "app_flutter" / "lib"
DEFAULT_BASELINE = ROOT / "tools" / "flutter_architecture_baseline.json"
MAX_LINES = 300

DECLARATION = re.compile(
    r"^\s*(?:(?:abstract|base|final|interface|sealed)\s+)*"
    r"(?:class|mixin|enum|extension(?:\s+type)?)\s+([A-Za-z_]\w*)",
    re.MULTILINE,
)
SPECIAL_DECLARATION = re.compile(
    r"^\s*(?:(?:abstract|base|final|interface|sealed)\s+)*class\s+"
    r"([A-Za-z_]\w*)[^\n]*(?:extends|implements)\s+"
    r"(?:CustomPainter|CustomClipper|RenderBox|RenderObject|Sliver|FlowDelegate)",
    re.MULTILINE,
)

# These are registration/catalog ownership smells. Existing occurrences are
# baselined; new occurrences or count increases fail the audit.
CENTRAL_REGISTRATION = re.compile(
    r"(?<!factory )(?<![A-Za-z])DeviceSnapshot\.fromMap|forDeviceType\s*\(|filterForDeviceType\s*\(|"
    r"knobsForModelIndex\s*\(|register(?:All|Type|Factory|Device|Panel)\s*\(",
)


@dataclass(frozen=True)
class Metrics:
    lines: int
    declarations: int
    special_declarations: int
    central_registrations: int


def scan(source_root: Path = SOURCE_ROOT) -> dict[str, Metrics]:
    result: dict[str, Metrics] = {}
    for path in sorted(source_root.rglob("*.dart")):
        text = path.read_text(encoding="utf-8")
        relative = path.relative_to(source_root).as_posix()
        result[relative] = Metrics(
            lines=len(text.splitlines()),
            declarations=len(DECLARATION.findall(text)),
            special_declarations=len(SPECIAL_DECLARATION.findall(text)),
            central_registrations=len(CENTRAL_REGISTRATION.findall(text)),
        )
    return result


def violations(metrics: dict[str, Metrics]) -> dict[str, dict[str, int]]:
    result: dict[str, dict[str, int]] = {}
    for path, item in metrics.items():
        values: dict[str, int] = {}
        if item.lines > MAX_LINES:
            values["lines"] = item.lines
        if item.declarations > 1:
            values["declarations"] = item.declarations
        # A special declaration must be alone in its file. A file containing
        # only one painter/renderer is compliant and is not baselined.
        if item.special_declarations and item.declarations > 1:
            values["embedded_special_declarations"] = item.special_declarations
        if item.central_registrations:
            values["central_registrations"] = item.central_registrations
        if values:
            result[path] = values
    return result


def load_baseline(path: Path) -> dict[str, dict[str, int]]:
    if not path.exists():
        raise SystemExit(f"Missing architecture baseline: {path}")
    raw = json.loads(path.read_text(encoding="utf-8"))
    return raw["violations"]


def regressions(
    current: dict[str, dict[str, int]], baseline: dict[str, dict[str, int]]
) -> list[str]:
    failures: list[str] = []
    for path, rules in current.items():
        previous = baseline.get(path, {})
        for rule, value in rules.items():
            allowed = previous.get(rule, 0)
            if value > allowed:
                failures.append(f"{path}: {rule}={value}, baseline={allowed}")
    return failures


def write_baseline(path: Path, metrics: dict[str, Metrics]) -> None:
    payload = {
        "maxLines": MAX_LINES,
        "violations": violations(metrics),
        "summary": {
            "files": len(metrics),
            "lines": sum(item.lines for item in metrics.values()),
            "declarations": sum(item.declarations for item in metrics.values()),
        },
    }
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-root", type=Path, default=SOURCE_ROOT)
    parser.add_argument("--baseline", type=Path, default=DEFAULT_BASELINE)
    parser.add_argument("--write-baseline", action="store_true")
    args = parser.parse_args(argv)

    metrics = scan(args.source_root)
    if args.write_baseline:
        write_baseline(args.baseline, metrics)
        print(f"Wrote Flutter architecture baseline: {args.baseline}")
        return 0

    current = violations(metrics)
    failures = regressions(current, load_baseline(args.baseline))
    if failures:
        print("Flutter architecture regressions:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1
    print(
        f"Flutter architecture audit passed: {len(metrics)} files, "
        f"{len(current)} baselined violation files"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
