extends CharacterBody3D

@export var tipo: int = 0
@export var nombre: String = "Personaje"
@export var velocidad: float = 3.0

var objetivo: Vector3
var esperando: bool = false
var tiempo_espera: float = 0.0
var altura_actual: float = 0.1

# Coordenadas: world_x = gx * 32 + tx * 2 + 1, world_z = gy * 32 + ty * 2 + 1
var rutas := {
	0: [
		Vector3(5*32+4*2+1, 0, 3*32+12*2+1),
		Vector3(8*32+8*2+1, 0, 3*32+12*2+1),
		Vector3(3*32+13*2+1, 0, 3*32+7*2+1),
		Vector3(5*32+4*2+1, 0, 3*32+12*2+1),
	],
	1: [
		Vector3(10*32+5*2+1, 0, 2*32+1*2+1),
		Vector3(9*32+12*2+1, 0, 2*32+10*2+1),
		Vector3(10*32+5*2+1, 0, 2*32+1*2+1),
	],
	2: [
		Vector3(3*32+10*2+1, 0, 3*32+4*2+1),
		Vector3(2*32+8*2+1, 0, 1*32+8*2+1),
		Vector3(3*32+10*2+1, 0, 3*32+4*2+1),
	],
	3: [
		Vector3(8*32+8*2+1, 0, 3*32+12*2+1),
		Vector3(8*32+8*2+1, 0, 2*32+4*2+1),
		Vector3(8*32+8*2+1, 0, 3*32+12*2+1),
	],
	4: [
		Vector3(6*32+8*2+1, 0, 6*32+1*2+1),
		Vector3(5*32+4*2+1, 0, 3*32+12*2+1),
		Vector3(6*32+8*2+1, 0, 6*32+1*2+1),
	],
	5: [
		Vector3(8*32+8*2+1, 0, 8*32+4*2+1),
		Vector3(8*32+8*2+1, 0, 2*32+4*2+1),
		Vector3(8*32+8*2+1, 0, 8*32+4*2+1),
	],
	6: [
		Vector3(12*32+7*2+1, 0, 2*32+7*2+1),
		Vector3(3*32+10*2+1, 0, 3*32+4*2+1),
		Vector3(12*32+7*2+1, 0, 2*32+7*2+1),
	],
}

var ruta_actual: Array = []
var indice_punto: int = 0

func _ready() -> void:
	altura_actual = position.y
	ruta_actual = rutas.get(tipo, [])
	if ruta_actual.size() > 0:
		objetivo = ruta_actual[0]
		indice_punto = 0

func _physics_process(delta: float) -> void:
	if ruta_actual.is_empty():
		return

	if esperando:
		tiempo_espera -= delta
		if tiempo_espera <= 0:
			esperando = false
			indice_punto = (indice_punto + 1) % ruta_actual.size()
			objetivo = ruta_actual[indice_punto]
		return

	var pos2d = Vector2(position.x, position.z)
	var obj2d = Vector2(objetivo.x, objetivo.z)
	var dir2d = obj2d - pos2d
	var distancia = dir2d.length()

	if distancia < 1.0:
		esperando = true
		tiempo_espera = randf_range(1.0, 3.0)
		velocity = Vector3.ZERO
		return

	var dir = Vector3(dir2d.x, 0, dir2d.y).normalized()
	velocity = dir * velocidad
	move_and_slide()

	# Mantener altura
	position.y = altura_actual

	if dir.length() > 0.01:
		look_at(position + Vector3(dir.x, 0, dir.z), Vector3.UP)
