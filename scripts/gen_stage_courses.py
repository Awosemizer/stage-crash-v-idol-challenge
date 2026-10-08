#!/usr/bin/env python3
"""Stage Crash — regenerate the 8 robot-master courses (v0.56 long stages).

Each stage is a chain of ~1-screen sections. Physics budget (Player.gd, unchanged):
  jump ~40px Miku / ~36px Teto (discrete apex ~38 / ~34) -> required rises <= 24px (v0.60)
  flat gaps <= 48px, 16px rise gaps <= 40px, 32px rise gaps <= 16px
  wall-jump shaft 36px open air with a mid foothold
Thin catwalks are one-way (jump up through them), floors and walls are solid.
Secrets: alcove inside the shaft's right wall, sealed with BreakableBlock in COL_WALL.

Rewrites in each level script: LEVEL_RIGHT / ARENA_LEFT / GATE_X, _build_course(),
_spawn_enemies(), _add_mid_checkpoints(), the spawn point, the secret coordinates and
_add_rect_platform(..., one_way). Arena / boss / flow code is left untouched.
usage: python3 scripts/gen_stage_courses.py [stage ...]
"""
import re, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
LEVELS = ROOT / "game/scripts/levels"
FY = 176  # floor top


class Course:
    def __init__(self, alt):
        self.alt = alt
        self.solids, self.catwalks, self.spikes, self.mets = [], [], [], []
        self.cks, self.gimmick, self.secret, self.notes = [], [], None, []
        self.want_secret = True
        self.seals = []

    def floor(self, x, w, top=FY, col="COL_FLOOR"):
        self.solids.append((x, top, w, 224 - top, col))

    def block(self, x, y, w, h, col="COL_WALL"):
        self.solids.append((x, y, w, h, col))

    def cat(self, x, y, w, h=8, col=None):
        self.catwalks.append((x, y, w, h, col or self.alt))

    def spike_pit(self, x, w):
        """Spike trench: 32px deep, you can always jump back out (rise 32)."""
        self.block(x, 208, w, 16)
        sx = x + 8
        while sx < x + w - 1:
            self.spikes.append((sx, 200))
            sx += 16

    def met(self, x, floor_y=FY, extra=""):
        self.mets.append((x, floor_y, extra))

    def ck(self, x, floor_y=FY):
        self.cks.append((x, floor_y))


# ---------------------------------------------------------------- sections
def s_start(c, x0):
    c.notes.append(f"{x0}: start run")
    c.floor(x0, 320)
    c.met(x0 + 248)
    return 320


def s_trench(c, x0):
    c.notes.append(f"{x0}: spike trenches — low path jumps them, upper path catwalk")
    c.ck(x0 + 40)
    c.floor(x0, 128)
    c.spike_pit(x0 + 128, 48)
    c.floor(x0 + 176, 80)
    c.spike_pit(x0 + 256, 48)
    c.floor(x0 + 304, 144)
    c.cat(x0 + 48, 144, 56)
    c.cat(x0 + 112, 112, 208)
    c.cat(x0 + 336, 144, 56)
    c.met(x0 + 216)
    return 448


def s_pits(c, x0):
    c.notes.append(f"{x0}: bottomless gaps between raised islands")
    c.ck(x0 + 40)
    c.floor(x0, 96)
    c.floor(x0 + 136, 64, top=160, col="COL_ALT")
    c.floor(x0 + 240, 48, top=144, col="COL_ALT")
    c.floor(x0 + 336, 112)
    c.met(x0 + 408)
    return 448


def s_shaft(c, x0):
    c.notes.append(f"{x0}: wall-jump shaft 36px + mid foothold" + (", secret in the right wall" if c.want_secret else ""))
    c.ck(x0 + 40)
    c.floor(x0, 448)
    c.block(x0 + 96, 40, 16, 104)             # left wall, 32px crawl-free gap under it
    c.block(x0 + 112, 128, 10, 8, c.alt)       # mid foothold
    if not c.want_secret:
        c.block(x0 + 148, 80, 64, 96)
    else:
        c.block(x0 + 148, 80, 64, 16)          # right wall top
        c.block(x0 + 196, 96, 16, 32)          # alcove back
        c.block(x0 + 148, 128, 64, 48)         # right wall base
    c.block(x0 + 212, 80, 48, 16, "COL_FLOOR")  # high ledge
    c.cat(x0 + 276, 112, 48)
    c.cat(x0 + 340, 144, 48)
    if c.want_secret:
        c.secret = ((x0 + 148, 96, x0 + 196, 128), (x0 + 180, 110))  # whole alcove filled
    c.met(x0 + 420)
    return 448


def s_stairs(c, x0):
    c.notes.append(f"{x0}: block stairs up and down, Met on the summit")
    c.ck(x0 + 32)
    c.floor(x0, 448)
    # v0.60: 24px steps (Teto's real apex is ~34px; 32px steps needed a perfect full jump).
    for i, top in enumerate((152, 128, 104, 128, 152)):
        c.block(x0 + 64 + i * 64, top, 64, FY - top, "COL_FLOOR" if i % 2 == 0 else "COL_ALT")
    c.met(x0 + 224, 104)
    return 448


def s_pillars(c, x0):
    c.notes.append(f"{x0}: pillars over a spike floor — low path is the spikes, hop the tops")
    c.ck(x0 + 40)
    c.floor(x0, 104)
    c.spike_pit(x0 + 104, 40)  # v0.60: 40px so Teto clears gap + 16px rise with room
    c.floor(x0 + 144, 32, top=160, col="COL_ALT")
    c.spike_pit(x0 + 176, 32)
    c.floor(x0 + 208, 32, top=144, col="COL_ALT")
    c.spike_pit(x0 + 240, 32)
    c.floor(x0 + 272, 32, top=160, col="COL_ALT")
    c.spike_pit(x0 + 304, 48)
    c.floor(x0 + 352, 96)
    c.cat(x0 + 168, 112, 112)   # upper path over the pillar tops
    c.met(x0 + 416)
    return 448


def s_preboss(c, x0):
    c.notes.append(f"{x0}: corridor to the gate")
    c.ck(x0 + 40)
    c.floor(x0, 320)
    c.met(x0 + 160)
    return 320


def s_sealgate(c, x0):
    c.notes.append(f"{x0}: vocal seal door — the wall above means you have to break the seals")
    c.floor(x0, 160)
    c.block(x0 + 64, 16, 32, 112)
    c.seals += [x0 + 72, x0 + 88]
    c.met(x0 + 136)
    return 160


def s_exit(c, x0):
    c.notes.append(f"{x0}: exit run")
    c.ck(x0 + 40)
    c.floor(x0, 240)
    return 240


# ---------------------------------------------------------------- gimmicks
def g_frameskip(c, x0):
    c.notes.append(f"{x0}: frame-skip pads over a pit (upper path) / ice pillar")
    c.ck(x0 + 40)
    c.floor(x0, 112)
    c.gimmick.append(f"_add_frame_skip(Vector2({x0 + 144}, 160), Vector2({x0 + 144}, 128), Vector2(56, 12), 1.6, 0.0)")
    c.floor(x0 + 188, 40, top=144, col="COL_ALT")
    c.gimmick.append(f"_add_frame_skip(Vector2({x0 + 260}, 160), Vector2({x0 + 260}, 128), Vector2(56, 12), 1.6, 0.8)")
    c.floor(x0 + 304, 144)
    c.met(x0 + 400)
    return 448


def g_collapse(c, x0):
    c.notes.append(f"{x0}: collapsing decks bridge two wide pits")
    c.ck(x0 + 40)
    c.floor(x0, 128)
    c.gimmick.append(f"_add_collapse(Vector2({x0 + 176}, 166), Vector2(48, 12), 0.65, 0.9, 2.2)")
    c.floor(x0 + 224, 96)
    c.gimmick.append(f"_add_collapse(Vector2({x0 + 368}, 166), Vector2(48, 12), 0.65, 0.9, 2.2)")
    c.floor(x0 + 416, 32)
    c.cat(x0 + 248, 128, 48)
    return 448


def g_wind(c, x0):
    c.notes.append(f"{x0}: updraft over the first gap, light headwind over the second (wind adds every frame — keep it small)")
    c.ck(x0 + 40)
    c.floor(x0, 112)
    c.floor(x0 + 160, 64)
    c.floor(x0 + 272, 176)
    c.gimmick.append(f"_add_wind({x0 + 136}.0, 136.0, Vector2(6.0, -6.0), Vector2(48, 64))")
    c.gimmick.append(f"_add_wind({x0 + 248}.0, 136.0, Vector2(-6.0, 0.0), Vector2(48, 64))")
    c.cat(x0 + 64, 144, 48)
    c.cat(x0 + 128, 112, 128)
    c.met(x0 + 420)
    return 448


def g_electric(c, x0):
    c.notes.append(f"{x0}: electric floor panels (low path) / catwalk (upper path)")
    c.ck(x0 + 32)
    c.floor(x0, 448)
    for i, cx in enumerate((x0 + 152, x0 + 264, x0 + 376)):
        c.gimmick.append(f"_add_electric({cx}.0, 170.0, Vector2(56, 10), {0.35 * i:.2f}, 1.15)")
    c.cat(x0 + 48, 144, 48)
    c.cat(x0 + 112, 112, 96)
    c.cat(x0 + 224, 112, 96)
    c.cat(x0 + 336, 144, 56)
    c.met(x0 + 208, 112)
    return 448


def g_metro(c, x0):
    c.notes.append(f"{x0}: metronome spikes on the beat (low path) / catwalk (upper path)")
    c.ck(x0 + 32)
    c.floor(x0, 448)
    for i, sx in enumerate((x0 + 120, x0 + 148, x0 + 232, x0 + 260, x0 + 344, x0 + 372)):
        c.gimmick.append(f"_add_metro_spike(Vector2({sx}, 168), 1.0, 0.35, {0.5 * (i % 2) + 0.15 * (i // 2):.2f})")
    c.cat(x0 + 56, 144, 48)
    c.cat(x0 + 120, 112, 184)
    c.cat(x0 + 320, 144, 56)
    c.met(x0 + 200, 112)
    return 448


def g_vines(c, x0):
    c.notes.append(f"{x0}: drifting vines over a pit, petals overhead")
    c.ck(x0 + 40)
    c.floor(x0, 96)
    c.gimmick.append(f"_add_vine(Vector2({x0 + 136}, 156), Vector2({x0 + 196}, 156), Vector2(52, 12), 2.2, 0.0)")
    c.gimmick.append(f"_add_vine(Vector2({x0 + 260}, 140), Vector2({x0 + 320}, 140), Vector2(52, 12), 2.4, 0.5)")
    c.floor(x0 + 352, 96)
    c.gimmick.append(f"_add_petal({x0 + 150}.0, 40.0)")
    c.gimmick.append(f"_add_petal({x0 + 230}.0, 32.0)")
    c.gimmick.append(f"_add_petal({x0 + 310}.0, 36.0)")
    c.met(x0 + 412)
    return 448


def g_static(c, x0):
    c.notes.append(f"{x0}: static pockets hang at jump height — low path walks under, upper path goes over")
    c.ck(x0 + 32)
    c.floor(x0, 448)
    for px, py in ((x0 + 160, 132), (x0 + 256, 128), (x0 + 352, 132)):
        c.gimmick.append(f"_add_static_pocket(Vector2({px}, {py}), 1.6)")
    c.cat(x0 + 24, 144, 40)
    c.cat(x0 + 72, 112, 40)
    c.cat(x0 + 120, 96, 288)
    c.met(x0 + 300, FY, ", true")
    return 448


def g_kiln(c, x0):
    return s_pillars(c, x0)


SECTIONS = dict(start=s_start, trench=s_trench, pits=s_pits, shaft=s_shaft, stairs=s_stairs,
                pillars=s_pillars, preboss=s_preboss, frameskip=g_frameskip, collapse=g_collapse,
                sealgate=s_sealgate, exit=s_exit, wind=g_wind, electric=g_electric, metro=g_metro, vines=g_vines, static=g_static, kiln=g_kiln)

STAGES = {
    "Level01": dict(sid="beatfire", alt="COL_ACCENT",
                    order=["start", "trench", "pits", "shaft", "stairs", "kiln", "preboss"]),
    "LevelGlitchIce": dict(sid="glitch_ice", alt="COL_ICE",
                           order=["start", "trench", "frameskip", "shaft", "pits", "stairs", "preboss"]),
    "LevelBassquake": dict(sid="bassquake", alt="COL_METAL",
                           order=["start", "pits", "trench", "shaft", "collapse", "stairs", "preboss"]),
    "LevelEchoWind": dict(sid="echo_wind", alt="COL_TOWER",
                          order=["start", "trench", "wind", "shaft", "stairs", "pits", "preboss"]),
    "LevelNeonVolt": dict(sid="neon_volt", alt="COL_NEON",
                          order=["start", "electric", "pits", "shaft", "trench", "stairs", "preboss"]),
    "LevelMetronome": dict(sid="metronome", alt="COL_METAL",
                           order=["start", "trench", "metro", "shaft", "pillars", "stairs", "preboss"]),
    "LevelChorusBloom": dict(sid="chorus_bloom", alt="COL_VINE",
                             order=["start", "pits", "vines", "shaft", "trench", "stairs", "preboss"]),
    "LevelStaticShadow": dict(sid="static_shadow", alt="COL_METAL",
                              order=["start", "trench", "static", "shaft", "pillars", "stairs", "preboss"]),
    "LevelFortressLobby": dict(sid="fortress_lobby", alt="COL_NEON", secret=False,
                               order=["start", "trench", "shaft", "pits", "stairs", "preboss"]),
}

ARCHIVE = dict(sid="voice_archive", alt="COL_ACCENT",
               order=["start", "trench", "sealgate", "shaft", "pits", "stairs", "sealgate", "exit"])


def fmt(v):
    return f"{v}" if isinstance(v, str) else (f"{int(v)}" if float(v).is_integer() else f"{v}")


def build(name, cfg):
    c = Course(cfg["alt"])
    c.want_secret = cfg.get("secret", True)
    x = 0
    for sec in cfg["order"]:
        x += SECTIONS[sec](c, x)
    arena_left = x
    gate_x = arena_left - 16
    return c, arena_left, gate_x


def replace_func(src, fname, new_body):
    m = re.search(rf"^func {re.escape(fname)}\(.*?(?=^func |\Z)", src, re.S | re.M)
    if not m:
        raise SystemExit(f"missing func {fname}")
    return src[:m.start()] + new_body.rstrip() + "\n\n\n" + src[m.end():].lstrip("\n")


def gen(name):
    cfg = STAGES[name]
    p = LEVELS / f"{name}.gd"
    src = p.read_text()
    c, arena_left, gate_x = build(name, cfg)
    old_right = float(re.search(r"^const LEVEL_RIGHT := ([\d.]+)", src, re.M).group(1))
    old_arena = float(re.search(r"^const ARENA_LEFT := ([\d.]+)", src, re.M).group(1))
    level_right = arena_left + int(old_right - old_arena)
    alt = cfg["alt"]

    old = re.search(r"^func _build_course\(.*?(?=^func )", src, re.S | re.M).group(0)
    label_blocks = [m.group(0) for m in re.finditer(r"\tvar (\w+) := Label\.new\(\)\n(?:\t\1\.[^\n]*\n)*?\tgeometry\.add_child\(\1\)\n", old)]
    secret_call = re.search(r"\t(_build_secret_\w+\(\))", old)
    extra_calls = []
    for keep in ("_add_rect_platform(", ):
        pass
    lines = [
        "func _build_course() -> void:",
        "\t# v0.56 long course (scripts/gen_stage_courses.py). Every screen has a low path",
        "\t# and most have an upper path. Required rises <= 24px (optional catwalks 32), one wall-jump shaft with a mid foothold.",
    ]
    for n in c.notes:
        lines.append(f"\t#   x{n}")
    lines.append("\tvar solids: Array = [")
    lines.append("\t\t[-32, 0, 32, 224, COL_WALL],")
    for (x, y, w, h, col) in c.solids:
        col = alt if col == "COL_ALT" else col
        lines.append(f"\t\t[{fmt(x)}, {fmt(y)}, {fmt(w)}, {fmt(h)}, {col}],")
    lines.append("\t]")
    lines.append("\tfor s in solids:")
    lines.append("\t\t_add_rect_platform(float(s[0]), float(s[1]), float(s[2]), float(s[3]), s[4])")
    lines.append("\t# upper path catwalks — one-way, jump up through them")
    lines.append("\tvar catwalks: Array = [")
    for (x, y, w, h, col) in c.catwalks:
        lines.append(f"\t\t[{fmt(x)}, {fmt(y)}, {fmt(w)}, {fmt(h)}, {col}],")
    lines.append("\t]")
    lines.append("\tfor cw in catwalks:")
    lines.append("\t\t_add_rect_platform(float(cw[0]), float(cw[1]), float(cw[2]), float(cw[3]), cw[4], true)")
    lines.append("\tvar spikes: Array = [")
    for (sx, sy) in c.spikes:
        lines.append(f"\t\tVector2({fmt(sx)}, {fmt(sy)}),")
    lines.append("\t]")
    lines.append("\tfor sp in spikes:")
    lines.append("\t\t_add_spike(sp.x, sp.y)")
    for g in c.gimmick:
        lines.append(f"\t{g}")
    if secret_call:
        lines.append(f"\t{secret_call.group(1)}")
    body = "\n".join(lines) + "\n"
    for blk in label_blocks:
        if "→" in blk:
            blk = re.sub(r"(\w+)\.position = Vector2\([^)]*\)", lambda m: f"{m.group(1)}.position = Vector2({gate_x - 40}, 136)", blk)
        body += "\n" + blk
    src = replace_func(src, "_build_course", body)

    # enemies
    met_sig = re.search(r"^func _add_met\((.*?)\)", src, re.M).group(1)
    mlines = ["func _spawn_enemies() -> void:", "\t# 1 Met per screen-ish, always on a floor top (y = floor)."]
    for (mx, my, extra) in c.mets:
        if extra and "stealth" not in met_sig:
            extra = ""
        mlines.append(f"\t_add_met({fmt(mx)}.0, {fmt(my)}.0{extra})")
    src = replace_func(src, "_spawn_enemies", "\n".join(mlines) + "\n")

    # checkpoints
    sid = cfg["sid"]
    clines = ["func _add_mid_checkpoints() -> void:",
              f"\t## v0.56: one checkpoint per section of the long {sid} course.",
              "\tvar parent_n: Node = geometry if geometry else self"]
    for i, (cx, cy) in enumerate(c.cks):
        clines.append(f"\tCheckpointScript.place(parent_n, Vector2({fmt(cx)}.0, {fmt(cy)}.0), \"{sid}\", \"CK{i + 1}\")")
    src = replace_func(src, "_add_mid_checkpoints", "\n".join(clines) + "\n")

    # constants
    src = re.sub(r"^const LEVEL_RIGHT := [\d.]+", f"const LEVEL_RIGHT := {level_right}.0", src, flags=re.M)
    src = re.sub(r"^const ARENA_LEFT := [\d.]+", f"const ARENA_LEFT := {arena_left}.0", src, flags=re.M)
    src = re.sub(r"^const GATE_X := [\d.]+", f"const GATE_X := {gate_x}.0", src, flags=re.M)

    # secret coordinates
    if c.secret:
        (sx0, sy0, sx1, sy1), (px, py) = c.secret
        fm = re.search(r"^func _build_secret_\w+\(.*?(?=^func )", src, re.S | re.M)
        if fm:
            f = fm.group(0)
            f = re.sub(r"_seal_secret_rect\([^)]*\)", f"_seal_secret_rect({sx0}.0, {sy0}.0, {sx1}.0, {sy1}.0)", f)
            f = re.sub(r"pickup\.position = Vector2\([^)]*\)", f"pickup.position = Vector2({px}.0, {py}.0)", f)
            f = re.sub(r"## Alcoba secreta[^\n]*", "## Alcoba secreta dentro de la pared derecha del pozo de wall-jump.", f, count=1)
            src = src[:fm.start()] + f + src[fm.end():]

    # one-way catwalk support in _add_rect_platform
    if "one_way" not in re.search(r"^func _add_rect_platform\(.*?(?=^func )", src, re.S | re.M).group(0):
        src = re.sub(r"^func _add_rect_platform\(x: float, y: float, w: float, h: float, color: Color\) -> void:",
                     "func _add_rect_platform(x: float, y: float, w: float, h: float, color: Color, one_way := false) -> void:",
                     src, flags=re.M)
        fm = re.search(r"^func _add_rect_platform\(.*?(?=^func )", src, re.S | re.M)
        f = fm.group(0).replace("\tcol.shape = shape\n", "\tcol.shape = shape\n\tcol.one_way_collision = one_way\n", 1)
        src = src[:fm.start()] + f + src[fm.end():]
    p.write_text(src)
    print(f"{name}: ARENA_LEFT={arena_left} LEVEL_RIGHT={level_right} mets={len(c.mets)} cks={len(c.cks)}")


def gen_archive():
    """Voice Archive: corridor under a ceiling, two seal doors, tank sealed in the shaft wall."""
    p = LEVELS / "LevelVoiceArchive.gd"
    src = p.read_text()
    cfg = ARCHIVE
    c = Course(cfg["alt"])
    x = 0
    for sec in cfg["order"]:
        x += SECTIONS[sec](c, x)
    level_right = x + 8
    exit_x = x - 48
    old = re.search(r"^func _build_course\(.*?(?=^func )", src, re.S | re.M).group(0)
    exit_block = re.search(r"\t_exit_trigger = Area2D\.new\(\).*?_exit_trigger\.body_entered\.connect\(_on_exit\)\n", old, re.S).group(0)
    label_blocks = [m.group(0) for m in re.finditer(r"\tvar (\w+) := Label\.new\(\)\n(?:\t\1\.[^\n]*\n)*?\tgeometry\.add_child\(\1\)\n", old)]
    L = ["func _build_course() -> void:",
         "\t# v0.56 long archive (scripts/gen_stage_courses.py): low path / upper path per screen,",
         "\t# two vocal seal doors (wall above them — break the seals), wall-jump shaft with a",
         "\t# mid foothold and the energy tank sealed inside its right wall."]
    for n in c.notes:
        L.append(f"\t#   x{n}")
    L += ["\tvar solids: Array = [",
          "\t\t[-32, 0, 32, 224, COL_WALL],",
          "\t\t[LEVEL_RIGHT - 8, 0, 24, 224, COL_WALL],",
          "\t\t[0, 0, LEVEL_RIGHT, 16, COL_WALL],"]
    for (bx, by, bw, bh, col) in c.solids:
        col = cfg["alt"] if col == "COL_ALT" else col
        L.append(f"\t\t[{fmt(bx)}, {fmt(by)}, {fmt(bw)}, {fmt(bh)}, {col}],")
    L += ["\t]", "\tfor s in solids:",
          "\t\t_add_rect_platform(float(s[0]), float(s[1]), float(s[2]), float(s[3]), s[4])",
          "\tvar catwalks: Array = ["]
    for (bx, by, bw, bh, col) in c.catwalks:
        L.append(f"\t\t[{fmt(bx)}, {fmt(by)}, {fmt(bw)}, {fmt(bh)}, {col}],")
    L += ["\t]", "\tfor cw in catwalks:",
          "\t\t_add_rect_platform(float(cw[0]), float(cw[1]), float(cw[2]), float(cw[3]), cw[4], true)"]
    for (sx, sy) in c.spikes:
        L.append(f"\t_add_spike({fmt(sx)}.0, {fmt(sy)}.0)")
    for sx in c.seals:
        L.append(f"\t_add_seal({fmt(sx)}.0, 176.0)")
    (sx0, sy0, sx1, sy1), (px, py) = c.secret
    L += [f"\t# Tank alcove — blocks look like the wall.",
          f"\t_seal_secret_rect({sx0}.0, {sy0}.0, {sx1}.0, {sy1}.0)",
          "\tvar tank: Area2D = EnergyTankScene.instantiate()",
          "\ttank.name = \"ArchiveTank\"",
          f"\ttank.position = Vector2({px}.0, {py}.0)",
          "\ttank.z_index = -2  # detrás de los bloques: la alcoba no se ve",
          "\tvar _seal_lbl = tank.get_node_or_null(\"Label\")",
          "\tif _seal_lbl: _seal_lbl.visible = false",
          "\tentities.add_child(tank)", ""]
    body = "\n".join(L) + "\n"
    for blk in label_blocks:
        if "→" in blk:
            blk = re.sub(r"(\w+)\.position = Vector2\([^)]*\)", lambda m: f"{m.group(1)}.position = Vector2({exit_x - 64}, 130)", blk)
        body += blk + "\n"
    body += exit_block
    src = replace_func(src, "_build_course", body)
    if "func _seal_secret_rect" not in src:
        helpers = (
            "func _seal_secret_rect(x0: float, y0: float, x1: float, y1: float) -> void:\n"
            "\t## Rellena el hueco con bloques que se ven como la pared.\n"
            "\tvar x := x0 + 8.0\n\twhile x < x1 - 0.1:\n\t\tvar y := y0 + 8.0\n"
            "\t\twhile y < y1 - 0.1:\n\t\t\t_add_breakable(x, y, int(round((x - 8.0 - x0) / 16.0)) % 3)\n\t\t\ty += 16.0\n\t\tx += 16.0\n\n\n"
            "func _add_breakable(x: float, y: float, variant: int = 0) -> void:\n"
            "\tvar block: StaticBody2D = BreakableBlockScene.instantiate()\n\tblock.set(\"tile_variant\", variant)\n"
            "\tblock.position = Vector2(x, y)\n\tblock.set(\"block_color\", COL_WALL)\n\tblock.set(\"show_top_edge\", false)\n"
            "\tgeometry.add_child(block)\n\n\n")
        src = src.replace("func _add_seal(", helpers + "func _add_seal(", 1)
    if "func _add_spike(" not in src:
        src = src.replace("func _add_seal(", "func _add_spike(x: float, y: float) -> void:\n"
                          "\tvar spike: Area2D = SpikeScene.instantiate()\n\tspike.position = Vector2(x, y)\n"
                          "\thazards.add_child(spike)\n\n\nfunc _add_seal(", 1)
    if "BreakableBlockScene" not in src.split("func ")[0]:
        src = src.replace('const EnergyTankScene := preload("res://scenes/pickups/EnergyTankPickup.tscn")',
                          'const EnergyTankScene := preload("res://scenes/pickups/EnergyTankPickup.tscn")\n'
                          'const BreakableBlockScene := preload("res://scenes/props/BreakableBlock.tscn")')
    mlines = ["func _spawn_enemies() -> void:"] + [f"\t_add_met({fmt(mx)}.0, {fmt(my)}.0)" for (mx, my, _e) in c.mets]
    src = replace_func(src, "_spawn_enemies", "\n".join(mlines) + "\n")
    clines = ["func _add_mid_checkpoints() -> void:", "\tvar parent_n: Node = geometry if geometry else self"]
    for i, (cx, cy) in enumerate(c.cks):
        clines.append(f"\tCheckpointScript.place(parent_n, Vector2({fmt(cx)}.0, {fmt(cy)}.0), \"voice_archive\", \"CK{i + 1}\")")
    src = replace_func(src, "_add_mid_checkpoints", "\n".join(clines) + "\n")
    src = re.sub(r"^const LEVEL_RIGHT := [\d.]+", f"const LEVEL_RIGHT := {level_right}.0", src, flags=re.M)
    src = re.sub(r"^const EXIT_X := [\d.]+", f"const EXIT_X := {exit_x}.0", src, flags=re.M)
    if "one_way" not in re.search(r"^func _add_rect_platform\(.*?(?=^func )", src, re.S | re.M).group(0):
        src = re.sub(r"^func _add_rect_platform\(x: float, y: float, w: float, h: float, color: Color\) -> void:",
                     "func _add_rect_platform(x: float, y: float, w: float, h: float, color: Color, one_way := false) -> void:",
                     src, flags=re.M)
        fm = re.search(r"^func _add_rect_platform\(.*?(?=^func )", src, re.S | re.M)
        f = fm.group(0).replace("\tcol.shape = shape\n", "\tcol.shape = shape\n\tcol.one_way_collision = one_way\n", 1)
        src = src[:fm.start()] + f + src[fm.end():]
    p.write_text(src)
    print(f"LevelVoiceArchive: LEVEL_RIGHT={level_right} EXIT_X={exit_x} seals={len(c.seals)} mets={len(c.mets)} cks={len(c.cks)}")


if __name__ == "__main__":
    names = sys.argv[1:] or list(STAGES) + ["LevelVoiceArchive"]
    for n in names:
        if n == "LevelVoiceArchive":
            gen_archive()
        else:
            gen(n)
