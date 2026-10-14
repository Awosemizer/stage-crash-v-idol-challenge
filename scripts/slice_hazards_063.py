#!/usr/bin/env python3
"""v0.63: key the hazard sheet (vent | fire x3 | icicle | debris | subwoofer) into small sprites."""
import os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
from slice_bosses_048 import bg_color, content_mask

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "game/assets/sprites/hazards")
SRC = "/home/box/agent-data/agents/66a8307e-b09a-4029-be0a-f63b78f273f6/assets/c8902fb5fdb492e5ab48b87473e2dc5a427cfb3d2fea47b298c2965f16029d04.jpg"

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



rgb = np.array(Image.open(SRC).convert("RGB"))
m = content_mask(rgb, bg_color(rgb))
r, g, b = (rgb[..., i].astype(np.int16) for i in range(3))
# pink fringe cut only near the background (keeps the purple subwoofer body)
edge = ~m
for _ in range(2):
    e = edge.copy()
    e[1:] |= edge[:-1]; e[:-1] |= edge[1:]; e[:, 1:] |= edge[:, :-1]; e[:, :-1] |= edge[:, 1:]
    edge = e
m &= ~(edge & (r - g > 20) & (b - g > 12))
rgba = np.dstack([rgb, (m * 255).astype(np.uint8)])
fr = runs(m, min_w=20)
assert len(fr) == 7, fr


def bbox(a, b_):
    ys = np.where(m[:, a:b_ + 1].sum(1) > 1)[0]
    return ys.min(), ys.max() + 1


def fit(frames, W, H):
    """Shared crop for all frames, aspect kept, bottom-centred in a W×H cell."""
    y0 = min(bbox(a, b_)[0] for a, b_ in frames); y1 = max(bbox(a, b_)[1] for a, b_ in frames)
    w = max(b_ - a + 1 for a, b_ in frames); h = y1 - y0
    s = min(W / w, H / h)
    nw, nh = max(1, round(w * s)), max(1, round(h * s))
    sheet = Image.new("RGBA", (W * len(frames), H))
    for i, (a, b_) in enumerate(frames):
        cx = (a + b_) // 2
        crop = Image.fromarray(rgba[y0:y1, cx - w // 2:cx - w // 2 + w]).resize((nw, nh), Image.NEAREST)
        arr = np.array(crop); arr[..., 3] = np.where(arr[..., 3] > 127, 255, 0)
        sheet.paste(Image.fromarray(arr), (i * W + (W - nw) // 2, H - nh))
    return sheet


items = {"fire_vent": ([fr[0]], 16, 6), "fire_column": (fr[1:4], 12, 40), "icicle": ([fr[4]], 10, 14),
         "debris": ([fr[5]], 12, 12), "subwoofer": ([fr[6]], 16, 20)}
sheets = {}
for name, (f, W, H) in items.items():
    sheets[name] = fit(f, W, H)
    sheets[name].save(os.path.join(OUT, name + ".png"))
x = 8
prev = Image.new("RGBA", (4 * (16 + 36 + 10 + 12 + 16) + 8 * 6, 4 * 40 + 16), (20, 20, 30, 255))
for name in items:
    s = sheets[name]
    prev.alpha_composite(s.resize((s.width * 4, s.height * 4), Image.NEAREST), (x, prev.height - 8 - s.height * 4))
    x += s.width * 4 + 8
prev.convert("RGB").save(os.path.join(ROOT, "docs/preview_hazards_063.png"))
print({k: v.size for k, v in sheets.items()})
