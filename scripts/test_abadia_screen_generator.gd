extends SceneTree
## Ejecutar desde la carpeta del proyecto:
## godot --headless --path . --script res://scripts/test_abadia_screen_generator.gd

func _initialize() -> void:
	var generator = load("res://scripts/abadia_screen_generator.gd").new()
	var maps: Array[String] = [
		"res://assets/3d_cpc.map",
		"res://assets/3d.map",
		"res://assets/3d_cpc_cinta.map"
	]
	var failures: int = 0
	var expected_totals: Array = [
		[24, 23, 28, 26],
		[22, 23, 28, 26],
		[0, 17, 25, 26]
	]
	var rooms: Array[int] = [39, 69, 77, 103]
	for map_index in range(maps.size()):
		if not generator.load_from_files("res://assets/bloques.bin", maps[map_index]):
			failures += 1
			continue
		for i in range(rooms.size()):
			var count: int = generator.generate_screen(rooms[i])
			var expected: int = expected_totals[map_index][i]
			var valid: bool = count == expected
			print(maps[map_index].get_file(), " habitación ", rooms[i], " elementos=", count, " esperado=", expected, " ", "OK" if valid else "ERROR")
			if not valid:
				failures += 1
		if map_index == 0:
			for limit in [0, 15, 22, 28]:
				generator.generate_screen(77, limit)
				var sum_tiles: int = 0
				for byte in generator.tiles:
					sum_tiles += byte
				var sums: Dictionary = {0: 0, 15: 14742, 22: 22764, 28: 32201}
				var valid_sum: bool = sum_tiles == sums[limit]
				print("Habitación 77, ", limit, "/28: checksum=", sum_tiles, " esperado=", sums[limit], " ", "OK" if valid_sum else "ERROR")
				if not valid_sum:
					failures += 1
	print("RESULTADO: ", "OK" if failures == 0 else str(failures) + " fallos")
	quit(0 if failures == 0 else 1)
