extends Control
class_name FloorPlan

signal room_hovered(room_id: int)
signal room_selected(room_id: int)

const FLOOR_IMAGES = [
	"res://assets/planta0.png",
	"res://assets/planta1.png",
	"res://assets/planta2.png"
]

const OVERLAY_COLOR = Color(1.0, 0.0, 0.0, 0.45)
const BORDER_SELECTED = Color(1.0, 1.0, 1.0, 0.9)
const OFFSET = Vector2(12, 12)

# Reference floor map from visor.abadiadelcrimenextensum.com
# 16 columns x 15 rows. Floor 0 = rows 0-9, Floor 1 = rows 10-14 cols 0-7, Floor 2 = rows 10-14 cols 8-15
const REF_MAP: Array = [
	0,0,0,0,0,0,0,0,39,0,62,0,0,0,0,0,
	0,10,9,0,7,8,42,40,38,41,55,56,57,0,0,0,
	0,2,1,0,13,14,36,35,37,43,44,45,0,0,0,0,
	0,3,0,31,0,0,0,34,0,46,47,48,0,0,0,0,
	0,4,29,30,0,61,0,33,0,49,50,51,0,0,0,0,
	0,12,11,28,5,6,60,0,32,0,52,53,54,0,0,0,
	0,0,0,15,16,17,18,0,27,0,26,0,0,0,0,0,
	0,0,0,0,0,0,19,20,21,24,25,0,0,0,0,0,
	0,0,0,0,0,0,0,0,22,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,23,0,0,0,0,0,0,0,
	0,69,68,0,72,73,0,0,0,103,102,0,101,100,0,0,
	0,0,67,71,74,0,0,0,0,0,106,105,104,0,0,0,
	0,0,66,0,75,0,0,0,0,0,108,0,107,0,0,0,
	0,0,65,64,76,0,0,0,0,0,111,110,109,0,0,0,
	0,63,70,0,77,78,0,0,0,115,114,0,113,112,0,0,
]

var floor_textures: Array = []
var floors_data: Array = []
var current_floor: int = 0
var current_room_id: int = -1
var hover_room_id: int = -1

var tooltip_label: Label

func _make_tooltip_bg() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.15, 0.2, 0.92)
	sb.border_color = Color(0.5, 0.5, 0.5)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(6)
	return sb

func _ref_lookup(gx: int, gy: int) -> int:
	if gx < 0 or gx >= 16 or gy < 0 or gy >= 15:
		return -1
	var val = REF_MAP[gy * 16 + gx]
	if val == 0:
		return -1
	return val

func _room_to_grid(fl: int, room_id: int) -> Vector2i:
	for gy in range(15):
		for gx in range(16):
			var rid = _ref_lookup(gx, gy)
			if rid == room_id:
				if fl == 0 and gy <= 9:
					return Vector2i(gx, gy)
				elif fl == 1 and gy >= 10 and gx < 8:
					return Vector2i(gx, gy)
				elif fl == 2 and gy >= 10 and gx >= 8:
					return Vector2i(gx, gy)
	return Vector2i(-1, -1)

func _canvas_to_grid(canvas_pos: Vector2, fl: int) -> Vector2i:
	var gx: int
	var gy: int
	if fl == 0:
		gx = floori(canvas_pos.x / 16.0)
		gy = floori(canvas_pos.y / 16.0) - 1
	else:
		gx = floori(canvas_pos.x / 32.0)
		gy = floori(canvas_pos.y / 32.0) + 9
		if fl == 2:
			gx += 8
	return Vector2i(gx, gy)

func _grid_to_canvas(gx: int, gy: int, fl: int) -> Vector2:
	var cs = 16.0
	var cx: float = gx * cs
	var cy: float
	if fl == 0:
		cy = (gy + 1) * cs
	else:
		cy = (gy - 9) * cs
		if fl == 2:
			cx = (gx - 8) * cs
	return Vector2(cx, cy)

func _ready() -> void:
	for path in FLOOR_IMAGES:
		var img = Image.new()
		var err = img.load(path)
		if err == OK:
			var tex = ImageTexture.create_from_image(img)
			floor_textures.append(tex)
		else:
			floor_textures.append(null)
			print("FloorPlan: Error cargando ", path)

	tooltip_label = Label.new()
	tooltip_label.visible = false
	tooltip_label.add_theme_font_size_override("font_size", 13)
	tooltip_label.add_theme_color_override("font_color", Color.WHITE)
	tooltip_label.add_theme_stylebox_override("normal", _make_tooltip_bg())
	tooltip_label.z_index = 10
	add_child(tooltip_label)

func setup(fl: int, rx: int, ry: int, floors: Array) -> void:
	floors_data = floors
	current_floor = fl
	_update_size()

func update_floor(fl: int) -> void:
	current_floor = fl
	_update_size()
	hover_room_id = -1
	tooltip_label.visible = false
	queue_redraw()

func update_room_from_grid(fl: int, rx: int, ry: int) -> void:
	current_floor = fl
	if fl == 0:
		current_room_id = _ref_lookup(rx, ry)
	elif fl == 1:
		current_room_id = _ref_lookup(rx, ry)
	elif fl == 2:
		current_room_id = _ref_lookup(rx, ry)
	queue_redraw()

func update_room_by_id(room_id: int) -> void:
	current_room_id = room_id
	queue_redraw()

func _update_size() -> void:
	if current_floor < floor_textures.size() and floor_textures[current_floor]:
		var img_size = floor_textures[current_floor].get_size()
		custom_minimum_size = img_size + OFFSET * 2
		size = custom_minimum_size

func _draw() -> void:
	if current_floor >= floor_textures.size():
		return
	var tex = floor_textures[current_floor]
	if tex == null:
		return
	draw_texture(tex, OFFSET)

	if current_room_id >= 0:
		var grid_pos = _room_to_grid(current_floor, current_room_id)
		if grid_pos.x >= 0:
			var canvas_pos = _grid_to_canvas(int(grid_pos.x), int(grid_pos.y), current_floor)
			var cs = 16.0
			if current_floor != 0:
				cs = 32.0
			var rect = Rect2(canvas_pos, Vector2(cs, cs))
			draw_rect(rect, OVERLAY_COLOR)
			draw_rect(rect, BORDER_SELECTED, false, 1.5)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var gp = _canvas_to_grid(event.position, current_floor)
		var rid = _ref_lookup(gp.x, gp.y)
		if rid != hover_room_id:
			hover_room_id = rid
			if rid > 0:
				tooltip_label.text = "Habitación %d" % rid
				tooltip_label.visible = true
			else:
				tooltip_label.visible = false
			queue_redraw()
		if tooltip_label.visible:
			tooltip_label.position = event.position + Vector2(14, -10)

	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var gp = _canvas_to_grid(event.position, current_floor)
		var rid = _ref_lookup(gp.x, gp.y)
		if rid > 0:
			current_room_id = rid
			room_selected.emit(rid)
			queue_redraw()
