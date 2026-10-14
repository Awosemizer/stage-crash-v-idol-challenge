#!/usr/bin/env python3
"""v0.66: X3-style UI kit (hot-pink key from the edges) + title key art at 398×224."""
from collections import deque
import numpy as np
from PIL import Image

A = "/home/box/agent-data/agents/66a8307e-b09a-4029-be0a-f63b78f273f6/assets/"
KEYART = A + "f2f76adcf3d5fcb5798ab13a21c8edeaf6cac263985e98f3b7d63f439af791bf.jpg"
KIT = A + "1d43586000495fad960f663f5ec8e3feb9db5514caa82b95a4b8930c2d3b401c.jpg"
UI = "game/assets/sprites/ui/"
S = 0.25  # kit art -> game pixels (buttons/cursor a bit finer so 20-26 px buttons keep rivets)
SCALE = {"btn_normal": 0.2, "btn_selected": 0.2, "btn_disabled": 0.2, "cursor": 0.18}

# ---------------- key art: area downscale + 48-colour palette, no dithering
ka = Image.open(KEYART).convert("RGB").resize((398, 224), Image.BOX)
ka = ka.quantize(colors=48, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
ka.save(UI + "title_keyart.png")

# ---------------- kit: flood fill background from the edges
rgb = np.array(Image.open(KIT).convert("RGB")).astype(np.int32)
h, w, _ = rgb.shape
border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
dist = np.sqrt(((rgb - np.median(border, axis=0)) ** 2).sum(2))
near = dist < 80
bgm = np.zeros((h, w), bool)
q = deque((y, x) for y in range(h) for x in (0, w - 1)) + deque((y, x) for y in (0, h - 1) for x in range(w))
for y, x in q:
    bgm[y, x] = near[y, x]
q = deque(p for p in q if bgm[p])
while q:
    y, x = q.popleft()
    for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
        if 0 <= ny < h and 0 <= nx < w and not bgm[ny, nx] and near[ny, nx]:
            bgm[ny, nx] = True; q.append((ny, nx))
r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
pinkish = (r - g > 60) & (r - b > 20)
for _ in range(2):
    t = np.zeros_like(bgm)
    t[1:] |= bgm[:-1]; t[:-1] |= bgm[1:]; t[:, 1:] |= bgm[:, :-1]; t[:, :-1] |= bgm[:, 1:]
    bgm |= t & pinkish
fg = ~bgm

# connected components (8 items) on a downsampled grid for speed
lab = np.zeros((h, w), np.int32); n = 0; boxes = []
for sy in range(0, h, 3):
    for sx in range(0, w, 3):
        if fg[sy, sx] and not lab[sy, sx]:
            n += 1; q = deque([(sy, sx)]); lab[sy, sx] = n; ys = []; xs = []
            while q:
                y, x = q.popleft(); ys.append(y); xs.append(x)
                for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                    if 0 <= ny < h and 0 <= nx < w and fg[ny, nx] and not lab[ny, nx]:
                        lab[ny, nx] = n; q.append((ny, nx))
            if len(ys) > 400:
                boxes.append((min(ys), min(xs), max(ys) + 1, max(xs) + 1, n))
boxes.sort(key=lambda b_: (b_[0] // 150, b_[1]))
print("components", [(b_[0], b_[1], b_[2] - b_[0], b_[3] - b_[1]) for b_ in boxes])
names = ["btn_normal", "btn_selected", "btn_disabled", "window", "cursor", "touch_round", "dpad"]
# row 2 order by x: window, cursor (higher), ring, dpad -> sort row 2 by x then fix cursor/ring
row1 = sorted([b_ for b_ in boxes if b_[0] < h * 0.3], key=lambda b_: b_[1])
row2 = [b_ for b_ in boxes if b_[0] >= h * 0.3]
window = max(row2, key=lambda b_: (b_[2] - b_[0]) * (b_[3] - b_[1]))
dpad = max(row2, key=lambda b_: b_[3])
rest = [b_ for b_ in row2 if b_ not in (window, dpad)]
cursor = min(rest, key=lambda b_: b_[0])
ring = max(rest, key=lambda b_: b_[0])
picked = dict(zip(names, row1[:3] + [window, cursor, ring, dpad]))
rgba = np.dstack([rgb.astype(np.uint8), np.where(fg, 255, 0).astype(np.uint8)])
for name, (y0, x0, y1, x1, li) in picked.items():
    crop = rgba[y0:y1, x0:x1].copy()
    crop[..., 3] = np.where(lab[y0:y1, x0:x1] == li, crop[..., 3], 0)
    im = Image.fromarray(crop, "RGBA")
    sc = SCALE.get(name, S)
    nw, nh = max(1, round(im.width * sc)), max(1, round(im.height * sc))
    im = im.resize((nw, nh), Image.NEAREST)
    a = np.array(im); a[..., 3] = np.where(a[..., 3] > 127, 255, 0)
    Image.fromarray(a).save(UI + "kit/" + name + ".png")
    print(name, (nw, nh))
