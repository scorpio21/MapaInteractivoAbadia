extends HSplitContainer

var floor_plan: FloorPlan
var room_renderer: RoomRenderer
var floor_select: OptionButton
var room_input: LineEdit
var go_button: Button
var info_label: Label
var slider: HSlider
var slider_value_label: Label
var status_label: Label
var player: CharacterBody2D

const FLOOR_NAMES = ["Iglesia", "Scriptorium", "Biblioteca"]

func _ready() -> void:
	floor_plan = $RightPanel/FloorPlan
	room_renderer = $LeftPanel/SubViewportContainer/SubViewport/RoomTiles
	floor_select = $RightPanel/Controls/FloorSelect
	room_input = $RightPanel/Controls/RoomInput
	go_button = $RightPanel/Controls/GoButton
	info_label = $RightPanel/Info
	slider = $BottomBar/ElementSlider/Slider
	slider_value_label = $BottomBar/ElementSlider/SliderValue
	status_label = $BottomBar/StatusBar
	player = $LeftPanel/SubViewportContainer/SubViewport/Player

	floor_plan.setup(room_renderer.floors_data, 0, 8, 1)
	floor_plan.room_selected.connect(_on_room_selected)
	floor_select.item_selected.connect(_on_floor_selected)
	go_button.pressed.connect(_on_go_pressed)
	slider.value_changed.connect(_on_slider_changed)

	_update_ui()

func _on_room_selected(rx: int, ry: int) -> void:
	var fl = floor_select.selected
	room_renderer.build_room(fl, rx, ry)
	floor_plan.update_room(rx, ry)
	_position_player()
	_update_ui()

func _on_floor_selected(index: int) -> void:
	floor_plan.update_floor(index)
	_update_ui()

func _on_go_pressed() -> void:
	var room_num = room_input.text.to_int()
	if room_num < 0 or room_num > 115:
		return
	var fl = floor_select.selected
	var room_grid = room_renderer.floors_data[fl].get("room", [])
	for ry in range(room_grid.size()):
		for rx in range(room_grid[ry].size()):
			if room_grid[ry][rx] == room_num:
				room_renderer.build_room(fl, rx, ry)
				floor_plan.update_room(rx, ry)
				_position_player()
				_update_ui()
				return

func _on_slider_changed(value: float) -> void:
	var fl = floor_select.selected
	room_renderer.build_room_partial(fl, room_renderer.current_room_x, room_renderer.current_room_y, int(value))
	slider_value_label.text = "%d/%d" % [int(value), room_renderer.get_block_count()]

func _position_player() -> void:
	player.position = Vector2(8 * 16, 8 * 8)

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