extends SceneTree

const ROOM_BYTES: int = 5280
const HEIGHT_BYTES: int = 576

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS | " + message)
	else:
		failures += 1
		push_error("FAIL | " + message)

func _run() -> void:
	var data := AbadiaData.new()
	_check(data.load_habitaciones("res://data/habitaciones.bin"), "carga habitaciones.bin")
	_check(data.load_alturas("res://data/alturas.bin"), "carga alturas.bin")
	_check(data.get_room_count() == 450, "habitaciones.bin contiene 450 bloques físicos")
	_check(ROOM_BYTES == 20 * 22 * 3 * 4, "tamaño de bloque de habitaciones")
	_check(HEIGHT_BYTES == 24 * 24, "tamaño de bloque de alturas")
	_check(data.get_grh(23, 4, 7, 2) == 625, "decodificación GRH conocida")
	_check(data.get_height(23, 4, 7) == 15, "decodificación de altura conocida")

	var tiles := load("res://assets/tilesRemake.png") as Texture2D
	var diagnostics := AbadiaDiagnostics.new()
	diagnostics.set_tiles_image(tiles.get_image() if tiles != null else null)
	var grh := 625
	var src_x: int = grh & 0xF0
	var src_y: int = ((grh & 0x0F) << 3) + ((grh >> 8) * 128)
	var result: Dictionary = diagnostics.analyze_grh(grh, src_x, src_y)
	_check(result.has("suspicious"), "diagnóstico devuelve estado")
	_check(result.has("reason"), "diagnóstico devuelve motivo")

	var bridge_script := load("res://scripts/RoomDataBridge.cs") as Script
	_check(bridge_script != null, "carga RoomDataBridge.cs")
	if bridge_script != null:
		var bridge := Node.new()
		bridge.set_script(bridge_script)
		root.add_child(bridge)
		_check(bool(bridge.call("IsReady")), "DLL de habitaciones preparada")
		var position: Vector2 = bridge.call("GetRoomPosition", 0, 39)
		_check(position == Vector2(124, 12), "posición conocida de habitación 39")
		var selected: int = bridge.call("GetRoomAtPosition", 1, 34.43478, 35.21739)
		_check(selected == 69, "selección exacta de habitación 69")
		_check(bridge.call("GetGridSize", 0) == 16, "tamaño de cuadrícula de Iglesia")
		_check(bridge.call("GetGridSize", 1) == 32, "tamaño de cuadrícula de Scriptorium")
		_check(bridge.call("GetGridSize", 2) == 32, "tamaño de cuadrícula de Biblioteca")
		bridge.queue_free()

	if failures == 0:
		print("REGRESION V0.7 OK")
	else:
		push_error("REGRESION V0.7 FALLIDA: %d comprobación(es)" % failures)
	quit(1 if failures > 0 else 0)
