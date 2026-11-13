extends Node

func _ready() -> void:
	var interpreter = ScriptInterpreter.new()

	var floors_file = FileAccess.open("res://data/floors.json", FileAccess.READ)
	var floors_data = []
	if floors_file:
		var json = JSON.new()
		if json.parse(floors_file.get_as_text()) == OK:
			floors_data = json.data
		floors_file.close()

	var rooms_file = FileAccess.open("res://data/rooms.json", FileAccess.READ)
	var rooms_data = []
	if rooms_file:
		var json = JSON.new()
		if json.parse(rooms_file.get_as_text()) == OK:
			rooms_data = json.data
		rooms_file.close()

	var scripts_file = FileAccess.open("res://data/scripts.abs", FileAccess.READ)
	if scripts_file:
		interpreter.parse_scripts(scripts_file.get_as_text())
		scripts_file.close()

	var renderer = RoomRenderer.new()
	renderer.setup(interpreter, floors_data, rooms_data)
	renderer.build_room(0, 8, 1)
	get_tree().quit()
