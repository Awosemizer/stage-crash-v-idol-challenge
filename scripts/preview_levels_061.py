"""v0.61: geometry map (+ StageKit hazards/enemies parsed from the level scripts) of the 8 Robot Master stages from tools_dump_levels.gd JSON (solids, spikes, checkpoints, goal).
Usage: godot --headless --path game -s tools_dump_levels.gd -- /tmp/sc_audit && python3 scripts/preview_levels_061.py /tmp/sc_audit"""
import json, sys, os
from PIL import Image, ImageDraw
src = sys.argv[1] if len(sys.argv) > 1 else "/tmp/sc_audit"
ids = ["beatfire", "glitch_ice", "bassquake", "echo_wind", "neon_volt", "metronome", "chorus_bloom", "static_shadow"]
S = 0.5; ROW = 130; W = 1840
img = Image.new("RGB", (W, ROW * len(ids) + 8), (14, 14, 22))
d = ImageDraw.Draw(img)
for i, lid in enumerate(ids):
    L = json.load(open(os.path.join(src, lid + ".json")))
    oy = 8 + i * ROW
    def R(x, y, w, h, col, outline=None):
        d.rectangle([int(x * S), int(oy + y * S), int((x + w) * S) - 1, int(oy + (y + h) * S) - 1], fill=col, outline=outline)
    for s in L["solids"]:
        col = (90, 200, 120) if s.get("one_way") else (120, 120, 150)
        if s.get("breakable"): col = (120, 120, 150)
        if "pos_a" in s: col = (90, 160, 230)
        R(s["x"], s["y"], s["w"], s["h"], col)
    for a in L["areas"]:
        k = a["kind"]
        col = {"Hazard": (230, 70, 70), "ElectricFloor": (240, 240, 80), "MetronomeSpike": (240, 120, 60), "PetalHazard": (240, 140, 200), "StaticZone": (150, 110, 220), "WindCurrent": (60, 90, 120), "ArenaTrigger": (240, 200, 60), "ExitTrigger": (240, 200, 60)}.get(k)
        if col: R(a["x"], a["y"], a["w"], a["h"], col)
    for c in L.get("checkpoints", []):
        R(c["x"] - 3, c["y"] - 12, 6, 12, (80, 230, 230))
    sp = L.get("spawn")
    if sp: R(sp[0] - 4, sp[1] - 14, 8, 14, (255, 255, 255))
    import re
    gd = {"beatfire": "Level01"}.get(lid, "Level" + "".join(p.title() for p in lid.split("_")))
    src_gd = open(f"game/scripts/levels/{gd}.gd").read()
    for m in re.finditer(r"kit\.(\w+)\((?:hazards|entities), ([\d.]+), ([\d.]+)", src_gd):
        k, x, y = m.group(1), float(m.group(2)), float(m.group(3))
        if k == "fire_jet": R(x - 5, y - 36, 10, 36, (255, 120, 30))
        elif k == "drop": R(x - 4, y, 8, 50, (150, 220, 255))
        elif k == "quake": R(x - 8, y - 20, 16, 20, (200, 120, 40))
        elif k == "drone": d.ellipse([int((x - 6) * S), int(oy + (y - 6) * S), int((x + 6) * S), int(oy + (y + 6) * S)], fill=(255, 80, 200))
        elif k == "turret": R(x - 6, y - 14, 12, 14, (255, 80, 200))
    d.text((4, oy), lid.upper(), fill=(230, 230, 240))
img.save("docs/preview_levels_061.png")
print("wrote docs/preview_levels_061.png", img.size)
