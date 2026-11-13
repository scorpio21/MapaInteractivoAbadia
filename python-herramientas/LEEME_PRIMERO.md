# Abadía v0.9 — Investigación de elementos (sin alterar v0.8.1)

## Resultado comprobado

El contador «Elementos» del visor original corresponde a **colocaciones arquitectónicas**, no al número de registros GRH ni a la cantidad de tipos GRH diferentes. Su opción de pintado progresivo recorre esas colocaciones en el orden de construcción. Consulta la ayuda del visor: https://visor.abadiadelcrimenextensum.com/

La v0.8.1 de Godot sigue siendo una **simulación provisional**. En los datos binarios suministrados, para el bloque físico 77 se han contado **770 registros GRH no cero** y **173 GRH diferentes**, mientras que el ejemplo observado del visor mostraba **28 elementos**. Por tanto, no debemos transformar 173 en 28 con una regla arbitraria.

## Qué incluye este paquete

- `analizar_elementos.py`: inspección exacta y reproducible de `habitaciones.bin`, sin tocar el proyecto Godot.
- `resultados/resumen.csv`: estadísticas verificadas de cuatro bloques físicos de ejemplo.
- `resultados/bloque_NNN_grh.csv`: operaciones en orden de lectura `y → x → capa`, con coordenadas y GRH.
- `resultados/bloque_NNN_frecuencias.csv`: frecuencias de tipos GRH.

**Aviso:** el orden de lectura del binario tampoco demuestra el orden original de las colocaciones de arquitectura. La equivalencia bloque físico ↔ habitación lógica debe validarse en `mapa_abadia.gd`.

## Ejecución en Windows

Si tienes Python instalado:

```powershell
cd K:\Proyectos\mapainteractivo-abadia
python herramientas\analizar_elementos.py assets\bin\habitaciones.bin --salida diagnostico_elementos --bloques 39 69 77 103
```

Ajusta la ruta del binario si tu archivo está en otra carpeta. El programa no escribe dentro de `scripts` ni altera el renderizador.

## Qué falta para reproducir 15/28 y 22/28 exactamente

Necesitamos obtener la **secuencia de elementos arquitectónicos y sus parámetros para cada habitación** del visor original o del motor original que los construye. `habitaciones.bin` contiene un resultado desplegado en GRH y no conserva, por sí solo, los límites de cada colocación. Cuando dispongamos de esa secuencia, la barra controlará las colocaciones 0..N y `_render_room` tendrá que consumir sus operaciones, no tipos GRH.

No se incluye cambio alguno a `main.gd` ni a `abadia_renderer.gd`, porque sería engañoso anunciar «pintado exacto» con estos datos.
