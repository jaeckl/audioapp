# ComfyUI Imagegen Codex template

This plugin exposes a local ComfyUI server as two MCP tools: `check_comfyui` and `generate_image`.

## Configure

1. Start ComfyUI with its HTTP API reachable at the `COMFYUI_URL` configured in `.mcp.json` (this installation uses `http://127.0.0.1:8000`).
2. Open `workflows/basic-txt2img.json` to select a different installed checkpoint if desired.
3. Adjust `.mcp.json` if the ComfyUI URL, workflow, output directory, or plugin location changes.

For an existing ComfyUI graph, enable dev mode in ComfyUI, choose **Save (API Format)**, and use the exported JSON as `COMFYUI_WORKFLOW`.

Supported exact-value tokens anywhere in workflow inputs:

- `__PROMPT__`
- `__NEGATIVE_PROMPT__`
- `__SEED__`
- `__WIDTH__`
- `__HEIGHT__`
- `__REFERENCE_IMAGE_1__`, `__REFERENCE_IMAGE_2__`, and so on

For reference images, put `__REFERENCE_IMAGE_1__` in the `image` input of a `LoadImage` node. The server uploads the local file to ComfyUI before queueing the workflow. Connect that node to IPAdapter, ControlNet, img2img, or your preferred identity-conditioning nodes.

## Hatch-pet integration

The stock hatch-pet skill mandates the system `$imagegen` skill, so merely installing this plugin does not override it. Fork/update hatch-pet's **Generation Delegation** section to invoke `$comfyui-imagegen` and require the returned `images[0]` path as `selected_source`.

Row workflows must consume the canonical base and layout guide supplied in `reference_images`; do not use the text-only sample workflow for hatch-pet rows.

## Direct server smoke test

Run the MCP server with:

```powershell
uv run --with mcp python .\scripts\comfyui_mcp.py
```

MCP stdio output is protocol traffic, so normally Codex should launch it through `.mcp.json`.
