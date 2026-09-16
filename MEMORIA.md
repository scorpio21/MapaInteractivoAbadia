# MEMORIA — Mapa interactivo La Abadía del Crimen

## Objetivo
Recrear el mapa isométrico de *La Abadía del Crimen* (1987) en Godot 4.7 con rendering tile-based usando assets reales del juego, personajes con IA y movimiento del jugador.

## Compilar / verificar
```powershell
# Ejecutar headless (verificar errores + sprites renderizados)
& "E:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --path "I:\MapaInteractivoAbadia" --headless --quit 2>&1 | Select-String "ERROR|SCRIPT ERROR|Floor|sprite|render"

# Ejecutar con ventana
& "E:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --path "I:\MapaInteractivoAbadia"
```

## Estado actual

### Hecho
- ✅ 3D eliminado (commit 9634594)
- ✅ Assets reales descargados de ultrabolido/abadia: tiles_day.png (256 tiles), 9 sprites de personajes, scripts.abs, tiles.json, adso.json, monk.json, doors.json, objects.json
- ✅ ScriptInterpreter parsea 113 scripts de scripts.abs correctamente
- ✅ **FIX stack corruption**: stacks separados `call_stack` (para CALL) y `while_depth` (para WHILE/ENDWHILE)
- ✅ 0 SCRIPT ERRORs, 559 sprites por habitación
- ✅ **REDESIGN: renderizado de UNA habitación a la vez** (como el juego original AbadiaBuilder.js)
- ✅ Fondo teal 0x008080 (BACKGROUND_COLOR_DAY) como el original
- ✅ SCREEN_OFFSET_X = 32 (centra la sala de 256px en viewport de 320px)
- ✅ Habitación cacheada en interpreted_rooms para rendimiento
- ✅ Transición de habitaciones al salir de los límites (0-15)
- ✅ Commit 01f6386 pushado a GitHub

### Activo
- ⚠️ **Verificar visualmente** — necesito que el usuario compruebe que la habitación se ve correctamente (tiles, colores, fondo teal)
- ⠿ **Jugador.tscn**: sprite scale=0.5 puede necesitar ajuste para verse proporcionado con tiles 4×
- ⠿ **Camera2D zoom=4×** — verificar que muestra la habitación completa

### Pendiente
- 🔲 Verificar que el jugador puede moverse entre habitaciones
- 🔲 Monjes con IA y patrullas (AbadIA.gd, MonjeIA.gd existen pero no integrados)
- 🔲 Sistema de cambio de pisos
- 🔲 Zonas interactivas, puertas, objetos

## Commits recientes
| SHA | Mensaje |
|-----|---------|
| 01f6386 | Redesign: single-room rendering like original game |
| 334c987 | Fix stack corruption in ScriptInterpreter + add real game assets |
| 15867b0 | Add MEMORIA.md session progress file |
| 9634594 | Eliminar versión 3D completa |

## Siguientes pasos

1. **Verificar visual** — El usuario abre el juego y comprueba que la habitación se ve correctamente (tiles naranjas/teal, fondo teal, personaje visible)
2. **Ajustar sprite del jugador** — Verificar proporción y posición del sprite de Guillermo con tiles a escala 4×
3. **Transiciones de habitación** — Probar moverse entre habitaciones con flechas
4. **Monjes IA** — Integrar AbadIA y MonjeIA con el mapa renderizado
5. **Cambio de pisos** — Implementar escaleras entre plantas

## Gotchas conocidos
- **El juego original renderiza UNA habitación a la vez** — NO todas a la vez. `AbadiaBuilder.buildRoom(floor, rx, ry)` limpia y re-renderiza
- Cada habitación se dibuja en posición FIJA: `(SCREEN_OFFSET_X + x*16, y*8)` — ocupa toda la pantalla
- `SCREEN_OFFSET_X = 32` centra la sala de 256px en viewport de 320px
- `BACKGROUND_COLOR_DAY = 0x008080` (teal), NO negro
- Orientación de sala depende de posición en grid: `((rx & 1) << 1) | ((rx & 1) ^ (ry & 1))` — afecta posiciones de actores, NO de tiles
- `floors.json` es Array de 3 pisos, `room[ry][rx]` da room_id
- `rooms.json` es Array de 116 habitaciones, cada una con `blocks` y `heightData[16][16]`
- `SCRIPT` naming: `script_id = "SCRIPT" + str(type >> 1)`
- Tile buffer: 16×20 grid (no 16×16), cada celda array de `{tile, depthX, depthY}`
- `_draw_tile_handler` coloca tiles en `block["x"]-8, block["y"]-8` (rango 0-15 x, 0-19 y)
- `Interpreter.get_tile_buffer()` devuelve referencia — hay que hacer `.duplicate()` para cachear
- Character sprites: 20×36 px por frame, 4 direcciones × 4 frames
