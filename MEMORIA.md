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
- ✅ **FIX stack corruption**: stacks separados `call_stack` (para CALL) y `while_depth` (para WHILE/ENDWHILE), evitando mezcla de tipos int/String en el stack
- ✅ 0 SCRIPT ERRORs (antes decenas)
- ✅ 32,207 sprites generados en piso 0 (antes 11,504)
- ✅ TileRenderer genera AtlasTextures desde tiles_day.png
- ✅ Jugador con sprite Guillermo, Camera2D zoom 4×
- ✅ UI con hora canónica (autoload Horario)
- ✅ Commit 334c987 pushado a GitHub

### Activo / Con bugs visuales
- ⚠️ **Posicionamiento de habitaciones**: se superponen y dejan gaps grises
- ⚠️ **Patrón checkerboard teal/negro**: algunas habitaciones muestran tiles repetidos en cuadrícula
- ⚠️ **Fondo gris** en lugar de negro

### Pendiente
- 🔲 Monjes con IA y patrullas (AbadIA.gd, MonjeIA.gd existen pero no integrados)
- 🔲 Sistema de cambio de pisos
- 🔲 Zonas interactivas, puertas, objetos

## Commits recientes
| SHA | Mensaje |
|-----|---------|
| 334c987 | Fix stack corruption in ScriptInterpreter + add real game assets |
| 9634594 | Eliminar versión 3D completa |

## Siguientes pasos (mañana)

1. **Investigar referencia JS** — Leer la función `renderRoom` de ultrabolido/abadia para entender cómo posiciona tiles en pantalla (coords exactas de cada room en el grid 16×16)
2. **Corregir posicionamiento** — Ajustar `MapaPisos._render_room()` para que cada habitación se coloque correctamente en su slot del grid sin superposición
3. **Fondo negro** — Cambiar color de fondo del viewport a negro
4. **Verificar visualmente** — Ejecutar y comparar con capturas del juego original
5. **Monjes IA** — Integrar AbadIA y MonjeIA con el mapa renderizado

## Gotchas conocidos
- `floors.json` es Array (no Dictionary) de 3 pisos, cada uno con `room[16][16]`
- `rooms.json` es Array de 116 habitaciones, cada una con `blocks` y `heightData[16][16]`
- JSON en Godot 4 retorna floats — hay que castear con `int()` antes de bit operations
- `SCRIPT` naming: `script_id = "SCRIPT" + str(type >> 1)`
- Tile buffer: 16×20 grid, cada celda es array de `{tile, depthX, depthY}`
- `_draw_tile_handler` coloca tiles en `block["x"]-8, block["y"]-8` (rango 0-15 x, 0-19 y)
- `SCREEN_OFFSET_X = 32` en el juego original (viewport 320×192, escalado 4×)
- Character sprites: 20×36 px por frame, 4 direcciones × 4 frames
- ScriptInterpreter tiene 3 stacks: `stack` (PUSH/POP de usuario + WHILE/ENDWHILE), `call_stack` (CALL retorno), `while_depth` (tracking de depth para ENDWHILE seguro)
