#!/usr/bin/env python3
"""Move named top-level Dart functions into individual library parts."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

from extract_dart_methods import method_end
from split_dart_declarations import snake_case


def split(source: Path, names: list[str]) -> None:
    text = source.read_text(encoding="utf-8")
    ranges: list[tuple[str, int, int, str]] = []
    for name in names:
        match = re.search(
            rf"(?m)^(?:[A-Za-z_][A-Za-z0-9_<>,?.()\[\] ]*\s+)?{re.escape(name)}\s*\(",
            text,
        )
        if not match:
            raise ValueError(f"Top-level function not found: {name}")
        end = method_end(text, match.start())
        while end < len(text) and text[end] in "\r\n":
            end += 1
        ranges.append((name, match.start(), end, text[match.start():end].strip()))

    updated = text
    for _, start, end, _ in sorted(ranges, key=lambda item: item[1], reverse=True):
        updated = updated[:start] + updated[end:]

    directives = list(re.finditer(r"(?m)^part '[^']+';\n", updated))
    imports = list(re.finditer(r"(?m)^import [^;]+;\n", updated))
    insert_at = directives[-1].end() if directives else imports[-1].end() if imports else 0
    part_names = [f"{source.stem}_{snake_case(name)}.dart" for name, *_ in ranges]
    part_text = "".join(f"part '{name}';\n" for name in part_names)
    updated = updated[:insert_at] + part_text + updated[insert_at:]

    source.write_text(updated.rstrip() + "\n", encoding="utf-8")
    for (name, _, _, body), filename in zip(ranges, part_names):
        target = source.with_name(filename)
        if target.exists():
            raise ValueError(f"Refusing to overwrite {target}")
        target.write_text(f"part of '{source.name}';\n\n{body}\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("names", nargs="+")
    args = parser.parse_args()
    split(args.source, args.names)


if __name__ == "__main__":
    main()
