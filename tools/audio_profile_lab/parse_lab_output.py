#!/usr/bin/env python3
"""Parse audio profile lab output (flutter test log and/or adb logcat)."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

REPORT_PREFIX = "@@AUDIO_PROFILE_LAB@@"
XRUN_RE = re.compile(
    r"XRUN: callback took (?P<elapsed>\d+) us \(deadline (?P<deadline>\d+) us\) ph=(?P<playhead>[\d.]+)"
)


@dataclass
class XRunEvent:
    elapsed_us: int
    deadline_us: int
    playhead: float
    source: str


def load_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def extract_reports(text: str) -> list[dict[str, Any]]:
    reports: list[dict[str, Any]] = []
    for line in text.splitlines():
        index = line.find(REPORT_PREFIX)
        if index < 0:
            continue
        payload = line[index + len(REPORT_PREFIX) :].strip()
        reports.append(json.loads(payload))
    return reports


def extract_xruns(text: str, source: str) -> list[XRunEvent]:
    events: list[XRunEvent] = []
    for match in XRUN_RE.finditer(text):
        events.append(
            XRunEvent(
                elapsed_us=int(match.group("elapsed")),
                deadline_us=int(match.group("deadline")),
                playhead=float(match.group("playhead")),
                source=source,
            )
        )
    return events


def summarize_report(report: dict[str, Any]) -> dict[str, Any]:
    rows: list[dict[str, Any]] = []
    for entry in report.get("results", []):
        final = entry.get("final", {})
        configured = entry.get("configured", {})
        deadline = float(final.get("deadlineMicros", 0.0))
        max_callback = float(final.get("maxCallbackMicros", 0.0))
        rows.append(
            {
                "profile": entry.get("profile"),
                "xRunCount": final.get("xRunCount"),
                "callbackOverruns": final.get("callbackOverruns"),
                "maxCallbackMicros": max_callback,
                "deadlineMicros": deadline,
                "headroomMicros": final.get("headroomMicros"),
                "headroomRatio": final.get("headroomRatio"),
                "framesPerCallback": configured.get("framesPerCallback"),
                "bufferSizeFrames": configured.get("bufferSizeFrames"),
                "performanceMode": configured.get("performanceMode"),
                "sharingMode": configured.get("sharingMode"),
                "stable": final.get("xRunCount", 0) == 0
                and final.get("callbackOverruns", 0) == 0
                and (deadline <= 0 or max_callback <= deadline * 0.5),
            }
        )
    return {
        "scenario": report.get("scenario"),
        "startedAt": report.get("startedAt"),
        "finishedAt": report.get("finishedAt"),
        "profiles": rows,
    }


def render_markdown(
    summaries: list[dict[str, Any]], xruns: list[XRunEvent]
) -> str:
    lines = ["# Audio profile lab summary", ""]
    if not summaries:
        lines.append("_No structured lab reports found._")
    for summary in summaries:
        lines.append(f"## Scenario `{summary.get('scenario', '?')}`")
        lines.append("")
        lines.append(
            "| Profile | XRuns | DSP misses | Max µs | Deadline µs | Headroom | Stable |"
        )
        lines.append("| --- | ---: | ---: | ---: | ---: | ---: | --- |")
        for row in summary.get("profiles", []):
            headroom = row.get("headroomMicros")
            headroom_text = f"{headroom:.0f}" if isinstance(headroom, (int, float)) else "?"
            lines.append(
                "| {profile} | {xRunCount} | {callbackOverruns} | {maxCallbackMicros:.0f} | "
                "{deadlineMicros:.0f} | {headroom} | {stable} |".format(
                    profile=row.get("profile"),
                    xRunCount=row.get("xRunCount"),
                    callbackOverruns=row.get("callbackOverruns"),
                    maxCallbackMicros=float(row.get("maxCallbackMicros", 0.0)),
                    deadlineMicros=float(row.get("deadlineMicros", 0.0)),
                    headroom=headroom_text,
                    stable="yes" if row.get("stable") else "no",
                )
            )
        lines.append("")
    if xruns:
        lines.append("## Native XRUN log lines")
        lines.append("")
        lines.append(f"Count: **{len(xruns)}**")
        lines.append("")
        for event in xruns[:20]:
            lines.append(
                f"- `{event.elapsed_us}` µs > `{event.deadline_us}` µs @ playhead {event.playhead}"
            )
        if len(xruns) > 20:
            lines.append(f"- … and {len(xruns) - 20} more")
        lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "inputs",
        nargs="*",
        help="flutter test logs, logcat dumps, or pre-parsed JSON reports",
    )
    parser.add_argument(
        "-o",
        "--output-json",
        type=Path,
        help="Write merged JSON summary",
    )
    parser.add_argument(
        "--markdown",
        type=Path,
        help="Write human-readable markdown summary",
    )
    args = parser.parse_args()

    reports: list[dict[str, Any]] = []
    xruns: list[XRunEvent] = []

    for raw in args.inputs:
        path = Path(raw)
        if not path.exists():
            print(f"warning: missing input {path}", file=sys.stderr)
            continue
        text = load_text(path)
        if path.suffix.lower() == ".json":
            data = json.loads(text)
            if data.get("kind") == "audio_profile_lab":
                reports.append(data)
            elif "profiles" in data:
                reports.append(data)
            continue
        reports.extend(extract_reports(text))
        xruns.extend(extract_xruns(text, str(path)))

    summaries = [summarize_report(report) for report in reports]
    merged = {
        "summaries": summaries,
        "xrunCount": len(xruns),
        "xruns": [
            {
                "elapsedUs": event.elapsed_us,
                "deadlineUs": event.deadline_us,
                "playhead": event.playhead,
                "source": event.source,
            }
            for event in xruns
        ],
    }

    if args.output_json:
        args.output_json.parent.mkdir(parents=True, exist_ok=True)
        args.output_json.write_text(json.dumps(merged, indent=2), encoding="utf-8")
        print(f"wrote {args.output_json}")

    if args.markdown:
        args.markdown.parent.mkdir(parents=True, exist_ok=True)
        args.markdown.write_text(render_markdown(summaries, xruns), encoding="utf-8")
        print(f"wrote {args.markdown}")

    if not args.output_json and not args.markdown:
        print(json.dumps(merged, indent=2))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
