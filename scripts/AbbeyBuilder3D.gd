extends Node3D

@export var tile_size: float = 2.0
@export var floor_index: int = 0

var floors_data: Array = []
var rooms_data: Array = []

# Build a lookup: room_grid[y][x] -> room_id
# And compute world positions from room grid + tile coords

func _ready() -> void:
	print("=== AbbeyBuilder3D INICIADO ===")
	call_deferred("_init_map")

func _init_map() -> void:
	_load_data()
	print("Floors: ", floors_data.size(), " Rooms: ", rooms_data.size())
	if floors_data.is_empty() or rooms_data.is_empty():
		_create_test_cube()
		return
	_generate_map()

func _load_data() -> void:
	var f = FileAccess.open("res://data/floors.json", FileAccess.READ)
	if f:
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			floors_data = json.data
		f.close()

	var r = FileAccess.open("res://data/rooms.json", FileAccess.READ)
	if r:
		var json = JSON.new()
		if json.parse(r.get_as_text()) == OK:
			rooms_data = json.data
		r.close()

# Convert room grid coords + tile coords to world position
# grid_x, grid_y = room position in the 16x16 grid
# tile_x, tile_y = position within the room (0-15)
func _room_to_world(grid_x: int, grid_y: int, tile_x: int, tile_y: int) -> Vector3:
	var wx = grid_x * 16 * tile_size + tile_x * tile_size + tile_size * 0.5
	var wz = grid_y * 16 * tile_size + tile_y * tile_size + tile_size * 0.5
	return Vector3(wx, 0, wz)

# Get height at a specific room grid + tile position
func _get_height_at(grid_x: int, grid_y: int, tile_x: int, tile_y: int) -> int:
	var floor_data = floors_data[floor_index]
	var room_grid = floor_data["room"]
	var room_id = room_grid[grid_y][grid_x]
	if room_id == 0 or room_id > rooms_data.size():
		return -1
	var room = rooms_data[room_id - 1]
	return room["heightData"][tile_y][tile_x]

func _generate_map() -> void:
	var floor_data = floors_data[floor_index]
	var room_grid = floor_data["room"]

	var walls_st = SurfaceTool.new()
	walls_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall_count = 0

	var floors_st = SurfaceTool.new()
	floors_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var floor_count = 0

	for ry in range(16):
		for rx in range(16):
			var room_id = room_grid[ry][rx]
			if room_id == 0 or room_id > rooms_data.size():
				continue
			var room = rooms_data[room_id - 1]
			var height_data = room["heightData"]
			var ox = rx * 16 * tile_size
			var oz = ry * 16 * tile_size

			for y in range(16):
				for x in range(16):
					var h = height_data[y][x]
					if h == 0:
						continue
					var px = ox + x * tile_size
					var pz = oz + y * tile_size

					if h == 15:
						_add_box(walls_st, px, pz, tile_size, tile_size * 2)
						_add_wall_collision(px, pz, tile_size, tile_size * 2)
						wall_count += 1
					else:
						var ph = float(h) * 0.5
						_add_box(floors_st, px, pz, tile_size, ph)
						floor_count += 1

	walls_st.generate_normals()
	var wall_mesh = walls_st.commit()

	var wall_inst = MeshInstance3D.new()
	wall_inst.mesh = wall_mesh
	wall_inst.name = "Walls"
	var wm = StandardMaterial3D.new()
	wm.albedo_color = Color(0.35, 0.3, 0.22)
	wm.cull_mode = BaseMaterial3D.CULL_DISABLED
	wall_inst.material_override = wm
	add_child(wall_inst)

	floors_st.generate_normals()
	var floor_mesh = floors_st.commit()

	var floor_inst = MeshInstance3D.new()
	floor_inst.mesh = floor_mesh
	floor_inst.name = "Floors"
	var fm = StandardMaterial3D.new()
	fm.albedo_color = Color(0.55, 0.45, 0.35)
	fm.cull_mode = BaseMaterial3D.CULL_DISABLED
	floor_inst.material_override = fm
	add_child(floor_inst)

	print("Paredes: ", wall_count, " Plataformas: ", floor_count)
	_add_characters()
	print("Mapa completo")

func _add_box(st: SurfaceTool, x: float, z: float, size: float, height: float) -> void:
	var s = size * 0.5
	var y0 = 0.0
	var y1 = height

	st.add_vertex(Vector3(x-s, y1, z-s))
	st.add_vertex(Vector3(x+s, y1, z-s))
	st.add_vertex(Vector3(x+s, y1, z+s))
	st.add_vertex(Vector3(x-s, y1, z-s))
	st.add_vertex(Vector3(x+s, y1, z+s))
	st.add_vertex(Vector3(x-s, y1, z+s))
	st.add_vertex(Vector3(x-s, y0, z-s))
	st.add_vertex(Vector3(x+s, y0, z-s))
	st.add_vertex(Vector3(x+s, y1, z-s))
	st.add_vertex(Vector3(x-s, y0, z-s))
	st.add_vertex(Vector3(x+s, y1, z-s))
	st.add_vertex(Vector3(x-s, y1, z-s))
	st.add_vertex(Vector3(x+s, y0, z+s))
	st.add_vertex(Vector3(x-s, y0, z+s))
	st.add_vertex(Vector3(x-s, y1, z+s))
	st.add_vertex(Vector3(x+s, y0, z+s))
	st.add_vertex(Vector3(x-s, y1, z+s))
	st.add_vertex(Vector3(x+s, y1, z+s))
	st.add_vertex(Vector3(x-s, y0, z+s))
	st.add_vertex(Vector3(x-s, y0, z-s))
	st.add_vertex(Vector3(x-s, y1, z-s))
	st.add_vertex(Vector3(x-s, y0, z+s))
	st.add_vertex(Vector3(x-s, y1, z-s))
	st.add_vertex(Vector3(x-s, y1, z+s))
	st.add_vertex(Vector3(x+s, y0, z-s))
	st.add_vertex(Vector3(x+s, y0, z+s))
	st.add_vertex(Vector3(x+s, y1, z+s))
	st.add_vertex(Vector3(x+s, y0, z-s))
	st.add_vertex(Vector3(x+s, y1, z+s))
	st.add_vertex(Vector3(x+s, y1, z-s))

var wall_body: StaticBody3D

func _add_wall_collision(x: float, z: float, size: float, height: float) -> void:
	if wall_body == null:
		wall_body = StaticBody3D.new()
		wall_body.name = "WallCollisions"
		add_child(wall_body)

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(size, height, size)
	col.shape = box
	col.position = Vector3(x, height * 0.5, z)
	wall_body.add_child(col)

func _add_characters() -> void:
	var script = preload("res://scripts/Personaje3D.gd")

	# Posiciones de AbbeyMap.gd: room(room_grid_x, room_grid_y), pos(tile_x, tile_y)
	# _room_to_world(gx, gy, tx, ty)
	var chars = [
		{"n": "Abad", "c": Color(1, 0.8, 0.2), "gx": 5, "gy": 3, "tx": 4, "ty": 12, "t": 0},
		{"n": "Adso", "c": Color(0.8, 0.8, 0.8), "gx": 10, "gy": 2, "tx": 5, "ty": 1, "t": 1},
		{"n": "Malaquías", "c": Color(0.7, 0.7, 0.9), "gx": 3, "gy": 3, "tx": 10, "ty": 4, "t": 2},
		{"n": "Berengario", "c": Color(0.9, 0.7, 0.7), "gx": 8, "gy": 3, "tx": 8, "ty": 12, "t": 3},
		{"n": "Severino", "c": Color(0.7, 0.9, 0.7), "gx": 6, "gy": 6, "tx": 8, "ty": 1, "t": 4},
		{"n": "Bernardo", "c": Color(0.85, 0.85, 0.6), "gx": 8, "gy": 8, "tx": 8, "ty": 4, "t": 5},
		{"n": "Jorge", "c": Color(0.6, 0.6, 0.6), "gx": 12, "gy": 2, "tx": 7, "ty": 7, "t": 6},
	]

	for d in chars:
		var pos = _room_to_world(d["gx"], d["gy"], d["tx"], d["ty"])
		var h = _get_height_at(d["gx"], d["gy"], d["tx"], d["ty"])
		var ground_h = 0.0
		if h > 0 and h < 15:
			ground_h = float(h) * 0.5

		var c = CharacterBody3D.new()
		c.name = d["n"]
		c.position = Vector3(pos.x, ground_h + 0.1, pos.z)

		var col = CollisionShape3D.new()
		var shape = CapsuleShape3D.new()
		shape.radius = 0.5
		shape.height = 1.5
		col.shape = shape
		col.position.y = 1.0
		c.add_child(col)

		var body = MeshInstance3D.new()
		body.mesh = CapsuleMesh.new()
		body.mesh.radius = 0.5
		body.mesh.height = 1.5
		body.position.y = 1.0
		var mat = StandardMaterial3D.new()
		mat.albedo_color = d["c"]
		body.material_override = mat
		c.add_child(body)

		var head = MeshInstance3D.new()
		head.mesh = SphereMesh.new()
		head.mesh.radius = 0.3
		head.position.y = 2.0
		var hmat = StandardMaterial3D.new()
		hmat.albedo_color = Color(0.9, 0.8, 0.7)
		head.material_override = hmat
		c.add_child(head)

		# Nombre sobre la cabeza
		var label3d = Label3D.new()
		label3d.text = d["n"]
		label3d.position.y = 2.8
		label3d.font_size = 48
		label3d.pixel_size = 0.01
		label3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label3d.no_depth_test = true
		label3d.fixed_size = true
		label3d.modulate = Color(1, 1, 0.5, 1.0)
		c.add_child(label3d)

		c.set_script(script)
		c.set("tipo", d["t"])
		c.set("nombre", d["n"])
		add_child(c)

func _create_test_cube() -> void:
	print("Sin datos - creando cubo de prueba")
	var box = BoxMesh.new()
	box.size = Vector3(20, 5, 20)
	var inst = MeshInstance3D.new()
	inst.mesh = box
	inst.position = Vector3(0, 2.5, 0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0)
	inst.material_override = mat
	add_child(inst)
