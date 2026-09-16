extends VBoxContainer

var floor_plan: FloorPlan
var room_renderer: RoomRenderer
var floor_select: OptionButton
var tileset_select: OptionButton
var map_select: OptionButton
var room_input: LineEdit
var info_label: Label
var slider: HSlider
var slider_value_label: Label
var status_label: Label
var player: CharacterBody2D
var extended_check: CheckBox
var border_check: CheckBox
var progressive_check: CheckBox
var music_check: CheckBox
var audio: AudioStreamPlayer

const FLOOR_NAMES = ["Iglesia", "Scriptorium", "Biblioteca"]

const TILESETS = [
	{"name": "Amstrad CPC", "file": "res://assets/tiles_cpc.png"},
	{"name": "Amstrad CPC noche", "file": "res://assets/tiles_cpc_noche.png"},
	{"name": "MSX", "file": "res://assets/tiles_msx.png"},
	{"name": "MSX2 Remake", "file": "res://assets/tiles_msx2.png"},
	{"name": "PC CGA", "file": "res://assets/tiles_cga.png"},
	{"name": "Remake PC", "file": "res://assets/tilesRemake.png"},
	{"name": "ZX Spectrum", "file": "res://assets/tiles_spectrum.png"}
]

const MAPS = [
	{"name": "Original CPC", "file": "res://assets/3d_cpc.map"},
	{"name": "MSX", "file": "res://assets/3d.map"},
	{"name": "Reducido (cinta CPC)", "file": "res://assets/3d_cpc_cinta.map"}
]

func _ready() -> void:
	floor_plan = $HSplit/RightPanel/FloorPlan
	room_renderer = $HSplit/LeftPanel/SubViewportContainer/SubViewport/RoomTiles
	floor_select = $HSplit/RightPanel/Controls/FloorSelect
	tileset_select = $HSplit/RightPanel/Controls/TilesetSelect
	map_select = $HSplit/RightPanel/Controls/MapSelect
	room_input = $HSplit/RightPanel/Controls/RoomInput
	info_label = $HSplit/RightPanel/Info
	slider = $BottomBar/ElementSlider/Slider
	slider_value_label = $BottomBar/ElementSlider/SliderValue
	status_label = $BottomBar/StatusBar
	player = $HSplit/LeftPanel/SubViewportContainer/SubViewport/Player
	extended_check = $HSplit/RightPanel/Controls/ExtendedCheck
	border_check = $HSplit/RightPanel/Controls/BorderCheck
	progressive_check = $HSplit/RightPanel/Controls/ProgressiveCheck
	music_check = $HSplit/RightPanel/Controls/MusicCheck
	audio = $Audio

	floor_select.clear()
	for name in FLOOR_NAMES:
		floor_select.add_item(name)
	floor_select.selected = 0

	tileset_select.clear()
	for ts in TILESETS:
		tileset_select.add_item(ts["name"])
	tileset_select.selected = 0

	map_select.clear()
	for m in MAPS:
		map_select.add_item(m["name"])
	map_select.selected = 0

	floor_plan.setup(0, 8, 1, room_renderer.floors_data)
	floor_plan.room_selected.connect(_on_room_selected)
	floor_select.item_selected.connect(_on_floor_selected)
	tileset_select.item_selected.connect(_on_tileset_selected)
	map_select.item_selected.connect(_on_map_selected)
	room_input.text_submitted.connect(_on_room_submitted)
	slider.value_changed.connect(_on_slider_changed)
	music_check.toggled.connect(_on_music_toggled)

	_update_ui()

func _on_room_selected(room_id: int) -> void:
	var fl = floor_select.selected
	var pos = _find_room_grid_pos(fl, room_id)
	if pos.x >= 0:
		room_renderer.build_room(fl, pos.x, pos.y)
		floor_plan.update_room_by_id(room_id)
		_position_player()
		_update_ui()

func _on_floor_selected(index: int) -> void:
	floor_plan.update_floor(index)
	_update_ui()

func _on_tileset_selected(index: int) -> void:
	pass

func _on_map_selected(index: int) -> void:
	pass

func _on_room_submitted(text: String) -> void:
	var room_num = text.to_int()
	if room_num < 0 or room_num > 115:
		return
	var fl = floor_select.selected
	var pos = _find_room_grid_pos(fl, room_num)
	if pos.x >= 0:
		room_renderer.build_room(fl, pos.x, pos.y)
		floor_plan.update_room_by_id(room_num)
		_position_player()
		_update_ui()

func _on_slider_changed(value: float) -> void:
	var fl = floor_select.selected
	room_renderer.build_room_partial(fl, room_renderer.current_room_x, room_renderer.current_room_y, int(value))
	slider_value_label.text = "%d/%d" % [int(value), room_renderer.get_block_count()]

func _on_music_toggled(pressed: bool) -> void:
	if pressed:
		audio.play()
	else:
		audio.stop()

func _position_player() -> void:
	player.position = Vector2(8 * 16, 8 * 8)

func _find_room_grid_pos(fl: int, room_id: int) -> Vector2i:
	if fl < 0 or fl >= room_renderer.floors_data.size():
		return Vector2i(-1, -1)
	var room_grid = room_renderer.floors_data[fl].get("room", [])
	for ry in range(room_grid.size()):
		for rx in range(room_grid[ry].size()):
			if room_grid[ry][rx] == room_id:
				return Vector2i(rx, ry)
	return Vector2i(-1, -1)

func _update_ui() -> void:
	var fl = floor_select.selected
	var rx = room_renderer.current_room_x
	var ry = room_renderer.current_room_y
	var room_grid = room_renderer.floors_data[fl].get("room", [])
	var room_id = 0
	if ry >= 0 and ry < room_grid.size() and rx >= 0 and rx < room_grid[ry].size():
		room_id = room_grid[ry][rx]
	var block_count = room_renderer.get_block_count()
	slider.max_value = block_count
	slider.value = block_count
	slider_value_label.text = "%d/%d" % [block_count, block_count]
	var text = "Habitación: %d — Elementos: %d — %s" % [room_id, block_count, FLOOR_NAMES[fl]]
	info_label.text = text
	status_label.text = text
