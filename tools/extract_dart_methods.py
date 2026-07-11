#!/usr/bin/env python3
"""Move explicitly named class methods into one-method Dart extensions."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

from split_dart_declarations import declaration_end, snake_case


def method_match(text: str, name: str) -> re.Match[str]:
    pattern = re.compile(
        rf"(?m)^  (?:(?:static|external|abstract)\s+)*"
        rf"[A-Za-z_][A-Za-z0-9_<>,?.\[\] ]*\s+{re.escape(name)}\s*\("
    )
    matches = list(pattern.finditer(text))
    if len(matches) != 1:
        raise ValueError(f"Expected one declaration of {name}, found {len(matches)}")
    return matches[0]


def body_brace(text: str, start: int) -> int:
    opening = text.find("(", start)
    depth = 0
    quote: str | None = None
    escaped = False
    for index in range(opening, len(text)):
        char = text[index]
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
        elif char in "'\"":
            quote = char
        elif char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                brace = text.find("{", index + 1)
                if brace < 0:
                    raise ValueError("Method has no block body")
                return brace
    raise ValueError("Unbalanced method parameters")


def extract(source: Path, names: list[str]) -> None:
    original = source.read_text(encoding="utf-8")
    owner = re.search(r"(?m)^class\s+(\w+)", original)
    part = re.search(r"(?m)^part\s+of\s+'([^']+)';", original)
    if not owner or not part:
        raise ValueError(f"Expected one class in a part file: {source}")
    parent = (source.parent / part.group(1)).resolve()
    ranges: list[tuple[str, int, int, str]] = []
    for name in names:
        match = method_match(original, name)
        end = declaration_end(original, body_brace(original, match.start()))
        while end < len(original) and original[end] in "\r\n":
            end += 1
        ranges.append((name, match.start(), end, original[match.start():end].strip()))
    ordered = sorted(ranges, key=lambda item: item[1])
    if any(a[2] > b[1] for a, b in zip(ordered, ordered[1:])):
        raise ValueError("Overlapping method ranges")

    outputs: list[tuple[Path, str]] = []
    owner_name = owner.group(1)
    for name, _, _, body in ranges:
        target = (source.parent / f"{source.stem}_{snake_case(name)}.dart").resolve()
        if target.exists():
            raise ValueError(f"Refusing to overwrite {target}")
        extension = f"_{owner_name.lstrip('_')}{''.join(p.title() for p in name.split('_'))}"
        outputs.append((target, f"part of '{part.group(1)}';\n\nextension {extension} on {owner_name} {{\n{body}\n}}\n"))

    remaining = original
    for _, start, end, _ in sorted(ranges, key=lambda item: item[1], reverse=True):
        remaining = remaining[:start] + remaining[end:]
    parent_text = parent.read_text(encoding="utf-8")
    directives = list(re.finditer(r"(?m)^part\s+'[^']+';\s*$", parent_text))
    insertion = directives[-1].end()
    additions = "\n" + "\n".join(
        f"part '{target.relative_to(parent.parent).as_posix()}';" for target, _ in outputs
    )
    source.write_text(remaining.rstrip() + "\n", encoding="utf-8")
    parent.write_text(parent_text[:insertion] + additions + parent_text[insertion:], encoding="utf-8")
    for target, content in outputs:
        target.write_text(content, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("methods", nargs="+")
    args = parser.parse_args()
    extract(args.source, args.methods)


if __name__ == "__main__":
    main()
