extends CharacterBody2D

enum TipoMonje {
	CORO,
	SCRIPTORIUM,
	REFECTORIO,
	NOCTURNO,
}

@export var tipo: TipoMonje = TipoMonje.CORO
@export var nombre: String = "Monje"

var velocidad: float = 35.0
var ruta_actual: Array = []
var indice_punto: int = 0
var esperando: bool = false

var rutas_por_tipo := {
	TipoMonje.CORO: [
		Vector2(0x54, 0x3c),
		Vector2(0x88, 0x84),
		Vector2(0x88, 0x3c),
		Vector2(0x88, 0x84),
		Vector2(0x54, 0x3c),
	],
	TipoMonje.SCRIPTORIUM: [
		Vector2(0x3a, 0x34),
		Vector2(0x3a, 0x0f),
		Vector2(0x3a, 0x34),
	],
	TipoMonje.REFECTORIO: [
		Vector2(0x54, 0x3c),
		Vector2(0x3d, 0x37),
		Vector2(0x54, 0x3c),
	],
	TipoMonje.NOCTURNO: [
		Vector2(0x20, 0x20),
		Vector2(0x10, 0x20),
		Vector2(0x20, 0x20),
	],
}

func _ready() -> void:
	ruta_actual = rutas_por_tipo.get(tipo, [])
	Horario.hora_cambiada.connect(_on_hora_cambiada)

func _on_hora_cambiada(_hora: int, nombre_hora: String) -> void:
	var horas_activas := ["Prima", "Tercia", "Sexta", "Nona", "Vísperas"]
	if nombre_hora in horas_activas:
		indice_punto = 0
	else:
		ruta_actual = []

func _physics_process(_delta: float) -> void:
	if ruta_actual.is_empty() or esperando:
		return

	var objetivo = ruta_actual[indice_punto]
	var dir = (objetivo - global_position).normalized()
	velocity = dir * velocidad
	move_and_slide()

	if global_position.distance_to(objetivo) < 4.0:
		indice_punto = (indice_punto + 1) % ruta_actual.size()
		esperando = true
		await get_tree().create_timer(randf_range(1.0, 3.0)).timeout
		esperando = false
