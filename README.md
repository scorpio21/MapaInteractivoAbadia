# Mapa interactivo La Abadía del Crimen

Proyecto con **Godot Engine 4.7** inspirado en la novela *El nombre de la rosa* de Umberto Eco. Mapa 2D interactivo con recorridos, zonas y horarios.

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
assets/              Texturas y sonidos (piso1, piso2, abad, campana, pasos)
scenes/              Escenas (Main, Jugador, MapaPisos, UI)
scripts/             Scripts adjuntos (Jugador, MapaPisos, Reloj, UI)
```

## Funcionalidades

- **Jugador** (`CharacterBody2D`): movimiento con flechas y sonido de pasos (`assets/sonidos/pasos.mp3`).
- **Mapa de pisos** (`MapaPisos.tscn`): planos con `Path2D` (`RutaAbad`) y recorrido automático del abad con `PathFollow2D`.
- **Reloj** (`Reloj.gd`): sistema de horas con `hora_actual` y detección de hora prohibida (22:00–06:00).
- **Zonas interactivas**: al entrar en un `Area2D`, el abad (o el área) informa del lugar; las zonas en grupo `zona_prohibida` durante la hora prohibida muestran un aviso.
- **UI** (`UI.tscn`): panel con mensajes de zona y hora actual.

## Roadmap (ideas)

- Avanzar la hora del reloj automáticamente (`Reloj.avanzar_hora`).
- Definir `Area2D` en grupos `zona_interactiva` / `zona_prohibida` sobre el mapa.
- Conexión de `campana.mp3` (campana de la abadía).
- Añadir piso 3 y otros recorridos.