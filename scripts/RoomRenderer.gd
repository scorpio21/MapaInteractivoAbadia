extends Node2D
class_name RoomRenderer

const TILE_W: int = 16
const TILE_H: int = 8
const BUFFER_W: int = 16
const BUFFER_H: int = 20

var tile_atlas: Texture2D
var tile_frames: Dictionary = {}
var interpreter
var floors_data: Array = []
var rooms_data: Array = []
var current_floor: int = 0
var current_room_x: int = -1
var current_room_y: int = -1
var current_sprites: Array = []
var room_cache: Dictionary = {}
var current_height_data: Array = []
var current_blocks: Array = []

func _init() -> void:
	pass

func _ready() -> void:
	var ScriptInterpreterGD = preload("res://scripts/ScriptInterpreter.gd")
	interpreter = ScriptInterpreterGD.new()

	var floors_file = FileAccess.open("res://data/floors.json", FileAccess.READ)
	if floors_file:
		var json = JSON.new()
		var err = json.parse(floors_file.get_as_text())
		if err == OK:
			floors_data = json.data
		floors_file.close()

	var rooms_file = FileAccess.open("res://data/rooms.json", FileAccess.READ)
	if rooms_file:
		var json = JSON.new()
		var err = json.parse(rooms_file.get_as_text())
		if err == OK:
			rooms_data = json.data
		rooms_file.close()

	var scripts_file = FileAccess.open("res://data/scripts.abs", FileAccess.READ)
	if scripts_file:
		var text = scripts_file.get_as_text()
		scripts_file.close()
		interpreter.parse_scripts(text)

	_load_tileset()

	var bg_color = Color(0.0, 0.502, 0.502)
	RenderingServer.set_default_clear_color(bg_color)

	var initial_room = _find_initial_room()
	if initial_room:
		build_room(current_floor, initial_room[0], initial_room[1])

	_position_player_at_room_center()

	await get_tree().process_frame
	_update_scale()

func _update_scale() -> void:
	var vp = get_viewport()
	if vp == null:
		return
	var vp_size = vp.get_visible_rect().size
	var base_size = Vector2(BUFFER_W * TILE_W, BUFFER_H * TILE_H)
	var sx = vp_size.x / base_size.x
	var sy = vp_size.y / base_size.y
	var s = min(sx, sy)
	var offset_x = (vp_size.x - base_size.x * s) / 2.0
	var offset_y = (vp_size.y - base_size.y * s) / 2.0
	vp.canvas_transform = Transform2D(Vector2(s, 0), Vector2(0, s), Vector2(offset_x, offset_y))

func _find_initial_room() -> Array:
	if current_floor >= floors_data.size():
		return []
	var room_grid = floors_data[current_floor].get("room", [])
	for ry in range(room_grid.size()):
		var row = room_grid[ry]
		for rx in range(row.size()):
			if row[rx] > 0:
				return [rx, ry]
	return []

func _position_player_at_room_center() -> void:
	await get_tree().process_frame
	var jugadores = get_tree().get_nodes_in_group("jugador")
	for j in jugadores:
		j.position = Vector2(8 * TILE_W, 8 * TILE_H)

func setup(interp, floors: Array, rooms: Array) -> void:
	interpreter = interp
	floors_data = floors
	rooms_data = rooms
	_load_tileset()

func _load_tileset() -> void:
	tile_atlas = load("res://assets/tiles_day.png")
	if tile_atlas == null:
		print("ERROR: No se pudo cargar tiles_day.png")
		return
	var tile_file = FileAccess.open("res://data/tiles.json", FileAccess.READ)
	if tile_file:
		var json = JSON.new()
		var err = json.parse(tile_file.get_as_text())
		if err == OK:
			var data = json.data
			for key in data.get("frames", {}).keys():
				var frame_data = data["frames"][key]["frame"]
				var tile_id = int(key.replace("tile", ""))
				tile_frames[tile_id] = Rect2(frame_data["x"], frame_data["y"], frame_data["w"], frame_data["h"])
		tile_file.close()
		print("RoomRenderer: ", tile_frames.size(), " tiles cargados")

func build_room(fl: int, rx: int, ry: int) -> void:
	if fl == current_floor and rx == current_room_x and ry == current_room_y:
		return
	current_floor = fl
	current_room_x = rx
	current_room_y = ry
	_clear_sprites()

	if fl >= floors_data.size():
		return
	var room_grid = floors_data[fl].get("room", [])
	if ry >= room_grid.size() or rx >= room_grid[ry].size():
		return
	var room_id = room_grid[ry][rx]
	if room_id < 1 or room_id > rooms_data.size():
		return

	current_blocks = rooms_data[room_id - 1].get("blocks", [])
	var buffer = _get_room_buffer(room_id)
	_render_buffer(buffer)
	current_height_data = rooms_data[room_id - 1].get("heightData", [])
	print("Room %d at (%d,%d): rendered (%d blocks)" % [room_id, rx, ry, current_blocks.size()])

func _get_room_buffer(room_id: int) -> Array:
	if room_cache.has(room_id):
		return room_cache[room_id]
	var room = rooms_data[room_id - 1]
	var blocks = room.get("blocks", [])
	interpreter.clear_tile_buffer()
	for block in blocks:
		interpreter.execute_block(block)
	var raw = interpreter.get_tile_buffer()
	var copy = []
	for x in range(BUFFER_W):
		var col = []
		for y in range(BUFFER_H):
			col.append(raw[x][y].duplicate())
		copy.append(col)
	room_cache[room_id] = copy
	return copy

func _render_buffer(buffer: Array) -> void:
	for x in range(BUFFER_W):
		for y in range(BUFFER_H):
			for tile_data in buffer[x][y]:
				_add_sprite(x, y, tile_data)

func _add_sprite(x: int, y: int, tile_data: Dictionary) -> void:
	var tile_id = tile_data["tile"]
	if not tile_frames.has(tile_id):
		return
	var atlas = AtlasTexture.new()
	atlas.atlas = tile_atlas
	atlas.region = tile_frames[tile_id]
	var sprite = Sprite2D.new()
	sprite.texture = atlas
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(x * TILE_W, y * TILE_H)
	sprite.z_index = tile_data["depthX"] + tile_data["depthY"] - 16
	add_child(sprite)
	current_sprites.append(sprite)

func _render_blocks(max_elements: int) -> void:
	_clear_sprites()
	if current_blocks.size() == 0:
		return
	var room_id = rooms_data.size() + 1
	var room_grid = floors_data[current_floor].get("room", [])
	if current_room_y < room_grid.size() and current_room_x < room_grid[current_room_y].size():
		room_id = room_grid[current_room_y][current_room_x]
	if room_id < 1 or room_id > rooms_data.size():
		return

	var limited_blocks = current_blocks.slice(0, mini(max_elements, current_blocks.size()))
	interpreter.clear_tile_buffer()
	for block in limited_blocks:
		interpreter.execute_block(block)
	var raw = interpreter.get_tile_buffer()

	for x in range(BUFFER_W):
		for y in range(BUFFER_H):
			for tile_data in raw[x][y]:
				_add_sprite(x, y, tile_data)

func build_room_partial(fl: int, rx: int, ry: int, max_elements: int) -> void:
	current_floor = fl
	current_room_x = rx
	current_room_y = ry

	if fl >= floors_data.size():
		return
	var room_grid = floors_data[fl].get("room", [])
	if ry >= room_grid.size() or rx >= room_grid[ry].size():
		return
	var room_id = room_grid[ry][rx]
	if room_id < 1 or room_id > rooms_data.size():
		return

	current_blocks = rooms_data[room_id - 1].get("blocks", [])
	_render_blocks(max_elements)
	current_height_data = rooms_data[room_id - 1].get("heightData", [])
	print("Room %d at (%d,%d): partial render %d/%d blocks" % [room_id, rx, ry, mini(max_elements, current_blocks.size()), current_blocks.size()])

func get_block_count() -> int:
	return current_blocks.size()

func _clear_sprites() -> void:
	for s in current_sprites:
		if is_instance_valid(s):
			s.queue_free()
	current_sprites.clear()

func get_room_at(fl: int, rx: int, ry: int) -> int:
	if fl < 0 or fl >= floors_data.size():
		return 0
	var room_grid = floors_data[fl].get("room", [])
	if ry < 0 or ry >= room_grid.size() or rx < 0 or rx >= room_grid[ry].size():
		return 0
	return room_grid[ry][rx]

func is_walkable(tile_x: int, tile_y: int) -> bool:
	if tile_x < 0 or tile_x >= 16 or tile_y < 0 or tile_y >= 16:
		return true
	if current_height_data.size() == 0:
		return true
	if tile_y >= current_height_data.size():
		return true
	var row = current_height_data[tile_y]
	if tile_x >= row.size():
		return true
	return row[tile_x] > 0
