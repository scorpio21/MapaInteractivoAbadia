# Análisis técnico de discrepancia entre el visor original de La Abadía del Crimen y la implementación en Godot

## Contexto

Estoy desarrollando una reimplementación en Godot 4 del visor de habitaciones de **La Abadía del Crimen**, tomando como referencia el visor web original.

Actualmente dispongo de:

- Visor web original (JavaScript).
- Implementación propia en Godot 4.

---

# Estado actual del proyecto

## Minimapa

La funcionalidad básica del minimapa ya está implementada:

- Selector de planta.
- Selector de habitaciones.
- Marcadores visuales.
- Calibración manual mediante clic.
- Exportación de coordenadas a fichero de texto.
- Persistencia de las posiciones ajustadas.

Las plantas disponibles son:

```gdscript
const FLOOR_NAMES := [
	"Iglesia",
	"Scriptorium",
	"Biblioteca"
]
```

---

## Sistema de habitaciones

Las habitaciones se almacenan en:

```gdscript
var room_positions: Array[Dictionary]
```

Cada diccionario contiene:

```gdscript
numero_habitacion -> Vector2(x_normalizada, y_normalizada)
```

Ejemplo:

```gdscript
73: Vector2(0.72, 0.27)
```

Las coordenadas están normalizadas entre 0 y 1.

---

# Cambios realizados recientemente

## Marcador cyan (habitación seleccionada)

Se implementó un marcador visual para representar la habitación seleccionada:

```gdscript
selected_marker : ColorRect
```

La posición se actualiza mediante:

```gdscript
_update_marker()
```

Actualmente el tamaño se adapta según la planta:

```gdscript
if current_floor == 0:
	selected_marker.size = Vector2(16, 16)
else:
	selected_marker.size = Vector2(32, 32)
```

Esta lógica está basada en el análisis del visor original, donde:

- Iglesia utiliza celdas de 16x16.
- Scriptorium utiliza celdas de 32x32.
- Biblioteca utiliza celdas de 32x32.

---

## Marcador amarillo (último clic)

También existe un segundo marcador:

```gdscript
marker : ColorRect
```

Su función es mostrar visualmente el último punto pulsado durante la calibración.

---

## Exportación de coordenadas

Cuando se realiza un clic sobre el minimapa se actualiza:

```gdscript
room_positions[current_floor][current_room] = normalized
```

y posteriormente:

```gdscript
_save_room_positions()
```

Lo que genera un fichero:

```text
room_positions.txt
```

Ejemplo de salida:

```text
CALIBRACIÓN | planta=Iglesia habitación=51 coordenadas=(0.6217, 0.9304)
```

El fichero generado contiene todas las habitaciones de todas las plantas con sus coordenadas actuales.

---

# Comportamiento observado

## Caso de prueba

Planta:

```text
Scriptorium
```

Habitación:

```text
73
```

---

# Comparación visual

## Visor web original

Para la habitación 73 se muestra:

- Sala relativamente pequeña.
- Escalera lateral.
- Suelo ajedrezado.
- Distribución compacta.
- La vista aparece centrada.

## Implementación Godot

Para la misma habitación 73 se muestra:

- Una sala mucho más grande.
- Mesas y atriles.
- Otra distribución arquitectónica.
- Distinta composición espacial.
- Distinta perspectiva visual.

Visualmente ambas habitaciones no coinciden.

---

# Observaciones importantes

## El minimapa parece correcto

Se observa que:

- La planta seleccionada coincide.
- La habitación seleccionada coincide.
- El marcador aparece en la zona correcta del minimapa.
- La calibración parece funcionar correctamente.

Por tanto:

```text
La selección de habitación parece correcta.
```

---

## El render 3D NO coincide

La discrepancia aparece exclusivamente en la habitación renderizada.

Esto sugiere que el problema está entre:

```text
Habitación lógica
↓
Pantalla 3D mostrada
```

y no en el minimapa.

---

# Hipótesis principal

Actualmente mi implementación utiliza una función provisional:

```gdscript
func logical_room_to_data_block(room_number: int) -> int:
	return room_number
```

Lo que implica:

```text
Habitación 73
↓
Bloque 73
```

sin ninguna transformación adicional.

---

# Sospecha

Tras comparar el comportamiento del visor original, sospecho que el número de habitación NO corresponde directamente con el índice utilizado por el motor de renderizado.

Es posible que exista una tabla de conversión similar a:

```text
Habitación lógica
↓
Identificador interno
↓
Bloque de pantalla
↓
Renderizado
```

y que mi implementación esté omitiendo esa transformación.

---

# Información relevante del código JavaScript original

En el código original existe una tabla de habitaciones:

```javascript
var c = new Uint8Array(...)
```

y una función:

```javascript
function l(x, y) {
	if (x < 0 || x >= 16 || y < 0 || y >= 15)
		return -1;

	let room = c[y * 16 + x];

	return room;
}
```

Esta función devuelve el número lógico de habitación.

Posteriormente se termina llamando a:

```javascript
generateScreen(room, ...)
```

pero todavía no he podido determinar si existe una transformación intermedia entre:

```text
room
```

y

```text
bloque de pantalla real
```

---

# Preguntas para analizar

## Pregunta 1

¿Existe en el visor original alguna tabla de conversión entre:

```text
Número lógico de habitación
```

y

```text
Identificador interno de pantalla
```

?

---

## Pregunta 2

¿El motor utiliza realmente:

```javascript
generateScreen(room)
```

de forma directa?

o

¿existe previamente alguna conversión similar a:

```javascript
screenId = roomToScreen[room];
```

?

---

## Pregunta 3

¿Es incorrecta la implementación actual?

```gdscript
func logical_room_to_data_block(room_number: int) -> int:
	return room_number
```

y debería sustituirse por una tabla equivalente a la utilizada por el visor web original.

---

# Conclusión provisional

Todo apunta a que:

✅ El minimapa funciona correctamente.

✅ La selección de habitación funciona.

✅ La calibración de coordenadas funciona.

✅ Los marcadores funcionan.

❌ El renderizado 3D no coincide con el visor original.

La causa más probable parece estar en el mapeo:

```text
Habitación lógica
↓
Bloque de datos 3D
```

ya que actualmente se está utilizando una correspondencia directa:

```gdscript
room_number == block_number
```

y sospecho que el visor original utiliza una conversión adicional que todavía no he identificado.