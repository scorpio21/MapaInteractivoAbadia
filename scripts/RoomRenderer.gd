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

func _init() -> void:
	pass

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

	var buffer = _get_room_buffer(room_id)
	_render_buffer(buffer)
	print("Room %d at (%d,%d): rendered" % [room_id, rx, ry])

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
				var tile_id = tile_data["tile"]
				if not tile_frames.has(tile_id):
					continue
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
