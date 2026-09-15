extends CanvasLayer

@onready var label_info := $Panel/LabelInfo
@onready var label_hora := $Panel/LabelHora

func _ready() -> void:
	label_info.text = "Mapa interactivo La Abadía del Crimen"
	Horario.hora_cambiada.connect(_on_hora_cambiada)
	Horario.momento_cambiado.connect(_on_momento_cambiado)
	_actualizar_hora()

func mostrar_mensaje(texto: String) -> void:
	label_info.text = texto

func mostrar_aviso_prohibido(zona: String) -> void:
	label_info.text = "Zona prohibida: " + zona

func _on_hora_cambiada(hora: int, nombre: String) -> void:
	_actualizar_hora()

func _on_momento_cambiado(momento: String) -> void:
	label_info.text = "Momento canónico: " + momento

func _actualizar_hora() -> void:
	var hora_display = Horario.get_hora_display()
	var momento = Horario.get_momento_nombre()
	var dia = Horario.get_dia()
	label_hora.text = "Día %d | %s | %s" % [dia, hora_display, momento]

func _process(_delta: float) -> void:
	_actualizar_hora()
