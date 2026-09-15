extends CharacterBody2D

# Estados extraídos de Abad.java
enum Estado {
	ESPERANDO_LLEGADA,
	VA_PRIMERA_PARADA,
	PRIMERA_PARADA,
	VA_SEGUNDA_PARADA,
	VA_CELDA,
	VA_MISA_VISPERAS,
	COMPLETAS_ESPERA,
	ENTRADA_CELDA_G,
	ORDENA_ENTRAR,
	VA_PUERTA_CELDAS,
	CIERRA_PUERTA,
	ECHAR_GUILLERMO,
	DURMIENDO,
	DESPIERTA_PATRULLA,
	VA_MISA_PRIMA,
	ESPERA_FRASE_MISA,
	VA_REFECTORIO,
	LLAMA_GUILLERMO,
	DICE_FRASE,
	VA_CELDA_SEVERINO,
	DEJA_PERGAMINO,
	SEGUNDA_PARADA,
}

var estado: Estado = Estado.ESPERANDO_LLEGADA
var contador: int = 0
var num_frase: int = 0
var guillermo_bien_colocado: int = 0
var llegan_los_monjes: int = 0

# Posiciones predefinidas (extraído de Abad.java)
var posiciones := {
	0: Vector2(0x88, 0x3c),
	1: Vector2(0x3d, 0x37),
	2: Vector2(0x54, 0x3c),
	3: Vector2(0x88, 0x84),
	4: Vector2(0xa4, 0x58),
	5: Vector2(0xa5, 0x21),
	6: Vector2(0x9c, 0x2a),
	7: Vector2(0xc7, 0x27),
	8: Vector2(0x68, 0x61),
	9: Vector2(0x3a, 0x34),
}

var a_donde_va: int = 2
var a_donde_ha_llegado: int = -1
var velocidad: float = 50.0

func _ready() -> void:
	Horario.hora_cambiada.connect(_on_hora_cambiada)

func _on_hora_cambiada(_hora: int, nombre_hora: String) -> void:
	match nombre_hora:
		"Maitines", "Laudes", "Prima":
			estado = Estado.VA_MISA_PRIMA
			a_donde_va = 0
		"Tercia":
			estado = Estado.VA_REFECTORIO
			a_donde_va = 1
		"Sexta":
			estado = Estado.VA_REFECTORIO
			a_donde_va = 1
		"Nona", "Vísperas", "Completas":
			estado = Estado.VA_MISA_VISPERAS
			a_donde_va = 0
		"Noche":
			estado = Estado.DURMIENDO
			a_donde_va = 2

func _physics_process(delta: float) -> void:
	if estado == Estado.DURMIENDO:
		_procesar_sueno(delta)
		return

	if estado == Estado.DESPIERTA_PATRULLA:
		_procesar_patrulla_nocturna(delta)
		return

	var destino = posiciones.get(a_donde_va, posiciones[2])
	var direccion = (destino - global_position).normalized()
	velocity = direccion * velocidad
	move_and_slide()

	if global_position.distance_to(destino) < 8.0:
		a_donde_ha_llegado = a_donde_va
		_procesar_llegada()

func _procesar_llegada() -> void:
	match estado:
		Estado.VA_MISA_PRIMA:
			if guillermo_bien_colocado >= 1 and llegan_los_monjes == 0:
				Horario.avanzar_momento_dia()
		Estado.VA_REFECTORIO:
			if guillermo_bien_colocado >= 1 and llegan_los_monjes == 0:
				Horario.avanzar_momento_dia()
		Estado.CIERRA_PUERTA:
			Horario.avanzar_momento_dia()
		Estado.DURMIENDO:
			contador = 0

func _procesar_sueno(delta: float) -> void:
	contador += 1
	if Horario.es_hora_prohibida():
		var jugadores = get_tree().get_nodes_in_group("jugador")
		for jugador in jugadores:
			if jugador.global_position.x < 0x60:
				estado = Estado.DESPIERTA_PATRULLA
				contador = 0

func _procesar_patrulla_nocturna(delta: float) -> void:
	var ruta_nocturna := [
		posiciones[2],
		Vector2(0x20, 0x20),
		Vector2(0x10, 0x10),
		Vector2(0x30, 0x10),
		Vector2(0x80, 0x20),
		posiciones[0],
		Vector2(0x3a, 0x34),
		posiciones[2],
	]

	if contador >= ruta_nocturna.size():
		estado = Estado.DURMIENDO
		contador = 0
		return

	var destino = ruta_nocturna[contador]
	var direccion = (destino - global_position).normalized()
	velocity = direccion * velocidad
	move_and_slide()

	if global_position.distance_to(destino) < 8.0:
		contador += 1

func get_estado_nombre() -> String:
	return Estado.keys()[estado]
