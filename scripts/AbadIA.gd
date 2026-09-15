extends CharacterBody2D

# Estados extraídos de Abad.js
enum Estado {
	ESPERANDO = 0,
	VA_PRIMERA_PARADA = 1,
	PRIMERA_PARADA = 2,
	VA_SEGUNDA_PARADA = 3,
	VA_CELDA = 4,
	VA_MISA_VISPERAS = 5,
	COMPLETAS_ESPERA = 6,
	ENTRADA_CELDA_G = 7,
	ORDENA_ENTRAR = 8,
	VA_PUERTA_CELDAS = 9,
	CIERRA_PUERTA = 10,
	ECHAR_GUILLERMO = 11,
	DURMIENDO = 12,
	DESPIERTA_PATRULLA = 13,
	VA_MISA_PRIMA = 14,
	ESPERA_FRASE_MISA = 15,
	VA_REFECTORIO = 16,
	LLAMA_GUILLERMO = 17,
	DICE_FRASE = 18,
	VA_CELDA_SEVERINO = 19,
	DEJA_PERGAMINO = 21,
	SEGUNDA_PARADA = 31,
}

var estado: int = Estado.ESPERANDO
var target: int = 2
var reached: int = -1
var guillermoHasTheScroll: bool = false
var inventory: Array = []

# Posiciones predefinidas del abad (extraído de Abad.js defaultPositions)
var defaultPositions := [
	{"floor": 0, "room": Vector2i(8, 3), "pos": Vector2i(8, 12), "orient": 2, "height": 4},  # 0: altar
	{"floor": 0, "room": Vector2i(3, 3), "pos": Vector2i(13, 7), "orient": 3, "height": 2},  # 1: refectory
	{"floor": 0, "room": Vector2i(5, 3), "pos": Vector2i(4, 12), "orient": 0, "height": 2},  # 2: cell
	{"floor": 0, "room": Vector2i(8, 8), "pos": Vector2i(8, 4), "orient": 2, "height": 2},   # 3: entry
	{"floor": 0, "room": Vector2i(10, 5), "pos": Vector2i(4, 8), "orient": 1, "height": 0},  # 4: welcome
	{"floor": 0, "room": Vector2i(10, 2), "pos": Vector2i(5, 1), "orient": 0, "height": 2},  # 5: guillermo cell
	{"floor": 0, "room": Vector2i(9, 2), "pos": Vector2i(12, 10), "orient": 0, "height": 2}, # 6: church door
	{"floor": 0, "room": Vector2i(12, 2), "pos": Vector2i(7, 7), "orient": 0, "height": 0},  # 7: jorge
	{"floor": 0, "room": Vector2i(6, 6), "pos": Vector2i(8, 1), "orient": 1, "height": 2},   # 8: severino
	{"floor": 1, "room": Vector2i(3, 3), "pos": Vector2i(10, 4), "orient": 0, "height": 2},  # 9: library
]

# Monjes que deben estar en la iglesia por día y momento
var MONKS_IN_CHURCH_PRIMA := [
	[],
	[1, 2, 3, 4],  # Adso, Malaquias, Berengario, Severino
	[1, 3, 4],
	[1, 3, 4],
	[1, 3, 4, 5],
	[1],
	[1],
]

var MONKS_IN_CHURCH_VISPERAS := [
	[1, 2, 3, 4],
	[1, 2, 3, 4],
	[1, 2, 4],
	[1, 2, 4, 5],
	[],
	[1],
	[],
]

var MONKS_IN_REFECTORY := [
	[],
	[1, 3, 4],
	[1, 4],
	[1, 4],
	[1],
	[1],
	[],
]

var velocidad: float = 50.0
var dia: int = 1
var momento: int = 0  # 0=NOCHE, 1=PRIMA, 2=TERCIA, 3=SEXTA, 4=NONA, 5=VISPERAS, 6=COMPLETAS

func _ready() -> void:
	Horario.hora_cambiada.connect(_on_hora_cambiada)

func _on_hora_cambiada(_hora: int, nombre_hora: String) -> void:
	dia = Horario.get_dia()
	match nombre_hora:
		"Prima":
			momento = 1
			_procesar_prima()
		"Tercia":
			momento = 2
			_procesar_tercia()
		"Sexta":
			momento = 3
			_procesar_sexta()
		"Nona":
			momento = 4
			_procesar_nona()
		"Vísperas":
			momento = 5
			_procesar_visperas()
		"Completas":
			momento = 6
			_procesar_completas()
		"Noche":
			momento = 0
			_procesar_noche()

func _procesar_prima() -> void:
	estado = Estado.VA_MISA_PRIMA
	target = 0  # Altar

func _procesar_tercia() -> void:
	estado = Estado.VA_REFECTORIO
	target = 1

func _procesar_sexta() -> void:
	estado = Estado.VA_REFECTORIO
	target = 1

func _procesar_nona() -> void:
	if dia == 1:
		estado = Estado.PRIMERA_PARADA
		target = 3  # Entrada

func _procesar_visperas() -> void:
	estado = Estado.VA_MISA_VISPERAS
	target = 0

func _procesar_completas() -> void:
	estado = Estado.COMPLETAS_ESPERA

func _procesar_noche() -> void:
	estado = Estado.DURMIENDO
	target = 2  # Celda

func _physics_process(delta: float) -> void:
	if estado == Estado.DURMIENDO:
		_procesar_sueno(delta)
		return

	var destino_info = defaultPositions[target]
	var destino_pos = Vector2(destino_info["room"]) * 16 + Vector2(destino_info["pos"])
	var direccion = (destino_pos - global_position).normalized()
	velocity = direccion * velocidad
	move_and_slide()

	if global_position.distance_to(destino_pos) < 8.0:
		reached = target
		_procesar_llegada()

func _procesar_sueno(delta: float) -> void:
	if Horario.es_hora_prohibida():
		var jugadores = get_tree().get_nodes_in_group("jugador")
		for jugador in jugadores:
			if jugador.global_position.x < 0x60:
				estado = Estado.DESPIERTA_PATRULLA
				target = 5  # Va a celda Guillermo

func _procesar_llegada() -> void:
	match estado:
		Estado.VA_MISA_PRIMA:
			Horario.avanzar_momento_dia()
		Estado.VA_REFECTORIO:
			Horario.avanzar_momento_dia()
		Estado.VA_MISA_VISPERAS:
			Horario.avanzar_momento_dia()
		Estado.COMPLETAS_ESPERA:
			estado = Estado.VA_CELDA
			target = 2
		Estado.CIERRA_PUERTA:
			Horario.avanzar_momento_dia()

func get_estado_nombre() -> String:
	return Estado.keys()[estado]
