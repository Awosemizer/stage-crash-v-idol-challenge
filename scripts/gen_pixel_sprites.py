#!/usr/bin/env python3
"""Generate original pixel-art placeholders for Stage Crash (Miku/Teto / SynthoCorp).
NOT Capcom assets — original silhouettes at Mega Man X3-ish density (16px tiles).
"""
from __future__ import annotations
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / "game" / "assets" / "sprites"
TRANSPARENT = (0, 0, 0, 0)


def new_img(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), TRANSPARENT)


def px(img: Image.Image, x: int, y: int, c: tuple) -> None:
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c)


def fill_rect(img: Image.Image, x0, y0, x1, y1, c) -> None:
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px(img, x, y, c)


def outline_rect(img, x0, y0, x1, y1, c) -> None:
    for x in range(x0, x1 + 1):
        px(img, x, y0, c)
        px(img, x, y1, c)
    for y in range(y0, y1 + 1):
        px(img, x0, y, c)
        px(img, x1, y, c)


def disc(img, cx, cy, r, c) -> None:
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r + r * 0.2:
                px(img, x, y, c)


def save(img: Image.Image, rel: str) -> None:
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    # Nearest-neighbor friendly: already 1:1 pixels
    img.save(path, "PNG")
    print("wrote", path.relative_to(ROOT.parent.parent))


# ---------- palette helpers ----------
def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


# ===================== PLAYER =====================
def draw_player_frame(char: str, pose: str, frame: int = 0) -> Image.Image:
    """16x32 character sprite. char=miku|teto. pose=idle|run|jump|slide."""
    img = new_img(16, 32)
    if char == "miku":
        hair = (57, 230, 240, 255)
        hair_dk = (30, 160, 180, 255)
        body = (45, 200, 215, 255)
        body_lt = (120, 235, 245, 255)
        accent = (255, 120, 180, 255)  # tie
        skin = (255, 224, 200, 255)
        boot = (35, 90, 110, 255)
        eye = (40, 60, 80, 255)
    else:
        hair = (230, 70, 85, 255)
        hair_dk = (160, 35, 50, 255)
        body = (220, 60, 75, 255)
        body_lt = (245, 130, 140, 255)
        accent = (255, 220, 80, 255)  # drill tips / sash
        skin = (255, 224, 200, 255)
        boot = (90, 30, 40, 255)
        eye = (50, 40, 45, 255)

    # bob for run
    bob = 0
    leg_off = 0
    arm_off = 0
    if pose == "run":
        cycle = frame % 8
        bob = 0 if cycle in (0, 1, 4, 5) else 1
        leg_table = [-2, -1, 0, 1, 2, 1, 0, -1]
        arm_table = [1, 1, 0, -1, -1, -1, 0, 1]
        leg_off = leg_table[cycle]
        arm_off = arm_table[cycle]
    elif pose == "jump":
        bob = -2 if frame % 2 == 0 else -1
        leg_off = -1 if frame % 2 == 0 else 1
    elif pose == "idle":
        bob = 0 if frame % 2 == 0 else 0
        # blink on odd idle frame handled below via eye skip
    elif pose == "slide":
        # drawn differently — wider low body
        return draw_slide(char)

    y0 = 2 + bob  # head top

    # twin-tails / drills
    if char == "miku":
        # left pigtail
        fill_rect(img, 1, y0 + 4, 3, y0 + 14, hair)
        fill_rect(img, 0, y0 + 10, 2, y0 + 18, hair_dk)
        # right
        fill_rect(img, 12, y0 + 4, 14, y0 + 14, hair)
        fill_rect(img, 13, y0 + 10, 15, y0 + 18, hair_dk)
        # bangs
        fill_rect(img, 4, y0, 11, y0 + 3, hair)
        fill_rect(img, 5, y0 + 1, 10, y0 + 2, hair_lt if False else hair)
    else:
        # drill hair cones
        for i, side in enumerate([(2, -1), (13, 1)]):
            sx, d = side
            fill_rect(img, sx, y0 + 2, sx + d * 0 + (1 if d > 0 else 0), y0 + 6, hair)
            # spiral-ish drills
            fill_rect(img, sx - (1 if d < 0 else 0), y0 + 6, sx + (2 if d > 0 else 1), y0 + 12, hair)
            fill_rect(img, sx + (1 if d > 0 else -1), y0 + 12, sx + (2 if d > 0 else 0), y0 + 18, hair_dk)
            px(img, sx + (2 if d > 0 else -1), y0 + 18, accent)
        fill_rect(img, 4, y0, 11, y0 + 3, hair)

    # head
    fill_rect(img, 5, y0 + 3, 10, y0 + 9, skin)
    # eyes (blink on idle odd frames)
    if pose == "idle" and frame % 2 == 1:
        px(img, 6, y0 + 6, eye)
        px(img, 9, y0 + 6, eye)
    else:
        px(img, 6, y0 + 6, eye)
        px(img, 9, y0 + 6, eye)
        px(img, 6, y0 + 5, (255, 255, 255, 200))
        px(img, 9, y0 + 5, (255, 255, 255, 200))
    # headset / mic
    if char == "miku":
        fill_rect(img, 4, y0 + 5, 4, y0 + 8, (80, 90, 100, 255))
        fill_rect(img, 11, y0 + 5, 11, y0 + 8, (80, 90, 100, 255))
        px(img, 3, y0 + 7, body_lt)
    else:
        # bow
        fill_rect(img, 7, y0 + 1, 8, y0 + 2, accent)

    # torso armor / suit
    fill_rect(img, 5, y0 + 10, 10, y0 + 18, body)
    fill_rect(img, 6, y0 + 11, 9, y0 + 14, body_lt)
    # chest gem / core
    fill_rect(img, 7, y0 + 12, 8, y0 + 13, accent)
    # skirt / shorts
    fill_rect(img, 4, y0 + 18, 11, y0 + 20, body_lt if char == "miku" else body)

    # arms
    ax = arm_off
    fill_rect(img, 3 + ax, y0 + 11, 4 + ax, y0 + 17, body)
    fill_rect(img, 11 - ax, y0 + 11, 12 - ax, y0 + 17, body)
    # fists / buster hint
    if char == "miku":
        fill_rect(img, 12 - ax, y0 + 16, 14 - ax, y0 + 18, body_lt)  # buster arm right
    else:
        fill_rect(img, 12 - ax, y0 + 15, 14 - ax, y0 + 18, accent)  # saber glow

    # legs
    if pose == "jump":
        fill_rect(img, 5, y0 + 21, 7, y0 + 27, body)
        fill_rect(img, 8, y0 + 21, 10, y0 + 26, body)
        fill_rect(img, 5, y0 + 27, 7, y0 + 29, boot)
        fill_rect(img, 8, y0 + 26, 10, y0 + 28, boot)
    else:
        fill_rect(img, 5, y0 + 21, 7, y0 + 27 + leg_off, body)
        fill_rect(img, 8, y0 + 21, 10, y0 + 27 - leg_off, body)
        fill_rect(img, 5, y0 + 27 + max(leg_off, 0), 7, y0 + 29 + max(leg_off, 0), boot)
        fill_rect(img, 8, y0 + 27 - min(leg_off, 0), 10, y0 + 29 - min(leg_off, 0), boot)

    # outline dark edges lightly
    for x, y in [(5, y0 + 3), (10, y0 + 3), (5, y0 + 10), (10, y0 + 10)]:
        pass
    return img


def draw_slide(char: str) -> Image.Image:
    img = new_img(24, 16)
    if char == "miku":
        body = (45, 200, 215, 255)
        hair = (57, 230, 240, 255)
        accent = (255, 120, 180, 255)
        boot = (35, 90, 110, 255)
        skin = (255, 224, 200, 255)
    else:
        body = (220, 60, 75, 255)
        hair = (230, 70, 85, 255)
        accent = (255, 220, 80, 255)
        boot = (90, 30, 40, 255)
        skin = (255, 224, 200, 255)
    # low crouch body
    fill_rect(img, 4, 4, 18, 11, body)
    fill_rect(img, 6, 5, 12, 8, skin)  # head facing right
    fill_rect(img, 2, 3, 8, 7, hair)
    fill_rect(img, 18, 6, 22, 12, boot)
    fill_rect(img, 10, 7, 11, 8, accent)
    # motion lines
    for i in range(3):
        px(img, 1 + i, 8 + i, (255, 255, 255, 120))
    return img


def gen_players() -> None:
    for char in ("miku", "teto"):
        # idle 2-frame blink sheet
        idle_sheet = new_img(32, 32)
        for f in range(2):
            fr = draw_player_frame(char, "idle", f)
            idle_sheet.paste(fr, (f * 16, 0), fr)
        save(idle_sheet, f"player/{char}_idle.png")
        # run sheet 8 frames × 16
        sheet = new_img(128, 32)
        for f in range(8):
            fr = draw_player_frame(char, "run", f)
            sheet.paste(fr, (f * 16, 0), fr)
        save(sheet, f"player/{char}_run.png")
        # jump 2 poses (ascent / apex)
        jump_sheet = new_img(32, 32)
        for f in range(2):
            fr = draw_player_frame(char, "jump", f)
            jump_sheet.paste(fr, (f * 16, 0), fr)
        save(jump_sheet, f"player/{char}_jump.png")
        save(draw_slide(char), f"player/{char}_slide.png")


# ===================== MET-BEAT =====================
def gen_met() -> None:
    # closed 16x16
    closed = new_img(16, 16)
    shell = (110, 125, 145, 255)
    shell_lt = (160, 175, 195, 255)
    shell_dk = (70, 80, 95, 255)
    disc(closed, 8, 9, 6, shell)
    disc(closed, 8, 8, 5, shell_lt)
    fill_rect(closed, 5, 5, 11, 7, shell_dk)
    # rivets
    for x in (5, 8, 11):
        px(closed, x, 6, (220, 220, 230, 255))
    # feet
    fill_rect(closed, 4, 14, 6, 15, shell_dk)
    fill_rect(closed, 9, 14, 11, 15, shell_dk)
    save(closed, "enemies/met_closed.png")

    opened = new_img(16, 16)
    body = (210, 80, 95, 255)
    body_lt = (240, 140, 150, 255)
    disc(opened, 8, 10, 5, body)
    fill_rect(opened, 5, 6, 11, 10, body_lt)
    # eye
    fill_rect(opened, 6, 7, 9, 10, (255, 240, 80, 255))
    px(opened, 7, 8, (40, 30, 20, 255))
    px(opened, 8, 8, (40, 30, 20, 255))
    # shell lifted
    fill_rect(opened, 4, 2, 11, 5, shell_lt)
    outline_rect(opened, 4, 2, 11, 5, shell_dk)
    fill_rect(opened, 4, 14, 6, 15, (90, 40, 50, 255))
    fill_rect(opened, 9, 14, 11, 15, (90, 40, 50, 255))
    # music note hint
    px(opened, 12, 4, (255, 255, 255, 200))
    save(opened, "enemies/met_open.png")


# ===================== BOSSES =====================
BOSS_SPECS = {
    "beatfire": {
        "body": (220, 60, 35, 255),
        "trim": (255, 180, 60, 255),
        "accent": (255, 90, 20, 255),
        "motif": "drum",
    },
    "echo_wind": {
        "body": (90, 210, 170, 255),
        "trim": (200, 255, 230, 255),
        "accent": (60, 160, 140, 255),
        "motif": "scarf",
    },
    "neon_volt": {
        "body": (230, 220, 60, 255),
        "trim": (80, 80, 90, 255),
        "accent": (255, 255, 180, 255),
        "motif": "bolt",
    },
    "glitch_ice": {
        "body": (120, 200, 240, 255),
        "trim": (220, 245, 255, 255),
        "accent": (80, 140, 200, 255),
        "motif": "crystal",
    },
    "chorus_bloom": {
        "body": (220, 100, 180, 255),
        "trim": (100, 210, 120, 255),
        "accent": (255, 180, 220, 255),
        "motif": "petal",
    },
    "bassquake": {
        "body": (180, 120, 55, 255),
        "trim": (240, 200, 80, 255),
        "accent": (120, 70, 30, 255),
        "motif": "amp",
    },
    "metronome": {
        "body": (160, 165, 190, 255),
        "trim": (240, 240, 250, 255),
        "accent": (60, 60, 80, 255),
        "motif": "pendulum",
    },
    "static_shadow": {
        "body": (70, 60, 100, 255),
        "trim": (180, 170, 220, 255),
        "accent": (40, 35, 55, 255),
        "motif": "static",
    },
    "core9": {
        "body": (140, 60, 200, 255),
        "trim": (255, 120, 220, 255),
        "accent": (80, 220, 255, 255),
        "motif": "core",
    },
    "overdub": {
        "body": (130, 90, 200, 255),
        "trim": (240, 200, 80, 255),
        "accent": (90, 60, 140, 255),
        "motif": "titan",
    },
    "refrain": {
        "body": (240, 80, 200, 255),
        "trim": (80, 220, 255, 255),
        "accent": (180, 40, 150, 255),
        "motif": "mirror",
    },
}


def draw_boss(name: str, w: int = 24, h: int = 36) -> Image.Image:
    spec = BOSS_SPECS[name]
    body, trim, accent = spec["body"], spec["trim"], spec["accent"]
    motif = spec["motif"]
    img = new_img(w, h)
    # legs
    fill_rect(img, 6, 26, 10, 34, body)
    fill_rect(img, 13, 26, 17, 34, body)
    fill_rect(img, 5, 33, 10, 35, accent)
    fill_rect(img, 13, 33, 18, 35, accent)
    # torso
    fill_rect(img, 5, 12, 18, 26, body)
    fill_rect(img, 7, 14, 16, 20, trim)
    # head
    fill_rect(img, 7, 4, 16, 12, body)
    fill_rect(img, 8, 5, 15, 10, trim)
    # eyes
    px(img, 9, 7, accent)
    px(img, 14, 7, accent)
    px(img, 9, 8, (255, 255, 255, 220))
    px(img, 14, 8, (255, 255, 255, 220))
    # shoulders / arms
    fill_rect(img, 2, 13, 5, 22, body)
    fill_rect(img, 18, 13, 21, 22, body)

    if motif == "drum":
        disc(img, 12, 20, 5, accent)
        outline_rect(img, 8, 16, 15, 24, (40, 15, 10, 255))
        fill_rect(img, 3, 8, 5, 10, trim)  # spikes
        fill_rect(img, 18, 8, 20, 10, trim)
    elif motif == "scarf":
        for i in range(6):
            fill_rect(img, 16 + (i % 2), 12 + i * 2, 20, 13 + i * 2, trim)
        fill_rect(img, 4, 2, 8, 4, trim)  # wind hair
    elif motif == "bolt":
        # lightning arm
        pts = [(19, 14), (21, 18), (18, 18), (22, 24)]
        for x, y in pts:
            px(img, x, y, accent)
            px(img, x + 1, y, accent)
        fill_rect(img, 10, 16, 13, 18, (40, 40, 50, 255))
    elif motif == "crystal":
        fill_rect(img, 11, 0, 12, 4, trim)
        fill_rect(img, 9, 2, 10, 5, trim)
        fill_rect(img, 13, 2, 14, 5, trim)
        # glitch pixels
        for x, y in [(6, 15), (17, 18), (8, 22)]:
            px(img, x, y, (255, 80, 200, 200))
    elif motif == "petal":
        for ang in range(5):
            ox = 12 + (ang - 2) * 2
            fill_rect(img, ox, 10, ox + 1, 13, trim)
        fill_rect(img, 3, 16, 6, 19, trim)
        fill_rect(img, 17, 16, 20, 19, trim)
    elif motif == "amp":
        # speaker circles
        disc(img, 12, 19, 4, accent)
        disc(img, 12, 19, 2, trim)
        fill_rect(img, 4, 8, 6, 11, trim)
        fill_rect(img, 17, 8, 19, 11, trim)
    elif motif == "pendulum":
        fill_rect(img, 11, 0, 12, 8, accent)
        disc(img, 12, 10, 3, trim)
        fill_rect(img, 7, 18, 16, 20, accent)
    elif motif == "static":
        for y in range(12, 26, 2):
            for x in range(6, 18):
                if (x + y) % 3 == 0:
                    px(img, x, y, trim)
        fill_rect(img, 8, 6, 9, 8, (255, 255, 255, 180))
        fill_rect(img, 14, 6, 15, 8, (255, 255, 255, 180))
    elif motif == "core":
        disc(img, 12, 18, 6, accent)
        disc(img, 12, 18, 3, trim)
        px(img, 12, 18, (255, 255, 255, 255))
        # orbit dots
        for x, y in [(5, 12), (19, 12), (5, 24), (19, 24)]:
            px(img, x, y, trim)
    elif motif == "titan":
        fill_rect(img, 3, 10, 6, 28, body)
        fill_rect(img, 17, 10, 20, 28, body)
        fill_rect(img, 8, 8, 15, 11, trim)
    elif motif == "mirror":
        outline_rect(img, 6, 6, 17, 28, trim)
        fill_rect(img, 10, 14, 13, 20, accent)

    # helmet crest
    fill_rect(img, 10, 2, 13, 4, trim)
    return img


def draw_boss_attack(name: str, w: int = 24, h: int = 36) -> Image.Image:
    """Attack / telegraph pose — arms raised, motif exaggerated."""
    img = draw_boss(name, w, h)
    spec = BOSS_SPECS[name]
    trim, accent = spec["trim"], spec["accent"]
    # raise arms
    fill_rect(img, 1, 6, 5, 14, spec["body"])
    fill_rect(img, 18, 6, 22, 14, spec["body"])
    fill_rect(img, 1, 5, 4, 7, accent)
    fill_rect(img, 19, 5, 22, 7, accent)
    # glow core
    disc(img, 12, 18, 4, accent)
    # telegraph sparks
    for x, y in [(3, 4), (20, 4), (0, 16), (23, 16), (11, 1)]:
        px(img, x, y, trim)
    return img


def gen_bosses() -> None:
    for name in BOSS_SPECS:
        idle = draw_boss(name)
        atk = draw_boss_attack(name)
        sheet = new_img(48, 36)
        sheet.paste(idle, (0, 0), idle)
        sheet.paste(atk, (24, 0), atk)
        save(sheet, f"bosses/{name}.png")
        # UI portrait 32x32 from idle
        big = draw_boss(name, 32, 40)
        portrait = new_img(32, 32)
        portrait.paste(big, (4, -4), big)
        outline_rect(portrait, 0, 0, 31, 31, (255, 255, 255, 180))
        # inner accent frame
        outline_rect(portrait, 1, 1, 30, 30, spec_accent_frame(name))
        save(portrait, f"ui/portrait_{name}.png")


def spec_accent_frame(name: str):
    c = BOSS_SPECS[name]["accent"]
    return (c[0], c[1], c[2], 200)


# ===================== TILES =====================
TILE_THEMES = {
    "beatfire": [(120, 50, 55), (90, 35, 40), (160, 80, 70), (200, 120, 90)],
    "echo_wind": [(50, 110, 100), (40, 90, 85), (90, 160, 140), (180, 220, 210)],
    "neon_volt": [(50, 50, 40), (80, 75, 30), (200, 200, 60), (40, 40, 45)],
    "glitch_ice": [(70, 120, 150), (100, 170, 200), (200, 230, 245), (60, 90, 120)],
    "chorus_bloom": [(70, 90, 55), (100, 60, 80), (140, 180, 90), (200, 120, 160)],
    "bassquake": [(90, 70, 40), (60, 45, 25), (150, 110, 60), (200, 160, 80)],
    "metronome": [(70, 70, 85), (50, 50, 65), (140, 145, 165), (220, 220, 235)],
    "static_shadow": [(40, 35, 55), (30, 25, 40), (80, 70, 110), (160, 150, 190)],
    "fortress": [(55, 40, 70), (35, 25, 50), (120, 70, 160), (80, 200, 220)],
    "default": [(80, 55, 60), (55, 40, 45), (120, 80, 70), (160, 120, 100)],
}


def draw_tile(theme: str, variant: int) -> Image.Image:
    cols = TILE_THEMES.get(theme, TILE_THEMES["default"])
    base = (*cols[variant % 2], 255)
    mid = (*cols[2], 255)
    hi = (*cols[3], 255)
    dk = tuple(max(0, c - 40) for c in base[:3]) + (255,)
    img = new_img(16, 16)
    fill_rect(img, 0, 0, 15, 15, base)
    # top highlight edge
    fill_rect(img, 0, 0, 15, 1, hi)
    fill_rect(img, 0, 1, 15, 1, mid)
    # bottom shadow
    fill_rect(img, 0, 14, 15, 15, dk)
    # brick / panel pattern by theme
    if theme in ("beatfire", "bassquake", "default"):
        # brick
        fill_rect(img, 0, 7, 15, 7, dk)
        fill_rect(img, 7 if variant % 2 == 0 else 3, 0, 7 if variant % 2 == 0 else 3, 7, dk)
        fill_rect(img, 3 if variant % 2 == 0 else 11, 8, 3 if variant % 2 == 0 else 11, 15, dk)
    elif theme in ("echo_wind", "chorus_bloom"):
        # organic / vine dots
        for x, y in [(3, 4), (10, 5), (6, 10), (12, 12)]:
            px(img, x, y, hi)
            px(img, x + 1, y + 1, mid)
    elif theme == "neon_volt":
        # circuit
        fill_rect(img, 2, 4, 13, 4, hi)
        fill_rect(img, 8, 4, 8, 12, hi)
        px(img, 4, 8, mid)
        px(img, 12, 10, mid)
    elif theme == "glitch_ice":
        # crystal facets
        for i in range(0, 16, 4):
            fill_rect(img, i, i // 2, i + 2, i // 2 + 2, hi)
        px(img, 14, 3, (255, 100, 200, 180))
    elif theme == "metronome":
        # metal panels
        outline_rect(img, 1, 1, 14, 14, dk)
        fill_rect(img, 3, 3, 6, 6, mid)
        fill_rect(img, 9, 9, 12, 12, mid)
    elif theme == "static_shadow":
        for y in range(16):
            for x in range(16):
                if (x * 3 + y * 5 + variant) % 7 == 0:
                    px(img, x, y, hi)
    elif theme == "fortress":
        outline_rect(img, 0, 0, 15, 15, dk)
        disc(img, 8, 8, 3, mid)
        px(img, 8, 8, hi)
    # corner screws
    for x, y in [(1, 2), (14, 2), (1, 13), (14, 13)]:
        px(img, x, y, hi)
    return img


def gen_tiles() -> None:
    for theme in TILE_THEMES:
        sheet = new_img(48, 16)
        for v in range(3):
            t = draw_tile(theme, v)
            sheet.paste(t, (v * 16, 0), t)
        save(sheet, f"tiles/{theme}.png")


# ===================== UI =====================
def gen_ui() -> None:
    # Miku / Teto portraits 48x48
    for char, hair, body in (
        ("miku", (57, 230, 240, 255), (45, 200, 215, 255)),
        ("teto", (230, 70, 85, 255), (220, 60, 75, 255)),
    ):
        img = new_img(48, 48)
        fill_rect(img, 0, 0, 47, 47, (20, 18, 35, 255))
        outline_rect(img, 0, 0, 47, 47, hair)
        # big head
        fill_rect(img, 14, 10, 33, 28, (255, 224, 200, 255))
        fill_rect(img, 12, 6, 35, 14, hair)
        if char == "miku":
            fill_rect(img, 6, 12, 12, 36, hair)
            fill_rect(img, 35, 12, 41, 36, hair)
        else:
            # drills
            for sx, d in ((8, -1), (38, 1)):
                fill_rect(img, sx, 10, sx + 3, 30, hair)
                px(img, sx + (3 if d > 0 else 0), 32, (255, 220, 80, 255))
        # eyes
        fill_rect(img, 18, 16, 21, 20, (40, 50, 60, 255))
        fill_rect(img, 26, 16, 29, 20, (40, 50, 60, 255))
        px(img, 19, 17, (255, 255, 255, 230))
        px(img, 27, 17, (255, 255, 255, 230))
        # torso
        fill_rect(img, 16, 28, 31, 44, body)
        fill_rect(img, 20, 32, 27, 36, (255, 120, 180, 255) if char == "miku" else (255, 220, 80, 255))
        save(img, f"ui/portrait_{char}.png")

    # title banner
    banner = new_img(192, 32)
    fill_rect(banner, 0, 0, 191, 31, (12, 10, 28, 255))
    # cyan / red bars
    fill_rect(banner, 0, 0, 191, 2, (57, 230, 240, 255))
    fill_rect(banner, 0, 29, 191, 31, (230, 70, 85, 255))
    # pixel stars
    for x, y in [(10, 10), (40, 16), (80, 8), (120, 18), (160, 12), (180, 20)]:
        px(banner, x, y, (255, 255, 255, 200))
        px(banner, x + 1, y, (180, 220, 255, 160))
    # dual idols silhouettes small
    fill_rect(banner, 20, 8, 28, 24, (57, 230, 240, 200))
    fill_rect(banner, 163, 8, 171, 24, (230, 70, 85, 200))
    save(banner, "ui/title_banner.png")

    # synthocorp logo mark
    logo = new_img(24, 24)
    fill_rect(logo, 2, 2, 21, 21, (30, 20, 50, 255))
    outline_rect(logo, 2, 2, 21, 21, (180, 80, 255, 255))
    disc(logo, 12, 12, 6, (80, 220, 255, 255))
    disc(logo, 12, 12, 3, (255, 100, 200, 255))
    px(logo, 12, 12, (255, 255, 255, 255))
    save(logo, "ui/synthocorp_mark.png")


def gen_fx() -> None:
    # hit spark 4 frames × 16
    sheet = new_img(64, 16)
    cols = [(255, 255, 220, 255), (255, 200, 80, 255), (255, 120, 40, 255), (200, 80, 255, 255)]
    for f in range(4):
        fr = new_img(16, 16)
        c = cols[f]
        r = 1 + f
        disc(fr, 8, 8, r, c)
        for ang in range(8):
            ox = int(8 + (3 + f) * (1 if ang % 2 == 0 else -1) * (1 if ang < 4 else 0.5))
            oy = int(8 + (3 + f) * (1 if (ang // 2) % 2 == 0 else -1) * (0.5 if ang < 4 else 1))
            px(fr, ox, oy, c)
            px(fr, ox + 1, oy, (255, 255, 255, 180))
        sheet.paste(fr, (f * 16, 0), fr)
    save(sheet, "fx/hit_spark.png")

    # muzzle flash 3 frames
    muzzle = new_img(48, 16)
    for f in range(3):
        fr = new_img(16, 16)
        c = (180, 230, 255, 255) if f < 2 else (255, 240, 120, 255)
        fill_rect(fr, 2, 6, 14 - f, 9, c)
        fill_rect(fr, 10 - f, 4, 14, 11, (255, 255, 255, 220))
        for y in (5, 10):
            px(fr, 14, y, c)
        muzzle.paste(fr, (f * 16, 0), fr)
    save(muzzle, "fx/muzzle.png")

    # slash arc 3 frames (24x24)
    slash = new_img(72, 24)
    for f in range(3):
        fr = new_img(24, 24)
        c = (255, 120, 160, 255) if f != 1 else (255, 230, 120, 255)
        # crescent
        for y in range(4, 20):
            x0 = 4 + abs(y - 12) // 2 + f
            x1 = 18 - abs(y - 12) // 3 + f
            for x in range(x0, min(x1, 23)):
                px(fr, x, y, c if (x + y + f) % 2 == 0 else (255, 255, 255, 200))
        slash.paste(fr, (f * 24, 0), fr)
    save(slash, "fx/slash_arc.png")

    # charge aura rings (inner/outer) 2×32
    rings = new_img(64, 32)
    for f, col in enumerate([(80, 200, 255, 180), (255, 220, 80, 200)]):
        fr = new_img(32, 32)
        for y in range(32):
            for x in range(32):
                dx, dy = x - 16, y - 16
                d2 = dx * dx + dy * dy
                if 10 * 10 <= d2 <= 14 * 14 or (f == 1 and 7 * 7 <= d2 <= 9 * 9):
                    px(fr, x, y, col)
                if d2 <= 3 * 3:
                    px(fr, x, y, (255, 255, 255, 90))
        rings.paste(fr, (f * 32, 0), fr)
    save(rings, "fx/charge_ring.png")


def gen_parallax() -> None:
    themes = {
        "beatfire": [(40, 12, 18), (90, 30, 25), (180, 70, 40)],
        "echo_wind": [(10, 30, 40), (40, 90, 80), (140, 210, 190)],
        "neon_volt": [(20, 12, 40), (60, 40, 20), (220, 220, 60)],
        "glitch_ice": [(12, 24, 40), (50, 110, 150), (180, 230, 250)],
        "chorus_bloom": [(20, 35, 22), (80, 40, 70), (200, 120, 170)],
        "bassquake": [(30, 22, 12), (80, 55, 25), (180, 130, 50)],
        "metronome": [(18, 18, 28), (50, 50, 70), (180, 185, 210)],
        "static_shadow": [(12, 10, 22), (40, 30, 60), (140, 120, 180)],
        "fortress": [(15, 8, 28), (50, 25, 70), (120, 60, 180)],
        "default": [(20, 15, 25), (50, 35, 45), (120, 90, 80)],
    }
    for theme, cols in themes.items():
        far = new_img(128, 64)
        fill_rect(far, 0, 0, 127, 63, (*cols[0], 255))
        # distant silhouettes
        for i, h in enumerate([20, 28, 18, 32, 22, 26, 16, 30]):
            x0 = i * 16
            fill_rect(far, x0, 64 - h, x0 + 14, 63, (*cols[1], 220))
            # windows
            if h > 22:
                for wy in range(64 - h + 4, 60, 6):
                    px(far, x0 + 4, wy, (*cols[2], 180))
                    px(far, x0 + 9, wy, (*cols[2], 180))
        save(far, f"bg/parallax_{theme}_far.png")

        mid = new_img(160, 64)
        fill_rect(mid, 0, 40, 159, 63, (*cols[1], 0))  # transparent upper
        for i in range(10):
            x0 = i * 16
            h = 18 + (i * 5) % 14
            fill_rect(mid, x0, 64 - h, x0 + 12, 63, (*cols[1], 200))
            fill_rect(mid, x0 + 2, 64 - h + 2, x0 + 5, 64 - h + 5, (*cols[2], 160))
        # floating motifs
        for x, y in [(20, 20), (70, 12), (120, 18), (145, 28)]:
            disc(mid, x, y, 2, (*cols[2], 150))
        save(mid, f"bg/parallax_{theme}_mid.png")


def gen_ui_chrome() -> None:
    # title panel chrome
    panel = new_img(128, 48)
    fill_rect(panel, 0, 0, 127, 47, (18, 14, 32, 255))
    outline_rect(panel, 0, 0, 127, 47, (57, 230, 240, 255))
    outline_rect(panel, 2, 2, 125, 45, (230, 70, 85, 200))
    for x in range(8, 120, 8):
        px(panel, x, 4, (255, 255, 255, 120))
    save(panel, "ui/panel_chrome.png")

    # boss select cell frame
    frame = new_img(32, 32)
    fill_rect(frame, 0, 0, 31, 31, (0, 0, 0, 0))
    outline_rect(frame, 0, 0, 31, 31, (255, 255, 255, 200))
    outline_rect(frame, 1, 1, 30, 30, (100, 220, 255, 160))
    px(frame, 0, 0, (255, 220, 80, 255))
    px(frame, 31, 0, (255, 220, 80, 255))
    px(frame, 0, 31, (255, 220, 80, 255))
    px(frame, 31, 31, (255, 220, 80, 255))
    save(frame, "ui/select_frame.png")

    # richer title banner
    banner = new_img(224, 40)
    fill_rect(banner, 0, 0, 223, 39, (10, 8, 24, 255))
    fill_rect(banner, 0, 0, 223, 3, (57, 230, 240, 255))
    fill_rect(banner, 0, 36, 223, 39, (230, 70, 85, 255))
    # scanlines
    for y in range(6, 34, 2):
        for x in range(0, 224, 3):
            px(banner, x, y, (40, 30, 60, 80))
    # stars
    for x, y in [(12, 12), (36, 22), (64, 10), (100, 18), (140, 12), (170, 24), (200, 14)]:
        px(banner, x, y, (255, 255, 255, 220))
        px(banner, x + 1, y, (180, 220, 255, 140))
    fill_rect(banner, 24, 10, 36, 28, (57, 230, 240, 210))
    fill_rect(banner, 188, 10, 200, 28, (230, 70, 85, 210))
    # center gem
    disc(banner, 112, 20, 5, (180, 80, 255, 255))
    disc(banner, 112, 20, 2, (255, 255, 255, 255))
    save(banner, "ui/title_banner.png")


def main() -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    gen_players()
    gen_met()
    gen_bosses()
    gen_tiles()
    gen_ui()
    gen_ui_chrome()
    gen_fx()
    gen_parallax()
    print("DONE sprites →", ROOT)


if __name__ == "__main__":
    main()
