# Análisis técnico — Visor La Abadía del Crimen en Godot

**Actualizado al estado probado de v1.1.5.** Este informe revisa el análisis anterior sobre el desacuerdo entre habitaciones y describe cómo se resolvió la reproducción del visor web.

## 1. Problema original: habitación seleccionada ≠ escena esperada

En las primeras pruebas el minimapa elegía habitación mediante proximidad a puntos de un `Dictionary`. Un clic de Scriptorium cerca de `(32.87, 34.43)` se asociaba a la **67** en vez de a la **69**. El problema se debía a utilizar el punto ajustado y la búsqueda por cercanía, no necesariamente a una conversión errónea entre habitación lógica y bloque físico.

### Solución aplicada

- Se calibraron celdas **16×16** para Iglesia y **32×32** para Scriptorium/Biblioteca.
- Se creó **`AbadiaMapData.dll`** (.NET 8), con `RoomDataBridge.cs` para identificar la habitación por celda.
- El clic **real** alimenta la selección; no se busca el marcador más próximo.
- Se validó la habitación 69 y otras habitaciones de las tres plantas; los marcadores temporales amarillo y celeste se retiraron del visor final.

**Conclusión revisada:** la hipótesis antigua «el fallo se debe a `logical_room_to_data_block(room) == room`» no estaba demostrada y **no debe tratarse como diagnóstico vigente**. El visor web pasa el número lógico de habitación directamente a `generateScreen(room, ...)`, mientras que el motor GRH tiene su propio almacenamiento de bloques físicos. Son dos rutas distintas.

## 2. Problema del contador «Elementos»

El visor web muestra la habitación 77 con **28 elementos** en el mapa Original CPC. El formato GRH previo contiene muchos más registros: en el bloque 77 se contabilizaron **770 GRH no vacíos**, de **173 IDs** diferentes (1320 registros en total, 20×22×3). Por tanto, un GRH o una fila de celdas **no** es un elemento arquitectónico del visor.

La versión v0.8.1 introdujo un avance provisional agrupando GRH para toda la interfaz, pero **no era equivalente** a 15/28 y 22/28 del original.

## 3. Descubrimiento del JavaScript original

El recurso `index-7uqyKgKQ.js` del visor incluía un intérprete de arquitectura con:

- `defBloques` y `defPantallas3D` (datos de `bloques.bin` y mapas `3d*.map`).
- `getScreenOffset(room)` para avanzar hasta los datos de una habitación.
- `generateScreen(room, buffer, element_limit)` para procesar las **construcciones**, con corte exacto al alcanzar el número solicitado.
- `initBlockInterpretation`, `interpretCommands`, `doMacro`, `drawTileAndMove` y `writeTile` para producir el buffer gráfico.

La función original no cuenta GRH únicos: avanza **una construcción por entrada** del mapa 3D. El valor 28/28 procede de ese recorrido.

### Mapas reconocidos

| Opción de interfaz | Archivo |
| --- | --- |
| Original CPC | `3d_cpc.map` |
| MSX | `3d.map` |
| Reducido (cinta CPC) | `3d_cpc_cinta.map` |

### Recuento de elementos verificado

| Habitación | Original CPC | MSX | Reducido CPC |
| --- | ---: | ---: | ---: |
| 39 | 24 | 22 | 0 |
| 69 | 23 | 23 | 17 |
| 77 | 28 | 28 | 25 |
| 103 | 26 | 26 | 26 |

La prueba real del usuario de `test_abadia_screen_generator.gd` en Godot 4.7.2 .NET concluyó con **`RESULTADO: OK`**. Para habitación 77 / Original CPC, checksums de buffers: **0/28→0, 15/28→14742, 22/28→22764, 28/28→32201**. Esto valida los datos generados para esos casos, no una equivalencia visual universal de todas las habitaciones.

## 4. Port a Godot y evolución del renderizado

`abadia_screen_generator.gd` interpreta las construcciones originales y alimenta el modo **ORIGINAL** de `abadia_renderer.gd`. GRH se conserva como modo alternativo.

### Fallos y correcciones comprobados

| Hito | Diagnóstico | Corrección / estado |
| --- | --- | --- |
| Selección 67/69 | Proximidad al `Dictionary` y clic ajustado | Selección exacta por DLL y clic real. |
| Construcciones a 15/28 | Conteo por filas/GRH | Generador original por entradas del `.map`. |
| Área extendida sin efecto | Se probaba en GRH y configuración de escala distinta | Se activó ORIGINAL y se conectó 16×20 ↔ 32×32 con arrastre. |
| Tiles mezclados | Ejes de atlas intercambiados | `tile_id >> 4` para X; `tile_id & 15` para Y. |
| Marco ausente | Borde de todo el lienzo | Marco blanco 16×20 desde celda `(8,8)` en área extendida. |
| Cambio GRH/ORIGINAL pequeño | Ambos motores compartían zoom 1.0 | Zoom independiente y escala limitada al área visible (v1.1.5). |

El usuario confirmó que la v1.1.5 funciona. No se debe declarar comprobada la totalidad de las habitaciones, tilesets y mapas por esa sola prueba.

## 5. Semántica precisa de los controles

**Motor ORIGINAL** usa el generador arquitectónico, la barra de **Elementos** y el pintado progresivo por construcciones. El JavaScript avanzaba aproximadamente cada **100 ms** en ese modo.

**Motor GRH** usa habitaciones precompuestas; sus pasos provisionales deben señalarse como tales y no considerarse elementos arquitectónicos exactos.

**Área extendida:** vista normal 16×20, extendida 32×32. El rectángulo de referencia blanco aparece al tener activados área extendida y mostrar borde; desplazamiento por arrastre para explorar el área. No representa un mero cambio de zoom.

**Gráficos:** Amstrad CPC, Amstrad CPC noche, MSX, MSX2 Remake, PC CGA, Remake PC, ZX Spectrum. **Mapa:** Original CPC, MSX, Reducido (cinta CPC). Hubo una etiqueta equivocada «Original CPC» en Gráficos, corregida durante el trabajo: son selectores independientes.

## 6. Elementos aún no completamente verificados

- Correspondencia visual de las **116 habitaciones** y todas las opciones de los tres `.map`.
- Los siete atlas combinados con cada mapa, incluido el modo nocturno.
- Ajuste inicial y respuesta al cambio de tamaño de ventana, zoom, arrastre y bordes en distintas resoluciones.
- Comportamiento de UI al alternar repetidamente ORIGINAL ↔ GRH.
- Código heredado de prototipos de juego (`Jugador`, `scripts.abs`, IA de monjes) que no forma parte de la ruta verificada del visor.

## 7. Recomendaciones para próximos cambios

1. Conservar una copia/tag del estado **v1.1.5** y nunca sobrescribirlo con variantes viejas de `main.gd`.
2. Crear una matriz de pruebas reproducibles, por ejemplo habitaciones 23/39 (Iglesia), 69/77 (Scriptorium), 100/103 (Biblioteca), con cada tileset y mapa.
3. Validar capturas del visor web frente a Godot en vista normal y extendida, con 0/N, 15/N, 22/N y N/N donde corresponda.
4. Desacoplar diagnóstico y datos de rendering sin alterar el orden de construcciones verificado.
5. Limpiar módulos duplicados solo tras comprobar dependencias y mantener una ruta de reversión.

## 8. Referencias del proyecto

- JavaScript del visor aportado: `index-7uqyKgKQ.js` (subido originalmente con extensión `.java`).
- Binarios originales: `bloques.bin`, `3d_cpc.map`, `3d.map`, `3d_cpc_cinta.map`.
- Scripts principales: `main.gd`, `mapa_abadia.gd`, `abadia_renderer.gd`, `abadia_screen_generator.gd`, `test_abadia_screen_generator.gd`.
- Integración C#: `AbadiaMapData/`, `RoomDataBridge.cs`, `data/habitaciones.json`.
- Visor de comparación: https://visor.abadiadelcrimenextensum.com/

### Nota histórica

El análisis previo sostenía provisionalmente que el problema de la habitación 73 era una conversión incorrecta de habitación lógica a bloque GRH y describía marcadores y calibración normalizada que ya se han retirado. Se conserva aquí como antecedente, **no como conclusión vigente**.
