extends Node

# Prueba no destructiva; añádelo temporalmente a una escena vacía.
func _ready() -> void:
    var bridge_script := load("res://scripts/RoomDataBridge.cs")
    var bridge := Node.new()
    bridge.set_script(bridge_script)
    add_child(bridge)
    # _ready() del puente se ejecuta al añadirlo al árbol.
    if not bridge.call("IsReady"):
        push_error("La biblioteca no ha cargado")
        return
    print("DLL | Hab 39:", bridge.call("GetRoomPosition", 0, 39))
    print("DLL | Hab 44:", bridge.call("GetRoomPosition", 0, 44))
    print("DLL | Hab 55:", bridge.call("GetRoomPosition", 0, 55))
    print("DLL | Hab 56:", bridge.call("GetRoomPosition", 0, 56))
    print("DLL | Selección prueba (170,44):", bridge.call("GetRoomAtPosition", 0, 170.0, 44.0))
    print("DLL | Tamaños:", bridge.call("GetGridSize", 0), ",", bridge.call("GetGridSize", 1), ",", bridge.call("GetGridSize", 2))
