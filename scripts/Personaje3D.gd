extends Node3D

# Personaje 3D que camina por el mapa

@export var tipo: int = 0  # 0=Abad, 1-5=Monjes
@export var nombre: String = "Personaje"
@export var velocidad: float = 3.0

var objetivo: Vector3
var esperando: bool = false
var tiempo_espera: float = 0.0

# Rutas predefinidas (posiciones en el mapa 3D)
var rutas := {
	0: [  # Abad
		Vector3(128, 2, 48),   # Altar
		Vector3(48, 2, 48),    # Refectorio
		Vector3(80, 2, 48),    # Celda
		Vector3(140, 2, 128),  # Entrada
	],
	1: [  # Adso
		Vector3(80, 2, 60),
		Vector3(128, 2, 48),
		Vector3(80, 2, 60),
	],
	2: [  # Malaquías
		Vector3(48, 2, 48),
		Vector3(48, 2, 96),
		Vector3(48, 2, 48),
	],
	3: [  # Berengario
		Vector3(96, 2, 96),
		Vector3(128, 2, 48),
		Vector3(96, 2, 96),
	],
	4: [  # Severino
		Vector3(100, 2, 32),
		Vector3(128, 2, 48),
		Vector3(100, 2, 32),
	],
	5: [  # Bernardo
		Vector3(140, 2, 140),
		Vector3(128, 2, 48),
		Vector3(140, 2, 140),
	],
	6: [  # Jorge
		Vector3(32, 2, 100),
		Vector3(48, 2, 48),
		Vector3(32, 2, 100),
	],
}

var ruta_actual: Array = []
var indice_punto: int = 0

func _ready() -> void:
	ruta_actual = rutas.get(tipo, [])
	if ruta_actual.size() > 0:
		objetivo = ruta_actual[0]
		indice_punto = 0

func _process(delta: float) -> void:
	if ruta_actual.is_empty():
		return

	if esperando:
		tiempo_espera -= delta
		if tiempo_espera <= 0:
			esperando = false
			indice_punto = (indice_punto + 1) % ruta_actual.size()
			objetivo = ruta_actual[indice_punto]
		return

	var direccion = (objetivo - position)
	direccion.y = 0
	var distancia = direccion.length()

	if distancia < 1.0:
		esperando = true
		tiempo_espera = randf_range(1.0, 3.0)
		return

	var dir = direccion.normalized()
	position += dir * velocidad * delta

	# Rotar hacia la dirección de movimiento
	if dir.length() > 0.01:
		look_at(position + dir, Vector3.UP)
