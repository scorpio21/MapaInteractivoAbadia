# MapainteractivoAbadia — Visor de La Abadía del Crimen

**Versión validada: v1.1.6 (pendiente de commit/tag de consolidación)** · **Godot 4.7.2 .NET (Mono)** · **.NET 8**

Proyecto de recreación del [visor de habitaciones de La Abadía del Crimen Extensum](https://visor.abadiadelcrimenextensum.com/) en Godot, con selección mediante minimapa, renderizado isométrico y reproducción del orden de construcción arquitectónica del visor web.

> **Alcance de esta documentación:** el **visor de habitaciones** que se ha probado durante las versiones v0.6–v1.1.6. El repositorio también ha contenido prototipos de juego completo (`Jugador`, `MapaPisos`, `MonjeIA`, `scripts.abs`, etc.). Esos módulos se consideran **experimentales o heredados**, no parte de la ruta principal verificada del visor. No deben eliminarse sin revisar sus dependencias.

## Estado comprobado

- ✅ Godot **4.7.2.stable.mono.official** con el proyecto C# compilando mediante `dotnet build`.
- ✅ `AbadiaMapData.dll` integrada con puente `RoomDataBridge.cs` y selección exacta por celdas en las tres plantas.
- ✅ **Iglesia 16×16**; **Scriptorium y Biblioteca 32×32** en el minimapa.
- ✅ Dos modos de renderizado: **ORIGINAL** (arquitectónico) y **GRH** (alternativo/de respaldo).
- ✅ Generador arquitectónico `abadia_screen_generator.gd` contrastado con el JavaScript original: interpretación de `bloques.bin` y tres mapas `.map`.
- ✅ Barra inferior **Elementos** y pintado progresivo por construcciones originales en modo ORIGINAL.
- ✅ Área extendida **32×32**, vista normal **16×20**, desplazamiento por arrastre y marco blanco de referencia cuando corresponde.
- ✅ Corrección del orden de coordenadas de tiles dentro del atlas; las pruebas visuales reportadas ya muestran la imagen original correctamente.
- ✅ Zoom separado por motor en **v1.1.5**; cambio entre GRH y ORIGINAL probado satisfactoriamente.
- ✅ Siete atlas y tres archivos de mapa comprobados mediante pruebas de carga; habitación 61 generada correctamente en vista normal y extendida para los tres mapas.
- ✅ Música original cargable; el usuario confirmó reproducción y detención desde el control.
- ✅ Diagnóstico F3 funcional en GRH: mensajes de activación/desactivación y selección de celda con marco blanco visible.
- ✅ Suite de pruebas trasladada a `scripts/Test/`; regresión v1.1.6 (21/21), selección de 93 habitaciones (0 errores), generador original (OK) y verificación issue #3 (18/18, ejecutada antes de mover los scripts).

**Alcance de validación:** el usuario confirmó la coincidencia visual de las habitaciones 77 y 61 en las configuraciones probadas. La selección exacta se comprobó para **93 habitaciones registradas en la DLL**; no implica haber comparado visualmente todas las habitaciones ni las 7×3 combinaciones de gráficos/mapas. La v1.1.5 fue la base estable; la v1.1.6 reúne el arreglo F3 y los tests.

## Requisitos y puesta en marcha

- Windows y **Godot 4.7.2 .NET** (`mono`), no el ejecutable estándar sin C#.
- SDK **.NET 8**; en el equipo de desarrollo están disponibles también .NET 9 y 10.
- Copia del proyecto en `K:\Proyectos\mapainteractivo-abadia`.

```powershell
cd K:\Proyectos\mapainteractivo-abadia
dotnet build MapainteractivoAbadia.csproj
& 'K:\Godot_v4.6.1\Godot_v4.7.2-stable_mono_win64.exe' --path .
```

El ejecutable y la ruta son los utilizados en las pruebas del usuario; ajústalos si cambian. También puedes abrir el proyecto en el editor Godot .NET y pulsar **F5**. No borres `.csproj`, `.sln` ni la referencia del proyecto a `AbadiaMapData`.

## Arquitectura del visor

| Pieza | Función |
| --- | --- |
| `scripts/main.gd` | Interfaz, selección de motor, zoom, área extendida, barra de elementos y opciones. |
| `scripts/mapa_abadia.gd` | Panel de plantas, clics y navegación entre habitaciones. |
| `scripts/abadia_renderer.gd` | Dibujo de tiles/capas en GRH y en ORIGINAL. |
| `scripts/abadia_screen_generator.gd` | Interpreta `bloques.bin` y `3d*.map` para generar construcciones del visor original. |
| `scripts/abadia_data.gd` | Lectura de los datos gráficos binarios usados por GRH. |
| `scripts/abadia_diagnostics.gd` | Comprobaciones gráficas separadas del dibujo habitual. |
| `scripts/Test/` | Seis tests GDScript de regresión, selección y generación. |
| `AbadiaMapData/` | Biblioteca C# .NET 8 con posiciones y búsqueda de habitaciones. |
| `scripts/RoomDataBridge.cs` | Puente Godot ↔ biblioteca C#. |
| `data/habitaciones.json` | Coordenadas y datos consultados por la DLL. |

Los nombres reflejan los archivos integrados durante el desarrollo. Si se reorganiza el repositorio, actualizar también esta tabla.

### Dos rutas de renderizado

**ORIGINAL:** `bloques.bin` + `3d_cpc.map` / `3d.map` / `3d_cpc_cinta.map` → instrucciones arquitectónicas → buffer de tiles → atlas gráfico. Esta es la ruta que debemos privilegiar para igualar el visor de referencia.

**GRH:** `habitaciones.bin` y datos de alturas → gráficos preprocesados, mantenidos como alternativa y comparación. No equivale al contador de elementos arquitectónicos original.

La identificación de la habitación mediante la DLL **no debe confundirse** con el índice físico de bloque usado por el renderizador GRH.

## Controles principales

- **Planta**: Iglesia / Scriptorium / Biblioteca; selección mediante minimapa o número de habitación.
- **Gráficos**: Amstrad CPC, Amstrad CPC noche, MSX, MSX2 Remake, PC CGA, Remake PC, ZX Spectrum.
- **Mapa**: Original CPC, MSX, Reducido (cinta CPC).
- **Elementos**: número de construcciones visibles; el total depende de habitación y mapa.
- **Pintado progresivo**: avance automático por construcciones en modo ORIGINAL, no por filas de imagen.
- **Área extendida**: genera 32×32 en lugar de 16×20; el arrastre permite explorarla.
- **Mostrar borde**: en área extendida, rectángulo de referencia blanco 16×20 con inicio lógico (8,8).
- **Motor**: alternar ORIGINAL / GRH para comparación.
- **Zoom**: ajuste independiente de los dos motores, con límites según el área disponible.
- **F3 (en GRH)**: alterna el diagnóstico; con F3 activo, al pulsar una celda se destaca con marco blanco y aparece información en consola. En ORIGINAL no se aplica el overlay GRH.

## Validaciones del generador original

La prueba ejecutada por el usuario fue:

```powershell
& 'K:\Godot_v4.6.1\Godot_v4.7.2-stable_mono_win64.exe' --headless --path . --script res://scripts/Test/test_abadia_screen_generator.gd
```

Resultados comunicados: **RESULTADO: OK**. Para `3d_cpc.map`, habitación 77: **28 elementos**, con sumas de comprobación para 0, 15, 22 y 28 elementos **0, 14742, 22764 y 32201**. También coincidieron los totales de las habitaciones 39, 69 y 103 para los tres mapas de prueba.

| Habitación | Original CPC | MSX | CPC cinta |
| --- | ---: | ---: | ---: |
| 39 | 24 | 22 | 0 |
| 69 | 23 | 23 | 17 |
| 77 | 28 | 28 | 25 |
| 103 | 26 | 26 | 26 |

## Pruebas reproducibles — v1.1.6

Los seis scripts de prueba están en `scripts/Test/` (con sus `.gd.uid`); no deben confundirse con los scripts de producción.

```powershell
cd K:\Proyectos\mapainteractivo-abadia
dotnet build MapainteractivoAbadia.csproj
$Godot = 'K:\Godot_v4.6.1\Godot_v4.7.2-stable_mono_win64.exe'
& $Godot --headless --path . --script res://scripts/Test/test_regresion_v07.gd
& $Godot --headless --path . --script res://scripts/Test/test_regresion_v116.gd
& $Godot --headless --path . --script res://scripts/Test/test_seleccion_93_v116.gd
& $Godot --headless --path . --script res://scripts/Test/test_abadia_screen_generator.gd
& $Godot --headless --path . --script res://scripts/Test/test_issue3_v116.gd
& $Godot --headless --path . --script res://scripts/Test/test_room_renderer.gd
```

| Test | Resultado comunicado |
| --- | --- |
| `test_regresion_v07.gd` | `REGRESION V0.7 OK` |
| `test_regresion_v116.gd` | 21/21 comprobaciones |
| `test_seleccion_93_v116.gd` | 93 habitaciones, 0 fallos |
| `test_abadia_screen_generator.gd` | `RESULTADO: OK` para tres mapas y checksums de habitación 77 |
| `test_issue3_v116.gd` | 18/18, ejecutado antes del traslado a `scripts/Test/` |
| `test_room_renderer.gd` | Incluido en la carpeta, sin resultado confirmado en esta sesión |

Los issues [#1](https://github.com/scorpio21/MapaInteractivoAbadia/issues/1), [#2](https://github.com/scorpio21/MapaInteractivoAbadia/issues/2) y [#3](https://github.com/scorpio21/MapaInteractivoAbadia/issues/3) constan cerrados como **Completed**. Tras reorganizar, se reejecutaron satisfactoriamente v0.7, v1.1.6, selección 93 y generador original; conviene repetir el test de issue #3 desde su nueva ruta antes del commit.

## Prioridades siguientes

1. Consolidar en Git la **v1.1.6** y crear etiqueta solo después de verificar el estado final de los archivos.
2. Ampliar las comparaciones visuales de los **siete atlas** y **tres mapas** en las tres plantas (ya se ha comprobado la carga de recursos y la habitación 61).
3. Revisar el aspecto de la ventana y el centrado inicial frente al visor web, sin alterar el generador comprobado.
4. Validar bordes, arrastre y escalado tras cambios de habitación/motor y al redimensionar ventana.
5. Solo después, evaluar eliminación del código GRH provisional y limpieza de módulos heredados.

## Material de referencia

- [Visor web de referencia](https://visor.abadiadelcrimenextensum.com/)
- JavaScript del visor aportado: `index-7uqyKgKQ.js` (se recibió también con extensión `.java`).
- Datos originales: `bloques.bin`, `3d_cpc.map`, `3d.map`, `3d_cpc_cinta.map`.
- Historial de decisiones y comprobaciones en [`MEMORIA.md`](MEMORIA.md); análisis técnico en [`analisis.md`](analisis.md).

**Nota sobre atribuciones y recursos:** la documentación anterior también citaba implementaciones externas (`ultrabolido/abadia` e `ibaca/la-abadia-del-crimen`) y recursos del juego. Conservar los créditos y verificar licencias y derechos antes de distribuir un paquete público con los recursos gráficos.
