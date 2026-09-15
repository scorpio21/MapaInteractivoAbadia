extends Node3D

# Generador de mapa 3D desde JSON de ultrabolido/abadia

@export var tile_size: float = 2.0
@export var height_scale: float = 1.0
@export var floor_index: int = 0

var floors_data: Array = []
var rooms_data: Array = []
var floor_meshes: Node3D

func _ready() -> void:
	floor_meshes = Node3D.new()
	floor_meshes.name = "FloorMeshes"
	add_child(floor_meshes)

	_load_data()
	_generate_floor()

func _load_data() -> void:
	var floors_file = FileAccess.open("res://data/floors.json", FileAccess.READ)
	if floors_file:
		var json = JSON.new()
		var error = json.parse(floors_file.get_as_text())
		if error == OK:
			floors_data = json.data
		else:
			push_warning("Error parsing floors.json: " + json.get_error_message())
		floors_file.close()
	else:
		push_warning("No se pudo abrir floors.json")

	var rooms_file = FileAccess.open("res://data/rooms.json", FileAccess.READ)
	if rooms_file:
		var json = JSON.new()
		var error = json.parse(rooms_file.get_as_text())
		if error == OK:
			rooms_data = json.data
		else:
			push_warning("Error parsing rooms.json: " + json.get_error_message())
		rooms_file.close()
	else:
		push_warning("No se pudo abrir rooms.json")

func _generate_floor() -> void:
	if floors_data.is_empty() or rooms_data.is_empty():
		push_warning("No hay datos de mapa cargados")
		return

	_clear_meshes()

	var floor = floors_data[floor_index]
	var room_grid = floor["room"]

	for ry in range(16):
		for rx in range(16):
			var room_id = room_grid[ry][rx]
			if room_id == 0:
				continue
			_generate_room(room_id, rx, ry)

func _generate_room(room_id: int, grid_x: int, grid_y: int) -> void:
	if room_id < 1 or room_id > rooms_data.size():
		return

	var room = rooms_data[room_id - 1]
	var height_data = room["heightData"]

	var room_node = Node3D.new()
	room_node.name = "Room_%d_%d_%d" % [room_id, grid_x, grid_y]
	room_node.position = Vector3(grid_x * 16 * tile_size, 0, grid_y * 16 * tile_size)
	floor_meshes.add_child(room_node)

	for y in range(16):
		for x in range(16):
			var height = height_data[y][x]
			if height == 15:
				_create_wall(room_node, x, y)
			elif height > 0 and height < 15:
				_create_platform(room_node, x, y, height)

func _create_wall(parent: Node3D, x: int, y: int) -> void:
	var box = BoxMesh.new()
	box.size = Vector3(tile_size, tile_size * 2, tile_size)

	var instance = MeshInstance3D.new()
	instance.mesh = box
	instance.position = Vector3(x * tile_size, tile_size, y * tile_size)

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.35, 0.25)
	instance.material_override = material

	parent.add_child(instance)

func _create_platform(parent: Node3D, x: int, y: int, height: int) -> void:
	var box = BoxMesh.new()
	box.size = Vector3(tile_size, height * height_scale * 0.25, tile_size)

	var instance = MeshInstance3D.new()
	instance.mesh = box
	instance.position = Vector3(x * tile_size, height * height_scale * 0.125, y * tile_size)

	var material = StandardMaterial3D.new()
	var color_value = float(height) / 15.0
	material.albedo_color = Color(0.5 + color_value * 0.3, 0.4, 0.3)

	parent.add_child(instance)

func _clear_meshes() -> void:
	for child in floor_meshes.get_children():
		child.queue_free()

func set_floor(index: int) -> void:
	floor_index = index
	_generate_floor()
