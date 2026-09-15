extends Node3D

@export var tipo: int = 0
@export var nombre: String = "Personaje"
@export var velocidad: float = 3.0

var objetivo: Vector3
var esperando: bool = false
var tiempo_espera: float = 0.0

# Coordenadas: _room_to_world(gx, gy, tx, ty)
# gx,gy = room grid, tx,ty = tile in room
# world_x = gx * 32 + tx * 2 + 1, world_z = gy * 32 + ty * 2 + 1
var rutas := {
	0: [  # Abad: celda -> altar -> refectorio -> celda
		Vector3(5*32+4*2+1, 0, 3*32+12*2+1),  # celda (5,3)(4,12)
		Vector3(8*32+8*2+1, 0, 3*32+12*2+1),  # altar (8,3)(8,12)
		Vector3(3*32+13*2+1, 0, 3*32+7*2+1),  # refectorio (3,3)(13,7)
		Vector3(5*32+4*2+1, 0, 3*32+12*2+1),  # celda
	],
	1: [  # Adso: celda Guillermo -> iglesia -> celda
		Vector3(10*32+5*2+1, 0, 2*32+1*2+1),
		Vector3(9*32+12*2+1, 0, 2*32+10*2+1),
		Vector3(10*32+5*2+1, 0, 2*32+1*2+1),
	],
	2: [  # Malaquías: scriptorium -> claustro -> scriptorium
		Vector3(3*32+10*2+1, 0, 3*32+4*2+1),
		Vector3(2*32+8*2+1, 0, 1*32+8*2+1),
		Vector3(3*32+10*2+1, 0, 3*32+4*2+1),
	],
	3: [  # Berengario: altar -> nave -> altar
		Vector3(8*32+8*2+1, 0, 3*32+12*2+1),
		Vector3(8*32+8*2+1, 0, 2*32+4*2+1),
		Vector3(8*32+8*2+1, 0, 3*32+12*2+1),
	],
	4: [  # Severino: celda -> celdas monjes -> celda
		Vector3(6*32+8*2+1, 0, 6*32+1*2+1),
		Vector3(5*32+4*2+1, 0, 3*32+12*2+1),
		Vector3(6*32+8*2+1, 0, 6*32+1*2+1),
	],
	5: [  # Bernardo: entrada -> iglesia -> entrada
		Vector3(8*32+8*2+1, 0, 8*32+4*2+1),
		Vector3(8*32+8*2+1, 0, 2*32+4*2+1),
		Vector3(8*32+8*2+1, 0, 8*32+4*2+1),
	],
	6: [  # Jorge: su area -> scriptorium -> su area
		Vector3(12*32+7*2+1, 0, 2*32+7*2+1),
		Vector3(3*32+10*2+1, 0, 3*32+4*2+1),
		Vector3(12*32+7*2+1, 0, 2*32+7*2+1),
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

	var pos_actual = Vector3(position.x, 0, position.z)
	var dir_obj = Vector3(objetivo.x, 0, objetivo.z) - pos_actual
	var distancia = dir_obj.length()

	if distancia < 1.0:
		esperando = true
		tiempo_espera = randf_range(1.0, 3.0)
		return

	var dir = dir_obj.normalized()
	position.x += dir.x * velocidad * delta
	position.z += dir.z * velocidad * delta

	# Keep Y based on terrain height (rough: just keep current Y)
	if dir.length() > 0.01:
		look_at(position + Vector3(dir.x, 0, dir.z), Vector3.UP)
