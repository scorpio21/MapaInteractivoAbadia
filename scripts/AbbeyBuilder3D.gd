extends Node3D

@export var tile_size: float = 2.0
@export var floor_index: int = 0

var floors_data: Array = []
var rooms_data: Array = []

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

func _generate_map() -> void:
	var floor_data = floors_data[floor_index]
	var room_grid = floor_data["room"]

	# Ground plane
	var ground = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(512, 512)
	ground.mesh = plane
	ground.position = Vector3(128, -0.1, 128)
	var gm = StandardMaterial3D.new()
	gm.albedo_color = Color(0.18, 0.3, 0.12)
	gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	ground.material_override = gm
	add_child(ground)

	# Batch walls into one mesh
	var walls_st = SurfaceTool.new()
	walls_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall_count = 0

	# Batch floors/platforms into one mesh
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
						wall_count += 1
					else:
						var ph = float(h) * 0.3
						_add_box(floors_st, px, pz, tile_size, ph)
						floor_count += 1

	walls_st.generate_normals()
	var wall_mesh = walls_st.commit()

	var wall_inst = MeshInstance3D.new()
	wall_inst.mesh = wall_mesh
	var wm = StandardMaterial3D.new()
	wm.albedo_color = Color(0.35, 0.3, 0.22)
	wm.cull_mode = BaseMaterial3D.CULL_DISABLED
	wall_inst.material_override = wm
	add_child(wall_inst)

	floors_st.generate_normals()
	var floor_mesh = floors_st.commit()

	var floor_inst = MeshInstance3D.new()
	floor_inst.mesh = floor_mesh
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

	# Only add 3 visible faces (top + 2 sides) to reduce triangles
	# Top face
	st.add_vertex(Vector3(x - s, y1, z - s))
	st.add_vertex(Vector3(x + s, y1, z - s))
	st.add_vertex(Vector3(x + s, y1, z + s))
	st.add_vertex(Vector3(x - s, y1, z - s))
	st.add_vertex(Vector3(x + s, y1, z + s))
	st.add_vertex(Vector3(x - s, y1, z + s))
	# Front
	st.add_vertex(Vector3(x - s, y0, z - s))
	st.add_vertex(Vector3(x + s, y0, z - s))
	st.add_vertex(Vector3(x + s, y1, z - s))
	st.add_vertex(Vector3(x - s, y0, z - s))
	st.add_vertex(Vector3(x + s, y1, z - s))
	st.add_vertex(Vector3(x - s, y1, z - s))
	# Back
	st.add_vertex(Vector3(x + s, y0, z + s))
	st.add_vertex(Vector3(x - s, y0, z + s))
	st.add_vertex(Vector3(x - s, y1, z + s))
	st.add_vertex(Vector3(x + s, y0, z + s))
	st.add_vertex(Vector3(x - s, y1, z + s))
	st.add_vertex(Vector3(x + s, y1, z + s))
	# Left
	st.add_vertex(Vector3(x - s, y0, z + s))
	st.add_vertex(Vector3(x - s, y0, z - s))
	st.add_vertex(Vector3(x - s, y1, z - s))
	st.add_vertex(Vector3(x - s, y0, z + s))
	st.add_vertex(Vector3(x - s, y1, z - s))
	st.add_vertex(Vector3(x - s, y1, z + s))
	# Right
	st.add_vertex(Vector3(x + s, y0, z - s))
	st.add_vertex(Vector3(x + s, y0, z + s))
	st.add_vertex(Vector3(x + s, y1, z + s))
	st.add_vertex(Vector3(x + s, y0, z - s))
	st.add_vertex(Vector3(x + s, y1, z + s))
	st.add_vertex(Vector3(x + s, y1, z - s))

func _add_characters() -> void:
	var script = preload("res://scripts/Personaje3D.gd")

	var chars = [
		{"n": "Abad", "c": Color(1, 0.8, 0.2), "p": Vector3(128, 0, 48), "t": 0},
		{"n": "Adso", "c": Color(0.8, 0.8, 0.8), "p": Vector3(80, 0, 60), "t": 1},
		{"n": "Malaquías", "c": Color(0.7, 0.7, 0.9), "p": Vector3(48, 0, 48), "t": 2},
		{"n": "Berengario", "c": Color(0.9, 0.7, 0.7), "p": Vector3(96, 0, 96), "t": 3},
		{"n": "Severino", "c": Color(0.7, 0.9, 0.7), "p": Vector3(100, 0, 32), "t": 4},
		{"n": "Bernardo", "c": Color(0.85, 0.85, 0.6), "p": Vector3(140, 0, 140), "t": 5},
		{"n": "Jorge", "c": Color(0.6, 0.6, 0.6), "p": Vector3(32, 0, 100), "t": 6},
	]

	for d in chars:
		var c = Node3D.new()
		c.name = d["n"]
		c.position = d["p"]

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
