# MEMORIA — MapainteractivoAbadia

**Referencia de continuidad: versión funcional v1.1.5 (14-11-2026).**

Este documento permite retomar el trabajo en Godot o Visual Studio sin confundir experimentos antiguos con el visor actual.

## Objetivo

Reproducir con fidelidad el [visor web de habitaciones de La Abadía del Crimen Extensum](https://visor.abadiadelcrimenextensum.com/) en **Godot 4.7.2 .NET**, con tres minimapas, selección exacta, siete opciones gráficas, tres mapas, barra de construcciones, pintado progresivo, vista extendida y comparación entre motor original y GRH.

## Entorno y comandos de trabajo

```powershell
cd K:\Proyectos\mapainteractivo-abadia
dotnet build MapainteractivoAbadia.csproj
& 'K:\Godot_v4.6.1\Godot_v4.7.2-stable_mono_win64.exe' --path .

# Test del intérprete original (sin interfaz)
& 'K:\Godot_v4.6.1\Godot_v4.7.2-stable_mono_win64.exe' --headless --path . --script res://scripts/test_abadia_screen_generator.gd
```

El usuario confirmó compilación de `AbadiaMapData` y `MapainteractivoAbadia` con **0 errores**. Evitar sustituir archivos por versiones antiguas sin comparar previamente.

## Estado confirmado por el usuario

| Versión | Hito |
| --- | --- |
| v0.6 | Limpieza del minimapa y consola; diagnósticos del renderizador separados. |
| v0.8.1 | Barra Elementos y avance **provisional GRH** aplicados a todas las habitaciones. |
| v0.9 | `abadia_screen_generator.gd` validado con binarios y sumas de comprobación del JS original. |
| v1.0 | Integrado el motor ORIGINAL; coincidencia visual reportada para la habitación 77. |
| v1.1.1–v1.1.2 | Trabajos de inicialización, vista extendida y arrastre; ORIGINAL se activa efectivamente. |
| v1.1.3 | Corregido el cálculo de región del atlas en ORIGINAL (columna `tile_id >> 4`, fila `tile_id & 15`); el usuario confirma tiles correctos. |
| v1.1.4 | Marco blanco de referencia en área extendida, coincidente con el visor original. |
| **v1.1.5** | Zoom separado ORIGINAL/GRH; el usuario confirma que funciona correctamente. |

La numeración de versiones se refiere a los paquetes de trabajo de esta conversación. **No se dispone aquí del SHA del commit final**; no atribuir SHA nuevos sin comprobar `git log`.

## Componentes del visor

- `main.gd`: UI, selector de motor, área extendida, arrastre, zoom independiente y barra.
- `mapa_abadia.gd`: minimapas y selección de habitación.
- `abadia_renderer.gd`: presentación de los buffers/tiles y marcos.
- `abadia_screen_generator.gd`: intérprete de construcciones arquitectónicas de `bloques.bin` + mapas 3D.
- `abadia_data.gd`: bloques de GRH precalculados y alturas.
- `abadia_diagnostics.gd`: funciones de diagnóstico opcionales.
- `AbadiaMapData.dll` (.NET 8) con `RoomDataBridge.cs`: identificación de habitaciones por celdas y consulta de posiciones; datos en `data/habitaciones.json`.

### Reglas importantes

1. **El ORIGINAL es la referencia de fidelidad.** GRH es ruta alternativa; sus pasos provisionales no equivalen a los elementos del visor web.
2. La selección mediante DLL ya solucionó la confusión de habitaciones (por ejemplo 69 frente a 67 en Scriptorium). No recuperar `_select_nearest_room()`.
3. Celdas del minimapa: Iglesia **16×16**; Scriptorium/Biblioteca **32×32**. No asumir que un clic cercano identifica correctamente la habitación.
4. Vista normal **16×20**; extendida **32×32**; marco de vista normal en área extendida desde `(8,8)` y tamaño `16×20` celdas.
5. En ORIGINAL, atlas: `x=(tile_id >> 4)*tile_width`; `y=(tile_id & 15)*tile_height`. Invertirlos produce gráficos mezclados.
6. **Gráficos ≠ Mapa:** «Amstrad CPC» es opción de gráficos; «Original CPC» es opción de mapa.
7. Mantener el renderizador y la DLL como están mientras se realizan verificaciones cruzadas; hacer copia antes de cambios grandes.
8. `habitaciones.bin`: 450 bloques de 5.280 bytes; `alturas.bin`: 450 bloques de 576 bytes. Sus GRH no permiten deducir directamente el total de elementos arquitectónicos.

## Comprobación original del intérprete

Pruebas reportadas para mapa CPC: habitación 77 = **28 elementos**; checksums **0/28=0, 15/28=14742, 22/28=22764, 28/28=32201**. Otras habitaciones y mapas también pasaron la prueba con `RESULTADO: OK`.

**Mapa de selección:** en la integración de la DLL se trabajó con 93 habitaciones con posiciones conocidas en tres plantas (no significa que existan únicamente 93 IDs de habitación en los datos del visor). No inventar las habitaciones 58 y 59 de Iglesia.

## Pendientes reales

1. Matriz de pruebas para **7 tilesets × 3 mapas** y habitaciones representativas de Iglesia/Scriptorium/Biblioteca.
2. Comparar visualmente vista normal, extendida, arrastre, bordes, zoom y estados 15/N, 22/N, N/N de distintas habitaciones.
3. Verificar el comportamiento al cambiar entre GRH y ORIGINAL sin alterar zoom o selección.
4. Mejoras de interfaz, limpieza final y acreditación/licencias de recursos antes de una publicación.

## Historial heredado (no confundir con el estado actual)

Los documentos anteriores describían un prototipo de juego más amplio: `scripts.abs`, `ScriptInterpreter.gd`, `RoomRenderer`, `TileRenderer`, `Jugador`, `Reloj/Horario`, `MapaPisos`, `MonjeIA`, `AbadIA`, `PathFinder`, puertas y cambios de piso. Se registraron allí problemas de superposición, fondos teal y coordenadas normalizadas/overlays. **Esas descripciones pertenecen a otra rama o etapa de desarrollo** y no reflejan el visor comprobado v1.1.5. Evaluar los módulos por separado antes de integrarlos.

Commits históricos citados por aquella documentación (sin afirmar que sean los más recientes): `01f6386`, `334c987`, `15867b0`, `9634594`.

## Cómo continuar una sesión

Abrir `README.md` y `analisis.md` junto con este documento, ejecutar `dotnet build`, comprobar la habitación **77** (Scriptorium, Remake PC, Original CPC) y verificar el motor **ORIGINAL** antes de editar. Si falla algo, pedir la salida exacta de Godot y el `main.gd` / `abadia_renderer.gd` actuales, no sustituir a ciegas.
