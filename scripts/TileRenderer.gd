extends Node2D
class_name TileRenderer

const TILE_W: int = 16
const TILE_H: int = 8
const SCREEN_OFFSET_X: int = 32
const ROOM_W: int = 16
const ROOM_H: int = 20
const SCALE: float = 4.0

var tile_atlas: Texture2D
var tile_frames: Dictionary = {}
var tile_cache: Dictionary = {}

func _init() -> void:
	pass

func setup(tile_texture: Texture2D, tile_json: Dictionary) -> void:
	tile_atlas = tile_texture
	tile_frames.clear()
	for key in tile_json.get("frames", {}).keys():
		var frame_data = tile_json["frames"][key]["frame"]
		var tile_id = int(key.replace("tile", ""))
		tile_frames[tile_id] = {
			"rect": Rect2(frame_data["x"], frame_data["y"], frame_data["w"], frame_data["h"])
		}

func render_room(tile_buffer: Array, parent: Node, room_x: int, room_y: int, floor_num: int) -> Array:
	var sprites: Array = []

	for x in range(ROOM_W):
		for y in range(ROOM_H):
			var tiles_at_pos = tile_buffer[x][y]
			for tile_data in tiles_at_pos:
				var tile_id = tile_data["tile"]
				var dx = tile_data["depthX"]
				var dy = tile_data["depthY"]
				var depth = dx + dy - 16

				var sprite = _create_tile_sprite(tile_id)
				if sprite == null:
					continue

				var pos_x = (room_x * ROOM_W + x) * TILE_W * SCALE
				var pos_y = (room_y * ROOM_H + y) * TILE_H * SCALE
				sprite.position = Vector2(pos_x + SCREEN_OFFSET_X * SCALE, pos_y)
				sprite.scale = Vector2(SCALE, SCALE)
				sprite.z_index = int(depth)
				sprite.set_meta("floor", floor_num)
				sprite.set_meta("room_x", room_x)
				sprite.set_meta("room_y", room_y)

				parent.add_child(sprite)
				sprites.append(sprite)

	return sprites

func render_room_at(tile_buffer: Array, parent: Node, screen_x: int, screen_y: int, floor_num: int) -> Array:
	var sprites: Array = []

	for x in range(ROOM_W):
		for y in range(ROOM_H):
			if x >= tile_buffer.size() or y >= tile_buffer[x].size():
				continue
			var tiles_at_pos = tile_buffer[x][y]
			for tile_data in tiles_at_pos:
				var tile_id = tile_data["tile"]
				var dx = tile_data["depthX"]
				var dy = tile_data["depthY"]
				var depth = dx + dy - 16

				var sprite = _create_tile_sprite(tile_id)
				if sprite == null:
					continue

				var pos_x = screen_x + x * TILE_W * SCALE
				var pos_y = screen_y + y * TILE_H * SCALE
				sprite.position = Vector2(pos_x, pos_y)
				sprite.scale = Vector2(SCALE, SCALE)
				sprite.z_index = int(depth)
				sprite.set_meta("floor", floor_num)

				parent.add_child(sprite)
				sprites.append(sprite)

	return sprites

func _create_tile_sprite(tile_id: int) -> Sprite2D:
	if not tile_frames.has(tile_id):
		return null

	var frame = tile_frames[tile_id]
	var atlas = AtlasTexture.new()
	atlas.atlas = tile_atlas
	atlas.region = frame["rect"]

	var sprite = Sprite2D.new()
	sprite.texture = atlas
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sprite

func clear_room(sprites: Array) -> void:
	for s in sprites:
		if is_instance_valid(s):
			s.queue_free()
	sprites.clear()
