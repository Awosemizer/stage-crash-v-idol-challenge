# Miku × Teto — Juego estilo Mega Man
## Documento de diseño (borrador)

### Visión
Side-scroller 2D clásico Mega Man ambientado en Neo-Stage City. SynthoCorp y su IA CORE-9 secuestran voces y conciertos Vocaloid. El jugador elige **Hatsune Miku** o **Kasane Teto**, derrota 8 Robot Masters, recupera armas y asalta la fortaleza.

---

### Historia
- **Sinopsis:** SynthoCorp promete conciertos perfectos con androides; CORE-9 clona y captura voces Vocaloid para control social. Miku y Teto escapan y liberan las voces etapa a etapa.
- **Villano:** corporación **SynthoCorp** + IA **CORE-9**.
- **Roles:** Miku (ágil, buster) y Teto (fuerza, sable); mismos niveles; diálogos distintos. Apoyo opcional: técnico aliado tipo Dr. Light.

---

### Jugabilidad base
- Vista lateral, etapas + selector 8 jefes, checkpoints.
- **Wall-jump siempre.**
- Controles: mover, saltar, slide/dash, disparar/atacar, charge, cambio de arma, pausa.
- **Miku:** buster (tap / hold charge).
- **Teto:** sable (combo, slash aéreo, charge = corte pesado / wave).
- Feel: Miku más rápida + slide largo; Teto más lenta, golpe más pesado, i-frames al inicio del slide.
- Vida, Energy Tanks opcionales; armas con munición; buster/sable básico sin límite de “balas” (sable = stamina corta opcional a definir).
- Debilidades x3 entre jefes (ciclo abajo).

---

### Armaduras (2 sets × 3 piezas, por personaje)
Halladas en **zonas secretas** de distintos niveles. Piezas mezclables; set completo = pasivo fuerte.

#### Stage Flight
- Vuelo/hover corto + arma potenciada.
- **Miku:** charge Nv.4 = ráfaga (spread).
- **Teto:** charge = **Sonic Slash** (onda de corte a media distancia).
- Piezas: casco (radar), torso (vuelo), brazos (arma+).

#### Encore Guard
- Defensa / utilidad (sin vuelo).
- **Miku:** **Barrier Pulse** (escudo que refleja proyectiles chicos; slide deja nota-mina).
- **Teto:** **Counter Guard** (bloqueo con sable; timing = contraataque + dash-slash).
- Piezas: casco (debilidad), torso (defensa / hyper armor breve), piernas (más i-frames en slide).

#### Secretos (mapa)
| Pieza | Set | Etapa |
|-------|-----|-------|
| Torso hover | Stage Flight | Beatfire Man |
| Brazos arma+ | Stage Flight | Neon Volt |
| Casco radar | Stage Flight | Echo Wind |
| Torso defensa | Encore Guard | Bassquake |
| Piernas i-frames | Encore Guard | Metronome |
| Casco debilidad | Encore Guard | Static Shadow |

Glitch Ice y Chorus Bloom: secretos de tanks / extras. Soft-lock suave: secretos pueden pedir arma de otro jefe (replay).

---

### 8 Robot Masters
1. **Beatfire Man** — fuego + batería → *Beat Blaze*
2. **Glitch Ice** — hielo + glitch → *Freeze Sample*
3. **Bassquake** — tierra + bajo → *Quake Drop*
4. **Echo Wind** — viento + eco → *Echo Gale*
5. **Neon Volt** — electricidad + synth → *Neon Arc*
6. **Metronome** — metal + tempo → *Tempo Spike*
7. **Chorus Bloom** — planta + coro → *Petal Chorus*
8. **Static Shadow** — oscuridad + ruido → *Static Veil*

**Ciclo de debilidades:** Beatfire ← Glitch Ice ← Bassquake ← Echo Wind ← Neon Volt ← Metronome ← Chorus Bloom ← Static Shadow ← Beatfire.

**Orden sugerido (fácil→dura):** Beatfire → Echo Wind → Neon Volt → Glitch Ice → Chorus Bloom → Bassquake → Metronome → Static Shadow → Fortaleza.

---

### Selector
- Grilla 3×3; centro = CORE-9 (bloqueado hasta los 8).
- Portraits, ✓ al vencer, icono si hay secreto de armadura pendiente.
- Primera vez: elegir Miku/Teto; cambio posterior en hub.
- UI: cartelera de concierto / terminal SynthoCorp.

---

### Etapa piloto — Beatfire Man
Estadio en llamas; plataformas al beat; Met-Beats y drones de fuego; wall-jump al snare; arena con patrones en compases (más rápido <50% HP). Recompensa: Beat Blaze.

---

### Enemigos comunes
Met-Beat, Speaker Drone, Cable Snipper, Spotlight Turret, Fanblade, Disc Spinner, Backup Singer, Pitchfork Hopper. Skin + twist por etapa. 1–2 hits del arma básica; máx. ~3 del mismo tipo en pantalla.

---

### Fortaleza CORE-9 (4 etapas)
1. **Lobby Neon** — mid-boss **Refrain Unit**
2. **Voice Archive** — puzzles de armas; secreto tank/pieza
3. **Core Shaft** — vertical; mid-boss **Overdub Titan**
4. **Heart of CORE-9** — boss final

**CORE-9 — 3 fases:** (1) holograma DJ, (2) cuerpo que copia 2 ataques de jefes vencidos, (3) núcleo (charge Nv.4 / Sonic Slash / Counter). Ending distinto Miku/Teto + credits.

---

### Pendiente
HUD, mapeo teclado/gamepad, números de daño/HP, arte, motor (Godot/Unity/etc.), audio.

*Última actualización: diseño conversacional con Luis.*

---

### Controles — táctil + Bluetooth

**Prioridad:** táctil bien diseñado; **gamepad Bluetooth** siempre disponible (plug-and-play).

#### HUD táctil (layout)
- **Izquierda:** stick virtual / D-pad (8 direcciones) — zona grande, deadzone configurable.
- **Derecha:**  
  - **A** (saltar) — botón principal grande.  
  - **B** (atacar / sable o buster) — hold = charge.  
  - **Slide** — botón menor bajo B, o doble-tap abajo en el stick.  
  - **Arma anterior / siguiente** — dos botones chicos arriba a la derecha.  
- **Esquina superior:** pausa · arma actual · vida · munición.
- **Wall-jump:** no botón extra; saltar contra pared (igual que clásico).
- Opacidad 40–70% ajustable; modo “fantasma” (semi-invisible hasta tocado).
- Zona muerta central para no tapar la acción; HUD no bloquea proyectiles visualmente (solo input).

#### Gestos opcionales (on/off)
- Deslizar hacia abajo en stick = slide.
- Mantener B = charge (barra sobre el personaje).

#### Gamepad Bluetooth
- Detectar al conectar; overlay táctil se **oculta** (opción “mostrar siempre”).
- Mapeo default estilo Xbox/Switch:  
  A=saltar · B/X=atacar · LT/RT o L=slide · LB/RB=cambiar arma · Start=pausa · stick/D-pad=mover.
- Remapeo en menú Opciones.
- Vibración ligera en hit / charge max (si el pad lo soporta).

#### Accesibilidad
- Tamaño de botones S/M/L, inversión slide, un solo stick + botones grandes para una mano (opcional).

---

### HUD (interfaz en partida)

**Esquina superior izquierda**
- Retrato pequeño Miku/Teto + barra de vida (segmentos estilo Mega Man o barra limpia Vocaloid).
- Bajo vida: Energy Tanks (iconos, máx. 4).
- Nombre corto del arma activa + barra/munición (el buster/sable base no muestra munición).

**Esquina superior derecha**
- Botón pausa.
- Icono de set de armadura equipado (Flight / Guard / híbrido) + piezas activas (3 slots).
- Si hay charge: anillo o barra sobre el personaje (no solo en HUD).

**Centro / diegético**
- Flash blanco suave al recibir daño; tint del color del arma al cambiar.
- Aviso de secreto cercano solo con casco radar (Stage Flight).

**Inferior** — solo táctil: controles (ver sección Controles). Con pad: limpio, sin botones.

**Pausa**
- Rejilla de armas (buster/sable + 8).
- Slots de armadura (equipar piezas).
- Mapa de etapa simple (si casco radar).
- Opciones / salir al selector.

**Estilo visual:** terminal SynthoCorp + acentos Miku (cian) / Teto (rojo); tipografía pixel-limpia; contraste alto; safe area para notches.

---

### Números (balance borrador)

**Jugador**
- HP: 28 (estilo Mega Man 28 unidades).
- Energy Tanks: máx. 4 (restauran 28).
- Invencibilidad tras golpe: 1.0 s.
- Contacto enemigo común: 2–4 dmg · proyectil común: 2 · pinchos/lava: 4 · caídas fatales: instakill.
- Charge Miku: Nv1=1 · Nv2=2 · Nv3=4 · Nv4 (Flight)=8 en ráfaga (4×2).
- Sable Teto: tap=2 · combo finisher=3 · charge=5 · Sonic Slash=6.

**Armas de jefe (munición máx. / coste / daño base / vs débil)**
| Arma | Máx | Coste | Daño | vs débil |
|------|-----|-------|------|----------|
| Beat Blaze | 28 | 1 | 2 | 6 |
| Freeze Sample | 28 | 2 | 2 | 6 |
| Quake Drop | 14 | 2 | 3 | 9 |
| Echo Gale | 28 | 1 | 2 | 6 |
| Neon Arc | 28 | 1 | 2 | 6 |
| Tempo Spike | 14 | 2 | 3 | 9 |
| Petal Chorus | 28 | 1 | 1 (+1 heal self opcional cada 4 hits) | 3 |
| Static Veil | 14 | 3 | 3 zona | 9 |

**Jefes Robot Master:** HP 28 · contacto 4 · patrón 2–4 · fase <50% +velocidad.
**Mid-bosses fortaleza:** HP 28–36.
**CORE-9:** Fase1 HP 28 · Fase2 28 · Fase3 20 (solo charge fuerte / slash / counter cuentan ×1.5).

**Movimiento (px/frame a 60fps, ref. 16px tile)**
- Run 1.5 · jump 4.5 · grav 0.25 · wall-jump horizontal 2.5 · slide 12 frames · hover Flight 45 frames / cooldown 1.5 s.

---

### Etapas (7 restantes + recordatorio Beatfire)

**1. Beatfire Man** — Estadio en llamas; plataformas al beat; secreto: torso Stage Flight.
**2. Echo Wind** — Torres de conciertos al viento; rebotes Echo Gale; wall-jump en corrientes; secreto: casco radar Flight.
**3. Neon Volt** — Club synth subterráneo; suelos electrificados a tempo; secreto: brazos arma+ Flight.
**4. Glitch Ice** — Estudio congelado / frames rotos; plataformas que “saltan” de sitio; sin pieza de armadura (tank).
**5. Chorus Bloom** — Invernadero-escenario; enredaderas al coro; tank o 1-up (sin armadura).
**6. Bassquake** — Subwoofer industrial; sacudidas de suelo; secreto: torso Encore Guard.
**7. Metronome** — Fábrica de relojes/metrónomos; púas a intervalos fijos; secreto: piernas Encore.
**8. Static Shadow** — Backstage negro / ruido blanco; visión reducida sin casco; secreto: casco debilidad Encore.

Cada etapa: ~4–6 pantallas · 1 checkpoint · mini-desafío temático · arena jefe.

---

### Audio

**Estilo:** chiptune + leads Vocaloid-like (sin usar stems oficiales); 120–160 BPM según jefe.

**BGM**
- Selector: terminal SynthoCorp (loop corto).
- Cada Robot Master: tema propio (elemento + género: beat/fire, glitch/ice, bass, wind pads, synthwave, industrial metronome, choral, dark ambient noise).
- Fortaleza: variaciones cada vez más tensas; CORE-9 fase 3 = remix acelerado.
- Ending Miku: brillante/pop · Ending Teto: rock/agresivo.
- Game Over: stinger 2 s + jingle corto.

**SFX**
- Buster / sable / charge levels distintos.
- Slide, wall-jump, land, hit, death.
- Cambio de arma (sample “beep” por arma).
- UI: cursor, confirm, pause.
- Jefe: telegraph 1 beat antes del patrón fuerte.

**Voces (opcional, SFX cortos)**
- Miku/Teto: jump, hurt, win (sílabas originales, no covers).
- Jefes: 1 grito al entrar / al morir.

**Canales:** BGM −6 dB · SFX 0 · Voces +3; ducking BGM al pause/diálogo.
**Tec:** loops seamless; stems muteables (beat/bass/lead) para dinámicas de boss <50% HP.

---

### Arte

**Pixel / tech (referencia Mega Man X3):** misma *densidad* y escala SNES (~256×224, tiles 16×16, sprites jugador ~35–40 px de alto, jefes grandes, parallax). No copiar personajes ni UI de Capcom; el *look* de personajes es Miku/Teto + SynthoCorp.

**Estilo visual propio:** Vocaloid + robots musicales; proporciones y detalle de animación tipo X (fluido, auras de charge, armaduras por pieza visibles).
**Paletas:** Miku cian · Teto rojo/beige · SynthoCorp púrpura/neón · jefe = elemento + metal.
**Armaduras:** Flight = thrusters/alas · Guard = placas (cambio fuerte al equipar).
**VFX:** auras de charge por nivel, sparks, slash arcs, freeze frames leves.
**UI:** portraits propios 16-bit; HUD compacto; iconos de arma 16×16.


---

### Meta

**Título:** *Stage Crash: V-Idol Challenge*
**Idioma:** solo español (ES).
**Saves:** 3 slots; guarda selector, jefes, armas, armaduras, tanks, personaje; autoguardado al volver al selector.
**Dificultad:** Normal (default) · Hard (más daño enemigo, menos i-frames).
**Vidas:** ilimitadas con continua en checkpoint (estilo X); opción “lives clásicas” off por default.
**Logros:**
- Derrotar a los 8 Robot Masters
- Liberar todas las voces (100% jefes)
- Todas las piezas de armadura
- Todos los secretos / tanks
- Boss sin daño (cualquiera)
- Clear con Miku · Clear con Teto
- Derrotar a CORE-9
- Speed clear (tiempo a definir)
**Plataforma:** solo **Android** (táctil + gamepad Bluetooth).

