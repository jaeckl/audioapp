"""Capture dynamics FX Flutter web screenshots via Chrome headless + CDP."""
from __future__ import annotations

import json
import os
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app_flutter"
BUILD = APP / "build" / "web_screenshot"
OUT = ROOT / "docs" / "design" / "dynamics_fx" / "screenshots"
PORT = 8765

CHROME_CANDIDATES = [
    Path(os.environ.get("PROGRAMFILES", r"C:\Program Files")) / "Google/Chrome/Application/chrome.exe",
    Path(os.environ.get("PROGRAMFILES(X86)", r"C:\Program Files (x86)")) / "Google/Chrome/Application/chrome.exe",
    Path(os.environ.get("LOCALAPPDATA", "")) / "Google/Chrome/Application/chrome.exe",
    Path(os.environ.get("PROGRAMFILES", r"C:\Program Files")) / "Microsoft/Edge/Application/msedge.exe",
    Path(os.environ.get("PROGRAMFILES(X86)", r"C:\Program Files (x86)")) / "Microsoft/Edge/Application/msedge.exe",
]


def find_chrome() -> Path:
    for path in CHROME_CANDIDATES:
        if path.is_file():
            return path
    raise SystemExit("Chrome or Edge not found")


def wait_for_server(url: str, timeout: float = 30.0) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(url, timeout=1) as resp:
                if resp.status == 200:
                    return
        except OSError:
            time.sleep(0.25)
    raise SystemExit(f"Server did not start at {url}")


def capture_sections(chrome: Path, sections: list[tuple[str, str]]) -> None:
    import base64
    import websocket  # type: ignore

    user_data = BUILD / ".chrome_profile"
    user_data.mkdir(exist_ok=True)

    proc = subprocess.Popen(
        [
            str(chrome),
            "--headless=new",
            "--disable-gpu",
            "--no-sandbox",
            f"--user-data-dir={user_data}",
            "--remote-debugging-port=9222",
            "--remote-allow-origins=*",
            "--hide-scrollbars",
            "--window-size=1600,900",
            f"http://127.0.0.1:{PORT}/",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        time.sleep(2.5)
        targets = json.loads(urllib.request.urlopen("http://127.0.0.1:9222/json").read())
        page_target = next(t for t in targets if t.get("type") == "page")
        ws = websocket.create_connection(page_target["webSocketDebuggerUrl"], timeout=60)
        msg_id = 0

        def send(method: str, params: dict | None = None) -> dict:
            nonlocal msg_id
            msg_id += 1
            payload = {"id": msg_id, "method": method, "params": params or {}}
            ws.send(json.dumps(payload))
            while True:
                reply = json.loads(ws.recv())
                if reply.get("id") == msg_id:
                    if "error" in reply:
                        raise RuntimeError(reply["error"])
                    return reply.get("result", {})

        send("Page.enable")
        send("Runtime.enable")
        send("Page.navigate", {"url": f"http://127.0.0.1:{PORT}/"})
        time.sleep(8.0)

        section_specs = {
            "picker": {"height": 440, "width": 420},
            "gate": {"height": 380, "width": 400},
            "compressor": {"height": 380, "width": 400},
            "expander": {"height": 380, "width": 400},
            "limiter": {"height": 380, "width": 400},
            "chain": {"height": 380, "width": 1520},
        }

        for label, filename in sections:
            out_file = OUT / filename
            spec = section_specs[label]
            send(
                "Runtime.evaluate",
                {
                    "expression": f"""
(() => {{
  const el = document.querySelector('[flt-semantics-identifier="{label}"]')
    || document.querySelector('[aria-label="{label}"]');
  if (el) el.scrollIntoView({{block: 'start', inline: 'nearest'}});
}})()
""",
                },
            )
            time.sleep(0.75)
            bounds = send(
                "Runtime.evaluate",
                {
                    "expression": f"""
(() => {{
  const el = document.querySelector('[flt-semantics-identifier="{label}"]')
    || document.querySelector('[aria-label="{label}"]');
  if (!el) return null;
  const r = el.getBoundingClientRect();
  const pad = 8;
  return {{
    x: Math.max(0, r.x - pad),
    y: Math.max(0, r.y - pad),
    width: Math.max({spec["width"]}, r.width + pad * 2),
    height: Math.max({spec["height"]}, r.height + pad * 2),
  }};
}})()
""",
                    "returnByValue": True,
                },
            )["result"]["value"]

            if not bounds:
                raise RuntimeError(f"Element not found: aria-label={label!r}")

            shot = send(
                "Page.captureScreenshot",
                {
                    "format": "png",
                    "clip": {
                        "x": bounds["x"],
                        "y": bounds["y"],
                        "width": bounds["width"],
                        "height": bounds["height"],
                        "scale": 1,
                    },
                },
            )
            out_file.write_bytes(base64.b64decode(shot["data"]))
            print(f"Wrote {out_file}")
    finally:
        proc.terminate()
        proc.wait(timeout=10)


def main() -> int:
    try:
        import websocket  # noqa: F401
    except ImportError:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "websocket-client"])
        import websocket  # noqa: F401

    if not BUILD.is_dir():
        raise SystemExit(f"Missing web build at {BUILD}. Run flutter build web first.")

    OUT.mkdir(parents=True, exist_ok=True)
    server = subprocess.Popen(
        [sys.executable, "-m", "http.server", str(PORT), "--directory", str(BUILD)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    chrome = find_chrome()

    try:
        wait_for_server(f"http://127.0.0.1:{PORT}/")
        sections = [
            ("picker", "01_device_picker_effects.png"),
            ("gate", "02_gate_detect.png"),
            ("compressor", "03_compressor_comp.png"),
            ("expander", "04_expander_expand.png"),
            ("limiter", "05_limiter_ceiling.png"),
            ("chain", "06_dynamics_chain_row.png"),
        ]
        capture_sections(chrome, sections)
    finally:
        server.terminate()
        server.wait(timeout=5)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
