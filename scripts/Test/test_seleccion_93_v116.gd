extends SceneTree
## Verifica que todas las habitaciones declaradas en habitaciones.json
## se recuperan por la DLL en el centro de su celda.
## Ejecutar: godot --headless --path . --script res://scripts/test_seleccion_93_v116.gd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var path := "res://data/habitaciones.json"
	if not FileAccess.file_exists(path):
		push_error("No existe " + path)
		quit(1)
		return

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or not parsed.has("rooms"):
		push_error("JSON inválido o sin rooms")
		quit(1)
		return

	var rooms: Array = parsed["rooms"]
	var bridge_script := load("res://scripts/RoomDataBridge.cs") as Script
	if bridge_script == null:
		push_error("No se puede cargar RoomDataBridge.cs")
		quit(1)
		return

	var bridge := Node.new()
	bridge.set_script(bridge_script)
	root.add_child(bridge)
	if not bool(bridge.call("IsReady")):
		push_error("DLL no inicializada")
		quit(1)
		return

	var failures := 0
	var checked := 0
	for room_data in rooms:
		var floor_index: int = int(room_data["floor"])
		var room_number: int = int(room_data["number"])
		var x: float = float(room_data["x"])
		var y: float = float(room_data["y"])
		var position: Vector2 = bridge.call("GetRoomPosition", floor_index, room_number)
		var actual: int = int(bridge.call("GetRoomAtPosition", floor_index, x, y))
		checked += 1
		if position != Vector2(x, y) or actual != room_number:
			failures += 1
			print("FAIL | planta=%d habitacion=%d posicion=%s resultado=%d" % [floor_index, room_number, str(position), actual])

	print("SELECCION DLL | %d habitaciones revisadas | %d fallos" % [checked, failures])
	if checked != 93:
		failures += 1
		push_error("Esperadas 93 habitaciones, encontradas: %d" % checked)
	if failures == 0:
		print("REGRESION SELECCION 93 OK")
	else:
		push_error("REGRESION SELECCION 93 FALLIDA")
	bridge.queue_free()
	quit(0 if failures == 0 else 1)
