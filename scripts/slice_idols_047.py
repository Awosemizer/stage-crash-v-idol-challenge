#!/usr/bin/env python3
"""Chroma-key the hand-drawn idol sheets and pack feet-aligned frames."""
from __future__ import annotations

import os
import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "game", "assets", "sprites", "player")
DOCS = os.path.join(ROOT, "docs")
MIKU_SRC = "/home/box/agent-data/agents/66a8307e-b09a-4029-be0a-f63b78f273f6/assets/fffa44a8330a28b9c39897d136814d7624030d0e3518e2872c22b9e84b874069.jpg"
TETO_SRC = "/home/box/agent-data/agents/66a8307e-b09a-4029-be0a-f63b78f273f6/assets/01f6aa1db3ef1ee4b2fc50782c3782061ba91221b6a652d2ffb38533bbbd3784.jpg"
BG = np.array([230.0, 22.0, 114.0], np.float32)
PAD = 6
TARGET_BODY = 32.0


def content_mask(rgb: np.ndarray) -> np.ndarray:
    d = np.linalg.norm(rgb.astype(np.float32) - BG, axis=2)
    r = rgb[:, :, 0].astype(np.int16)
    g = rgb[:, :, 1].astype(np.int16)
    b = rgb[:, :, 2].astype(np.int16)
    # JPEG magenta fringe. Real reds keep a low blue channel.
    fringe = (d < 58) & (r > 170) & (b > 90) & (g < 110) & (b > g + 25)
    return (d > 42) & ~fringe


def components(mask, min_n=80):
    h, w = mask.shape
    seen = np.zeros(mask.shape, np.uint8)
    items = []
    ys, xs = np.where(mask)
    from collections import deque
    for y, x in zip(ys.tolist(), xs.tolist()):
        if seen[y, x]:
            continue
        q = deque([(y, x)])
        seen[y, x] = 1
        cells = [(y, x)]
        while q:
            cy, cx = q.popleft()
            for dy in (-1, 0, 1):
                ny = cy + dy
                if ny < 0 or ny >= h:
                    continue
                row = mask[ny]
                srow = seen[ny]
                for dx in (-1, 0, 1):
                    nx = cx + dx
                    if 0 <= nx < w and row[nx] and not srow[nx]:
                        srow[nx] = 1
                        q.append((ny, nx))
                        cells.append((ny, nx))
        if len(cells) >= min_n:
            arr = np.array(cells, np.int32)
            items.append(arr)
    items.sort(key=lambda a: int(a[:, 1].min()))
    return items


def frame_stats_from_cells(cells):
    ys = cells[:, 0]
    xs = cells[:, 1]
    top, bot = int(ys.min()), int(ys.max())
    left, right = int(xs.min()), int(xs.max())
    height = bot - top + 1
    band = ys >= bot - max(6, int(height * 0.12))
    anchor_x = float(np.median(xs[band]))
    return {
        "top": top,
        "bot": bot,
        "left": left,
        "right": right,
        "anchor_x": anchor_x,
        "height": height,
        "cells": cells,
    }


def pack(name, path):
    rgb = np.array(Image.open(path).convert("RGB"))
    mask = content_mask(rgb)
    stats = [frame_stats_from_cells(c) for c in components(mask)]
    print(name, "frames", len(stats))
    for i, st in enumerate(stats):
        print(
            f"  {i} x {st['left']}-{st['right']} y {st['top']}-{st['bot']} "
            f"h {st['height']} anchor {st['anchor_x']:.1f} n {len(st['cells'])}"
        )
    return rgb, mask, stats


def compose(rgb, mask, stats, cell_w, cell_h, anchor_at, foot_y):
    frames = []
    for st in stats:
        canvas = np.zeros((cell_h, cell_w, 4), np.uint8)
        if "cells" in st:
            src_y = st["cells"][:, 0]
            src_x = st["cells"][:, 1]
        else:
            ys, xs = np.where(mask[st["top"] : st["bot"] + 1, st["left"] : st["right"] + 1])
            src_x = xs + st["left"]
            src_y = ys + st["top"]
        if len(src_x) == 0:
            frames.append(Image.fromarray(canvas, "RGBA"))
            continue
        dx = int(round(anchor_at - st["anchor_x"]))
        dy = int(foot_y - st["bot"])
        dst_x = src_x + dx
        dst_y = src_y + dy
        ok = (dst_x >= 0) & (dst_x < cell_w) & (dst_y >= 0) & (dst_y < cell_h)
        canvas[dst_y[ok], dst_x[ok], :3] = rgb[src_y[ok], src_x[ok]]
        canvas[dst_y[ok], dst_x[ok], 3] = 255
        frames.append(Image.fromarray(canvas, "RGBA"))
    return frames


def hstack(frames):
    w, h = frames[0].size
    sheet = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, fr in enumerate(frames):
        sheet.paste(fr, (i * w, 0))
    return sheet


def main():
    packed = {}
    raw = {}
    for name, path in (("miku", MIKU_SRC), ("teto", TETO_SRC)):
        rgb, mask, stats = pack(name, path)
        raw[name] = (rgb, mask, stats)
        if len(stats) != 8:
            raise SystemExit(f"{name} expected 8 poses, got {len(stats)}")
    # Shared cell so one frame size drives every region rect.
    left_ext = 0
    right_ext = 0
    up_ext = 0
    for rgb, mask, stats in raw.values():
        for st in stats:
            left_ext = max(left_ext, st["anchor_x"] - st["left"])
            right_ext = max(right_ext, st["right"] - st["anchor_x"])
            up_ext = max(up_ext, st["bot"] - st["top"])
    side = max(left_ext, right_ext)
    cell_w = int(side * 2 + PAD * 2 + 2)
    cell_h = int(up_ext + PAD * 2 + 2)
    anchor_at = cell_w / 2.0
    foot_y = cell_h - PAD - 1
    print(f"cell {cell_w}x{cell_h} anchor {anchor_at:.1f} foot {foot_y}")
    os.makedirs(OUT, exist_ok=True)
    scales = {}
    sheets = {}
    names = ["idle", "walk", "run", "jump", "fall", "action", "dash", "crouch"]
    for name, (rgb, mask, stats) in raw.items():
        frames = compose(rgb, mask, stats, cell_w, cell_h, anchor_at, foot_y)
        # Idle body height (opaque), used so standing height stays ~32px.
        idle = np.array(frames[0])
        opaque_rows = np.where(idle[:, :, 3].any(1))[0]
        body_h = int(opaque_rows.max() - opaque_rows.min() + 1) if len(opaque_rows) else cell_h
        scales[name] = TARGET_BODY / float(body_h)
        print(name, "idle body", body_h, "scale", round(scales[name], 4))
        by = {n: frames[i] for i, n in enumerate(names)}
        sheets[name] = by
        hstack([by["idle"]]).save(os.path.join(OUT, f"{name}_idle.png"))
        hstack([by["walk"], by["run"]]).save(os.path.join(OUT, f"{name}_run.png"))
        hstack([by["jump"], by["fall"], by["dash"]]).save(os.path.join(OUT, f"{name}_jump.png"))
        by["crouch"].save(os.path.join(OUT, f"{name}_slide.png"))
        action = "shoot" if name == "miku" else "saber"
        by["action"].save(os.path.join(OUT, f"{name}_{action}.png"))
    # Preview on black, both rows, native pixels.
    gap = 8
    row_w = cell_w * 8
    canvas = Image.new("RGBA", (row_w, cell_h * 2 + gap), (0, 0, 0, 255))
    for r, name in enumerate(("miku", "teto")):
        y = r * (cell_h + gap)
        for i, key in enumerate(names):
            fr = sheets[name][key]
            canvas.paste(fr, (i * cell_w, y), fr)
    os.makedirs(DOCS, exist_ok=True)
    prev = os.path.join(DOCS, "preview_idols_047.png")
    canvas.save(prev)
    print("preview", canvas.size, prev)
    # Cutoff check: any opaque pixel on the cell border
    for name in ("miku", "teto"):
        for key, fr in sheets[name].items():
            a = np.array(fr)
            edge = np.concatenate([a[0, :, 3], a[-1, :, 3], a[:, 0, 3], a[:, -1, 3]])
            if edge.max() > 0:
                print("CUTOFF", name, key)


if __name__ == "__main__":
    main()
