extends CharacterBody2D

# Tipos de monjes extraídos de Abad.js
# 0=Adso, 1=Malaquias, 2=Berengario, 3=Severino, 4=Bernardo, 5=Jorge

enum TipoMonje {
	ADSO = 0,
	MALAQUIAS = 1,
	BERENGARIO = 2,
	SEVERINO = 3,
	BERNARDO = 4,
	JORGE = 5,
}

@export var tipo: int = TipoMonje.ADSO
@export var nombre: String = "Monje"

var velocidad: float = 35.0
var ruta_actual: Array = []
var indice_punto: int = 0
var esperando: bool = false
var floor_num: int = 0
var room := Vector2i.ZERO

# Posiciones iniciales por tipo (extraído de Abad.js y los scripts)
var posiciones_iniciales := {
	TipoMonje.ADSO: {"floor": 0, "room": Vector2i(10, 2), "pos": Vector2i(5, 1)},
	TipoMonje.MALAQUIAS: {"floor": 1, "room": Vector2i(3, 3), "pos": Vector2i(10, 4)},
	TipoMonje.BERENGARIO: {"floor": 1, "room": Vector2i(1, 2), "pos": Vector2i(8, 4)},
	TipoMonje.SEVERINO: {"floor": 0, "room": Vector2i(6, 6), "pos": Vector2i(8, 1)},
	TipoMonje.BERNARDO: {"floor": 0, "room": Vector2i(8, 8), "pos": Vector2i(8, 8)},
	TipoMonje.JORGE: {"floor": 2, "room": Vector2i(1, 6), "pos": Vector2i(2, 5)},
}

# Rutas por momento del día
var rutas_por_momento := {
	"Prima": [
		{"room": Vector2i(8, 4), "pos": Vector2i(4, 11)},  # Iglesia
	],
	"Tercia": [
		{"room": Vector2i(3, 3), "pos": Vector2i(13, 7)},  # Refectorio
	],
	"Sexta": [
		{"room": Vector2i(3, 3), "pos": Vector2i(13, 7)},  # Refectorio
	],
	"Nona": [
		{"room": Vector2i(8, 4), "pos": Vector2i(4, 11)},  # Iglesia
	],
	"Vísperas": [
		{"room": Vector2i(8, 4), "pos": Vector2i(4, 11)},  # Iglesia
	],
}

func _ready() -> void:
	var init_data = posiciones_iniciales.get(tipo, posiciones_iniciales[0])
	floor_num = init_data["floor"]
	room = init_data["room"]
	position = Vector2(init_data["pos"])

	Horario.hora_cambiada.connect(_on_hora_cambiada)

func _on_hora_cambiada(_hora: int, nombre_hora: String) -> void:
	ruta_actual = rutas_por_momento.get(nombre_hora, [])
	indice_punto = 0

func _physics_process(_delta: float) -> void:
	if ruta_actual.is_empty() or esperando:
		return

	var objetivo = ruta_actual[indice_punto]
	var destino = Vector2(objetivo["room"]) * 16 + Vector2(objetivo["pos"])
	var dir = (destino - global_position).normalized()
	velocity = dir * velocidad
	move_and_slide()

	if global_position.distance_to(destino) < 4.0:
		indice_punto = (indice_punto + 1) % ruta_actual.size()
		esperando = true
		await get_tree().create_timer(randf_range(1.0, 3.0)).timeout
		esperando = false
