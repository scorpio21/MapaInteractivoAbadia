# CONTEXTO DE CONTINUIDAD — MapainteractivoAbadia

Fecha de preparación: 2026-11-13

## Objetivo
Reproducir de forma lo más fiel posible en Godot el visor de pantallas de *La Abadía del Crimen Extensum*:
https://visor.abadiadelcrimenextensum.com/#room=51&floor=0&tileset=2&map=0

## Proyecto local
- Windows: `K:\Proyectos\mapainteractivo-abadia\`
- Godot 4.7.2 .NET (mono), verificado en ejecución: `v4.7.2.stable.mono.official`.
- SDK disponibles: .NET 8, 9, 10; proyecto principal configurado con .NET 8.
- Solución: `MapainteractivoAbadia.sln`; proyecto: `MapainteractivoAbadia.csproj`.
- Comando de compilación validado: `dotnet build MapainteractivoAbadia.csproj`.

## Arquitectura actual
- `scripts/main.gd`: interfaz, ventana, zoom y comunicación con minimapa y renderer.
- `scripts/mapa_abadia.gd`: minimapa y selección de habitación; versión limpia v0.3, funcionando.
- `scripts/abadia_renderer.gd`: dibuja gráficos/GRH; limpieza v0.6 en uso y verificada por el usuario.
- `scripts/abadia_diagnostics.gd`: diagnósticos extraídos de renderer en v0.6; F3 conservado.
- `scripts/abadia_data.gd`: lectura de habitaciones y alturas.
- `scripts/RoomDataBridge.cs`: puente entre GDScript y la biblioteca C#.
- `AbadiaMapData/`: biblioteca independiente de C#/.NET 8 compilada como `AbadiaMapData.dll`.
- `data/habitaciones.json`: datos de posiciones de habitación consultados por DLL.

## Datos y mapas
- Iglesia, planta 0: cuadrícula 16 × 16 píxeles.
- Scriptorium, planta 1: cuadrícula 32 × 32 píxeles.
- Biblioteca, planta 2: cuadrícula 32 × 32 píxeles.
- Se cargan **93 habitaciones con coordenadas** desde `habitaciones.json`: 61 Iglesia, 16 Scriptorium, 16 Biblioteca. Estas no equivalen a los 450 bloques físicos almacenados.
- `habitaciones.bin`: 2.376.000 bytes, 450 registros/bloques físicos.
- `alturas.bin`: 259.200 bytes, 450 bloques.
- No existen habitaciones 58 ni 59 en el mapa lógico de Iglesia; no inventarlas.
- Una tabla Java original `q.d[]` se ha investigado para mapear coordenadas mundiales a índices de bloques físicos; **no asumir** que número lógico = índice físico sin pruebas.

## Funciones verificadas
- La DLL carga 93 habitaciones y devuelve posiciones y tamaños de celda.
- Prueba: habitación 39 (124,12); 44 (172,44); 55 (156,28); 56 (172,28).
- Prueba: `GetRoomAtPosition(0,170,44)` devuelve 44.
- La selección exacta por celdas en Godot está funcionando y resuelve problema de Scriptorium: clic `(34.43478,35.21739)` devuelve habitación 69, no 67.
- El usuario confirmó que escenas y selección funcionaban después de retirar los marcadores amarillo/celeste y limpiar el minimapa.
- Se eliminaron mensajes informativos repetitivos en consola, preservando advertencias y errores.
- Se confirmó que la limpieza del renderizador **v0.6 funciona**.

## Versiones / hitos validados por el usuario
- DLL `AbadiaMapData` v0.1: compilación y escena de prueba correctas.
- Integración DLL en selección: funciona; registro confirmó la habitación 69.
- Minimapa limpio v0.3: funciona.
- Limpieza de consola v0.5: aplicada en el proceso de limpieza.
- Separación diagnósticos del renderer v0.6: **funcionando** (última versión estable confirmada).
- Próximo objetivo planteado: v0.7, seguir separando diagnóstico del renderizado sin alterar ni un píxel de los escenarios.

## Restricciones importantes
1. No reescribir el motor isométrico ni la lectura GRH/alturas mientras no exista evidencia de error.
2. No restaurar búsquedas por proximidad; la selección correcta usa la DLL/celdas.
3. No mostrar cuadros de calibración amarillo y celeste en la interfaz final.
4. Conservar zoom, ubicación de ventana, tooltip y selección de planta.
5. Conservar F3 como diagnóstico manual cuando sea útil.
6. Hacer copias de seguridad antes de cambiar `main.gd`, `mapa_abadia.gd` o `abadia_renderer.gd`.
7. Tratar el código local actual como fuente de verdad: los archivos citados en conversaciones antiguas pueden ser anteriores.
8. Mantener nombres de clases, señales, firmas y rutas reales comprobando los archivos actuales antes de editar.

## Pendientes
- Revisar versión actual en disco del renderer y su módulo de diagnósticos para posible limpieza v0.7, sin cambios visuales.
- Validar de forma completa las tres plantas contra el visor original, incluida distinción entre índices lógicos y bloques físicos.
- Mejorar arquitectura y pruebas unitarias sin romper la versión estable.

## Instrucción para el asistente de Visual Studio
Estoy continuando *MapainteractivoAbadia*, proyecto Godot 4.7.2 .NET. Lee primero este documento, luego inspecciona la solución y los archivos reales del repositorio. Quiero cambios pequeños y verificables, conservando la versión v0.6 que funciona. Antes de editar, identifica exactamente los archivos, funciones y posibles efectos secundarios. No inventes APIs ni datos y no sustituyas por aproximación la selección por DLL. Responde en español y con concisión.

## Contexto de conversación
Este Markdown resume los hechos y decisiones técnicos importantes, **no es una exportación íntegra de los mensajes de ChatGPT**. Para conservar el historial completo se debe abrir la conversación original en ChatGPT o usar la exportación de datos de la cuenta si es necesaria.
