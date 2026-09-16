extends Node2D

const ScriptInterpreterGD = preload("res://scripts/ScriptInterpreter.gd")
const TileRendererGD = preload("res://scripts/TileRenderer.gd")

var interpreter
var renderer: TileRenderer
var floors_data = []
var rooms_data: Array = []
var rendered_sprites: Array = []
var current_floor: int = 0
var rendered_rooms: Dictionary = {}

func _ready() -> void:
	interpreter = ScriptInterpreterGD.new()
	renderer = TileRendererGD.new()
	add_child(renderer)

	_load_data()
	_parse_scripts()
	_setup_renderer()
	_render_initial_map()

	# Position player at entrance area
	await get_tree().process_frame
	var jugadores = get_tree().get_nodes_in_group("jugador")
	for j in jugadores:
		var room_pixel_w = 16 * 16 * int(TileRendererGD.SCALE)
		var room_pixel_h = 20 * 8 * int(TileRendererGD.SCALE)
		j.position = Vector2(8 * room_pixel_w, 8 * room_pixel_h)

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

func _render_initial_map() -> void:
	_render_floor(current_floor)

func _render_floor(floor_num: int) -> void:
	_clear_rendered()

	if floor_num >= floors_data.size():
		return

	var floor = floors_data[floor_num]
	var room_grid = floor.get("room", [])
	var total_rooms = 0
	var total_tiles = 0

	for ry in range(room_grid.size()):
		var row = room_grid[ry]
		for rx in range(row.size()):
			var room_id = row[rx]
			if room_id > 0:
				var count = _render_room(floor_num, rx, ry, room_id)
				if count > 0:
					total_rooms += 1
					total_tiles += count

	print("Floor %d: %d rooms rendered, %d total sprites" % [floor_num, total_rooms, total_tiles])

func _render_room(floor_num: int, rx: int, ry: int, room_id: int) -> int:
	var key = "%d_%d_%d" % [floor_num, rx, ry]
	if rendered_rooms.has(key):
		return 0

	if room_id < 1 or room_id > rooms_data.size():
		return 0

	var room = rooms_data[room_id - 1]
	var blocks = room.get("blocks", [])

	if blocks.size() == 0:
		return 0

	interpreter.clear_tile_buffer()
	for block in blocks:
		interpreter.execute_block(block)

	var tile_buffer = interpreter.get_tile_buffer()

	var room_pixel_w = 16 * 16 * int(TileRendererGD.SCALE)
	var room_pixel_h = 20 * 8 * int(TileRendererGD.SCALE)
	var screen_x = rx * room_pixel_w
	var screen_y = ry * room_pixel_h

	var sprites = renderer.render_room_at(tile_buffer, self, screen_x, screen_y, floor_num)
	rendered_rooms[key] = sprites
	rendered_sprites.append_array(sprites)

	var tile_count = 0
	for x in range(16):
		for y in range(20):
			tile_count += tile_buffer[x][y].size()
	return tile_count

func _clear_rendered() -> void:
	for sprites in rendered_rooms.values():
		renderer.clear_room(sprites)
	rendered_rooms.clear()
	rendered_sprites.clear()

func get_world_size() -> Vector2:
	var room_pixel_w = 16 * 16 * int(TileRendererGD.SCALE)
	var room_pixel_h = 20 * 8 * int(TileRendererGD.SCALE)
	return Vector2(16 * room_pixel_w, 12 * room_pixel_h)
