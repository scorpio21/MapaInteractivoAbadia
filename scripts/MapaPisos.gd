extends Node2D

const ScriptInterpreterGD = preload("res://scripts/ScriptInterpreter.gd")
const TileRendererGD = preload("res://scripts/TileRenderer.gd")

const SCREEN_OFFSET_X: int = 32

var interpreter
var renderer: TileRenderer
var floors_data = []
var rooms_data: Array = []
var current_floor: int = 0
var current_room_x: int = -1
var current_room_y: int = -1
var current_room_sprites: Array = []
var interpreted_rooms: Dictionary = {}

func _ready() -> void:
	interpreter = ScriptInterpreterGD.new()
	renderer = TileRendererGD.new()
	add_child(renderer)

	_load_data()
	_parse_scripts()
	_setup_renderer()

	var bg_color = Color(0.0, 0.502, 0.502)
	RenderingServer.set_default_clear_color(bg_color)

	var initial_room = _find_initial_room()
	if initial_room:
		current_room_x = initial_room[0]
		current_room_y = initial_room[1]
		_build_and_render_room(current_floor, current_room_x, current_room_y)

	_position_player_at_room_center()

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
		j.position = Vector2(
			SCREEN_OFFSET_X * int(TileRendererGD.SCALE) + 8 * 16 * int(TileRendererGD.SCALE),
			8 * 8 * int(TileRendererGD.SCALE)
		)

func _load_data() -> void:
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

	print("Floors: ", floors_data.size(), " Rooms: ", rooms_data.size())

func _parse_scripts() -> void:
	var scripts_file = FileAccess.open("res://data/scripts.abs", FileAccess.READ)
	if scripts_file:
		var text = scripts_file.get_as_text()
		scripts_file.close()
		interpreter.parse_scripts(text)
		print("Scripts parseados: ", interpreter.scripts.size())

func _setup_renderer() -> void:
	var tile_texture = load("res://assets/tiles_day.png")
	if tile_texture == null:
		print("ERROR: No se pudo cargar tiles_day.png")
		return

	var tile_file = FileAccess.open("res://data/tiles.json", FileAccess.READ)
	if tile_file:
		var json = JSON.new()
		var err = json.parse(tile_file.get_as_text())
		if err == OK:
			renderer.setup(tile_texture, json.data)
			print("TileRenderer configurado con ", renderer.tile_frames.size(), " tiles")
		tile_file.close()

func build_and_render_room(fl: int, rx: int, ry: int) -> void:
	if fl == current_floor and rx == current_room_x and ry == current_room_y:
		return
	current_floor = fl
	current_room_x = rx
	current_room_y = ry
	_build_and_render_room(fl, rx, ry)

func _build_and_render_room(fl: int, rx: int, ry: int) -> void:
	_clear_current_room()

	if fl >= floors_data.size():
		return
	var room_grid = floors_data[fl].get("room", [])
	if ry >= room_grid.size() or rx >= room_grid[ry].size():
		return
	var room_id = room_grid[ry][rx]
	if room_id < 1 or room_id > rooms_data.size():
		return

	var room_data = _interpret_room(room_id)

	_render_room(room_data)

	var tile_count = 0
	for x in range(16):
		for y in range(20):
			tile_count += room_data[x][y].size()
	print("Room %d at (%d,%d): %d sprites" % [room_id, rx, ry, tile_count])

func _interpret_room(room_id: int) -> Array:
	if interpreted_rooms.has(room_id):
		return interpreted_rooms[room_id]

	var room = rooms_data[room_id - 1]
	var blocks = room.get("blocks", [])

	interpreter.clear_tile_buffer()
	for block in blocks:
		interpreter.execute_block(block)

	var tile_buffer = interpreter.get_tile_buffer()
	var copy = []
	for x in range(16):
		var col = []
		for y in range(20):
			col.append(tile_buffer[x][y].duplicate())
		copy.append(col)

	interpreted_rooms[room_id] = copy
	return copy

func _render_room(room_data: Array) -> void:
	for x in range(16):
		for y in range(20):
			var tiles_at_pos = room_data[x][y]
			for tile_data in tiles_at_pos:
				var tile_id = tile_data["tile"]
				var dx = tile_data["depthX"]
				var dy = tile_data["depthY"]
				var depth = dx + dy - 16

				var sprite = renderer._create_tile_sprite(tile_id)
				if sprite == null:
					continue

				var pos_x = SCREEN_OFFSET_X * int(TileRendererGD.SCALE) + x * int(TileRendererGD.TILE_W) * int(TileRendererGD.SCALE)
				var pos_y = y * int(TileRendererGD.TILE_H) * int(TileRendererGD.SCALE)
				sprite.position = Vector2(pos_x, pos_y)
				sprite.scale = Vector2(TileRendererGD.SCALE, TileRendererGD.SCALE)
				sprite.z_index = int(depth)

				add_child(sprite)
				current_room_sprites.append(sprite)

func _clear_current_room() -> void:
	for s in current_room_sprites:
		if is_instance_valid(s):
			s.queue_free()
	current_room_sprites.clear()

func get_room_at(fl: int, rx: int, ry: int) -> int:
	if fl < 0 or fl >= floors_data.size():
		return 0
	var room_grid = floors_data[fl].get("room", [])
	if ry < 0 or ry >= room_grid.size() or rx < 0 or rx >= room_grid[ry].size():
		return 0
	return room_grid[ry][rx]

func get_world_size() -> Vector2:
	var room_pixel_w = 16 * int(TileRendererGD.TILE_W) * int(TileRendererGD.SCALE)
	var room_pixel_h = 16 * int(TileRendererGD.TILE_H) * int(TileRendererGD.SCALE)
	return Vector2(16 * room_pixel_w, 16 * room_pixel_h)
