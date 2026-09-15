extends Node3D

# Generador de mapa 3D optimizado - usa un solo ArrayMesh

@export var tile_size: float = 2.0
@export var height_scale: float = 0.5
@export var floor_index: int = 0

var floors_data: Array = []
var rooms_data: Array = []

func _ready() -> void:
	call_deferred("_init_map")

func _init_map() -> void:
	_load_data()
	if floors_data.is_empty() or rooms_data.is_empty():
		push_warning("No hay datos de mapa")
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
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var floor = floors_data[floor_index]
	var room_grid = floor["room"]

	for ry in range(16):
		for rx in range(16):
			var room_id = room_grid[ry][rx]
			if room_id == 0 or room_id > rooms_data.size():
				continue
			_add_room_mesh(st, room_id, rx, ry)

	st.generate_normals()
	var mesh = st.commit()

	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	instance.name = "AbbeyMesh"

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.5, 0.4)
	instance.material_override = material

	add_child(instance)

	# Agregar personajes 3D
	_add_characters()

func _add_room_mesh(st: SurfaceTool, room_id: int, grid_x: int, grid_y: int) -> void:
	var room = rooms_data[room_id - 1]
	var height_data = room["heightData"]
	var offset_x = grid_x * 16 * tile_size
	var offset_z = grid_y * 16 * tile_size

	for y in range(16):
		for x in range(16):
			var h = height_data[y][x]
			if h == 0:
				continue

			var px = offset_x + x * tile_size
			var pz = offset_z + y * tile_size

			if h == 15:
				_add_cube(st, px, pz, tile_size, tile_size * 2, Color(0.4, 0.35, 0.25))
			else:
				var ph = h * height_scale
				_add_cube(st, px, pz, tile_size, ph, Color(0.5 + float(h)/30.0, 0.4, 0.3))

func _add_cube(st: SurfaceTool, x: float, z: float, size: float, height: float, color: Color) -> void:
	var y0 = 0.0
	var y1 = height
	var s = size * 0.5

	var verts = [
		# Front
		Vector3(x - s, y0, z - s), Vector3(x + s, y0, z - s), Vector3(x + s, y1, z - s),
		Vector3(x - s, y0, z - s), Vector3(x + s, y1, z - s), Vector3(x - s, y1, z - s),
		# Back
		Vector3(x + s, y0, z + s), Vector3(x - s, y0, z + s), Vector3(x - s, y1, z + s),
		Vector3(x + s, y0, z + s), Vector3(x - s, y1, z + s), Vector3(x + s, y1, z + s),
		# Top
		Vector3(x - s, y1, z - s), Vector3(x + s, y1, z - s), Vector3(x + s, y1, z + s),
		Vector3(x - s, y1, z - s), Vector3(x + s, y1, z + s), Vector3(x - s, y1, z + s),
	]

	for v in verts:
		st.set_color(color)
		st.add_vertex(v)

func _add_characters() -> void:
	var Personaje3DScript = preload("res://scripts/Personaje3D.gd")

	# Abad
	var abad = _create_character("Abad", Color(1, 0.8, 0.2), Vector3(128, 2, 48))
	abad.set_script(Personaje3DScript)
	abad.set("tipo", 0)
	abad.set("nombre", "Abad")
	add_child(abad)

	# Monjes
	var monjes_data := [
		{"nombre": "Adso", "color": Color(0.8, 0.8, 0.8), "pos": Vector3(80, 2, 60)},
		{"nombre": "Malaquías", "color": Color(0.7, 0.7, 0.9), "pos": Vector3(48, 2, 48)},
		{"nombre": "Berengario", "color": Color(0.9, 0.7, 0.7), "pos": Vector3(96, 2, 96)},
		{"nombre": "Severino", "color": Color(0.7, 0.9, 0.7), "pos": Vector3(100, 2, 32)},
		{"nombre": "Bernardo", "color": Color(0.85, 0.85, 0.6), "pos": Vector3(140, 2, 140)},
		{"nombre": "Jorge", "color": Color(0.6, 0.6, 0.6), "pos": Vector3(32, 2, 100)},
	]

	for i in range(monjes_data.size()):
		var d = monjes_data[i]
		var monje = _create_character(d["nombre"], d["color"], d["pos"])
		monje.set_script(Personaje3DScript)
		monje.set("tipo", i + 1)
		monje.set("nombre", d["nombre"])
		add_child(monje)

func _create_character(nombre: String, color: Color, pos: Vector3) -> Node3D:
	var char_node = Node3D.new()
	char_node.name = nombre
	char_node.position = pos

	# Cuerpo (capsula simplificada)
	var body = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.2
	body.mesh = capsule
	body.position.y = 0.8

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	body.material_override = mat

	char_node.add_child(body)

	# Cabeza
	var head = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.25
	head.mesh = sphere
	head.position.y = 1.6

	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.9, 0.8, 0.7)
	head.material_override = head_mat

	char_node.add_child(head)

	return char_node
