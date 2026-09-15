extends Node2D

const AbbeyMapScript = preload("res://scripts/AbbeyMap.gd")
const PathFinderScript = preload("res://scripts/PathFinder.gd")
const AbadIAScript = preload("res://scripts/AbadIA.gd")
const MonjeIAScript = preload("res://scripts/MonjeIA.gd")

var abbey_map
var path_finder
var abad
var monjes := []
var zonas := {}

func _ready() -> void:
	abbey_map = AbbeyMapScript.new()
	path_finder = PathFinderScript.new(abbey_map)
	_crear_zonas()
	_crear_personajes()

func _crear_zonas() -> void:
	var zonas_datos := {
		"iglesia": {"rect": Rect2(500, 0, 200, 200), "prohibida": false},
		"claustro": {"rect": Rect2(0, 0, 200, 200), "prohibida": false},
		"refectorio": {"rect": Rect2(200, 200, 200, 200), "prohibida": false},
		"celda_abad": {"rect": Rect2(400, 400, 100, 100), "prohibida": true},
		"celda_guillermo": {"rect": Rect2(300, 400, 100, 100), "prohibida": false},
		"cocina": {"rect": Rect2(0, 200, 200, 200), "prohibida": false},
		"scriptorium": {"rect": Rect2(0, 400, 200, 200), "prohibida": false},
		"biblioteca": {"rect": Rect2(200, 400, 200, 200), "prohibida": true},
		"entrada": {"rect": Rect2(500, 400, 200, 200), "prohibida": false},
	}

	for nombre in zonas_datos:
		var datos = zonas_datos[nombre]
		var zona = Area2D.new()
		zona.name = nombre
		zona.position = datos["rect"].position

		var shape = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = datos["rect"].size
		shape.shape = rect_shape
		zona.add_child(shape)

		if datos["prohibida"]:
			zona.add_to_group("zona_prohibida")

		zona.add_to_group("zona_interactiva")
		add_child(zona)
		zonas[nombre] = zona

func _crear_personajes() -> void:
	abad = AbadIAScript.new()
	abad.name = "Abad"
	abad.position = Vector2(0x88, 0x3c)
	abad.modulate = Color(1, 0.8, 0.2)
	add_child(abad)

	var tipos_monjes := [
		{"tipo": 0, "nombre": "Berengario", "pos": Vector2(0x54, 0x3c)},
		{"tipo": 1, "nombre": "Malaquías", "pos": Vector2(0x3a, 0x34)},
		{"tipo": 2, "nombre": "Severino", "pos": Vector2(0x68, 0x61)},
		{"tipo": 0, "nombre": "Bernardo", "pos": Vector2(0x88, 0x84)},
		{"tipo": 3, "nombre": "Jorge", "pos": Vector2(0x3a, 0x0f)},
	]

	for datos in tipos_monjes:
		var monje = MonjeIAScript.new()
		monje.name = datos["nombre"]
		monje.set("tipo", datos["tipo"])
		monje.set("nombre", datos["nombre"])
		monje.position = datos["pos"]
		monje.modulate = Color(0.8, 0.8, 0.8)
		add_child(monje)
		monjes.append(monje)

func get_zona_en_posicion(pos: Vector2) -> String:
	for nombre in zonas:
		var zona = zonas[nombre]
		if zona.get_global_rect().has_point(pos):
			return nombre
	return ""

func get_abbey_map():
	return abbey_map

func get_path_finder():
	return path_finder
