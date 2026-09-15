extends CanvasLayer

@onready var label_info := $Panel/LabelInfo
@onready var label_hora := $Panel/LabelHora
@onready var reloj := get_tree().get_root().get_node("Main/Reloj")

func _ready():
    label_info.text = "Mapa interactivo La Abadía del Crimen"
    _actualizar_hora()

func mostrar_mensaje(texto: String) -> void:
    label_info.text = texto

func mostrar_aviso_prohibido(zona: String) -> void:
    label_info.text = "⚠️ Zona prohibida: " + zona

func _actualizar_hora() -> void:
    label_hora.text = "Hora: " + str(reloj.hora_actual)

func _process(delta: float) -> void:
    _actualizar_hora()


