#!/usr/bin/env python3
"""Mechanically split top-level Dart declarations into library part files."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

DECLARATION = re.compile(
    r"(?m)^(?:(?:abstract|base|final|interface|sealed)\s+)?"
    r"(?:class|enum|mixin|extension\s+type)\s+([A-Za-z_]\w*)"
)


def snake_case(name: str) -> str:
    name = name.lstrip("_")
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()


def declaration_end(text: str, start: int) -> int:
    brace = text.find("{", start)
    if brace < 0:
        raise ValueError("Declaration has no body")
    depth = 0
    quote: str | None = None
    line_comment = False
    block_comment = False
    escaped = False
    index = brace
    while index < len(text):
        char = text[index]
        following = text[index + 1] if index + 1 < len(text) else ""
        if line_comment:
            if char == "\n":
                line_comment = False
        elif block_comment:
            if char == "*" and following == "/":
                block_comment = False
                index += 1
        elif quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
        elif char == "/" and following == "/":
            line_comment = True
            index += 1
        elif char == "/" and following == "*":
            block_comment = True
            index += 1
        elif char in "'\"":
            quote = char
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return index + 1
        index += 1
    raise ValueError("Unbalanced declaration body")


def split(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    if re.search(r"(?m)^part\s+of\s+", text):
        raise ValueError(f"Cannot split an existing part file: {path}")
    matches = list(DECLARATION.finditer(text))
    if len(matches) < 2:
        return

    keeper = next(
        (match for match in matches if snake_case(match.group(1)) == path.stem),
        matches[0],
    )
    extracted: list[tuple[str, str, int, int]] = []
    used_names: set[str] = set()
    for match in matches:
        if match is keeper:
            continue
        name = match.group(1)
        filename = snake_case(name) + ".dart"
        if filename in used_names:
            raise ValueError(f"Part filename collision in {path}: {filename}")
        used_names.add(filename)
        end = declaration_end(text, match.start())
        while end < len(text) and text[end] in " \t\r\n":
            end += 1
        extracted.append((name, filename, match.start(), end))

    remaining = text
    for _, _, start, end in reversed(extracted):
        remaining = remaining[:start] + remaining[end:]

    directive_matches = list(
        re.finditer(r"(?m)^(?:import|export|part)\s+[^;]+;\s*$", remaining)
    )
    if not directive_matches:
        raise ValueError(f"No directive insertion point in {path}")
    insertion = directive_matches[-1].end()
    directives = "\n" + "\n".join(
        f"part '{filename}';" for _, filename, _, _ in extracted
    )
    remaining = remaining[:insertion] + directives + remaining[insertion:]
    path.write_text(remaining.rstrip() + "\n", encoding="utf-8")

    for _, filename, start, end in extracted:
        content = text[start:end].strip()
        (path.parent / filename).write_text(
            f"part of '{path.name}';\n\n{content}\n", encoding="utf-8"
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="+", type=Path)
    args = parser.parse_args()
    for path in args.paths:
        split(path)
        print(f"Split {path}")


if __name__ == "__main__":
    main()
