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

Main scene: `scenes/levels/Level01.tscn`.

## Controls

### Keyboard

| Action | Keys |
|--------|------|
| Move | Arrow keys or WASD |
| Jump | **Z** or Space |
| Attack (stub flash) | **X** |
| Slide | **C** |

**Wall-jump:** press Jump while sliding down / touching a wall (always available).

### Touch HUD (`scenes/ui/TouchControls.tscn`)

CanvasLayer (layer 100) over the **256×224** viewport — screen-space anchors, not world-scaled.

| Zone | Control | InputMap action(s) |
|------|---------|-------------------|
| Left | Virtual stick (8-dir, deadzone) | `move_left` / `move_right` / `move_up` / `move_down` |
| Right | **A** (large, green) | `jump` |
| Right | **B** (red; hold for future charge) | `attack` |
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
| Top-left | Weapon label (`Arma: Buster`) + 4 empty Energy Tank icons |
| Top-right | Pause (`II` → panel **PAUSA** / **Continuar**, freezes tree) |
| Top-right | 3 empty armor slots |

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

- `Player.gd` — acceleration, jump cut, coyote, jump buffer, wall slide + wall jump, short slide with stub i-frames; `hp` / `max_hp` (28), `take_damage`, `hp_changed`
- `TouchControls` — mobile overlay + joypad InputMap wiring (CanvasLayer 100)
- `HUD` — life bar, portrait, weapon label, energy tanks, armor stubs, pause (CanvasLayer 50; Spanish strings)
- `Level01` — platforms, wall-jump corridor, spike pits, slide tunnel, goal marker
- Viewport **256×224**, integer stretch, pixel snap, physics 60 Hz
- Placeholder ColorRect / Polygon2D art (Miku cyan player; no Capcom assets)

## Project layout

```
game/
  project.godot
  icon.svg
  scripts/player/Player.gd
  scripts/levels/Level01.gd
  scripts/hazards/Hazard.gd
  scripts/ui/TouchControls.gd
  scripts/ui/HUD.gd
  scenes/player/Player.tscn
  scenes/levels/Level01.tscn
  scenes/levels/Platform.tscn
  scenes/hazards/Spike.tscn
  scenes/ui/TouchControls.tscn
  scenes/ui/HUD.tscn
```

## Validate scripts/scenes

```bash
/workspace/tools/godot --headless --path /workspace/miku-teto-megaman/game -s tools_validate.gd
```

Expect `VALIDATE_PASS`.

## Next recommended step

Attack stub → real Miku buster / Teto saber (B hold = charge), then weapon ammo on HUD.

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
