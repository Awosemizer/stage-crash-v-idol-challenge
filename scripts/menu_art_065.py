#!/usr/bin/env python3
"""v0.65: title logo (hot-pink key via edge flood fill) + character-select stage backdrop."""
from collections import deque
import numpy as np
from PIL import Image

A = "/home/box/agent-data/agents/66a8307e-b09a-4029-be0a-f63b78f273f6/assets/"
LOGO = A + "68106e550a9c2948274cf6c81df487c5547aed883338279e3f3b36a59f6aa10c.jpg"
STAGE = A + "914b28a16151bca7d0d47da5d64e0879ebc453a45cc5c5faab8670dced0b84c2.jpg"
UI = "game/assets/sprites/ui/"

# --- logo: flood fill from the borders through pixels close to the background pink
rgb = np.array(Image.open(LOGO).convert("RGB")).astype(np.int32)
h, w, _ = rgb.shape
border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
bg = np.median(border, axis=0)
dist = np.sqrt(((rgb - bg) ** 2).sum(2))
near = dist < 70
bgm = np.zeros((h, w), bool)
q = deque()
for x in range(w):
    for y in (0, h - 1):
        if near[y, x] and not bgm[y, x]:
            bgm[y, x] = True; q.append((y, x))
for y in range(h):
    for x in (0, w - 1):
        if near[y, x] and not bgm[y, x]:
            bgm[y, x] = True; q.append((y, x))
while q:
    y, x = q.popleft()
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ny, nx = y + dy, x + dx
        if 0 <= ny < h and 0 <= nx < w and not bgm[ny, nx] and near[ny, nx]:
            bgm[ny, nx] = True; q.append((ny, nx))
# fringe: 2 passes peeling pink-ish pixels that touch the keyed background
r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
pinkish = (r - g > 70) & (b - g > 30) & (dist < 140)
for _ in range(2):
    touch = np.zeros_like(bgm)
    touch[1:] |= bgm[:-1]; touch[:-1] |= bgm[1:]; touch[:, 1:] |= bgm[:, :-1]; touch[:, :-1] |= bgm[:, 1:]
    bgm |= touch & pinkish
# closed letter counters (inside R/A/…) trap background pink: key every enclosed near-bg
# region above the V-IDOL banner (the banner's own pink stays).
seen = bgm.copy()
banner_top = int(h * 0.66)
for sy in range(banner_top):
    for sx in range(w):
        if near[sy, sx] and not seen[sy, sx] and dist[sy, sx] < 40:
            comp = []; q = deque([(sy, sx)]); seen[sy, sx] = True
            while q:
                y, x = q.popleft(); comp.append((y, x))
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < h and 0 <= nx < w and not seen[ny, nx] and near[ny, nx]:
                        seen[ny, nx] = True; q.append((ny, nx))
            if max(c[0] for c in comp) < banner_top:
                for y, x in comp:
                    bgm[y, x] = True
for _ in range(2):
    touch = np.zeros_like(bgm)
    touch[1:] |= bgm[:-1]; touch[:-1] |= bgm[1:]; touch[:, 1:] |= bgm[:, :-1]; touch[:, :-1] |= bgm[:, 1:]
    bgm |= touch & pinkish
alpha = np.where(bgm, 0, 255).astype(np.uint8)
ys, xs = np.where(alpha > 0)
y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
img = Image.fromarray(np.dstack([rgb.astype(np.uint8), alpha])[y0:y1, x0:x1], "RGBA")
W = 264
H = round(img.height * W / img.width)
img = img.resize((W, H), Image.NEAREST)
a = np.array(img); a[..., 3] = np.where(a[..., 3] > 127, 255, 0)
Image.fromarray(a).save(UI + "logo_stage_crash.png")
print("logo", (W, H))

# --- character select stage: area-quantized downscale
st = Image.open(STAGE).convert("RGB").resize((398, 224), Image.BOX)
st.save(UI + "charselect_stage.png")
print("charselect_stage", st.size)
