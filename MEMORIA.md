# MEMORIA — Mapa interactivo La Abadía del Crimen

## Objetivo
Replicar el visor de habitaciones de La Abadía del Crimen (visor.abadiadelcrimenextensum.com) en Godot 4.7 con rendering tile-based usando assets reales del juego, panel lateral con planos de planta, y movimiento del jugador.

## Compilar / verificar
```powershell
# Ejecutar headless (verificar errores)
& "E:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --path "I:\MapaInteractivoAbadia" --headless --quit 2>&1 | Select-String "ERROR|SCRIPT ERROR"

# Ejecutar con ventana
& "E:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --path "I:\MapaInteractivoAbadia"
```

## Estado actual

### Hecho
- ✅ 3D eliminado (commit 9634594)
- ✅ Assets reales descargados: tiles_day.png, sprites, scripts.abs, tiles.json, floors.json, rooms.json
- ✅ ScriptInterpreter parsea 113 scripts correctamente, 0 errores
- ✅ RoomRenderer: rendering tile-based nativo CPC (256×160 px), heightData collision, room caching
- ✅ Jugador: movimiento con AnimatedSprite2D, 4 direcciones, transiciones de habitación
- ✅ FloorPlan: imágenes PNG reales de planos de planta (planta0/1/2.png), overlay de selección, tooltip
- ✅ Panel derecho: Planta/Gráficos/Mapa dropdowns, Habitación input, checkboxes
- ✅ BottomBar: slider de elementos, status bar
- ✅ **FIX overlay alignment**: Removido OFFSET del dibujado del overlay en FloorPlan.gd (linea 142)
- ✅ Verificación de consistencia de coordenadas canvas↔grid (funciones inverse)

### Activo
- ⠿ **Verificar visualmente** — El usuario debe comprobar que el overlay se alinea correctamente con las habitaciones en el plano de planta

### Pendiente
- 🔲 Monjes con IA y patrullas
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

1. **Verificar overlay** — El usuario abre el juego y comprueba que el rectángulo rojo se alinea con la habitación seleccionada en el plano de planta
2. **Probar click en plano** — Hacer click en diferentes habitaciones del plano y verificar que se renderizan correctamente
3. **Transiciones de jugador** — Moverse entre habitaciones con flechas y verificar que el plano se actualiza
4. **Monjes IA** — Integrar AbadIA y MonjeIA
5. **Cambio de pisos** — Implementar escaleras entre plantas

## Gotchas conocidos
- **El juego original renderiza UNA habitación a la vez** — NO todas a la vez
- Cada habitación se dibuja en posición FIJA: `(x*16, y*8)` en el SubViewport
- `BACKGROUND_COLOR_DAY = 0x008080` (teal)
- `floors.json` es Array de 3 pisos, `room[ry][rx]` da room_id (1-based)
- `rooms.json` es Array de 116 habitaciones, cada una con `blocks` y `heightData[16][16]`
- `heightData[y][x] > 0` = caminable, `== 0` = pared/bloqueado
- Tile buffer: 16×20 grid, cada celda array de `{tile, depthX, depthY}`
- Character sprites: 20×36 px por frame, 4 direcciones × 4 frames
- **FloorPlan coordenadas**: piso 0 usa celdas 16×16, pisos 1-2 usan 32×32; imagen en offset (12,12)
- **Overlay**: Se dibuja en `_grid_to_canvas(gx, gy, fl)` SIN offset (el offset es solo para la imagen)
