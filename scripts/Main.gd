extends Control

func _ready():
	var container = $SubViewportContainer
	container.size = size
	container.anchors_preset = PRESET_FULL_RECT
	get_tree().root.size_changed.connect(_on_resize)

func _on_resize():
	var container = $SubViewportContainer
	container.size = size
