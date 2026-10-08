#!/usr/bin/env python3
"""v0.60 passability audit for Stage Crash.

1) game/tools_dump_levels.gd (headless Godot) instantiates every level and dumps the real
   collision rects, spikes, checkpoints, spawn and ArenaTrigger to JSON.
2) This script rebuilds standable segments and runs a BFS where every edge is a simulated
   jump / walk-off / wall-jump with the Player.gd numbers (worst case = Teto:
   run 79.2 px/s, jump 253.8 px/s -> ~36 px, gravity 900, wall kick 92/-220).
   Breakable secret blocks count as solid (the main path must not need them); VocalSeal
   (Voice Archive puzzle) counts as open. Wind is ignored (it only helps).
Checks: spawn + every checkpoint stand on solid ground and are reachable, the boss
ArenaTrigger is reachable, and (heuristic) report big steps/gaps between consecutive
segments on the found route.
usage: python3 scripts/audit_levels.py [dump_dir] [--miku]
"""
from __future__ import annotations

import json
import math
import os
import sys
from collections import deque

DT = 1.0 / 60.0
G = 900.0
MAX_FALL = 360.0
HW = 7.0      # half width of the 14x28 stand box
H = 28.0
WALL_SLIDE = 60.0
WJ_H, WJ_V, WJ_LOCK, WJ_DECAY, WJ_DECAY_T = 92.0, -220.0, 0.06, 420.0, 0.22
RAY = 12.0    # wall rays reach 12 px from the centre
STRICT = "--loose" not in sys.argv  # wall-jumps only inside 32-48 px shafts (designed path)

CHARS = {
    "teto": dict(S=90.0 * 0.88, V=270.0 * 0.94, A=780.0 * 0.85),
    "miku": dict(S=90.0, V=270.0, A=780.0),
    # Safety margin: Teto with ~2 px less jump and 5% less run (sloppy touch input).
    "teto_margin": dict(S=90.0 * 0.88 * 0.95, V=270.0 * 0.94 * 0.97, A=780.0 * 0.85),
}


class World:
    def __init__(self, d):
        self.d = d
        self.solid = []   # (x0,y0,x1,y1)
        self.oneway = []
        self.spikes = []
        for s in d["solids"]:
            r = (s["x"], s["y"], s["x"] + s["w"], s["y"] + s["h"])
            if s.get("kind") == "VocalSeal":
                continue
            if "pos_a" in s:
                for p in (s["pos_a"], s["pos_b"]):
                    cx, cy = p
                    self.oneway.append((cx - s["w"] / 2, cy - s["h"] / 2, cx + s["w"] / 2, cy + s["h"] / 2))
                continue
            if s.get("one_way") or s.get("kind") == "CollapsingFloor":
                self.oneway.append(r)
            else:
                self.solid.append(r)
        for a in d["areas"]:
            if a["kind"] == "Hazard" or "Spike" in a.get("name", ""):
                self.spikes.append((a["x"], a["y"], a["x"] + a["w"], a["y"] + a["h"]))
        self.trigger = None
        for a in d["areas"]:
            if a["name"] in ("ArenaTrigger", "ExitTrigger"):
                self.trigger = (a["x"], a["y"], a["x"] + a["w"], a["y"] + a["h"])
        xs = [r[0] for r in self.solid + self.oneway] + [r[2] for r in self.solid + self.oneway]
        self.xmin, self.xmax = min(xs), max(xs)
        ys = [r[3] for r in self.solid + self.oneway]
        self.death_y = max(ys) + 40.0

    @staticmethod
    def _ov(a, b):
        return a[0] < b[2] - 1e-6 and a[2] > b[0] + 1e-6 and a[1] < b[3] - 1e-6 and a[3] > b[1] + 1e-6

    def box(self, x, fy):
        return (x - HW, fy - H, x + HW, fy)

    def hits_solid(self, b):
        for r in self.solid:
            if self._ov(b, r):
                return r
        return None

    def deadly(self, b):
        for r in self.spikes:
            if self._ov((b[0] + 2, b[1] + 4, b[2] - 2, b[3] - 1), r):
                return True
        return False

    def supported(self, x, fy):
        for r in self.solid + self.oneway:
            if abs(r[1] - fy) < 0.5 and r[0] < x + HW - 1 and r[2] > x - HW + 1:
                return True
        return False

    def in_shaft(self, x, fy, side):
        """Wall-jump shaft: an opposing wall face 16-48 px away (a foothold may narrow it)."""
        cy = fy - H / 2
        if side > 0:
            wall_x = min((r[0] for r in self.solid if r[1] < cy < r[3] and r[0] >= x), default=None)
            other = max((r[2] for r in self.solid if r[1] < cy < r[3] and r[2] <= x), default=None)
        else:
            wall_x = max((r[2] for r in self.solid if r[1] < cy < r[3] and r[2] <= x), default=None)
            other = min((r[0] for r in self.solid if r[1] < cy < r[3] and r[0] >= x), default=None)
        if wall_x is None or other is None:
            return False
        return 16.0 <= abs(wall_x - other) <= 48.0

    def wall_side(self, x, fy):
        """-1 = wall on the left within the ray, +1 = right."""
        cy = fy - H / 2
        for r in self.solid:
            if r[1] < cy < r[3]:
                if r[2] <= x and x - r[2] <= RAY - 0.5:
                    return -1
                if r[0] >= x and r[0] - x <= RAY - 0.5:
                    return 1
        return 0


def segments(w: World):
    tops = sorted({round(r[1], 2) for r in w.solid + w.oneway})
    segs = []
    for y in tops:
        x = math.floor(w.xmin)
        run = None
        while x <= w.xmax:
            ok = w.supported(x, y) and w.hits_solid(w.box(x, y)) is None and not w.deadly(w.box(x, y))
            if ok:
                if run is None:
                    run = [x, x]
                else:
                    run[1] = x
            elif run is not None:
                segs.append((run[0], run[1], y))
                run = None
            x += 2
        if run is not None:
            segs.append((run[0], run[1], y))
    return segs


def find_seg(segs, x, fy, tol=3.0):
    best = None
    for i, (a, b, y) in enumerate(segs):
        if a - tol <= x <= b + tol and abs(y - fy) < 1.0:
            best = i
    return best


def simulate(w, segs, ch, x, fy, vx, vy, hold, hold_after=0, budget=240, wall_depth=0, memo=None, out=None):
    """Integrate one airborne arc. Returns set of landed segment ids (adds to out)."""
    S, A = ch["S"], ch["A"]
    lock = 0.0
    lock_dir = 0
    decay = 0.0
    if isinstance(hold, tuple):  # wall-jump continuation: (hold, lock_dir)
        hold, lock_dir = hold
        lock, decay = WJ_LOCK, WJ_DECAY_T
    wall_touch_frames = 0
    for f in range(budget):
        h = hold if f >= hold_after else 0
        side = w.wall_side(x, fy)
        # gravity / wall slide
        if side != 0 and vy > 0 and h == side:
            vy = min(vy + G * DT * 0.45, WALL_SLIDE)
        else:
            vy = min(vy + G * DT, MAX_FALL)
        # horizontal
        if decay > 0:
            decay -= DT
            if h * lock_dir <= 0.2:
                vx = _toward(vx, 0.0, WJ_DECAY * DT)
        if lock > 0:
            lock -= DT
            if h * lock_dir > 0.15:
                vx = _toward(vx, h * S, A * DT)
        elif h != 0:
            vx = _toward(vx, h * S, A * DT)
        else:
            vx = _toward(vx, 0.0, A * 0.35 * DT)
        # wall-jump branch (holding into the wall or neutral), every 6 frames of contact
        if side != 0 and wall_depth < 14 and memo is not None and (h == side or h == 0) and (not STRICT or w.in_shaft(x, fy, side)):
            if wall_touch_frames % 6 == 0:
                key = (round(x / 2), round(fy / 4), side)
                if key not in memo:
                    memo.add(key)
                    for nh in (side, -side, 0):
                        simulate(w, segs, ch, x, fy, -side * WJ_H, WJ_V, (nh, -side), 0, 150, wall_depth + 1, memo, out)
            wall_touch_frames += 1
        else:
            wall_touch_frames = 0
        # move x
        nx = x + vx * DT
        r = w.hits_solid(w.box(nx, fy))
        if r is not None:
            nx = r[0] - HW if vx > 0 else r[2] + HW
            if w.hits_solid(w.box(nx, fy)) is not None:
                nx = x
            vx = 0.0
        x = nx
        # move y
        ny = fy + vy * DT
        if vy < 0:
            r = w.hits_solid(w.box(x, ny))
            if r is not None:
                ny = r[3] + H
                vy = 0.0
            fy = ny
        else:
            landed = None
            for rr in w.solid + w.oneway:
                if fy <= rr[1] + 0.01 and ny >= rr[1] and rr[0] < x + HW - 1 and rr[2] > x - HW + 1:
                    if landed is None or rr[1] < landed:
                        landed = rr[1]
            if landed is not None:
                fy = landed
                if w.deadly(w.box(x, fy)):
                    return out
                sid = find_seg(segs, x, fy)
                if sid is not None:
                    out.add(sid)
                return out
            r = w.hits_solid(w.box(x, ny))
            if r is not None:
                fy = r[1]
                sid = find_seg(segs, x, fy)
                if sid is not None:
                    out.add(sid)
                return out
            fy = ny
        if w.deadly(w.box(x, fy)) or fy > w.death_y:
            return out
    return out


def _toward(v, t, d):
    if v < t:
        return min(v + d, t)
    return max(v - d, t)


def neighbours(w, segs, ch, i, memo):
    a, b, y = segs[i]
    out = set()
    S, V = ch["S"], ch["V"]
    xs = sorted({a, b, (a + b) / 2} | set(range(int(a), int(b) + 1, 12)))
    for x in xs:
        for d in (-1, 1):
            # running jump (full speed if there is run-up)
            for vx0 in (d * S, 0.0):
                simulate(w, segs, ch, x, y, vx0, -V, d, 0, 240, 0, memo, out)
            # jump straight up, steer later (through one-way catwalks / around ledges)
            for k in (8, 16, 24):
                simulate(w, segs, ch, x, y, 0.0, -V, d, k, 240, 0, memo, out)
        simulate(w, segs, ch, x, y, 0.0, -V, 0, 0, 240, 0, memo, out)
    # walk off both edges
    for x, d in ((a - 2, -1), (b + 2, 1)):
        if w.hits_solid(w.box(x + d * 8, y)) is None:
            simulate(w, segs, ch, x + d * 8, y, d * S, 0.0, d, 0, 240, 0, memo, out)
            simulate(w, segs, ch, x + d * 8, y, d * S, 0.0, -d, 4, 240, 0, memo, out)
    # drop through nothing: one-way platforms are not drop-through in this game
    out.discard(i)
    return out


def audit(path, chname="teto", verbose=False):
    d = json.load(open(path))
    w = World(d)
    segs = segments(w)
    ch = CHARS[chname]
    issues = []
    # spawn: first surface under the spawn point
    sx, sy = d["spawn"]
    cand = [i for i, (a, b, y) in enumerate(segs) if a - 4 <= sx <= b + 4 and y >= sy - 2]
    if not cand:
        issues.append(f"spawn ({sx:.0f},{sy:.0f}) has no ground below")
        return issues, None
    start = min(cand, key=lambda i: segs[i][2])
    if segs[start][2] - sy > 40:
        issues.append(f"spawn ({sx:.0f},{sy:.0f}) floats {segs[start][2]-sy:.0f}px above ground")
    memo = set()
    prev = {start: None}
    q = deque([start])
    adj_cache = {}
    while q:
        i = q.popleft()
        nb = neighbours(w, segs, ch, i, memo)
        adj_cache[i] = nb
        for j in nb:
            if j not in prev:
                prev[j] = i
                q.append(j)
    reach = set(prev)
    # checkpoints
    for ck in d["checkpoints"]:
        cx, cy = ck["x"], ck["y"]
        sid = find_seg(segs, cx, cy, tol=8)
        if sid is None:
            # maybe the checkpoint's y is the feet y: nearest surface below within 24px
            below = [i for i, (a, b, y) in enumerate(segs) if a - 8 <= cx <= b + 8 and 0 <= y - cy <= 24]
            sid = min(below, key=lambda i: segs[i][2]) if below else None
        if sid is None:
            issues.append(f"checkpoint {ck['name']} ({cx:.0f},{cy:.0f}) not on solid ground")
        elif sid not in reach:
            issues.append(f"checkpoint {ck['name']} ({cx:.0f},{cy:.0f}) unreachable")
    goal = None
    if w.trigger:
        t = w.trigger
        for i in reach:
            a, b, y = segs[i]
            if a - HW < t[2] and b + HW > t[0] and y - H < t[3] and y > t[1]:
                goal = i
                break
        if goal is None:
            issues.append(f"ArenaTrigger {tuple(round(v) for v in t)} unreachable")
    else:
        if verbose:
            print("  (no ArenaTrigger in this scene)")
    route = []
    if goal is not None:
        j = goal
        while j is not None:
            route.append(segs[j])
            j = prev[j]
        route.reverse()
    # unreachable standable floor that is long (possible dead zones on the intended path)
    far_x = max((segs[i][1] for i in reach), default=0)
    if verbose:
        print(f"  segments {len(segs)}, reachable {len(reach)}, furthest x {far_x:.0f}")
    return issues, dict(route=route, reach=reach, segs=segs, far_x=far_x)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dump = args[0] if args else "/tmp/sc_audit"
    chars = ["teto", "miku"] if "--miku" in sys.argv else ["teto"]
    if "--margin" in sys.argv:
        chars.append("teto_margin")
    only = args[1:] if len(args) > 1 else None
    total = 0
    for f in sorted(os.listdir(dump)):
        if not f.endswith(".json"):
            continue
        lid = f[:-5]
        if only and lid not in only:
            continue
        for chname in chars:
            issues, info = audit(os.path.join(dump, f), chname, verbose=True)
            status = "OK" if not issues else "FAIL"
            print(f"{status} {lid} [{chname}]" + ("" if info is None else f" route {len(info['route'])} segs, furthest x {info['far_x']:.0f}"))
            for s in issues:
                print("   -", s)
            total += len(issues)
            if info and info["route"]:
                rt = info["route"]
                for (a0, b0, y0), (a1, b1, y1) in zip(rt, rt[1:]):
                    rise = y0 - y1
                    gap = max(a1 - b0, a0 - b1, 0) - 2 * HW
                    if rise > 40 or gap > 64:
                        print(f"   ~ route step [{a0:.0f}..{b0:.0f}]y{y0:.0f} -> [{a1:.0f}..{b1:.0f}]y{y1:.0f} rise {rise:.0f} gap {max(gap,0):.0f} (shaft/wall-jump)")
            if info and "--route" in sys.argv:
                for a, b, y in info["route"]:
                    print(f"     [{a:.0f}..{b:.0f}] y{y:.0f}")
    print("AUDIT_ISSUES", total)
    sys.exit(1 if total else 0)


if __name__ == "__main__":
    main()
