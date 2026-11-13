class_name MapaAbadia
extends Control

# Visor de minimapas. Selección por AbadiaMapData.dll con respaldo local.
# No contiene las herramientas temporales de calibración ni dibuja marcadores.
signal room_selected(room_number: int, floor: int)
signal floor_changed(floor: int)
signal tileset_changed(tileset_index: int)
signal map_changed(map_index: int)
signal music_changed(enabled: bool)

const FLOOR_NAMES: Array[String] = ["Iglesia", "Scriptorium", "Biblioteca"]
const FLOOR_IMAGES: Array[String] = [
	"res://assets/planta0.png",
	"res://assets/planta1.png",
    "res://assets/planta2.png"
]
const FLOOR_IMAGE_SIZES: Array[Vector2] = [
	Vector2(198, 166), Vector2(180, 180), Vector2(180, 180)
]
const CELL_SIZES: Array[int] = [16, 32, 32]
const TILESET_NAMES: Array[String] = [
	"Original CPC", "Amstrad CPC noche", "MSX", "MSX2 Remake",
	"PC CGA", "Remake PC", "ZX Spectrum"
]
const MAP_NAMES: Array[String] = [
	"Original CPC", "MSX", "Reducido (cinta CPC)"
]

# Se conserva la numeración conocida para navegación y determinar la planta.
var room_positions: Array[Dictionary] = [
	# Iglesia
	{
		0: Vector2(58, 44),
		1: Vector2(46, 43),
		2: Vector2(28, 43),
		3: Vector2(28, 60),
		4: Vector2(20, 68),
		5: Vector2(52, 84),
		6: Vector2(68, 84),
		7: Vector2(52, 20),
		8: Vector2(68, 20),
		9: Vector2(29, 28),
		10: Vector2(14, 25),
		11: Vector2(28, 90),
		12: Vector2(12, 90),
		13: Vector2(68, 36),
		14: Vector2(84, 36),
		15: Vector2(44, 108),
		16: Vector2(52, 100),
		17: Vector2(60, 108),
		18: Vector2(92, 108),
		19: Vector2(76, 108),
		20: Vector2(92, 124),
		21: Vector2(124, 124),
		22: Vector2(124, 140),
		23: Vector2(124, 156),
		24: Vector2(140, 124),
		25: Vector2(156, 124),
		26: Vector2(156, 108),
		27: Vector2(124, 108),
		28: Vector2(43, 89),
		29: Vector2(36, 68),
		30: Vector2(52, 68),
		31: Vector2(52, 52),
		32: Vector2(124, 92),
		33: Vector2(124, 76),
		34: Vector2(124, 44),
		35: Vector2(116, 36),
		36: Vector2(100, 36),
		37: Vector2(135, 27),
		38: Vector2(124, 28),
		39: Vector2(124, 12),
		40: Vector2(100, 20),
		41: Vector2(132, 20),
		42: Vector2(84, 20),
		43: Vector2(148, 36),
		44: Vector2(172, 44),
		45: Vector2(188, 43),
		46: Vector2(156, 60),
		47: Vector2(172, 60),
		48: Vector2(188, 60),
		49: Vector2(156, 76),
		50: Vector2(164, 68),
		51: Vector2(180, 68),
		52: Vector2(156, 92),
		53: Vector2(164, 84),
		54: Vector2(172, 76),
		55: Vector2(152, 29),
		56: Vector2(176, 26),
		57: Vector2(188, 26),
		60: Vector2(84, 84),
		61: Vector2(84, 68),
		62: Vector2(156, 12)
	},

	# Scriptorium
	{
		63: Vector2(19, 148),
		64: Vector2(83, 116),
		65: Vector2(51, 116),
		66: Vector2(51, 84),
		67: Vector2(51, 52),
		68: Vector2(51, 20),
		69: Vector2(19, 20),
		70: Vector2(51, 148),
		71: Vector2(83, 52),
		72: Vector2(115, 20),
		73: Vector2(147, 20),
		74: Vector2(115, 52),
		75: Vector2(115, 84),
		76: Vector2(115, 116),
		77: Vector2(115, 148),
		78: Vector2(147, 148)
	},

	# Biblioteca
	{
		100: Vector2(147, 20),
		101: Vector2(115, 20),
		102: Vector2(51, 20),
		103: Vector2(19, 20),
		104: Vector2(115, 52),
		105: Vector2(83, 52),
		106: Vector2(51, 52),
		107: Vector2(115, 84),
		108: Vector2(51, 84),
		109: Vector2(115, 116),
		110: Vector2(83, 116),
		111: Vector2(51, 116),
		112: Vector2(147, 148),
		113: Vector2(115, 148),
		114: Vector2(51, 148),
		115: Vector2(19, 148)
	}
]

# Respaldo local si falla el puente a la DLL.
var grid_reference_rooms: Array[Dictionary] = [
	{
		0: Vector2(52,36),
		1: Vector2(36,36),
		2: Vector2(20,36),
		3: Vector2(20,52),
		4: Vector2(20,68),
		5: Vector2(52,84),
		6: Vector2(68,84),
		7: Vector2(52,20),
		8: Vector2(68,20),
		9: Vector2(20,20),
		10: Vector2(4,20),
		11: Vector2(20,84),
		12: Vector2(4,84),
		13: Vector2(68,36),
		14: Vector2(84,36),
		15: Vector2(36,100),
		16: Vector2(52,100),
		17: Vector2(68,100),
		18: Vector2(84,100),
		19: Vector2(84,116),
		20: Vector2(100,116),
		21: Vector2(116,116),
		22: Vector2(116,132),
		23: Vector2(116,148),
		24: Vector2(132,116),
		25: Vector2(148,116),
		26: Vector2(148,100),
		27: Vector2(116,100),
		28: Vector2(36,84),
		29: Vector2(36,68),
		30: Vector2(52,68),
		31: Vector2(52,52),
		32: Vector2(116,84),
		33: Vector2(116,68),
		34: Vector2(116,52),
		35: Vector2(116,36),
		36: Vector2(100,36),
		37: Vector2(132,36),
		38: Vector2(116,20),
		39: Vector2(116,4),
		40: Vector2(100,20),
		41: Vector2(132,20),
		42: Vector2(84,20),
		43: Vector2(148,36),
		44: Vector2(164,36),
		45: Vector2(180,36),
		46: Vector2(148,52),
		47: Vector2(164,52),
		48: Vector2(180,52),
		49: Vector2(148,68),
		50: Vector2(164,68),
		51: Vector2(180,68),
		52: Vector2(148,84),
		53: Vector2(164,84),
		54: Vector2(180,84),
		55: Vector2(148,20),
		56: Vector2(164,20),
		57: Vector2(180,20),
		60: Vector2(84,84),
		61: Vector2(84,68),
		62: Vector2(148,4)
	},
	{
		63: Vector2(19,148),
		64: Vector2(83,116),
		65: Vector2(51,116),
		66: Vector2(51,84),
		67: Vector2(51,52),
		68: Vector2(51,20),
		69: Vector2(19,20),
		70: Vector2(51,148),
		71: Vector2(83,52),
		72: Vector2(115,20),
		73: Vector2(147,20),
		74: Vector2(115,52),
		75: Vector2(115,84),
		76: Vector2(115,116),
		77: Vector2(115,148),
		78: Vector2(147,148)
	},
	{
		100: Vector2(147,20),
		101: Vector2(115,20),
		102: Vector2(51,20),
		103: Vector2(19,20),
		104: Vector2(115,52),
		105: Vector2(83,52),
		106: Vector2(51,52),
		107: Vector2(115,84),
		108: Vector2(51,84),
		109: Vector2(115,116),
		110: Vector2(83,116),
		111: Vector2(51,116),
		112: Vector2(147,148),
		113: Vector2(115,148),
		114: Vector2(51,148),
		115: Vector2(19,148)
	}
]

var current_floor: int = 0
var current_room: int = 51
var dll_bridge: Node = null

var panel: Panel
var title_label: Label
var floor_selector: OptionButton
var tileset_selector: OptionButton
var map_selector: OptionButton
var map_texture: TextureRect
var room_input: LineEdit
var extended_toggle: CheckBox
var border_toggle: CheckBox
var progressive_toggle: CheckBox
var music_toggle: CheckBox
var controls_panel: Panel
var control_labels: Array[Label] = []
var room_label: Label
var hover_room_label: Label
var hover_room_number: int = -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_initialize_dll_bridge()
	set_floor(0)
	select_room(current_room)

func _initialize_dll_bridge() -> void:
	var bridge_script: Script = load("res://scripts/RoomDataBridge.cs") as Script
	if bridge_script == null:
		push_warning("No se pudo cargar RoomDataBridge.cs; se usarán referencias locales.")
		return
	var candidate := Node.new()
	candidate.name = "RoomDataBridge"
	candidate.set_script(bridge_script)
	add_child(candidate)
	if not candidate.has_method("IsReady") or not bool(candidate.call("IsReady")):
		push_warning("DLL no disponible; se usarán referencias locales.")
		candidate.queue_free()
		return
	dll_bridge = candidate

func _get_room_at_pixel(floor_index: int, pixel: Vector2) -> int:
	if is_instance_valid(dll_bridge):
		return int(dll_bridge.call("GetRoomAtPosition", floor_index, pixel.x, pixel.y))
	return _find_room_by_reference_cell(floor_index, pixel)

func _find_room_by_reference_cell(floor_index: int, pixel: Vector2) -> int:
	if floor_index < 0 or floor_index >= grid_reference_rooms.size():
		return -1
	var side: float = float(CELL_SIZES[floor_index])
	var half := Vector2.ONE * (side * 0.5)
	for key in grid_reference_rooms[floor_index].keys():
		var reference: Vector2 = grid_reference_rooms[floor_index][key]
		if Rect2(reference - half, Vector2.ONE * side).has_point(pixel):
			return int(key)
	return -1

func _build_ui() -> void:
	panel = Panel.new()
	panel.name = "PanelMapa"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#171b3f")
	panel_style.border_color = Color("#2d376b")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)

	title_label = Label.new()
	title_label.text = "Mapa"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title_label)

	floor_selector = OptionButton.new()
	floor_selector.name = "Planta"
	for i in range(FLOOR_NAMES.size()):
		floor_selector.add_item(FLOOR_NAMES[i], i)
	floor_selector.item_selected.connect(_on_floor_selected)
	panel.add_child(floor_selector)

	map_texture = TextureRect.new()
	map_texture.name = "Mapa"
	map_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_texture.mouse_filter = Control.MOUSE_FILTER_STOP
	map_texture.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	map_texture.gui_input.connect(_on_map_gui_input)
	map_texture.mouse_exited.connect(_on_map_mouse_exited)
	panel.add_child(map_texture)

	controls_panel = Panel.new()
	controls_panel.name = "Controles"
	var controls_style := StyleBoxFlat.new()
	controls_style.bg_color = Color("#182044")
	controls_style.border_color = Color("#293568")
	controls_style.set_border_width_all(1)
	controls_style.set_corner_radius_all(6)
	controls_panel.add_theme_stylebox_override("panel", controls_style)
	panel.add_child(controls_panel)
	panel.remove_child(floor_selector)
	controls_panel.add_child(floor_selector)

	var control_label_color := Color("#9aaddc")
	var control_input_style := StyleBoxFlat.new()
	control_input_style.bg_color = Color("#171b46")
	control_input_style.border_color = Color("#293568")
	control_input_style.set_border_width_all(1)
	control_input_style.set_corner_radius_all(4)

	var control_focus_style := control_input_style.duplicate()
	control_focus_style.border_color = Color("#e1bb20")
	control_focus_style.set_border_width_all(1)

	for text in ["Planta", "Gráficos", "Mapa", "Habitación"]:
		var label := Label.new()
		label.text = text
		label.add_theme_color_override("font_color", control_label_color)
		controls_panel.add_child(label)
		control_labels.append(label)

	for input in [floor_selector]:
		input.add_theme_stylebox_override("normal", control_input_style)
		input.add_theme_stylebox_override("hover", control_focus_style)
		input.add_theme_stylebox_override("focus", control_focus_style)

	tileset_selector = OptionButton.new()
	tileset_selector.name = "Graficos"
	for name in TILESET_NAMES:
		tileset_selector.add_item(name)
	tileset_selector.item_selected.connect(_on_tileset_selected)
	tileset_selector.add_theme_stylebox_override("normal", control_input_style)
	tileset_selector.add_theme_stylebox_override("hover", control_focus_style)
	tileset_selector.add_theme_stylebox_override("focus", control_focus_style)
	controls_panel.add_child(tileset_selector)

	map_selector = OptionButton.new()
	map_selector.name = "MapaSelector"
	for name in MAP_NAMES:
		map_selector.add_item(name)
	map_selector.item_selected.connect(_on_map_selected)
	map_selector.add_theme_stylebox_override("normal", control_input_style)
	map_selector.add_theme_stylebox_override("hover", control_focus_style)
	map_selector.add_theme_stylebox_override("focus", control_focus_style)
	controls_panel.add_child(map_selector)

	room_input = LineEdit.new()
	room_input.name = "HabitacionInput"
	room_input.alignment = HORIZONTAL_ALIGNMENT_LEFT
	room_input.add_theme_stylebox_override("normal", control_input_style)
	room_input.add_theme_stylebox_override("focus", control_focus_style)
	room_input.text_submitted.connect(_on_room_submitted)
	controls_panel.add_child(room_input)

	var toggles: Array[Dictionary] = [
		{"text": "Área extendida", "name": "AreaExtendida"},
		{"text": "Mostrar borde", "name": "MostrarBorde"},
		{"text": "Pintado progresivo", "name": "PintadoProgresivo"},
		{"text": "Música", "name": "Musica"},
	]
	var toggle_nodes: Array[CheckBox] = []
	for item in toggles:
		var check := CheckBox.new()
		check.name = item.name
		check.text = item.text
		check.alignment = HORIZONTAL_ALIGNMENT_LEFT
		check.add_theme_color_override("font_color", control_label_color)
		controls_panel.add_child(check)
		toggle_nodes.append(check)
	extended_toggle = toggle_nodes[0]
	border_toggle = toggle_nodes[1]
	progressive_toggle = toggle_nodes[2]
	music_toggle = toggle_nodes[3]
	border_toggle.button_pressed = true
	music_toggle.toggled.connect(_on_music_toggled)

	room_label = Label.new()
	room_label.name = "Habitacion"
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(room_label)

	hover_room_label = Label.new()
	hover_room_label.name = "HabitacionHover"
	hover_room_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_room_label.visible = false
	hover_room_label.z_index = 100
	hover_room_label.add_theme_color_override("font_color", Color.WHITE)
	hover_room_label.add_theme_font_size_override("font_size", 12)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.20, 0.35, 0.82)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	hover_room_label.add_theme_stylebox_override("normal", style)
	panel.add_child(hover_room_label)

func set_layout_size(new_size: Vector2) -> void:
	size = new_size
	custom_minimum_size = new_size
	if panel == null:
		return
	panel.position = Vector2.ZERO
	panel.size = new_size
	_layout_controls()

func _layout_controls() -> void:
	if panel == null:
		return
	var width: float = panel.size.x
	var height: float = panel.size.y
	title_label.position = Vector2(8, 8)
	title_label.size = Vector2(width - 16, 32)
	var map_top: float = 45.0
	var controls_height: float = 278.0
	var status_height: float = 26.0
	var map_height: float = maxf(150.0, height - map_top - controls_height - status_height - 24.0)
	map_texture.position = Vector2(10, map_top)
	map_texture.size = Vector2(width - 20, map_height)

	controls_panel.position = Vector2(10, map_top + map_height + 8)
	controls_panel.size = Vector2(width - 20, controls_height)

	var controls_width: float = controls_panel.size.x
	var label_width := 92.0
	var input_x := label_width + 10.0
	var input_width := maxf(80.0, controls_width - input_x - 10.0)
	var row_height := 32.0
	var y := 8.0
	var inputs: Array[Control] = [floor_selector, tileset_selector, map_selector, room_input]
	for i in range(inputs.size()):
		var label := control_labels[i]
		label.position = Vector2(10, y + 5)
		label.size = Vector2(label_width, 22)
		inputs[i].position = Vector2(input_x, y)
		inputs[i].size = Vector2(input_width, 28)
		y += row_height

	var checkboxes: Array[CheckBox] = [
		extended_toggle, border_toggle, progressive_toggle, music_toggle
	]
	for checkbox in checkboxes:
		checkbox.position = Vector2(10, y)
		checkbox.size = Vector2(controls_width - 20, 28)
		y += 29.0

	room_label.position = Vector2(10, controls_panel.position.y + controls_height + 2)
	room_label.size = Vector2(width - 20, status_height)

func _on_floor_selected(index: int) -> void:
	set_floor(index)

func _on_tileset_selected(index: int) -> void:
	tileset_changed.emit(index)

func _on_map_selected(index: int) -> void:
	map_changed.emit(index)

func _on_music_toggled(enabled: bool) -> void:
	music_changed.emit(enabled)

func set_tileset(index: int) -> void:
	if tileset_selector != null:
		tileset_selector.select(clampi(index, 0, TILESET_NAMES.size() - 1))

func set_map(index: int) -> void:
	if map_selector != null:
		map_selector.select(clampi(index, 0, MAP_NAMES.size() - 1))

func set_floor(floor_index: int) -> void:
	current_floor = clampi(floor_index, 0, FLOOR_NAMES.size() - 1)
	if floor_selector != null:
		floor_selector.select(current_floor)
	if map_texture != null:
		map_texture.texture = load(FLOOR_IMAGES[current_floor]) as Texture2D
	if hover_room_label != null:
		hover_room_label.visible = false
	floor_changed.emit(current_floor)

func select_room(room_number: int) -> void:
	current_room = room_number
	var room_floor: int = _get_floor_for_room(room_number)
	if room_floor >= 0:
		current_floor = room_floor
		if floor_selector != null:
			floor_selector.select(current_floor)
		if map_texture != null:
			map_texture.texture = load(FLOOR_IMAGES[current_floor]) as Texture2D
	if room_label != null:
		room_label.text = "Habitación %d" % current_room
	if room_input != null and not room_input.has_focus():
		room_input.text = str(current_room)
	room_selected.emit(current_room, current_floor)

func _on_room_submitted(value: String) -> void:
	if not value.is_valid_int():
		room_input.text = str(current_room)
		return
	var room_number := int(value)
	if _get_floor_for_room(room_number) < 0:
		room_input.text = str(current_room)
		return
	select_room(room_number)

func next_room() -> void:
	var rooms: Array[int] = get_floor_rooms(current_floor)
	if rooms.is_empty():
		return
	var index: int = rooms.find(current_room)
	select_room(rooms[0] if index < 0 else rooms[(index + 1) % rooms.size()])

func previous_room() -> void:
	var rooms: Array[int] = get_floor_rooms(current_floor)
	if rooms.is_empty():
		return
	var index: int = rooms.find(current_room)
	select_room(rooms[0] if index < 0 else rooms[(index - 1 + rooms.size()) % rooms.size()])

func get_floor_rooms(floor_index: int) -> Array[int]:
	var result: Array[int] = []
	if floor_index < 0 or floor_index >= room_positions.size():
		return result
	for key in room_positions[floor_index].keys():
		result.append(int(key))
	result.sort()
	return result

func _get_floor_for_room(room_number: int) -> int:
	for i in range(room_positions.size()):
		if room_positions[i].has(room_number):
			return i
	return -1

func logical_room_to_data_block(room_number: int) -> int:
	# Mantener la asociación actual hasta validar la tabla de bloques físicos.
	return room_number

func _map_local_to_normalized(local_pos: Vector2) -> Vector2:
	if map_texture == null or map_texture.texture == null:
		return Vector2(-1, -1)
	var texture_size: Vector2 = map_texture.texture.get_size()
	var control_size: Vector2 = map_texture.size
	if texture_size.x <= 0 or texture_size.y <= 0 or control_size.x <= 0 or control_size.y <= 0:
		return Vector2(-1, -1)
	var image_scale: float = minf(control_size.x / texture_size.x, control_size.y / texture_size.y)
	var drawn_size: Vector2 = texture_size * image_scale
	var offset: Vector2 = (control_size - drawn_size) * 0.5
	var image_pos: Vector2 = local_pos - offset
	if image_pos.x < 0.0 or image_pos.y < 0.0 or image_pos.x >= drawn_size.x or image_pos.y >= drawn_size.y:
		return Vector2(-1, -1)
	return image_pos / drawn_size

func _on_map_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var click := event as InputEventMouseButton
	if not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var normalized: Vector2 = _map_local_to_normalized(click.position)
	if normalized.x < 0.0:
		return
	var pixel: Vector2 = normalized * FLOOR_IMAGE_SIZES[current_floor]
	var detected: int = _get_room_at_pixel(current_floor, pixel)
	if detected >= 0:
		select_room(detected)

func _process(_delta: float) -> void:
	if map_texture == null or hover_room_label == null or map_texture.texture == null:
		return
	var local_pos: Vector2 = map_texture.get_local_mouse_position()
	var normalized: Vector2 = _map_local_to_normalized(local_pos)
	if normalized.x < 0.0:
		hover_room_label.visible = false
		return
	var pixel: Vector2 = normalized * FLOOR_IMAGE_SIZES[current_floor]
	var room_number: int = _get_room_at_pixel(current_floor, pixel)
	if room_number < 0:
		hover_room_label.visible = false
		return
	hover_room_number = room_number
	hover_room_label.text = "Habitación %d" % room_number
	hover_room_label.reset_size()
	var mouse_pos: Vector2 = get_local_mouse_position()
	var tooltip_pos := mouse_pos + Vector2(15, -8)
	if tooltip_pos.x + hover_room_label.size.x > panel.size.x:
		tooltip_pos.x = mouse_pos.x - hover_room_label.size.x - 10
	tooltip_pos.x = clampf(tooltip_pos.x, 0.0, maxf(0.0, panel.size.x - hover_room_label.size.x))
	tooltip_pos.y = clampf(tooltip_pos.y, 0.0, maxf(0.0, panel.size.y - hover_room_label.size.y - 4.0))
	hover_room_label.position = tooltip_pos
	hover_room_label.visible = true

func _on_map_mouse_exited() -> void:
	if hover_room_label != null:
		hover_room_label.visible = false
	hover_room_number = -1
