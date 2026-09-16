extends Control
class_name FloorPlan

signal room_selected(rx: int, ry: int)

const ROOM_COLOR = Color(0.769, 0.659, 0.510)
const EMPTY_COLOR = Color(0.102, 0.102, 0.180)
const CURRENT_COLOR = Color(1.0, 0.267, 0.267)
const BORDER_COLOR = Color(0.2, 0.2, 0.2)

var floors_data: Array = []
var current_floor: int = 0
var current_rx: int = 0
var current_ry: int = 0
var room_rects: Array = []

func setup(floors: Array, fl: int, rx: int, ry: int) -> void:
	floors_data = floors
	current_floor = fl
	current_rx = rx
	current_ry = ry
	queue_redraw()

func update_floor(fl: int) -> void:
	current_floor = fl
	queue_redraw()

func update_room(rx: int, ry: int) -> void:
	current_rx = rx
	current_ry = ry
	queue_redraw()

func _draw() -> void:
	room_rects.clear()
	if current_floor >= floors_data.size():
		return
	var room_grid = floors_data[current_floor].get("room", [])
	if room_grid.size() == 0:
		return
	var rows = room_grid.size()
	var cols = room_grid[0].size()
	var cell_w = size.x / cols
	var cell_h = size.y / rows
	for ry in range(rows):
		for rx in range(cols):
			var room_id = room_grid[ry][rx]
			var rect = Rect2(rx * cell_w, ry * cell_h, cell_w - 1, cell_h - 1)
			room_rects.append({"rect": rect, "rx": rx, "ry": ry})
			var color = ROOM_COLOR if room_id > 0 else EMPTY_COLOR
			if rx == current_rx and ry == current_ry:
				color = CURRENT_COLOR
			draw_rect(rect, color)
			draw_rect(rect, BORDER_COLOR, false, 1.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = event.position
		for room_data in room_rects:
			if room_data["rect"].has_point(click_pos):
				room_selected.emit(room_data["rx"], room_data["ry"])
				break
