extends Node

const TILE_MAP_SIZE: int = 672
const ROOM_DATA_SIZE: int = 5280
const HEIGHT_DATA_SIZE: int = 576
const ROOM_GRID_W: int = 20
const ROOM_GRID_H: int = 22
const HEIGHT_GRID: int = 24
const TILES_PER_PAGE: int = 150

var tile_map: PackedInt32Array = PackedInt32Array()
var room_states: Array = []
var event_flags: int = 0
var all_room_data: PackedByteArray = PackedByteArray()
var all_height_data: PackedByteArray = PackedByteArray()
var exit_data: PackedByteArray = PackedByteArray()

const LIGHTING_PITCH_BLACK := Color(0.0, 0.0, 0.0)
const LIGHTING_DAY := Color(1.0, 1.0, 1.0)
const LIGHTING_WARM_DAY := Color(0.9, 0.8, 0.7)
const LIGHTING_DUSK := Color(0.3, 0.3, 0.6)
const LIGHTING_DEEP_NIGHT := Color(0.15, 0.15, 0.3)
const LIGHTING_INDOOR := Color(0.8, 0.8, 0.8)
const LIGHTING_CANDLE := Color(0.8, 0.8, 0.4)
const LIGHTING_TORCH := Color(0.8, 0.4, 0.2)

const LIGHTING_NAMES := [
	"Pitch Black", "Day", "Warm Day", "Dusk",
	"Deep Night", "Indoor", "Candle", "Torch"
]

const FLOOR_ROOM_OFFSETS := [0, 10, 10]

var current_lighting := LIGHTING_DAY

func _ready() -> void:
	_init_tile_map()
	_init_room_states()
	_load_binary_data()

func _init_tile_map() -> void:
	tile_map.resize(TILE_MAP_SIZE)
	tile_map.fill(0)
	var mapping := {
		24: 39, 26: 62, 27: 79, 28: 126,
		33: 10, 34: 9, 36: 7, 37: 8, 38: 42, 39: 40,
		40: 38, 41: 41, 42: 55, 43: 56, 44: 57,
		50: 2, 51: 1, 53: 13, 54: 14, 55: 36, 56: 35,
		57: 37, 58: 43, 59: 44, 60: 45,
		66: 3, 68: 31, 69: 132, 70: 131, 71: 116,
		72: 34, 73: 117, 74: 46, 75: 47, 76: 48,
		82: 4, 83: 29, 84: 30, 85: 130, 86: 61,
		87: 98, 88: 33, 89: 99, 90: 49, 91: 50, 92: 51,
		97: 12, 98: 11, 99: 28, 100: 5, 101: 6, 102: 60,
		103: 96, 104: 32, 105: 97, 106: 52, 107: 53, 108: 54,
		115: 15, 116: 16, 117: 17, 118: 18, 119: 94,
		120: 27, 121: 95, 122: 26, 123: 58, 124: 59,
		133: 129, 134: 19, 135: 20, 136: 21, 137: 24,
		138: 25, 139: 124, 140: 125,
		148: 123, 149: 120, 150: 90, 151: 91, 152: 22,
		153: 92, 154: 93, 155: 137,
		164: 122, 165: 119, 166: 85, 167: 86, 168: 87,
		169: 88, 170: 89, 171: 138,
		180: 121, 181: 118, 182: 80, 183: 81, 184: 82,
		185: 83, 186: 84, 187: 139,
		200: 23,
		257: 69, 258: 68, 260: 72, 261: 73, 262: 127,
		274: 67, 275: 71, 276: 74,
		290: 66, 292: 75,
		306: 65, 307: 64, 308: 76,
		321: 63, 322: 70, 324: 77, 325: 78,
		481: 103, 482: 102, 484: 101, 485: 100, 486: 128,
		497: 133, 498: 106, 499: 105, 500: 104, 501: 134,
		514: 108, 516: 107,
		529: 135, 530: 111, 531: 110, 532: 109, 533: 136,
		545: 115, 546: 114, 548: 113, 549: 112, 551: 140
	}
	for key in mapping:
		tile_map[key] = mapping[key]

func _init_room_states() -> void:
	room_states.resize(116)
	for i in range(116):
		room_states[i] = {
			"a": 0, "i": 0, "j": 0, "r": 0, "b": 0,
			"l": 0, "c": 0, "m": 0, "p": 0, "q": 0
		}

func _load_binary_data() -> void:
	var rooms_file = FileAccess.open("res://assets/bin/habitaciones.bin", FileAccess.READ)
	if rooms_file:
		all_room_data = rooms_file.get_buffer(rooms_file.get_length())
		rooms_file.close()
		print("GameData: ", all_room_data.size(), " bytes de habitaciones cargados")

	var heights_file = FileAccess.open("res://assets/bin/alturas.bin", FileAccess.READ)
	if heights_file:
		all_height_data = heights_file.get_buffer(heights_file.get_length())
		heights_file.close()
		print("GameData: ", all_height_data.size(), " bytes de alturas cargados")

	var exits_file = FileAccess.open("res://assets/bin/salidas.bin", FileAccess.READ)
	if exits_file:
		exit_data = exits_file.get_buffer(exits_file.get_length())
		exits_file.close()

func map_tile_index(raw_index: int) -> int:
	var page: int = raw_index / TILES_PER_PAGE
	var local: int = raw_index % TILES_PER_PAGE
	return page * TILES_PER_PAGE + local

func get_tile_from_map(x: int, y: int, layer: int, room_index: int) -> int:
	var offset: int = room_index * ROOM_DATA_SIZE
	offset += (y * ROOM_GRID_W + x) * 12 + layer * 4 + 2
	if offset + 1 >= all_room_data.size():
		return 0
	var low: int = all_room_data[offset]
	var high: int = all_room_data[offset + 1]
	var raw: int = low + (high << 8)
	return raw

func get_mapped_tile(x: int, y: int, layer: int, room_index: int) -> int:
	var raw: int = get_tile_from_map(x, y, layer, room_index)
	if raw == 0:
		return 0
	var lighting: int = (raw >> 8) & 0xFF
	var tile_id: int = raw % TILES_PER_PAGE
	return lighting * TILES_PER_PAGE + tile_id

func get_height_at(x: int, y: int, room_index: int) -> int:
	var offset: int = room_index * HEIGHT_DATA_SIZE + y * HEIGHT_GRID + x
	if offset >= all_height_data.size():
		return 0
	return all_height_data[offset]

func get_room_index_from_floor(fl: int, rx: int, ry: int) -> int:
	var grid_start_row: int = 0
	var grid_start_col: int = 0
	if fl == 1:
		grid_start_row = 10
	elif fl == 2:
		grid_start_row = 10
		grid_start_col = 8
	var map_x: int = grid_start_col + rx
	var map_y: int = grid_start_row + ry
	return map_y * ROOM_GRID_W + map_x

func set_room_state(room_id: int, key: String, value: int) -> void:
	if room_id >= 0 and room_id < room_states.size():
		room_states[room_id][key] = value

func get_room_state(room_id: int, key: String) -> int:
	if room_id >= 0 and room_id < room_states.size():
		return room_states[room_id].get(key, 0)
	return 0

func set_event_flag(flag: int) -> void:
	event_flags |= flag

func clear_event_flag(flag: int) -> void:
	event_flags &= ~flag

func has_event_flag(flag: int) -> bool:
	return (event_flags & flag) != 0

func set_lighting(light_type: Color) -> void:
	current_lighting = light_type

func get_lighting() -> Color:
	return current_lighting

const TILE_CATEGORY_FLOOR_OUTDOOR := [80, 81, 82, 83, 85, 86, 87, 88, 138, 90, 91, 22, 92, 93, 137, 20, 21, 24, 25, 124, 61, 130, 131, 52, 53, 54, 49, 50, 51, 46, 47, 48, 45, 90, 19, 18, 17, 16, 15, 28, 60]
const TILE_CATEGORY_STAIRS := [40, 42, 127, 128]
const TILE_CATEGORY_INDOOR_FLOOR := [100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 133, 134, 135, 136, 140]
const TILE_CATEGORY_DOOR := [130, 132, 61]
const TILE_CATEGORY_SPECIAL := [96, 98, 116]

func is_floor_tile(tile_id: int) -> bool:
	return tile_id in TILE_CATEGORY_FLOOR_OUTDOOR

func is_stair_tile(tile_id: int) -> bool:
	return tile_id in TILE_CATEGORY_STAIRS

func is_indoor_floor_tile(tile_id: int) -> bool:
	return tile_id in TILE_CATEGORY_INDOOR_FLOOR

func is_door_tile(tile_id: int) -> bool:
	return tile_id in TILE_CATEGORY_DOOR
