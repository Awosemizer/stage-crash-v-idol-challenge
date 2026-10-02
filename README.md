# Stage Crash: V-Idol Challenge


**v0.40:** sprites de Miku y Teto a 32 px — idle, correr, salto, pared, desliz, disparo y sable. Alas de Stage Flight y hombreras de Encore si llevas la pieza. Sin cambiar el combate.
**v0.41:** sprites de los 8 Robot Masters (idle + ataque, 48×64) y baldosas de suelo 16×16. CORE-9 holograma. Sin cambiar el combate.
**v0.46:** Miku y Teto redibujadas a 64 px (misma altura en pantalla, escala 0.5). Idle, correr a 8 frames, salto, pared, desliz, disparo y sable, con contorno oscuro y más tonos. Alas de Stage Flight y hombreras de Encore siguen encima. Sin cambiar el combate.
**v0.45:** título con escenario y logo en pixel, cartelera detrás de los jefes, Miku y Teto más grandes al elegir. Los botones no cambian.
**v0.44:** cada etapa tiene su fondo (luces, hielo, club, cielo, neón, reloj, invernadero, glitch, fortaleza). Sin cambiar el combate.
**v0.43:** más detalle en Miku, Teto y los 8 jefes (sombras, ojos, pelo, arma). Mismos tamaños de frame. Sin cambiar el combate.
**v0.42:** Met-Beat (cerrado/abierto), disparos en pixel (buster, sable, armas y notas de jefe) y retratos 64 px en la cartelera. Sin cambiar el combate.
**v0.38:** Difícil más justo — +1 de daño con tope 10 (no media barra), i-frames 0.6 s, arma robada al 75%. Normal igual. La pausa y los PV dicen Normal o Difícil.
**v0.37:** audio — aviso del jefe en el beat, debilidad con un golpe distinto, armadura con sonido de activar, música un poco más rápida bajo 50% de vida, pausa baja el tema y lo devuelve.
**v0.36:** CORE-9 en tres fases — aviso ámbar 0.30 s, tiros que no hieren al nacer, el núcleo solo recibe Nv4 / Sonic Slash / Counter (un chip lento si no tienes golpe fuerte), transiciones con pausa y texto.
**v0.35:** jefes restantes y armadura — aviso ámbar 0.28 s antes de atacar (Glitch Ice, Echo Wind, Neon Volt, Chorus Bloom), tiros que no hieren al aparecer, hover con enfriamiento de 1.5 s, parry más legible.
**v0.34:** enemigos comunes — Met-Beat avisa antes de abrir y disparar, peligros con destello ámbar (~0.28 s), pétalos a 2 de daño, el golpe ya no te lanza al pozo.
**v0.33:** balance de armas — ciclo de debilidades ×3 (sin derretir al jefe), Freeze cuesta 2, buster Nv3/Nv4, Static Veil un golpe, E-Tank usable en pausa.
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
- Versión demo: `0.46.0-proto`

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

**[build/StageCrash-debug.apk](./build/StageCrash-debug.apk)** (v0.35 — jefes/armadura)

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