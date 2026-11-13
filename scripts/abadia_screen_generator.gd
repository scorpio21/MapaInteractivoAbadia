class_name AbadiaScreenGenerator
extends RefCounted
## Intérprete de construcciones arquitectónicas del visor Extensum.
## Puerto independiente de la clase t de index-7uqyKgKQ.js.
## Lee bloques.bin y los mapas 3d*.map, no habitaciones.bin.
## NO sustituye automáticamente AbadiaRenderer ni AbadiaMapData.dll.

const DEFAULT_BLOCKS_PATH: String = "res://assets/bloques.bin"
const DEFAULT_MAP_PATH: String = "res://assets/3d_cpc.map"
const BASE_WIDTH: int = 16
const BASE_HEIGHT: int = 20
const EXTENDED_WIDTH: int = 32
const EXTENDED_HEIGHT: int = 32
const PLANES: int = 3
const MAX_COMMANDS: int = 200000
const MAX_DEPTH: int = 64

var def_bloques: PackedByteArray = PackedByteArray()
var def_pantallas_3d: PackedByteArray = PackedByteArray()
var mem_offset: int = 0
var extended_view: bool = false
var last_error: String = ""

var width: int = BASE_WIDTH
var height: int = BASE_HEIGHT
var num_planes: int = PLANES
## Cada celda contiene num_planes grupos de 3 bytes: ordenX, ordenY, ID tile.
var tiles: PackedByteArray = PackedByteArray()
var total_elements: int = 0
var visible_elements: int = 0

var _commands_ptr: int = 0
var _block_data: PackedByteArray = PackedByteArray()
var _tile_pos_x: int = 0
var _tile_pos_y: int = 0
var _coord_system_changed: bool = false
var _x_ops_state: Array[int] = [1, 1, 1, 0]
var _reg_pos: int = 0
var _stack: Array[int] = []
var _command_count: int = 0
var _call_depth: int = 0
var _failed: bool = false

func _init() -> void:
	_block_data.resize(17)
	_clear_buffer()


func load_from_files(blocks_path: String = DEFAULT_BLOCKS_PATH, map_path: String = DEFAULT_MAP_PATH) -> bool:
	last_error = ""
	_failed = false
	if not FileAccess.file_exists(blocks_path):
		return _error("No existe bloques.bin: " + blocks_path)
	if not FileAccess.file_exists(map_path):
		return _error("No existe el mapa: " + map_path)
	var block_file: FileAccess = FileAccess.open(blocks_path, FileAccess.READ)
	if block_file == null:
		return _error("No se pudo abrir " + blocks_path)
	def_bloques = block_file.get_buffer(block_file.get_length())
	block_file.close()
	var map_file: FileAccess = FileAccess.open(map_path, FileAccess.READ)
	if map_file == null:
		return _error("No se pudo abrir " + map_path)
	def_pantallas_3d = map_file.get_buffer(map_file.get_length())
	map_file.close()
	if def_bloques.is_empty() or def_pantallas_3d.is_empty():
		return _error("Los datos arquitectónicos están vacíos")
	return true


func set_block_definitions(data: PackedByteArray) -> void:
	def_bloques = data


func set_screen_data(data: PackedByteArray) -> void:
	def_pantallas_3d = data


func set_mem_offset(offset: int) -> void:
	mem_offset = offset


func set_extended_view(enabled: bool) -> void:
	extended_view = enabled


## max_elements < 0: habitación completa. 0: sin elementos.
## El retorno es el TOTAL de elementos, no la cantidad dibujada.
func generate_screen(room_number: int, max_elements: int = -1) -> int:
	last_error = ""
	_failed = false
	_command_count = 0
	_call_depth = 0
	width = EXTENDED_WIDTH if extended_view else BASE_WIDTH
	height = EXTENDED_HEIGHT if extended_view else BASE_HEIGHT
	_clear_buffer()
	total_elements = 0
	visible_elements = 0
	if def_bloques.is_empty() or def_pantallas_3d.is_empty():
		_error("Carga primero bloques.bin y un archivo 3d*.map")
		return -1
	var start: int = _screen_offset(room_number)
	if start < 0:
		return -1
	var ptr: int = start + 1
	var entries: Array[Dictionary] = []
	while ptr < def_pantallas_3d.size():
		var command: int = def_pantallas_3d[ptr]
		if command == 255:
			break
		if ptr + 2 >= def_pantallas_3d.size():
			_error("Entrada de pantalla incompleta")
			return -1
		var has_height: bool = (command & 1) != 0
		if has_height and ptr + 3 >= def_pantallas_3d.size():
			_error("Entrada con altura incompleta")
			return -1
		entries.append({
			"address": command & 254,
			"x": def_pantallas_3d[ptr + 1],
			"y": def_pantallas_3d[ptr + 2],
			"height": def_pantallas_3d[ptr + 3] if has_height else 255
		})
		ptr += 4 if has_height else 3
	if ptr >= def_pantallas_3d.size():
		_error("Pantalla sin terminador 255")
		return -1
	total_elements = entries.size()
	visible_elements = total_elements if max_elements < 0 else clampi(max_elements, 0, total_elements)
	if visible_elements == 0:
		return total_elements

	_coord_system_changed = false
	_x_ops_state = [1, 1, 1, 0]
	_stack.clear()
	for i in range(visible_elements):
		var entry: Dictionary = entries[i]
		var address: int = _address(int(entry["address"]))
		if _failed:
			return -1
		var block_ptr: int = _address(address)
		if _failed:
			return -1
		_commands_ptr = address + 2
		var x: int = int(entry["x"])
		var y: int = int(entry["y"])
		_tile_pos_x = x & 31
		_tile_pos_y = y & 31
		_block_data[12] = _u8(_s8((x >> 5) & 7))
		_block_data[13] = _u8(_s8((y >> 5) & 7))
		_block_data[15] = 0
		_block_data[16] = 0
		var h: int = int(entry["height"])
		_block_data[14] = _u8(_s8(h))
		_init_block_interpretation(block_ptr, true, h)
		if _failed:
			return -1
	return total_elements


func get_screen_buffer() -> Dictionary:
	return {
		"width": width,
		"height": height,
		"num_planes": num_planes,
		"tiles": tiles.duplicate(),
		"total_elements": total_elements,
		"visible_elements": visible_elements
	}


func get_tile_id(x: int, y: int, layer: int) -> int:
	if x < 0 or y < 0 or x >= width or y >= height or layer < 0 or layer >= num_planes:
		return -1
	return tiles[((y * width + x) * num_planes + layer) * 3 + 2]


func _clear_buffer() -> void:
	tiles.resize(width * height * num_planes * 3)
	tiles.fill(0)


func _screen_offset(room_number: int) -> int:
	if room_number < 0:
		_error("Número de habitación negativo")
		return -1
	var ptr: int = 0
	for _i in range(room_number):
		if ptr >= def_pantallas_3d.size():
			_error("Número de habitación fuera del mapa")
			return -1
		var length: int = def_pantallas_3d[ptr]
		if length == 0:
			_error("Longitud de pantalla cero")
			return -1
		ptr += length
	if ptr >= def_pantallas_3d.size():
		_error("Habitación fuera del archivo .map")
		return -1
	return ptr


func _init_block_interpretation(block_ptr: int, initial: bool, elevation: int) -> void:
	if _failed:
		return
	if initial:
		for i in range(12):
			_block_data[i] = _u8(_s8(_block_byte(block_ptr + i)))
	_transform_to_grid(elevation)
	_interpret_commands()


func _transform_to_grid(elevation: int) -> void:
	if elevation != 255:
		_block_data[15] = _u8(_s8(_tile_pos_y + (elevation >> 1) + _tile_pos_x - 15))
		_block_data[16] = _u8(_s8(_tile_pos_y + (elevation >> 1) - _tile_pos_x + 16))


func _interpret_commands() -> void:
	while not _failed:
		_command_count += 1
		if _command_count > MAX_COMMANDS:
			_error("Límite de instrucciones alcanzado")
			return
		var opcode: int = _s8(_block_byte(_commands_ptr) ^ 255)
		_commands_ptr += 1
		if _failed or _do_macro(opcode):
			return


func _do_macro(opcode: int) -> bool:
	match opcode:
		0:
			var changed: bool = _coord_system_changed
			_coord_system_changed = false
			if not changed:
				_x_ops_state = [1, 1, 1, 0]
			return true
		1, 2:
			var reg: int = 109 if opcode == 1 else 110
			var n: int = _get_register(reg, 0)
			if n > 0:
				_push(_commands_ptr)
				_push(n)
			else:
				_skip_to_end_while()
		3:
			_push(_tile_pos_x)
			_push(_tile_pos_y)
		4:
			_tile_pos_y = _pop()
			_tile_pos_x = _pop()
		5:
			var count: int = _pop() - 1
			if count > 0:
				_commands_ptr = _pop()
				_push(_commands_ptr)
				_push(count)
			else:
				_pop()
		6:
			_draw_tile_and_move(0, -1)
		7:
			_draw_tile_and_move(_x_ops_state[2], 0)
		8:
			var flag: int = _block_byte(_commands_ptr)
			_reg_pos = -1
			_read_data_or_register(1)
			var value: int = _read_data_or_register(0)
			value = _evaluate_expression(value)
			if flag >= 112:
				if _block_data[_reg_pos] == 0:
					return false
				if value > 100:
					value = 0
			if _reg_pos < 0 or _reg_pos >= _block_data.size():
				_error("Registro no válido en macro 8")
				return true
			_block_data[_reg_pos] = _u8(_s8(value))
		9:
			_tile_pos_y += 1
		10:
			_tile_pos_x += _x_ops_state[0]
		11:
			_tile_pos_y -= 1
		12:
			_tile_pos_x -= _x_ops_state[1]
		13:
			_tile_pos_y += _evaluate_expression(_read_data_or_register(0))
		14:
			_tile_pos_x += _evaluate_expression(_read_data_or_register(0))
		15:
			_update_register(109, 1)
		16:
			_update_register(110, 1)
		17:
			_update_register(109, -1)
		18:
			_update_register(110, -1)
		19:
			_call(true)
		20:
			_draw_tile_and_move(-1, 0)
		21:
			_commands_ptr = _address(_commands_ptr)
		22, 23, 24, 25, 26:
			_x_ops_state[0] = -_x_ops_state[0]
			_x_ops_state[1] = -_x_ops_state[1]
			_x_ops_state[2] = -_x_ops_state[2]
			_x_ops_state[3] ^= 1
		27:
			_coord_system_changed = true
			_call(false)
		_:
			return true
	return false


func _read_data_or_register(update_position: int) -> int:
	var value: int = _block_byte(_commands_ptr)
	_commands_ptr += 1
	if value < 96:
		return value
	if value == 130:
		value = _block_byte(_commands_ptr)
		_commands_ptr += 1
		return value
	if value >= 112:
		value ^= _x_ops_state[3]
	var register: int = value - 97
	if update_position != 0:
		_reg_pos = register
	if register < 0 or register >= _block_data.size():
		_error("Registro fuera de rango: " + str(register))
		return 0
	return _s8(_block_data[register])


func _get_register(register_id: int, set_position: int) -> int:
	# Refleja exactamente la operación del JS original (incluido su caso >=112).
	if register_id >= 112:
		register_id = _x_ops_state[3]
	var index: int = register_id - 97
	if set_position != 0:
		_reg_pos = index
	if index < 0 or index >= _block_data.size():
		_error("Registro no válido: " + str(index))
		return 0
	return _block_data[index]


func _update_register(register_id: int, delta: int) -> void:
	if register_id >= 112:
		register_id ^= _x_ops_state[3]
	var index: int = register_id - 97
	if index < 0 or index >= _block_data.size():
		_error("Registro no válido: " + str(index))
		return
	_block_data[index] = _u8(_s8(_s8(_block_data[index]) + delta))


func _evaluate_expression(value: int) -> int:
	while not _failed:
		var opcode: int = _block_byte(_commands_ptr)
		if opcode >= 200:
			return value
		if opcode == 132:
			value = -value
			_commands_ptr += 1
		else:
			value += _s8(_read_data_or_register(0))
	return value


func _draw_tile_and_move(delta_x: int, delta_y: int) -> void:
	while not _failed:
		var tile_id: int = _read_data_or_register(0)
		var operation: int = _block_byte(_commands_ptr)
		if operation >= 200:
			_write_tile(tile_id)
			_tile_pos_x += delta_x
			_tile_pos_y += delta_y
			break
		_commands_ptr += 1
		if operation == 128:
			_write_tile(tile_id)
			_tile_pos_x += delta_x
			_tile_pos_y += delta_y
		elif operation == 129:
			_write_tile(tile_id)
		else:
			var count: int = _read_data_or_register(0)
			for _i in range(maxi(0, count)):
				_write_tile(tile_id)
				_tile_pos_x += delta_x
				_tile_pos_y += delta_y
			if _block_byte(_commands_ptr) >= 200:
				break
			_commands_ptr += 1


func _write_tile(tile_id: int) -> void:
	var x: int = _tile_pos_x if extended_view else _tile_pos_x - 8
	var y: int = _tile_pos_y if extended_view else _tile_pos_y - 8
	if x < 0 or x >= width or y < 0 or y >= height:
		return
	_update_tile(tile_id, y * width + x)


func _update_tile(tile_id: int, cell_index: int) -> void:
	var ptr: int = cell_index * num_planes * 3
	var order_x: int = _block_data[15]
	var order_y: int = _block_data[16]
	for _plane in range(1, num_planes):
		var next_x: int = tiles[ptr + 3]
		var next_y: int = tiles[ptr + 4]
		var next_tile: int = tiles[ptr + 5]
		if order_x < next_x and order_y < next_y:
			next_x = order_x
			next_y = order_y
		tiles[ptr] = next_x
		tiles[ptr + 1] = next_y
		tiles[ptr + 2] = next_tile
		ptr += 3
	ptr -= 3
	tiles[ptr + 3] = order_x
	tiles[ptr + 4] = order_y
	tiles[ptr + 5] = _u8(tile_id)


func _call(restore_registers: bool) -> void:
	if _call_depth >= MAX_DEPTH:
		_error("Límite de llamadas anidadas")
		return
	_call_depth += 1
	_push(_tile_pos_x)
	_push(_tile_pos_y)
	for index in range(4):
		_push(_x_ops_state[index])
	for index in range(12, 17):
		_push(_s8(_block_data[index]))
	var target: int = _address(_commands_ptr)
	_commands_ptr += 2
	_push(_commands_ptr)
	var block_ptr: int = _address(target)
	_commands_ptr = target + 2
	_init_block_interpretation(block_ptr, restore_registers, _block_data[14])
	_commands_ptr = _pop()
	for index in range(16, 11, -1):
		_block_data[index] = _u8(_s8(_pop()))
	for index in range(3, -1, -1):
		_x_ops_state[index] = _pop()
	_tile_pos_y = _pop()
	_tile_pos_x = _pop()
	_call_depth -= 1


func _skip_to_end_while() -> void:
	var depth: int = 1
	while depth > 0 and not _failed:
		var operation: int = _block_byte(_commands_ptr)
		if operation == 130:
			_commands_ptr += 2
		else:
			if operation == 254 or operation == 253:
				depth += 1
			elif operation == 250:
				depth -= 1
			_commands_ptr += 1


func _address(ptr: int) -> int:
	var low: int = _block_byte(ptr)
	var high: int = _block_byte(ptr + 1)
	var target: int = (low | (high << 8)) - mem_offset
	if target < 0 or target >= def_bloques.size():
		_error("Dirección de bloque fuera de rango: " + str(target))
	return target


func _block_byte(ptr: int) -> int:
	if ptr < 0 or ptr >= def_bloques.size():
		_error("Lectura fuera de bloques.bin: " + str(ptr))
		return 0
	return def_bloques[ptr]


func _push(value: int) -> void:
	if _stack.size() >= 2048:
		_error("Pila del intérprete llena")
		return
	_stack.append(_s16(value))


func _pop() -> int:
	if _stack.is_empty():
		_error("Pila del intérprete vacía")
		return 0
	return _stack.pop_back()


func _error(message: String) -> bool:
	if not _failed:
		last_error = message
		push_error("AbadiaScreenGenerator: " + message)
	_failed = true
	return false


static func _u8(value: int) -> int:
	return value & 255


static func _s8(value: int) -> int:
	value &= 255
	return value - 256 if value >= 128 else value


static func _s16(value: int) -> int:
	value &= 65535
	return value - 65536 if value >= 32768 else value
