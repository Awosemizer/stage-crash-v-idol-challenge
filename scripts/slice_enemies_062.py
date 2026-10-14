#!/usr/bin/env python3
"""v0.62: key the Speaker Drone / Spotlight Turret sheets (magenta JPEG) into small
pixel sheets (uniform cells, nearest scaling, feet at the bottom)."""
import os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
from slice_bosses_048 import bg_color, content_mask

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "game/assets/sprites/enemies")
A = "/home/box/agent-data/agents/66a8307e-b09a-4029-be0a-f63b78f273f6/assets/"
DRONE = A + "6bdec9c942625bd9c5bb99c4604a30956a076ed3afafab2aa363b3e32c959a2f.jpg"
TURRET = A + "c804079451c8e49b3b6d6abca40c613dd0845355423d0fc0c2696d600a98c6ac.jpg"


def keyed(path):
    rgb = np.array(Image.open(path).convert("RGB"))
    m = content_mask(rgb, bg_color(rgb))
    r, g, b = (rgb[..., i].astype(np.int16) for i in range(3))
    m &= ~((r - g > 20) & (b - g > 12))  # magenta fringe / spill
    # drop specks (open 1px)
    rgba = np.dstack([rgb, (m * 255).astype(np.uint8)])
    return rgba, m


def runs(m, min_w=60, gap=6):
    cols = m.sum(0) > 2
    out, s, last = [], None, -99
    for i, v in enumerate(cols):
        if v:
            if s is None or i - last > gap:
                if s is not None:
                    out.append((s, last))
                s = i
            last = i
    if s is not None:
        out.append((s, last))
    return [r for r in out if r[1] - r[0] >= min_w]


def cut(rgba, m, frames, cell_h, cell_w=None):
    ys = np.where(m[:, frames[0][0]:frames[-1][1] + 1].sum(1) > 2)[0]
    y0, y1 = ys.min(), ys.max() + 1
    w_src = max(b - a + 1 for a, b in frames)
    scale = cell_h / (y1 - y0)
    cw = cell_w or int(round(w_src * scale))
    cells = []
    for a, b in frames:
        crop = Image.fromarray(rgba[y0:y1, a:a + w_src])
        cr = crop.resize((cw, cell_h), Image.NEAREST)
        arr = np.array(cr)
        arr[..., 3] = np.where(arr[..., 3] > 127, 255, 0)
        cells.append(Image.fromarray(arr))
    sheet = Image.new("RGBA", (cw * len(cells), cell_h))
    for i, c in enumerate(cells):
        sheet.paste(c, (i * cw, 0))
    return sheet, cw


rgba, m = keyed(DRONE)
fr = runs(m)
assert len(fr) == 4, fr
d, dw = cut(rgba, m, fr, 20)
d.save(os.path.join(OUT, "speaker_drone.png"))

rgba, m = keyed(TURRET)
fr = runs(m)
assert len(fr) >= 3, fr
fr = fr[:3]
# frame 3 carries a detached beam: clip every frame to frame 2's width (barn doors)
w2 = fr[1][1] - fr[1][0]
fr = [(a, a + w2) for a, _ in fr]
t, tw = cut(rgba, m, fr, 24)
t.save(os.path.join(OUT, "spotlight_turret.png"))
print("drone cell", dw, "x20  turret cell", tw, "x24")

prev = Image.new("RGBA", (max(d.width, t.width) * 4 + 16, (20 + 24) * 4 + 24), (20, 20, 30, 255))
prev.alpha_composite(d.resize((d.width * 4, 80), Image.NEAREST), (8, 8))
prev.alpha_composite(t.resize((t.width * 4, 96), Image.NEAREST), (8, 96))
prev.convert("RGB").save(os.path.join(ROOT, "docs/preview_enemies_062.png"))
