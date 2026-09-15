extends CharacterBody3D

@export var tipo: int = 0
@export var nombre: String = "Personaje"
@export var velocidad: float = 3.0

var objetivo: Vector3
var esperando: bool = false
var tiempo_espera: float = 0.0
var altura_actual: float = 0.1
var ray_cast: RayCast3D

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

	ray_cast = RayCast3D.new()
	ray_cast.target_position = Vector3(0, 0, -1.5)
	ray_cast.enabled = true
	add_child(ray_cast)

func _physics_process(delta: float) -> void:
	if ruta_actual.is_empty():
		return

	if esperando:
		tiempo_espera -= delta
		if tiempo_espera <= 0:
			esperando = false
			indice_punto = (indice_punto + 1) % ruta_actual.size()
			objetivo = ruta_actual[indice_punto]
		velocity = Vector3.ZERO
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

	# Update raycast direction
	ray_cast.target_position = Vector3(dir.x * 1.5, 0, dir.z * 1.5)
	force_raycast_update()

	if ray_cast.is_colliding():
		# Wall ahead - try sliding along it
		var collision_normal = ray_cast.get_collision_normal()
		var slide_dir = dir.slide(collision_normal).normalized()
		if slide_dir.length() > 0.01:
			velocity = slide_dir * velocidad
		else:
			velocity = Vector3.ZERO
	else:
		velocity = dir * velocidad

	move_and_slide()
	position.y = altura_actual

	if velocity.length() > 0.01:
		look_at(position + Vector3(velocity.x, 0, velocity.z), Vector3.UP)
