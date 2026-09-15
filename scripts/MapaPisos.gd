extends Node2D

@onready var ruta = $RutaAbad
var follow: PathFollow2D
var velocidad_abad := 50.0

func _ready():
	_crear_ruta_abad()

	for area in get_tree().get_nodes_in_group("zona_interactiva"):
		area.connect("area_entered", Callable(self, "_on_area_entered"))

func _process(delta: float) -> void:
	if follow:
		follow.progress += velocidad_abad * delta

func _crear_ruta_abad():
	follow = PathFollow2D.new()
	ruta.add_child(follow)

	var abad = Sprite2D.new()
	abad.texture = load("res://assets/abad.png")
	abad.scale = Vector2(0.5, 0.5)
	follow.add_child(abad)

	follow.loop = true

func _on_area_entered(area: Area2D) -> void:
	var ui := get_tree().get_root().get_node("Main/UI")
	var reloj := get_tree().get_root().get_node("Main/Reloj")

	if area.is_in_group("zona_prohibida") and reloj.es_hora_prohibida():
		ui.mostrar_aviso_prohibido(area.name)
	else:
		ui.mostrar_mensaje("Has entrado en: " + area.name)
