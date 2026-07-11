from PIL import Image, ImageDraw

W, H = 832, 1216
im = Image.new("RGB", (W, H), "black")
d = ImageDraw.Draw(im)

p = {
    "nose": (416, 132), "neck": (416, 235),
    "rs": (350, 270), "re": (326, 410), "rw": (335, 555),
    "ls": (482, 270), "le": (506, 410), "lw": (497, 555),
    "rh": (382, 595), "rk": (382, 810), "ra": (382, 1050),
    "lh": (450, 595), "lk": (450, 810), "la": (450, 1050),
    "reye": (395, 122), "leye": (437, 122), "rear": (375, 132), "lear": (457, 132),
}

edges = [
    ("neck", "rs", (255, 85, 0)), ("rs", "re", (255, 170, 0)), ("re", "rw", (255, 255, 0)),
    ("neck", "ls", (170, 255, 0)), ("ls", "le", (85, 255, 0)), ("le", "lw", (0, 255, 0)),
    ("neck", "rh", (0, 255, 85)), ("rh", "rk", (0, 255, 170)), ("rk", "ra", (0, 255, 255)),
    ("neck", "lh", (0, 170, 255)), ("lh", "lk", (0, 85, 255)), ("lk", "la", (0, 0, 255)),
    ("neck", "nose", (85, 0, 255)), ("nose", "reye", (170, 0, 255)), ("reye", "rear", (255, 0, 255)),
    ("nose", "leye", (255, 0, 170)), ("leye", "lear", (255, 0, 85)),
]

for a, b, color in edges:
    d.line((p[a], p[b]), fill=color, width=14)
for point in p.values():
    x, y = point
    d.ellipse((x - 9, y - 9, x + 9, y + 9), fill=(255, 255, 255))

im.save(r"C:\Users\ludwi\Desktop\audioapp\output\hatch-pet\velora-comfy-v2\references\arms-down-openpose.png")
