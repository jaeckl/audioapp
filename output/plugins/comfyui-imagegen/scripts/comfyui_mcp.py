from __future__ import annotations

import json
import os
import random
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path
from typing import Any

from mcp.server.fastmcp import FastMCP


mcp = FastMCP("comfyui")
BASE_URL = os.getenv("COMFYUI_URL", "http://127.0.0.1:8188").rstrip("/")
DEFAULT_WORKFLOW = os.getenv("COMFYUI_WORKFLOW", "")
DEFAULT_OUTPUT_DIR = os.getenv("COMFYUI_OUTPUT_DIR", str(Path.cwd() / "output" / "comfyui"))


def _request(path: str, *, data: bytes | None = None, headers: dict[str, str] | None = None) -> bytes:
    request = urllib.request.Request(BASE_URL + path, data=data, headers=headers or {})
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return response.read()
    except urllib.error.URLError as exc:
        raise RuntimeError(f"ComfyUI request failed at {path}: {exc}") from exc


def _json_request(path: str, payload: dict[str, Any]) -> dict[str, Any]:
    raw = _request(
        path,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    return json.loads(raw)


def _upload_image(path: Path) -> str:
    boundary = "----CodexComfyUI" + uuid.uuid4().hex
    content = path.read_bytes()
    body = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="image"; filename="{path.name}"\r\n'
        "Content-Type: application/octet-stream\r\n\r\n"
    ).encode() + content + f"\r\n--{boundary}--\r\n".encode()
    result = json.loads(
        _request(
            "/upload/image",
            data=body,
            headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        )
    )
    return result.get("name", path.name)


def _replace_tokens(value: Any, replacements: dict[str, Any]) -> Any:
    if isinstance(value, dict):
        return {key: _replace_tokens(item, replacements) for key, item in value.items()}
    if isinstance(value, list):
        return [_replace_tokens(item, replacements) for item in value]
    if isinstance(value, str):
        if value in replacements:
            return replacements[value]
        for token, replacement in replacements.items():
            value = value.replace(token, str(replacement))
    return value


def _wait_for_outputs(prompt_id: str, timeout_seconds: int) -> list[dict[str, Any]]:
    deadline = time.monotonic() + timeout_seconds
    while time.monotonic() < deadline:
        history = json.loads(_request(f"/history/{prompt_id}"))
        record = history.get(prompt_id)
        if record:
            images: list[dict[str, Any]] = []
            for output in record.get("outputs", {}).values():
                images.extend(output.get("images", []))
            if images:
                return images
            status = record.get("status", {})
            if status.get("completed") is True:
                raise RuntimeError("ComfyUI completed without returning image outputs")
        time.sleep(1)
    raise TimeoutError(f"ComfyUI did not finish within {timeout_seconds} seconds")


@mcp.tool()
def generate_image(
    prompt: str,
    negative_prompt: str = "text, watermark, logo, blurry, malformed",
    workflow_path: str = "",
    output_dir: str = "",
    reference_images: list[str] | None = None,
    seed: int = -1,
    width: int = 1024,
    height: int = 1024,
    timeout_seconds: int = 600,
) -> dict[str, Any]:
    """Run an API-format ComfyUI workflow and return downloaded local PNG paths.

    Workflow tokens: __PROMPT__, __NEGATIVE_PROMPT__, __SEED__, __WIDTH__,
    __HEIGHT__, and __REFERENCE_IMAGE_1__ through __REFERENCE_IMAGE_N__.
    """
    selected_workflow = Path(workflow_path or DEFAULT_WORKFLOW).expanduser().resolve()
    if not selected_workflow.is_file():
        raise FileNotFoundError(f"Workflow not found: {selected_workflow}")

    refs = [Path(item).expanduser().resolve() for item in (reference_images or [])]
    missing = [str(item) for item in refs if not item.is_file()]
    if missing:
        raise FileNotFoundError(f"Reference image(s) not found: {', '.join(missing)}")
    uploaded = [_upload_image(item) for item in refs]

    actual_seed = seed if seed >= 0 else random.randint(0, 2**63 - 1)
    replacements: dict[str, Any] = {
        "__PROMPT__": prompt,
        "__NEGATIVE_PROMPT__": negative_prompt,
        "__SEED__": actual_seed,
        "__WIDTH__": width,
        "__HEIGHT__": height,
    }
    replacements.update({f"__REFERENCE_IMAGE_{i}__": name for i, name in enumerate(uploaded, 1)})
    workflow = _replace_tokens(json.loads(selected_workflow.read_text(encoding="utf-8")), replacements)

    client_id = str(uuid.uuid4())
    queued = _json_request("/prompt", {"prompt": workflow, "client_id": client_id})
    if "error" in queued:
        raise RuntimeError(f"ComfyUI rejected workflow: {queued}")
    prompt_id = queued["prompt_id"]
    images = _wait_for_outputs(prompt_id, timeout_seconds)

    destination = Path(output_dir or DEFAULT_OUTPUT_DIR).expanduser().resolve()
    destination.mkdir(parents=True, exist_ok=True)
    saved: list[str] = []
    for index, image in enumerate(images, 1):
        query = urllib.parse.urlencode(
            {
                "filename": image["filename"],
                "subfolder": image.get("subfolder", ""),
                "type": image.get("type", "output"),
            }
        )
        suffix = Path(image["filename"]).suffix or ".png"
        target = destination / f"comfyui-{prompt_id}-{index}{suffix}"
        target.write_bytes(_request(f"/view?{query}"))
        saved.append(str(target))
    return {"prompt_id": prompt_id, "seed": actual_seed, "images": saved}


@mcp.tool()
def check_comfyui() -> dict[str, Any]:
    """Check whether the configured local ComfyUI server is reachable."""
    stats = json.loads(_request("/system_stats"))
    return {"url": BASE_URL, "reachable": True, "system_stats": stats}


if __name__ == "__main__":
    mcp.run(transport="stdio")
