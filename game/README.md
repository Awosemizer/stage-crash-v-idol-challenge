# Stage Crash: V-Idol Challenge — Prototype

Godot **4.5** vertical slice: run / jump / wall-jump / slide on a Beatfire-style test course.

## Open the project

```bash
# Editor (needs display)
/workspace/tools/godot --path /workspace/miku-teto-megaman/game

# Or from Godot Project Manager → Import → select game/project.godot
```

Godot binary (if not on PATH): `/workspace/tools/godot` (symlink to 4.5.stable).

## Run / validate headless

```bash
/workspace/tools/godot --headless --path /workspace/miku-teto-megaman/game --quit-after 2
```

Main scene: `scenes/ui/TitleScreen.tscn` → CharacterSelect → BossSelect → Level01 / LevelEchoWind / LevelNeonVolt / LevelGlitchIce / LevelChorusBloom / LevelBassquake / LevelMetronome / LevelStaticShadow.

**v0.30:** Stability/QA — expanded smoke (Title→Select→BossSelect→all stages), save roundtrip for fortress_segment/tutorials/touch prefs, hitstop/pause time_scale guards, AudioManager missing-stream safety.

**v0.29:** Fortress + ending polish — hub stage list/progress, CORE-9 marked on Boss Select, ending skip + tap-advance, credits scroll, Core Shaft fall-death softlock fix, midboss/CORE-9 HUD HP wire + fairness, fortress checkpoints/seal bypass.

**v0.28:** secrets/boss HP/tutorials/touch gaps.

**v0.27:** Feel/UI polish — mid-stage checkpoint markers (per stage), faster death respawn, ammo-empty HUD flash, jump dust, pause touch size S/M/L + opacity.

**v0.26:** Combat/UI polish — hitstop, clearer charge, pit respawn i-frames, ATK/DASH gap 20px, Met contact 1, E-Tank toast, BossSelect ✓ + HARD banner.

**v0.25:** Feel polish — coyote/buffer/wall-coyote/slide-buffer, clearer hurt flash, fairer boss contact boxes, fortress midboss retune, Title/BossSelect no-clip, pause weapon strip touch targets.

**v0.24:** Attack/Slide touch no-overlap + camera/telegraph feel polish.

**v0.23:** Touch weapon switch — prev/next buttons (SafeArea, upper-right) + pause weapon strip; gamepad LB/RB cycle weapons, LT/RT slide.

**v0.22:** Landscape UI polish — SafeArea margins, ≥28–44px touch buttons, BossSelect 3×3 fits 16:9/20:9, readable HUD, touch pause menu.

**v0.21:** Touch-playability pass across all 8 stages + fortress (sealed pits, fair gaps, slide clearance, arena pads, camera/spawn).

**v0.20:** Android landscape real (canvas_items+expand, 398×224, SafeArea HUD/touch) + Beatfire touch-playable retune.
**v0.19:** art+audio pro pass — 8-frame run, boss poses, parallax, hit FX, longer BGM, layered SFX.
**v0.18:** armaduras GDD — Sonic Slash (Teto), Barrier Pulse (Miku), Counter Guard, hover+ set completo.

**v0.16:** logros (persistentes) + dificultad Hard (+2 daño, i-frames 0.6s), pantalla Logros.

**v0.15:** audio chiptune (BGM/SFX), AudioManager, mute en título, duck en pausa.

**v0.14:** 3 slots de guardado (Continuar/Nueva partida), `user://save_N.json`, autosave al Boss Select.

**v0.11:** etapa **Metronome** (púas a tempo, jefe, Tempo Spike, piernas Encore Guard).

**v0.12:** etapa **Static Shadow** (oscuridad, Static Veil, casco Encore, CORE-9 stub).
**v0.10:** etapa **Bassquake** (temblores, suelos colapsables, jefe, Quake Drop, torso Encore Guard).
**v0.9:** etapa **Chorus Bloom** (enredaderas, pétalos, jefe, Petal Chorus, Energy Tank).
**v0.8:** etapa **Glitch Ice** (plataformas frame-skip, jefe, Freeze Sample, Energy Tank).
**v0.7:** etapa **Neon Volt** (pisos eléctricos a tempo, jefe, Neon Arc, brazos Stage Flight).

## Controls

### Keyboard

| Action | Keys |
|--------|------|
| Move | Arrow keys or WASD |
| Jump | **Z** or Space |
| Attack / charge Buster | **X** (hold to charge) |
| Weapon prev / next | **Q** / **E** (also **1** Buster/Sable, **2** Beat Blaze, **3** Echo Gale, **4** Neon Arc, **5** Freeze Sample, **6** Petal Chorus, **7** Quake Drop, **8** Tempo Spike) |
| Slide | **C** |

**Wall-jump:** press Jump while sliding down / touching a wall (always available).

### Touch HUD (`scenes/ui/TouchControls.tscn`)

CanvasLayer (layer 100) over the viewport — SafeArea insets for notches; larger hit targets for thumbs.

| Zone | Control | InputMap action(s) |
|------|---------|-------------------|
| Left | Virtual stick (8-dir, deadzone) | `move_left` / `move_right` / `move_up` / `move_down` |
| Right | **A** (large, green) | `jump` |
| Right | **B** (red; hold = charge) | `attack` |
| Right | **SL** (smaller, purple) | `slide` |

- Semi-transparent (~55% opacity); large hit targets; ~8px safe margins.
- Mouse works as touch for desktop playtesting.
- Player reads the same actions via `Input.is_action_*` / `Input.get_axis` — no Player.gd fork needed.

**Visibility:** hidden when a joypad is connected, unless `show_touch_always` is true (defaults **true** on mobile/Android/iOS, **false** on desktop).


### In-game HUD (`scenes/ui/HUD.tscn`)

CanvasLayer **layer 50** (below touch @ 100). Spanish UI.

| Zone | Element |
|------|---------|
| Top-left | Cyan portrait stub (Miku) + HP bar (28 units, `PV x/28`) |
| Top-left | Weapon label (`Arma: Buster` o `Beat Blaze n/28`) + 4 empty Energy Tank icons |
| Top-right | Pause (`II` → panel **PAUSA** / **Continuar**, freezes tree) |
| Top-right | 3 armor slots (Stage Flight head/torso/arms) |

Spikes call `Player.take_damage(4)` → `hp_changed` → bar updates. Walk onto the spike pit (~x=288) to see HP drop.

### Gamepad (Bluetooth / USB)

Bound at runtime by TouchControls (same actions):

| Action | Default pad |
|--------|-------------|
| Move | Left stick + D-pad |
| Jump | **A** (South) |
| Attack | **B** / **X** |
| Slide | **LB** / **RB** or LT / RT |

## What’s in this slice

- `Player.gd` — movement + **Buster charge** + **weapon stub** (Buster / Beat Blaze); `hp` / `max_hp` (28)
- `BusterShot` — proyectil Area2D niveles 1–3
- `BeatBlazeShot` — proyectil naranja (daño 2, munición 28)
- `BeatfireMan` — jefe piloto HP 28 (salto / fireballs / ground pound al beat)
- `EchoWind` — 2º jefe HP 28 (flotar / ráfagas / dash); debilidad Beat Blaze ×3
- `EchoGaleShot` — proyectil verde (daño 2, delay+rebote stub, munición 28)
- `WindCurrent` — corrientes que empujan al jugador
- `MetBeat` — enemigo caparazón a ritmo (HP 2, contacto 2)
- `TouchControls` — mobile overlay + joypad InputMap wiring (CanvasLayer 100)
- `HUD` — life bar, portrait, weapon label, energy tanks, armor stubs, pause (CanvasLayer 50; Spanish strings)
- `TitleScreen` / `CharacterSelect` / **`BossSelect`** — flujo de menú (grilla 3×3, CORE-9 tras 8 jefes → stub fortaleza)
- `Level01` — platforms, wall-jump, spikes, slide tunnel, **3 Met-Beat**, arena **Beatfire Man**
- `LevelEchoWind` — torres, corrientes de viento, secreto **casco Stage Flight**, arena **Echo Wind**
- Victoria jefe → `GameState.beatfire_defeated` + botón/auto a Boss Select
- Viewport **398×224** (16:9 base), canvas_items + expand + fractional scale, pixel snap, physics 60 Hz
- Placeholder ColorRect / Polygon2D art (Miku cyan player; no Capcom assets)

## Project layout

```
game/
  project.godot
  icon.svg
  scripts/player/Player.gd
  scripts/combat/BusterShot.gd
  scripts/enemies/MetBeat.gd
  scripts/bosses/BeatfireMan.gd
  scripts/combat/BeatBlazeShot.gd
  scripts/combat/Fireball.gd
  scripts/levels/Level01.gd
  scripts/hazards/Hazard.gd
  scripts/ui/TouchControls.gd
  scripts/ui/HUD.gd
  scripts/ui/TitleScreen.gd
  scripts/ui/CharacterSelect.gd
  scripts/ui/BossSelect.gd
  scripts/autoload/GameState.gd
  scenes/player/Player.tscn
  scenes/combat/BusterShot.tscn
  scenes/enemies/MetBeat.tscn
  scenes/bosses/BeatfireMan.tscn
  scenes/combat/BeatBlazeShot.tscn
  scenes/combat/Fireball.tscn
  scenes/levels/Level01.tscn
  scenes/hazards/Spike.tscn
  scenes/ui/TouchControls.tscn
  scenes/ui/HUD.tscn
  scenes/ui/TitleScreen.tscn
  scenes/ui/CharacterSelect.tscn
  scenes/ui/BossSelect.tscn
```

## Validate scripts/scenes

```bash
/workspace/tools/godot --headless --path /workspace/miku-teto-megaman/game -s tools_validate.gd
```

Expect `VALIDATE_PASS`.

## Next recommended step

Fortaleza CORE-9 jugable, arte definitivo.

## Android debug APK

**Ready:** `../build/StageCrash-debug.apk` (~27 MB), package `com.luis.stagecrash.vidol`, landscape, arm64-v8a, signed with the Godot debug keystore.

```bash
# Re-export
bash /workspace/miku-teto-megaman/scripts/export_android_debug.sh

# Install on a connected device/emulator
adb install -r /workspace/miku-teto-megaman/build/StageCrash-debug.apk
```

Full setup / bootstrap: [`../docs/ANDROID_EXPORT.md`](../docs/ANDROID_EXPORT.md).

## Notes

- No display in CI/headless boxes: use a machine with a GPU/window to playtest feel.
- Design reference: `../DISENO.md` (Controles — táctil + Bluetooth).
