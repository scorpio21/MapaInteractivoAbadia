extends Node

signal hora_cambiada(hora: int, nombre: String)
signal momento_cambiado(momento: String)

# Momentos del día (extraído de MomentosDia.java)
enum MomentoDia {
	NOCHE,
	PRIMA,
	TERCIA,
	SEXTA,
	NONA,
	VISPERAS,
	COMPLETAS,
}

var momento_actual: int = MomentoDia.NOCHE
var dia: int = 1
var minuto_actual: float = 0.0
var velocidad_tiempo: float = 30.0

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

func _process(delta: float) -> void:
	minuto_actual += velocidad_tiempo * delta

	if minuto_actual >= 1440.0:
		minuto_actual -= 1440.0

	var nuevo_momento := _calcular_momento()
	if nuevo_momento != momento_actual:
		momento_actual = nuevo_momento
		momento_cambiado.emit(nombres_momentos[momento_actual])
		hora_cambiada.emit(int(minuto_actual), nombres_momentos[momento_actual])

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

	momento_cambiado.emit(nombres_momentos[momento_actual])

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
