# MEMORIA — MapainteractivoAbadia

**Referencia de continuidad: v1.1.6 validada funcionalmente (14-11-2026), pendiente de commit/tag. Base anterior estable: v1.1.5.**

Este documento permite retomar el trabajo en Godot o Visual Studio sin confundir experimentos antiguos con el visor actual.

## Objetivo

Reproducir con fidelidad el [visor web de habitaciones de La Abadía del Crimen Extensum](https://visor.abadiadelcrimenextensum.com/) en **Godot 4.7.2 .NET**, con tres minimapas, selección exacta, siete opciones gráficas, tres mapas, barra de construcciones, pintado progresivo, vista extendida y comparación entre motor original y GRH.

## Entorno y comandos de trabajo

```powershell
cd K:\Proyectos\mapainteractivo-abadia
dotnet build MapainteractivoAbadia.csproj
& 'K:\Godot_v4.6.1\Godot_v4.7.2-stable_mono_win64.exe' --path .

# Test del intérprete original (sin interfaz)
& 'K:\Godot_v4.6.1\Godot_v4.7.2-stable_mono_win64.exe' --headless --path . --script res://scripts/Test/test_abadia_screen_generator.gd
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
| **v1.1.6** | F3 operativo desde teclado, selección de celda visible en GRH, 21 pruebas nuevas, comprobación de 93 habitaciones, 18 pruebas del issue #3 y traslado de los tests a `scripts/Test/`. |

La numeración de versiones se refiere a los paquetes de trabajo de esta conversación. **No se dispone aquí del SHA del commit final v1.1.6**; no atribuir SHA nuevos sin comprobar `git log`. Los issues #1, #2 y #3 se cerraron en GitHub como `Completed`.

## Componentes del visor

- `main.gd`: UI, selector de motor, área extendida, arrastre, zoom independiente y barra.
- `mapa_abadia.gd`: minimapas y selección de habitación.
- `abadia_renderer.gd`: presentación de los buffers/tiles y marcos.
- `abadia_screen_generator.gd`: intérprete de construcciones arquitectónicas de `bloques.bin` + mapas 3D.
- `abadia_data.gd`: bloques de GRH precalculados y alturas.
- `abadia_diagnostics.gd`: funciones de diagnóstico opcionales.
- `scripts/Test/`: seis scripts de prueba (y correspondientes `.gd.uid`): `test_abadia_screen_generator.gd`, `test_issue3_v116.gd`, `test_regresion_v07.gd`, `test_regresion_v116.gd`, `test_room_renderer.gd`, `test_seleccion_93_v116.gd`.
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

## Pruebas confirmadas y cierre de issues

- `dotnet build MapainteractivoAbadia.csproj`: correcto para los proyectos .NET 8.
- `scripts/Test/test_regresion_v07.gd`: **OK**.
- `scripts/Test/test_regresion_v116.gd`: **21/21 PASS**, también después del traslado.
- `scripts/Test/test_seleccion_93_v116.gd`: **93 habitaciones revisadas; 0 fallos**, también después del traslado.
- `scripts/Test/test_abadia_screen_generator.gd`: **RESULTADO: OK** para los tres mapas, también después del traslado.
- `scripts/Test/test_issue3_v116.gd`: **18/18** antes de moverlo; comprobó la habitación 61 (16×20 y 32×32), siete atlas, tres mapas y carga de `original.ogg`. Tras moverlo, se lanzó de nuevo pero no consta su resultado completo en la transcripción; repetir antes de consolidar.
- `scripts/Test/test_room_renderer.gd`: reubicado, sin ejecución confirmada.
- **F3**: el usuario verificó activación y desactivación en consola y **marco blanco al hacer clic en una celda en GRH**. Se corrigió `scripts/abadia_renderer.gd` sin alterar el motor ORIGINAL.
- La comparación de habitación **61** con el visor web y el control de **música** se confirmaron manualmente.
- Issues [#1](https://github.com/scorpio21/MapaInteractivoAbadia/issues/1), [#2](https://github.com/scorpio21/MapaInteractivoAbadia/issues/2), [#3](https://github.com/scorpio21/MapaInteractivoAbadia/issues/3): **Closed / Completed**.

### Ejecutar la suite desde la nueva ubicación

```powershell
cd K:\Proyectos\mapainteractivo-abadia
$Godot = 'K:\Godot_v4.6.1\Godot_v4.7.2-stable_mono_win64.exe'
& $Godot --headless --path . --script res://scripts/Test/test_regresion_v116.gd
& $Godot --headless --path . --script res://scripts/Test/test_seleccion_93_v116.gd
& $Godot --headless --path . --script res://scripts/Test/test_regresion_v07.gd
& $Godot --headless --path . --script res://scripts/Test/test_abadia_screen_generator.gd
& $Godot --headless --path . --script res://scripts/Test/test_issue3_v116.gd
```

## Pendientes reales

1. Comparación **visual** de la matriz **7 tilesets × 3 mapas** y habitaciones representativas de las tres plantas; las pruebas de carga de archivos y de la habitación 61 ya se superaron.
2. Comparar visualmente vista normal, extendida, arrastre, bordes, zoom y estados 15/N, 22/N, N/N de distintas habitaciones.
3. Verificar el comportamiento al cambiar entre GRH y ORIGINAL sin alterar zoom o selección.
4. Repetir `test_issue3_v116.gd` desde `scripts/Test/` y documentar resultado de `test_room_renderer.gd`; revisar `git status` y excluir `corregir_f3_v116.ps1` y el `.bak-f3-...` de un commit.
5. Mejoras de interfaz, limpieza final y acreditación/licencias de recursos antes de una publicación.

## Historial heredado (no confundir con el estado actual)

Los documentos anteriores describían un prototipo de juego más amplio: `scripts.abs`, `ScriptInterpreter.gd`, `RoomRenderer`, `TileRenderer`, `Jugador`, `Reloj/Horario`, `MapaPisos`, `MonjeIA`, `AbadIA`, `PathFinder`, puertas y cambios de piso. Se registraron allí problemas de superposición, fondos teal y coordenadas normalizadas/overlays. **Esas descripciones pertenecen a otra rama o etapa de desarrollo** y no reflejan el visor comprobado v1.1.5. Evaluar los módulos por separado antes de integrarlos.

Commits históricos citados por aquella documentación (sin afirmar que sean los más recientes): `01f6386`, `334c987`, `15867b0`, `9634594`.

## Cómo continuar una sesión

Abrir `README.md` y `analisis.md` junto con este documento, ejecutar `dotnet build`, comprobar la habitación **77** (Scriptorium, Remake PC, Original CPC) y la **61** (Iglesia) y verificar el motor **ORIGINAL** antes de editar. Si falla algo, pedir la salida exacta de Godot y el `main.gd` / `abadia_renderer.gd` actuales, no sustituir a ciegas.
