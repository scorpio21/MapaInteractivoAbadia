# Mapa interactivo La Abadía del Crimen

Proyecto con **Godot Engine 4.7** que recrea el mapa isométrico del juego original *La Abadía del Crimen* (Paco Menéndez / UltraCaca, 1987). Renderizado tile-based con assets reales del juego original.

## Estado actual

- ✅ Assets reales del juego: `tiles_day.png` (256 tiles 16×8), sprites de personajes, scripts.abs
- ✅ Parser de `scripts.abs`: 113 scripts parseados e interpretados
- ✅ Generación dinámica de tile buffers por habitación (32,207 sprites en piso 0)
- ✅ Sistema de horas canónicas (autoload `Horario`)
- ✅ Jugador con movimiento 2D y sprite de Guillermo
- ⚠️ Rendering visual con bugs: superposición de habitaciones, áreas grises, checkerboard teal/negro
- 🔲 Monjes con IA y patrullas
- 🔲 Cambio de pisos

## Requisitos

- Godot Engine 4.7 (project.godot: `config_version=5`, renderer GLES3)

## Ejecución

1. Abre el proyecto con Godot.
2. La escena principal es `res://scenes/Main.tscn` (configurada en `project.godot`).
3. Ejecuta el proyecto (F5).

## Controles

| Acción | Tecla |
| --- | --- |
| Mover el personaje | Flechas del teclado |

## Estructura

```
assets/
  tiles_day.png              Hoja de 256 tiles isométricos (16×8 px c/u)
  tiles_night.png            Versión nocturna
  sprites/                   Hojas de sprites: abad, adso, guillermo, malaquias,
                             berengario, severino, bernardo, jorge, hooded,
                             doors, objects, light
data/
  floors.json                3 pisos, grid 16×16 de IDs de habitación
  rooms.json                 116 habitaciones con blocks y heightData[16][16]
  scripts.abs                Bytecode parseado de los scripts de dibujado de habitaciones
  tiles.json                 Definiciones de frames de los 256 tiles
  adso.json, monk.json       Definiciones de frames de sprites de personajes
  doors.json, objects.json   Definiciones de frames de puertas y objetos
scenes/
  Main.tscn                  Escena raíz (MapaPisos + Jugador + UI + Audio)
  MapaPisos.tscn             Nodo2D con script MapaPisos.gd
  Jugador.tscn               CharacterBody2D + Camera2D (zoom 4×) + sprite Guillermo
  UI.tscn                    CanvasLayer con etiquetas de zona y hora
scripts/
  ScriptInterpreter.gd       Parsea scripts.abs e interpreta bloques → genera tile buffers
  TileRenderer.gd            Convierte tile buffers en Sprite2D con AtlasTexture de tiles_day.png
  MapaPisos.gd               Carga datos, orquesta renderizado de mapas por piso
  Jugador.gd                 Movimiento 2D con sonido de pasos
  Reloj.gd                   Sistema de horas canónicas (autoload "Horario")
  UI.gd                      Muestra hora y zona actual
  AbbeyMap.gd                Datos de posiciones y conexiones de habitaciones
  PathFinder.gd              Pathfinding BFS
  AbadIA.gd                  Autómata del abad con 10 posiciones
  MonjeIA.gd                 6 tipos de monjes con rutas
```

## Arquitectura de rendering

El mapa se genera dinámicamente desde los datos originales del juego:

1. `floors.json` define un grid 16×16 de IDs de habitación por piso.
2. `rooms.json` contiene los bloques de construcción de cada habitación (tipo, posición, altura, parámetros).
3. `ScriptInterpreter` parsea `scripts.abs` (scripts de 6-9 opcodes: WHILE, LD, INC, DEC, DRAWTILE, CALL, FLIP, etc.) y ejecuta los bloques para generar un **tile buffer** de 16×20 celdas por habitación.
4. `TileRenderer` convierte los tile buffers en `Sprite2D` usando `AtlasTexture` sobre `tiles_day.png`, con depth sorting.
5. `MapaPisos` coloca cada habitación en su posición del grid (rx × 16 tiles × SCALE, ry × 20 tiles × SCALE).

## Datos originales

Todos los assets y datos provienen del reimplementación JS de [ultrabolido/abadia](https://github.com/ultrabolido/abadia) y el Java de [ibaca/la-abadia-del-crimen](https://github.com/ibaca/la-abadia-del-crimen).

## Roadmap

- [ ] Corregir posicionamiento de habitaciones (superposición y gaps)
- [ ] Corregir color de fondo (debe ser negro, no gris)
- [ ] Añadir monjes con IA y patrullas basadas en horarios
- [ ] Sistema de cambio de pisos
- [ ] Interactividad: zonas informativas, puertas, objetos
