#!/usr/bin/env python3
"""v0.59: Overdub Titan + Refrain Unit (midjefes) from generated 16-bit sheets.

Same conventions as slice_bosses_048.py: border-median chroma key + JPEG fringe rule,
split idle|attack by column runs, feet/bottom anchored at the bottom of an equal-size
cell, sheet = two cells side by side at native resolution (Godot scales at runtime via
ArtKit.set_boss_pose, nearest filter). Differences, per source sheet:
  * no ground-shadow pass (these sheets have no shadow; the 0.48 rule eats boots/claws)
  * Overdub: the sonic wave attached to the cannon is cut at the cannon mouth (cleanest)
  * Refrain: the echo-ring arcs are dropped (only parts touching the drone are kept)
  * edge despill: 1–2 px magenta JPEG halo removed (tight for Refrain's pink armor)
"""
from __future__ import annotations

import os
import sys
from collections import deque

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import slice_bosses_048 as S  # noqa: E402

ROOT = S.ROOT
OUT = S.OUT
DOCS = S.DOCS
PAD = S.PAD
ASSETS = "/home/box/agent-data/agents/66a8307e-b09a-4029-be0a-f63b78f273f6/assets/"

FILES = {
    "overdub": ASSETS + "a6e24595561247ebfe8bc6a936f9a53491e775508ba8c6b122677f56b79fc8c7.jpg",
    "refrain": ASSETS + "357d8494c75fd81b6a7f27919929552cbaa2047b1f80f45cb27b2cc02b56c484.jpg",
}
# On-screen height (px) of the whole cell; must match ArtKit.BOSS_DISPLAY_H.
DISPLAY_H = {"overdub": 72, "refrain": 56}
# Despill distance to background (smaller = keeps more pink armor).
DESPILL_D = {"overdub": 110.0, "refrain": 62.0}


def label(mask: np.ndarray):
    h, w = mask.shape
    lab = np.zeros((h, w), np.int32)
    n = 0
    ys, xs = np.nonzero(mask)
    for y0, x0 in zip(ys, xs):
        if lab[y0, x0]:
            continue
        n += 1
        lab[y0, x0] = n
        q = deque([(y0, x0)])
        while q:
            y, x = q.popleft()
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < h and 0 <= xx < w and mask[yy, xx] and not lab[yy, xx]:
                        lab[yy, xx] = n
                        q.append((yy, xx))
    return lab, n


def dilate(mask: np.ndarray, r: int) -> np.ndarray:
    out = mask.copy()
    for _ in range(r):
        m = out.copy()
        m[1:, :] |= out[:-1, :]
        m[:-1, :] |= out[1:, :]
        m[:, 1:] |= out[:, :-1]
        m[:, :-1] |= out[:, 1:]
        out = m
    return out


def keep_main(mask: np.ndarray, near: int = 3) -> np.ndarray:
    """Largest component plus anything touching it within `near` px (drops arcs/particles)."""
    lab, n = label(mask)
    if n == 0:
        return mask
    sizes = np.bincount(lab.ravel())[1:]
    main = lab == (int(np.argmax(sizes)) + 1)
    zone = dilate(main, near)
    keep_ids = np.unique(lab[zone & mask])
    keep_ids = keep_ids[keep_ids > 0]
    return np.isin(lab, keep_ids)


def despill(rgb: np.ndarray, mask: np.ndarray, bg: np.ndarray, dmax: float, passes: int = 2) -> np.ndarray:
    f = rgb.astype(np.float32)
    d = np.linalg.norm(f - bg, axis=2)
    r, g, b = f[:, :, 0], f[:, :, 1], f[:, :, 2]
    magenta = (r > 120) & (b > 110) & (g < 95) & (r - g > 90) & (d < dmax)
    m = mask.copy()
    for _ in range(passes):
        inner = ~dilate(~m, 1)  # pixels whose 4-neighbours are all opaque
        edge = m & ~inner
        m = m & ~(edge & magenta)
    return m


def build(name: str, path: str):
    rgb = np.array(Image.open(path).convert("RGB"))
    bg = S.bg_color(rgb)
    mask = S.content_mask(rgb, bg)
    raw = mask.copy()
    runs = S.column_runs(mask)
    if len(runs) != 2:
        raise SystemExit(f"FAIL {name} runs {runs}")
    (ix0, ix1), (ax0, ax1) = runs
    idle = np.zeros_like(mask)
    idle[:, ix0 : ix1 + 1] = mask[:, ix0 : ix1 + 1]
    atk = np.zeros_like(mask)
    atk[:, ax0 : ax1 + 1] = mask[:, ax0 : ax1 + 1]
    if name == "overdub":
        # Cut the attached sonic wave at the cannon mouth: first column (from the left)
        # where dark-gray cannon pixels appear in the arm band.
        f = rgb.astype(np.int16)
        lum = f.sum(2)
        dark = atk & (lum < 260) & (np.abs(f[:, :, 0] - f[:, :, 2]) < 70)
        ys, xs = np.nonzero(atk)
        band_y0, band_y1 = int(ys.min() + (ys.max() - ys.min()) * 0.2), int(ys.min() + (ys.max() - ys.min()) * 0.5)
        cols = dark[band_y0:band_y1].sum(0)
        cut = int(np.argmax(cols > 12))
        atk[:, :cut] = False
        print(f"overdub wave cut at x={cut}")
    if name == "refrain":
        # Echo-ring arcs left of the drone: drop the band left of the rotor ring (above the
        # claw), a thin wisp beside the left claw, then lilac arc-coloured pixels that are
        # outside the thick body core on the left half. Body/rotor/claws/flame stay.
        atk[:400, :728] = False
        atk[400:480, :710] = False
        f = rgb.astype(np.int16)
        arc = (f[:, :, 0] > 165) & (f[:, :, 2] > 195) & (f[:, :, 1] >= 105)
        core = dilate(~dilate(~atk, 4), 5)
        left = np.zeros_like(atk)
        left[:, :880] = True
        atk = atk & ~(arc & ~core & left)
    idle = keep_main(despill(rgb, keep_main(idle), bg, DESPILL_D[name]))
    atk = keep_main(despill(rgb, keep_main(atk), bg, DESPILL_D[name]))
    # Pink-armor check: coverage of the kept body vs the raw key inside the body hull.
    for tag, m, (x0, x1) in (("idle", idle, (ix0, ix1)), ("attack", atk, (ax0, ax1))):
        ys, xs = np.nonzero(m)
        hull = np.zeros_like(m)
        hull[ys.min() : ys.max() + 1, xs.min() : xs.max() + 1] = True
        rawin = raw & hull
        cov = (m & rawin).sum() / max(1, rawin.sum())
        f = rgb.astype(np.int16)
        pink = rawin & (f[:, :, 0] > 150) & (f[:, :, 2] > 90) & (f[:, :, 1] < 120)
        pcov = (m & pink).sum() / max(1, pink.sum())
        print(f"{name} {tag}: body coverage {cov:.3f}, pink/magenta armor kept {pcov:.3f} ({int(pink.sum())} px)")
    poses = [S.pose_cells(rgb, m, 0, m.shape[1] - 1) for m in (idle, atk)]
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
    body_h = up_ext + 1
    print(f"{name:10} cell {cell_w}x{cell_h} sheet {sheet.shape[1]}x{sheet.shape[0]} "
          f"body on screen ~{body_h * DISPLAY_H[name] / cell_h:.1f}px of {DISPLAY_H[name]}")
    return frames


def main():
    thumbs = []
    for name, path in FILES.items():
        frames = build(name, path)
        dh = DISPLAY_H[name]
        row = []
        for fr in frames:
            im = Image.fromarray(fr, "RGBA")
            w = max(1, int(round(im.width * dh / im.height)))
            im = im.resize((w, dh), Image.NEAREST)  # in-game size
            row.append(im.resize((w * 4, dh * 4), Image.NEAREST))
        thumbs.append(row)
    gap = 16
    width = max(sum(i.width for i in r) + gap * (len(r) + 1) for r in thumbs)
    height = sum(max(i.height for i in r) for r in thumbs) + gap * (len(thumbs) + 1)
    canvas = Image.new("RGBA", (width, height), (22, 20, 30, 255))
    y = gap
    for r in thumbs:
        x = gap
        rh = max(i.height for i in r)
        for im in r:
            canvas.paste(im, (x, y + rh - im.height), im)
            x += im.width + gap
        # floor line at feet
        y += rh + gap
    path = os.path.join(DOCS, "preview_midbosses_059.png")
    canvas.save(path)
    print("preview", canvas.size, path)


if __name__ == "__main__":
    main()
