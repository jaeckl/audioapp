#!/usr/bin/env python3
"""Split a large class-static Dart map into bounded library part files."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def split_map(
    source: Path,
    owner: str,
    field: str,
    prefix: str,
    max_lines: int,
    qualify: list[str],
) -> None:
    text = source.read_text(encoding="utf-8")
    declaration = re.search(
        rf"(?m)^  static final Map<[^\n]+>\s+{re.escape(field)}\s*=\s*\{{\n",
        text,
    )
    if not declaration:
        raise ValueError(f"Could not find static map {owner}.{field}")

    body_start = declaration.end()
    end_match = re.search(r"(?m)^  };\s*$", text[body_start:])
    if not end_match:
        raise ValueError(f"Could not find end of {owner}.{field}")
    body_end = body_start + end_match.start()
    declaration_end = body_start + end_match.end()
    body = text[body_start:body_end]

    starts = list(re.finditer(r"(?m)^    '[^']+':", body))
    if not starts:
        raise ValueError(f"No entries found in {owner}.{field}")
    entries = [
        body[item.start() : starts[index + 1].start() if index + 1 < len(starts) else len(body)]
        for index, item in enumerate(starts)
    ]

    groups: list[list[str]] = []
    current: list[str] = []
    current_lines = 3
    for entry in entries:
        entry_lines = len(entry.splitlines())
        if current and current_lines + entry_lines > max_lines:
            groups.append(current)
            current = []
            current_lines = 3
        current.append(entry)
        current_lines += entry_lines
    if current:
        groups.append(current)

    identifiers = [f"_{prefix}Group{index + 1}" for index in range(len(groups))]
    replacement = (
        declaration.group(0)
        + "".join(f"    ...{identifier},\n" for identifier in identifiers)
        + "  };"
    )
    updated = text[: declaration.start()] + replacement + text[declaration_end:]

    part_names = [f"{source.stem}_{prefix}_group_{index + 1}.dart" for index in range(len(groups))]
    directives = "".join(f"part '{name}';\n" for name in part_names)
    existing_parts = list(re.finditer(r"(?m)^part '[^']+';\n", updated))
    if existing_parts:
        insert_at = existing_parts[-1].end()
    else:
        imports = list(re.finditer(r"(?m)^import [^;]+;\n", updated))
        insert_at = imports[-1].end() if imports else 0
    updated = updated[:insert_at] + directives + updated[insert_at:]

    for index, (name, group, identifier) in enumerate(zip(part_names, groups, identifiers)):
        content = "".join(group)
        for member in qualify:
            content = re.sub(
                rf"(?<![A-Za-z0-9_.]){re.escape(member)}\b",
                f"{owner}.{member}",
                content,
            )
        target = source.with_name(name)
        if target.exists():
            raise ValueError(f"Refusing to overwrite {target}")
        target.write_text(
            f"part of '{source.name}';\n\n"
            f"final Map<String, {('dynamic' if owner == 'PhaseModSynthPresets' else 'SubtractiveSynthPreset')}> "
            f"{identifier} = {{\n{content}}};\n",
            encoding="utf-8",
        )

    source.write_text(updated, encoding="utf-8")
    print(f"Split {owner}.{field} into {len(groups)} groups")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("owner")
    parser.add_argument("field")
    parser.add_argument("prefix")
    parser.add_argument("--max-lines", type=int, default=260)
    parser.add_argument("--qualify", nargs="*", default=[])
    args = parser.parse_args()
    split_map(
        args.source,
        args.owner,
        args.field,
        args.prefix,
        args.max_lines,
        args.qualify,
    )


if __name__ == "__main__":
    main()
