#!/usr/bin/env python3
"""Synthesize original chiptune/synth BGM + SFX for Stage Crash (no Capcom/Vocaloid samples).
Outputs OGG via ffmpeg. Loops ~12–16s for stage themes.
"""
from __future__ import annotations
import math
import struct
import subprocess
import tempfile
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1] / "game" / "audio"
SR = 22050


def midi(n: float) -> float:
    return 440.0 * (2.0 ** ((n - 69.0) / 12.0))


def env_adsr(n: int, a=0.01, d=0.08, s=0.65, r=0.12) -> np.ndarray:
    e = np.ones(n, dtype=np.float64)
    na, nd, nr = int(a * SR), int(d * SR), int(r * SR)
    na, nd, nr = max(1, na), max(1, nd), max(1, nr)
    if na < n:
        e[:na] = np.linspace(0, 1, na)
    else:
        e[:] = np.linspace(0, 1, n)
        return e
    rest = n - na
    if nd < rest:
        e[na : na + nd] = np.linspace(1, s, nd)
        sustain_end = n - nr
        if sustain_end > na + nd:
            e[na + nd : sustain_end] = s
            e[sustain_end:] = np.linspace(s, 0, n - sustain_end)
        else:
            e[na + nd :] = np.linspace(s, 0, rest - nd)
    else:
        e[na:] = np.linspace(1, 0, rest)
    return e


def sq(freq: float, t: np.ndarray, duty=0.5) -> np.ndarray:
    ph = (freq * t) % 1.0
    return np.where(ph < duty, 1.0, -1.0)


def tri(freq: float, t: np.ndarray) -> np.ndarray:
    ph = (freq * t) % 1.0
    return 2.0 * np.abs(2.0 * ph - 1.0) - 1.0


def saw(freq: float, t: np.ndarray) -> np.ndarray:
    ph = (freq * t) % 1.0
    return 2.0 * ph - 1.0


def noise(n: int) -> np.ndarray:
    return np.random.default_rng(42).uniform(-1, 1, n)


def soft_clip(x: np.ndarray, drive=1.2) -> np.ndarray:
    return np.tanh(x * drive)


def mix_tracks(*parts: np.ndarray) -> np.ndarray:
    m = max(len(p) for p in parts)
    out = np.zeros(m, dtype=np.float64)
    for p in parts:
        out[: len(p)] += p
    peak = np.max(np.abs(out)) + 1e-9
    return soft_clip(out / peak * 0.85)


def note_seq(pattern, bpm, wave="square", vol=0.35, duty=0.5, transpose=0):
    """pattern: list of (midi_or_None, beats)."""
    beat = 60.0 / bpm
    chunks = []
    for pitch, beats in pattern:
        n = max(1, int(beats * beat * SR))
        t = np.arange(n) / SR
        if pitch is None:
            chunks.append(np.zeros(n))
            continue
        f = midi(pitch + transpose)
        if wave == "square":
            w = sq(f, t, duty)
        elif wave == "tri":
            w = tri(f, t)
        elif wave == "saw":
            w = saw(f, t)
        else:
            w = np.sin(2 * math.pi * f * t)
        chunks.append(w * env_adsr(n, 0.005, 0.05, 0.55, max(0.04, beats * beat * 0.25)) * vol)
    return np.concatenate(chunks) if chunks else np.zeros(1)


def drum_hit(kind: str, dur=0.12) -> np.ndarray:
    n = int(dur * SR)
    t = np.arange(n) / SR
    if kind == "kick":
        f = np.linspace(120, 40, n)
        return np.sin(2 * np.pi * np.cumsum(f) / SR) * env_adsr(n, 0.001, 0.05, 0.2, 0.08) * 0.7
    if kind == "snare":
        return noise(n) * env_adsr(n, 0.001, 0.04, 0.15, 0.06) * 0.45
    if kind == "hat":
        return noise(n) * env_adsr(n, 0.001, 0.02, 0.05, 0.03) * 0.28
    return np.zeros(n)


def drum_pattern(steps, bpm, bars=4):
    beat = 60.0 / bpm
    step_len = beat / 2.0  # 8th notes
    total = int(bars * 4 * beat * SR)
    out = np.zeros(total)
    for bar in range(bars):
        for i, kind in enumerate(steps):
            if not kind:
                continue
            start = int((bar * 8 + i) * step_len * SR)
            hit = drum_hit(kind)
            end = min(total, start + len(hit))
            out[start:end] += hit[: end - start]
    return out


def write_ogg(samples: np.ndarray, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    clipped = np.clip(samples, -1, 1)
    pcm = (clipped * 32767.0).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wav = Path(tmp.name)
    # minimal WAV
    data = pcm.tobytes()
    with open(wav, "wb") as f:
        f.write(b"RIFF")
        f.write(struct.pack("<I", 36 + len(data)))
        f.write(b"WAVEfmt ")
        f.write(struct.pack("<IHHIIHH", 16, 1, 1, SR, SR * 2, 2, 16))
        f.write(b"data")
        f.write(struct.pack("<I", len(data)))
        f.write(data)
    subprocess.run(
        ["ffmpeg", "-y", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "4", str(path)],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    wav.unlink(missing_ok=True)
    print("wrote", path.relative_to(ROOT.parent), f"({path.stat().st_size}b)")


# ---------- BGM themes (distinct harmonic colors) ----------
THEMES = {
    "title": {
        "bpm": 112,
        "lead": [(72, 0.5), (74, 0.5), (76, 1), (79, 1), (76, 0.5), (74, 0.5), (72, 1), (69, 1)] * 4,
        "bass": [(48, 1), (48, 1), (53, 1), (55, 1), (48, 1), (50, 1), (53, 1), (55, 1)] * 4,
        "pad": [(60, 2), (64, 2), (65, 2), (67, 2)] * 4,
        "drums": ["kick", None, "hat", None, "snare", None, "hat", "hat"],
        "lead_wave": "square",
        "duty": 0.45,
    },
    "boss_select": {
        "bpm": 100,
        "lead": [(67, 0.5), (None, 0.5), (70, 0.5), (None, 0.5), (72, 1), (67, 1)] * 6,
        "bass": [(43, 2), (46, 2), (48, 2), (46, 2)] * 3,
        "pad": [(55, 4), (58, 4), (60, 4)] * 2,
        "drums": ["kick", "hat", None, "hat", "snare", "hat", None, "hat"],
        "lead_wave": "tri",
        "duty": 0.5,
    },
    "stage_beatfire": {
        "bpm": 136,
        "lead": [(64, 0.5), (67, 0.5), (71, 0.5), (72, 0.5), (71, 0.5), (67, 0.5), (64, 1)] * 6,
        "bass": [(40, 0.5), (40, 0.5), (47, 1), (40, 0.5), (40, 0.5), (43, 1)] * 6,
        "pad": [(52, 2), (55, 2), (59, 2), (55, 2)] * 3,
        "drums": ["kick", "hat", "kick", "hat", "snare", "hat", "kick", "hat"],
        "lead_wave": "saw",
        "duty": 0.4,
    },
    "stage_echo_wind": {
        "bpm": 118,
        "lead": [(76, 1), (79, 0.5), (81, 0.5), (79, 1), (76, 1), (72, 2)] * 4,
        "bass": [(45, 2), (48, 2), (50, 2), (48, 2)] * 4,
        "pad": [(57, 4), (60, 4), (64, 4), (60, 4)],
        "drums": ["kick", None, "hat", None, "snare", None, "hat", None],
        "lead_wave": "tri",
        "duty": 0.5,
    },
    "stage_neon_volt": {
        "bpm": 144,
        "lead": [(71, 0.25), (72, 0.25), (74, 0.5), (76, 0.5), (74, 0.5), (71, 0.5), (67, 1)] * 6,
        "bass": [(47, 0.5), (None, 0.5), (47, 0.5), (54, 0.5), (47, 0.5), (None, 0.5), (50, 1)] * 6,
        "pad": [(59, 2), (62, 2), (66, 2), (62, 2)] * 3,
        "drums": ["kick", "hat", "kick", "hat", "snare", "hat", "hat", "hat"],
        "lead_wave": "square",
        "duty": 0.35,
    },
    "stage_glitch_ice": {
        "bpm": 108,
        "lead": [(69, 0.5), (72, 0.5), (76, 1), (74, 0.5), (71, 0.5), (69, 1), (64, 2)] * 4,
        "bass": [(45, 2), (40, 2), (43, 2), (45, 2)] * 4,
        "pad": [(57, 4), (52, 4), (55, 4), (57, 4)],
        "drums": ["kick", None, None, "hat", "snare", None, "hat", None],
        "lead_wave": "tri",
        "duty": 0.5,
    },
    "stage_chorus_bloom": {
        "bpm": 122,
        "lead": [(72, 0.5), (74, 0.5), (76, 0.5), (79, 0.5), (81, 1), (79, 1), (76, 2)] * 4,
        "bass": [(48, 1), (52, 1), (53, 1), (55, 1)] * 8,
        "pad": [(60, 2), (64, 2), (65, 2), (67, 2)] * 4,
        "drums": ["kick", "hat", None, "hat", "snare", None, "hat", "hat"],
        "lead_wave": "square",
        "duty": 0.5,
    },
    "stage_bassquake": {
        "bpm": 96,
        "lead": [(55, 1), (58, 1), (60, 0.5), (58, 0.5), (55, 1), (52, 2)] * 4,
        "bass": [(36, 1), (36, 1), (43, 1), (41, 1), (36, 1), (36, 1), (38, 1), (43, 1)] * 4,
        "pad": [(48, 4), (51, 4), (53, 4), (51, 4)],
        "drums": ["kick", None, "kick", None, "snare", None, "kick", "hat"],
        "lead_wave": "saw",
        "duty": 0.5,
    },
    "stage_metronome": {
        "bpm": 130,
        "lead": [(67, 0.5), (67, 0.5), (71, 0.5), (71, 0.5), (74, 1), (72, 1)] * 6,
        "bass": [(43, 1), (43, 1), (47, 1), (50, 1)] * 6,
        "pad": [(55, 2), (59, 2), (62, 2), (59, 2)] * 3,
        "drums": ["kick", "hat", "kick", "hat", "snare", "hat", "kick", "hat"],
        "lead_wave": "square",
        "duty": 0.25,
    },
    "stage_static_shadow": {
        "bpm": 110,
        "lead": [(63, 1), (66, 0.5), (68, 0.5), (66, 1), (61, 1), (58, 2)] * 4,
        "bass": [(39, 2), (42, 2), (44, 2), (42, 2)] * 4,
        "pad": [(51, 4), (54, 4), (56, 4), (54, 4)],
        "drums": ["kick", None, "hat", "hat", "snare", None, None, "hat"],
        "lead_wave": "saw",
        "duty": 0.4,
    },
    "fortress": {
        "bpm": 150,
        "lead": [(60, 0.5), (63, 0.5), (67, 0.5), (70, 0.5), (72, 0.5), (70, 0.5), (67, 0.5), (63, 0.5)] * 8,
        "bass": [(36, 0.5), (36, 0.5), (43, 0.5), (36, 0.5), (39, 0.5), (36, 0.5), (43, 1)] * 8,
        "pad": [(48, 2), (51, 2), (55, 2), (58, 2)] * 4,
        "drums": ["kick", "hat", "kick", "hat", "snare", "hat", "kick", "snare"],
        "lead_wave": "square",
        "duty": 0.3,
        "intense": True,
    },
    "victory": {
        "bpm": 140,
        "lead": [(72, 0.5), (76, 0.5), (79, 0.5), (84, 1.5), (79, 0.5), (76, 0.5), (72, 1)],
        "bass": [(48, 1), (52, 1), (55, 1), (60, 2)],
        "pad": [(64, 2), (67, 2)],
        "drums": ["kick", None, "snare", None, "kick", "hat", "snare", "hat"],
        "lead_wave": "square",
        "duty": 0.5,
        "bars": 2,
    },
}


def build_theme(name: str, cfg: dict) -> np.ndarray:
    bpm = cfg["bpm"]
    bars = cfg.get("bars", 8 if name != "victory" else 2)
    # Expand patterns to cover bars
    lead = note_seq(cfg["lead"], bpm, cfg.get("lead_wave", "square"), 0.32, cfg.get("duty", 0.5))
    bass = note_seq(cfg["bass"], bpm, "square", 0.38, 0.55, transpose=0)
    pad = note_seq(cfg["pad"], bpm, "tri", 0.18, 0.5)
    drums = drum_pattern(cfg["drums"], bpm, bars=max(2, bars // 2 if name == "victory" else bars))
    # Match lengths
    target = int((60.0 / bpm) * 4 * bars * SR)
    def fit(x):
        if len(x) >= target:
            return x[:target]
        reps = int(math.ceil(target / max(1, len(x))))
        return np.tile(x, reps)[:target]

    parts = [fit(lead), fit(bass), fit(pad), fit(drums)]
    if cfg.get("intense"):
        # Extra octave lead + noise riser hits
        lead2 = note_seq(cfg["lead"], bpm, "saw", 0.18, 0.3, transpose=12)
        parts.append(fit(lead2))
        riser = np.zeros(target)
        for i in range(0, target, SR // 2):
            n = min(SR // 4, target - i)
            riser[i : i + n] += noise(n) * env_adsr(n, 0.01, 0.05, 0.3, 0.1) * 0.12
        parts.append(riser)
    return mix_tracks(*parts)


def sfx_jump() -> np.ndarray:
    n = int(0.14 * SR)
    t = np.arange(n) / SR
    f = np.linspace(220, 660, n)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env_adsr(n, 0.005, 0.04, 0.3, 0.08) * 0.55


def sfx_shoot() -> np.ndarray:
    n = int(0.09 * SR)
    t = np.arange(n) / SR
    return sq(880, t, 0.4) * env_adsr(n, 0.001, 0.03, 0.2, 0.04) * 0.4


def sfx_hit() -> np.ndarray:
    n = int(0.1 * SR)
    return (noise(n) * 0.5 + sq(180, np.arange(n) / SR) * 0.3) * env_adsr(n, 0.001, 0.03, 0.1, 0.05) * 0.55


def sfx_hurt() -> np.ndarray:
    n = int(0.18 * SR)
    t = np.arange(n) / SR
    f = np.linspace(400, 120, n)
    return (np.sin(2 * np.pi * np.cumsum(f) / SR) + noise(n) * 0.3) * env_adsr(n, 0.005, 0.06, 0.25, 0.1) * 0.5


def sfx_ui() -> np.ndarray:
    n = int(0.08 * SR)
    t = np.arange(n) / SR
    return (sq(660, t) * 0.5 + sq(990, t) * 0.3) * env_adsr(n, 0.002, 0.02, 0.2, 0.04) * 0.4


def sfx_boss_hit() -> np.ndarray:
    n = int(0.16 * SR)
    t = np.arange(n) / SR
    return (saw(140, t) * 0.4 + noise(n) * 0.5) * env_adsr(n, 0.002, 0.05, 0.2, 0.08) * 0.6


def sfx_pickup() -> np.ndarray:
    n = int(0.22 * SR)
    t = np.arange(n) / SR
    f = np.concatenate([np.linspace(520, 780, n // 2), np.linspace(780, 1040, n - n // 2)])
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env_adsr(n, 0.005, 0.05, 0.4, 0.1) * 0.45


def sfx_slide() -> np.ndarray:
    n = int(0.16 * SR)
    return noise(n) * env_adsr(n, 0.01, 0.05, 0.35, 0.08) * 0.35 + sq(90, np.arange(n) / SR, 0.6) * env_adsr(n, 0.01, 0.04, 0.2, 0.06) * 0.2


def sfx_wall_jump() -> np.ndarray:
    n = int(0.12 * SR)
    t = np.arange(n) / SR
    f = np.linspace(280, 720, n)
    return (np.sin(2 * np.pi * np.cumsum(f) / SR) + sq(560, t) * 0.2) * env_adsr(n, 0.003, 0.03, 0.25, 0.06) * 0.5


def sfx_charge_tick() -> np.ndarray:
    n = int(0.07 * SR)
    t = np.arange(n) / SR
    return sq(440, t, 0.3) * env_adsr(n, 0.002, 0.02, 0.15, 0.03) * 0.35


def sfx_charge_full() -> np.ndarray:
    n = int(0.2 * SR)
    t = np.arange(n) / SR
    return (sq(330, t) * 0.3 + sq(660, t) * 0.35 + sq(990, t) * 0.25) * env_adsr(n, 0.01, 0.05, 0.4, 0.1) * 0.5


def sfx_explosion() -> np.ndarray:
    n = int(0.35 * SR)
    t = np.arange(n) / SR
    body = noise(n) * env_adsr(n, 0.005, 0.1, 0.4, 0.2)
    boom = np.sin(2 * np.pi * np.cumsum(np.linspace(90, 35, n)) / SR) * env_adsr(n, 0.005, 0.12, 0.3, 0.15)
    return (body * 0.55 + boom * 0.45) * 0.7


def sfx_menu_move() -> np.ndarray:
    n = int(0.05 * SR)
    t = np.arange(n) / SR
    return sq(520, t, 0.4) * env_adsr(n, 0.001, 0.015, 0.1, 0.02) * 0.3


def sfx_boss_intro() -> np.ndarray:
    # Dramatic sting ~1.2s
    n = int(1.2 * SR)
    t = np.arange(n) / SR
    bass = saw(55, t) * env_adsr(n, 0.02, 0.2, 0.5, 0.4) * 0.45
    brass = sq(110, t, 0.4) * env_adsr(n, 0.05, 0.15, 0.45, 0.35) * 0.35
    hit = np.zeros(n)
    hit[: int(0.15 * SR)] = noise(int(0.15 * SR)) * env_adsr(int(0.15 * SR), 0.001, 0.04, 0.2, 0.08) * 0.6
    sparkle = np.sin(2 * np.pi * 880 * t) * env_adsr(n, 0.3, 0.2, 0.3, 0.4) * 0.15
    return soft_clip(bass + brass + hit + sparkle)


def main() -> None:
    bgm_dir = ROOT / "bgm"
    sfx_dir = ROOT / "sfx"
    bgm_dir.mkdir(parents=True, exist_ok=True)
    sfx_dir.mkdir(parents=True, exist_ok=True)
    for name, cfg in THEMES.items():
        write_ogg(build_theme(name, cfg), bgm_dir / f"{name}.ogg")
    sfx_map = {
        "jump": sfx_jump,
        "shoot": sfx_shoot,
        "hit": sfx_hit,
        "hurt": sfx_hurt,
        "ui_confirm": sfx_ui,
        "boss_hit": sfx_boss_hit,
        "pickup": sfx_pickup,
        "slide": sfx_slide,
        "wall_jump": sfx_wall_jump,
        "charge_tick": sfx_charge_tick,
        "charge_full": sfx_charge_full,
        "explosion": sfx_explosion,
        "menu_move": sfx_menu_move,
        "boss_intro": sfx_boss_intro,
    }
    for name, fn in sfx_map.items():
        write_ogg(fn(), sfx_dir / f"{name}.ogg")
    print("DONE audio →", ROOT)


if __name__ == "__main__":
    main()
