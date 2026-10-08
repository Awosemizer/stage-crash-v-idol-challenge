"""v0.60: geometry map of the 8 Robot Master stages from tools_dump_levels.gd JSON (solids, spikes, checkpoints, goal).
Usage: godot --headless --path game -s tools_dump_levels.gd -- /tmp/sc_audit && python3 scripts/preview_levels_060.py /tmp/sc_audit"""
import json, sys, os
from PIL import Image, ImageDraw
src = sys.argv[1] if len(sys.argv) > 1 else "/tmp/sc_audit"
ids = ["beatfire", "glitch_ice", "bassquake", "echo_wind", "neon_volt", "metronome", "chorus_bloom", "static_shadow"]
S = 0.5; ROW = 130; W = 1680
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
        col = {"Hazard": (230, 70, 70), "WindCurrent": (60, 90, 120), "ArenaTrigger": (240, 200, 60), "ExitTrigger": (240, 200, 60)}.get(k)
        if col: R(a["x"], a["y"], a["w"], a["h"], col)
    for c in L.get("checkpoints", []):
        R(c["x"] - 3, c["y"] - 12, 6, 12, (80, 230, 230))
    sp = L.get("spawn")
    if sp: R(sp[0] - 4, sp[1] - 14, 8, 14, (255, 255, 255))
    d.text((4, oy), lid.upper(), fill=(230, 230, 240))
img.save("docs/preview_levels_060.png")
print("wrote docs/preview_levels_060.png", img.size)
