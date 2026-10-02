#!/usr/bin/env python3
"""Chroma-key boss sheets (idle|attack) and drop magenta ground shadows."""
from __future__ import annotations

import os
import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "game", "assets", "sprites", "bosses")
UI = os.path.join(ROOT, "game", "assets", "sprites", "ui")
DOCS = os.path.join(ROOT, "docs")
PAD = 4

FILES = {
    "beatfire": "/home/box/agent-data/agents/66a8307e-b09a-4029-be0a-f63b78f273f6/assets/99f40d02fb1347e043d97f7fc1f4cf0045b614d97ab8c08dcaa4bbb8574a0e0d.jpg",
    "glitch_ice": "/home/box/agent-data/agents/66a8307e-b09a-4029-be0a-f63b78f273f6/assets/f00fcc7f4d61753f615c6f3ae190dcb8fc4eb030745c42980dba62af51a83dcd.jpg",
    "bassquake": "/home/box/agent-data/agents/66a8307e-b09a-4029-be0a-f63b78f273f6/assets/b40ebdd4aa4d4dbc18081d81f58936cecfeb67b5a8fd6aece20a9ef54ba82d6b.jpg",
    "echo_wind": "/home/box/agent-data/agents/66a8307e-b09a-4029-be0a-f63b78f273f6/assets/86f14941065efe02742ef5b3d98cf23f3d96e8d7d679a136fdbbab64df39c22f.jpg",
    "neon_volt": "/home/box/agent-data/agents/66a8307e-b09a-4029-be0a-f63b78f273f6/assets/849a9e321eccc770c79dfce70baf46ba6219c04fad9a01ca5f2d3105b26abf5b.jpg",
    "metronome": "/home/box/agent-data/agents/66a8307e-b09a-4029-be0a-f63b78f273f6/assets/f379c455d3f426a46ad9c1459674ff169067971db0c6f56770470a7c58365414.jpg",
    "chorus_bloom": "/home/box/agent-data/agents/66a8307e-b09a-4029-be0a-f63b78f273f6/assets/9181dd6fadda05c1ee555865bb2bde9c5c45d2338c3e2d7c2ea88454c72029c5.jpg",
    "static_shadow": "/home/box/agent-data/agents/66a8307e-b09a-4029-be0a-f63b78f273f6/assets/7d6589799c1161c0d45d37032efbb3ecdbf3dd0cd46911ef11c884798fecf0a8.jpg",
    "core9": "/home/box/agent-data/agents/66a8307e-b09a-4029-be0a-f63b78f273f6/assets/7a37176b1e522ee163d62a0a22b788881e4d332108ce9a3fc04265be539f4148.jpg",
}


def bg_color(rgb: np.ndarray) -> np.ndarray:
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]], axis=0)
    return np.median(border, axis=0).astype(np.float32)


def content_mask(rgb: np.ndarray, bg: np.ndarray) -> np.ndarray:
    d = np.linalg.norm(rgb.astype(np.float32) - bg, axis=2)
    r = rgb[:, :, 0].astype(np.int16)
    g = rgb[:, :, 1].astype(np.int16)
    b = rgb[:, :, 2].astype(np.int16)
    # JPEG magenta fringe around the character.
    fringe = (d < 55) & (r > 160) & (b > 80) & (g < 110) & (b > g + 20) & (r < 250)
    return (d > 38) & ~fringe


def shadow_mask(rgb: np.ndarray, content: np.ndarray) -> np.ndarray:
    """Dark pink/purple ground blobs under the feet, not armor."""
    if not content.any():
        return content
    r = rgb[:, :, 0].astype(np.int16)
    g = rgb[:, :, 1].astype(np.int16)
    b = rgb[:, :, 2].astype(np.int16)
    ys = np.where(content.any(1))[0]
    top, bot = int(ys.min()), int(ys.max())
    height = max(1, bot - top)
    y0 = bot - max(10, int(height * 0.14))
    band = np.zeros(content.shape, dtype=bool)
    band[y0 : bot + 1, :] = True
    # Magenta-tinted and darker than the floor, redder than blue (not a purple cloak).
    # Magenta cast: blue above green. Orange armor has blue below green, so it stays.
    pink = (b > g + 8) & (r > g + 12) & (g < 85) & (r < 185) & (b < 150) & (r + g + b < 420)
    y_black = bot - max(6, int(height * 0.04))
    low = np.zeros(content.shape, dtype=bool)
    low[y_black : bot + 1, :] = True
    near_black = (r + g + b < 42) & (b + 6 >= g) & low
    return content & ((band & pink) | near_black)


def column_runs(mask: np.ndarray, min_w: int = 80):
    cols = mask.any(0)
    runs = []
    inn = False
    start = 0
    for i, v in enumerate(cols):
        if v and not inn:
            start = i
            inn = True
        elif (not v) and inn:
            if i - start >= min_w:
                runs.append((start, i - 1))
            inn = False
    if inn and len(cols) - start >= min_w:
        runs.append((start, len(cols) - 1))
    return runs


def pose_cells(rgb, mask, x0, x1):
    sl = mask[:, x0 : x1 + 1]
    ys, xs = np.where(sl)
    if len(xs) == 0:
        return None
    top, bot = int(ys.min()), int(ys.max())
    left, right = int(xs.min()) + x0, int(xs.max()) + x0
    height = bot - top + 1
    band = ys >= bot - max(8, int(height * 0.16))
    anchor = float(np.median(xs[band])) + x0
    return {
        "top": top,
        "bot": bot,
        "left": left,
        "right": right,
        "anchor": anchor,
        "ys": ys,
        "xs": xs + x0,
    }


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(UI, exist_ok=True)
    packed = {}
    failed = []
    for name, path in FILES.items():
        rgb = np.array(Image.open(path).convert("RGB"))
        bg = bg_color(rgb)
        mask = content_mask(rgb, bg)
        sh = shadow_mask(rgb, mask)
        removed = int(sh.sum())
        mask = mask & ~sh
        runs = column_runs(mask)
        if len(runs) != 2:
            print("FAIL", name, "runs", len(runs), runs)
            failed.append(name)
            continue
        poses = []
        for x0, x1 in runs:
            st = pose_cells(rgb, mask, x0, x1)
            if st is None:
                failed.append(name)
                break
            poses.append(st)
        if len(poses) != 2:
            continue
        left_ext = max(p["anchor"] - p["left"] for p in poses)
        right_ext = max(p["right"] - p["anchor"] for p in poses)
        up_ext = max(p["bot"] - p["top"] for p in poses)
        side = max(left_ext, right_ext)
        cell_w = int(side * 2 + PAD * 2 + 2)
        cell_h = int(up_ext + PAD * 2 + 2)
        anchor_at = cell_w / 2.0
        foot_y = cell_h - PAD - 1
        frames = []
        for st in poses:
            canvas = np.zeros((cell_h, cell_w, 4), np.uint8)
            dx = int(round(anchor_at - st["anchor"]))
            dy = int(foot_y - st["bot"])
            dst_x = st["xs"] + dx
            dst_y = st["ys"] + dy
            ok = (dst_x >= 0) & (dst_x < cell_w) & (dst_y >= 0) & (dst_y < cell_h)
            if not ok.all():
                print("CUTOFF", name, "dropped", int((~ok).sum()))
            canvas[dst_y[ok], dst_x[ok], :3] = rgb[st["ys"][ok], st["xs"][ok]]
            canvas[dst_y[ok], dst_x[ok], 3] = 255
            frames.append(canvas)
        sheet = np.concatenate(frames, axis=1)
        Image.fromarray(sheet, "RGBA").save(os.path.join(OUT, f"{name}.png"))
        # 64x64 portrait from idle opaque crop, nearest.
        idle = frames[0]
        op = np.where(idle[:, :, 3] > 0)
        portrait = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        if len(op[0]):
            y0, y1 = int(op[0].min()), int(op[0].max())
            x0, x1 = int(op[1].min()), int(op[1].max())
            crop = Image.fromarray(idle[y0 : y1 + 1, x0 : x1 + 1], "RGBA")
            cw, ch = crop.size
            scale = 64 / max(cw, ch)
            nw, nh = max(1, int(round(cw * scale))), max(1, int(round(ch * scale)))
            crop = crop.resize((nw, nh), Image.NEAREST)
            portrait.paste(crop, ((64 - nw) // 2, (64 - nh) // 2), crop)
        portrait.save(os.path.join(UI, f"portrait_{name}.png"))
        idle_h = int(op[0].max() - op[0].min() + 1) if len(op[0]) else 0
        print(f"{name:16} cell {cell_w}x{cell_h} idle_h {idle_h} shadow_px {removed} scale {64/cell_h:.4f}")
        packed[name] = frames
    if failed:
        print("FAILED", failed)
    # Preview on black, two rows-ish. Native is huge; nearest half for the doc? User wants a preview. Use native but that is ~1200*9. Place each boss's two frames scaled by nearest to height 160.
    thumbs = []
    for name, frames in packed.items():
        pair = np.concatenate(frames, axis=1)
        im = Image.fromarray(pair, "RGBA")
        nh = 180
        nw = max(1, int(round(im.width * (nh / im.height))))
        im = im.resize((nw, nh), Image.NEAREST)
        thumbs.append((name, im))
    gap = 6
    width = max(im.width for _, im in thumbs)
    height = sum(im.height for _, im in thumbs) + gap * (len(thumbs) - 1)
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 255))
    y = 0
    for _, im in thumbs:
        canvas.paste(im, (0, y), im)
        y += im.height + gap
    os.makedirs(DOCS, exist_ok=True)
    path = os.path.join(DOCS, "preview_bosses_048.png")
    canvas.save(path)
    print("preview", canvas.size, path)


if __name__ == "__main__":
    main()
