extends Node

signal hora_cambiada(hora: int, nombre: String)
signal momento_cambiado(momento: String)

# Momentos del día (extraído de GameLogic.js)
enum MomentoDia {
	NOCHE,
	PRIMA,
	TERCIA,
	SEXTA,
	NONA,
	VISPERAS,
	COMPLETAS,
}

# Duración de cada momento por día (extraído de GameLogic.js)
# Valores en ticks de 256 ( TICK_TIME * 256 = 45ms * 256 = 11520ms ≈ 11.5s por tick)
var DURACIONES := [
	[0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],  # Día 1
	[0x00, 0x00, 0x05, 0x00, 0x05, 0x00, 0x00],  # Día 2
	[0x00, 0x00, 0x05, 0x00, 0x05, 0x00, 0x00],  # Día 3
	[0x0f, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00],  # Día 4
	[0x0f, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00],  # Día 5
	[0x0f, 0x00, 0x05, 0x00, 0x05, 0x00, 0x00],  # Día 6
	[0x0f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],  # Día 7
]

var momento_actual: int = MomentoDia.SEXTA  # Empieza en Sexta como en el original
var dia: int = 1
var minuto_actual: float = 720.0  # 12:00 (Sexta)
var velocidad_tiempo: float = 30.0
var timer_avance: Timer

var nombres_momentos := {
	MomentoDia.NOCHE: "Noche",
	MomentoDia.PRIMA: "Prima",
	MomentoDia.TERCIA: "Tercia",
	MomentoDia.SEXTA: "Sexta",
	MomentoDia.NONA: "Nona",
	MomentoDia.VISPERAS: "Vísperas",
	MomentoDia.COMPLETAS: "Completas",
}

var minutos_por_momento := {
	MomentoDia.NOCHE: 0,
	MomentoDia.PRIMA: 360,
	MomentoDia.TERCIA: 540,
	MomentoDia.SEXTA: 720,
	MomentoDia.NONA: 900,
	MomentoDia.VISPERAS: 1080,
	MomentoDia.COMPLETAS: 1260,
}

func _ready() -> void:
	timer_avance = Timer.new()
	timer_avance.one_shot = true
	timer_avance.timeout.connect(_on_timer_avance)
	add_child(timer_avance)
	_iniciar_timer()

func _iniciar_timer() -> void:
	var duracion = DURACIONES[dia - 1][momento_actual]
	if duracion > 0:
		var tiempo_real = duracion * 45.0 * 256.0 / 1000.0  # Convertir a segundos
		timer_avance.start(tiempo_real)

func _on_timer_avance() -> void:
	avanzar_momento_dia()

func _process(delta: float) -> void:
	minuto_actual += velocidad_tiempo * delta

	if minuto_actual >= 1440.0:
		minuto_actual -= 1440.0

func _calcular_momento() -> int:
	if minuto_actual < 360:
		return MomentoDia.NOCHE
	elif minuto_actual < 540:
		return MomentoDia.PRIMA
	elif minuto_actual < 720:
		return MomentoDia.TERCIA
	elif minuto_actual < 900:
		return MomentoDia.SEXTA
	elif minuto_actual < 1080:
		return MomentoDia.NONA
	elif minuto_actual < 1260:
		return MomentoDia.VISPERAS
	else:
		return MomentoDia.COMPLETAS

func avanzar_momento_dia() -> void:
	timer_avance.stop()

	var siguientes := {
		MomentoDia.NOCHE: MomentoDia.PRIMA,
		MomentoDia.PRIMA: MomentoDia.TERCIA,
		MomentoDia.TERCIA: MomentoDia.SEXTA,
		MomentoDia.SEXTA: MomentoDia.NONA,
		MomentoDia.NONA: MomentoDia.VISPERAS,
		MomentoDia.VISPERAS: MomentoDia.COMPLETAS,
		MomentoDia.COMPLETAS: MomentoDia.NOCHE,
	}

	momento_actual = siguientes[momento_actual]
	minuto_actual = minutos_por_momento[momento_actual]

	if momento_actual == MomentoDia.NOCHE:
		dia += 1
		if dia > 7:
			dia = 1

	momento_cambiado.emit(nombres_momentos[momento_actual])
	hora_cambiada.emit(int(minuto_actual), nombres_momentos[momento_actual])

	_iniciar_timer()

func es_hora_prohibida() -> bool:
	return momento_actual == MomentoDia.NOCHE

func get_hora_display() -> String:
	var horas := int(minuto_actual) / 60
	var minutos := int(minuto_actual) % 60
	return "%02d:%02d" % [horas, minutos]

func get_momento_nombre() -> String:
	return nombres_momentos[momento_actual]

func get_dia() -> int:
	return dia

func is_night() -> bool:
	return momento_actual == MomentoDia.COMPLETAS or momento_actual == MomentoDia.NOCHE
