---
name: comfyui-imagegen
description: Generate raster images through the user's local ComfyUI API, including reference-grounded sprite and hatch-pet jobs.
---

# ComfyUI Image Generation

Use the `comfyui` MCP tools when the user asks to generate with their local ComfyUI backend.

1. Call `check_comfyui` before the first generation in a task.
2. Call `generate_image` with the complete visual prompt.
3. For reference-grounded work, pass every required local image in `reference_images` and select a workflow containing matching `__REFERENCE_IMAGE_N__` tokens.
4. Inspect the returned local image before accepting it.
5. Return the selected absolute image path.

The default workflow is text-to-image only. Hatch-pet row generation requires a custom API-format workflow with LoadImage/IPAdapter or another identity-conditioning path.
