extends SceneTree
## Pruebas complementarias para el issue #2. No modifica los motores.
## Ejecutar: godot --headless --path . --script res://scripts/test_regresion_v116.gd

var failures: int = 0
var checks: int = 0

func _check(ok: bool, message: String) -> void:
    checks += 1
    if ok:
        print("PASS | " + message)
    else:
        failures += 1
        push_error("FAIL | " + message)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var data := AbadiaData.new()
    var rooms_loaded := data.load_habitaciones("res://data/habitaciones.bin")
    var heights_loaded := data.load_alturas("res://data/alturas.bin")
    _check(rooms_loaded, "cargar habitaciones.bin")
    _check(heights_loaded, "cargar alturas.bin")
    if not rooms_loaded or not heights_loaded:
        quit(1)
        return

    _check(data.get_room_count() == 450, "450 bloques físicos")
    _check(data.get_grh(23, 4, 7, 2) == 625, "GRH conocido en bloque 23")
    _check(data.get_height(23, 4, 7) == 15, "altura conocida en bloque 23")

    var diagnostics := AbadiaDiagnostics.new()
    var problems := AbadiaDiagnostics.find_out_of_bounds_grhs(
        data, 23, Vector2i(16, 8)
    )
    _check(problems.size() > 0, "detectar GRH fuera de atlas artificial pequeño")
    var no_atlas := diagnostics.analyze_grh(625, 0, 0)
    _check(bool(no_atlas.get("suspicious", false)), "diagnóstico detecta atlas ausente")

    var bridge_script := load("res://scripts/RoomDataBridge.cs") as Script
    _check(bridge_script != null, "cargar RoomDataBridge.cs")
    if bridge_script != null:
        var bridge := Node.new()
        bridge.set_script(bridge_script)
        root.add_child(bridge)
        var ready := bool(bridge.call("IsReady"))
        _check(ready, "DLL y datos de habitaciones disponibles")
        if ready:
            _check(bridge.call("GetGridSize", 0) == 16, "Iglesia: cuadrícula 16")
            _check(bridge.call("GetGridSize", 1) == 32, "Scriptorium: cuadrícula 32")
            _check(bridge.call("GetGridSize", 2) == 32, "Biblioteca: cuadrícula 32")
            _check(bridge.call("GetRoomAtPosition", 1, 34.43478, 35.21739) == 69,
                "selección exacta de habitación 69")
            for room_number in [39, 44, 55, 56, 69]:
                var found := false
                for floor_index in range(3):
                    var pos: Vector2 = bridge.call("GetRoomPosition", floor_index, room_number)
                    if pos != Vector2(-1, -1):
                        found = true
                        break
                _check(found, "habitación %d presente en la DLL" % room_number)
        bridge.queue_free()

    var renderer := AbadiaRenderer.new()
    root.add_child(renderer)
    _check(not renderer.diagnostic_enabled, "F3: diagnóstico inicialmente apagado")
    var key := InputEventKey.new()
    key.keycode = KEY_F3
    key.pressed = true
    renderer._unhandled_key_input(key)
    _check(renderer.diagnostic_enabled, "F3: activar diagnóstico")
    renderer._unhandled_key_input(key)
    _check(not renderer.diagnostic_enabled, "F3: desactivar diagnóstico")
    renderer.queue_free()

    if failures == 0:
        print("REGRESION V1.1.6 OK | %d comprobaciones" % checks)
    else:
        push_error("REGRESION V1.1.6 FALLIDA | %d/%d errores" % [failures, checks])
    quit(0 if failures == 0 else 1)
