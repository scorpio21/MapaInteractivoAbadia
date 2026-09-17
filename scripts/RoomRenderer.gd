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
var use_binary: bool = true
var show_border: bool = true
var extended_view: bool = false
var grid_w: int = 16
var grid_h: int = 20

func _init() -> void:
	pass

func _draw() -> void:
	if show_border and extended_view:
		var rx: float = 8 * TILE_W
		var ry: float = 8 * TILE_H
		var rw: float = 16 * TILE_W
		var rh: float = 20 * TILE_H
		draw_rect(Rect2(rx, ry, rw, rh), Color(1, 1, 1, 0.8), false, 2.0)

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

func _process(_delta: float) -> void:
	_update_scale()

var _last_scale := Vector2.ZERO

func _update_scale() -> void:
	var vp = get_viewport()
	if vp == null:
		return
	var vp_size = vp.get_visible_rect().size
	if vp_size.x <= 0 or vp_size.y <= 0:
		return
	if vp_size == _last_scale:
		return
	_last_scale = vp_size
	var base_size = Vector2(grid_w * TILE_W, grid_h * TILE_H)
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
	if GameData.all_room_data.size() > 0:
		tile_atlas = load("res://assets/tiles.png")
		use_binary = (tile_atlas != null)
		if not use_binary:
			tile_atlas = load("res://assets/tiles_day.png")
	else:
		tile_atlas = load("res://assets/tiles_day.png")
		use_binary = false
	if tile_atlas == null:
		print("ERROR: No se pudo cargar tileset")
		return
	_load_tile_frames()

func load_tileset(path: String) -> void:
	var tex = load(path)
	if tex == null:
		print("ERROR: No se pudo cargar ", path)
		return
	room_cache.clear()

	if path == "res://assets/tiles.png" and GameData.all_room_data.size() > 0:
		tile_atlas = tex
		_load_tile_frames()
		use_binary = true
		print("RoomRenderer: tileset Original (binary)")
	else:
		tile_atlas = load("res://assets/tiles_day.png")
		_load_tile_frames()
		use_binary = false
		print("RoomRenderer: tileset ", path, " (scripts, usando tiles_day.png)")

	if current_room_x >= 0 and current_room_y >= 0:
		_clear_sprites()
		if use_binary:
			_build_room_binary(current_floor, current_room_x, current_room_y)
		else:
			_build_room_script(current_floor, current_room_x, current_room_y)

func _load_tile_frames() -> void:
	tile_frames.clear()
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

func build_room(fl: int, rx: int, ry: int, force: bool = false) -> void:
	if not force and fl == current_floor and rx == current_room_x and ry == current_room_y:
		return
	current_floor = fl
	current_room_x = rx
	current_room_y = ry
	_clear_sprites()

	if use_binary and GameData.all_room_data.size() > 0:
		_build_room_binary(fl, rx, ry)
	else:
		_build_room_script(fl, rx, ry)

func _build_room_binary(fl: int, rx: int, ry: int) -> void:
	var room_index: int = GameData.get_room_index_from_floor(fl, rx, ry)
	_render_binary_room(room_index)
	current_height_data = []
	current_blocks = []
	_count_binary_blocks(room_index)
	print("Room binary index %d at (%d,%d): floor %d (%d tiles)" % [room_index, rx, ry, fl, current_blocks.size()])

func _count_binary_blocks(room_index: int) -> void:
	var count: int = 0
	for y in range(GameData.ROOM_GRID_H):
		for x in range(GameData.ROOM_GRID_W):
			for layer in range(3):
				var raw: int = GameData.get_tile_from_map(x, y, layer, room_index)
				if raw > 0:
					count += 1
	current_blocks.resize(count)
	for i in range(count):
		current_blocks[i] = {}

func _build_room_script(fl: int, rx: int, ry: int) -> void:
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

func _render_binary_room(room_index: int) -> void:
	for y in range(GameData.ROOM_GRID_H):
		for x in range(GameData.ROOM_GRID_W):
			for layer in range(3):
				var raw: int = GameData.get_tile_from_map(x, y, layer, room_index)
				if raw > 0:
					_add_binary_sprite(x, y, raw)

func _add_binary_sprite(x: int, y: int, raw_index: int) -> void:
	var page: int = raw_index / 256
	var tile_x: int = raw_index & 0xF0
	var tile_y: int = ((raw_index & 0xF) << 3) + page * 128
	var atlas = AtlasTexture.new()
	atlas.atlas = tile_atlas
	atlas.region = Rect2(tile_x, tile_y, 16, 8)
	var sprite = Sprite2D.new()
	sprite.texture = atlas
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var draw_x: int = x
	var draw_y: int = y
	if not extended_view:
		draw_x = x - 8
		draw_y = y - 8
	sprite.position = Vector2(draw_x * TILE_W, draw_y * TILE_H)
	sprite.z_index = x + y - 16
	sprite.modulate = GameData.current_lighting
	add_child(sprite)
	current_sprites.append(sprite)

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
	for x in range(buffer.size()):
		for y in range(buffer[x].size()):
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
	var draw_x: int = x
	var draw_y: int = y
	if not extended_view:
		draw_x = x - 8
		draw_y = y - 8
	sprite.position = Vector2(draw_x * TILE_W, draw_y * TILE_H)
	sprite.z_index = tile_data["depthX"] + tile_data["depthY"] - 16
	sprite.modulate = GameData.current_lighting
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

	if use_binary and GameData.all_room_data.size() > 0:
		var room_index: int = GameData.get_room_index_from_floor(fl, rx, ry)
		_clear_sprites()
		_render_binary_room(room_index)
		print("Room binary index %d at (%d,%d): partial render (binary)" % [room_index, rx, ry])
		return

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

func set_lighting(color: Color) -> void:
	GameData.current_lighting = color
	for s in current_sprites:
		if is_instance_valid(s):
			s.modulate = color

func set_extended(extended: bool) -> void:
	extended_view = extended
	if extended:
		grid_w = 32
		grid_h = 32
	else:
		grid_w = 16
		grid_h = 20
	queue_redraw()

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
