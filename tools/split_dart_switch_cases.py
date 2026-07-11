#!/usr/bin/env python3
"""Extract top-level Dart switch case bodies into one-method extension parts."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

from split_dart_declarations import snake_case


def split(source: Path, method: str, parameter_list: str) -> None:
    text = source.read_text(encoding="utf-8")
    part = re.search(r"(?m)^part of '([^']+)';", text)
    extension = re.search(r"(?m)^extension\s+\w+\s+on\s+(\w+)", text)
    if not part or not extension:
        raise ValueError("Expected an extension part file")
    owner_file = source.parent / part.group(1)
    owner_type = extension.group(1)

    method_match = re.search(rf"(?m)^\s*Widget\s+{re.escape(method)}\([^\n]+\)\s*\{{", text)
    if not method_match:
        raise ValueError(f"Method {method} not found")
    switch_start = text.find("    switch (", method_match.end())
    if switch_start < 0:
        raise ValueError("Switch not found")
    body_start = text.find("\n", switch_start) + 1
    body_end = text.rfind("    }\n", body_start)
    if body_end < 0:
        raise ValueError("Switch end not found")
    lines = text[body_start:body_end].splitlines(keepends=True)

    groups: list[tuple[list[str], list[str]]] = []
    labels: list[str] = []
    statements: list[str] = []
    label_pattern = re.compile(r"^      (case '([^']+)':|default:)")
    for line in lines:
        match = label_pattern.match(line)
        if match:
            if labels and statements:
                groups.append((labels, statements))
                labels, statements = [], []
            labels.append(line)
        else:
            statements.append(line)
    if labels:
        groups.append((labels, statements))

    outputs: list[tuple[Path, str, str]] = []
    replacements: list[str] = []
    for index, (case_labels, case_body) in enumerate(groups):
        type_match = re.search(r"case '([^']+)'", "".join(case_labels))
        key = type_match.group(1) if type_match else "unknown"
        helper = f"_build{''.join(piece.title() for piece in key.split('_'))}Device"
        filename = f"{source.stem}_{snake_case(helper)}.dart"
        target = source.with_name(filename)
        if target.exists():
            raise ValueError(f"Refusing to overwrite {target}")
        extension_name = f"{owner_type.lstrip('_')}{helper.lstrip('_').title()}Operation"
        body = "".join(case_body)
        body = "\n".join(line[8:] if line.startswith("        ") else line for line in body.splitlines())
        content = (
            f"part of '{part.group(1)}';\n\n"
            f"extension {extension_name} on {owner_type} {{\n"
            f"  Widget {helper}({parameter_list}) {{\n{body}\n  }}\n}}\n"
        )
        outputs.append((target, content, filename))
        replacements.extend(case_labels)
        replacements.append(f"        return {helper}(context, contentHeight);\n")

    updated = text[:body_start] + "".join(replacements) + text[body_end:]
    owner = owner_file.read_text(encoding="utf-8")
    directives = "".join(f"part '{filename}';\n" for _, _, filename in outputs)
    existing = list(re.finditer(r"(?m)^part '[^']+';\n", owner))
    if not existing:
        raise ValueError("Owner has no part directives")
    declaration = re.search(
        r"(?m)^(?:const|final|class|enum|mixin|extension|abstract|base|sealed|interface)\b",
        owner[existing[0].start() :],
    )
    insert_at = (
        existing[0].start() + declaration.start()
        if declaration
        else existing[-1].end()
    )
    owner = owner[:insert_at] + directives + owner[insert_at:]

    source.write_text(updated, encoding="utf-8")
    owner_file.write_text(owner, encoding="utf-8")
    for target, content, _ in outputs:
        target.write_text(content, encoding="utf-8")
    print(f"Split {len(outputs)} switch case groups from {source}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("method")
    parser.add_argument("--parameters", default="BuildContext context, double contentHeight")
    args = parser.parse_args()
    split(args.source, args.method, args.parameters)


if __name__ == "__main__":
    main()
