#!/usr/bin/env python3
"""Original 64px idol sprites for Stage Crash (Miku-inspired / Teto-inspired).

Crisp nearest-neighbor pixels only. Not a trace of any reference sheet.
"""
from __future__ import annotations

import math
import os
from PIL import Image, ImageDraw

S = 64
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "game", "assets", "sprites", "player")
DOCS = os.path.join(ROOT, "docs")

# Ramps are dark → light. 7–8 steps per material.
MIKU_HAIR = [
    (6, 36, 52),
    (10, 62, 84),
    (14, 98, 122),
    (22, 140, 158),
    (48, 186, 196),
    (110, 230, 226),
    (186, 252, 246),
    (232, 255, 252),
]
TETO_HAIR = [
    (62, 8, 18),
    (110, 16, 28),
    (158, 28, 40),
    (196, 48, 58),
    (220, 78, 86),
    (236, 120, 122),
    (250, 176, 170),
    (255, 220, 214),
]
SKIN = [
    (92, 52, 48),
    (128, 74, 64),
    (176, 108, 92),
    (214, 146, 122),
    (240, 184, 158),
    (255, 214, 196),
    (255, 236, 226),
]
MIKU_CLOTH = [
    (8, 40, 58),
    (12, 68, 92),
    (18, 104, 126),
    (28, 146, 160),
    (64, 190, 186),
    (140, 230, 220),
    (210, 255, 246),
]
TETO_CLOTH = [
    (72, 10, 22),
    (120, 18, 32),
    (164, 32, 44),
    (198, 52, 62),
    (220, 86, 92),
    (236, 130, 128),
    (255, 190, 184),
]
INK = [
    (10, 10, 18),
    (26, 28, 40),
    (46, 50, 66),
    (72, 78, 98),
    (112, 120, 140),
    (168, 176, 192),
    (214, 220, 230),
]
METAL = [
    (18, 24, 34),
    (40, 52, 68),
    (72, 88, 108),
    (118, 136, 154),
    (168, 184, 198),
    (214, 226, 234),
    (246, 250, 252),
]
GOLD = [
    (92, 52, 12),
    (140, 84, 18),
    (186, 124, 28),
    (220, 168, 48),
    (244, 208, 96),
    (255, 236, 170),
]
BLADE = [
    (40, 48, 70),
    (90, 110, 150),
    (160, 190, 230),
    (220, 236, 255),
    (255, 255, 255),
]
OUTLINE = (8, 8, 16, 255)


def clamp(v, a, b):
    return a if v < a else b if v > b else v


class Spr:
    def __init__(self):
        self.im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        self.px = self.im.load()

    def inside(self, x, y):
        return 0 <= x < S and 0 <= y < S

    def put(self, x, y, rgb):
        x, y = int(x), int(y)
        if self.inside(x, y):
            self.px[x, y] = (rgb[0], rgb[1], rgb[2], 255)

    def empty(self, x, y):
        if not self.inside(x, y):
            return True
        return self.px[x, y][3] == 0

    def cel(self, nx, ny, ramp, bias=0.0):
        """Hard bands, not a per-pixel gradient. nx right, ny down."""
        key = (-ny) * 0.72 + (-nx) * 0.42 + bias
        n = len(ramp)
        if n == 1:
            return ramp[0]
        if key > 0.78:
            i = n - 1
        elif key > 0.42:
            i = max(0, n - 3)
        elif key > 0.08:
            i = n // 2
        elif key > -0.28:
            i = min(2, n - 1)
        else:
            i = 0
        return ramp[i]

    def capsule(self, x0, y0, x1, y1, rad, ramp, bias=0.0):
        rad = float(rad)
        x0, y0, x1, y1 = float(x0), float(y0), float(x1), float(y1)
        minx = int(min(x0, x1) - rad - 1)
        maxx = int(max(x0, x1) + rad + 1)
        miny = int(min(y0, y1) - rad - 1)
        maxy = int(max(y0, y1) + rad + 1)
        dx, dy = x1 - x0, y1 - y0
        seglen2 = dx * dx + dy * dy
        n = len(ramp)
        for y in range(miny, maxy + 1):
            for x in range(minx, maxx + 1):
                if seglen2 < 0.01:
                    t = 0.0
                    cx, cy = x0, y0
                else:
                    t = ((x - x0) * dx + (y - y0) * dy) / seglen2
                    t = clamp(t, 0.0, 1.0)
                    cx, cy = x0 + dx * t, y0 + dy * t
                ddx, ddy = x - cx, y - cy
                dist = math.hypot(ddx, ddy)
                if dist > rad + 0.35:
                    continue
                if dist < 0.01:
                    nx, ny = 0.0, -1.0
                else:
                    nx, ny = ddx / dist, ddy / dist
                # Upper-left key light. Screen +y is down.
                light = 0.42 + (-nx) * 0.34 + (-ny) * 0.48 + bias
                # Core slightly brighter so limbs aren't muddy.
                edge = dist / rad
                light += (1.0 - edge) * 0.08
                self.put(x, y, self.cel(nx, ny, ramp, bias))

    def ellipse(self, cx, cy, rx, ry, ramp, ang=0.0, bias=0.0):
        cx, cy, rx, ry = float(cx), float(cy), float(rx), float(ry)
        if rx < 0.4 or ry < 0.4:
            return
        minx = int(cx - rx - 2)
        maxx = int(cx + rx + 2)
        miny = int(cy - ry - 2)
        maxy = int(cy + ry + 2)
        ca, sa = math.cos(ang), math.sin(ang)
        n = len(ramp)
        for y in range(miny, maxy + 1):
            for x in range(minx, maxx + 1):
                dx, dy = x - cx, y - cy
                lx = dx * ca + dy * sa
                ly = -dx * sa + dy * ca
                if (lx * lx) / (rx * rx) + (ly * ly) / (ry * ry) > 1.0:
                    continue
                nx = lx / rx
                ny = ly / ry
                light = 0.40 + (-nx) * 0.36 + (-ny) * 0.50 + bias
                self.put(x, y, self.cel(nx, ny, ramp, bias))

    def poly(self, pts, ramp, vertical=True, bias=0.0):
        if len(pts) < 3:
            return
        mask = Image.new("L", (S, S), 0)
        d = ImageDraw.Draw(mask)
        d.polygon([(int(p[0]), int(p[1])) for p in pts], fill=255)
        mp = mask.load()
        ys = [p[1] for p in pts]
        xs = [p[0] for p in pts]
        y0, y1 = min(ys), max(ys)
        x0, x1 = min(xs), max(xs)
        span_y = max(1.0, y1 - y0)
        span_x = max(1.0, x1 - x0)
        n = len(ramp)
        for y in range(S):
            for x in range(S):
                if mp[x, y] == 0:
                    continue
                nx = ((x - x0) / span_x) * 2.0 - 1.0
                ny = ((y - y0) / span_y) * 2.0 - 1.0
                self.put(x, y, self.cel(nx, ny, ramp, bias))

    def outline(self):
        add = []
        for y in range(S):
            for x in range(S):
                if self.px[x, y][3] == 0:
                    continue
                for nx, ny in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    xx, yy = x + nx, y + ny
                    if not self.inside(xx, yy) or self.px[xx, yy][3] == 0:
                        add.append((xx, yy))
                        break
        # Draw outline in the transparent neighbor, not by eating the color.
        neigh = []
        for y in range(S):
            for x in range(S):
                if self.px[x, y][3] != 0:
                    continue
                for nx, ny in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    xx, yy = x + nx, y + ny
                    if self.inside(xx, yy) and self.px[xx, yy][3] != 0:
                        neigh.append((x, y))
                        break
        for x, y in neigh:
            if self.inside(x, y) and self.px[x, y][3] == 0:
                self.px[x, y] = OUTLINE

    def rim(self):
        """1px top/left highlight on existing color so materials catch light."""
        lights = []
        for y in range(1, S - 1):
            for x in range(1, S - 1):
                p = self.px[x, y]
                if p[3] == 0 or p[:3] == OUTLINE[:3]:
                    continue
                up = self.px[x, y - 1]
                left = self.px[x - 1, y]
                if up[3] == 0 or up[:3] == OUTLINE[:3] or left[3] == 0 or left[:3] == OUTLINE[:3]:
                    r, g, b = p[:3]
                    lights.append((x, y, (min(255, r + 38), min(255, g + 38), min(255, b + 28))))
        for x, y, c in lights:
            self.px[x, y] = (c[0], c[1], c[2], 255)


def leg(spr, hipx, hipy, thigh_deg, shin_deg, cloth, boot, thigh_len=12, shin_len=11, thick=3.3):
    kx, ky = _ang(hipx, hipy, thigh_len, thigh_deg)
    fx, fy = _ang(kx, ky, shin_len, shin_deg)
    spr.capsule(hipx, hipy, kx, ky, thick, cloth)
    spr.capsule(kx, ky, fx, fy, thick - 0.5, cloth, bias=-0.05)
    # Boot covers the lower shin and adds a toe forward.
    spr.capsule(kx, ky + (fy - ky) * 0.35, fx, fy, thick + 0.3, boot, bias=-0.02)
    toe_x, toe_y = _ang(fx, fy, 4.5, shin_deg - 70)
    spr.capsule(fx, fy, toe_x, toe_y, 2.4, boot)
    # Sole
    sole_x, sole_y = _ang(fx, fy, 4.5, shin_deg - 70)
    spr.capsule(fx + 0.5, fy + 1.2, sole_x, sole_y + 1.2, 1.3, INK)


def _ang(x, y, length, deg):
    rad = math.radians(deg)
    return x + math.sin(rad) * length, y + math.cos(rad) * length


def arm(spr, sx, sy, deg, length, ramp, thick=2.6):
    ex, ey = _ang(sx, sy, length, deg)
    spr.capsule(sx, sy, ex, ey, thick, ramp)
    return ex, ey


def miku_hair(spr, hx, hy, swing, front=True):
    """Twin tails in profile: one rear ribbon, one nearer ribbon."""
    # Rear tail
    c0 = (hx - 8, hy - 8)
    c1 = (hx - 16 + swing, hy + 4)
    c2 = (hx - 14 + swing * 1.2, hy + 18)
    c3 = (hx - 10 + swing * 0.5, hy + 32)
    ribbon(spr, [c0, c1, c2, c3], 4.6, MIKU_HAIR)
    if front:
        f0 = (hx - 2, hy - 2)
        f1 = (hx - 8 + swing * 0.5, hy + 8)
        f2 = (hx - 5 + swing, hy + 20)
        f3 = (hx - 1 + swing * 0.4, hy + 30)
        ribbon(spr, [f0, f1, f2, f3], 3.6, MIKU_HAIR, bias=0.08)
        # Hair ties
        spr.ellipse(hx - 4, hy - 1, 2.2, 2.2, INK, bias=0.1)
        spr.ellipse(hx - 4, hy - 1, 1.2, 1.2, MIKU_CLOTH, bias=0.2)


def ribbon(spr, pts, rad, ramp, bias=0.0):
    # Sample the polyline densely and stamp shaded ellipses, then a connecting capsule.
    for i in range(len(pts) - 1):
        spr.capsule(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], rad, ramp, bias=bias)
    # Specular streak along the upper side
    for i in range(len(pts) - 1):
        x0, y0 = pts[i]
        x1, y1 = pts[i + 1]
        spr.capsule(x0, y0 - rad * 0.45, x1, y1 - rad * 0.45, max(1.1, rad * 0.28), ramp[-3:], bias=0.15)


def teto_drills(spr, hx, hy, swing):
    # Rear drill
    drill(spr, hx - 8 + swing * 0.3, hy - 2, 5, 5.5, 4.2, TETO_HAIR, phase=0.4)
    # Front drill, slightly shorter, overlaps the chest
    drill(spr, hx - 3 + swing * 0.15, hy + 1, 4, 4.6, 3.6, TETO_HAIR, phase=1.6)


def drill(spr, cx, y0, rings, rx, ry, ramp, phase=0.0):
    for i in range(rings):
        cy = y0 + i * (ry * 1.55)
        shrink = 1.0 - i * 0.06
        ang = phase + i * 0.85
        spr.ellipse(cx, cy, rx * shrink, ry * shrink, ramp, ang=ang, bias=0.02 * i)
        # Spiral highlight tooth
        hx = cx + math.cos(ang) * rx * 0.35
        hy = cy - ry * 0.35
        spr.ellipse(hx, hy, rx * 0.38, ry * 0.28, ramp[-3:], bias=0.2)
    # Tip
    spr.ellipse(cx, y0 + rings * (ry * 1.55), rx * 0.45, ry * 0.4, ramp[2:5])


def draw_idol(kind, pose):
    """kind: miku|teto. pose keys documented in build()."""
    spr = Spr()
    miku = kind == "miku"
    hair = MIKU_HAIR if miku else TETO_HAIR
    cloth = MIKU_CLOTH if miku else TETO_CLOTH
    boot = INK
    bob = pose.get("bob", 0)
    swing = pose.get("swing", 0)
    lean = pose.get("lean", 0)
    blink = pose.get("blink", False)
    # Anchor: feet baseline around y=56, hip around 40.
    hip_x = 34 + lean
    hip_y = 36 + bob
    shoulder_x = hip_x + pose.get("torso_lean", 0)
    shoulder_y = hip_y - 14
    head_x = shoulder_x + 2 + pose.get("head_x", 0)
    head_y = shoulder_y - 8 + pose.get("head_y", 0)

    # Far hair first so the body overlaps the root.
    if miku:
        miku_hair(spr, head_x, head_y, swing, front=False)
    else:
        drill(spr, head_x - 9 + swing * 0.25, head_y - 1, 5, 5.4, 4.0, TETO_HAIR, phase=0.2)

    # Back arm
    if pose.get("back_arm"):
        bd, bl = pose["back_arm"]
        arm(spr, shoulder_x - 1, shoulder_y + 1, bd, bl, cloth, 2.5)
        # Detached sleeve
        ex, ey = _ang(shoulder_x - 1, shoulder_y + 1, bl * 0.45, bd)
        spr.capsule(shoulder_x - 1, shoulder_y + 1, ex, ey, 3.1, INK, bias=-0.05)

    # Legs
    back = pose["back_leg"]
    front = pose["front_leg"]
    leg(spr, hip_x - 1, hip_y, back[0], back[1], cloth if not miku else SKIN, boot)
    # Skirt / shorts before the front leg so the front thigh overlaps.
    if miku:
        skirt(spr, hip_x, hip_y, pose.get("skirt", 0))
    else:
        shorts(spr, hip_x, hip_y)

    leg(spr, hip_x + 1, hip_y, front[0], front[1], SKIN, boot)

    # Torso
    torso(spr, shoulder_x, shoulder_y, hip_x, hip_y, cloth, miku)

    # Head
    head(spr, head_x, head_y, hair, miku, blink, pose.get("mouth", "smile"))

    # Front hair overlaps shoulder
    if miku:
        f0 = (head_x - 2, head_y - 2)
        f1 = (head_x - 6 + swing * 0.3, head_y + 10)
        f2 = (head_x - 2 + swing * 0.6, head_y + 22)
        f3 = (head_x + 3 + swing * 0.2, head_y + 32)
        ribbon(spr, [f0, f1, f2, f3], 3.2, MIKU_HAIR, bias=0.12)
        spr.ellipse(head_x - 3, head_y - 2, 2.3, 2.3, INK, bias=0.15)
        spr.ellipse(head_x - 3, head_y - 2, 1.15, 1.15, MIKU_CLOTH, bias=0.25)
        # Rear tie
        spr.ellipse(head_x - 7, head_y - 5, 2.1, 2.1, INK, bias=0.1)
        spr.ellipse(head_x - 7, head_y - 5, 1.0, 1.0, MIKU_CLOTH, bias=0.2)
    else:
        teto_front_drill(spr, head_x, head_y, swing)
        # Ahoge
        spr.capsule(head_x - 1, head_y - 11, head_x + 2, head_y - 16, 1.3, TETO_HAIR, bias=0.15)
        spr.capsule(head_x + 2, head_y - 16, head_x + 5, head_y - 14, 1.2, TETO_HAIR, bias=0.2)

    # Front arm / weapon on top
    weapon(spr, shoulder_x, shoulder_y, pose, miku, cloth)

    spr.outline()
    return spr.im


def teto_front_drill(spr, hx, hy, swing):
    drill(spr, hx - 2 + swing * 0.1, hy + 2, 4, 4.4, 3.5, TETO_HAIR, phase=1.4)


def torso(spr, sx, sy, hx, hy, cloth, miku):
    # Chest plate
    spr.poly(
        [
            (sx - 5, sy - 1),
            (sx + 6, sy),
            (sx + 5, hy - 1),
            (sx - 4, hy),
        ],
        cloth,
    )
    # White collar
    spr.poly(
        [
            (sx - 3, sy - 1),
            (sx + 4, sy - 1),
            (sx + 2, sy + 4),
            (sx - 1, sy + 5),
        ],
        INK[-4:],
        bias=0.15,
    )
    if miku:
        # Tie
        spr.poly(
            [(sx + 1, sy + 1), (sx + 3, sy + 2), (sx + 2, sy + 8), (sx, sy + 7)],
            MIKU_HAIR[2:6],
        )
        # Speaker gem
        spr.ellipse(sx + 1, sy + 6, 1.6, 1.6, MIKU_HAIR[-4:], bias=0.2)
    else:
        spr.poly(
            [(sx, sy + 2), (sx + 3, sy + 3), (sx + 2, sy + 7), (sx, sy + 6)],
            GOLD[2:],
        )
        spr.ellipse(sx + 1, sy + 6, 1.5, 1.5, TETO_HAIR[-3:], bias=0.25)


def skirt(spr, hx, hy, flare):
    spr.poly(
        [
            (hx - 6, hy - 2),
            (hx + 7, hy - 1),
            (hx + 9 + flare, hy + 8),
            (hx - 8 - flare, hy + 9),
        ],
        INK,
        bias=0.02,
    )
    # Pleat shadows
    for i, ox in enumerate((-3, 1, 5)):
        spr.capsule(hx + ox, hy, hx + ox + flare * 0.3, hy + 8, 0.7, INK[:3], bias=-0.1)
    # Teal hem light
    spr.capsule(hx - 6, hy + 7, hx + 8, hy + 7, 0.8, MIKU_CLOTH[3:6], bias=0.1)


def shorts(spr, hx, hy):
    spr.poly(
        [
            (hx - 6, hy - 2),
            (hx + 6, hy - 1),
            (hx + 6, hy + 5),
            (hx - 6, hy + 6),
        ],
        INK,
    )
    spr.capsule(hx - 4, hy + 4, hx + 5, hy + 4, 0.7, TETO_CLOTH[3:6])


def head(spr, hx, hy, hair, miku, blink, mouth):
    # Neck
    spr.capsule(hx - 1, hy + 8, hx, hy + 13, 2.2, SKIN, bias=0.05)
    # Skull
    spr.ellipse(hx - 1, hy, 8.2, 9.0, SKIN, bias=0.05)
    # Ear
    spr.ellipse(hx - 6, hy + 1, 2.0, 2.6, SKIN[1:5])
    spr.ellipse(hx - 6, hy + 1, 0.8, 1.2, SKIN[:3], bias=-0.1)
    # Bangs and crown hair
    spr.ellipse(hx - 1, hy - 3, 8.6, 6.4, hair, bias=0.05)
    # Sideburn / back hair mass
    spr.ellipse(hx - 6, hy + 1, 4.0, 6.5, hair, bias=-0.05)
    # Fringe over forehead, leave the eye
    spr.poly(
        [
            (hx - 8, hy - 6),
            (hx + 7, hy - 7),
            (hx + 6, hy - 1),
            (hx + 2, hy + 1),
            (hx - 2, hy - 2),
            (hx - 8, hy - 1),
        ],
        hair,
    )
    # Face window is skin again on the front
    spr.ellipse(hx + 2, hy + 2, 4.6, 5.2, SKIN, bias=0.08)
    # Eye
    if blink:
        spr.capsule(hx + 1, hy + 1, hx + 5, hy + 2, 0.7, INK[:3])
    else:
        spr.ellipse(hx + 3.4, hy + 0.4, 3.1, 3.3, [(255, 255, 255)])
        spr.ellipse(hx + 3.8, hy + 0.8, 1.7, 2.0, INK[:2])
        spr.put(hx + 2, hy - 1, (255, 255, 255))
        spr.put(hx + 3, hy - 1, (255, 255, 255))
        spr.put(hx + 2, hy, (255, 255, 255))
    # Brow
    spr.capsule(hx + 1, hy - 2, hx + 5, hy - 3, 0.6, hair[:3])
    # Mouth
    if mouth == "open":
        spr.ellipse(hx + 4, hy + 4.2, 1.4, 1.1, [(90, 24, 36), (160, 50, 60), (220, 90, 100)])
        spr.put(hx + 4, hy + 4, (255, 180, 186))
    else:
        spr.capsule(hx + 3, hy + 4, hx + 5, hy + 5, 0.55, [(150, 60, 70)])
    # Blush
    spr.put(hx + 1, hy + 3, (230, 140, 140) if miku else (220, 110, 110))
    spr.put(hx + 1, hy + 4, (230, 140, 140) if miku else (220, 110, 110))
    # Headset band — original, not a Vocaloid trace
    if miku:
        spr.capsule(hx - 7, hy - 6, hx + 6, hy - 8, 1.15, METAL, bias=0.05)
        spr.ellipse(hx - 7, hy, 2.3, 2.8, METAL, bias=0.05)
        spr.ellipse(hx - 7, hy, 1.1, 1.4, MIKU_HAIR[-4:], bias=0.3)
        # Mic boom
        spr.capsule(hx - 6, hy + 2, hx + 3, hy + 5, 0.6, METAL)
    else:
        spr.ellipse(hx - 7, hy - 1, 1.6, 1.6, GOLD[2:], bias=0.2)


def weapon(spr, sx, sy, pose, miku, cloth):
    kind = pose.get("weapon", "arm")
    if kind == "buster":
        # Upper arm then cannon
        ex, ey = arm(spr, sx + 1, sy + 2, pose.get("buster_deg", 78), 8, cloth, 2.7)
        spr.capsule(sx + 1, sy + 2, ex, ey, 3.2, INK, bias=-0.08)
        bx, by = _ang(ex, ey, 12, pose.get("buster_deg", 78))
        spr.capsule(ex, ey, bx, by, 4.0, METAL, bias=0.05)
        spr.capsule(ex, ey - 1.2, bx, by - 1.2, 1.0, MIKU_HAIR[3:7], bias=0.15)
        # Muzzle
        mx, my = _ang(bx, by, 2.2, pose.get("buster_deg", 78))
        spr.ellipse(mx, my, 2.2, 2.2, INK[:4])
        spr.ellipse(mx, my, 1.1, 1.1, MIKU_HAIR[-3:], bias=0.35)
    elif kind == "saber":
        ex, ey = arm(spr, sx + 1, sy + 1, pose.get("saber_arm", -40), 9, cloth, 2.6)
        # Grip
        gx, gy = _ang(ex, ey, 4, pose.get("saber_arm", -40))
        spr.capsule(ex, ey, gx, gy, 1.6, INK[1:5])
        # Blade
        deg = pose.get("saber_deg", -20)
        tip_x, tip_y = _ang(gx, gy, 20, deg)
        spr.capsule(gx, gy, tip_x, tip_y, 2.6, BLADE, bias=0.12)
        spr.capsule(gx, gy, tip_x, tip_y, 0.9, [(255, 255, 255)], bias=0.4)
        # Guard
        spr.ellipse(gx, gy, 2.4, 1.6, GOLD[1:5], bias=0.1)
    elif kind == "none":
        return
    else:
        deg, length = pose.get("front_arm", (70, 10))
        ex, ey = arm(spr, sx + 1, sy + 2, deg, length, cloth, 2.6)
        spr.capsule(sx + 1, sy + 2, _ang(sx + 1, sy + 2, length * 0.5, deg)[0], _ang(sx + 1, sy + 2, length * 0.5, deg)[1], 3.0, INK)
        # Hand
        spr.ellipse(ex, ey, 1.8, 1.6, SKIN[2:6])


def poses_for(kind):
    # Leg angles: 0 straight down, + forward (right), - back.
    # (thigh, shin)
    stand_back = (-8, 6)
    stand_front = (12, 4)
    idle = dict(
        back_leg=stand_back,
        front_leg=stand_front,
        back_arm=(-30, 9),
        front_arm=(55, 9),
        weapon="arm",
        swing=0,
        bob=0,
    )
    idle2 = dict(idle)
    idle2.update(blink=True, swing=1, bob=1)
    # 8-frame run. Opposite arms/legs.
    run_keys = [
        # contact
        dict(back_leg=(-48, 18), front_leg=(42, -8), back_arm=(50, 9), front_arm=(-35, 9), bob=0, swing=3, torso_lean=2),
        dict(back_leg=(-28, 36), front_leg=(22, 18), back_arm=(28, 9), front_arm=(-12, 9), bob=1, swing=2, torso_lean=2),
        # passing
        dict(back_leg=(6, 8), front_leg=(-8, 22), back_arm=(6, 9), front_arm=(12, 9), bob=2, swing=0, torso_lean=1),
        # high knee
        dict(back_leg=(38, -36), front_leg=(-42, 48), back_arm=(-28, 9), front_arm=(48, 9), bob=1, swing=-2, torso_lean=2),
        dict(back_leg=(46, -6), front_leg=(-50, 16), back_arm=(-48, 9), front_arm=(36, 9), bob=0, swing=-3, torso_lean=2),
        dict(back_leg=(24, 22), front_leg=(-26, 38), back_arm=(-22, 9), front_arm=(18, 9), bob=1, swing=-2, torso_lean=2),
        dict(back_leg=(-4, 16), front_leg=(8, 10), back_arm=(-4, 9), front_arm=(4, 9), bob=2, swing=0, torso_lean=1),
        dict(back_leg=(-40, 46), front_leg=(40, -34), back_arm=(40, 9), front_arm=(-30, 9), bob=1, swing=2, torso_lean=2),
    ]
    for p in run_keys:
        p["weapon"] = "arm"
        p["lean"] = 1
    jump_up = dict(
        back_leg=(-36, -20),
        front_leg=(28, -30),
        back_arm=(-70, 10),
        front_arm=(-50, 10),
        weapon="arm",
        bob=-2,
        swing=-4,
        torso_lean=1,
        head_y=-1,
    )
    jump_fall = dict(
        back_leg=(8, 10),
        front_leg=(34, 6),
        back_arm=(-80, 10),
        front_arm=(-60, 9),
        weapon="arm",
        bob=1,
        swing=4,
        torso_lean=0,
    )
    wall = dict(
        back_leg=(18, 55),
        front_leg=(42, 70),
        back_arm=(80, 8),
        front_arm=(78, 9),
        weapon="arm",
        bob=0,
        swing=2,
        lean=2,
        torso_lean=3,
    )
    slide = dict(
        back_leg=(-70, 10),
        front_leg=(30, 40),
        back_arm=(-20, 8),
        front_arm=(80, 10),
        weapon="arm",
        bob=8,
        swing=5,
        lean=2,
        torso_lean=6,
        head_y=2,
        skirt=2,
    )
    if kind == "miku":
        action = dict(idle)
        action.update(weapon="buster", buster_deg=90, back_arm=(-50, 9), swing=-1, torso_lean=2)
    else:
        action = dict(idle)
        action.update(weapon="saber", saber_arm=-30, saber_deg=118, back_arm=(55, 9), swing=1, torso_lean=2, mouth="open")
    return {
        "idle": [idle, idle2],
        "run": run_keys,
        "jump": [jump_up, jump_fall, wall],
        "slide": [slide],
        "action": [action],
    }


def hstack(frames):
    w = S * len(frames)
    sheet = Image.new("RGBA", (w, S), (0, 0, 0, 0))
    for i, fr in enumerate(frames):
        sheet.paste(fr, (i * S, 0))
    return sheet


def wings():
    spr = Spr()
    # Mechanical wings behind the shoulders. Center stays empty so the body reads.
    # Left wing
    spr.poly([(18, 22), (4, 16), (2, 22), (8, 28), (16, 30)], METAL, bias=0.05)
    spr.poly([(16, 28), (6, 30), (4, 38), (14, 36)], MIKU_CLOTH[1:5])
    spr.poly([(18, 24), (8, 18), (10, 20), (18, 26)], MIKU_HAIR[-4:])
    # Right wing
    spr.poly([(46, 22), (60, 16), (62, 22), (56, 28), (48, 30)], METAL, bias=0.05)
    spr.poly([(48, 28), (58, 30), (60, 38), (50, 36)], MIKU_CLOTH[1:5])
    spr.poly([(46, 24), (56, 18), (54, 20), (46, 26)], MIKU_HAIR[-4:])
    # Root struts
    spr.capsule(22, 26, 30, 30, 1.4, METAL)
    spr.capsule(42, 26, 34, 30, 1.4, METAL)
    spr.outline()
    return spr.im


def shoulders():
    spr = Spr()
    # Encore pads sit on the shoulders, center of the head left clear.
    spr.ellipse(24, 22, 6.5, 4.2, METAL, bias=0.05)
    spr.ellipse(24, 21, 4.2, 2.4, TETO_CLOTH[2:6], bias=0.1)
    spr.ellipse(24, 20, 1.6, 1.2, GOLD[-3:], bias=0.3)
    spr.ellipse(42, 22, 6.5, 4.2, METAL, bias=0.05)
    spr.ellipse(42, 21, 4.2, 2.4, TETO_CLOTH[2:6], bias=0.1)
    spr.ellipse(42, 20, 1.6, 1.2, GOLD[-3:], bias=0.3)
    # Strap hint
    spr.capsule(28, 24, 36, 24, 1.1, INK[1:4])
    spr.outline()
    return spr.im


def save(im, name):
    path = os.path.join(OUT, name)
    im.save(path)
    print(name, im.size)


def preview(sheets):
    # 2x integer, Miku column and Teto column of pose strips.
    labels_h = 0
    gap = 4
    col_w = 0
    rows = []
    order = ["idle", "run", "jump", "slide", "action"]
    for kind in ("miku", "teto"):
        strips = []
        for key in order:
            fr = sheets[(kind, key)]
            big = fr.resize((fr.width * 2, fr.height * 2), Image.NEAREST)
            strips.append(big)
        width = max(s.width for s in strips)
        height = sum(s.height for s in strips) + gap * (len(strips) - 1)
        col = Image.new("RGBA", (width, height), (12, 10, 18, 255))
        y = 0
        for s in strips:
            col.paste(s, (0, y), s)
            y += s.height + gap
        rows.append(col)
        col_w = max(col_w, col.width)
    pad = 8
    H = max(c.height for c in rows)
    canvas = Image.new("RGBA", (rows[0].width + rows[1].width + pad * 3, H + pad * 2), (12, 10, 18, 255))
    canvas.paste(rows[0], (pad, pad))
    canvas.paste(rows[1], (pad * 2 + rows[0].width, pad))
    os.makedirs(DOCS, exist_ok=True)
    path = os.path.join(DOCS, "preview_idols_046.png")
    canvas.save(path)
    print("preview", canvas.size, path)


def main():
    os.makedirs(OUT, exist_ok=True)
    sheets = {}
    for kind in ("miku", "teto"):
        pack = poses_for(kind)
        sheets[(kind, "idle")] = hstack([draw_idol(kind, p) for p in pack["idle"]])
        sheets[(kind, "run")] = hstack([draw_idol(kind, p) for p in pack["run"]])
        sheets[(kind, "jump")] = hstack([draw_idol(kind, p) for p in pack["jump"]])
        sheets[(kind, "slide")] = pack and draw_idol(kind, pack["slide"][0])
        action_name = "shoot" if kind == "miku" else "saber"
        sheets[(kind, "action")] = draw_idol(kind, pack["action"][0])
        save(sheets[(kind, "idle")], f"{kind}_idle.png")
        save(sheets[(kind, "run")], f"{kind}_run.png")
        save(sheets[(kind, "jump")], f"{kind}_jump.png")
        save(sheets[(kind, "slide")], f"{kind}_slide.png")
        save(sheets[(kind, "action")], f"{kind}_{action_name}.png")
    save(wings(), "armor_wings.png")
    save(shoulders(), "armor_shoulders.png")
    preview(sheets)


if __name__ == "__main__":
    main()
