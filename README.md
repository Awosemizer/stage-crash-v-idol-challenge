# Stage Crash: V-Idol Challenge


**v0.32:** menús/HUD — botones más altos, panel Datos, jefes y munición más legibles, pausa sin pisar el cambio de arma.
**v0.31:** feel/balance — movimiento (pared solo si empujas), sable con recovery, cadencia de armas, pips de carga y barra de munición, jefes Beatfire/Metronome/Static Shadow/Bassquake más justos.
**v0.28:** secrets clearer + Flight helmet map blip, top boss HP bar, wall-jump/slide tutorial toasts, touch S/M/L keeps ATK/DASH gap.
**v0.27:** checkpoints, feel polish, touch size/opacity.
**v0.26:** combat/UI polish — hitstop, charge, respawn i-frames, touch ATK/DASH, Met dmg 1, E-Tank, BossSelect HARD/✓.
**v0.25:** feel polish — coyote/buffer/wall-coyote/slide-buffer, hurt flash, fairer boss contacts, midboss retune, Title/BossSelect no-clip.
**v0.24:** touch Attack/Slide no longer overlap; camera bias above controls; clearer boss telegraphs; fairer collapse warns.
**v0.19:** art+audio pro pass — 8-frame run, boss poses, parallax, hit FX, longer BGM, layered SFX.
**v0.17:** pixel-art placeholders (player Miku/Teto frames, bosses, tiles, Met-Beat, UI portraits).

**v0.16:** logros (pantalla Logros, toast) + Hard (+2 daño, i-frames 0.6s).
Demo / prototipo **Mega Man–like** con Hatsune Miku × Kasane Teto.

- Motor: **Godot 4.5**
- Plataforma: **Android** (landscape, táctil + gamepad Bluetooth)
- Idioma: **español**
- Paquete: `com.luis.stagecrash.vidol`
- Versión demo: `0.32.0-proto`

Documento de diseño completo: [DISENO.md](./DISENO.md)  
Notas de export Android: [docs/ANDROID_EXPORT.md](./docs/ANDROID_EXPORT.md)

---

## Abrir el proyecto en Godot

1. Instala [Godot 4.5](https://godotengine.org/download/).
2. Abre Godot → **Import** / **Open**.
3. Selecciona la carpeta `game/` (el archivo `game/project.godot`).
4. Ejecuta la escena principal (Title → Miku/Teto → Boss Select → Beatfire).

### Controles (PC / editor)

| Acción | Teclado | Gamepad |
|--------|---------|---------|
| Mover | Flechas / WASD | Stick / D-pad |
| Saltar | Z / Espacio | A / Cross |
| Atacar | X | X / Square |
| Slide | C / Shift | B / Circle |
| Pausa | Esc / Enter | Start |

En Android: stick virtual + botones en pantalla (se ocultan si hay mando BT).

### Flujo de menú

1. **Title** — *Continuar* / *Nueva partida* → **3 slots** (`user://save_N.json`)
2. **Selección** — **Miku** (Buster + carga, cian) o **Teto** (Sable melee, rojo)
3. **Boss Select** — grilla 3×3 SynthoCorp (8 Robot Masters + CORE-9); **autoguarda** al entrar
4. **Etapas** — 8 Robot Masters + fortaleza CORE-9

---

## Instalar el APK (Android)

Archivo listo (debug, un solo archivo, ~27 MB):

**[build/StageCrash-debug.apk](./build/StageCrash-debug.apk)** (v0.32 — menús/HUD)

1. Descarga el APK desde este repo (botón Raw / Download).
2. En el teléfono: permite **orígenes desconocidos** / instalar apps desconocidas para el navegador o gestor de archivos.
3. Abre el APK e instálalo.
4. Orientación **horizontal** (landscape).

> Build **debug** firmado con keystore de desarrollo. No es una release de Play Store.

### Re-exportar el APK (opcional)

Con Godot 4.5, plantillas Android, JDK y Android SDK configurados:

```bash
./scripts/export_android_debug.sh
```

Salida: `build/StageCrash-debug.apk`

---

## Estructura del repo

```
DISENO.md                 # GDD / diseño
README.md                 # Este archivo
docs/ANDROID_EXPORT.md    # Setup export Android
scripts/export_android_debug.sh
build/StageCrash-debug.apk
game/                     # Proyecto Godot 4.5
  project.godot
  scenes/  scripts/
```

---

## Estado actual (prototipo)

Incluye: correr, saltar, wall-jump, slide, **Buster con carga Nv1–3**, enemigos **Met-Beat**, jefe **Beatfire Man**, arma **Beat Blaze**, HUD de vida/munición, controles táctiles, nivel piloto con arena.

Pendiente: sprites finales estilo densidad X3, 8 jefes, armaduras, audio, menú de título, saves, etc.

### Combate (demo)

- **Atacar (X / B táctil):** tap = disparo Nv1 (1 dmg); mantener = carga Nv2 (~0.45 s) / Nv3 (~1.15 s) con aura en el jugador.
- **Met-Beat:** se cierra/abre a ritmo; HP 2; solo vulnerable abierto; daño de contacto 2. Hay 3 en Level01.


### v0.13 — Fortaleza CORE-9 jugable (Lobby → Archive → Shaft → Heart → Ending)